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
    let module = args.next().unwrap();
    assert!(args.next().is_none());

    gen!(module.as_str(), [icecap_generic_timer_server_config,])?;

    Ok(())
}
