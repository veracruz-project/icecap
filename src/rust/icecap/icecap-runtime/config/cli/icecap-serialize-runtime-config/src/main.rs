use std::io::{self, Write};
use std::path::PathBuf;
use std::fs;

use icecap_runtime_config::Config;

fn main() -> Result<(), std::io::Error> {
    let config: Config<PathBuf> = serde_json::from_reader(io::stdin())?;
    let config = config.traverse(|path| {
        fs::read(path)
    })?;
    for chunk in &config.serialize() {
        io::stdout().write_all(chunk)?;
    }
    Ok(())
}
