#![no_std]
#![feature(alloc_prelude)]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;
use alloc::prelude::v1::*;

use dyndl_realize::*;
use dyndl_types::*;
use hypervisor_event_server_types as event_server;
use hypervisor_resource_server_types::*;
use icecap_core::prelude::*;
use icecap_core::rpc;
use icecap_generic_timer_server_client::TimerClient;

mod cpu;

use cpu::{schedule, NUM_ACTIVE_CORES};

pub struct ResourceServer {
    realizer: Realizer,

    realms: BTreeMap<RealmId, Realm>,
    partial_specs: BTreeMap<RealmId, Vec<u8>>,

    partial_realms: BTreeMap<RealmId, PartialRealm>,
    physical_nodes: [Option<(RealmId, VirtualNodeIndex)>; NUM_ACTIVE_CORES],

    cnode: CNode,
    node_local: Vec<NodeLocal>,
}

pub struct NodeLocal {
    pub reply_slot: Endpoint,
    pub timer_server_client: TimerClient,
    pub event_server_control: rpc::Client<event_server::calls::ResourceServer>,
}

struct Realm {
    virtual_nodes: Vec<VirtualNode>,
    subsystem: Subsystem,
}

struct VirtualNode {
    tcbs: Vec<TCB>,
    physical_node: Option<PhysicalNodeIndex>, // TODO include timout target?
}

struct PartialRealm {
    partial_subsystem: PartialSubsystem,
}

impl ResourceServer {
    pub fn new(realizer: Realizer, cnode: CNode, node_local: Vec<NodeLocal>) -> Self {
        ResourceServer {
            realizer,
            realms: BTreeMap::new(),
            partial_specs: BTreeMap::new(),
            partial_realms: BTreeMap::new(),
            physical_nodes: [None; NUM_ACTIVE_CORES],
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

    pub fn incorporate_spec_chunk(
        &mut self,
        realm_id: RealmId,
        offset: usize,
        chunk: &[u8],
    ) -> Fallible<()> {
        let range = offset..offset + chunk.len();
        let partial = self.partial_specs.get_mut(&realm_id).unwrap();
        partial[range].copy_from_slice(chunk);
        Ok(())
    }

    pub fn realize_start(&mut self, realm_id: RealmId) -> Fallible<()> {
        let raw = self.partial_specs.remove(&realm_id).unwrap();
        let model: Model = postcard::from_bytes(&raw).unwrap();
        let model_ = model.clone();
        let partial_subsystem = self.realizer.realize_start(model_)?;
        self.partial_realms
            .insert(realm_id, PartialRealm { partial_subsystem });
        Ok(())
    }

    pub fn realize_continue(
        &mut self,
        realm_id: RealmId,
        object_index: usize,
        fill_entry_index: usize,
        content: &[u8],
    ) -> Fallible<()> {
        let partial_realm = self.partial_realms.get_mut(&realm_id).unwrap();
        self.realizer.realize_continue(
            &mut partial_realm.partial_subsystem,
            object_index,
            fill_entry_index,
            content,
        )?;
        Ok(())
    }

    pub fn realize_finish(&mut self, node_index: usize, realm_id: RealmId) -> Fallible<()> {
        let partial_realm = self.partial_realms.remove(&realm_id).unwrap();

        let subsystem = self
            .realizer
            .realize_finish(partial_realm.partial_subsystem)?;

        let virtual_nodes = subsystem
            .virtual_cores
            .iter()
            .map(|virtual_core| {
                Ok(VirtualNode {
                    tcbs: virtual_core
                        .tcbs
                        .iter()
                        .map(|virtual_core_tcb| {
                            let tcb = virtual_core_tcb.cap;
                            cpu::schedule(tcb, None)?;
                            if virtual_core_tcb.resume {
                                tcb.resume()?;
                            }
                            Ok(tcb)
                        })
                        .collect::<Fallible<Vec<TCB>>>()?,
                    physical_node: None,
                })
            })
            .collect::<Fallible<Vec<VirtualNode>>>()?;

        self.realms.insert(
            realm_id,
            Realm {
                subsystem,
                virtual_nodes,
            },
        );

        self.node_local[node_index].event_server_control.call::<()>(
            &event_server::calls::ResourceServer::CreateRealm {
                realm_id,
                num_nodes: 1,
            },
        );

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
            self.realizer.destroy(realm.subsystem)?;

            // HACK
            self.node_local[node_index]
                .event_server_control
                .call::<()>(&event_server::calls::ResourceServer::DestroyRealm { realm_id });
        } else {
            // HACK
        }
        Ok(())
    }

    // CPU resources

    pub fn yield_to(
        &mut self,
        physical_node: PhysicalNodeIndex,
        realm_id: RealmId,
        virtual_node: VirtualNodeIndex,
        timeout: Option<Nanoseconds>,
    ) -> Fallible<()> {
        // HACK
        self.cnode
            .save_caller(self.node_local[physical_node].reply_slot)?;

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

    pub fn yield_back(
        &mut self,
        realm_id: RealmId,
        virtual_node: VirtualNodeIndex,
        condition: YieldBackCondition,
    ) -> Fallible<()> {
        let realm = self.realms.get_mut(&realm_id).unwrap();
        let virtual_node = &mut realm.virtual_nodes[virtual_node];
        let physical_node = virtual_node.physical_node.take().unwrap();
        for tcb in &virtual_node.tcbs {
            schedule(*tcb, None)?;
        }
        self.cancel_notify_host_event(physical_node)?;
        self.cancel_timeout(physical_node)?;
        self.resume_host(
            physical_node,
            ResumeHostCondition::RealmYieldedBack(condition),
        )?;
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
        self.node_local[physical_node]
            .timer_server_client
            .oneshot_relative(0, ns as u64)
            .unwrap();
        Ok(())
    }

    fn cancel_timeout(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        self.node_local[physical_node]
            .timer_server_client
            .stop(0)
            .unwrap();
        Ok(())
    }

    fn set_notify_host_event(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        self.node_local[physical_node]
            .event_server_control
            .call::<()>(&event_server::calls::ResourceServer::Subscribe {
                nid: physical_node,
                host_nid: physical_node,
            });
        Ok(())
    }

    fn cancel_notify_host_event(&mut self, physical_node: PhysicalNodeIndex) -> Fallible<()> {
        self.node_local[physical_node]
            .event_server_control
            .call::<()>(&event_server::calls::ResourceServer::Unsubscribe {
                nid: physical_node,
                host_nid: physical_node,
            });
        Ok(())
    }

    fn resume_host(
        &mut self,
        physical_node: PhysicalNodeIndex,
        condition: ResumeHostCondition,
    ) -> Fallible<()> {
        // debug_println!("resuming with {:?}", condition);
        rpc::Client::<ResumeHostCondition>::new(self.node_local[physical_node].reply_slot)
            .send(&condition);
        Ok(())
    }
}
