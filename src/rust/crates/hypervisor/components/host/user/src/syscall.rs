use std::fs::File;
use std::os::unix::io::AsRawFd;
use icecap_rpc::*;
use icecap_host_vmm_types::{sys_id as host_vmm_sys_id, DirectRequest, DirectResponse};
use icecap_resource_server_types::Request;

cfg_if::cfg_if! {
    if #[cfg(target_env = "gnu")] {
        type Ioctl = u64;
    } else if #[cfg(target_env = "musl")] {
        type Ioctl = i32;
    }
}

const ICECAP_VMM_PASSTHRU: u32 = 0xc0403300;
const ICECAP_VMM_YIELD_TO: u32 = 0xc0103301;

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

fn ioctl<T>(request: u32, ptr: *mut T) {
    let f = File::open("/sys/kernel/debug/icecap_vmm").unwrap();
    let ret = unsafe {
        libc::ioctl(f.as_raw_fd(), request as Ioctl, ptr)
    };
    assert_eq!(ret, 0);
}

fn ioctl_passthru(passthru: &mut Passthru) {
    ioctl(ICECAP_VMM_PASSTHRU, passthru as *mut Passthru)
}

fn ioctl_yield_to(yield_to: &mut YieldTo) {
    ioctl(ICECAP_VMM_YIELD_TO, yield_to as *mut YieldTo)
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
    resource_server_passthru(&Request::Declare { realm_id, spec_size })
}

pub fn spec_chunk(realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize, offset: usize) {
    resource_server_passthru(&Request::SpecChunk { realm_id, bulk_data_offset, bulk_data_size, offset })
}

pub fn fill_chunk(realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize, object_index: usize, fill_entry_index: usize, offset: usize) {
    resource_server_passthru(&Request::FillChunk { realm_id, bulk_data_offset, bulk_data_size, object_index, fill_entry_index, offset })
}

pub fn realize(realm_id: usize) {
    resource_server_passthru(&Request::Realize { realm_id })
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
