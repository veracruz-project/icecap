use std::env;
use std::fs::{self, OpenOptions};
use std::io::{Read, Write};
use std::net::{SocketAddr, TcpStream};
use std::path::{Path, PathBuf};

pub use icecap_caput_types::Message;

use crate::{Result, bail};

const BULK_TRANSPORT_ENV: &str = "ICECAP_BULK_TRANSPORT";

pub trait ReadWrite: Read + Write {}

impl<T> ReadWrite for T where T: Read + Write {}

pub struct BulkTransport(Box<dyn ReadWrite + Send>);

impl BulkTransport {

    pub fn send_msg(&mut self, msg: &Message) -> Result<()> {
        let (hdr, msg) = msg.mk_with_header();
        self.0.write_all(&hdr)?;
        self.0.write_all(&msg)?;
        self.0.flush()?;
        Ok(())
    }

    pub fn send_content(&mut self, content: &[u8]) -> Result<()> {
        let hdr = Message::mk_content_header(content);
        self.0.write_all(&hdr)?;
        self.0.write_all(content)?;
        self.0.flush()?;
        Ok(())
    }

    pub fn send_spec(&mut self, realm_id: usize, spec: &[u8], chunk_size: usize) -> Result<()> {
        for (i, chunk) in spec.chunks(chunk_size).enumerate() {
            let offset = i * chunk_size;
            self.send_msg(&Message::SpecChunk { realm_id, offset })?;
            self.send_content(chunk)?;
        }
        Ok(())
    }

    pub fn send_spec_from_file(&mut self, realm_id: usize, path: &impl AsRef<Path>, chunk_size: usize) -> Result<()> {
        let spec = fs::read(path)?;
        self.send_spec(realm_id, &spec, chunk_size)
    }

}

pub enum BulkTransportSpec {
    TCP(SocketAddr),
    File(PathBuf),
}

impl BulkTransportSpec {

    pub fn parse(s: &str) -> Result<Self> {
        let it: Vec<&str> = s.splitn(2, ":").collect();
        if it.len() != 2 {
            bail!("")
        }
        Ok(match it[0] {
            "tcp" => {
                BulkTransportSpec::TCP(it[1].parse()?)
            }
            "file" => {
                BulkTransportSpec::File(PathBuf::from(it[1]))
            }
            _ => {
                bail!("")
            }
        })
    }

    pub fn open(&self) -> Result<BulkTransport> {
        Ok(BulkTransport(match self {
            Self::TCP(addr) => {
                Box::new(TcpStream::connect(addr)?)
            }
            Self::File(path) => {
                Box::new(OpenOptions::new().read(true).write(true).open(path)?)
            }
        }))
    }

    pub fn env_at(k: &str) -> Result<Self> {
        let s = env::var(k)?;
        Self::parse(&s)
    }

    pub fn env() -> Result<Self> {
        Self::env_at(BULK_TRANSPORT_ENV)
    }
}
