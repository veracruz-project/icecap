use icecap_core::prelude::*;
use dyndl_types::*;

pub fn blueprint_of(obj: &Obj) -> ObjectBlueprint {
    match obj {
        Obj::Untyped(obj) => ObjectBlueprint::Untyped { size_bits: obj.size_bits },
        Obj::Endpoint => ObjectBlueprint::Endpoint,
        Obj::Notification => ObjectBlueprint::Notification,
        Obj::CNode(obj) => ObjectBlueprint::CNode { size_bits: obj.size_bits },
        Obj::TCB(_) => ObjectBlueprint::TCB,
        Obj::VCPU => ObjectBlueprint::VCPU,
        Obj::SmallPage(_) => ObjectBlueprint::SmallPage,
        Obj::LargePage(_) => ObjectBlueprint::LargePage,
        Obj::PT(_) => ObjectBlueprint::PT,
        Obj::PD(_) => ObjectBlueprint::PD,
        Obj::PUD(_) => ObjectBlueprint::PUD,
        Obj::PGD(_) => ObjectBlueprint::PGD,
    }
}

pub fn rights_of(rights: &Rights) -> CapRights {
    CapRights::new(rights.grant_reply, rights.grant, rights.read, rights.write)
}
