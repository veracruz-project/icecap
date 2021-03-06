use serde::{Deserialize, Serialize};

use crate::ClientId;

#[derive(Debug, Serialize, Deserialize)]
pub enum Event {
    Interrupt,
    Timeout,
    Con(ClientId),
}
