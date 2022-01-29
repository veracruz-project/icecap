use alloc::collections::BTreeMap;
use alloc::sync::Arc;
use alloc::vec::Vec;

use icecap_core::{
    prelude::*,
    rpc,
    runtime::Thread,
    sel4::fault::*,
    sync::{ExplicitMutexNotification, Mutex},
};
use icecap_event_server_types as event_server;
use icecap_vmm_gic::*;

use crate::psci;

const SYS_PSCI: Word = 0;
const SYS_PUTCHAR: Word = 1337;

const BADGE_FAULT: Badge = 0;

pub struct VMMConfig<E> {
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub event_server_client_ep: Vec<Endpoint>, // HACK per node
    pub irq_map: IRQMap,
    pub gic_dist_paddr: usize,
    pub nodes: Vec<VMMNodeConfig<E>>,

    pub debug: bool,
}

pub struct VMMNodeConfig<E> {
    pub tcb: TCB,
    pub vcpu: VCPU,
    pub ep: Endpoint,
    pub fault_reply_slot: Endpoint,
    pub thread: Thread,
    pub event_server_bitfield: usize, // HACK
    pub extension: E,
}

pub trait VMMExtension: Sized {
    fn handle_wf(node: &mut VMMNode<Self>) -> Fallible<()>;
    fn handle_syscall(node: &mut VMMNode<Self>, fault: &UnknownSyscall) -> Fallible<()>;
    fn handle_putchar(node: &mut VMMNode<Self>, c: u8) -> Fallible<()>;
}

pub struct IRQMap {
    pub ppi: BTreeMap<usize, (event_server::InIndex, bool)>, // (in_index, must_ack)
    pub spi: BTreeMap<usize, (event_server::InIndex, usize, bool)>, // (in_index, nid, must_ack)
}

pub struct VMMNode<E> {
    pub node_index: NodeIndex,

    pub tcb: TCB,
    pub vcpu: VCPU,
    pub ep: Endpoint,

    pub cnode: CNode,
    pub fault_reply_slot: Endpoint,

    pub event_server_client: rpc::Client<event_server::calls::Client>,
    pub event_server_bitfield: event_server::Bitfield,

    pub gic_dist_paddr: usize,
    pub gic: Arc<Mutex<GIC<VMMGICCallbacks>>>,

    pub nodes: Arc<Mutex<Vec<Option<(Thread, VMMNode<E>)>>>>,

    pub extension: E,

    pub debug: bool,
}

pub struct VMMGICCallbacks {
    vcpus: Vec<VCPU>,
    event_server_client: Vec<rpc::Client<event_server::calls::Client>>,
    irq_map: IRQMap,
}

impl<E: 'static + VMMExtension + Send> VMMConfig<E> {
    pub fn run(mut self) -> Fallible<()> {
        let event_server_client_ep = self.event_server_client_ep;

        let nodes = Arc::new(Mutex::new(
            ExplicitMutexNotification::new(self.nodes_lock),
            Vec::new(),
        ));

        let gic = GIC::new(
            self.nodes.len(),
            VMMGICCallbacks {
                irq_map: self.irq_map,
                vcpus: self.nodes.iter().map(|node| node.vcpu).collect(),
                event_server_client: event_server_client_ep
                    .iter()
                    .map(|ep| rpc::Client::<event_server::calls::Client>::new(*ep))
                    .collect(),
            },
        );
        let gic = Arc::new(Mutex::new(
            ExplicitMutexNotification::new(self.gic_lock),
            gic,
        ));

        for (i, node_config) in self.nodes.drain(..).enumerate() {
            let node = VMMNode {
                node_index: i,

                tcb: node_config.tcb,
                vcpu: node_config.vcpu,
                ep: node_config.ep,

                cnode: self.cnode,
                fault_reply_slot: node_config.fault_reply_slot,

                event_server_client: rpc::Client::<event_server::calls::Client>::new(
                    event_server_client_ep[i],
                ),
                event_server_bitfield: unsafe {
                    event_server::Bitfield::new(node_config.event_server_bitfield)
                },

                gic_dist_paddr: self.gic_dist_paddr,
                gic: gic.clone(),

                nodes: nodes.clone(),

                extension: node_config.extension,

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

impl<E: 'static + VMMExtension + Send> VMMNode<E> {
    fn run(&mut self) -> Fallible<()> {
        self.vcpu.write_regs(VCPUReg::CNTVOFF, 0)?;
        self.tcb.resume()?;
        loop {
            let (info, badge) = self.ep.recv();
            match badge {
                BADGE_FAULT => {
                    let fault = Fault::get(info);
                    match fault {
                        Fault::VMFault(fault) => {
                            self.handle_page_fault(fault)?;
                            reply(MessageInfo::empty());
                        }
                        Fault::UnknownSyscall(fault) => {
                            self.handle_syscall(&fault)?;
                        }
                        Fault::VGICMaintenance(fault) => {
                            self.gic
                                .lock()
                                .handle_maintenance(self.node_index, fault.idx.unwrap() as usize)?;
                            reply(MessageInfo::empty());
                        }
                        Fault::VCPUFault(fault) => {
                            if fault.is_wf() {
                                E::handle_wf(self)?;
                            } else {
                                panic!();
                            }
                        }
                        Fault::VPPIEvent(fault) => {
                            let irq = QualifiedIRQ::QualifiedPPI {
                                node: self.node_index,
                                irq: fault.irq as usize,
                            };
                            self.gic.lock().handle_irq(self.node_index, irq)?;
                            reply(MessageInfo::empty());
                        }
                        _ => {
                            panic!("unexpected fault: {:?}", fault);
                        }
                    }
                }
                event_bit_groups => {
                    let mut gic = self.gic.lock();
                    self.event_server_bitfield
                        .clear(event_bit_groups, |bit| -> Fallible<()> {
                            let in_index = bit as usize;
                            // debug_println!("in_index = {}", in_index);
                            let irq = {
                                let mut irq = None;
                                for (ppi, (ppi_in_index, _must_ack)) in &gic.callbacks().irq_map.ppi
                                {
                                    if *ppi_in_index == in_index {
                                        irq = Some(QualifiedIRQ::QualifiedPPI {
                                            node: self.node_index,
                                            irq: *ppi,
                                        });
                                        break;
                                    }
                                }
                                if let None = irq {
                                    for (spi, (spi_in_index, nid, _must_ack)) in
                                        &gic.callbacks().irq_map.spi
                                    {
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
                            Ok(())
                        })?;
                }
            }
        }
    }

    fn handle_page_fault(&mut self, fault: VMFault) -> Fallible<()> {
        let addr = fault.addr as usize;
        if self.gic_dist_paddr <= addr
            && addr < self.gic_dist_paddr + GIC::<VMMGICCallbacks>::DISTRIBUTOR_SIZE
        {
            let offset = addr - self.gic_dist_paddr;
            self.handle_dist_fault(fault, offset)?;
        } else {
            panic!("unhandled page fault: {:x?}", fault);
        }
        Ok(())
    }

    fn handle_dist_fault(&mut self, fault: VMFault, offset: usize) -> Fallible<()> {
        assert!(fault.is_valid());
        assert!(fault.is_aligned());
        if fault.is_write() {
            let mut ctx = self.tcb.read_all_registers(false).unwrap();
            let data = fault.data(&ctx);
            self.gic
                .lock()
                .handle_write(self.node_index, offset, data)?;
            ctx.advance();
            self.tcb.write_all_registers(false, &mut ctx).unwrap();
        } else if fault.is_read() {
            let data = self
                .gic
                .lock()
                .handle_read(self.node_index, offset, fault.width())?;
            let mut ctx = self.tcb.read_all_registers(false).unwrap();
            fault.emulate_read(&mut ctx, data);
            ctx.advance();
            self.tcb.write_all_registers(false, &mut ctx).unwrap();
        } else {
            panic!();
        }
        Ok(())
    }

    fn handle_syscall(&mut self, fault: &UnknownSyscall) -> Fallible<()> {
        Ok(match fault.syscall {
            SYS_PUTCHAR => self.sys_putchar(fault)?,
            SYS_PSCI => self.sys_psci(fault)?,
            _ => E::handle_syscall(self, fault)?,
        })
    }

    fn sys_putchar(&mut self, fault: &UnknownSyscall) -> Fallible<()> {
        E::handle_putchar(self, fault.x0 as u8)?;
        fault.advance_and_reply();
        Ok(())
    }

    fn sys_psci(&self, fault: &UnknownSyscall) -> Fallible<()> {
        let fid = fault.x0 as u32;
        let ret = match fid {
            psci::FID_PSCI_VERSION => psci::VERSION,
            psci::FID_PSCI_FEATURES => {
                let qfid = fault.x1 as u32;
                match qfid {
                    psci::FID_CPU_ON => {
                        0 // no feature flags
                    }
                    _ => psci::RET_NOT_SUPPORTED,
                }
            }
            psci::FID_CPU_ON => {
                let target = fault.x1 as usize;
                let entry = fault.x2 as u64;
                let ctx_id = fault.x3 as u64;
                let (thread, mut node) = {
                    let mut this = None;
                    let mut nodes = self.nodes.lock();
                    core::mem::swap(&mut this, &mut nodes[target]);
                    this.unwrap()
                };
                thread.start(move || {
                    let mut ctx = node.tcb.read_all_registers(false).unwrap();
                    *ctx.pc_mut() = entry;
                    *ctx.gpr_mut(0) = ctx_id;
                    node.tcb.write_all_registers(false, &mut ctx).unwrap();
                    node.run().unwrap()
                });
                psci::RET_SUCCESS
            }
            psci::FID_MIGRATE_INFO_TYPE => psci::RET_NOT_SUPPORTED,
            _ => {
                panic!("unexpected psci fid {:x}", fid);
            }
        };
        UnknownSyscall::mr_gpr(0).set(ret as u64);
        fault.advance_and_reply();
        Ok(())
    }
}

impl GICCallbacks for VMMGICCallbacks {
    fn ack(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ) -> Fallible<()> {
        match irq {
            QualifiedIRQ::QualifiedPPI { node, irq } => {
                // assert_eq!(calling_node, node); // TODO
                if let Some((in_index, must_ack)) = self.irq_map.ppi.get(&irq) {
                    if *must_ack {
                        self.event_server_client[calling_node].call::<()>(
                            &event_server::calls::Client::End {
                                nid: calling_node,
                                index: *in_index,
                            },
                        );
                    }
                } else {
                    self.vcpus[node].ack_vppi(irq as u64)?;
                }
            }
            QualifiedIRQ::SPI { irq } => {
                if let Some((in_index, nid, must_ack)) = self.irq_map.spi.get(&irq) {
                    if *must_ack {
                        self.event_server_client[calling_node].call::<()>(
                            &event_server::calls::Client::End {
                                nid: *nid,
                                index: *in_index,
                            },
                        );
                    }
                } else {
                    // panic!("unbound irq: {}", irq); // TODO
                }
            }
        }
        Ok(())
    }

    fn vcpu_inject_irq(
        &mut self,
        calling_node: NodeIndex,
        target_node: NodeIndex,
        index: usize,
        irq: IRQ,
        priority: usize,
    ) -> Fallible<()> {
        if calling_node != target_node && irq > 15 {
            debug_println!(
                "warning: cross-core vcpu_inject_irq({}), node:{} -> node:{}",
                irq,
                calling_node,
                target_node
            );
        }
        self.vcpus[target_node].inject_irq(irq as u16, priority as u8, 0, index as u8)?;
        Ok(())
    }

    fn set_affinity(
        &mut self,
        calling_node: NodeIndex,
        irq: SPI,
        affinity: NodeIndex,
    ) -> Fallible<()> {
        debug_println!(
            "VMMGICCallbacks::set_affinity({}, {}, {})",
            calling_node,
            irq,
            affinity
        );
        // TODO
        Ok(())
    }

    fn set_priority(
        &mut self,
        calling_node: NodeIndex,
        irq: QualifiedIRQ,
        priority: usize,
    ) -> Fallible<()> {
        debug_println!(
            "VMMGICCallbacks::set_priority({}, {:?}, {})",
            calling_node,
            irq,
            priority
        );
        self.configure(
            calling_node,
            irq,
            event_server::ConfigureAction::SetPriority(priority),
        )
    }

    fn set_enabled(
        &mut self,
        calling_node: NodeIndex,
        irq: QualifiedIRQ,
        enabled: bool,
    ) -> Fallible<()> {
        self.configure(
            calling_node,
            irq,
            event_server::ConfigureAction::SetEnabled(enabled),
        )
    }
}

impl VMMGICCallbacks {
    fn configure(
        &mut self,
        calling_node: NodeIndex,
        irq: QualifiedIRQ,
        action: event_server::ConfigureAction,
    ) -> Fallible<()> {
        debug_println!(
            "VMMGICCallbacks::configure({}, {:?}, {:?})",
            calling_node,
            irq,
            action
        );
        match irq {
            QualifiedIRQ::QualifiedPPI { node, irq } => {
                // assert_eq!(calling_node, node); // TODO
                if let Some((in_index, _must_ack)) = self.irq_map.ppi.get(&irq) {
                    self.event_server_client[calling_node].call::<()>(
                        &event_server::calls::Client::Configure {
                            nid: calling_node,
                            index: *in_index,
                            action,
                        },
                    );
                } else {
                    self.vcpus[node].ack_vppi(irq as u64)?;
                }
            }
            QualifiedIRQ::SPI { irq } => {
                if let Some((in_index, nid, _must_ack)) = self.irq_map.spi.get(&irq) {
                    self.event_server_client[calling_node].call::<()>(
                        &event_server::calls::Client::Configure {
                            nid: *nid,
                            index: *in_index,
                            action,
                        },
                    );
                } else {
                    panic!("unbound irq: {}", irq); // TODO
                }
            }
        }
        Ok(())
    }
}
