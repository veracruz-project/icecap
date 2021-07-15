#![feature(with_options)]

mod error;
mod bulk_transport;
pub mod syscall;

pub use error::{
    LameError, Result,
};
pub use bulk_transport::{
    BulkTransport,
};

pub struct Host {
}

impl Host {

    pub fn new() -> Result<Self> {
        Ok(Self {
        })
    }

    pub fn create_realm(&mut self, realm_id: usize, spec: &[u8], bulk_transport_chunk_size: usize) -> Result<()> {
        syscall::declare(realm_id, spec.len());
        let mut bulk_transport = BulkTransport::open()?;
        bulk_transport.send_spec(realm_id, spec, bulk_transport_chunk_size)?;
        syscall::realize(realm_id);
        Ok(())
    }

    pub fn destroy_realm(&mut self, realm_id: usize) -> Result<()> {
        syscall::destroy(realm_id);
        Ok(())
    }

    pub fn hack_run_realm(&mut self, realm_id: usize) -> Result<()> {
        syscall::hack_run(realm_id);
        Ok(())
    }

    pub fn run_realm_node(&mut self, realm_id: usize, virtual_node: usize) -> Result<()> {
        loop {
            syscall::yield_to(realm_id, virtual_node);
        }
        Ok(())
    }
}
