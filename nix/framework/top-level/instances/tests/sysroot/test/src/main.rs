#![no_main]

use icecap_core::failure::Fallible;
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

fn main(_: ()) -> Fallible<()> {
    icecap_std_external::early_init();
    println!("Hello, println!");
    Ok(())
}
