#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

mod resource_server;

pub use resource_server::ResourceServer;
