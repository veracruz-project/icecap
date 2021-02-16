use crate::{
    sys,
    Word,
    MessageInfo,
    MessageRegister,
};

// TODO
// - use proper types in fault structs (e.g. signed for seL4_VGICMaintenance_IDX)

fn get(i: Word) -> Word {
    MessageRegister::new(i as i32).get()
}

pub trait IsFault {
    fn get() -> Self;
}

#[derive(Debug)]
pub struct NullFault {
}

impl IsFault for NullFault {
    fn get() -> Self {
        Self {
        }
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
            ip: get(sys::seL4_CapFault_IP),
            addr: get(sys::seL4_CapFault_Addr),
            in_recv_phase: get(sys::seL4_CapFault_InRecvPhase),
            lookup_failure_type: get(sys::seL4_CapFault_LookupFailureType),
            bits_left: get(sys::seL4_CapFault_BitsLeft),
            guard_mismatch_guard_found: get(sys::seL4_CapFault_GuardMismatch_GuardFound),
            guard_mismatch_bits_found: get(sys::seL4_CapFault_GuardMismatch_BitsFound),
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
            x0: get(sys::seL4_UnknownSyscall_X0),
            x1: get(sys::seL4_UnknownSyscall_X1),
            x2: get(sys::seL4_UnknownSyscall_X2),
            x3: get(sys::seL4_UnknownSyscall_X3),
            x4: get(sys::seL4_UnknownSyscall_X4),
            x5: get(sys::seL4_UnknownSyscall_X5),
            x6: get(sys::seL4_UnknownSyscall_X6),
            x7: get(sys::seL4_UnknownSyscall_X7),
            fault_ip: get(sys::seL4_UnknownSyscall_FaultIP),
            sp: get(sys::seL4_UnknownSyscall_SP),
            lr: get(sys::seL4_UnknownSyscall_LR),
            spsr: get(sys::seL4_UnknownSyscall_SPSR),
            syscall: get(sys::seL4_UnknownSyscall_Syscall),
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
            fault_ip: get(sys::seL4_UserException_FaultIP),
            sp: get(sys::seL4_UserException_SP),
            spsr: get(sys::seL4_UserException_SPSR),
            number: get(sys::seL4_UserException_Number),
            code: get(sys::seL4_UserException_Code),
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
            ip: get(sys::seL4_VMFault_IP),
            addr: get(sys::seL4_VMFault_Addr),
            prefetch_fault: get(sys::seL4_VMFault_PrefetchFault),
            fsr: get(sys::seL4_VMFault_FSR),
        }
    }
}

#[derive(Debug)]
pub struct VGICMaintenance {
    pub idx: Word,
}

impl IsFault for VGICMaintenance {
    fn get() -> Self {
        Self {
            idx: get(sys::seL4_VGICMaintenance_IDX),
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
            hsr: get(sys::seL4_VCPUFault_HSR),
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
            irq: get(sys::seL4_VPPIEvent_IRQ),
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
                assert!(tag.length() == sys::seL4_UnknownSyscall_Length);
                Fault::UnknownSyscall(UnknownSyscall::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_UserException => {
                assert!(tag.length() == sys::seL4_UserException_Length);
                Fault::UserException(UserException::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_VMFault => {
                assert!(tag.length() == sys::seL4_VMFault_Length);
                Fault::VMFault(VMFault::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_VGICMaintenance => {
                assert!(tag.length() == sys::seL4_VGICMaintenance_Length);
                Fault::VGICMaintenance(VGICMaintenance::get())
            }
            sys::seL4_Fault_tag_seL4_Fault_VCPUFault => {
                assert!(tag.length() == sys::seL4_VCPUFault_Length);
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
