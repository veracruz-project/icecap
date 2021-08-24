use alloc::sync::Arc;
use alloc::vec::Vec;
use alloc::collections::BTreeMap;

use icecap_core::{
    prelude::*,
    sel4::fault::*,
    runtime::Thread,
    sync::{Mutex, ExplicitMutexNotification},
    ring_buffer::Kick,
    rpc_sel4::RPCClient,
    finite_set::Finite,
};
use icecap_vmm_gic::*;
use icecap_event_server_types::{
    self as event_server,
    InIndex,
};

use crate::asm;

pub struct IRQMap {
    pub ppi: BTreeMap<usize, InIndex>,
    pub spi: BTreeMap<usize, (InIndex, usize)>, // (in_index, nid)
}

pub struct VMMConfig<E> {
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub event_server_client_ep: Vec<Endpoint>, // HACK per node
    pub irq_map: IRQMap,
    pub gic_dist_paddr: usize,
    pub kicks: Vec<Box<dyn Fn(&VMMNode<E>) -> Fallible<()> + Send + Sync>>,
    pub nodes: Vec<VMMNodeConfig<E>>,

    pub debug: bool,
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
    pub event_server_client: RPCClient<event_server::calls::Client>,
    pub kicks: Arc<Vec<Box<dyn Fn(&VMMNode<E>) -> Fallible<()> + Send + Sync>>>,
    pub gic_dist_paddr: usize,
    pub gic: Arc<Mutex<GIC<VMMGICCallbacks>>>,
    pub nodes: Arc<Mutex<Vec<Option<(Thread, VMMNode<E>)>>>>,
    pub extension: E,

    pub debug: bool,
}

pub struct VMMGICCallbacks {
    vcpus: Vec<VCPU>,
    event_server_client: Vec<RPCClient<event_server::calls::Client>>,
    irq_map: IRQMap,
}

impl VMMGICCallbacks {

    fn configure(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ, action: event_server::ConfigureAction) -> Fallible<()> {
        debug_println!("XXXXXXX configure: {} {:?} {:?}", calling_node, irq, action);
        match irq {
            QualifiedIRQ::QualifiedPPI { node, irq } => {
                // assert_eq!(calling_node, node); // TODO HACK
                if let Some(in_index) = self.irq_map.ppi.get(&irq) {
                    self.event_server_client[calling_node].call::<()>(&event_server::calls::Client::Configure {
                        nid: calling_node,
                        index: *in_index,
                        action,
                    });
                } else {
                    self.vcpus[node].ack_vppi(irq as u64)?;
                }
            }
            QualifiedIRQ::SPI { irq } => {
                if let Some((in_index, nid)) = self.irq_map.spi.get(&irq) {
                    self.event_server_client[calling_node].call::<()>(&event_server::calls::Client::Configure {
                        nid: *nid,
                        index: *in_index,
                        action,
                    });
                } else {
                    // panic!("unbound irq: {}", irq); // TODO HACK
                }
            }
        }
        Ok(())
    }
}

#[cfg(icecap_plat = "virt")]
const CNTFRQ: u32 = 62500000;
#[cfg(icecap_plat = "rpi4")]
const CNTFRQ: u32 = 54000000;

impl GICCallbacks for VMMGICCallbacks {

    fn event(&mut self, calling_node: NodeIndex, target_node: NodeIndex) -> Fallible<()> {
        // if calling_node != target_node {
        //     self.event_server_client[calling_node].call::<()>(&event_server::calls::Client::SEV {
        //         nid: target_node,
        //     });
        // }
        Ok(())
    }

    fn ack(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ) -> Fallible<()> {
        match irq {
            QualifiedIRQ::QualifiedPPI { node, irq } => {
                // assert_eq!(calling_node, node); // TODO HACK
                if let Some(in_index) = self.irq_map.ppi.get(&irq) {
                    self.event_server_client[calling_node].call::<()>(&event_server::calls::Client::End {
                        nid: calling_node,
                        index: *in_index,
                    });
                } else {
                    self.vcpus[node].ack_vppi(irq as u64)?;
                }
            }
            QualifiedIRQ::SPI { irq } => {
                if let Some((in_index, nid)) = self.irq_map.spi.get(&irq) {
                    self.event_server_client[calling_node].call::<()>(&event_server::calls::Client::End {
                        nid: *nid,
                        index: *in_index,
                    });
                } else {
                    // panic!("unbound irq: {}", irq); // TODO HACK
                }
            }
        }
        Ok(())
    }

    fn vcpu_inject_irq(&mut self, calling_node: NodeIndex, target_node: NodeIndex, index: usize, irq: IRQ, priority: usize) -> Fallible<()> {
        if calling_node != target_node && irq > 15 {
            debug_println!("warning: cross-core vcpu_inject_irq({}), {} -> {}", irq, calling_node, target_node);
        }
        self.vcpus[target_node].inject_irq(irq as u16, priority as u8, 0, index as u8)?;
        Ok(())
    }

    fn set_affinity(&mut self, calling_node: NodeIndex, irq: SPI, affinity: NodeIndex) -> Fallible<()> {
        Ok(())
    }

    fn set_priority(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ, priority: usize) -> Fallible<()> {
        self.configure(calling_node, irq, event_server::ConfigureAction::SetPriority(priority))
    }

    fn set_enabled(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ, enabled: bool) -> Fallible<()> {
        self.configure(calling_node, irq, event_server::ConfigureAction::SetEnabled(enabled))
    }
}

impl<E: 'static + VMMExtension + Send> VMMConfig<E> {

    pub fn run(mut self) -> Fallible<()> {
        let event_server_client_ep = self.event_server_client_ep;
        let nodes = Arc::new(Mutex::new(ExplicitMutexNotification::new(self.nodes_lock), Vec::new()));
        let gic = GIC::new(self.nodes.len(), VMMGICCallbacks {
            event_server_client: event_server_client_ep.iter().map(|ep| RPCClient::<event_server::calls::Client>::new(*ep)).collect(), // HACK
            vcpus: self.nodes.iter().map(|node| node.vcpu).collect(),
            irq_map: self.irq_map,
        });
        let gic = Arc::new(Mutex::new(ExplicitMutexNotification::new(self.gic_lock), gic));
        let kicks = Arc::new(self.kicks);
        for (i, node_config) in self.nodes.drain(..).enumerate() {
            let node = VMMNode {
                tcb: node_config.tcb,
                vcpu: node_config.vcpu,
                ep: node_config.ep,
                fault_reply_slot: node_config.fault_reply_slot,
                event_server_client: RPCClient::<event_server::calls::Client>::new(event_server_client_ep[i]),
                cnode: self.cnode,
                extension: node_config.extension,
                gic_dist_paddr: self.gic_dist_paddr,
                node_index: i,
                kicks: kicks.clone(),
                gic: gic.clone(),
                nodes: nodes.clone(),

                debug: self.debug,
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

const SYS_PSCI: Word = 0;
const SYS_PUTCHAR: Word = 1337;
const SYS_KICK: Word = 1347;

impl<E: 'static + VMMExtension + Send> VMMNode<E> {

    fn run(&mut self) -> Fallible<()> {
        self.vcpu.write_regs(VCPUReg::CNTVOFF, 0)?;
        self.tcb.resume()?;
        loop {
            let (info, badge) = self.ep.recv();
            match badge {
                BADGE_EXTERNAL => {
                    // if self.debug {
                    //     debug_println!("badge external");
                    // }
                    // TODO should the poll be atomic w.r.t. GIC with rest of block?
                    while let Some(in_index) = self.event_server_client.call::<Option<event_server::InIndex>>(&event_server::calls::Client::Poll { nid: self.node_index }) {
                        // debug_println!("poll: {:?}", event_server::events::HostIn::from_nat(in_index));
                        let mut gic = self.gic.lock();
                        let irq = {
                            let mut irq = None;
                            for (ppi, ppi_in_index) in &gic.callbacks().irq_map.ppi {
                                if *ppi_in_index == in_index {
                                    irq = Some(QualifiedIRQ::QualifiedPPI { node: self.node_index, irq: *ppi });
                                    break;
                                }
                            }
                            if let None = irq {
                                for (spi, (spi_in_index, nid)) in &gic.callbacks().irq_map.spi {
                                    assert_eq!(*nid, self.node_index);
                                    if *spi_in_index == in_index {
                                        irq = Some(QualifiedIRQ::SPI { irq: *spi });
                                        break;
                                    }
                                }
                            }
                            irq.unwrap()
                        };
                        gic.handle_irq(self.node_index, irq)?;
                    }
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
                            self.gic.lock().handle_maintenance(self.node_index, fault.idx.unwrap() as usize)?;
                            reply(MessageInfo::empty());
                        }
                        Fault::VCPUFault(fault) => {
                            assert!(fault.hsr >> 26 == 1);
                            E::handle_wfe(self)?;
                        }
                        Fault::VPPIEvent(fault) => {
                            self.gic.lock().handle_irq(self.node_index, QualifiedIRQ::QualifiedPPI {
                                node: self.node_index,
                                irq: fault.irq as usize,
                            })?;
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
        Ok(())
    }

    fn handle_dist_fault(&mut self, fault: VMFault, offset: usize) -> Fallible<()> {
        assert!(fault.is_valid());
        assert!(fault.is_aligned());
        if fault.is_write() {
            let mut ctx = self.tcb.read_all_registers(false).unwrap();
            let data = fault.data(&ctx);
            self.gic.lock().handle_write(self.node_index, offset, data)?;
            ctx.pc += 4;
            self.tcb.write_all_registers(false, &mut ctx).unwrap();
        } else if fault.is_read() {
            let data = self.gic.lock().handle_read(self.node_index, offset, fault.width())?;
            let mut ctx = self.tcb.read_all_registers(false).unwrap();
            fault.emulate_read(&mut ctx, data);
            ctx.pc += 4;
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
            SYS_KICK => {
                self.sys_kick()?;
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

    fn kick(&self, kick_index: usize) -> Fallible<()> {
        (self.kicks[kick_index])(self)
    }

    fn sys_kick(&mut self) -> Fallible<()> {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        let kick_index = ctx.x0 as usize;
        self.kick(kick_index)?;
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
        Ok(())
    }

    fn handle_exception(&mut self, _ip: Word) {
        panic!();
    }

    pub fn upper_ns_bound_interrupt(&mut self) -> Fallible<Option<i64>> {
        assert_eq!(self.vcpu.read_regs(VCPUReg::CNTVOFF)?, 0);
        assert_eq!(asm::read_cntfrq_el0(), CNTFRQ);
        let cntv_ctl = self.vcpu.read_regs(VCPUReg::CNTV_CTL)?;
        Ok(if (cntv_ctl & asm::CNTV_CTL_EL0_ENABLE) != 0 && (cntv_ctl & asm::CNTV_CTL_EL0_IMASK) == 0 {
            let cntv_cval = self.vcpu.read_regs(VCPUReg::CNTV_CVAL)?;
            let cntvct = asm::read_cntvct_el0();
            let ns = ((((cntv_cval - cntvct) as i128) * 1_000_000_000) / (CNTFRQ as i128)) as i64;
            Some(ns)
        } else {
            None
        })
    }
}
