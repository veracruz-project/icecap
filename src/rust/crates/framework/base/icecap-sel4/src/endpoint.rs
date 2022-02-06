use crate::{sys, IPCBuffer, MessageInfo};

pub fn reply(_ipcbuf: &IPCBuffer, info: MessageInfo) {
    unsafe { sys::seL4_Reply(info.raw()) }
}
