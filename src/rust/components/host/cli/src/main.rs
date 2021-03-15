use std::{
    io, env, fs,
};

use icecap_host_core::{Host, Message};

// TODO use proper CLI framework
fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    let host = &args[1];
    let spec_path = &args[2];
    let spec = fs::read(spec_path)?;
    let num_nodes = 4; // TOOD
    let host = Host::from_str(&host).unwrap();
    const CHUNK_SIZE: usize = 4096 * 64;
    host.run(&spec, num_nodes, CHUNK_SIZE).unwrap();
    Ok(())
}
