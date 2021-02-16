use icecap_sel4::*;

pub struct Timer {
    ep: Endpoint,
}

enum MessageLabel {
    Completed = 1,
    Periodic = 2,
    OneshotAbsolute = 3,
    OneshotRelative = 4,
    Stop = 5,
    Time = 6,
}

pub type TimerID = i64;
pub type Nanoseconds = u64;

pub type Error = ();
pub type Result<T> = core::result::Result<T, Error>;

fn result_of(ret: Word) -> Result<()> {
    match ret {
        0 => Ok(()),
        _ => Err(()),
    }
}

impl Timer {

    pub fn new(ep: Endpoint)-> Self {
        Self {
            ep,
        }
    }

    pub fn completed(&self) -> Result<()> {
        self.ep.call(MessageInfo::new(MessageLabel::Completed as Word, 0, 0, 0));
        result_of(MR_0.get())
    }

    pub fn periodic(&self, tid: TimerID, ns: Nanoseconds) -> Result<()> {
        MR_0.set(tid as Word); // TODO we don't want overflow checking here
        MR_1.set(ns as Word);
        self.ep.call(MessageInfo::new(MessageLabel::Periodic as Word, 0, 0, 2));
        result_of(MR_0.get())
    }

    pub fn oneshot_absolute(&self, tid: TimerID, ns: Nanoseconds) -> Result<()> {
        MR_0.set(tid as Word);
        MR_1.set(ns as Word);
        self.ep.call(MessageInfo::new(MessageLabel::OneshotAbsolute as Word, 0, 0, 2));
        result_of(MR_0.get())
    }

    pub fn oneshot_relative(&self, tid: TimerID, ns: Nanoseconds) -> Result<()> {
        MR_0.set(tid as Word);
        MR_1.set(ns as Word);
        self.ep.call(MessageInfo::new(MessageLabel::OneshotRelative as Word, 0, 0, 2));
        result_of(MR_0.get())
    }

    pub fn stop(&self, tid: TimerID) -> Result<()> {
        MR_0.set(tid as Word);
        self.ep.call(MessageInfo::new(MessageLabel::Stop as Word, 0, 0, 1));
        result_of(MR_0.get())
    }

    pub fn time(&self) -> Nanoseconds {
        self.ep.call(MessageInfo::new(MessageLabel::Time as Word, 0, 0, 0));
        MR_0.get()
    }

}
