use crate::sel4::{Endpoint, MessageInfo, get_mr, set_mr};

pub const MAP: u64 = 215;
pub const WRITE: u64 = 218;

#[derive(Copy, Clone, Debug)]
pub struct Supervisor(Endpoint);

impl Supervisor {

    pub const fn new(ep: Endpoint) -> Self {
        Self(ep)
    }

    pub fn ep(self) -> Endpoint {
        self.0
    }

    pub fn call(self, nr: u64, nargs: usize, nret: usize) {
        let info = self.ep().call(MessageInfo::new(nr, 0, 0, nargs as u64));
        assert!(info.get_label() == 1);
        assert!(info.get_length() as usize == nret);
    }

    pub fn map(self, size: usize) -> usize {
        set_mr(0, size as u64);
        self.call(MAP, 1, 1);
        let addr = get_mr(0) as usize;
        addr
    }

    pub fn write(self, fd: i32, addr: usize, size: usize) {
        set_mr(0, fd as u64);
        set_mr(1, addr as u64);
        set_mr(2, size as u64);
        self.call(WRITE, 3, 0);
    }
}
