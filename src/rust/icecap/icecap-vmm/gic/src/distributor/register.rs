// HACK to make help in phasing out use of atomics

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

    // HACK

    pub fn set_byte(&mut self, byte_index: usize, v: u8) -> u32 {
        let mask: u32 = 0xff << (byte_index * 8);
        let old = self.0;
        self.0 = (old & !mask) | (u32::from(v) << (byte_index * 8));
        old
    }
}
