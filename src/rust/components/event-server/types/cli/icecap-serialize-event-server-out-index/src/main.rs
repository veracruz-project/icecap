use std::env;
use std::io;

use finite_set::*;
use icecap_event_server_types::*;

fn main() -> Result<(), std::io::Error> {
    let args: Vec<String> = env::args().collect();
    assert_eq!(args.len(), 3);
    let role = &args[1];
    let index = &args[2];
    let nat = match role.as_str() {
        "host" => f::<events::HostOut>(index),
        "realm" => f::<events::RealmOut>(index),
        _ => panic!(),
    };
    print!("{}", nat);
    Ok(())
}

fn f<T: Finite>(index: &str) -> usize
  where
    T: for<'de> serde::de::Deserialize<'de>
{
    let v: T = serde_json::from_str(index).unwrap();
    v.to_nat()
}
