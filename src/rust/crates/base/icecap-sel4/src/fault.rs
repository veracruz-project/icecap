use crate::{reply, sys, MessageInfo, MessageRegister, UserContext, Word};

// TODO
// - use proper types in fault structs (e.g. signed for seL4_VGICMaintenance_IDX)

fn get(i: Word) -> Word {
    MessageRegister::new(i as i32).get()
}

pub trait IsFault {
    fn get() -> Self;
}

#[derive(Debug)]
pub struct NullFault {}

impl IsFault for NullFault {
    fn get() -> Self {
        Self {}
    }
}

#[derive(Debug)]
pub struct CapFault {
    pub ip: Word,
    pub addr: Word,
    pub in_recv_phase: Word,
    pub lookup_failure_type: Word,
    pub bits_left: Word,
    pub guard_mismatch_guard_found: Word,
    pub guard_mismatch_bits_found: Word,
}

impl IsFault for CapFault {
    fn get() -> Self {
        Self {
            ip: get(sys::seL4_CapFault_Msg_seL4_CapFault_IP),
            addr: get(sys::seL4_CapFault_Msg_seL4_CapFault_Addr),
            in_recv_phase: get(sys::seL4_CapFault_Msg_seL4_CapFault_InRecvPhase),
            lookup_failure_type: get(sys::seL4_CapFault_Msg_seL4_CapFault_LookupFailureType),
            bits_left: get(sys::seL4_CapFault_Msg_seL4_CapFault_BitsLeft),
            guard_mismatch_guard_found: get(
                sys::seL4_CapFault_Msg_seL4_CapFault_GuardMismatch_GuardFound,
            ),
            guard_mismatch_bits_found: get(
                sys::seL4_CapFault_Msg_seL4_CapFault_GuardMismatch_BitsFound,
            ),
        }
    }
}

#[derive(Debug)]
pub struct UnknownSyscall {
    pub x0: Word,
    pub x1: Word,
    pub x2: Word,
    pub x3: Word,
    pub x4: Word,
    pub x5: Word,
    pub x6: Word,
    pub x7: Word,
    pub fault_ip: Word,
    pub sp: Word,
    pub lr: Word,
    pub spsr: Word,
    pub syscall: Word,
}

impl IsFault for UnknownSyscall {
    fn get() -> Self {
        Self {
            x0: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X0),
            x1: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X1),
            x2: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X2),
            x3: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X3),
            x4: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X4),
            x5: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X5),
            x6: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X6),
            x7: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X7),
            fault_ip: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_FaultIP),
            sp: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_SP),
            lr: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_LR),
            spsr: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_SPSR),
            syscall: get(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_Syscall),
        }
    }
}

#[derive(Debug)]
pub struct UserException {
    pub fault_ip: Word,
    pub sp: Word,
    pub spsr: Word,
    pub number: Word,
    pub code: Word,
}

impl IsFault for UserException {
    fn get() -> Self {
        Self {
            fault_ip: get(sys::seL4_UserException_Msg_seL4_UserException_FaultIP),
            sp: get(sys::seL4_UserException_Msg_seL4_UserException_SP),
            spsr: get(sys::seL4_UserException_Msg_seL4_UserException_SPSR),
            number: get(sys::seL4_UserException_Msg_seL4_UserException_Number),
            code: get(sys::seL4_UserException_Msg_seL4_UserException_Code),
        }
    }
}

#[derive(Debug)]
pub struct VMFault {
    pub ip: Word,
    pub addr: Word,
    pub prefetch_fault: Word,
    pub fsr: Word,
}

impl VMFault {
    pub fn is_prefetch(&self) -> bool {
        self.prefetch_fault != 0
    }
}

impl IsFault for VMFault {
    fn get() -> Self {
        Self {
            ip: get(sys::seL4_VMFault_Msg_seL4_VMFault_IP),
            addr: get(sys::seL4_VMFault_Msg_seL4_VMFault_Addr),
            prefetch_fault: get(sys::seL4_VMFault_Msg_seL4_VMFault_PrefetchFault),
            fsr: get(sys::seL4_VMFault_Msg_seL4_VMFault_FSR),
        }
    }
}

#[derive(Debug)]
pub struct VGICMaintenance {
    pub idx: Option<Word>,
}

impl IsFault for VGICMaintenance {
    fn get() -> Self {
        Self {
            idx: match get(sys::seL4_VGICMaintenance_Msg_seL4_VGICMaintenance_IDX) {
                Word::MAX => None,
                idx => Some(idx),
            },
        }
    }
}

#[derive(Debug)]
pub struct VCPUFault {
    pub hsr: Word,
}

impl IsFault for VCPUFault {
    fn get() -> Self {
        Self {
            hsr: get(sys::seL4_VCPUFault_Msg_seL4_VCPUFault_HSR),
        }
    }
}

#[derive(Debug)]
pub struct VPPIEvent {
    pub irq: Word,
}

impl IsFault for VPPIEvent {
    fn get() -> Self {
        Self {
            irq: get(sys::seL4_VPPIEvent_Msg_seL4_VPPIEvent_IRQ),
        }
    }
}

#[derive(Debug)]
pub enum Fault {
    NullFault(NullFault),
    CapFault(CapFault),
    UnknownSyscall(UnknownSyscall),
    UserException(UserException),
    VMFault(VMFault),
    VGICMaintenance(VGICMaintenance),
    VCPUFault(VCPUFault),
    VPPIEvent(VPPIEvent),
}

impl Fault {
    pub fn get(tag: MessageInfo) -> Fault {
        match tag.label() as u32 {
            sys::seL4_Fault_tag_seL4_Fault_NullFault => {
                // TODO
                // assert!(tag.length() == sys::seL4_NullFault_Length);
                Fault::NullFault(NullFault::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_CapFault => {
                // TODO
                // assert!(tag.length() == sys::seL4_CapFault_Length);
                Fault::CapFault(CapFault::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_UnknownSyscall => {
                assert!(tag.length() == sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_Length);
                Fault::UnknownSyscall(UnknownSyscall::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_UserException => {
                assert!(tag.length() == sys::seL4_UserException_Msg_seL4_UserException_Length);
                Fault::UserException(UserException::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_VMFault => {
                assert!(tag.length() == sys::seL4_VMFault_Msg_seL4_VMFault_Length);
                Fault::VMFault(VMFault::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_VGICMaintenance => {
                assert!(tag.length() == sys::seL4_VGICMaintenance_Msg_seL4_VGICMaintenance_Length);
                Fault::VGICMaintenance(VGICMaintenance::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_VCPUFault => {
                assert!(tag.length() == sys::seL4_VCPUFault_Msg_seL4_VCPUFault_Length);
                Fault::VCPUFault(VCPUFault::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_VPPIEvent => {
                // TODO
                // assert!(tag.length() == sys::seL4_VPPIEvent_Length);
                Fault::VPPIEvent(VPPIEvent::get())
            }
            _ => {
                panic!()
            }
        }
    }
}

// TODO move elsewhere
// TODO remove magic values

const HSR_SYNDROME_VALID: Word = 1 << 24;
const SRT_MASK: Word = 0x1f;

impl VMFault {
    pub fn is_valid(&self) -> bool {
        self.fsr & HSR_SYNDROME_VALID != 0
    }

    pub fn valid_hsr(&self) -> u64 {
        assert!(self.is_valid());
        self.fsr
    }

    pub fn is_aligned(&self) -> bool {
        let mask = match self.width() {
            VMFaultWidth::Byte => 0x0,
            VMFaultWidth::HalfWord => 0x1,
            VMFaultWidth::Word => 0x3,
            VMFaultWidth::DoubleWord => 0x7,
        };
        self.addr & mask == 0
    }

    pub fn is_write(&self) -> bool {
        self.valid_hsr() & (1 << 6) != 0
    }

    pub fn is_read(&self) -> bool {
        !self.is_write()
    }

    pub fn width(&self) -> VMFaultWidth {
        match (self.valid_hsr() >> 22) & 0x3 {
            0 => VMFaultWidth::Byte,
            1 => VMFaultWidth::HalfWord,
            2 => VMFaultWidth::Word,
            3 => VMFaultWidth::DoubleWord,
            _ => unreachable!(),
        }
    }

    fn gpr_index(&self) -> u64 {
        (self.valid_hsr() >> 16) & SRT_MASK
    }

    pub fn data(&self, ctx: &UserContext) -> VMFaultData {
        assert!(self.is_write());
        self.width().truncate(ctx.read_gpr(self.gpr_index()))
    }

    pub fn emulate_read(&self, ctx: &mut UserContext, val: VMFaultData) {
        assert!(self.is_read());
        assert_eq!(self.width(), val.into());
        let gpr = ctx.gpr_mut(self.gpr_index());
        *gpr = val.set(*gpr);
    }
}

#[derive(Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Debug)]
pub enum VMFaultWidth {
    Byte,
    HalfWord,
    Word,
    DoubleWord,
}

impl VMFaultWidth {
    pub fn mask(self) -> u64 {
        match self {
            Self::Byte => 0xff,
            Self::HalfWord => 0xffff,
            Self::Word => 0xffff_ffff,
            Self::DoubleWord => !0,
        }
    }

    pub fn truncate(self, val: u64) -> VMFaultData {
        let val = val & self.mask();
        match self {
            Self::Byte => VMFaultData::Byte(val as u8),
            Self::HalfWord => VMFaultData::HalfWord(val as u16),
            Self::Word => VMFaultData::Word(val as u32),
            Self::DoubleWord => VMFaultData::DoubleWord(val as u64),
        }
    }
}

#[derive(Copy, Clone, Eq, PartialEq, Debug)]
pub enum VMFaultData {
    Byte(u8),
    HalfWord(u16),
    Word(u32),
    DoubleWord(u64),
}

impl VMFaultData {
    pub fn set(self, old_val: u64) -> u64 {
        (old_val & !VMFaultWidth::from(self).mask()) | u64::from(self)
    }
}

impl From<VMFaultData> for u64 {
    fn from(x: VMFaultData) -> u64 {
        match x {
            VMFaultData::Byte(raw) => raw as u64,
            VMFaultData::HalfWord(raw) => raw as u64,
            VMFaultData::Word(raw) => raw as u64,
            VMFaultData::DoubleWord(raw) => raw as u64,
        }
    }
}

impl From<VMFaultData> for VMFaultWidth {
    fn from(x: VMFaultData) -> VMFaultWidth {
        match x {
            VMFaultData::Byte(_) => Self::Byte,
            VMFaultData::HalfWord(_) => Self::HalfWord,
            VMFaultData::Word(_) => Self::Word,
            VMFaultData::DoubleWord(_) => Self::DoubleWord,
        }
    }
}

///

impl UnknownSyscall {
    pub fn reply(num_regs: usize) {
        reply(MessageInfo::new(0, 0, 0, num_regs as u64))
    }

    pub fn advance(&self) {
        Self::mr_pc().set(self.fault_ip + 4)
    }

    pub fn advance_and_reply(&self) {
        self.advance();
        Self::reply(Self::num_regs_for_gprs_and_pc())
    }

    pub const fn num_regs_for_gprs_and_pc() -> usize {
        sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_FaultIP as usize + 1
    }

    pub const fn mr_pc() -> MessageRegister {
        MessageRegister::new(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_FaultIP as i32)
    }

    pub const fn mr_gpr(ix: usize) -> MessageRegister {
        assert!(ix <= 7);
        MessageRegister::new(sys::seL4_UnknownSyscall_Msg_seL4_UnknownSyscall_X0 as i32 + ix as i32)
    }

    pub fn gpr(&self, ix: usize) -> u64 {
        match ix {
            0 => self.x0,
            1 => self.x1,
            2 => self.x2,
            3 => self.x3,
            4 => self.x4,
            5 => self.x5,
            6 => self.x6,
            7 => self.x7,
            _ => panic!(),
        }
    }
}

impl VCPUFault {
    pub fn is_wf(&self) -> bool {
        // AArch64 ESR_EL{1,2}
        self.hsr >> 26 == 1
    }
}
