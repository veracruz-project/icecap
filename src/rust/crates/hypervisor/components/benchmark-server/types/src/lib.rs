#![no_std]

use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Request {
    Start,
    Finish,
}

pub type Response = Result<InnerResponse, Error>;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct InnerResponse;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Error;
