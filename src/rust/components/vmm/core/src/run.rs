use core::ptr::{read_volatile, write_volatile};
use core::convert::TryFrom;

use alloc::boxed::Box;
use alloc::collections::{VecDeque, BTreeMap};

use icecap_failure::Fallible;
use icecap_sel4::{Fault, fault::*, prelude::*};
use icecap_interfaces::Timer;

use crate::{
    asm, biterate::biterate,
    event::Event,
    gic::{Distributor, IRQ, Action, GIC_DIST_SIZE},
};

// NOTE
// - General principle: use laziness to minimize time spent in the VMM

// TODO
// - For guest, use platform-independant GIC location and virtual timer IRQ

pub const BADGE_EXTERNAL: Badge = 0;
pub const BADGE_VM: Badge = 1;

const SYS_PUTCHAR: Word = 1337;
const SYS_PSCI: Word = 0;
const SYS_CAPUT: Word = 1338;

const CNTV_CTL_EL0_IMASK: u64 = 2 << 0;
const CNTV_CTL_EL0_ENABLE: u64 = 1 << 0;

pub fn run(
    tcb: TCB, vcpu: VCPU, cspace: CNode, fault_reply_cap: Endpoint, timer: Timer,
    gic_dist_vaddr: usize, gic_dist_paddr: usize,
    irqs: BTreeMap<IRQ, IRQType>, real_virtual_timer_irq: IRQ, virtual_timer_irq: IRQ,
    vmm_endpoint: Endpoint,
    caput_write: Option<Endpoint>,
    putchar: impl Fn(u8),
) -> Fallible<()> {
    let mut vm = VM {
        tcb,
        vcpu,
        cspace, fault_reply_cap,
        timer,
        gic_dist_paddr,
        gic_dist: Distributor::new(gic_dist_vaddr as usize),
        irqs,
        real_virtual_timer_irq,
        virtual_timer_irq,

        is_wfi: false,
        lr: LR {
            mirror: [None; 64],
            overflow: VecDeque::new(),
        },

        caput_write,
        putchar,
    };

    vm.gic_dist.reset();
    tcb.resume()?;
    vm.run(vmm_endpoint);
    Ok(())
}

#[derive(Debug)]
pub enum IRQType {
    Passthru(IRQHandler),
    Virtual,
    Timer,
}

struct LR {
    mirror: [Option<IRQ>; 64],
    overflow: VecDeque<IRQ>,
}

struct VM<T> {
    // configuration
    tcb: TCB,
    vcpu: VCPU,
    cspace: CNode, fault_reply_cap: Endpoint,
    timer: Timer,
    gic_dist_paddr: usize,
    gic_dist: Distributor,
    irqs: BTreeMap<IRQ, IRQType>,
    real_virtual_timer_irq: IRQ,
    virtual_timer_irq: IRQ,

    // mutable state
    is_wfi: bool,
    lr: LR,

    caput_write: Option<Endpoint>,
    putchar: T,
}

impl<F: Fn(u8)> VM<F> {

    fn run(&mut self, ep: Endpoint) {
        loop {
            let (info, badge) = ep.recv();
            match badge {
                BADGE_EXTERNAL => {
                    match Event::get(info) {
                        Event::Timeout => {
                            self.pass_wfi();
                        }
                        Event::IRQ(irq) => {
                            self.inject_irq(irq);
                        }
                    }
                }
                BADGE_VM => {
                    let fault = Fault::get(info);
                    match fault {
                        Fault::VMFault(fault) => {
                            self.cspace.save_caller(self.fault_reply_cap).unwrap();
                            self.handle_page_fault(fault);
                            self.fault_reply_cap.send(MessageInfo::empty());
                        }
                        Fault::UnknownSyscall(fault) => {
                            self.handle_syscall(fault.syscall);
                            reply(MessageInfo::empty());
                        }
                        Fault::UserException(fault) => {
                            self.handle_exception(fault.fault_ip);
                        }
                        Fault::VGICMaintenance(fault) => {
                            assert!(fault.idx as i32 >= 0);
                            self.handle_vgic_maintenance(fault.idx as usize);
                            reply(MessageInfo::empty());
                        }
                        Fault::VCPUFault(fault) => {
                            // We only handle WFI/WFE
                            let ctx = self.tcb.read_all_registers(false).unwrap();
                            debug_println!("bb {:x?}", &ctx);
                            assert!(fault.hsr >> 26 == 1);
                            self.handle_wfi();
                        }
                        Fault::VPPIEvent(fault) => {
                            assert!(usize::try_from(fault.irq).unwrap() == self.real_virtual_timer_irq);
                            self.inject_irq(self.virtual_timer_irq);
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
        assert!(fault.is_write());
        let ctx = self.tcb.read_all_registers(false).unwrap();
        let val: u32 = match fault.data(&ctx) {
            VMFaultData::Word(val) => val,
            _ => panic!(),
        };
        let reg = (self.gic_dist.base_addr + offset) as *mut u32;
        let act_on_set = |extra_offset: usize, mut f: Box<dyn FnMut(IRQ)>| {
            let cur = unsafe { *reg };
            let set = val & !cur;
            for i in biterate(set) {
                let irq: usize = i as usize + (offset - extra_offset) * 8;
                f(irq as IRQ);
            }
        };
        match Action::at(offset) {
            Action::ReadOnly => {}
            Action::Passthru => {
                unsafe {
                    write_volatile(reg, val);
                }
            }
            Action::Enable => {
                match val {
                    0 => self.gic_dist.disable(),
                    1 => self.gic_dist.enable(),
                    _ => panic!(),
                }
            }
            Action::EnableSet => {
                act_on_set(0x100, Box::new(|irq| self.enable_irq(irq)));
            }
            Action::EnableClr => {
                act_on_set(0x180, Box::new(|irq| self.disable_irq(irq)));
            }
            Action::PendingSet => {
                act_on_set(0x200, Box::new(|irq| self.set_pending_irq(irq)));
            }
            Action::PendingClr => {
                act_on_set(0x280, Box::new(|irq| self.clr_pending_irq(irq)));
            }
            _ => panic!(),
        }
    }

    fn enable_irq(&mut self, irq: IRQ) {
        self.gic_dist.set_enable(irq, true);
        // TODO SliceIndex trait
        if let Some(_) = self.irqs.get(&irq) {
            if !self.gic_dist.is_pending(irq) {
                self.ack_irq(irq);
            }
        }
    }

    fn disable_irq(&mut self, irq: IRQ) {
        self.gic_dist.set_enable(irq, false);
    }

    fn set_pending_irq(&mut self, irq: IRQ) {
        if let Some(_) = self.irqs.get(&irq) {
            if self.gic_dist.is_dist_enabled() && self.gic_dist.is_enabled(irq) {
                self.gic_dist.set_pending(irq, true);
                self.vcpu_inject_irq(irq);
            }
        }
    }

    fn clr_pending_irq(&mut self, irq: IRQ) {
        self.gic_dist.set_pending(irq, false);
    }

    fn handle_syscall(&mut self, syscall: Word) {
        match syscall {
            SYS_PUTCHAR => {
                self.sys_putchar();
            }
            SYS_PSCI => {
                self.sys_psci();
            }
            SYS_CAPUT => {
                self.sys_caput();
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
                panic!();
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

    fn sys_caput(&self) {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        debug_println!("SYS_CAPUT {:x?}", ctx);
        let label = ctx.x4;
        let length = ctx.x5;
        MR_0.set(ctx.x0);
        MR_1.set(ctx.x1);
        MR_2.set(ctx.x2);
        MR_3.set(ctx.x3);
        let info = self.caput_write.unwrap().call(MessageInfo::new(label, 0, 0, length));
        ctx.x0 = match info.length() {
            0 => 0,
            1 => MR_0.get(),
            _ => panic!(),
        };
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
    }

    fn handle_exception(&mut self, _ip: Word) {
        // TODO pretty-print fault
        panic!();
    }

    fn handle_vgic_maintenance(&mut self, ix: usize) {
        let irq = self.lr.mirror[ix].unwrap();
        self.lr.mirror[ix] = None;
        self.gic_dist.set_pending(irq, false);
        self.ack_irq(irq);
        if let Some(irq) = self.lr.overflow.pop_front() {
            self.vcpu_inject_irq(irq);
        }
    }

    fn handle_wfi(&mut self) {
        // TODO only wait for ns > \epsilon
        // TODO cancel timer once it becomes unecessary (just adds extra spurrious irqs to vm)
        match self.upper_ns_bound_interrupt() {
            None => {
                self.set_wfi();
            }
            Some(ns) if ns > 0 => {
                self.set_wfi();
                self.timer.oneshot_relative(0, ns as u64).unwrap();
            }
            _ => {
                self.advance();
                reply(MessageInfo::empty());
            }
        }
    }

    fn upper_ns_bound_interrupt(&mut self) -> Option<i64> {
        let cntv_ctl = self.vcpu.read_regs(VCPUReg::CNTV_CTL).unwrap();
        if (cntv_ctl & CNTV_CTL_EL0_ENABLE) != 0 && (cntv_ctl & CNTV_CTL_EL0_IMASK) == 0 {
            // TODO use tval?
            let cntv_cval = self.vcpu.read_regs(VCPUReg::CNTV_CVAL).unwrap() as i128;
            let cntfrq = asm::read_cntfrq_el0() as i128;
            let cntvct = asm::read_cntvct_el0() as i128;
            let ns = (((cntv_cval - cntvct) * 1_000_000_000) / cntfrq) as i64;
            Some(ns)
        } else {
            None
        }
    }

    fn ack_irq(&mut self, irq: IRQ) {
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
        }
    }

    fn inject_irq(&mut self, irq: IRQ) {
        self.set_pending_irq(irq);
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
        self.pass_wfi();
    }

    fn set_wfi(&mut self) {
        self.cspace.save_caller(self.fault_reply_cap).unwrap();
        self.is_wfi = true;
    }

    fn pass_wfi(&mut self) {
        if self.is_wfi {
            self.advance();
            self.is_wfi = false;
            self.fault_reply_cap.send(MessageInfo::empty());
        }
    }

    fn advance(&mut self) {
        let mut ctx = self.tcb.read_all_registers(false).unwrap();
        ctx.pc += 4;
        self.tcb.write_all_registers(false, &mut ctx).unwrap();
    }
}
