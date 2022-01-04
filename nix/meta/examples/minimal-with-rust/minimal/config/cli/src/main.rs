#![feature(type_ascription)]

use std::io;
use std::marker::PhantomData;

pub fn main() -> Result<(), io::Error> {
    icecap_config_cli_core::main(PhantomData: PhantomData<minimal_config::Config>)
}
