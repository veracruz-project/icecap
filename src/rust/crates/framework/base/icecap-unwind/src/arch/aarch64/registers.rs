use core::fmt;
use core::ops::{Index, IndexMut};

#[derive(Default, Clone, PartialEq, Eq)]
pub struct Registers {
    registers: [Option<u64>; 32],
}

impl fmt::Debug for Registers {
    fn fmt(&self, fmtr: &mut fmt::Formatter) -> fmt::Result {
        for reg in &self.registers {
            match *reg {
                None => write!(fmtr, " XXX")?,
                Some(x) => write!(fmtr, " 0x{:x}", x)?,
            }
        }
        Ok(())
    }
}

impl Index<u16> for Registers {
    type Output = Option<u64>;

    fn index(&self, index: u16) -> &Option<u64> {
        &self.registers[index as usize]
    }
}

impl IndexMut<u16> for Registers {
    fn index_mut(&mut self, index: u16) -> &mut Option<u64> {
        &mut self.registers[index as usize]
    }
}

impl Index<gimli::Register> for Registers {
    type Output = Option<u64>;

    fn index(&self, reg: gimli::Register) -> &Option<u64> {
        &self[reg.0]
    }
}

impl IndexMut<gimli::Register> for Registers {
    fn index_mut(&mut self, reg: gimli::Register) -> &mut Option<u64> {
        &mut self[reg.0]
    }
}

#[allow(dead_code)]
#[allow(non_snake_case)]
pub mod DwarfRegister {
    pub const X0: gimli::Register = gimli::Register(0);
    pub const X1: gimli::Register = gimli::Register(1);
    pub const X2: gimli::Register = gimli::Register(2);
    pub const X3: gimli::Register = gimli::Register(3);
    pub const X4: gimli::Register = gimli::Register(4);
    pub const X5: gimli::Register = gimli::Register(5);
    pub const X6: gimli::Register = gimli::Register(6);
    pub const X7: gimli::Register = gimli::Register(7);
    pub const X8: gimli::Register = gimli::Register(8);
    pub const X9: gimli::Register = gimli::Register(9);
    pub const X10: gimli::Register = gimli::Register(10);
    pub const X11: gimli::Register = gimli::Register(11);
    pub const X12: gimli::Register = gimli::Register(12);
    pub const X13: gimli::Register = gimli::Register(13);
    pub const X14: gimli::Register = gimli::Register(14);
    pub const X15: gimli::Register = gimli::Register(15);
    pub const X16: gimli::Register = gimli::Register(16);
    pub const X17: gimli::Register = gimli::Register(17);
    pub const X18: gimli::Register = gimli::Register(18);
    pub const X19: gimli::Register = gimli::Register(19);
    pub const X20: gimli::Register = gimli::Register(20);
    pub const X21: gimli::Register = gimli::Register(21);
    pub const X22: gimli::Register = gimli::Register(22);
    pub const X23: gimli::Register = gimli::Register(23);
    pub const X24: gimli::Register = gimli::Register(24);
    pub const X25: gimli::Register = gimli::Register(25);
    pub const X26: gimli::Register = gimli::Register(26);
    pub const X27: gimli::Register = gimli::Register(27);
    pub const X28: gimli::Register = gimli::Register(28);
    pub const X29: gimli::Register = gimli::Register(29);
    pub const IP: gimli::Register = gimli::Register(30);
    pub const SP: gimli::Register = gimli::Register(31);
}
