use alloc::boxed::Box;
use alloc::string::ToString;
use log::{Level, Log, Metadata, Record, SetLoggerError};

use crate::println;

struct SimpleLogger {
    level: Level,
}

impl Log for SimpleLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= self.level
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            let level_string = {
                {
                    record.level().to_string()
                }
            };
            let target = if record.target().len() > 0 {
                record.target()
            } else {
                record.module_path().unwrap_or_default()
            };
            {
                println!("{:<5} [{}] {}", level_string, target, record.args());
            }
        }
    }

    fn flush(&self) {}
}

pub fn init_with_level(level: Level) -> Result<(), SetLoggerError> {
    let logger = SimpleLogger {
        level,
    };
    log::set_logger(Box::leak(Box::new(logger)))?;
    log::set_max_level(level.to_level_filter());
    Ok(())
}

pub fn init() -> Result<(), SetLoggerError> {
    init_with_level(Level::Trace)
}
