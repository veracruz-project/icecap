pub type ParameterValue = u64;

pub trait Parameter {
    fn into_value(self) -> ParameterValue;

    fn from_value(value: ParameterValue) -> Self;
}

impl Parameter for u64 {
    fn into_value(self) -> ParameterValue {
        self
    }

    fn from_value(value: ParameterValue) -> Self {
        value
    }
}
