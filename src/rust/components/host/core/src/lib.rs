mod error;
mod bulk_transport;
pub mod syscall;

pub use error::{
    LameError, Result,
};
pub use bulk_transport::{
    BulkTransport, BulkTransportSpec,
};

pub struct Host {
}

impl Host {

    pub fn new() -> Result<Self> {
        Ok(Self {
        })
    }

    pub fn create_realm(&mut self, spec: &[u8], bulk_transport_spec: &BulkTransportSpec, bulk_transport_chunk_size: usize) -> Result<usize> {
        let realm_id = 0; // HACK
        syscall::declare(realm_id, spec.len())?;
        let mut bulk_transport = bulk_transport_spec.open()?;
        bulk_transport.send_spec(realm_id, spec, bulk_transport_chunk_size)?;
        syscall::realize(realm_id)?;
        Ok(realm_id)
    }
}
