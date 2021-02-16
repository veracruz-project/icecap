use icecap_backtrace::Backtrace as ActualBacktrace;

#[derive(Debug, Clone)]
pub struct Backtrace {
    // TODO
    pub internal: Option<ActualBacktrace>,
}

impl Backtrace {

    pub fn new() -> Self {
        Self::new_skip(1)
    }

    pub fn new_skip(skip: usize) -> Self {
        Backtrace {
            internal:
                if is_backtrace_enabled() {
                    Some(ActualBacktrace::new_skip(skip + 1))
                } else {
                    None
                },
        }
    }

    pub fn none() -> Self {
        Backtrace { internal: None }
    }

    #[allow(dead_code)]
    pub(crate) fn is_none(&self) -> bool {
        self.internal.is_none()
    }

    /// Returns true if displaying this backtrace would be an empty string.
    pub fn is_empty(&self) -> bool {
        self.internal.is_none()
    }
}

fn is_backtrace_enabled() -> bool {
    // HACK
    cfg_if::cfg_if! {
        if #[cfg(debug_assertions)] {
            true
        } else {
            false
        }
    }
}
