use std::{
    io, env, fs,
};

use icecap_caput_host::{Host, Message};

// TODO use proper CLI framework
fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    let host = &args[1];
    let spec_path = &args[2];
    let spec = fs::read(spec_path)?;
    let host = Host::from_str(&host).unwrap();
    const CHUNK_SIZE: usize = 4096 * 64 - Message::HEADER_SIZE;
    host.send_spec(&spec, CHUNK_SIZE).unwrap();
    Ok(())
}
