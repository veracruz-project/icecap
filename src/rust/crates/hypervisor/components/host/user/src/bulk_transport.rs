use std::fs::{self, File, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

use crate::{
    syscall::{fill_chunks, spec_chunk},
    Result,
};

const BULK_TRANSPORT_PATH: &str = "/dev/resource_server";

pub struct BulkTransport(File);

impl BulkTransport {
    pub fn open() -> Result<Self> {
        Ok(Self(
            OpenOptions::new()
                .read(true)
                .write(true)
                .open(PathBuf::from(BULK_TRANSPORT_PATH))?,
        ))
    }

    pub fn send(&mut self, bytes: &[u8]) -> Result<()> {
        self.0.write_all(bytes)?;
        self.0.flush()?;
        Ok(())
    }

    pub fn send_spec(&mut self, realm_id: usize, spec: &[u8], chunk_size: usize) -> Result<()> {
        for (i, chunk) in spec.chunks(chunk_size).enumerate() {
            let offset = i * chunk_size;
            self.send(chunk)?;
            spec_chunk(realm_id, 0, chunk.len(), offset);
        }
        Ok(())
    }

    pub fn send_spec_from_file(
        &mut self,
        realm_id: usize,
        path: &impl AsRef<Path>,
        chunk_size: usize,
    ) -> Result<()> {
        let spec = fs::read(path)?;
        self.send_spec(realm_id, &spec, chunk_size)
    }

    pub fn send_fill(
        &mut self,
        realm_id: usize,
        content: &[u8],
    ) -> Result<()> {
        self.send(content)?;
        fill_chunks(realm_id, 0, content.len());
        Ok(())
    }
}
