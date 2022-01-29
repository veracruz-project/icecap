use std::error::Error;
use std::result;

use dyndl_types::*;
use hypervisor_host_vmm_types::{DirectRequest, DirectResponse};

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
        let (model, fill_content): (Model, &[u8]) = postcard::take_from_bytes(&spec).unwrap();
        let model_size = spec.len() - fill_content.len();

        syscall::declare(realm_id, model_size);

        let mut bulk_transport = BulkTransport::open()?;
        bulk_transport.send_spec(realm_id, &spec[..model_size], bulk_transport_chunk_size)?;

        syscall::realize_start(realm_id);

        let mut acc = vec![];
        let mut offset = 0;
        for (i, obj) in model.objects.iter().enumerate() {
            if let AnyObj::Local(obj) = &obj.object {
                if let Some(fill) = match obj {
                    Obj::SmallPage(frame) => Some(&frame.fill),
                    Obj::LargePage(frame) => Some(&frame.fill),
                    _ => None,
                } {
                    for (j, entry) in fill.iter().enumerate() {
                        let content = &fill_content[offset..offset + entry.length];
                        let header =
                            postcard::to_allocvec(&hypervisor_resource_server_types::FillChunkHeader {
                                object_index: i,
                                fill_entry_index: j,
                                size: content.len(),
                            })
                            .unwrap();
                        let size = header.len() + content.len();
                        if acc.len() + size > bulk_transport_chunk_size {
                            bulk_transport.send_fill(realm_id, &acc)?;
                            acc.clear();
                        }
                        acc.extend_from_slice(&header);
                        acc.extend_from_slice(content);
                        offset = offset + entry.length;
                    }
                }
            }
        }
        assert!(acc.len() <= bulk_transport_chunk_size);
        bulk_transport.send_fill(realm_id, &acc)?;

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
