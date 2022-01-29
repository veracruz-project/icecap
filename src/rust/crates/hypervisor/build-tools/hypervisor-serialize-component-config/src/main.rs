#![feature(concat_idents)]
#![feature(type_ascription)]

use std::env;
use std::io;
use std::marker::PhantomData;

macro_rules! gen {
    ( $v:expr, [ $( $i:ident, )* ] ) => {
        match $v {
            $( stringify!($i) => icecap_config_cli_core::main(PhantomData: PhantomData<$i::Config>), )*
            _ => panic!(),
        }
    }
}

pub fn main() -> Result<(), io::Error> {
    let mut args = env::args();
    let _ = args.next().unwrap();
    let arg = args.next().unwrap();
    assert!(args.next().is_none());

    let module = format!("hypervisor_{}_config", arg.replace("-", "_"));

    gen!(
        module.as_str(),
        [
            hypervisor_fault_handler_config,
            hypervisor_serial_server_config,
            hypervisor_host_vmm_config,
            hypervisor_realm_vmm_config,
            hypervisor_resource_server_config,
            hypervisor_event_server_config,
            hypervisor_benchmark_server_config,
            hypervisor_mirage_config,
        ]
    )?;

    Ok(())
}
