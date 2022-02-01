#![no_std]
#![feature(const_panic)]
#![feature(thread_local)]

// TODO remove or guard with feature
extern crate alloc;

#[macro_use]
extern crate icecap_sel4_derive;

pub use icecap_sel4_sys as sys;

mod types;
mod error;
mod cspace;
mod vspace;
mod invoke;
mod ipc_buffer;
mod endpoint;
pub mod fault; // TODO
mod bootinfo;
mod debug;

#[cfg(icecap_benchmark)]
pub mod benchmark;

pub mod prelude;

#[doc(hidden)]
#[path = "fmt.rs"]
pub mod _fmt;

// TODO harness some of Rust's memory-safety features for compile-time checking of CSpace manipulation
//   - 'unsafe' for handling of RawCPtr and casting between TypedCPtr's
//   - use references to TypedCPtr's for liveness and use of 'Deref' for managed CPtr's

pub use types::{
    Badge, CNodeCapData, CapRights, MessageInfo, Slot, UserContext, VCPUReg, VMAttributes, Word,
};

pub use error::{Error, Result};

pub use cspace::{
    ASIDPool, CNode, CPtr, CPtrWithDepth, Endpoint, HugePage, IRQHandler, LargePage, LocalCPtr,
    Notification, Null, ObjectBlueprint, ObjectFixedSize, ObjectType, ObjectVariableSize,
    RelativeCPtr, SmallPage, Unspecified, Untyped, PD, PGD, PT, PUD, TCB, VCPU,
};

pub use vspace::{Frame, FrameSize, VSpaceBranch};

pub use invoke::yield_;

pub use endpoint::{
    reply, MessageRegister, MR_0, MR_1, MR_2, MR_3, MR_4, MR_5, MR_6, MR_7, MSG_MAX_LENGTH,
};

pub use ipc_buffer::{IPCBuffer, IPC_BUFFER};

pub use fault::{
    CapFault,
    Fault,
    IsFault,
    // fault types:
    NullFault,
    UnknownSyscall,
    UserException,
    VCPUFault,
    VGICMaintenance,
    VMFault,
    VMFaultData,
    // helpers:
    VMFaultWidth,
    VPPIEvent,
};

pub use bootinfo::{BootInfo, BootInfoExtraStructure, BootInfoExtraStructureId};

pub use debug::{debug_put_char, debug_snapshot};
