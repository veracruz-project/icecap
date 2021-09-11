use core::mem;

use super::IRQ;

// Used to identify a register number.  No register type exceeds 255 registers.
type IRQRegNum = usize;

// Used to identify a byte offset in a 32 bit register.
type IRQRegByte = usize;

// Enumerate each of the GIC Distributor registers that are word-accessible
#[derive(Debug)]
#[allow(non_camel_case_types)]
pub enum GICDistRegWord {
    GICD_CTLR,
    GICD_TYPER,
    GICD_IIDR,
    GICD_IGROUPRn(IRQRegNum),
    GICD_ISENABLERn(IRQRegNum),
    GICD_ICENABLERn(IRQRegNum),
    GICD_ISPENDRn(IRQRegNum),
    GICD_ICPENDRn(IRQRegNum),
    GICD_ISACTIVERn(IRQRegNum),
    GICD_ICACTIVERn(IRQRegNum),
    GICD_IPRIORITYRn(IRQRegNum),
    GICD_ITARGETSRn(IRQRegNum),
    GICD_ICFGRn(IRQRegNum),
    GICD_NSACRn(IRQRegNum),
    GICD_SGIR,
    GICD_CPENDSGIRn(IRQRegNum),
    GICD_SPENDSGIRn(IRQRegNum),
    ICCIDRn(IRQRegNum),
    ICPIDRn(IRQRegNum),
}

impl GICDistRegWord {
    pub fn from_offset(offset: usize) -> Self {
        match offset {
            0x000 => GICDistRegWord::GICD_CTLR,
            0x004 => GICDistRegWord::GICD_TYPER,
            0x008 => GICDistRegWord::GICD_IIDR,
            0x080..=0x0FC => GICDistRegWord::GICD_IGROUPRn(calc_reg_num(offset, 0x080)),
            0x100..=0x17C => GICDistRegWord::GICD_ISENABLERn(calc_reg_num(offset, 0x100)),
            0x180..=0x1FC => GICDistRegWord::GICD_ICENABLERn(calc_reg_num(offset, 0x180)),
            0x200..=0x27C => GICDistRegWord::GICD_ISPENDRn(calc_reg_num(offset, 0x200)),
            0x280..=0x2FC => GICDistRegWord::GICD_ICPENDRn(calc_reg_num(offset, 0x280)),
            0x300..=0x37C => GICDistRegWord::GICD_ISACTIVERn(calc_reg_num(offset, 0x300)),
            0x380..=0x3FC => GICDistRegWord::GICD_ICACTIVERn(calc_reg_num(offset, 0x380)),
            0x400..=0x7F8 => GICDistRegWord::GICD_IPRIORITYRn(calc_reg_num(offset, 0x400)),
            0x800..=0xBF8 => GICDistRegWord::GICD_ITARGETSRn(calc_reg_num(offset, 0x800)),
            0xC00..=0xCFC => GICDistRegWord::GICD_ICFGRn(calc_reg_num(offset, 0xC00)),
            0xE00..=0xEFC => GICDistRegWord::GICD_NSACRn(calc_reg_num(offset, 0xE00)),
            0xF00 => GICDistRegWord::GICD_SGIR,
            0xF10..=0xF1C => GICDistRegWord::GICD_CPENDSGIRn(calc_reg_num(offset, 0xF10)),
            0xF20..=0xF2C => GICDistRegWord::GICD_SPENDSGIRn(calc_reg_num(offset, 0xF20)),
            0xFD0..=0xFEC => GICDistRegWord::ICPIDRn(calc_reg_num(offset, 0xFD0)),
            0xFF0..=0xFFC => GICDistRegWord::ICCIDRn(calc_reg_num(offset, 0xFF0)),
            _ => panic!("Undefined register offset {:x}", offset)
        }
    }
}

// Enumerate each of the GIC Distributor registers that are byte-accessible
#[derive(Debug)]
#[allow(non_camel_case_types)]
pub enum GICDistRegByte {
    GICD_IPRIORITYRn(IRQRegNum, IRQRegByte),
    GICD_ITARGETSRn(IRQRegNum, IRQRegByte),
    GICD_CPENDSGIRn(IRQRegNum, IRQRegByte),
    GICD_SPENDSGIRn(IRQRegNum, IRQRegByte),
}

impl GICDistRegByte {
    pub fn from_offset(offset: usize) -> Self {
        match offset {
            0x400..=0x7F8 => GICDistRegByte::GICD_IPRIORITYRn(
                calc_reg_num(offset, 0x400),
                calc_reg_byte_offset(offset, 0x400)
                ),
            0x800..=0xBF8 => GICDistRegByte::GICD_ITARGETSRn(
                calc_reg_num(offset, 0x800),
                calc_reg_byte_offset(offset, 0x800)
                ),
            0xF10..=0xF1C => GICDistRegByte::GICD_CPENDSGIRn(
                calc_reg_num(offset, 0xF10),
                calc_reg_byte_offset(offset, 0xF10)
                ),
            0xF20..=0xF2C => GICDistRegByte::GICD_SPENDSGIRn(
                calc_reg_num(offset, 0xF20),
                calc_reg_byte_offset(offset, 0xF20)
                ),
            _ => panic!("Undefined register offset {:x}", offset)
        }
    }
}

fn calc_reg_num(offset: usize, base: usize) -> IRQRegNum {
    let reg_num = (offset - base) / mem::size_of::<u32>();
    assert!(reg_num < 256);
    reg_num
}

fn calc_reg_byte_offset(offset: usize, base: usize) -> IRQRegByte {
    let reg_byte = (offset - base) % mem::size_of::<u32>();
    assert!(reg_byte < mem::size_of::<u32>());
    reg_byte
}

// Converts bits in an IRQ register to a vector if IRQ values.
// fn reg_word_to_irqs(reg_num: IRQRegNum, irq_bits: u32) -> Vec<IRQ> {
//     let mut irqs: Vec<IRQ> = Vec::new();
//     for i in biterate(irq_bits) {
//         let irq_num = (i as usize) + 32 * reg_num;
//         irqs.push(irq_num as IRQ)
//     }
//     irqs
// }
