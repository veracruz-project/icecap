use std::fs::File;
use std::os::unix::io::AsRawFd;
use std::path::Path;

use hypervisor_host_vmm_types::{sys_id as host_vmm_sys_id, DirectRequest, DirectResponse};
use hypervisor_resource_server_types::Request;
use icecap_rpc_types::*;

cfg_if::cfg_if! {
    if #[cfg(target_env = "gnu")] {
        type Ioctl = u64;
    } else if #[cfg(target_env = "musl")] {
        type Ioctl = i32;
    }
}

const ICECAP_VMM_PASSTHRU: u32 = 0xc0403300;
const ICECAP_RESOURCE_SERVER_YIELD_TO: u32 = 0xc0103301;

const ICECAP_VMM_IOCTL_PATH: &'static str = "/sys/kernel/debug/icecap_vmm";
const ICECAP_RESOURCE_SERVER_IOCTL_PATH: &'static str = "/dev/icecap_resource_server";

#[repr(C)]
struct Passthru {
    sys_id: u64,
    regs: [u64; 7],
}

#[repr(C)]
struct YieldTo {
    realm_id: u64,
    virtual_node: u64,
}

fn ioctl<T>(path: impl AsRef<Path>, request: u32, ptr: *mut T) {
    let f = File::open(path).unwrap();
    let ret = unsafe { libc::ioctl(f.as_raw_fd(), request as Ioctl, ptr) };
    assert_eq!(ret, 0);
}

fn ioctl_passthru(passthru: &mut Passthru) {
    ioctl(
        ICECAP_VMM_IOCTL_PATH,
        ICECAP_VMM_PASSTHRU,
        passthru as *mut Passthru,
    )
}

fn ioctl_yield_to(yield_to: &mut YieldTo) {
    ioctl(
        ICECAP_RESOURCE_SERVER_IOCTL_PATH,
        ICECAP_RESOURCE_SERVER_YIELD_TO,
        yield_to as *mut YieldTo,
    )
}

//

fn call_passthru<Input: RPC, Output: RPC>(sys_id: u64, input: &Input) -> Output {
    let mut v_in = input.send_to_vec();
    let length = v_in.len();
    assert!(length <= 6);
    v_in.resize_with(6, || 0);
    let mut passthru = Passthru {
        sys_id,
        regs: [0; 7],
    };
    passthru.regs[0] = length as u64;
    passthru.regs[1..].copy_from_slice(&v_in);
    ioctl_passthru(&mut passthru);
    Output::recv_from_slice(&passthru.regs[1..][..passthru.regs[0] as usize])
}

pub fn direct(request: &DirectRequest) -> DirectResponse {
    call_passthru(host_vmm_sys_id::DIRECT, request)
}

fn resource_server_passthru<Output: RPC>(request: &Request) -> Output {
    call_passthru(host_vmm_sys_id::RESOURCE_SERVER_PASSTHRU, request)
}

//

pub fn declare(realm_id: usize, spec_size: usize) {
    resource_server_passthru(&Request::Declare {
        realm_id,
        spec_size,
    })
}

pub fn spec_chunk(realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize, offset: usize) {
    resource_server_passthru(&Request::SpecChunk {
        realm_id,
        bulk_data_offset,
        bulk_data_size,
        offset,
    })
}

pub fn fill_chunks(realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize) {
    resource_server_passthru(&Request::FillChunks {
        realm_id,
        bulk_data_offset,
        bulk_data_size,
    })
}

pub fn realize_start(realm_id: usize) {
    resource_server_passthru(&Request::RealizeStart { realm_id })
}

pub fn realize_finish(realm_id: usize) {
    resource_server_passthru(&Request::RealizeFinish { realm_id })
}

pub fn destroy(realm_id: usize) {
    resource_server_passthru(&Request::Destroy { realm_id })
}

pub fn hack_run(realm_id: usize) {
    resource_server_passthru(&Request::HackRun { realm_id })
}

//

pub fn yield_to(realm_id: usize, virtual_node: usize) {
    let mut yield_to = YieldTo {
        realm_id: realm_id as u64,
        virtual_node: virtual_node as u64,
    };
    ioctl_yield_to(&mut yield_to);
}
