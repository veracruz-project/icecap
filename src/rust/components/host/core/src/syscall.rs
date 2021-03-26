use libc::{syscall, c_long};
use icecap_resource_server_types::calls;
use crate::{Result, ensure};

const SYS_ICECAP: c_long = 436;

fn wrap(label: &str, ret: c_long) -> Result<c_long> {
    ensure!(ret >= 0, "{} returned {}", label, ret);
    Ok(ret)
}

pub fn declare(realm_id: usize, spec_size: usize) -> Result<()> {
    assert_eq!(0, unsafe {
        wrap("declare", syscall(SYS_ICECAP, realm_id as c_long, spec_size as c_long, 0, 0, calls::DECLARE as c_long, 3))?
    });
    Ok(())
}

pub fn realize(realm_id: usize, num_nodes: usize) -> Result<()> {
    assert_eq!(0, unsafe {
        wrap("realize", syscall(SYS_ICECAP, realm_id as c_long, num_nodes as c_long, 0, 0, calls::REALIZE as c_long, 3))?
    });
    Ok(())
}
