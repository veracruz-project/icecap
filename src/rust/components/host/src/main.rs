use std::{
    io, env, fs,
};

use clap::{Arg, App, SubCommand};

use icecap_host_core::*;


fn main() -> Result<()> {
    let matches = App::new("")
            .subcommand(SubCommand::with_name("create")
                .arg(Arg::with_name("REALM_ID")
                    .required(true)
                    .index(1))
                .arg(Arg::with_name("SPEC")
                    .required(true)
                    .index(2))
                .arg(Arg::with_name("BULK_TRANSPORT")
                    .required(true)
                    .index(3)))
            .subcommand(SubCommand::with_name("destroy")
                .arg(Arg::with_name("REALM_ID")
                    .required(true)
                    .index(1)))
            .subcommand(SubCommand::with_name("hack-run")
                .arg(Arg::with_name("REALM_ID")
                    .required(true)
                    .index(1)))
            .get_matches();

    let subcommand = match &matches.subcommand {
        Some(subcommand) => subcommand,
        None => panic!("{}", matches.usage()),
    };

    match subcommand.name.as_str() {
        "create" => {
            let realm_id = subcommand.matches.value_of("REALM_ID").unwrap().parse()?;
            let spec = subcommand.matches.value_of("SPEC").unwrap();
            let bulk_transport = BulkTransportSpec::parse(subcommand.matches.value_of("BULK_TRANSPORT").unwrap())?;
            create(realm_id, spec, bulk_transport)?;
        }
        "destroy" => {
            let realm_id = subcommand.matches.value_of("REALM_ID").unwrap().parse()?;
            destroy(realm_id)?;
        }
        "hack-run" => {
            let realm_id = subcommand.matches.value_of("REALM_ID").unwrap().parse()?;
            hack_run(realm_id)?;
        }
        _ => {
            panic!("{}", matches.usage())
        }
    }

    Ok(())
}

fn create(realm_id: usize, spec_path: &str, bulk_transport_spec: BulkTransportSpec) -> Result<()> {
    let spec = fs::read(spec_path)?;
    let bulk_transport_chunk_size: usize = 4096 * 64; // TODO make configurable
    let mut host = Host::new().unwrap();
    host.create_realm(realm_id, &spec, &bulk_transport_spec, bulk_transport_chunk_size)
}

fn destroy(realm_id: usize) -> Result<()> {
    let mut host = Host::new().unwrap();
    host.destroy_realm(realm_id)
}

fn hack_run(realm_id: usize) -> Result<()> {
    let mut host = Host::new().unwrap();
    host.hack_run_realm(realm_id)
}
