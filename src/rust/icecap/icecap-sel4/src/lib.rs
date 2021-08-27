#![no_std]
#![feature(const_if_match)]
#![feature(format_args_nl)]

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
mod endpoint;
pub mod fault; // TODO
mod debug;

pub mod prelude;

#[path = "fmt.rs"]
pub mod _fmt;

// TODO harness some of Rust's memory-safety features for compile-time checking of CSpace manipulation
//   - 'unsafe' for handling of RawCPtr and casting between TypedCPtr's
//   - use references to TypedCPtr's for liveness and use of 'Deref' for managed CPtr's

pub use types::{
    Word, Slot, Badge,
    CapRights, MessageInfo, CNodeCapData, VMAttributes,
    UserContext, VCPUReg,
};

pub use error::{
    Error, Result,
};

pub use cspace::{
    CPtr, CPtrWithDepth,
    ObjectType, ObjectBlueprint,
    LocalCPtr, ObjectFixedSize, ObjectVariableSize,
    RelativeCPtr,

    Untyped,
    Endpoint, Notification,
    TCB, VCPU,
    CNode,
    SmallPage, LargePage, HugePage,
    PGD, PUD, PD, PT,
    IRQHandler,
    ASIDPool,
    Unspecified, Null,
};

pub use vspace::{
    Frame, FrameSize, VSpaceBranch,
};

pub use endpoint::{
    reply, MessageRegister,
    MR_0, MR_1, MR_2, MR_3,
    MR_4, MR_5, MR_6, MR_7,
};

pub use fault::{
    Fault, IsFault,
    // fault types:
    NullFault, CapFault, UnknownSyscall, UserException,
    VMFault, VGICMaintenance, VCPUFault, VPPIEvent,
    // helpers:
    VMFaultWidth, VMFaultData,
};

pub use debug::{
    debug_put_char, debug_snapshot,
};
