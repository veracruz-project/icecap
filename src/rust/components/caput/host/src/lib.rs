use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{Read, Write};
use std::mem::size_of;
use std::net::{SocketAddr, TcpStream};
use std::path::{Path, PathBuf};
use std::result;
use std::sync::Mutex;
use std::error::Error;
use std::fmt;

use libc::{syscall, c_long};

pub use icecap_caput_types::{Message, calls};

pub const SYS_ICECAP: c_long = 436;

pub enum Endpoint {
    TCP(SocketAddr),
    File(PathBuf),
}

impl Endpoint {

    pub fn parse(s: &str) -> Option<Self> {
        let it: Vec<&str> = s.splitn(2, ":").collect();
        if it.len() != 2 {
            return None
        }
        Some(match it[0] {
            "tcp" => {
                Endpoint::TCP(it[1].parse().ok()?)
            }
            "file" => {
                Endpoint::File(PathBuf::from(it[1]))
            }
            _ => {
                return None
            }
        })
    }

}

const ENDPOINT_ENV: &str = "CAPUT_ENDPOINT";

trait ReadWrite: Read + Write {}

impl<T> ReadWrite for T where T: Read + Write {}

pub struct Host {
    endpoint: Mutex<Box<dyn ReadWrite + Send>>,
}

type Result<T> = std::result::Result<T, Box<dyn Error>>;

#[derive(Debug)]
struct LameError {
    msg: String,
}

impl fmt::Display for LameError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.msg)
    }
}

impl Error for LameError {}

impl LameError {
    pub fn new(msg: String) -> Self {
        Self { msg }
    }
}

#[macro_export]
macro_rules! format_err {
    ($($arg:tt)*) => { $crate::LameError::new(std::format!($($arg)*)) }
}

impl Host {

    pub fn new(endpoint: Endpoint) -> Result<Self> {
        let endpoint: Box<dyn ReadWrite + Send> = match endpoint {
            Endpoint::TCP(addr) => {
                Box::new(TcpStream::connect(addr)?)
            }
            Endpoint::File(path) => {
                Box::new(OpenOptions::new().read(true).write(true).open(path)?)
            }
        };
        Ok(Self {
            endpoint: Mutex::new(endpoint),
        })
    }

    pub fn from_str(s: &str) -> Result<Self> {
        Self::new(Endpoint::parse(&s).ok_or(format_err!("invalid caput endpoint: {}", s))?)
    }

    pub fn env_at(k: &str) -> Result<Self> {
        let s = env::var(k)?;
        Self::from_str(&s)
    }

    pub fn env() -> Result<Self> {
        Self::env_at(ENDPOINT_ENV)
    }

    pub fn send_msg(&self, msg: &Message) -> Result<()> {
        let (hdr, msg) = msg.mk_with_header();
        let mut endpoint = self.endpoint.lock().unwrap();
        endpoint.write_all(&hdr)?;
        endpoint.write_all(&msg)?;
        endpoint.flush()?;
        Ok(())
    }

    pub fn send_content(&self, content: &[u8]) -> Result<()> {
        let hdr = Message::mk_content_header(content);
        let mut endpoint = self.endpoint.lock().unwrap();
        endpoint.write_all(&hdr)?;
        endpoint.write_all(content)?;
        endpoint.flush()?;
        Ok(())
    }

    pub fn send_spec(&self, realm_id: usize, spec: &[u8], chunk_size: usize) -> Result<()> {
        for (i, chunk) in spec.chunks(chunk_size).enumerate() {
            let offset = i * chunk_size;
            self.send_msg(&Message::SpecChunk { realm_id, offset })?;
            self.send_content(chunk)?;
        }
        Ok(())
    }

    pub fn send_spec_from_file(&self, realm_id: usize, path: &impl AsRef<Path>, chunk_size: usize) -> Result<()> {
        let spec = fs::read(path)?;
        self.send_spec(realm_id, &spec, chunk_size)
    }

    pub fn declare(&self, spec_size: usize) -> Result<usize> {
        println!("declare");
        Ok(unsafe {
            syscall(SYS_ICECAP, spec_size as c_long, 0, 0, 0, calls::DECLARE as c_long, 2)
        } as usize)
    }

    pub fn realize(&self, realm_id: usize, num_nodes: usize) -> Result<()> {
        unsafe {
            syscall(SYS_ICECAP, realm_id as c_long, num_nodes as c_long, 0, 0, calls::REALIZE as c_long, 3)
        };
        Ok(())
    }

    pub fn run(&self, spec: &[u8], num_nodes: usize, chunk_size: usize) -> Result<()> {
        let realm_id = self.declare(spec.len())?;
        self.send_spec(realm_id, spec, chunk_size)?;
        self.realize(realm_id, num_nodes)?;
        Ok(())
    }
}
