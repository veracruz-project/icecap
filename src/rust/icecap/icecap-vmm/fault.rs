use icecap_sel4::prelude::*;

pub struct VMFault(pub sel4::VMFault);

#[derive(Copy, Clone, PartialEq)]
pub enum Width {
    DoubleWord,
    Word,
    HalfWord,
    Byte,
}

const HSR_SYNDROME_VALID: Word = 1 << 24;
const SRT_MASK: Word = 0x1f;

fn hsr_is_syndrome_valid(hsr: Word) -> bool {
    hsr & HSR_SYNDROME_VALID != 0
}

fn hsr_syndrome_width(x: Word) -> Word {
    (x >> 22) & 0x3
}

fn hsr_syndrome_rt(x: Word) -> Word {
    (x >> 16) & SRT_MASK
}

impl VMFault {

    pub fn get_data_mask(&self) -> Word {
        let addr = self.0.addr;
        let mask = match self.get_width() {
            Width::Byte => {
                assert!(addr & 0x0 == 0);
                0x000000ff
            }
            Width::HalfWord => {
                assert!(addr & 0x1 == 0);
                0x0000ffff
            }
            Width::Word | Width::DoubleWord => {
                assert!(addr & 0x3 == 0);
                0xffffffff
            }
        };
        mask << (addr & 0x3) * 8
    }

    pub fn get_width(&self) -> Width {
        assert!(hsr_is_syndrome_valid(self.0.fsr));
        match hsr_syndrome_width(self.0.fsr) {
            0 => Width::Byte,
            1 => Width::HalfWord,
            2 => Width::Word,
            _ => panic!(),
        }
    }

    pub fn get_data(&self, tcb: TCB) -> Word {
        // TODO see upstream fault_insn.c
        assert!(hsr_is_syndrome_valid(self.0.fsr));
        let rt = hsr_syndrome_rt(self.0.fsr);
        let regs = tcb.read_all_registers(false).unwrap();
        decode_rt(&regs, rt)
    }

    // TODO bit width
    pub fn emulate(&self, tcb: TCB, o: u32) -> u32 {
        assert!(self.get_width() == Width::Word);
        let s = (self.0.addr & 0x3) * 8;
        let m = self.get_data_mask() as u32;
        let n = self.get_data(tcb) as u32;
        if self.is_read() {
            (o & !(m >> s)) | ((n & m) >> s)
        } else {
            (o & !m) | ((n << s) & m)
        }
    }

    pub fn is_write(&self) -> bool {
        self.0.fsr & (1 << 6) != 0
    }

    pub fn is_read(&self) -> bool {
        !self.is_write()
    }
}

fn decode_rt(c: &UserContext, reg: Word) -> Word {
    match reg {
        0 => c.x0,
        1 => c.x1,
        2 => c.x2,
        3 => c.x3,
        4 => c.x4,
        5 => c.x5,
        6 => c.x6,
        7 => c.x7,
        8 => c.x8,
        9 => c.x9,
        10 => c.x10,
        11 => c.x11,
        12 => c.x12,
        13 => c.x13,
        14 => c.x14,
        15 => c.x15,
        16 => c.x16,
        17 => c.x17,
        18 => c.x18,
        19 => c.x19,
        20 => c.x20,
        21 => c.x21,
        22 => c.x22,
        23 => c.x23,
        24 => c.x24,
        25 => c.x25,
        26 => c.x26,
        27 => c.x27,
        28 => c.x28,
        29 => c.x29,
        30 => c.x30,
        31 => 0,
        _ => panic!(),
    }
}
