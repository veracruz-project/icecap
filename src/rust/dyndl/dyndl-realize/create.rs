use icecap_core::prelude::*;
use dyndl_types::*;
use crate::{Externs, Caps, utils::*};

pub struct Create {
    pub untyped: Untyped,
    pub cnode: CNode,
    pub free_slot: Slot,
}

impl Create {

    pub fn create_objects(&mut self, model: &Model, externs: &Externs) -> Fallible<Caps> {
        model.objects.iter().map(|obj| {
            Ok(match &obj.object {
                AnyObj::Extern(ty) => {
                    match externs.get(&obj.name) {
                        None => {
                            bail!("missing extern {}", obj.name)
                        }
                        Some(ext) => {
                            ensure!(ext.ty == *ty);
                            ext.cptr
                        }
                    }
                }
                AnyObj::Local(obj_) => {
                    self.create_object(obj_)?
                }
            })
        }).collect()
    }

    fn next_slot(&mut self) -> Slot {
        let slot = self.free_slot;
        self.free_slot += 1;
        slot
    }

    pub fn retype(&mut self, blueprint: ObjectBlueprint) -> Fallible<Unspecified> {
        let slot = self.next_slot();
        let dst = self.cnode.relative_self();
        self.untyped.retype(blueprint, &dst, slot, 1)?;
        Ok(Unspecified::from_raw(slot))
    }

    pub fn copy(&mut self, cap: Unspecified) -> Fallible<Unspecified> {
        let slot = self.next_slot();
        let dst = self.cnode.relative(Unspecified::from_raw(slot));
        let src = self.cnode.relative(cap);
        dst.copy(&src, CapRights::all_rights())?;
        Ok(Unspecified::from_raw(slot))
    }

    fn create_object(&mut self, obj: &Obj) -> Fallible<Unspecified> {
        self.retype(blueprint_of(obj))
    }

}
