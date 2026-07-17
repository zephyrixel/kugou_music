mod writer;

use log::{Level, LevelFilter, Log, Metadata, Record};
use std::{
    path::PathBuf,
    sync::{
        OnceLock,
        atomic::{AtomicBool, AtomicU8, AtomicU64, Ordering},
        mpsc::{SyncSender, TrySendError, sync_channel},
    },
    thread,
    time::{SystemTime, UNIX_EPOCH},
};

use super::dto::{AppLogLevelDto, BridgeError};

const CHANNEL_CAPACITY: usize = 256;
static LOGGER: OnceLock<NativeLogger> = OnceLock::new();
static LOGGER_INSTALLED: AtomicBool = AtomicBool::new(false);

pub(super) struct NativeRecord {
    pub(super) timestamp_ms: u128,
    pub(super) level: Level,
    pub(super) target: String,
    pub(super) message: String,
}

pub(super) enum Command {
    Record(NativeRecord),
    Configure(PathBuf, SyncSender<Result<(), String>>),
    Clear(SyncSender<Result<(), String>>),
    Flush(SyncSender<Result<(), String>>),
}

struct NativeLogger {
    sender: SyncSender<Command>,
    level: AtomicU8,
    dropped: AtomicU64,
}

impl NativeLogger {
    fn new() -> Result<Self, BridgeError> {
        let (sender, receiver) = sync_channel(CHANNEL_CAPACITY);
        thread::Builder::new()
            .name("kgmusic-log-writer".to_owned())
            .spawn(move || writer::run(receiver))
            .map_err(|error| {
                BridgeError::internal(format!("failed to start native log writer: {error}"))
            })?;
        Ok(Self {
            sender,
            level: AtomicU8::new(level_value(AppLogLevelDto::Off)),
            dropped: AtomicU64::new(0),
        })
    }

    fn set_level(&self, level: AppLogLevelDto) {
        self.level.store(level_value(level), Ordering::Release);
    }

    fn accepts(&self, level: Level) -> bool {
        level_value_from_log(level) <= self.level.load(Ordering::Acquire)
    }

    fn send_record(&self, record: &Record<'_>) {
        let dropped = self.dropped.swap(0, Ordering::Relaxed);
        let message = if dropped == 0 {
            record.args().to_string()
        } else {
            format!("[dropped {dropped} log records] {}", record.args())
        };
        let value = NativeRecord {
            timestamp_ms: now_millis(),
            level: record.level(),
            target: record.target().to_owned(),
            message,
        };
        match self.sender.try_send(Command::Record(value)) {
            Ok(()) => {}
            Err(TrySendError::Full(_)) => {
                self.dropped.fetch_add(dropped + 1, Ordering::Relaxed);
            }
            Err(TrySendError::Disconnected(_)) => {}
        }
    }

    fn request(
        &self,
        command: impl FnOnce(SyncSender<Result<(), String>>) -> Command,
    ) -> Result<(), BridgeError> {
        let (reply, result) = sync_channel(0);
        self.sender
            .send(command(reply))
            .map_err(|_| BridgeError::internal("native log writer is unavailable"))?;
        result
            .recv()
            .map_err(|_| BridgeError::internal("native log writer stopped unexpectedly"))?
            .map_err(BridgeError::internal)
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
            self.send_record(record);
        }
    }

    fn flush(&self) {
        let _ = self.request(Command::Flush);
    }
}

pub(super) fn install() -> Result<(), BridgeError> {
    if LOGGER.get().is_none() {
        let _ = LOGGER.set(NativeLogger::new()?);
    }
    let logger = LOGGER
        .get()
        .ok_or_else(|| BridgeError::internal("native logger initialization failed"))?;
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

pub(super) fn initialize(directory: String, level: AppLogLevelDto) -> Result<(), BridgeError> {
    install()?;
    let logger = logger()?;
    logger.request(|reply| Command::Configure(PathBuf::from(directory), reply))?;
    logger.set_level(level);
    log::info!(target: "kugou_bridge::logging", "native logging initialized");
    Ok(())
}

pub(super) fn set_level(level: AppLogLevelDto) -> Result<(), BridgeError> {
    let logger = logger()?;
    logger.set_level(level);
    log::info!(target: "kugou_bridge::logging", "native log level changed to {level:?}");
    Ok(())
}

pub(super) fn clear() -> Result<(), BridgeError> {
    logger()?.request(Command::Clear)
}

pub(super) fn flush() -> Result<(), BridgeError> {
    logger()?.request(Command::Flush)
}

fn logger() -> Result<&'static NativeLogger, BridgeError> {
    if !LOGGER_INSTALLED.load(Ordering::Acquire) {
        return Err(BridgeError::internal("native logger is not installed"));
    }
    LOGGER
        .get()
        .ok_or_else(|| BridgeError::internal("native logger is not initialized"))
}

fn now_millis() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|value| value.as_millis())
        .unwrap_or_default()
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
    fn changed_level_is_visible_to_filter_immediately() {
        let logger = NativeLogger::new().unwrap();
        logger.set_level(AppLogLevelDto::Warn);
        assert!(logger.accepts(Level::Error));
        assert!(!logger.accepts(Level::Debug));

        logger.set_level(AppLogLevelDto::Trace);
        assert!(logger.accepts(Level::Debug));
        assert!(logger.accepts(Level::Trace));
    }
}
