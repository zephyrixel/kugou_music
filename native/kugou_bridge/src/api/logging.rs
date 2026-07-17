use log::{Level, LevelFilter, Log, Metadata, Record};
use serde_json::json;
use std::{
    fs::{self, OpenOptions},
    io::Write,
    path::{Path, PathBuf},
    sync::{
        Mutex, OnceLock,
        atomic::{AtomicBool, AtomicU8, Ordering},
    },
    time::{SystemTime, UNIX_EPOCH},
};

use super::dto::{AppLogLevelDto, BridgeError};

const MAX_FILE_BYTES: u64 = 2 * 1024 * 1024;
const CURRENT_FILE: &str = "native-current.jsonl";
const FIRST_HISTORY: &str = "native-1.jsonl";
const SECOND_HISTORY: &str = "native-2.jsonl";

static LOGGER: OnceLock<NativeLogger> = OnceLock::new();
static LOGGER_INSTALLED: AtomicBool = AtomicBool::new(false);

struct NativeLogger {
    directory: Mutex<Option<PathBuf>>,
    level: AtomicU8,
    write_lock: Mutex<()>,
}

impl NativeLogger {
    fn new() -> Self {
        Self {
            directory: Mutex::new(None),
            level: AtomicU8::new(level_value(AppLogLevelDto::Off)),
            write_lock: Mutex::new(()),
        }
    }

    fn configure(&self, directory: PathBuf, level: AppLogLevelDto) -> Result<(), BridgeError> {
        fs::create_dir_all(&directory).map_err(io_error)?;
        *self
            .directory
            .lock()
            .map_err(|_| BridgeError::internal("native logger directory lock is poisoned"))? =
            Some(directory);
        self.set_level(level);
        Ok(())
    }

    fn set_level(&self, level: AppLogLevelDto) {
        self.level.store(level_value(level), Ordering::Relaxed);
    }

    fn directory(&self) -> Option<PathBuf> {
        self.directory.lock().ok().and_then(|path| path.clone())
    }

    fn accepts(&self, level: Level) -> bool {
        level_value_from_log(level) <= self.level.load(Ordering::Relaxed)
    }

    fn write_record(&self, record: &Record<'_>) {
        let Some(directory) = self.directory() else {
            return;
        };
        let timestamp_ms = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|value| value.as_millis())
            .unwrap_or_default();
        let line = json!({
            "timestampMs": timestamp_ms,
            "level": record.level().as_str().to_ascii_lowercase(),
            "source": "native",
            "target": record.target(),
            "message": record.args().to_string(),
        })
        .to_string()
            + "\n";

        let Ok(_guard) = self.write_lock.lock() else {
            return;
        };
        if rotate_if_needed(&directory, line.len() as u64).is_err() {
            return;
        }
        let path = directory.join(CURRENT_FILE);
        if let Ok(mut file) = OpenOptions::new().create(true).append(true).open(path) {
            let _ = file.write_all(line.as_bytes());
        }
    }
}

impl Log for NativeLogger {
    fn enabled(&self, metadata: &Metadata<'_>) -> bool {
        self.accepts(metadata.level())
            && (metadata.target().starts_with("kugou_sdk")
                || metadata.target().starts_with("kugou_bridge"))
    }

    fn log(&self, record: &Record<'_>) {
        if self.enabled(record.metadata()) {
            self.write_record(record);
        }
    }

    fn flush(&self) {}
}

pub(super) fn initialize(directory: String, level: AppLogLevelDto) -> Result<(), BridgeError> {
    install()?;
    let path = PathBuf::from(directory);
    fs::create_dir_all(&path).map_err(io_error)?;
    logger()?.configure(path, level)?;
    log::info!(target: "kugou_bridge::logging", "native logging initialized");
    Ok(())
}

/// Install before Flutter Rust Bridge's default Android console logger. The
/// `log` facade permits only one global logger, so `init_app` must claim it and
/// defer file configuration until Dart supplies the application support path.
pub(super) fn install() -> Result<(), BridgeError> {
    let logger = LOGGER.get_or_init(NativeLogger::new);
    if LOGGER_INSTALLED.load(Ordering::Acquire) {
        return Ok(());
    }
    log::set_logger(logger).map_err(|error| {
        BridgeError::internal(format!("failed to install native logger: {error}"))
    })?;
    log::set_max_level(LevelFilter::Trace);
    LOGGER_INSTALLED.store(true, Ordering::Release);
    Ok(())
}

pub(super) fn set_level(level: AppLogLevelDto) -> Result<(), BridgeError> {
    let logger = logger()?;
    logger.set_level(level);
    log::info!(target: "kugou_bridge::logging", "native log level changed to {level:?}");
    Ok(())
}

pub(super) fn clear() -> Result<(), BridgeError> {
    let logger = logger()?;
    let directory = logger
        .directory()
        .ok_or_else(|| BridgeError::internal("native logger directory lock is poisoned"))?;
    let _guard = logger
        .write_lock
        .lock()
        .map_err(|_| BridgeError::internal("native logger write lock is poisoned"))?;
    for name in [CURRENT_FILE, FIRST_HISTORY, SECOND_HISTORY] {
        remove_if_exists(&directory.join(name))?;
    }
    Ok(())
}

pub(super) fn flush() -> Result<(), BridgeError> {
    let logger = logger()?;
    let _guard = logger
        .write_lock
        .lock()
        .map_err(|_| BridgeError::internal("native logger write lock is poisoned"))?;
    Ok(())
}

fn logger() -> Result<&'static NativeLogger, BridgeError> {
    if !LOGGER_INSTALLED.load(Ordering::Acquire) {
        return Err(BridgeError::internal("native logger is not installed"));
    }
    LOGGER
        .get()
        .ok_or_else(|| BridgeError::internal("native logger is not initialized"))
}

fn rotate_if_needed(directory: &Path, incoming_bytes: u64) -> std::io::Result<()> {
    let current = directory.join(CURRENT_FILE);
    let current_bytes = fs::metadata(&current).map(|value| value.len()).unwrap_or(0);
    if current_bytes + incoming_bytes <= MAX_FILE_BYTES {
        return Ok(());
    }
    let first = directory.join(FIRST_HISTORY);
    let second = directory.join(SECOND_HISTORY);
    if second.exists() {
        fs::remove_file(&second)?;
    }
    if first.exists() {
        fs::rename(&first, &second)?;
    }
    if current.exists() {
        fs::rename(&current, &first)?;
    }
    Ok(())
}

fn remove_if_exists(path: &Path) -> Result<(), BridgeError> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(io_error(error)),
    }
}

fn io_error(error: std::io::Error) -> BridgeError {
    BridgeError::internal(format!("native log file operation failed: {error}"))
}

const fn level_value(level: AppLogLevelDto) -> u8 {
    match level {
        AppLogLevelDto::Off => 0,
        AppLogLevelDto::Error => 1,
        AppLogLevelDto::Warn => 2,
        AppLogLevelDto::Info => 3,
        AppLogLevelDto::Debug => 4,
        AppLogLevelDto::Trace => 5,
    }
}

const fn level_value_from_log(level: Level) -> u8 {
    match level {
        Level::Error => 1,
        Level::Warn => 2,
        Level::Info => 3,
        Level::Debug => 4,
        Level::Trace => 5,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn level_order_matches_log_verbosity() {
        assert!(level_value(AppLogLevelDto::Warn) < level_value(AppLogLevelDto::Debug));
        assert_eq!(level_value_from_log(Level::Error), 1);
        assert_eq!(level_value_from_log(Level::Trace), 5);
    }

    #[test]
    fn rotation_keeps_two_history_files() {
        let directory = std::env::temp_dir().join(format!(
            "kgmusic-native-log-test-{}",
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        fs::create_dir_all(&directory).unwrap();
        fs::write(directory.join(CURRENT_FILE), "current").unwrap();
        rotate_if_needed(&directory, MAX_FILE_BYTES).unwrap();
        fs::write(directory.join(CURRENT_FILE), "next").unwrap();
        rotate_if_needed(&directory, MAX_FILE_BYTES).unwrap();
        fs::write(directory.join(CURRENT_FILE), "last").unwrap();
        rotate_if_needed(&directory, MAX_FILE_BYTES).unwrap();
        assert!(directory.join(FIRST_HISTORY).exists());
        assert!(directory.join(SECOND_HISTORY).exists());
        fs::remove_dir_all(directory).unwrap();
    }
}
