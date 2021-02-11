use core::convert::{TryFrom, TryInto};
use core::slice;
use icecap_core::prelude::*;
use dyndl_types::*;
use crate::{Initializer, Caps, utils::*, Create};

impl Initializer {

    pub fn initialize(&self, caps: &Caps, model: &Model, create: &mut Create) -> Fallible<Vec<TCB>> {
        let mut initialize = Initialize {
            my: self,
            caps: &caps,
            model,
            create,
        };
        initialize.initialize()
    }

    fn init_frame<T: Frame>(&self, frame: T, fill: &Fill) -> Fallible<()> {
        let vaddr = match T::frame_size() {
            FrameSize::Small => self.small_page_addr,
            FrameSize::Large => self.large_page_addr,
            _ => panic!(),
        };
        frame.map(self.pd, vaddr, CapRights::read_write(), VMAttributes::default())?;
        let view = unsafe {
            slice::from_raw_parts_mut(vaddr as *mut u8, T::frame_size().bytes())
        };
        for entry in fill {
            view[entry.offset..(entry.offset + entry.content.len())].copy_from_slice(&entry.content);
        }
        frame.unmap()?;
        Ok(())
    }
}

struct Initialize<'a> {
    my: &'a Initializer,
    caps: &'a Caps,
    model: &'a Model,
    create: &'a mut Create,
}

impl<'a> Initialize<'a> {

    fn initialize(&mut self) -> Fallible<Vec<TCB>> {
        for (pgd, obj) in self.it::<_, &obj::PGD>() {
            self.my.asid_pool.assign(pgd)?;
        }
        for (frame, obj) in self.it::<SmallPage, &obj::SmallPage>() {
            self.my.init_frame(frame, &obj.fill)?;
        }
        for (frame, obj) in self.it::<LargePage, &obj::LargePage>() {
            self.my.init_frame(frame, &obj.fill)?;
        }
        self.init_vspace()?;
        let mut tcbs = vec![];
        for (i, obj) in self.it_i::<&obj::TCB>() {
            let tcb = self.cap(i);
            let name = &self.model.objects[i].name;
            self.init_tcb(tcb, obj)?;
            tcb.debug_name(name);
            tcbs.push(tcb);
        }
        self.init_cspace()?;
        self.start_threads()?;
        Ok(tcbs)
    }

    fn init_vspace(&mut self) -> Fallible<()> {
        for (pgd, obj) in self.it::<PGD, &obj::PGD>() {

            for (i, cap) in &obj.entries {
                let obj: &obj::PUD = self.obj(cap.obj)?;
                let pud: PUD = self.cap(cap.obj);
                let vaddr = i << (9 + 9 + 9 + 12);
                let attrs = VMAttributes::default();
                pud.map(pgd, vaddr, attrs)?;

                for (i, cap) in &obj.entries {
                    let obj: &obj::PD = self.obj(cap.obj)?;
                    let pd: PD = self.cap(cap.obj);
                    let vaddr = vaddr + (i << (9 + 9 + 12));
                    let attrs = VMAttributes::default();
                    pd.map(pgd, vaddr, attrs)?;

                    for (i, cap) in &obj.entries {
                        let vaddr = vaddr + (i << (9 + 12));
                        match cap {
                            PDEntry::LargePage(cap) => {
                                let orig_frame: LargePage = self.cap(cap.obj);
                                let frame: LargePage = self.create.copy(orig_frame.upcast())?.downcast();
                                let rights = rights_of(&cap.rights);
                                let attrs = VMAttributes::default();
                                frame.map(pgd, vaddr, rights, attrs)?;
                            }
                            PDEntry::PT(cap) => {
                                let obj: &obj::PT = self.obj(cap.obj)?;
                                let pt: PT = self.cap(cap.obj);
                                let attrs = VMAttributes::default();
                                pt.map(pgd, vaddr, attrs)?;

                                for (i, cap) in &obj.entries {
                                    // TODO vmattrs from cdl
                                    let orig_frame: SmallPage = self.cap(cap.obj);
                                    let frame: SmallPage = self.create.copy(orig_frame.upcast())?.downcast();
                                    let vaddr = vaddr + (i << 12);
                                    let rights = rights_of(&cap.rights);
                                    let attrs = VMAttributes::default();
                                    frame.map(pgd, vaddr, rights, attrs)?;
                                }
                            }
                        }
                    }
                }
            }
        }
        Ok(())
    }

    fn init_tcb(&self, tcb: TCB, obj: &obj::TCB) -> Fallible<()> {
        let fault_ep = CPtr::from_raw(obj.fault_ep);
        let cspace = self.cap(obj.cspace.obj);
        let cspace_root_data = CNodeCapData::new(obj.cspace.guard, obj.cspace.guard_size);
        let vspace = self.cap(obj.vspace.obj);
        let ipc_buffer_frame = self.cap(obj.ipc_buffer.obj);
        if let Some(vcpu) = &obj.vcpu {
            let vcpu: VCPU = self.cap(vcpu.obj);
            vcpu.set_tcb(tcb)?;
        }
        tcb.configure(fault_ep, cspace, cspace_root_data, vspace, obj.ipc_buffer_addr, ipc_buffer_frame)?;
        tcb.set_sched_params(self.my.tcb_authority, 0, obj.prio as u64)?;
        tcb.set_affinity(obj.affinity)?;
        let mut regs = UserContext::default();
        regs.pc = obj.ip;
        regs.sp = obj.sp;
        regs.spsr = obj.spsr;
        let n = obj.gprs.len();
        ensure!(n <= 2);
        if n > 0 {
            regs.x0 = obj.gprs[0];
        }
        if n > 1 {
            regs.x1 = obj.gprs[1];
        }
        tcb.write_all_registers(false, &mut regs)?;
        Ok(())
    }

    fn init_cspace(&self) -> Fallible<()> {
        for (cnode, obj) in self.it::<CNode, &obj::CNode>() {
            for (i, cap) in &obj.entries {
                let dst = cnode.relative(&CPtrWithDepth::new(CPtr::from_raw(*i as u64), obj.size_bits));
                let mut rights = CapRights::all_rights();
                let mut badge = None;
                let ptr = match cap {
                    Cap::Untyped(cap) => {
                        cap.obj
                    }
                    Cap::Endpoint(cap) => {
                        badge = Some(cap.badge);
                        rights = rights_of(&cap.rights);
                        cap.obj
                    }
                    Cap::Notification(cap) => {
                        badge = Some(cap.badge);
                        rights = rights_of(&cap.rights);
                        cap.obj
                    }
                    Cap::CNode(cap) => {
                        badge = Some(CNodeCapData::new(cap.guard, cap.guard_size).raw());
                        cap.obj
                    }
                    Cap::TCB(cap) => {
                        cap.obj
                    }
                    Cap::VCPU(cap) => {
                        cap.obj
                    }
                    Cap::PGD(cap) => {
                        cap.obj
                    }
                    _ => {
                        bail!("unsupported cap {:?}", cap)
                    }
                };
                let src = self.my.cnode.relative(self.caps[ptr]);
                match badge {
                    // HACK 0-badge != no-badge
                    None | Some(0) => dst.copy(&src, rights),
                    Some(badge) => dst.mint(&src, rights, badge),
                }?;
            }
        }
        Ok(())
    }

    fn start_threads(&self) -> Fallible<()> {
        for (tcb, _) in self.it::<TCB, &obj::TCB>() {
            tcb.resume()?;
        }
        Ok(())
    }

    fn stop_threads(&self) -> Fallible<()> {
        for (tcb, _) in self.it::<TCB, &obj::TCB>() {
            tcb.suspend()?;
        }
        Ok(())
    }

    ////

    fn obj<O: TryFrom<&'a Obj>>(&self, i: usize) -> Fallible<O> {
        let top = &self.model.objects[i];
        if let AnyObj::Local(obj) = &top.object {
            Ok(O::try_from(&obj).ok()?)
        } else {
            bail!("")
        }
    }

    fn cap<T: LocalCPtr>(&self, i: usize) -> T {
        self.caps[i].downcast()
    }

    fn it_i<T: TryFrom<&'a Obj>>(&self) -> impl Iterator<Item = (usize, T)> + 'a {
        self.model.objects.iter().enumerate().filter_map(|(i, obj)| {
            let obj: T = match &obj.object {
                AnyObj::Local(obj) => T::try_from(obj).ok(),
                _ => None,
            }?;
            Some((i, obj))
        })
    }

    fn it<O: LocalCPtr, T: TryFrom<&'a Obj>>(&self) -> impl Iterator<Item = (O, T)> + 'a {
        // TODO
        let caps = self.caps.clone();
        self.model.objects.iter().enumerate().filter_map(move |(i, obj)| {
            let cptr = caps[i];
            let obj: T = match &obj.object {
                AnyObj::Local(obj) => T::try_from(obj).ok(),
                _ => None,
            }?;
            Some((cptr.downcast(), obj))
        })
    }

}
