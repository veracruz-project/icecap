#![no_std]
#![feature(alloc_prelude)]
#![feature(format_args_nl)]
#![allow(dead_code)]
#![allow(unreachable_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]

#[macro_use]
extern crate alloc;

use alloc::prelude::v1::*;
use alloc::collections::btree_map::BTreeMap;
use icecap_core::prelude::*;
use dyndl_types::*;

mod cregion;
mod allocator;
mod utils;
mod model_view;
mod initialize_realm_objects;

use utils::*;
use model_view::ModelView;

pub use cregion::{CRegion, Slot};
pub use allocator::{Allocator, AllocatorBuilder};
pub use initialize_realm_objects::{RealmObjectInitializationResources};

pub type RealmId = usize;
pub type NodeIndex = usize;
pub type PhysicalNodeIndex = usize;
pub type VirtualNodeIndex = usize;

pub struct FillId {
    obj_id: ObjId,
    fill_index: usize,
}

pub struct ElaboratedUntyped {
    pub cptr: Untyped,
    pub paddr: usize,
    pub size_bits: usize,
}

pub type Externs = BTreeMap<String, Extern>;

pub struct Extern {
    pub ty: ExternObj,
    pub cptr: Unspecified,
}

pub struct Caput {
    initialization_resources: RealmObjectInitializationResources,
    allocator: Allocator,
    externs: Externs,

    realms: BTreeMap<RealmId, Realm>,
    partial_specs: BTreeMap<RealmId, Vec<u8>>,

    // TODO
    // partial_realms: BTreeMap<RealmId, PartialRealm>,
}

struct Realm {
    virtual_nodes: Vec<VirtualNode>,
    cnode_untyped: ElaboratedUntyped,
    object_untyped: Vec<ElaboratedUntyped>,
    externs: Externs,
}

struct VirtualNode {
    tcbs: Vec<TCB>,
    physical_node: Option<PhysicalNodeIndex>,
}

// TODO
// struct PartialRealm {
// }

impl Caput {

    pub fn new(
        initialization_resources: RealmObjectInitializationResources,
        allocator: Allocator,
        externs: Externs,
    ) -> Self {
        Caput {
            initialization_resources,
            allocator,
            externs,

            realms: BTreeMap::new(),
            partial_specs: BTreeMap::new(),
        }
    }

    pub fn declare(&mut self, spec_size: usize) -> Fallible<RealmId> {
        let realm_id = 0; // TODO
        self.partial_specs.insert(realm_id, vec![0; spec_size]);
        Ok(realm_id)
    }

    pub fn incorporate_spec_chunk(&mut self, realm_id: RealmId, offset: usize, chunk: &[u8]) -> Fallible<()> {
        let range = offset .. offset + chunk.len();
        let partial = self.partial_specs.get_mut(&realm_id).unwrap();
        partial[range].copy_from_slice(chunk);
        Ok(())
    }

    pub fn realize(&mut self, realm_id: RealmId, num_nodes: usize) -> Fallible<()> {
        let raw = self.partial_specs.remove(&realm_id).unwrap();
        let model = pinecone::from_bytes(&raw).unwrap();
        let realm = self.realize_inner(&model, num_nodes)?;
        self.realms.insert(realm_id, realm);
        Ok(())
    }

    pub fn put(&mut self, realm_id: RealmId, virtual_node: VirtualNodeIndex, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        // TODO
        Ok(())
    }

    pub fn take(&mut self, realm_id: RealmId, virtual_node: VirtualNodeIndex) -> Fallible<()> {
        // TODO
        Ok(())
    }

    pub fn destroy(&mut self, realm_id: RealmId) -> Fallible<()> {
        let realm = self.realms.remove(&realm_id).unwrap();
        for virtual_node in &realm.virtual_nodes {
            for tcb in &virtual_node.tcbs {
                // HACK
                tcb.suspend()?;
            }
        }
        self.allocator.revoke_and_free(&realm.cnode_untyped)?;
        for untyped in &realm.object_untyped {
            self.allocator.revoke_and_free(&untyped)?;
        }
        self.externs.extend(realm.externs);
        Ok(())
    }

    ////

    fn realize_inner(&mut self, model: &Model, num_nodes: usize) -> Fallible<Realm> {
        let view = ModelView::new(model);

        // allocate

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
                        _ => {
                        }
                    }
                }
            }
            size_bits_to_contain(view.local_objects.len() + num_frame_mappings)
        };

        let local_object_blueprints: Vec<ObjectBlueprint> = view.local_objects.iter().map(|i| {
            match &model.objects[*i].object {
                AnyObj::Local(obj) => blueprint_of(&obj),
                _ => panic!(),
            }
        }).collect();

        let untyped_requirements: Vec<usize> = {
            let mut v = vec![0; 64];
            v[ObjectBlueprint::CNode { size_bits: cnode_slots_size_bits }.physical_size_bits()] += 1;
            for blueprint in &local_object_blueprints {
                v[blueprint.physical_size_bits()] += 1
            }
            v
        };
        ensure!(self.allocator.peek_space(&untyped_requirements));

        let (mut cregion, cnode_untyped) = self.allocator.create_cnode(cnode_slots_size_bits)?;
        let (local_object_slots, local_object_untyped) = self.allocator.create_objects(&mut cregion, &local_object_blueprints)?;

        // fill pages
        // TODO continuation interface with integrity protection
        for (i, obj) in model.objects.iter().enumerate() {
            if let AnyObj::Local(obj) = &obj.object {
                let cptr = cregion.cptr(view.local_objects[view.reverse[i]]);
                match obj {
                    Obj::SmallPage(frame) => {
                        self.initialization_resources.fill_frame(SmallPage::from_cptr(cptr), &frame.fill)?;
                    }
                    Obj::LargePage(frame) => {
                        self.initialization_resources.fill_frame(LargePage::from_cptr(cptr), &frame.fill)?;
                    }
                    _ => {
                    }
                }
            }
        }

        // initialize objects
        let (externs, extern_caps): (Externs, Vec<Unspecified>) = todo!(); // f(model, &mut self.externs)
        let all_caps: Vec<Unspecified> = model.objects.iter().enumerate().map(|(i, obj)| {
            match &obj.object {
                AnyObj::Local(_) => Unspecified::from_cptr(cregion.cptr(local_object_slots[view.reverse[i]])),
                AnyObj::Extern(_) => extern_caps[view.reverse[i]],
            }
        }).collect();

        let virtual_nodes = self.initialization_resources.initialize(num_nodes, model, &all_caps, &mut cregion)?;
        let virtual_nodes = virtual_nodes.into_iter().map(|tcbs| VirtualNode {
            tcbs, physical_node: None,
        }).collect();

        Ok(Realm {
            virtual_nodes,
            cnode_untyped,
            object_untyped: local_object_untyped,
            externs,
        })
    }
}
