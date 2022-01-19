use std::error::Error;
use std::result;

use dyndl_types::*;
use icecap_host_vmm_types::{DirectRequest, DirectResponse};

mod bulk_transport;
pub mod syscall;

pub use bulk_transport::BulkTransport;

pub type Result<T> = result::Result<T, Box<dyn Error>>;

pub struct Host {}

impl Host {
    pub fn new() -> Result<Self> {
        Ok(Self {})
    }

    pub fn create_realm(
        &mut self,
        realm_id: usize,
        spec: &[u8],
        bulk_transport_chunk_size: usize,
    ) -> Result<()> {
        syscall::declare(realm_id, spec.len());
        let mut bulk_transport = BulkTransport::open()?;
        bulk_transport.send_spec(realm_id, spec, bulk_transport_chunk_size)?;
        syscall::realize_start(realm_id);

        let (model, fill_content): (Model, &[u8]) = postcard::take_from_bytes(&spec).unwrap();
        let mut offset = 0;
        for (i, obj) in model.objects.iter().enumerate() {
            if let AnyObj::Local(obj) = &obj.object {
                match obj {
                    Obj::SmallPage(frame) => {
                        for (j, entry) in frame.fill.iter().enumerate() {
                            bulk_transport.send_fill(
                                realm_id,
                                i,
                                j,
                                &fill_content[offset..offset + entry.length],
                            )?;
                            offset = offset + entry.length;
                        }
                    }
                    Obj::LargePage(frame) => {
                        for (j, entry) in frame.fill.iter().enumerate() {
                            bulk_transport.send_fill(
                                realm_id,
                                i,
                                j,
                                &fill_content[offset..offset + entry.length],
                            )?;
                            offset = offset + entry.length;
                        }
                    }
                    _ => {}
                }
            }
        }

        syscall::realize_finish(realm_id);
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
            // std::thread::yield_now(); // TODO experiment with ways of yielding fuller time slices
            syscall::yield_to(realm_id, virtual_node);
        }
    }

    pub fn direct(&mut self, request: &DirectRequest) -> Result<DirectResponse> {
        Ok(syscall::direct(request))
    }
}
