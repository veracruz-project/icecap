use core::mem::size_of;
use alloc::prelude::v1::*;
use alloc::collections::BTreeMap;

use crate::align_up;
use crate::failure::{Fallible, bail, ensure, format_err};
use crate::types::*;

struct Cursor<'a> {
    buf: &'a [u8],
    i: usize,
}

impl<'a> Cursor<'a> {

    fn new(buf: &'a [u8]) -> Self {
        Self {
            buf,
            i: 0,
        }
    }

    fn advance(&mut self, n: usize) {
        self.i += n;
    }

    fn align(&mut self, n: usize) {
        self.i = align_up(self.i, n);
    }

    fn read(&mut self, n: usize) -> Fallible<&[u8]> {
        if let Some(sub) = self.buf.get(self.i .. self.i + n) {
            self.advance(n);
            Ok(sub)
        } else {
            bail!("read out of bounds: {}", n)
        }
    }

    fn read_value(&mut self, size: usize) -> Fallible<Value> {
        let v = Value::new(self.read(size)?.to_vec());
        self.align(4);
        Ok(v)
    }

    fn read_unit_name(&mut self) -> Fallible<&str> {
        let s = cstring_at(self.buf, self.i)?;
        self.advance(s.len() + 1); // '\0'
        self.align(4);
        Ok(s)
    }

    fn read_be_u32(&mut self) -> Fallible<u32> {
        const SIZE: usize = size_of::<u32>();
        let mut raw: [u8; SIZE] = [0; SIZE];
        raw.copy_from_slice(self.read(SIZE)?);
        Ok(u32::from_be_bytes(raw))
    }

    fn read_be_u64(&mut self) -> Fallible<u64> {
        const SIZE: usize = size_of::<u64>();
        let mut raw: [u8; SIZE] = [0; SIZE];
        raw.copy_from_slice(self.read(SIZE)?);
        Ok(u64::from_be_bytes(raw))
    }

    fn read_header(&mut self) -> Fallible<Header> {
        Ok(Header {
            magic: self.read_be_u32()?,
            totalsize: self.read_be_u32()?,
            off_dt_struct: self.read_be_u32()?,
            off_dt_strings: self.read_be_u32()?,
            off_mem_rsvmap: self.read_be_u32()?,
            version: self.read_be_u32()?,
            last_comp_version: self.read_be_u32()?,
            boot_cpuid_phys: self.read_be_u32()?,
            size_dt_strings: self.read_be_u32()?,
            size_dt_struct: self.read_be_u32()?,
        })
    }

    fn read_reserve_entry(&mut self) -> Fallible<ReserveEntry> {
        Ok(ReserveEntry {
            address: self.read_be_u64()?,
            size: self.read_be_u64()?,
        })
    }

    fn read_prop_header(&mut self) -> Fallible<PropHeader> {
        Ok(PropHeader {
            len: self.read_be_u32()?,
            name_off: self.read_be_u32()?,
        })
    }

    fn read_node(&mut self, strings: &Strings) -> Fallible<Node> {
        let mut properties = BTreeMap::new();
        let mut children = BTreeMap::new();
        loop {
            let tok = self.read_be_u32()?;
            match tok {
                TOK_NOP => {
                }
                TOK_PROP => {
                    let prop = self.read_prop_header()?;
                    let name = strings.get(prop.name_off)?.into();
                    let value = self.read_value(prop.len as usize)?;
                    properties.insert(name, value);
                }
                TOK_BEGIN_NODE => {
                    let name = self.read_unit_name()?.into();
                    let child = self.read_node(strings)?;
                    children.insert(name, Box::new(child));
                }
                TOK_END_NODE => {
                    break
                }
                _ => {
                    bail!("unexpected token: {:x}", tok)
                }
            }
        }
        Ok(Node {
            properties,
            children,
        })
    }

    fn read_mem_rsvmap(&mut self) -> Fallible<Vec<ReserveEntry>> {
        let mut v = vec![];
        loop {
            let entry = self.read_reserve_entry()?;
            if entry.address == 0 && entry.size == 0 {
                return Ok(v);
            }
            v.push(entry);
        }
    }
}

struct Strings<'a> {
    table: &'a [u8],
}

impl<'a> Strings<'a> {

    fn get(&self, offset: u32) -> Fallible<&str> {
        cstring_at(self.table, offset as usize)
    }

}

fn cstring_at(buf: &[u8], offset: usize) -> Fallible<&str> {
    let sub = buf.get(offset..).ok_or(format_err!("offset {} out of bounds", offset))?;
    let n = sub.iter().position(|&b| b == 0).ok_or(format_err!("no null byte"))?;
    Ok(core::str::from_utf8(&sub[..n])?)
}

impl DeviceTree {

    pub fn read(dtb: &[u8]) -> Fallible<Self> {

        let header = Cursor::new(dtb).read_header()?;
        ensure!(header.magic == MAGIC);
        ensure!(header.version == VERSION);
        ensure!(header.last_comp_version == LAST_COMP_VERSION);

        let mem_rsvmap = Cursor::new(&dtb[header.off_mem_rsvmap as usize..]).read_mem_rsvmap()?;

        let strings = Strings {
            table: &dtb[header.off_dt_strings as usize .. (header.off_dt_strings + header.size_dt_strings) as usize],
        };

        let mut cursor = Cursor::new(&dtb[header.off_dt_struct as usize .. (header.off_dt_struct + header.size_dt_struct) as usize]);

        let tok = cursor.read_be_u32()?;
        ensure!(tok == TOK_BEGIN_NODE);
        let name = cursor.read_unit_name()?;
        ensure!(name.len() == 0);
        let root = cursor.read_node(&strings)?;
        let tok = cursor.read_be_u32()?;
        ensure!(tok == TOK_END);

        Ok(Self {
            mem_rsvmap,
            root,
            boot_cpuid_phys: header.boot_cpuid_phys,
        })
    }
}
