use alloc::vec;
use alloc::vec::Vec;
use core::convert::TryInto;

use crate::sys;

#[derive(Clone, Debug)]
pub struct BootInfo {
    pub bootinfo: &'static sys::seL4_BootInfo,
    pub extra: Vec<BootInfoExtraStructure>,
}

#[derive(Clone, Debug)]
pub struct BootInfoExtraStructure {
    pub id: BootInfoExtraStructureId,
    pub content: &'static [u8],
}

#[derive(Clone, Debug)]
pub enum BootInfoExtraStructureId {
    Fdt,
}

impl BootInfo {
    pub unsafe fn from_ptr(ptr: *const sys::seL4_BootInfo) -> Self {
        let bootinfo: &sys::seL4_BootInfo = &*ptr;
        let mut extra = vec![];
        let mut extra_start = (ptr as *const u8).offset(4096);
        let extra_end = extra_start.offset(bootinfo.extraLen.try_into().unwrap());
        while extra_start < extra_end {
            let header = &*(extra_start as *const sys::seL4_BootInfoHeader);
            let cur_start = extra_start.offset(
                core::mem::size_of::<sys::seL4_BootInfoHeader>()
                    .try_into()
                    .unwrap(),
            );
            let cur_end = extra_start.offset(header.len.try_into().unwrap());
            let id = match header.id.try_into().unwrap() {
                sys::SEL4_BOOTINFO_HEADER_PADDING => None,
                sys::SEL4_BOOTINFO_HEADER_FDT => Some(BootInfoExtraStructureId::Fdt),
                _ => panic!(),
            };
            if let Some(id) = id {
                extra.push(BootInfoExtraStructure {
                    id,
                    content: core::slice::from_raw_parts(
                        cur_start,
                        cur_end.offset_from(cur_start).try_into().unwrap(),
                    ),
                });
            }
            extra_start = cur_end;
        }
        assert_eq!(extra_start, extra_end);
        Self { bootinfo, extra }
    }
}
