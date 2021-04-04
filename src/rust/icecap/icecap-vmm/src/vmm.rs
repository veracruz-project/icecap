use alloc::sync::Arc;
use alloc::vec::Vec;
use alloc::collections::BTreeMap;

use icecap_core::{
    prelude::*,
    sel4::fault::*,
    runtime::Thread,
    sync::{Mutex, ExplicitMutexNotification},
};
use icecap_vmm_gic::*;

pub struct VMMConfig<E> {
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub irq_handlers: BTreeMap<IRQ, IRQHandler>,
    pub gic_dist_paddr: usize,
    pub nodes: Vec<VMMNodeConfig<E>>,
}

pub struct VMMNodeConfig<E> {
    pub tcb: TCB,
    pub vcpu: VCPU,
    pub ep: Endpoint,
    pub fault_reply_slot: Endpoint,
    pub thread: Thread,
    pub extension: E,
}

pub trait VMMExtension: Sized {
    fn handle_wfe(node: &mut VMMNode<Self>) -> Fallible<()>;
    fn handle_syscall(node: &mut VMMNode<Self>, syscall: u64) -> Fallible<()>;
    fn handle_putchar(node: &mut VMMNode<Self>, c: u8) -> Fallible<()>;
}

pub struct VMMNode<E> {
    pub node_index: NodeIndex,
    pub tcb: TCB,
    pub vcpu: VCPU,
    pub ep: Endpoint,
    pub cnode: CNode,
    pub fault_reply_slot: Endpoint,
    pub gic_dist_paddr: usize,
    pub gic: Arc<Mutex<GIC<VMMGICCallbacks>>>,
    pub nodes: Arc<Mutex<Vec<Option<(Thread, VMMNode<E>)>>>>,
    pub extension: E,
}

pub struct VMMGICCallbacks {
    vcpus: Vec<VCPU>,
    irq_handlers: BTreeMap<IRQ, IRQHandler>,
}

impl GICCallbacks for VMMGICCallbacks {

    fn event(&mut self, node: NodeIndex, target_node: NodeIndex) -> Fallible<()> {
        Ok(())
    }

    fn ack(&mut self, node: NodeIndex, irq: IRQ) -> Fallible<()> {
        if irq < 16 {
            panic!("invalid irq: sgi {}", irq);
        } else if irq < 32 {
            self.vcpus[node].ack_vppi(irq as u64)?;
        } else {
            if let Some(handler) = self.irq_handlers.get(&irq) {
                handler.ack()?;
            }
        }
        Ok(())
    }

    fn vcpu_inject_irq(&mut self, node: NodeIndex, index: usize, irq: IRQ, priority: usize) -> Fallible<()> {
        self.vcpus[node].inject_irq(irq as u16, priority as u8, 0, index as u8)?;
        Ok(())
    }

    fn set_affinity(&mut self, node: NodeIndex, irq: IRQ, target_node: NodeIndex) -> Fallible<()> {
        Ok(())
    }

    fn set_priority(&mut self, node: NodeIndex, irq: IRQ, priority: usize) -> Fallible<()> {
        Ok(())
    }

    fn set_enabled(&mut self, node: NodeIndex, irq: IRQ, enabled: bool) -> Fallible<()> {
        Ok(())
    }
}

impl<E: 'static + VMMExtension + Send> VMMConfig<E> {

    pub fn run(mut self) -> Fallible<()> {
        let nodes = Arc::new(Mutex::new(ExplicitMutexNotification::new(self.nodes_lock), Vec::new()));
        let gic = GIC::new(self.nodes.len(), VMMGICCallbacks {
            irq_handlers: self.irq_handlers,
            vcpus: self.nodes.iter().map(|node| node.vcpu).collect(),
        });
        let gic = Arc::new(Mutex::new(ExplicitMutexNotification::new(self.gic_lock), gic));
        for (i, node_config) in self.nodes.drain(..).enumerate() {
            let node = VMMNode {
                tcb: node_config.tcb,
                vcpu: node_config.vcpu,
                ep: node_config.ep,
                fault_reply_slot: node_config.fault_reply_slot,
                cnode: self.cnode,
                extension: node_config.extension,
                gic_dist_paddr: self.gic_dist_paddr,
                node_index: i,
                gic: gic.clone(),
                nodes: nodes.clone(),
            };
            nodes.lock().push(Some((node_config.thread, node)));
        }
        let (_thread, mut node) = {
            let mut this = None;
            let mut nodes = nodes.lock();
            core::mem::swap(&mut this, &mut nodes[0]);
            this.unwrap()
        };
        node.run()
    }
}

pub const BADGE_EXTERNAL: Badge = 0;
pub const BADGE_VM: Badge = 1;

const SYS_PUTCHAR: Word = 1337;
const SYS_PSCI: Word = 0;

impl<E: 'static + VMMExtension + Send> VMMNode<E> {

    pub fn run(&mut self) -> Fallible<()> {
        self.tcb.resume()?;
        loop {
            let (info, badge) = self.ep.recv();
            match badge {
                BADGE_EXTERNAL => {
                    // HACK
                    let irq = MR_0.get() as IRQ;
                    self.gic.lock().handle_irq(self.node_index, irq)?;
                }
                BADGE_VM => {
                    let fault = Fault::get(info);
                    match fault {
                        Fault::VMFault(fault) => {
                            self.handle_page_fault(fault)?;
                            reply(MessageInfo::empty());
                        }
                        Fault::UnknownSyscall(fault) => {
                            self.cnode.save_caller(self.fault_reply_slot).unwrap();
                            self.handle_syscall(fault.syscall)?;
                            self.fault_reply_slot.send(MessageInfo::empty());
                        }
                        Fault::UserException(fault) => {
                            panic!("Fault::UserException({:x?})", fault);
                        }
                        Fault::VGICMaintenance(fault) => {
                            self.gic.lock().handle_maintenance(self.node_index, fault.idx as usize)?;
                            reply(MessageInfo::empty());
                        }
                        Fault::VCPUFault(fault) => {
                            assert!(fault.hsr >> 26 == 1);
                            E::handle_wfe(self)?;
                        }
                        Fault::VPPIEvent(fault) => {
                            self.gic.lock().handle_irq(self.node_index, fault.irq as usize)?;
                            reply(MessageInfo::empty());
                        }
                        _ => {
                            panic!();
                        }
                    }
                }
                _ => {
                    panic!();
                }
            }
        }
    }

    fn handle_page_fault(&mut self, fault: VMFault) -> Fallible<()> {
        let addr = fault.addr as usize;
        if addr >= self.gic_dist_paddr && addr < self.gic_dist_paddr + GIC::<VMMGICCallbacks>::DISTRIBUTOR_SIZE {
            let offset = addr - self.gic_dist_paddr;
            self.handle_dist_fault(fault, offset)?;
        } else {
            panic!("unhandled page fault at 0x{:x}", addr);
        }
        self.advance();
        Ok(())
    }

    fn handle_dist_fault(&mut self, fault: VMFault, offset: usize) -> Fallible<()> {
        assert!(fault.is_valid());
        assert!(fault.is_aligned());
        if fault.is_write() {
            let ctx = self.tcb.read_all_registers(false).unwrap();
            let data = fault.data(&ctx);
            self.gic.lock().handle_write(self.node_index, offset, data)?;
        } else if fault.is_read() {
            let data = self.gic.lock().handle_read(self.node_index, offset, fault.width())?;
            let mut ctx = self.tcb.read_all_registers(false).unwrap();
            fault.emulate_read(&mut ctx, data);
            self.tcb.write_all_registers(false, &mut ctx).unwrap();
        } else {
            panic!();
        }
        Ok(())
    }

    fn handle_syscall(&mut self, syscall: Word) -> Fallible<()> {
        match syscall {
            SYS_PUTCHAR => {
                self.sys_putchar()?;
            }
            SYS_PSCI => {
                self.sys_psci()?;
            }
            _ => {
                E::handle_syscall(self, syscall)?;
            }
        }
        Ok(())
    }

    fn sys_putchar(&mut self) -> Fallible<()> {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        let c = ctx.x0 as u8;
        E::handle_putchar(self, c)?;
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
        Ok(())
    }

    fn sys_psci(&self) -> Fallible<()> {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        const FID_PSCI_VERSION: u32 = 0x8400_0000;
        const FID_CPU_ON: u32 = 0xC400_0003;
        const FID_MIGRATE_INFO_TYPE: u32 = 0x8400_0006;
        const FID_PSCI_FEATURES: u32 = 0x8400_000a;
        const RET_SUCCESS: i32 = 0;
        const RET_NOT_SUPPORTED: i32 = -1;
        let fid = ctx.x0 as u32;
        match fid {
            FID_PSCI_VERSION => {
                const VERSION: u32 = 0x0001_0001;
                ctx.x0 = VERSION as u64;
            }
            FID_CPU_ON => {
                let target = ctx.x1 as usize;
                let entry = ctx.x2 as u64;
                let ctx_id = ctx.x3 as u64;
                debug_println!("cpu_on: {:x} {:x} {:x}", target, entry, ctx_id);
                let (thread, mut node) = {
                    let mut this = None;
                    let mut nodes = self.nodes.lock();
                    core::mem::swap(&mut this, &mut nodes[target]);
                    this.unwrap()
                };
                thread.start(move || {
                    let mut ctx = node.tcb.read_all_registers(false).unwrap();
                    ctx.pc = entry;
                    ctx.x0 = ctx_id;
                    node.tcb.write_all_registers(false, &mut ctx).unwrap();
                    node.run().unwrap()
                });
                ctx.x0 = RET_SUCCESS as u64;
            }
            FID_MIGRATE_INFO_TYPE => {
                ctx.x0 = RET_NOT_SUPPORTED as u64;
            }
            FID_PSCI_FEATURES => {
                let qfid = ctx.x1 as u32;
                ctx.x0 = match qfid {
                    FID_CPU_ON => {
                        0
                    }
                    _ => {
                        RET_NOT_SUPPORTED as u64
                    }
                }
            }
            _ => {
                panic!("psci fid {:x}", fid);
            }
        }
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
        Ok(())
    }

    fn handle_exception(&mut self, _ip: Word) {
        panic!();
    }

    fn advance(&mut self) {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
    }
}
