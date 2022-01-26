use crate::{CapRights, LocalCPtr, ObjectBlueprint, ObjectFixedSize, Result, VMAttributes, PGD};

pub trait Frame: LocalCPtr + ObjectFixedSize {
    fn frame_size() -> FrameSize;

    fn map(&self, pgd: PGD, vaddr: usize, rights: CapRights, attrs: VMAttributes) -> Result<()>;
    fn unmap(&self) -> Result<()>;
}

#[derive(Copy, Clone, Debug)]
pub enum FrameSize {
    Small,
    Large,
    Huge,
}

impl FrameSize {
    pub const fn blueprint(self) -> ObjectBlueprint {
        match self {
            FrameSize::Small => ObjectBlueprint::SmallPage,
            FrameSize::Large => ObjectBlueprint::LargePage,
            FrameSize::Huge => ObjectBlueprint::HugePage,
        }
    }

    pub const fn bits(self) -> usize {
        match self {
            FrameSize::Small => 12,
            FrameSize::Large => 21,
            FrameSize::Huge => 30,
        }
    }

    pub const fn bytes(self) -> usize {
        1 << self.bits()
    }
}

// TODO
pub trait VSpaceBranch: LocalCPtr {
    fn map(&self, pgd: PGD, vaddr: usize, attrs: VMAttributes) -> Result<()>;
}

// TODO this doesn't belong here

// #[derive(Copy, Clone, Debug)]
// pub enum AnyFrame {
//     cptr: CPtr,
//     size: FrameSize,
// }

// impl AnyFrame {

//     pub fn cptr(&self) -> CPtr {
//         match self {
//             Self::Small(cap) => cap.cptr(),
//             Self::Large(cap) => cap.cptr(),
//             Self::Huge(cap) => cap.cptr(),
//         }
//     }

//     pub fn size(&self) -> FrameSize {
//         match self {
//             Self::Small(_) => FrameSize::Small,
//             Self::Large(_) => FrameSize::Large,
//             Self::Huge(_) => FrameSize::Huge,
//         }
//     }

//     pub fn map(&self, pgd: PGD, vaddr: usize, rights: CapRights, attrs: VMAttributes) -> Result<()> {
//         match self {
//             Self::Small(cap) => cap.map(pgd, vaddr, rights, attrs),
//             Self::Large(cap) => cap.map(pgd, vaddr, rights, attrs),
//             Self::Huge(cap) => cap.map(pgd, vaddr, rights, attrs),
//         }
//     }

//     pub fn unmap(&self) -> Result<()> {
//         match self {
//             Self::Small(cap) => cap.unmap(),
//             Self::Large(cap) => cap.unmap(),
//             Self::Huge(cap) => cap.unmap(),
//         }
//     }
// }
