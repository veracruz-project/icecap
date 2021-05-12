use crate::sel4::debug_put_char;

pub fn write_to_fd(fd: i32, data: &[u8]) {
    assert!(fd == 1 || fd == 2);
    for b in data {
        debug_put_char(*b)
    }
}
