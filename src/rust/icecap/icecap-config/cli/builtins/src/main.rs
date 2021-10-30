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

    let module = format!("icecap_{}_config", arg.replace("-", "_"));
    eprintln!("{}", module);

    gen!(
        module.as_str(), [
            icecap_fault_handler_config,
            icecap_timer_server_config,
            icecap_serial_server_config,
            icecap_host_vmm_config,
            icecap_realm_vmm_config,
            icecap_resource_server_config,
            icecap_event_server_config,
            icecap_benchmark_server_config,
        ]
    )?;

    Ok(())
}
