use core::convert::TryFrom;
use core::slice;

use dyndl_types::*;
use icecap_core::prelude::*;

use crate::{utils::rights_of, CRegion, VirtualCore, VirtualCoreTCB, VirtualCores};

pub struct SubsystemObjectInitializationResources {
    pub pgd: PGD,
    pub asid_pool: ASIDPool,
    pub tcb_authority: TCB,
    pub small_page_addr: usize,
    pub large_page_addr: usize,
}

impl SubsystemObjectInitializationResources {
    pub fn fill_frame<T: Frame>(&self, frame: T, fill: &Fill) -> Fallible<()> {
        let vaddr = match T::frame_size() {
            FrameSize::Small => self.small_page_addr,
            FrameSize::Large => self.large_page_addr,
            _ => panic!(),
        };
        frame.map(
            self.pgd,
            vaddr,
            CapRights::read_write(),
            VMAttributes::default() & !VMAttributes::PAGE_CACHEABLE,
        )?;
        let view = unsafe { slice::from_raw_parts_mut(vaddr as *mut u8, T::frame_size().bytes()) };
        for entry in fill {
            view[entry.offset..(entry.offset + entry.content.len())]
                .copy_from_slice(&entry.content);
        }
        frame.unmap()?;
        Ok(())
    }

    pub fn initialize(
        &self,
        num_nodes: usize,
        model: &Model,
        caps: &[Unspecified],
        cregion: &mut CRegion,
    ) -> Fallible<VirtualCores> {
        Initialize {
            initialization_resources: self,
            num_nodes,
            model,
            caps: &caps,
            cregion,
        }
        .initialize()
    }
}

struct Initialize<'a> {
    initialization_resources: &'a SubsystemObjectInitializationResources,
    num_nodes: usize,
    model: &'a Model,
    caps: &'a [Unspecified],
    cregion: &'a mut CRegion,
}

impl<'a> Initialize<'a> {
    fn initialize(&mut self) -> Fallible<VirtualCores> {
        self.init_vspaces()?;
        self.init_cspaces()?;
        let mut virtual_cores = (0..self.num_nodes)
            .map(|_| VirtualCore { tcbs: vec![] })
            .collect::<VirtualCores>();
        for (i, obj) in Self::it_i::<&obj::TCB>(self.model) {
            let tcb = self.cap(i);
            let name = &self.model.objects[i].name;
            self.init_tcb(tcb, obj)?;
            tcb.debug_name(name);
            virtual_cores[obj.affinity as usize]
                .tcbs
                .push(VirtualCoreTCB {
                    cap: tcb,
                    resume: obj.resume,
                });
        }
        Ok(virtual_cores)
    }

    fn init_vspaces(&mut self) -> Fallible<()> {
        for (pgd, obj) in Self::it_cap::<PGD, &obj::PGD>(self.model, self.caps) {
            self.initialization_resources.asid_pool.assign(pgd)?;

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
                                let frame: LargePage = self.copy(orig_frame)?;
                                let rights = rights_of(&cap.rights);
                                // TODO more VMAttributes from cdl
                                let attrs = VMAttributes::default()
                                    & !(if !cap.cached {
                                        VMAttributes::PAGE_CACHEABLE
                                    } else {
                                        VMAttributes::NONE
                                    });
                                frame.map(pgd, vaddr, rights, attrs)?;
                            }
                            PDEntry::PT(cap) => {
                                let obj: &obj::PT = self.obj(cap.obj)?;
                                let pt: PT = self.cap(cap.obj);
                                let attrs = VMAttributes::default();
                                pt.map(pgd, vaddr, attrs)?;

                                for (i, cap) in &obj.entries {
                                    let orig_frame: SmallPage = self.cap(cap.obj);
                                    let frame: SmallPage = self.copy(orig_frame)?;
                                    let vaddr = vaddr + (i << 12);
                                    let rights = rights_of(&cap.rights);
                                    // TODO more VMAttributes from cdl
                                    let attrs = VMAttributes::default()
                                        & !(if !cap.cached {
                                            VMAttributes::PAGE_CACHEABLE
                                        } else {
                                            VMAttributes::NONE
                                        });
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

    fn init_cspaces(&self) -> Fallible<()> {
        for (cnode, obj) in self.it::<CNode, &obj::CNode>() {
            for (i, cap) in &obj.entries {
                // TODO enforce per-extern policy
                let dst = cnode.relative(&CPtrWithDepth::new(
                    CPtr::from_raw(*i as u64),
                    obj.size_bits,
                ));
                let mut rights = CapRights::all_rights();
                let mut badge = None;
                let ptr = match cap {
                    Cap::Untyped(cap) => cap.obj,
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
                    Cap::TCB(cap) => cap.obj,
                    Cap::VCPU(cap) => cap.obj,
                    Cap::PGD(cap) => cap.obj,
                    Cap::LargePage(cap) => {
                        rights = rights_of(&cap.rights);
                        cap.obj
                    }
                    _ => {
                        bail!("unsupported cap {:?}", cap)
                    }
                };
                let src = self
                    .cregion
                    .root
                    .root
                    .relative(self.cap::<Unspecified>(ptr));
                match badge {
                    // HACK 0-badge != no-badge
                    None | Some(0) => dst.copy(&src, rights),
                    Some(badge) => dst.mint(&src, rights, badge),
                }?;
            }
        }
        Ok(())
    }

    fn init_tcb(&self, tcb: TCB, obj: &obj::TCB) -> Fallible<()> {
        // TODO limit or scale prio and max_prio to protect non-realm components

        let fault_ep = CPtr::from_raw(obj.fault_ep);
        let cspace = self.cap(obj.cspace.obj);
        let cspace_root_data = CNodeCapData::new(obj.cspace.guard, obj.cspace.guard_size);
        let vspace = self.cap(obj.vspace.obj);
        let ipc_buffer_frame = self.cap(obj.ipc_buffer.obj);

        if let Some(vcpu) = &obj.vcpu {
            let vcpu: VCPU = self.cap(vcpu.obj);
            vcpu.set_tcb(tcb)?;
        }

        if let Some(bound_notification) = &obj.bound_notification {
            let bound_notification: Notification = self.cap(bound_notification.obj);
            tcb.bind_notification(bound_notification)?;
        }

        tcb.configure(
            fault_ep,
            cspace,
            cspace_root_data,
            vspace,
            obj.ipc_buffer_addr,
            ipc_buffer_frame,
        )?;
        tcb.set_sched_params(
            self.initialization_resources.tcb_authority,
            obj.max_prio as u64,
            obj.prio as u64,
        )?;
        // schedule(tcb, None)?;

        let mut regs = UserContext::default();
        *regs.pc_mut() = obj.ip;
        *regs.sp_mut() = obj.sp;
        *regs.spsr_mut() = obj.spsr;
        let n = obj.gprs.len();
        ensure!(n <= 2);
        if n > 0 {
            *regs.gpr_mut(0) = obj.gprs[0];
        }
        if n > 1 {
            *regs.gpr_mut(1) = obj.gprs[1];
        }
        tcb.write_all_registers(false, &mut regs)?;

        // TODO resume according to obj.resume once MCS or approx

        Ok(())
    }

    ////

    fn copy<T: LocalCPtr>(&mut self, cap: T) -> Fallible<T> {
        let slot = self.cregion.alloc().unwrap();
        let src = self.cregion.context().relative(cap);
        self.cregion
            .relative_cptr(slot)
            .copy(&src, CapRights::all_rights())?;
        Ok(self.cregion.cptr_with_depth(slot).local_cptr())
    }

    fn obj<O: TryFrom<&'a Obj>>(&self, i: usize) -> Fallible<O> {
        if let AnyObj::Local(obj) = &self.model.objects[i].object {
            Ok(O::try_from(&obj).ok().unwrap()) // TODO
        } else {
            bail!("")
        }
    }

    fn cap<T: LocalCPtr>(&self, i: usize) -> T {
        self.caps[i].downcast()
    }

    fn it_i<T: TryFrom<&'a Obj>>(model: &'a Model) -> impl Iterator<Item = (usize, T)> + 'a {
        model.objects.iter().enumerate().filter_map(|(i, obj)| {
            let obj: T = match &obj.object {
                AnyObj::Local(obj) => T::try_from(obj).ok(),
                _ => None,
            }?;
            Some((i, obj))
        })
    }

    fn it_cap<O: LocalCPtr + 'a, T: TryFrom<&'a Obj> + 'a>(
        model: &'a Model,
        caps: &'a [Unspecified],
    ) -> impl Iterator<Item = (O, T)> + 'a {
        Self::it_i(model).map(move |(i, obj)| (caps[i].downcast(), obj))
    }

    fn it<O: LocalCPtr + 'a, T: TryFrom<&'a Obj> + 'a>(
        &'a self,
    ) -> impl Iterator<Item = (O, T)> + 'a {
        Self::it_cap(&self.model, &self.caps)
    }
}
