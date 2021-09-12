#[derive(Debug)]
pub struct Register32(pub u32);

impl Register32 {

    pub fn new(v: u32) -> Self {
        Self(v)
    }

    pub fn load(&self) -> u32 {
        self.0
    }

    pub fn store(&mut self, v: u32) {
        self.0 = v;
    }

    pub fn swap(&mut self, v: u32) -> u32 {
        let old = self.0;
        self.0 = v;
        old
    }

    pub fn fetch_and(&mut self, v: u32) -> u32 {
        let old = self.0;
        self.0 &= v;
        old
    }

    pub fn fetch_or(&mut self, v: u32) -> u32 {
        let old = self.0;
        self.0 |= v;
        old
    }
}
