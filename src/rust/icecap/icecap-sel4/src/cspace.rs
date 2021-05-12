use core::fmt;
#[cfg(feature = "use-serde")]
use serde::{Serialize, Deserialize};
use crate::{
    sys, Result,
};

pub type RawCPtr = sys::seL4_CPtr; // u64

#[derive(Copy, Clone, Debug)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct CPtr(RawCPtr);

impl CPtr {
    pub const NULL: Self = Self::from_raw(0);

    pub const fn raw(self) -> RawCPtr {
        self.0
    }

    pub const fn from_raw(raw: RawCPtr) -> Self {
        Self(raw)
    }

    pub const fn with_depth(self, depth: usize) -> CPtrWithDepth {
        CPtrWithDepth::new(self, depth)
    }

    pub const fn deep(self) -> CPtrWithDepth {
        CPtrWithDepth::deep(self)
    }
}

#[derive(Copy, Clone, Debug)]
pub struct CPtrWithDepth {
    pub cptr: CPtr,
    pub depth: usize,
}

impl CPtrWithDepth {
    pub const WORD_SIZE: usize = 64;

    pub const fn new(cptr: CPtr, depth: usize) -> Self {
        Self {
            cptr, depth,
        }
    }

    pub const fn deep(cptr: CPtr) -> Self {
        Self::new(cptr, Self::WORD_SIZE)
    }

    // TODO: Propagate this logic throughout the crate (i.e. that CPtr without a depth cannot be
    // used on it's own and LocalCPtrs have a depth of 64).
    pub fn local_cptr<T: LocalCPtr>(&self) -> T {
        assert_eq!(self.depth, 64);
        T::from_cptr(self.cptr)
    }

    // HACK: This is used when creating a LocalCPtr to an Untyped which
    // does not have a depth 64, so we remove the assertion.
    // This will work for anything except a CNode capability.
    // TODO: Get rid of this hack.
    pub fn local_cptr_hack<T: LocalCPtr>(&self) -> T {
        T::from_cptr(CPtr::from_raw(self.cptr.raw() << (64 - self.depth)))
    }
}

pub type RawObjectType = u32;

#[repr(u32)]
#[derive(Copy, Clone, Debug)]
pub enum ObjectType {
    Untyped = sys::api_object_seL4_UntypedObject,
    Endpoint = sys::api_object_seL4_EndpointObject,
    Notification = sys::api_object_seL4_NotificationObject,
    CNode = sys::api_object_seL4_CapTableObject,
    TCB = sys::api_object_seL4_TCBObject,
    VCPU = sys::_object_seL4_ARM_VCPUObject,
    SmallPage = sys::_object_seL4_ARM_SmallPageObject,
    LargePage = sys::_object_seL4_ARM_LargePageObject,
    HugePage = sys::_mode_object_seL4_ARM_HugePageObject,
    PT = sys::_object_seL4_ARM_PageTableObject,
    PD = sys::_object_seL4_ARM_PageDirectoryObject,
    PUD = sys::_mode_object_seL4_ARM_PageUpperDirectoryObject,
    PGD = sys::_mode_object_seL4_ARM_PageGlobalDirectoryObject,
}

impl ObjectType {
    pub const fn raw(self) -> RawObjectType {
        self as RawObjectType
    }
}

#[derive(Copy, Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum ObjectBlueprint {
    Untyped { size_bits: usize },
    Endpoint,
    Notification,
    CNode { size_bits: usize },
    TCB,
    VCPU,
    SmallPage,
    LargePage,
    HugePage,
    PT,
    PD,
    PUD,
    PGD,
}

impl ObjectBlueprint {

    pub const fn ty(self) -> ObjectType {
        match self {
            Self::Untyped { .. } => ObjectType::Untyped,
            Self::Endpoint => ObjectType::Endpoint,
            Self::Notification => ObjectType::Notification,
            Self::CNode { .. } => ObjectType::CNode,
            Self::TCB => ObjectType::TCB,
            Self::VCPU => ObjectType::VCPU,
            Self::SmallPage => ObjectType::SmallPage,
            Self::LargePage => ObjectType::LargePage,
            Self::HugePage => ObjectType::HugePage,
            Self::PT => ObjectType::PT,
            Self::PD => ObjectType::PD,
            Self::PUD => ObjectType::PUD,
            Self::PGD => ObjectType::PGD,
        }
    }

    pub const fn raw_size_bits(self) -> Option<usize> {
        match self {
            Self::Untyped { size_bits } => Some(size_bits),
            Self::CNode { size_bits } => Some(size_bits),
            _ => None,
        }
    }

    pub const fn physical_size_bits(self) -> usize {
        (match self {
            Self::Untyped { size_bits } => size_bits as u32,
            Self::Endpoint => sys::seL4_EndpointBits,
            Self::Notification => sys::seL4_NotificationBits,
            Self::CNode { size_bits } => sys::seL4_SlotBits + size_bits as u32,
            Self::TCB => sys::seL4_TCBBits,
            Self::VCPU => sys::seL4_VCPUBits,
            Self::SmallPage => sys::seL4_PageBits,
            Self::LargePage => sys::seL4_LargePageBits,
            Self::HugePage => sys::seL4_HugePageBits,
            Self::PT => sys::seL4_PageTableBits,
            Self::PD => sys::seL4_PageDirBits,
            Self::PUD => sys::seL4_PUDBits,
            Self::PGD => sys::seL4_PGDBits,
        }) as usize
    }
}

pub trait LocalCPtr: Sized + Copy {

    fn cptr(self) -> CPtr;

    fn from_cptr(cptr: CPtr) -> Self;

    fn raw(self) -> RawCPtr {
        self.cptr().raw()
    }

    fn from_raw(raw: RawCPtr) -> Self {
        Self::from_cptr(CPtr::from_raw(raw))
    }

    fn upcast(self) -> Unspecified {
        Unspecified::from_cptr(self.cptr())
    }

    fn null() -> Self {
        Unspecified::NULL.downcast()
    }
}

pub trait ObjectFixedSize {
    fn blueprint() -> ObjectBlueprint;

    fn object_type() -> ObjectType {
        Self::blueprint().ty()
    }
}

pub trait ObjectVariableSize {
    fn blueprint(size_bits: usize) -> ObjectBlueprint;

    fn object_type() -> ObjectType;
}

#[derive(Copy, Clone, LocalCPtr, ObjectVariableSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct Untyped(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct Endpoint(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct Notification(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct TCB(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct VCPU(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectVariableSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct CNode(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct SmallPage(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct LargePage(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct HugePage(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct PGD(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct PUD(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct PD(CPtr);
#[derive(Copy, Clone, LocalCPtr, ObjectFixedSize)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct PT(CPtr);
#[derive(Copy, Clone, LocalCPtr)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct IRQHandler(CPtr);
#[derive(Copy, Clone, LocalCPtr)]
pub struct ASIDPool(CPtr);
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
#[derive(Copy, Clone, LocalCPtr)]
pub struct Unspecified(CPtr);
#[derive(Copy, Clone, LocalCPtr)]
#[cfg_attr(feature = "use-serde", derive(Serialize, Deserialize))]
pub struct Null(CPtr);

#[derive(Clone, Debug)]
pub struct RelativeCPtr {
    pub root: CNode,
    pub path: CPtrWithDepth,
}

pub trait HasDepth {
    fn with_depth(self) -> CPtrWithDepth;
}

impl HasDepth for &CPtrWithDepth {
    fn with_depth(self) -> CPtrWithDepth {
        *self
    }
}

impl<T: LocalCPtr> HasDepth for T {
    fn with_depth(self) -> CPtrWithDepth {
        self.cptr().deep()
    }
}

impl CNode {

    pub fn relative<T: HasDepth>(self, t: T) -> RelativeCPtr {
        RelativeCPtr {
            root: self,
            path: t.with_depth(),
        }
    }

    pub fn relative_cptr(&self, cptr: CPtr, depth: usize) -> RelativeCPtr {
        self.relative(&CPtrWithDepth::new(cptr, depth))
    }

    pub fn relative_self(&self) -> RelativeCPtr {
        // self.relative_cptr(CPtr::NULL, 0)
        // TODO which is preferred?
        self.relative(*self)
    }

    pub fn save_caller(&self, ep: Endpoint) -> Result<()> {
        self.relative(ep).save_caller()
    }
}

impl Unspecified {
    pub const NULL: Self = Self(CPtr::NULL);

    pub fn downcast<T: LocalCPtr>(self) -> T {
        T::from_cptr(self.cptr())
    }
}
