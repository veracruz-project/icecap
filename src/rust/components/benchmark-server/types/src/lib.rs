#![no_std]
#![allow(unused_imports)]

use serde::{Serialize, Deserialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Request {
    Start,
    Finish,
}

pub type Response = Result<InnerResponse, ()>;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct InnerResponse;
