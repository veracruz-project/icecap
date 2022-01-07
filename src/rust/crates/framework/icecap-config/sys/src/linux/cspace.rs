use serde::{Deserialize, Serialize};

pub type RawCPtr = u64;

#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct CPtr(RawCPtr);

#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct Untyped(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct Endpoint(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct Notification(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct TCB(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct VCPU(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct CNode(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct SmallPage(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct LargePage(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct HugePage(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct PGD(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct PUD(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct PD(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct PT(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct IRQHandler(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct ASIDPool(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct Unspecified(CPtr);
#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct Null(CPtr);
