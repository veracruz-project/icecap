#![no_std]

pub type Label = u64;

pub struct Info {
    pub length: usize,
    pub label: Label,
}

pub type ParameterIndex = usize;
pub type ParameterValue = u64;

pub trait Call: Sized {

    fn new(info: Info) -> Self;

    fn info(&self) -> &Info;

    fn get(&self, ix: ParameterIndex) -> ParameterValue;

    fn set(&mut self, ix: ParameterIndex, value: ParameterValue);

    fn simple(label: Label, parameters: &[ParameterValue]) -> Self {
        let mut call = Self::new(Info { label, length: parameters.len() });
        for (i, parameter) in parameters.iter().enumerate() {
            call.set(i, *parameter);
        }
        call
    }
}

pub trait RPC {

    fn send<T: Call>(&self) -> T;

    fn recv(call: impl Call) -> Self;
}
