#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

use alloc::collections::btree_map::BTreeMap;

use dyndl_types::*;
use icecap_core::prelude::*;

mod cregion;
mod allocator;
mod utils;
mod model_view;
mod initialize_subsystem_objects;

use model_view::ModelView;
use utils::{blueprint_of, size_bits_to_contain};

pub use allocator::{Allocator, AllocatorBuilder};
pub use cregion::{CRegion, Slot};
pub use initialize_subsystem_objects::SubsystemObjectInitializationResources;

/// Unique id for an untyped block of memory
#[derive(Clone, Debug)]
pub struct UntypedId {
    /// The physical address of the untyped block
    pub paddr: usize,

    /// log_2 of the size (in bytes) of the untyped block
    /// (e.g., for a 32 byte block, `size_bits` is 5)
    pub size_bits: usize,
}

pub struct ElaboratedUntyped {
    pub cptr: Untyped,
    pub untyped_id: UntypedId,
}

pub type Externs = BTreeMap<String, Extern>;

pub struct Extern {
    pub ty: ExternObj,
    pub cptr: Unspecified,
}

pub struct Realizer {
    pub initialization_resources: SubsystemObjectInitializationResources,
    pub allocator: Allocator,
    pub externs: Externs,
}

pub struct Subsystem {
    pub virtual_cores: Vec<VirtualCore>,

    // ID of the Untyped retyped for the realm's CNode.
    pub cnode_untyped_id: UntypedId,

    // IDs of the Untypeds retyped for the realm's objects.
    pub object_untyped_ids: Vec<UntypedId>,

    pub externs: Externs,
}

pub type VirtualCores = Vec<VirtualCore>;

pub struct VirtualCore {
    pub tcbs: Vec<VirtualCoreTCB>,
}

pub struct VirtualCoreTCB {
    pub cap: TCB,
    pub resume: bool,
}

pub struct PartialSubsystem {
    pub model: Model,
    pub model_view: ModelView,
    pub cregion: CRegion,
    pub cnode_untyped_id: UntypedId,
    pub local_object_slots: Vec<Slot>,
    pub local_object_untyped_ids: Vec<UntypedId>,
}

impl Realizer {
    pub fn new(
        initialization_resources: SubsystemObjectInitializationResources,
        allocator: Allocator,
        externs: Externs,
    ) -> Self {
        Realizer {
            initialization_resources,
            allocator,
            externs,
        }
    }

    pub fn destroy(&mut self, subsystem: Subsystem) -> Fallible<()> {
        self.allocator
            .revoke_and_free(&subsystem.cnode_untyped_id)?;
        for untyped_id in &subsystem.object_untyped_ids {
            self.allocator.revoke_and_free(&untyped_id)?;
        }
        self.externs.extend(subsystem.externs);
        Ok(())
    }

    pub fn realize_start(&mut self, model: Model) -> Fallible<PartialSubsystem> {
        let view = ModelView::new(&model);

        let cnode_slots_size_bits = {
            let mut num_frame_mappings: usize = 0;
            for i in view.local_objects.iter() {
                if let AnyObj::Local(obj) = &model.objects[*i].object {
                    match obj {
                        Obj::PT(obj) => {
                            num_frame_mappings += obj.entries.len();
                        }
                        Obj::PD(obj) => {
                            for entry in obj.entries.values() {
                                if let PDEntry::LargePage(_) = entry {
                                    num_frame_mappings += 1;
                                }
                            }
                        }
                        _ => {}
                    }
                }
            }
            size_bits_to_contain(view.local_objects.len() + num_frame_mappings)
        };

        let local_object_blueprints: Vec<ObjectBlueprint> = view
            .local_objects
            .iter()
            .map(|i| match &model.objects[*i].object {
                AnyObj::Local(obj) => blueprint_of(&obj),
                _ => panic!(),
            })
            .collect();

        let untyped_requirements: Vec<usize> = {
            let mut v = vec![0; 64];
            v[ObjectBlueprint::CNode {
                size_bits: cnode_slots_size_bits,
            }
            .physical_size_bits()] += 1;
            for blueprint in &local_object_blueprints {
                v[blueprint.physical_size_bits()] += 1
            }
            v
        };
        ensure!(self.allocator.peek_space(&untyped_requirements));

        let (mut cregion, cnode_untyped_id, _managed_cnode_slot) =
            self.allocator.create_cnode(cnode_slots_size_bits)?;
        let (local_object_slots, local_object_untyped_ids) = self
            .allocator
            .create_objects(&mut cregion, &local_object_blueprints)?;

        let model_view = ModelView::new(&model);

        Ok(PartialSubsystem {
            model,
            model_view,
            cregion,
            cnode_untyped_id,
            local_object_slots,
            local_object_untyped_ids,
        })
    }

    pub fn realize_continue(
        &self,
        partial: &PartialSubsystem,
        obj_id: ObjId,
        fill_entry_index: usize,
        untrusted_content: &[u8],
    ) -> Fallible<()> {
        let obj = &partial.model.objects[obj_id];
        if let AnyObj::Local(obj) = &obj.object {
            let cptr_with_depth = partial
                .cregion
                .cptr_with_depth(partial.local_object_slots[partial.model_view.reverse[obj_id]]);
            match obj {
                Obj::SmallPage(frame) => {
                    self.initialization_resources.fill_frame(
                        cptr_with_depth.local_cptr::<SmallPage>(),
                        frame.fill[fill_entry_index].offset,
                        &frame.fill[fill_entry_index].content_digest,
                        untrusted_content,
                    )?;
                }
                Obj::LargePage(frame) => {
                    self.initialization_resources.fill_frame(
                        cptr_with_depth.local_cptr::<LargePage>(),
                        frame.fill[fill_entry_index].offset,
                        &frame.fill[fill_entry_index].content_digest,
                        untrusted_content,
                    )?;
                }
                _ => {
                    panic!()
                }
            }
        } else {
            panic!()
        }
        Ok(())
    }

    pub fn realize_finish(&mut self, mut partial: PartialSubsystem) -> Fallible<Subsystem> {
        let (externs, extern_caps): (Externs, Vec<Unspecified>) = {
            let mut externs = BTreeMap::new();
            let extern_caps: Vec<Unspecified> = partial
                .model_view
                .extern_objects
                .iter()
                .map(|i| match &partial.model.objects[*i].object {
                    AnyObj::Extern(obj) => {
                        let name = partial.model.objects[*i].name.clone();
                        let ext = self.externs.remove(&name).unwrap();
                        assert_eq!(&ext.ty, obj);
                        let cptr = ext.cptr;
                        externs.insert(name, ext);
                        cptr
                    }
                    _ => panic!(),
                })
                .collect();
            (externs, extern_caps)
        };

        let all_caps: Vec<Unspecified> = partial
            .model
            .objects
            .iter()
            .enumerate()
            .map(|(i, obj)| match &obj.object {
                AnyObj::Local(_) => partial
                    .cregion
                    .cptr_with_depth(partial.local_object_slots[partial.model_view.reverse[i]])
                    .local_cptr::<Unspecified>(),
                AnyObj::Extern(_) => extern_caps[partial.model_view.reverse[i]],
            })
            .collect();

        let virtual_cores = self.initialization_resources.initialize(
            partial.model.num_nodes,
            &partial.model,
            &all_caps,
            &mut partial.cregion,
        )?;

        Ok(Subsystem {
            virtual_cores,
            cnode_untyped_id: partial.cnode_untyped_id,
            object_untyped_ids: partial.local_object_untyped_ids,
            externs,
        })
    }
}
