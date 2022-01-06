#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

use alloc::prelude::v1::*;
use alloc::collections::btree_map::BTreeMap;
use icecap_core::prelude::*;
use icecap_core::rpc_sel4::*;
use icecap_resource_server_types::*;
use icecap_event_server_types as event_server;
use icecap_timer_server_client::TimerClient;
use dyndl_types::*;

mod cregion;
mod allocator;
mod utils;
mod model_view;
mod initialize_realm_objects;
mod cpu;

use utils::*;
use model_view::ModelView;
use cpu::{
    NUM_NODES, schedule,
};

pub use cregion::{CRegion, Slot};
pub use allocator::{Allocator, AllocatorBuilder};
pub use initialize_realm_objects::{RealmObjectInitializationResources};

#[allow(dead_code)]
pub struct FillId {
    obj_id: ObjId,
    fill_index: usize,
}

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

pub struct ResourceServer {
    initialization_resources: RealmObjectInitializationResources,
    allocator: Allocator,
    externs: Externs,

    realms: BTreeMap<RealmId, Realm>,
    partial_specs: BTreeMap<RealmId, Vec<u8>>,

    // TODO
    // partial_realms: BTreeMap<RealmId, PartialRealm>,

    physical_nodes: [Option<(RealmId, VirtualNodeIndex)>; NUM_NODES],

    cnode: CNode,
    node_local: Vec<NodeLocal>,
}

pub struct NodeLocal {
    pub reply_slot: Endpoint,
    pub timer_server_client: TimerClient,
    pub event_server_control: RPCClient::<event_server::calls::ResourceServer>,
}

struct Realm {
    virtual_nodes: Vec<VirtualNode>,

    // ID of the Untyped retyped for the realm's CNode.
    cnode_untyped_id: UntypedId,

    // IDs of the Untypeds retyped for the realm's objects.
    object_untyped_ids: Vec<UntypedId>,

    externs: Externs,
}

struct VirtualNode {
    tcbs: Vec<TCB>,
    physical_node: Option<PhysicalNodeIndex>, // TODO include timout target?
}

// TODO
// struct PartialRealm {
// }

impl ResourceServer {

    pub fn new(
        initialization_resources: RealmObjectInitializationResources,
        allocator: Allocator,
        externs: Externs,

        cnode: CNode,
        node_local: Vec<NodeLocal>,
    ) -> Self {
        ResourceServer {
            initialization_resources,
            allocator,
            externs,

            realms: BTreeMap::new(),
            partial_specs: BTreeMap::new(),

            physical_nodes: [None; NUM_NODES],

            cnode,
            node_local,
        }
    }

    // Kernel object resources

    pub fn declare(&mut self, realm_id: RealmId, spec_size: usize) -> Fallible<()> {
        assert!(!self.partial_specs.contains_key(&realm_id));
        assert!(!self.realms.contains_key(&realm_id));
        self.partial_specs.insert(realm_id, vec![0; spec_size]);
        Ok(())
    }

    pub fn incorporate_spec_chunk(&mut self, realm_id: RealmId, offset: usize, chunk: &[u8]) -> Fallible<()> {
        let range = offset .. offset + chunk.len();
        let partial = self.partial_specs.get_mut(&realm_id).unwrap();
        partial[range].copy_from_slice(chunk);
        Ok(())
    }

    pub fn realize(&mut self, node_index: usize, realm_id: RealmId) -> Fallible<()> {
        let raw = self.partial_specs.remove(&realm_id).unwrap();
        let model = postcard::from_bytes(&raw).unwrap();
        let realm = self.realize_inner(&model)?;

        self.realms.insert(realm_id, realm);

        self.node_local[node_index].event_server_control.call::<()>(&event_server::calls::ResourceServer::CreateRealm {
            realm_id,
            num_nodes: 1,
        });

        Ok(())
    }

    pub fn destroy(&mut self, node_index: usize, realm_id: RealmId) -> Fallible<()> {
        if let Some(realm) = self.realms.remove(&realm_id) {
            for virtual_node in &realm.virtual_nodes {
                assert!(virtual_node.physical_node.is_none());
                // HACK
                for virtual_node in &realm.virtual_nodes {
                    for tcb in &virtual_node.tcbs {
                        schedule(*tcb, None)?;
                    }
                }
            }
            self.allocator.revoke_and_free(&realm.cnode_untyped_id)?;
            for untyped_id in &realm.object_untyped_ids {
                self.allocator.revoke_and_free(&untyped_id)?;
            }
            self.externs.extend(realm.externs);

            // HACK
            self.node_local[node_index].event_server_control.call::<()>(&event_server::calls::ResourceServer::DestroyRealm {
                realm_id,
            });
        } else {
            // HACK
        }
        Ok(())
    }

    fn realize_inner(&mut self, model: &Model) -> Fallible<Realm> {
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

        let (mut cregion, cnode_untyped_id, _managed_cnode_slot) = self.allocator.create_cnode(cnode_slots_size_bits)?;
        let (local_object_slots, local_object_untyped_ids) = self.allocator.create_objects(&mut cregion, &local_object_blueprints)?;

        // fill pages
        // TODO continuation interface with integrity protection
        for (i, obj) in model.objects.iter().enumerate() {
            if let AnyObj::Local(obj) = &obj.object {
                let cptr_with_depth = cregion.cptr_with_depth(local_object_slots[view.reverse[i]]);
                match obj {
                    Obj::SmallPage(frame) => {
                        self.initialization_resources.fill_frame(cptr_with_depth.local_cptr::<SmallPage>(), &frame.fill)?;
                    }
                    Obj::LargePage(frame) => {
                        self.initialization_resources.fill_frame(cptr_with_depth.local_cptr::<LargePage>(), &frame.fill)?;
                    }
                    _ => {
                    }
                }
            }
        }

        // initialize objects
        let (externs, extern_caps): (Externs, Vec<Unspecified>) = {
            let mut externs = BTreeMap::new();

            let extern_caps: Vec<Unspecified> = view.extern_objects.iter().map(|i| {
                match &model.objects[*i].object {
                    AnyObj::Extern(obj) => {
                        let name = model.objects[*i].name.clone();
                        let ext = self.externs.remove(&name).unwrap();
                        assert_eq!(&ext.ty, obj);
                        let cptr = ext.cptr;

                        // Store the removed extern from self.extern to restore
                        // when the realm is destroyed.
                        externs.insert(name, ext);

                        // Collect the cptr.
                        cptr
                    }
                    _ => panic!(),
                }
            }).collect();

            (externs, extern_caps)
        };

        let all_caps: Vec<Unspecified> = model.objects.iter().enumerate().map(|(i, obj)| {
            match &obj.object {
                AnyObj::Local(_) => cregion.cptr_with_depth(local_object_slots[view.reverse[i]]).local_cptr::<Unspecified>(),
                AnyObj::Extern(_) => extern_caps[view.reverse[i]],
            }
        }).collect();

        let virtual_nodes = self.initialization_resources.initialize(model.num_nodes, model, &all_caps, &mut cregion)?;
        let virtual_nodes: Vec<VirtualNode> = virtual_nodes.into_iter().map(|tcbs| VirtualNode {
            tcbs, physical_node: None,
        }).collect();

        Ok(Realm {
            virtual_nodes,
            cnode_untyped_id,
            object_untyped_ids: local_object_untyped_ids,
            externs,
        })
    }

    // CPU resources

    pub fn yield_to(&mut self, physical_node: PhysicalNodeIndex, realm_id: RealmId, virtual_node: VirtualNodeIndex, timeout: Option<Nanoseconds>) -> Fallible<()> {
        // HACK
        self.cnode.save_caller(self.node_local[physical_node].reply_slot)?;

        assert!(self.physical_nodes[physical_node].is_none());
        self.physical_nodes[physical_node] = Some((realm_id, virtual_node));
        let realm = self.realms.get_mut(&realm_id).unwrap();
        let virtual_node = &mut realm.virtual_nodes[virtual_node];
        assert!(virtual_node.physical_node.is_none());
        virtual_node.physical_node = Some(physical_node);
        for tcb in &virtual_node.tcbs {
            schedule(*tcb, Some(physical_node))?;
        }
        self.set_notify_host_event(physical_node)?;
        if let Some(timeout) = timeout {
            self.set_timeout(physical_node, timeout)?;
        }
        Ok(())
    }

    pub fn yield_back(&mut self, realm_id: RealmId, virtual_node: VirtualNodeIndex, condition: YieldBackCondition) -> Fallible<()> {
        let realm = self.realms.get_mut(&realm_id).unwrap();
        let virtual_node = &mut realm.virtual_nodes[virtual_node];
        let physical_node = virtual_node.physical_node.take().unwrap();
        for tcb in &virtual_node.tcbs {
            schedule(*tcb, None)?;
        }
        self.cancel_notify_host_event(physical_node)?;
        self.cancel_timeout(physical_node)?;
        self.resume_host(physical_node, ResumeHostCondition::RealmYieldedBack(condition))?;
        Ok(())
    }

    pub fn host_event(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        if let Some((realm_id, virtual_node)) = self.physical_nodes[physical_node].take() {
            let realm = self.realms.get_mut(&realm_id).unwrap();
            let virtual_node = &mut realm.virtual_nodes[virtual_node];
            virtual_node.physical_node = None;
            for tcb in &virtual_node.tcbs {
                schedule(*tcb, None)?;
            }
            self.cancel_notify_host_event(physical_node)?;
            self.cancel_timeout(physical_node)?;
            self.resume_host(physical_node, ResumeHostCondition::HostEvent)?;
        }
        Ok(())
    }

    pub fn timeout(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        if let Some((realm_id, virtual_node)) = self.physical_nodes[physical_node].take() {
            let realm = self.realms.get_mut(&realm_id).unwrap();
            let virtual_node = &mut realm.virtual_nodes[virtual_node];
            virtual_node.physical_node = None;
            for tcb in &virtual_node.tcbs {
                schedule(*tcb, None)?;
            }
            self.cancel_notify_host_event(physical_node)?;
            self.resume_host(physical_node, ResumeHostCondition::Timeout)?;
        }
        Ok(())
    }

    pub fn hack_run(&mut self, realm_id: RealmId) -> Fallible<()> {
        let realm = self.realms.get(&realm_id).unwrap();
        for (i, virtual_node) in realm.virtual_nodes.iter().enumerate() {
            for tcb in &virtual_node.tcbs {
                schedule(*tcb, Some(i))?;
            }
        }
        Ok(())
    }

    ///

    fn set_timeout(&mut self, physical_node: PhysicalNodeIndex, ns: Nanoseconds) -> Fallible<()> {
        self.node_local[physical_node].timer_server_client.oneshot_relative(0, ns as u64).unwrap();
        Ok(())
    }

    fn cancel_timeout(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        self.node_local[physical_node].timer_server_client.stop(0).unwrap();
        Ok(())
    }

    fn set_notify_host_event(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        self.node_local[physical_node].event_server_control.call::<()>(&event_server::calls::ResourceServer::Subscribe { nid: physical_node, host_nid: physical_node });
        Ok(())
    }

    fn cancel_notify_host_event(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        self.node_local[physical_node].event_server_control.call::<()>(&event_server::calls::ResourceServer::Unsubscribe { nid: physical_node, host_nid: physical_node });
        Ok(())
    }

    fn resume_host(&mut self, physical_node: PhysicalNodeIndex, condition: ResumeHostCondition) -> Fallible<()> {
        // debug_println!("resuming with {:?}", condition);
        RPCClient::<ResumeHostCondition>::new(self.node_local[physical_node].reply_slot).send(&condition);
        Ok(())
    }
}
