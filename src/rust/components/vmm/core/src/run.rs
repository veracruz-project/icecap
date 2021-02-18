use core::ptr::{read_volatile, write_volatile};
use core::convert::TryFrom;
use core::sync::atomic::{AtomicBool, Ordering};

use alloc::vec::Vec; // TODO: Implement Mailbox with static arrays.
use alloc::boxed::Box;
use alloc::collections::{VecDeque, BTreeMap};

use icecap_failure::Fallible;
use icecap_sel4::{Fault, fault::*, prelude::*};
use icecap_rpc_sel4::*;

use crate::{
    asm, biterate::biterate,
    event::Event,
    gic::{Distributor, IRQType, IRQ, CPU, GIC_DIST_SIZE, WriteAction, ReadAction,
    PPIAction, SPIAction, SGIAction, AckAction},
};

// NOTE
// - General principle: use laziness to minimize time spent in the VMM

// TODO
// - For guest, use platform-independant GIC location and virtual timer IRQ

pub const BADGE_EXTERNAL: Badge = 0;
pub const BADGE_VM: Badge = 1;

const SYS_PUTCHAR: Word = 1337;
const SYS_PSCI: Word = 0;
const SYS_RESOURCE_SERVER_PASSTHRU: Word = 1338;

const CNTV_CTL_EL0_IMASK: u64 = 2 << 0;
const CNTV_CTL_EL0_ENABLE: u64 = 1 << 0;

pub struct Mailbox {
    pub irq: Vec<AtomicBool>,
}

impl Mailbox {
    pub fn new() -> Self {
        Self {
            irq: (0..1020).map(|_| AtomicBool::new(false)).collect(),
        }
    }

    fn add_irq(&self, irq: IRQ) {
        self.irq[irq].store(true, Ordering::SeqCst);
    }
}

pub fn run(
    node_index: usize,
    tcb: TCB, vcpu: VCPU, cspace: CNode, fault_reply_cap: Endpoint,
    gic_dist: &Distributor, gic_dist_paddr: usize,
    irqs: &BTreeMap<IRQ, IRQType>, real_virtual_timer_irq: IRQ, virtual_timer_irq: IRQ,
    vmm_endpoint: Endpoint, start_eps: &[Endpoint], nfn_writes: &[Notification],
    mailboxes: &[Mailbox], putchar: impl Fn(u8),
    resource_server_write: Option<Endpoint>,
) -> Fallible<()> {
    let mut vm = VM {
        node_index,
        tcb,
        vcpu,
        cspace, fault_reply_cap,
        gic_dist_paddr,
        gic_dist,
        irqs,
        real_virtual_timer_irq,
        virtual_timer_irq,
        start_eps,
        nfn_writes,
        mailboxes,

        lr: LR {
            mirror: [None; 64],
            overflow: VecDeque::new(),
        },

        resource_server_write,
        putchar,
    };

    vm.vcpu.write_regs(VCPUReg::VMPIDR_EL2, node_index as Word)?;

    if node_index == 0 {
        tcb.resume()?;
    } else {
        let (_info, _badge) = start_eps[node_index - 1].recv();
        let entry = MR_0.get();
        let ctx_id = MR_1.get();
        let mut ctx = vm.tcb.read_all_registers(false).unwrap();
        ctx.pc = entry;
        ctx.x0 = ctx_id;
        vm.tcb.write_all_registers(false, &mut ctx).unwrap();
        vm.tcb.resume();
    }
    vm.run(vmm_endpoint);
    Ok(())
}

struct LR {
    mirror: [Option<IRQ>; 64],
    overflow: VecDeque<IRQ>,
}

// TODO: Does it make sense to rename this something like VMM_VCPU
// since it now basically corresponds with a single threaded vcpu?
// It will also have a single associated seL4 vcpu and be pinned
// to a single core...
struct VM<'a, T> {
    // configuration
    node_index: usize,
    tcb: TCB,
    vcpu: VCPU,
    cspace: CNode, fault_reply_cap: Endpoint,
    gic_dist_paddr: usize,
    gic_dist: &'a Distributor,
    irqs: &'a BTreeMap<IRQ, IRQType>,
    real_virtual_timer_irq: IRQ,
    virtual_timer_irq: IRQ,
    start_eps: &'a [Endpoint],
    nfn_writes: &'a [Notification],
    mailboxes: &'a [Mailbox],

    // mutable state
    lr: LR,

    resource_server_write: Option<Endpoint>,
    putchar: T,
}

impl<'a, F: Fn(u8)> VM<'a, F> {

    fn run(&mut self, ep: Endpoint) {
        loop {
            let (info, badge) = ep.recv();
            match badge {
                BADGE_EXTERNAL => {
                    match Event::get(info) {
                        Event::SPI(irq) => {
                            let val = self.gic_dist.handle_spi(irq);
                            match val {
                                SPIAction::InjectIRQ => {
                                    self.vcpu_inject_irq(irq);
                                }
                                _ => {}
                            }
                        }
                        Event::SGI(irq) => {
                            let val = self.gic_dist.handle_sgi(irq, self.node_index);
                            match val {
                                SGIAction::InjectIRQ => {
                                    self.vcpu_inject_irq(irq);
                                }
                                _ => {}
                            }
                        }
                    }
                }
                BADGE_VM => {
                    let fault = Fault::get(info);
                    // if self.node_index > 0 {
                    //     debug_println!("fault on node {}: {:?}", self.node_index, fault);
                    // }
                    match fault {
                        Fault::VMFault(fault) => {
                            // handle_page_fault() clobbers the reply capability
                            // in the TCB, so we'll save it to fault_reply_cap
                            // to invoke after we've handled the fault.
                            // TODO: Avoid clobber to avoid this syscall.
                            self.cspace.save_caller(self.fault_reply_cap).unwrap();
                            self.handle_page_fault(fault);
                            self.fault_reply_cap.send(MessageInfo::empty());
                        }
                        Fault::UnknownSyscall(fault) => {
                            self.cspace.save_caller(self.fault_reply_cap).unwrap();
                            self.handle_syscall(fault.syscall);
                            self.fault_reply_cap.send(MessageInfo::empty());
                        }
                        Fault::UserException(fault) => {
                            self.handle_exception(fault.fault_ip);
                            panic!("Fault::UserException{:?}", fault);
                        }
                        Fault::VGICMaintenance(fault) => {
                            assert!(fault.idx as i32 >= 0);
                            self.handle_vgic_maintenance(fault.idx as usize);
                            reply(MessageInfo::empty());
                        }
                        Fault::VCPUFault(fault) => {
                            // We only handle WFI/WFE
                            assert!(fault.hsr >> 26 == 1);
                            panic!("WFI");
                        }
                        Fault::VPPIEvent(fault) => {
                            assert!(usize::try_from(fault.irq).unwrap() == self.real_virtual_timer_irq);
                            let val = self.gic_dist.handle_ppi(self.virtual_timer_irq, self.node_index);
                            match val {
                                PPIAction::InjectIRQ => {
                                    self.vcpu_inject_irq(self.virtual_timer_irq);
                                }
                                _ => {}
                            }
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

    fn handle_page_fault(&mut self, fault: VMFault) {
        let addr = fault.addr as usize;
        if addr >= self.gic_dist_paddr && addr < self.gic_dist_paddr + GIC_DIST_SIZE {
            let offset = addr - self.gic_dist_paddr;
            self.handle_dist_fault(fault, offset);
        } else {
            // TODO pretty-print fault
            panic!("unhandled page fault at 0x{:x}", addr);
        }
        self.advance();
    }

    fn handle_dist_fault(&mut self, fault: VMFault, offset: usize) {
        assert!(fault.is_valid());
        assert!(fault.is_aligned());

        if fault.is_write() {
            let ctx = self.tcb.read_all_registers(false).unwrap();
            let val = fault.data(&ctx);

            let write_action = self.gic_dist.handle_write(offset, self.node_index, val);
            match write_action {
                WriteAction::NoAction => {}
                WriteAction::InjectAndAckIRQs((to_inject, to_ack)) => {
                    // Handle acks
                    if let Some(to_ack) = to_ack {
                        for (irq, cpu) in to_ack.iter() {
                            // Only ack registered IRQs on this CPU.
                            if *cpu == self.node_index {
                                if let Some(_) = self.irqs.get(irq) {
                                    self.ack_irq(*irq);
                                }
                            }
                        }
                    }

                    // Handle injections
                    if let Some(to_inject) = to_inject {
                        for (irq, cpu) in to_inject.iter() {
                            // Only ack registered IRQs on this CPU. Forward IRQs
                            // to other CPUs for action, where appropriate.
                            if *cpu == self.node_index {
                                if let Some(_) = self.irqs.get(irq) {
                                    self.ack_irq(*irq);
                                }
                            } else if *cpu < self.nfn_writes.len() {
                                self.mailboxes[*cpu].add_irq(*irq);

                                // Notify any other CPUs of IRQs in their mailboxes
                                // TODO: This is inefficient.  Should wait for all
                                // additions to the mailboxes and signal at the end,
                                // but would need a way to track additions to each
                                // mailbox to only notify affected CPUs.
                                self.nfn_writes[*cpu].signal();
                            }
                        }
                    }
                }
                _ => panic!("Unexpected WriteAction")
            };
        } else if fault.is_read() {
            let (val, read_action) = self.gic_dist.handle_read(offset, self.node_index, fault.width());
            match read_action {
                ReadAction::NoAction => {}
                _ => panic!("Unexpected ReadAction")
            };
            let mut ctx = self.tcb.read_all_registers(false).unwrap();
            fault.emulate_read(&mut ctx, val);
            self.tcb.write_all_registers(false, &mut ctx).unwrap();
        } else {
            panic!();
        }
    }

    fn handle_syscall(&mut self, syscall: Word) {
        match syscall {
            SYS_PUTCHAR => {
                self.sys_putchar();
            }
            SYS_PSCI => {
                self.sys_psci();
            }
            SYS_RESOURCE_SERVER_PASSTHRU => {
                self.sys_resource_server_passthru();
            }
            _ => {
                panic!();
            }
        }
    }

    fn sys_putchar(&self) {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        let c = ctx.x0 as u8;
        (self.putchar)(c);
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
    }

    fn sys_psci(&self) {
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
                let target = ctx.x1 as u64;
                let entry = ctx.x2 as u64;
                let ctx_id = ctx.x3 as u64;
                debug_println!("cpu_on: {:x} {:x} {:x}", target, entry, ctx_id);
                MR_0.set(entry);
                MR_1.set(ctx_id);
                self.start_eps[target as usize - 1].send(MessageInfo::new(0, 0, 0, 2));
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
    }

    fn sys_resource_server_passthru(&self) {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        let length = ctx.x0 as usize;
        let parameters = &[ctx.x1, ctx.x2, ctx.x3, ctx.x4, ctx.x5, ctx.x6][..length];
        let recv_info = self.resource_server_write.unwrap().call(proxy::up(parameters));
        let mut r = proxy::down(&recv_info);
        assert!(r.len() <= 6);
        ctx.x0 = r.len() as u64;
        r.resize_with(6, || 0);
        ctx.x1 = r[0];
        ctx.x2 = r[1];
        ctx.x3 = r[2];
        ctx.x4 = r[3];
        ctx.x5 = r[4];
        ctx.x6 = r[5];
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
    }

    fn handle_exception(&mut self, _ip: Word) {
        // TODO pretty-print fault
        panic!();
    }

    // We expect VGICMaintenance events when the VM is done servicing the IRQ.
    fn handle_vgic_maintenance(&mut self, ix: usize) {
        let irq = self.lr.mirror[ix].unwrap();
        self.lr.mirror[ix] = None;
        self.ack_irq(irq);
        if let Some(irq) = self.lr.overflow.pop_front() {
            self.vcpu_inject_irq(irq);
        }
    }

    // This effectively skips the traditional acknowledgement state change
    // from pending -> active and acts like an End of Interrupt, clearing
    // the pending state of the IRQ in the GIC distributor and performing
    // any necessary acknowledgements with the hypervisor.
    fn ack_irq(&mut self, irq: IRQ) {
        // Handle the GIC distributor
        let ack = self.gic_dist.handle_ack(irq, self.node_index);
        match ack {
            AckAction::NoAction => {},
            _ => panic!("Unexpected result while acknowledging IRQ {}", irq)
        }

        // Perform any other actions
        let ty = &self.irqs[&irq];
        match ty {
            IRQType::Virtual => {
            }
            IRQType::Timer => {
                self.vcpu.ack_vppi(u64::try_from(irq).unwrap()).unwrap()
            }
            IRQType::Passthru(handler) => {
                handler.ack().unwrap()
            }
            IRQType::SGI => {
            }
        }
    }

    fn vcpu_inject_irq(&mut self, irq: IRQ) {
        // TODO only add if not already in either mirror or overflow
        let mut ix = 64;
        for (i, x) in self.lr.mirror.iter().enumerate() {
            if let None = x {
                ix = i;
                break;
            }
        }
        if self.vcpu.inject_irq(irq as u16, 0, 0, ix as u8).is_ok() {
            // TODO is this right?
            assert!(ix < 64);
            self.lr.mirror[ix] = Some(irq);
        } else {
            self.lr.overflow.push_back(irq);
        }
    }

    fn advance(&mut self) {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
    }
}
