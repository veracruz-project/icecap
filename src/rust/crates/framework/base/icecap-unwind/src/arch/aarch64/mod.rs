use alloc::vec::Vec;
use core::iter::ExactSizeIterator;
use fallible_iterator::FallibleIterator;
use gimli::{
    UnwindSection, UnwindTable, UnwindTableRow,
    BaseAddresses, UninitializedUnwindContext, Pointer, CfaRule, RegisterRule,
    Reader, EndianSlice, NativeEndian,
    EhFrame, EhFrameHdr, ParsedEhFrameHdr,
};

use crate::{EhRef, find_cfi_sections};
use registers::{Registers, DwarfRegister};

mod glue;
mod registers;

pub struct StackFrame {
    pub personality: Option<u64>,
    pub lsda: Option<u64>,
    pub initial_address: u64,
    pub caller: u64,
}

pub struct StackFrames<'a> {
    unwinder: &'a mut DwarfUnwinder,
    registers: Registers,
    state: Option<(UnwindTableRow<StaticReader>, u64)>,
}

pub trait Unwinder: Default {
    fn trace<F>(&mut self, f: F) where F: FnMut(&mut StackFrames);
}

type StaticReader = EndianSlice<'static, NativeEndian>;

struct ObjectRecord {
    er: EhRef,
    eh_frame_hdr: ParsedEhFrameHdr<StaticReader>,
    eh_frame: EhFrame<StaticReader>,
    bases: BaseAddresses,
}

pub struct DwarfUnwinder {
    cfi: Vec<ObjectRecord>,
    ctx: Option<UninitializedUnwindContext<StaticReader>>,
}

impl Default for DwarfUnwinder {
    fn default() -> DwarfUnwinder {
        let cfi = find_cfi_sections().into_iter().map(|er| {
            unsafe {
                // TODO: set_got()
                let bases = BaseAddresses::default()
                    .set_eh_frame_hdr(er.eh_frame_hdr.start as u64)
                    .set_text(er.text.start as u64);

                let eh_frame_hdr: &'static [u8] = core::slice::from_raw_parts(er.eh_frame_hdr.start as *const u8, er.eh_frame_hdr.len());
                let eh_frame_hdr = EhFrameHdr::new(eh_frame_hdr, NativeEndian).parse(&bases, 8).unwrap();

                let eh_frame_addr = deref_ptr(eh_frame_hdr.eh_frame_ptr()) as usize;
                let eh_frame_sz = er.eh_frame_end - eh_frame_addr;

                let eh_frame: &'static [u8] = core::slice::from_raw_parts(eh_frame_addr as *const u8, eh_frame_sz);
                let eh_frame = EhFrame::new(eh_frame, NativeEndian);

                let bases = bases.set_eh_frame(eh_frame_addr as u64);

                ObjectRecord { er, eh_frame_hdr, eh_frame, bases }
            }
        }).collect();

        DwarfUnwinder {
            cfi,
            ctx: Some(UninitializedUnwindContext::new()),
        }
    }
}

pub struct UnwindPayload<'a> {
    unwinder: &'a mut DwarfUnwinder,
    tracer: &'a mut dyn FnMut(&mut StackFrames),
}

impl Unwinder for DwarfUnwinder {
    fn trace<F>(&mut self, mut f: F) where F: FnMut(&mut StackFrames) {
        let mut payload = UnwindPayload {
            unwinder: self,
            tracer: &mut f,
        };

        unsafe { glue::unwind_trampoline(&mut payload) };
    }
}


struct UnwindInfo<R: Reader> {
    row: UnwindTableRow<R>,
    personality: Option<Pointer>,
    lsda: Option<Pointer>,
    initial_address: u64,
}

impl ObjectRecord {
    fn unwind_info_for_address(
        &self,
        ctx: &mut UninitializedUnwindContext<StaticReader>,
        address: u64,
    ) -> gimli::Result<UnwindInfo<StaticReader>> {
        let &ObjectRecord {
            ref eh_frame_hdr,
            ref eh_frame,
            ref bases,
            ..
        } = self;

        let fde = eh_frame_hdr.table().unwrap()
            .fde_for_address(eh_frame, bases, address, EhFrame::cie_from_offset)?;
        let mut result_row = None;
        {
            let mut table = UnwindTable::new(eh_frame, bases, ctx, &fde)?;
            while let Some(row) = table.next_row()? {
                if row.contains(address) {
                    result_row = Some(row.clone());
                    break;
                }
            }
        }

        match result_row {
            Some(row) => Ok(UnwindInfo {
                row,
                personality: fde.personality(),
                lsda: fde.lsda(),
                initial_address: fde.initial_address(),
            }),
            None => Err(gimli::Error::NoUnwindInfoForAddress)
        }
    }
}

unsafe fn deref_ptr(ptr: Pointer) -> u64 {
    match ptr {
        Pointer::Direct(x) => x,
        Pointer::Indirect(x) => *(x as *const u64),
    }
}

impl<'a> FallibleIterator for StackFrames<'a> {
    type Item = StackFrame;
    type Error = gimli::Error;

    fn next(&mut self) -> Result<Option<StackFrame>, Self::Error> {
        let registers = &mut self.registers;

        if let Some((row, cfa)) = self.state.take() {
            let mut newregs = registers.clone();
            newregs[DwarfRegister::IP] = None;
            for &(reg, ref rule) in row.registers() {
                assert!(reg != DwarfRegister::SP); // stack = cfa
                newregs[reg] = match *rule {
                    RegisterRule::Undefined => unreachable!(), // registers[reg],
                    RegisterRule::SameValue => Some(registers[reg].unwrap()), // not sure why this exists
                    RegisterRule::Register(r) => registers[r],
                    RegisterRule::Offset(n) => Some(unsafe { *((cfa.wrapping_add(n as u64)) as *const u64) }),
                    RegisterRule::ValOffset(n) => Some(cfa.wrapping_add(n as u64)),
                    RegisterRule::Expression(_) => unimplemented!(),
                    RegisterRule::ValExpression(_) => unimplemented!(),
                    RegisterRule::Architectural => unreachable!(),
                };
            }
            newregs[DwarfRegister::SP] = Some(cfa);

            *registers = newregs;
        }


        if let Some(mut caller) = registers[DwarfRegister::IP] {
            // HACK
            if caller == 0 {
                return Ok(None)
            }
            caller -= 1; // THIS IS NECESSARY

            let rec = self.unwinder.cfi.iter().filter(|x| x.er.text.contains(&(caller as usize))).next().ok_or(gimli::Error::NoUnwindInfoForAddress)?;

            let mut ctx = self.unwinder.ctx.take().unwrap_or_else(UninitializedUnwindContext::new);
            let UnwindInfo { row, personality, lsda, initial_address } = rec.unwind_info_for_address(&mut ctx, caller)?;
            self.unwinder.ctx = Some(ctx);

            let cfa = match *row.cfa() {
                CfaRule::RegisterAndOffset { register, offset } =>
                    registers[register].unwrap().wrapping_add(offset as u64),
                _ => unimplemented!(),
            };

            self.state = Some((row, cfa));

            Ok(Some(StackFrame {
                personality: personality.map(|x| unsafe { deref_ptr(x) }),
                lsda: lsda.map(|x| unsafe { deref_ptr(x) }),
                initial_address,
                caller,
            }))
        } else {
            Ok(None)
        }
    }
}
