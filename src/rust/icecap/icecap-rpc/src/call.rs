use alloc::vec::Vec;
use crate::{Parameter, ParameterValue};

pub trait ReadCall {

    fn read_value(&mut self) -> ParameterValue;

    fn read<T: Parameter>(&mut self) -> T {
        T::from_value(self.read_value())
    }
}

pub trait WriteCall {

    fn write_value(&mut self, value: ParameterValue);

    fn write<T: Parameter>(&mut self, value: T) {
        self.write_value(value.into_value())
    }

    fn write_all(&mut self, values: &[ParameterValue]) {
        for value in values.iter() {
            self.write(*value);
        }
    }
}

pub(crate) struct SliceReader<'a> {
    pub(crate) unread: &'a [ParameterValue],
}

impl ReadCall for SliceReader<'_> {

    fn read_value(&mut self) -> ParameterValue {
        let v = self.unread[0];
        self.unread = &self.unread[1..];
        v
    }
}

impl WriteCall for Vec<ParameterValue> {

    fn write_value(&mut self, value: ParameterValue) {
        self.push(value)
    }
}
