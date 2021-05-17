#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

use core::default::Default;
use alloc::prelude::v1::*;
use log::{Log, Metadata, Record};
pub use log::{self, Level, SetLoggerError};

pub struct Logger {
    pub level: Level,
    pub display_mode: DisplayMode,
    pub write: fn(String),
    pub flush: fn(),
}

pub enum DisplayMode {
    Module,
    Line,
}

impl Default for Logger {

    fn default() -> Self {
        Self {
            level: Level::Info,
            display_mode: DisplayMode::default(),
            write: |_| {},
            flush: || {},
        }
    }
}

impl Default for DisplayMode {

    fn default() -> Self {
        DisplayMode::Module
    }
}

impl Log for Logger {

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
            let s = match self.display_mode {
                DisplayMode::Module => {
                    format!("{:<5} [{}] {}", level_string, target, record.args())
                }
                DisplayMode::Line => {
                    format!("{:<5} [{}:{}] {}",
                        level_string,
                        record.file().map(|x| x.to_string()).or(record.file_static().map(|x| x.to_string())).unwrap_or("?".to_string()),
                        record.line().map(|x| format!("{}", x)).unwrap_or("?".to_string()),
                        record.args(),
                    )
                }
            };
            (self.write)(s)
        }
    }

    fn flush(&self) {
        (self.flush)()
    }
}

impl Logger {

    pub fn init(self) -> Result<(), SetLoggerError> {
        log::set_max_level(self.level.to_level_filter());
        log::set_logger(Box::leak(Box::new(self)))?;
        Ok(())
    }
}
