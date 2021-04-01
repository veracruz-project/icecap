use libc::{syscall, c_long};
use std::fs::File;
use std::os::unix::io::AsRawFd;
use icecap_resource_server_types::*;
use icecap_rpc::*;
use crate::{Result, ensure};

const ICECAP_VMM_SYS_ID_RESOURCE_SERVER_PASSTHRU: u64 = 1338;

const ICECAP_VMM_PASSTHRU: u64 = 0xc0403300;

#[repr(C)]
struct Passthru {
    sys_id: u64,
    regs: [u64; 7],
}

fn ioctl_passthru(passthru: &mut Passthru) {
    let f = File::open("/sys/kernel/debug/icecap_vmm").unwrap();
    let ret = unsafe {
        libc::ioctl(f.as_raw_fd(), ICECAP_VMM_PASSTHRU, passthru as *mut Passthru)
    };
    assert_eq!(ret, 0);
}

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

fn call_resource_server<Output: RPC>(request: &Request) -> Output {
    call_passthru(ICECAP_VMM_SYS_ID_RESOURCE_SERVER_PASSTHRU, request)
}

pub fn declare(realm_id: usize, spec_size: usize) {
    call_resource_server(&Request::Declare { realm_id, spec_size })
}

pub fn realize(realm_id: usize) {
    call_resource_server(&Request::Realize { realm_id })
}

pub fn destroy(realm_id: usize) {
    call_resource_server(&Request::Destroy { realm_id })
}

pub fn hack_run(realm_id: usize) {
    call_resource_server(&Request::HackRun { realm_id })
}
