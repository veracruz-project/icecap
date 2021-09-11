use core::mem::size_of;
use crate::{
    sys, Result, Error,
    Word, Badge,
    UserContext, VCPUReg,
    CapRights, MessageInfo, CNodeCapData, VMAttributes,
    Frame, FrameSize, VSpaceBranch,
};

use super::*;

// TODO
// type Addr = usize;

// NOTE
// &self enables convenient use of Deref at the cost of indirection. Is this appropriate?

impl Untyped {

    pub fn retype(&self, blueprint: ObjectBlueprint, dst: &RelativeCPtr, dst_offset: Word, num_objects: Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_Untyped_Retype(self.raw(), blueprint.ty() as Word, blueprint.raw_size_bits().unwrap_or(0) as Word, dst.root.raw(), dst.path.cptr.raw(), dst.path.depth as Word, dst_offset, num_objects)
        })
    }

}

impl Endpoint {

    pub fn send(&self, info: MessageInfo) {
        unsafe {
            sys::seL4_Send(self.raw(), info.raw())
        }
    }

    pub fn nb_send(&self, info: MessageInfo) {
        unsafe {
            sys::seL4_NBSend(self.raw(), info.raw())
        }
    }

    pub fn recv(&self) -> (MessageInfo, Badge) {
        let mut badge = 0;
        let raw_info = unsafe {
            sys::seL4_Recv(self.raw(), &mut badge)
        };
        (MessageInfo::from_raw(raw_info), badge)
    }

    pub fn nb_recv(&self) -> (MessageInfo, Badge) {
        let mut badge = 0;
        let raw_info = unsafe {
            sys::seL4_NBRecv(self.raw(), &mut badge)
        };
        (MessageInfo::from_raw(raw_info), badge)
    }

    pub fn call(&self, info: MessageInfo) -> MessageInfo {
        unsafe {
            MessageInfo::from_raw(sys::seL4_Call(self.raw(), info.raw()))
        }
    }

}

impl Notification {

    pub fn signal(&self) {
        unsafe {
            sys::seL4_Signal(self.raw());
        }
    }

    pub fn wait(&self) -> Badge {
        let mut badge = 0;
        let null = core::ptr::null_mut();
        unsafe {
            // HACK
            sys::seL4_RecvWithMRs(self.raw(), &mut badge, null, null, null, null);
        }
        badge
    }

}

impl TCB {

    pub fn read_registers(&self, suspend: bool, count: Word) -> Result<UserContext> {
        let mut regs: UserContext = Default::default();
        let err = unsafe {
            sys::seL4_TCB_ReadRegisters(self.raw(), suspend as sys::seL4_Bool, 0, count, regs.raw_mut())
        };
        Error::or(regs, err)
    }

    pub fn read_all_registers(&self, suspend: bool) -> Result<UserContext> {
        let count = size_of::<UserContext>() / size_of::<Word>();
        self.read_registers(suspend, count as Word)
    }

    // HACK should not be mut
    pub fn write_registers(&self, resume: bool, count: Word, regs: &mut UserContext) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_WriteRegisters(self.raw(), resume as sys::seL4_Bool, 0, count, regs.raw_mut())
        })
    }

    pub fn write_all_registers(&self, resume: bool, regs: &mut UserContext) -> Result<()> {
        let count = size_of::<UserContext>() / size_of::<Word>();
        self.write_registers(resume, count as Word, regs)
    }

    pub fn resume(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_Resume(self.raw())
        })
    }

    pub fn suspend(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_Suspend(self.raw())
        })
    }

    pub fn configure(&self, fault_ep: CPtr, cspace_root: CNode, cspace_root_data: CNodeCapData, vspace_root: PGD, ipc_buffer: Word, ipc_buffer_frame: SmallPage) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_Configure(self.raw(), fault_ep.raw(), cspace_root.raw(), cspace_root_data.raw(), vspace_root.raw(), 0 /* HACK */, ipc_buffer, ipc_buffer_frame.raw())
        })
    }

    pub fn set_sched_params(&self, authority: TCB, mcp: Word, priority: Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_SetSchedParams(self.raw(), authority.raw(), mcp, priority)
        })
    }

    pub fn set_affinity(&self, affinity: Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_SetAffinity(self.raw(), affinity)
        })
    }

    pub fn set_tls_base(&self, tls_base: Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_SetTLSBase(self.raw(), tls_base)
        })
    }

    pub fn bind_notification(&self, notification: Notification) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_TCB_BindNotification(self.raw(), notification.raw())
        })
    }
}

impl VCPU {

    pub fn set_tcb(&self, tcb: TCB) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_VCPU_SetTCB(self.raw(), tcb.raw())
        })
    }

    pub fn read_regs(&self, field: VCPUReg) -> Result<Word> {
        let res = unsafe {
            sys::seL4_ARM_VCPU_ReadRegs(self.raw(), field as Word)
        };
        Error::or(res.value, res.error as u32)
    }

    pub fn write_regs(&self, field: VCPUReg, value: Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_VCPU_WriteRegs(self.raw(), field as Word, value)
        })
    }

    pub fn ack_vppi(&self, irq: Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_VCPU_AckVPPI(self.raw(), irq)
        })
    }

    pub fn inject_irq(&self, virq: u16, priority: u8, group: u8, index: u8) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_VCPU_InjectIRQ(self.raw(), virq, priority, group, index)
        })
    }

}

impl Frame for SmallPage {
    fn frame_size() -> FrameSize {
        FrameSize::Small
    }

    fn map(&self, pgd: PGD, vaddr: usize, rights: CapRights, attrs: VMAttributes) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_Page_Map(self.raw(), pgd.raw(), vaddr as u64, rights.raw(), attrs.raw())
        })
    }

    fn unmap(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_Page_Unmap(self.raw())
        })
    }
}

impl Frame for LargePage {
    fn frame_size() -> FrameSize {
        FrameSize::Large
    }

    fn map(&self, pgd: PGD, vaddr: usize, rights: CapRights, attrs: VMAttributes) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_Page_Map(self.raw(), pgd.raw(), vaddr as u64, rights.raw(), attrs.raw())
        })
    }

    fn unmap(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_Page_Unmap(self.raw())
        })
    }
}

impl Frame for HugePage {
    fn frame_size() -> FrameSize {
        FrameSize::Huge
    }

    fn map(&self, pgd: PGD, vaddr: usize, rights: CapRights, attrs: VMAttributes) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_Page_Map(self.raw(), pgd.raw(), vaddr as u64, rights.raw(), attrs.raw())
        })
    }

    fn unmap(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_Page_Unmap(self.raw())
        })
    }
}

impl VSpaceBranch for PUD {
    fn map(&self, vspace: PGD, vaddr: usize, attrs: VMAttributes) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_PageUpperDirectory_Map(self.raw(), vspace.raw(), vaddr as u64, attrs.raw())
        })
    }
}

impl VSpaceBranch for PD {
    fn map(&self, vspace: PGD, vaddr: usize, attrs: VMAttributes) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_PageDirectory_Map(self.raw(), vspace.raw(), vaddr as u64, attrs.raw())
        })
    }
}

impl VSpaceBranch for PT {
    fn map(&self, vspace: PGD, vaddr: usize, attrs: VMAttributes) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_PageTable_Map(self.raw(), vspace.raw(), vaddr as u64, attrs.raw())
        })
    }
}

impl IRQHandler {

    pub fn ack(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_IRQHandler_Ack(self.raw())
        })
    }

    pub fn set_notification(&self, notification: Notification) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_IRQHandler_SetNotification(self.raw(), notification.raw())
        })
    }

    pub fn clear(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_IRQHandler_Clear(self.raw())
        })
    }

}

impl ASIDPool {

    pub fn assign(&self, pd: PGD) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_ARM_ASIDPool_Assign(self.raw(), pd.raw())
        })
    }

}

impl RelativeCPtr {

    pub fn revoke(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_CNode_Revoke(
                self.root.raw(),
                self.path.cptr.raw(),
                self.path.depth as u8,
            )
        })
    }

    pub fn delete(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_CNode_Delete(
                self.root.raw(),
                self.path.cptr.raw(),
                self.path.depth as u8,
            )
        })
    }

    pub fn copy(&self, src: &RelativeCPtr, rights: CapRights) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_CNode_Copy(
                self.root.raw(),
                self.path.cptr.raw(),
                self.path.depth as u8,
                src.root.raw(),
                src.path.cptr.raw(),
                src.path.depth as u8,
                rights.raw(),
            )
        })
    }

    pub fn mint(&self, src: &RelativeCPtr, rights: CapRights, badge: sys::seL4_Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_CNode_Mint(
                self.root.raw(),
                self.path.cptr.raw(),
                self.path.depth as u8,
                src.root.raw(),
                src.path.cptr.raw(),
                src.path.depth as u8,
                rights.raw(),
                badge
            )
        })
    }

    pub fn mutate(&self, src: &RelativeCPtr, badge: sys::seL4_Word) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_CNode_Mutate(
                self.root.raw(),
                self.path.cptr.raw(),
                self.path.depth as u8,
                src.root.raw(),
                src.path.cptr.raw(),
                src.path.depth as u8,
                badge
            )
        })
    }

    pub fn save_caller(&self) -> Result<()> {
        Error::wrap(unsafe {
            sys::seL4_CNode_SaveCaller(self.root.raw(), self.path.cptr.raw(), self.path.depth as u8)
        })
    }
}
