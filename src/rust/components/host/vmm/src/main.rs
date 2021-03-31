#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![allow(unused_variables)]
#![allow(unused_imports)]
#![allow(unreachable_code)]

extern crate alloc;

use core::convert::TryFrom;
use core::sync::atomic::{AtomicBool, Ordering};
use alloc::collections::btree_map::BTreeMap;
use alloc::sync::Arc;

use biterate::biterate;

use icecap_std::prelude::*;
use icecap_rpc_sel4::*;
use icecap_host_vmm_config::*;
use icecap_vmm::*;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    let con = BufferedRingBuffer::new(RingBuffer::realize_resume_unmanaged(&config.con));
    // icecap_std::set_print(con);

    let ep_writes: Arc<Vec<Endpoint>> = Arc::new(config.nodes.iter().map(|node| node.ep_write).collect());

    let mut irq_handlers = BTreeMap::new();

    for group in config.passthru_irqs {
        for irq in &group.bits {
            if let Some(irq) = irq {
                irq.handler.ack().unwrap();
                irq_handlers.insert(irq.irq, irq.handler);
            }
        }
        group.thread.start({
            let nfn = group.nfn;
            let bits: Vec<Option<IRQ>> = group.bits.iter().map(|bit| bit.as_ref().map(|x| x.irq)).collect();
            let ep_writes = Arc::clone(&ep_writes);
            move || {
                loop {
                    let badge = nfn.wait();
                    for i in biterate(badge) {
                        let node = 0;
                        let spi = bits[i as usize].unwrap();
                        RPCClient::<usize>::new(ep_writes[node]).call::<()>(&spi);
                    }
                }
            }
        })
    }

    for group in config.virtual_irqs {
        group.thread.start({
            let nfn = group.nfn;
            let bits = group.bits.clone();
            let ep_writes = Arc::clone(&ep_writes);
            move || {
                loop {
                    let badge = nfn.wait();
                    for i in biterate(badge) {
                        let node = 0; // TODO
                        let spi = bits[i as usize].unwrap();
                        RPCClient::<usize>::new(ep_writes[node]).call::<()>(&spi);
                    }
                }
            }
        })
    }

    let resource_server_ep_write = config.resource_server_ep_write;

    VMMConfig {
        cnode: config.cnode,
        gic_lock: config.gic_lock,
        nodes_lock: config.nodes_lock,
        irq_handlers: irq_handlers,
        gic_dist_paddr: config.gic_dist_paddr,
        nodes: config.nodes.iter().map(|node| {
            VMMNodeConfig {
                tcb: node.tcb,
                vcpu: node.vcpu,
                ep: node.ep_read,
                fault_reply_slot: node.fault_reply_slot,
                thread: node.thread,
                extension: Extension {
                    resource_server_ep_write,
                },
            }
        }).collect(),
    }.run()
}

struct Extension {
    resource_server_ep_write: Endpoint,
}

const SYS_RESOURCE_SERVER_PASSTHRU: Word = 1338;

impl VMMExtension for Extension {

    fn handle_wfe(node: &mut VMMNode<Self>) -> Fallible<()> {
        panic!("wfe");
        Ok(())
    }

    fn handle_syscall(node: &mut VMMNode<Self>, syscall: u64) -> Fallible<()> {
        match syscall {
            SYS_RESOURCE_SERVER_PASSTHRU => {
                Self::sys_resource_server_passthru(node)?;
            }
            _ => {
                panic!("unknown syscall");
            }
        }
        Ok(())
    }

    fn handle_putchar(node: &mut VMMNode<Self>, c: u8) -> Fallible<()> {
        debug_print!("{}", c as char);
        Ok(())
    }
}

impl Extension {

    fn sys_resource_server_passthru(node: &mut VMMNode<Self>) -> Fallible<()> {
        let mut ctx = node.tcb.read_all_registers(false)?;
        let length = ctx.x0 as usize;
        let parameters = &[ctx.x1, ctx.x2, ctx.x3, ctx.x4, ctx.x5, ctx.x6][..length];
        let recv_info = node.extension.resource_server_ep_write.call(proxy::up(parameters));
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
        node.tcb.write_all_registers(false, &mut ctx)?;
        Ok(())
    }
}
