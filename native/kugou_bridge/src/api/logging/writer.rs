use serde_json::json;
use std::{
    fs::{self, File, OpenOptions},
    io::{BufWriter, Write},
    path::{Path, PathBuf},
    sync::mpsc::Receiver,
};

use super::{Command, NativeRecord};

const MAX_FILE_BYTES: u64 = 2 * 1024 * 1024;
const CURRENT_FILE: &str = "native-current.jsonl";
const FIRST_HISTORY: &str = "native-1.jsonl";
const SECOND_HISTORY: &str = "native-2.jsonl";

pub(super) fn run(receiver: Receiver<Command>) {
    let mut state = WriterState::default();
    while let Ok(command) = receiver.recv() {
        match command {
            Command::Record(record) => {
                if let Err(error) = state.write(record) {
                    state.last_error = Some(error.to_string());
                }
            }
            Command::Configure(directory, reply) => {
                let _ = reply.send(
                    state
                        .configure(directory)
                        .map_err(|error| error.to_string()),
                );
            }
            Command::Clear(reply) => {
                let _ = reply.send(state.clear().map_err(|error| error.to_string()));
            }
            Command::Flush(reply) => {
                let _ = reply.send(state.flush_checked().map_err(|error| error.to_string()));
            }
        }
    }
}

#[derive(Default)]
struct WriterState {
    directory: Option<PathBuf>,
    writer: Option<BufWriter<File>>,
    current_bytes: u64,
    last_error: Option<String>,
}

impl WriterState {
    fn configure(&mut self, directory: PathBuf) -> std::io::Result<()> {
        self.close()?;
        fs::create_dir_all(&directory)?;
        self.directory = Some(directory);
        self.last_error = None;
        self.open()
    }

    fn write(&mut self, record: NativeRecord) -> std::io::Result<()> {
        if self.directory.is_none() {
            return Ok(());
        }
        let line = json!({
            "timestampMs": record.timestamp_ms,
            "level": record.level.as_str().to_ascii_lowercase(),
            "source": "native",
            "target": record.target,
            "message": record.message,
        })
        .to_string()
            + "\n";
        let incoming = line.len() as u64;
        if self.current_bytes + incoming > MAX_FILE_BYTES {
            self.rotate()?;
        }
        self.open()?;
        if let Some(writer) = self.writer.as_mut() {
            writer.write_all(line.as_bytes())?;
            self.current_bytes += incoming;
        }
        Ok(())
    }

    fn open(&mut self) -> std::io::Result<()> {
        if self.writer.is_some() {
            return Ok(());
        }
        let Some(directory) = self.directory.as_ref() else {
            return Ok(());
        };
        let path = directory.join(CURRENT_FILE);
        self.current_bytes = fs::metadata(&path).map(|value| value.len()).unwrap_or(0);
        let file = OpenOptions::new().create(true).append(true).open(path)?;
        self.writer = Some(BufWriter::new(file));
        Ok(())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        if let Some(writer) = self.writer.as_mut() {
            writer.flush()?;
        }
        Ok(())
    }

    fn flush_checked(&mut self) -> std::io::Result<()> {
        self.flush()?;
        match self.last_error.take() {
            Some(error) => Err(std::io::Error::other(error)),
            None => Ok(()),
        }
    }

    fn close(&mut self) -> std::io::Result<()> {
        self.flush()?;
        self.writer = None;
        Ok(())
    }

    fn rotate(&mut self) -> std::io::Result<()> {
        self.close()?;
        if let Some(directory) = self.directory.as_ref() {
            rotate_files(directory)?;
        }
        self.current_bytes = 0;
        self.last_error = None;
        self.open()
    }

    fn clear(&mut self) -> std::io::Result<()> {
        self.close()?;
        if let Some(directory) = self.directory.as_ref() {
            for name in [CURRENT_FILE, FIRST_HISTORY, SECOND_HISTORY] {
                remove_if_exists(&directory.join(name))?;
            }
        }
        self.current_bytes = 0;
        self.open()
    }
}

fn rotate_files(directory: &Path) -> std::io::Result<()> {
    let current = directory.join(CURRENT_FILE);
    let first = directory.join(FIRST_HISTORY);
    let second = directory.join(SECOND_HISTORY);
    remove_if_exists(&second)?;
    if first.exists() {
        fs::rename(&first, &second)?;
    }
    if current.exists() {
        fs::rename(&current, &first)?;
    }
    Ok(())
}

fn remove_if_exists(path: &Path) -> std::io::Result<()> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use log::Level;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn temporary_directory(label: &str) -> PathBuf {
        std::env::temp_dir().join(format!(
            "kgmusic-{label}-{}",
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ))
    }

    #[test]
    fn rotation_keeps_two_history_files() {
        let directory = temporary_directory("native-log-test");
        fs::create_dir_all(&directory).unwrap();
        for value in ["first", "second", "third"] {
            fs::write(directory.join(CURRENT_FILE), value).unwrap();
            rotate_files(&directory).unwrap();
        }
        assert!(directory.join(FIRST_HISTORY).exists());
        assert!(directory.join(SECOND_HISTORY).exists());
        fs::remove_dir_all(directory).unwrap();
    }

    #[test]
    fn buffered_writer_flushes_and_clears_deterministically() {
        let directory = temporary_directory("native-writer-test");
        let mut state = WriterState::default();
        state.configure(directory.clone()).unwrap();
        state
            .write(NativeRecord {
                timestamp_ms: 1,
                level: Level::Info,
                target: "kugou_bridge::test".into(),
                message: "hello".into(),
            })
            .unwrap();
        state.flush().unwrap();
        let content = fs::read_to_string(directory.join(CURRENT_FILE)).unwrap();
        assert!(content.contains("hello"));
        state.clear().unwrap();
        state.flush().unwrap();
        assert_eq!(fs::metadata(directory.join(CURRENT_FILE)).unwrap().len(), 0);
        state.close().unwrap();
        fs::remove_dir_all(directory).unwrap();
    }
}
