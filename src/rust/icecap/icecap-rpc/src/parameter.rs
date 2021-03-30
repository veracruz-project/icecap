pub type ParameterValue = u64;

pub trait Parameter: Copy {

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

impl Parameter for usize {

    fn into_value(self) -> ParameterValue {
        self as ParameterValue
    }

    fn from_value(value: ParameterValue) -> Self {
        value as Self
    }
}

impl Parameter for i64 {

    fn into_value(self) -> ParameterValue {
        self as ParameterValue
    }

    fn from_value(value: ParameterValue) -> Self {
        value as Self
    }
}

impl Parameter for i32 {

    fn into_value(self) -> ParameterValue {
        self as ParameterValue
    }

    fn from_value(value: ParameterValue) -> Self {
        value as Self
    }
}
