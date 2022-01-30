#![no_main]

use icecap_core::failure::Fallible;
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

fn main(_: ()) -> Fallible<()> {
    icecap_std_external::early_init();
    let n: libc::size_t = 100usize;
    let r = 0..n;
    let mut v = vec![];
    for i in r.clone() {
        v.push(i);
    }
    assert_eq!(v.iter().sum::<usize>(), r.sum::<usize>());
    println!("Hello, println!");
    println!("TEST_PASS");
    Ok(())
}
