use alloc::prelude::v1::*;
use core::iter;

use crate::types::*;
use crate::utils::align_up;

struct Strings {
    buf: Vec<u8>,
}

impl Strings {
    fn new() -> Self {
        Self { buf: Vec::new() }
    }

    // TODO deduplicate strings
    fn insert(&mut self, s: &str) -> u32 {
        let offset = self.buf.len();
        self.buf.extend(s.as_bytes());
        self.buf.push(0);
        offset as u32
    }
}

struct Writer {
    buf: Vec<u8>,
}

impl Writer {
    fn new() -> Self {
        Self { buf: Vec::new() }
    }

    fn pad(&mut self, n: usize) {
        self.buf.extend(iter::repeat(0).take(n));
    }

    fn align(&mut self, n: usize) {
        self.pad(align_up(self.buf.len(), n) - self.buf.len())
    }

    fn write(&mut self, bytes: &[u8]) {
        self.buf.extend(bytes);
    }

    fn write_be_u32(&mut self, v: u32) {
        self.write(&v.to_be_bytes());
    }

    fn write_be_u64(&mut self, v: u64) {
        self.write(&v.to_be_bytes());
    }

    fn write_header(&mut self, header: &Header) {
        self.write_be_u32(header.magic);
        self.write_be_u32(header.totalsize);
        self.write_be_u32(header.off_dt_struct);
        self.write_be_u32(header.off_dt_strings);
        self.write_be_u32(header.off_mem_rsvmap);
        self.write_be_u32(header.version);
        self.write_be_u32(header.last_comp_version);
        self.write_be_u32(header.boot_cpuid_phys);
        self.write_be_u32(header.size_dt_strings);
        self.write_be_u32(header.size_dt_struct);
    }

    fn write_mem_rsvmap(&mut self, mem_rsvmap: &[ReserveEntry]) {
        for entry in mem_rsvmap {
            self.write_be_u64(entry.address);
            self.write_be_u64(entry.size);
        }
        self.write_be_u64(0);
        self.write_be_u64(0);
    }

    fn write_node(&mut self, strings: &mut Strings, name: &str, node: &Node) {
        self.write_be_u32(TOK_BEGIN_NODE);
        self.write(name.as_bytes());
        self.write(&[0]);
        self.align(4);
        for (k, v) in &node.properties {
            self.write_be_u32(TOK_PROP);
            self.write_be_u32(v.raw.len() as u32);
            self.write_be_u32(strings.insert(k));
            self.write(&v.raw);
            self.align(4);
        }
        for (k, child) in &node.children {
            self.write_node(strings, k, child);
        }
        self.write_be_u32(TOK_END_NODE);
    }
}

impl DeviceTree {
    pub fn write(&self) -> Vec<u8> {
        let mut mem_rsvmap = Writer::new();
        mem_rsvmap.write_mem_rsvmap(&self.mem_rsvmap);
        let mem_rsvmap = mem_rsvmap.buf;

        let mut strings = Strings::new();
        let mut root = Writer::new();
        root.write_node(&mut strings, "", &self.root);
        root.write_be_u32(TOK_END);
        let root = root.buf;
        let strings = strings.buf;

        let mut w = Writer::new();
        w.pad(HEADER_SIZE);
        w.align(8);
        let off_mem_rsvmap = w.buf.len() as u32;
        w.write(&mem_rsvmap);
        w.align(4);
        let size_dt_struct = root.len() as u32;
        let off_dt_struct = w.buf.len() as u32;
        w.write(&root);
        w.align(4);
        let size_dt_strings = strings.len() as u32;
        let off_dt_strings = w.buf.len() as u32;
        w.write(&strings);
        let totalsize = w.buf.len() as u32;

        let mut header = Writer::new();
        header.write_header(&Header {
            magic: MAGIC,
            totalsize,
            off_dt_struct,
            off_dt_strings,
            off_mem_rsvmap,
            version: VERSION,
            last_comp_version: LAST_COMP_VERSION,
            boot_cpuid_phys: self.boot_cpuid_phys,
            size_dt_strings,
            size_dt_struct,
        });
        let header = header.buf;

        w.buf[..HEADER_SIZE].copy_from_slice(&header);
        w.buf
    }
}
