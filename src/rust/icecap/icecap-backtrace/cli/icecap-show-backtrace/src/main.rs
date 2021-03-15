use addr2line::Context;
use clap::{Arg, App};
use fallible_iterator::FallibleIterator;
use gimli::read::Reader;
use memmap::Mmap;
use std::fs::File;
// use rustc_demangle::demangle;

use icecap_backtrace_types::RawBacktrace;

fn main() {
    let matches = App::new("")
        .arg(Arg::from_usage("<raw_backtrace>"))
        .get_matches();
    let bt_hex = matches.value_of("raw_backtrace").unwrap();
    let bt: RawBacktrace = RawBacktrace::deserialize(bt_hex);
    let elf_file = File::open(&bt.path).unwrap();
    let map = unsafe { Mmap::map(&elf_file).unwrap() };
    let elf_obj = &object::File::parse(&*map).unwrap();
    let ctx = Context::new(elf_obj).unwrap();
    show_backtrace(ctx, bt).unwrap();
}

fn show_backtrace<R: Reader>(ctx: Context<R>, bt: RawBacktrace) -> Result<(), gimli::Error> {
    println!("backtrace: {}", bt.path);
    if let Some(ref err) = bt.error {
        println!("    error: {}", err);
    }
    for (i, frame) in bt.stack_frames.iter().enumerate() {
        let mut first = true;
        // let mut seen = false;
        // let initial_location = ctx.find_location(frame.initial_address)?;
        ctx.find_frames(frame.initial_address)?.for_each(|inner_frame| {
            if first {
                // TODO not correct when inlining present
                if i == bt.skip {
                    print!("[{:4}:]", i);
                } else {
                    print!(" {:4}: ", i);
                }
                print!(" {:#18x} - ", frame.initial_address);
            } else {
                print!("      {:18}   ", "");
            }
            // TODO
            // if inner_frame.location == frame {
            //     seen = true;
            // }
            match inner_frame.function {
                Some(f) => {
                    // let raw_name = f.raw_name()?;
                    // let demangled = demangle(&raw_name);
                    let demangled = f.demangle()?;
                    print!("{}", demangled)
                }
                None => print!("<unknown>"),
            }
            print!("\n");
            // if let Some(loc) = inner_frame.location {
            //     println!("      {:18}       at {}", "", fmt_location(loc));
            // }
            first = false;
            Ok(())
        })?;
        if let Some(loc) = ctx.find_location(frame.callsite_address)? {
            println!("      {:18}       at {}", "", fmt_location(loc));
        }
        // if !seen {
        //     print!("      ");
        //     print!("warning: initial location missing: {}", initial_location);
        //     print!("\n");
        // }
    };
    Ok(())
}

fn fmt_location(loc: addr2line::Location) -> String {
    format!("{} {},{}",
        loc.file.unwrap_or("<unknown>"),
        loc.line.map(|x| x.to_string()).unwrap_or(String::from("<unknown>")),
        loc.column.map(|x| x.to_string()).unwrap_or(String::from("<unknown>")),
    )
}