use std::fs;

use clap::{App, Arg, SubCommand};

use icecap_host_user::*;
use icecap_host_vmm_types::DirectRequest;

fn main() -> Result<()> {
    let matches = App::new("")
        .subcommand(
            SubCommand::with_name("create")
                .arg(Arg::with_name("REALM_ID").required(true).index(1))
                .arg(Arg::with_name("SPEC").required(true).index(2)),
        )
        .subcommand(
            SubCommand::with_name("destroy")
                .arg(Arg::with_name("REALM_ID").required(true).index(1)),
        )
        .subcommand(
            SubCommand::with_name("run")
                .arg(Arg::with_name("REALM_ID").required(true).index(1))
                .arg(Arg::with_name("VIRTUAL_NODE").required(true).index(2)),
        )
        .subcommand(
            SubCommand::with_name("hack-run")
                .arg(Arg::with_name("REALM_ID").required(true).index(1)),
        )
        .subcommand(
            SubCommand::with_name("benchmark")
                .arg(Arg::with_name("BENCHMARK_COMMAND").required(true).index(1)),
        )
        .get_matches();

    let subcommand = match &matches.subcommand {
        Some(subcommand) => subcommand,
        None => panic!("{}", matches.usage()),
    };

    match subcommand.name.as_str() {
        "create" => {
            let realm_id = subcommand.matches.value_of("REALM_ID").unwrap().parse()?;
            let spec = subcommand.matches.value_of("SPEC").unwrap();
            create(realm_id, spec)?;
        }
        "destroy" => {
            let realm_id = subcommand.matches.value_of("REALM_ID").unwrap().parse()?;
            destroy(realm_id)?;
        }
        "run" => {
            let realm_id = subcommand.matches.value_of("REALM_ID").unwrap().parse()?;
            let virtual_node = subcommand
                .matches
                .value_of("VIRTUAL_NODE")
                .unwrap()
                .parse()?;
            run(realm_id, virtual_node)?;
        }
        "hack-run" => {
            let realm_id = subcommand.matches.value_of("REALM_ID").unwrap().parse()?;
            hack_run(realm_id)?;
        }
        "benchmark" => {
            let benchmark_command = subcommand.matches.value_of("BENCHMARK_COMMAND").unwrap();
            match benchmark_command {
                "start" => {
                    benchmark_start()?;
                }
                "finish" => {
                    benchmark_finish()?;
                }
                _ => {
                    panic!("{}", matches.usage())
                }
            }
        }
        _ => {
            panic!("{}", matches.usage())
        }
    }

    Ok(())
}

fn create(realm_id: usize, spec_path: &str) -> Result<()> {
    let spec = fs::read(spec_path)?;
    let bulk_transport_chunk_size: usize = 4096 * 64; // TODO make configurable
    let mut host = Host::new().unwrap();
    host.create_realm(realm_id, &spec, bulk_transport_chunk_size)
}

fn destroy(realm_id: usize) -> Result<()> {
    let mut host = Host::new().unwrap();
    host.destroy_realm(realm_id)
}

fn run(realm_id: usize, virtual_node: usize) -> Result<()> {
    let mut host = Host::new().unwrap();
    host.run_realm_node(realm_id, virtual_node)
}

fn hack_run(realm_id: usize) -> Result<()> {
    let mut host = Host::new().unwrap();
    host.hack_run_realm(realm_id)
}

fn benchmark_start() -> Result<()> {
    let mut host = Host::new().unwrap();
    host.direct(&DirectRequest::BenchmarkUtilisationStart)?;
    Ok(())
}

fn benchmark_finish() -> Result<()> {
    let mut host = Host::new().unwrap();
    host.direct(&DirectRequest::BenchmarkUtilisationFinish)?;
    Ok(())
}
