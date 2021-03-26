use std::{
    io, env, fs,
};

use icecap_host_core::*;

// TODO use proper CLI framework
fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    let host = &args[1];
    let spec_path = &args[2];
    let spec = fs::read(spec_path)?;
    let bulk_transport_spec = BulkTransportSpec::parse(&host).unwrap();
    let bulk_transport_chunk_size: usize = 4096 * 64;
    let mut host = Host::new().unwrap();
    let realm_id = host.create_realm(&spec, &bulk_transport_spec, bulk_transport_chunk_size).unwrap();
    Ok(())
}
