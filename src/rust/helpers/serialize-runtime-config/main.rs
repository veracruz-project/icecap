use std::io::{self, Write};

use icecap_runtime_config::Config;

fn main() -> Result<(), std::io::Error> {
    let config: Config = serde_json::from_reader(io::stdin())?;
    io::stdout().write_all(&config.serialize())?;
    Ok(())
}
