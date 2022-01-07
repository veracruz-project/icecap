use crate::{sys, CPtr, LocalCPtr, TCB};

pub fn debug_put_char(c: u8) {
    unsafe { sys::seL4_DebugPutChar(c) }
}

pub fn debug_snapshot() {
    unsafe { sys::seL4_DebugSnapshot() }
}

impl TCB {
    pub fn debug_name(self, name: &str) {
        let mut name = name.as_bytes().to_vec();
        name.push(0);
        unsafe { sys::seL4_DebugNameThread(self.raw(), name.as_ptr()) }
    }
}

impl CPtr {
    pub fn debug_identify(self) -> u32 {
        unsafe { sys::seL4_DebugCapIdentify(self.raw()) }
    }
}

// generated in kernel:
// enum cap_tag {
//     cap_null_cap = 0,
//     cap_untyped_cap = 2,
//     cap_endpoint_cap = 4,
//     cap_notification_cap = 6,
//     cap_reply_cap = 8,
//     cap_cnode_cap = 10,
//     cap_thread_cap = 12,
//     cap_irq_control_cap = 14,
//     cap_irq_handler_cap = 16,
//     cap_zombie_cap = 18,
//     cap_domain_cap = 20,
//     cap_frame_cap = 1,
//     cap_page_table_cap = 3,
//     cap_page_directory_cap = 5,
//     cap_page_upper_directory_cap = 7,
//     cap_page_global_directory_cap = 9,
//     cap_asid_control_cap = 11,
//     cap_asid_pool_cap = 13,
//     cap_vcpu_cap = 15
// };
