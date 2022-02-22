#![no_std]
#![no_main]

extern crate alloc;
use alloc::format;

use core::convert::TryFrom;
use core::ops::Range;

use serde::{Deserialize, Serialize};

use icecap_driver_interfaces::TimerDevice;
use icecap_start_generic::declare_generic_main;
use icecap_std::{prelude::*, rpc};
use icecap_virt_timer_driver::VirtTimerDevice;

use timer_server_types::{Request, NS_IN_S};

use virtio_drivers::VirtIOConsole;
use virtio_drivers::VirtIOHeader;
// not sure why this is private in virtio_drivers
const VIRTIO_PAGE_SIZE: usize = 4096;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    loop_ep: Endpoint,
    dev_vaddr: usize,
    irq_handler: IRQHandler,
    client_timeout: Notification,
    virtio_region: Range<usize>,
    virtio_pool: Range<usize>,
    virtio_pages: Vec<SmallPage>,
    badges: Badges,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Badges {
    irq: Badge,
    client: Badge,
}

struct VirtioPool {
    pool: &'static mut [u8],
    paddr: usize,
    mark: usize,
}

static mut VIRTIO_POOL: Option<VirtioPool> = None;

fn main(config: Config) -> Fallible<()> {
    debug_println!("hello from timer (now virtio) server");
    debug_println!("{:#?}", config);
    
    // is the virtio region mapped correctly?
    for (i, v) in config.virtio_region.clone().step_by(512).enumerate() {
        debug_println!("virtio{}@{:012x}: {:08x} {:08x} {:08x} {:08x}",
            i,
            v,
            unsafe { core::ptr::read_volatile((v+ 0) as *const u32) },
            unsafe { core::ptr::read_volatile((v+ 4) as *const u32) },
            unsafe { core::ptr::read_volatile((v+ 8) as *const u32) },
            unsafe { core::ptr::read_volatile((v+12) as *const u32) },
        );
    }

    // test pool was allocated correctly
    for (_, (addr, page)) in
        config.virtio_pool.clone().step_by(4096)
            .zip(&config.virtio_pages)
            .enumerate()
    {
        debug_println!("virtio_pool@{:012x} = {:012x}", addr, page.paddr().unwrap_or(0));
    }

    // setup the virtio pool
    unsafe {
        VIRTIO_POOL = Some(VirtioPool {
            pool: core::slice::from_raw_parts_mut(
                config.virtio_pool.start as *mut u8,
                config.virtio_pool.end - config.virtio_pool.start,
            ),
            paddr: config.virtio_pages[0].paddr().unwrap(),
            mark: 0,
        });
    }

    // initialize virtio driver
    for (i, v) in config.virtio_region.clone().step_by(512).enumerate() {
        let id = unsafe { core::ptr::read_volatile((v+ 8) as *const u32) };
        if id != 3 {
            continue;
        }

        debug_println!("found virtio-console at virtio{}@{:012x}, initializing...", i, v);
        let mmio = unsafe { &mut *(v as *mut VirtIOHeader) };
        let mut console = VirtIOConsole::new(mmio).unwrap();
        for c in format!("hello over virtio{}@{:012x}!\r\n\r\n", i, v).bytes() {
            console.send(c).unwrap();
        }
    }

    debug_println!("done!");
    loop {}
//
//
//
//
//
//
//    debug_println!("HELLO FROM TIMER SERVER");
//    loop {}
//
//    let dev = VirtTimerDevice::new(config.dev_vaddr);
//    dev.set_enable(false);
//    dev.clear_interrupt();
//    config.irq_handler.ack()?;
//
//    let freq = dev.get_freq().into();
//    let ns_to_ticks = |ns| convert(ns, freq, NS_IN_S);
//    let ticks_to_ns = |ticks| convert(ticks, NS_IN_S, freq);
//
//    let mut compare_state: Option<u64> = None;
//
//    loop {
//        let (info, badge) = config.loop_ep.recv();
//        if badge & config.badges.irq != 0 {
//            if let Some(compare) = compare_state {
//                if compare <= dev.get_count() {
//                    compare_state = None;
//                    config.client_timeout.signal();
//                    dev.set_enable(false);
//                }
//            }
//            dev.clear_interrupt();
//            config.irq_handler.ack()?;
//        }
//        if badge & config.badges.client != 0 {
//            match rpc::server::recv::<Request>(&info) {
//                Request::SetTimeout(ns) => {
//                    let ticks = ns_to_ticks(ns);
//                    let compare = ticks + dev.get_count();
//                    compare_state = Some(compare);
//                    dev.set_compare(compare);
//                    dev.set_enable(true);
//                    rpc::server::reply(&());
//                }
//                Request::GetTime => {
//                    let ticks = dev.get_count();
//                    let response = ticks_to_ns(ticks);
//                    rpc::server::reply(&response);
//                }
//            }
//        }
//    }
}

// NOTE this function is correct on the domain relevant to this example
fn convert(value: u64, numerator: u64, denominator: u64) -> u64 {
    u64::try_from((u128::from(value) * u128::from(numerator)) / u128::from(denominator)).unwrap()
}


// mappings for virtio
#[no_mangle]
pub unsafe extern "C" fn virtio_dma_alloc(pages: usize) -> usize {
    debug_println!("virtio_pool: allocating {}x{} pages", pages, VIRTIO_PAGE_SIZE);
    let pool = VIRTIO_POOL.as_mut().unwrap();
    if pool.mark + pages*VIRTIO_PAGE_SIZE > pool.pool.len() {
        debug_println!("virtio_pool: out of pages ({}/{})!",
            pool.pool.len() / VIRTIO_PAGE_SIZE,
            pool.pool.len() / VIRTIO_PAGE_SIZE
        );
    }

    let old_mark = pool.mark;
    pool.mark += pages*VIRTIO_PAGE_SIZE;
    let p = &mut pool.pool[old_mark] as *mut _ as usize;
    debug_println!("virtio: allocating {}x{} pages -> {:012x}", pages, VIRTIO_PAGE_SIZE, virtio_virt_to_phys(p as usize));
    virtio_virt_to_phys(p as usize)
}

#[no_mangle]
pub unsafe extern "C" fn virtio_dma_dealloc(paddr: usize, pages: usize) -> i32 {
    debug_println!("virtio_pool: deallocating {:012x}", paddr);
    let pool = VIRTIO_POOL.as_mut().unwrap();
    debug_assert!(pool.pool.as_ptr_range().contains(&(virtio_phys_to_virt(paddr) as *const u8)));
    0
}

#[no_mangle]
pub unsafe extern "C" fn virtio_phys_to_virt(paddr: usize) -> usize {
    let pool = VIRTIO_POOL.as_mut().unwrap();
    debug_println!("map_pv {:012x} => {:012x}", paddr, paddr - pool.paddr + (pool.pool.as_ptr() as usize));
    paddr - pool.paddr + (pool.pool.as_ptr() as usize)
}

#[no_mangle]
pub unsafe extern "C" fn virtio_virt_to_phys(vaddr: usize) -> usize {
    let pool = VIRTIO_POOL.as_mut().unwrap();
    debug_println!("map_vp {:012x} => {:012x}", vaddr, vaddr - (pool.pool.as_ptr() as usize) + pool.paddr);
    vaddr - (pool.pool.as_ptr() as usize) + pool.paddr
}

