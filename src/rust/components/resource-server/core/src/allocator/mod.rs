use core::convert::TryFrom;

use icecap_core::prelude::*;
use crate::{CRegion, Slot, UntypedId, ElaboratedUntyped};

mod node;
use node::{Node, NodeType, AccessibleNodeType, LeafNodes};

pub struct AllocatorBuilder {
    cregion: CRegion,
    fragmentation_threshold_size_bits: usize,
    untyped: Vec<ElaboratedUntyped>,
}

impl AllocatorBuilder {

    pub fn new(cregion: CRegion) -> Self {
        Self {
            cregion,
            fragmentation_threshold_size_bits: 0,
            untyped: vec![],
        }
    }

    pub fn add_untyped(&mut self, untyped: ElaboratedUntyped) {
        // TODO: Verify that the untyped are disjoint.
        self.untyped.push(untyped);
    }

    pub fn set_fragmentation_threshold_size_bits(&mut self, fragmentation_threshold_size_bits: usize) {
        self.fragmentation_threshold_size_bits = fragmentation_threshold_size_bits;
    }

    pub fn build(self) -> Allocator {
        let mut allocator = Allocator {
            cregion: self.cregion,
            fragmentation_threshold_size_bits: self.fragmentation_threshold_size_bits,
            cap_derivation_tree: Node::new(),
            leaf_nodes: LeafNodes::new(),
        };

        // Add the built ins to the derivation tree and to the leaf nodes.
        for untyped in self.untyped.iter() {
            let untyped_cptr = untyped.cptr;
            let untyped_id = &untyped.untyped_id;
            let mut low_addr = 0;
            let mut high_addr = 0xFFFF_FFFF_FFFF_FFFF;
            let mut depth = 64;

            // We assume the untyped region will never be the root of the
            // capability derivation tree (e.g., paddr == 0 and
            // size_bits == 64).
            assert!(!(untyped_id.paddr == 0 && untyped_id.size_bits == 64));

            // Verify the paddr is in bounds
            assert!(untyped_id.paddr >= low_addr && untyped_id.paddr <= high_addr);

            // Work down the tree, creating Inaccessible Nodes until we get
            // to the Node corresponding to the UntypedId, then create a
            // BuiltIn Node.
            let mut node = &mut allocator.cap_derivation_tree;
            while depth > untyped_id.size_bits {
                let half_addr = low_addr + ((high_addr - low_addr) >> 1) + 1;
                if untyped_id.paddr < half_addr {
                    high_addr = half_addr - 1;
                    if node.left.is_none() {
                        node.left = Some(
                            Box::new(
                                Node {
                                    node_type: NodeType::Inaccessible,
                                    left: None,
                                    right: None,
                                })
                            );
                    }
                    node = node.left.as_mut().unwrap();
                } else {
                    low_addr = half_addr;
                    if node.right.is_none() {
                        node.right = Some(
                            Box::new(
                                Node {
                                    node_type: NodeType::Inaccessible,
                                    left: None,
                                    right: None,
                                })
                            );
                    }
                    node = node.right.as_mut().unwrap();
                }
                depth -= 1;
            }

            // At this point, we should be at the depth of the BuiltIn
            assert_eq!(depth, untyped_id.size_bits);

            // The Node was created as Inaccessible, so we'll recreate it as
            // a BuiltIn and assign the untyped_cptr.
            *node = Node {
                node_type: NodeType::Accessible {
                    consumed: false,
                    accessible_node_type: AccessibleNodeType::BuiltIn {
                        local_cptr: untyped_cptr,
                    },
                },
                left: None,
                right: None,
            };

            // Add the BuiltIn to leaf_nodes
            allocator.leaf_nodes.add_leaf(&untyped_id);
        }

        allocator
    }
}

/// Structure used to allocate memory for Realms and Realm objects.
pub struct Allocator {
    cregion: CRegion,
    fragmentation_threshold_size_bits: usize,
    cap_derivation_tree: Node,
    leaf_nodes: LeafNodes,
}

impl Allocator {

    /// Determine if there is sufficient Untyped left to create the number and
    /// size of objects provided to the function.
    ///
    /// count_by_size_bits: Vector indexed by size_bits containing a count of
    /// object requiring that many size bits.
    ///
    /// TODO: Function currently only ensures there is enough TOTAL space to
    /// fit all the objects, but it's possible that the BuiltIn Untyped regions
    /// are sized such that they cannot actually fit the provided objects (e.g.,
    /// we have two Untyped regions for 8 bytes and want an object requiring 16
    /// bytes).  We basically need to implement a knapsack solution to do this
    /// more robustly.  At the moment we assume that the BuiltIns provided will
    /// be sufficient for each of the objects requested.
    pub fn peek_space(&self, count_by_size_bits: &[usize]) -> bool {
        // Get the total size requested.
        let mut required_space = 0;
        for (size_bits, count) in count_by_size_bits.iter().enumerate() {
            required_space += (1 << size_bits) * count;
        }

        // Obtain the consumable space available in leaf nodes.
        let consumable_space = self.leaf_nodes.consumable_space();

        // Return true if there is sufficient consumable space.
        consumable_space >= required_space
    }

    /// Create a new CNode with 2^radix slots.
    pub fn create_cnode(&mut self, radix: usize) -> Fallible<(CRegion, UntypedId, Slot)> {
        // Get a slot in the allocator's CNode to place a cap to the new CNode.

        // Create a CRegion for the new CNode.
        let realm_slot = self.cregion.alloc().unwrap();
        let realm_cnode = self.cregion.relative_cptr(realm_slot);
        let guard = 0;
        let guard_size = u64::try_from(64 - realm_cnode.path.depth - radix).unwrap();
        let realm_cregion = CRegion::new(realm_cnode, guard, guard_size, radix);

        // Create a blueprint for the CNode which will be used to create the object.
        let blueprint = ObjectBlueprint::CNode { size_bits: radix };

        // The CPtr to the realm's CNode will be placed in the allocator's CNode.
        let destination_cnode = &self.cregion.root.clone();

        // Create a temporary Slot and RelativeCPtr for the initial object.
        let temp_slot = self.cregion.alloc().unwrap();
        let temp_rel_cptr = self.cregion.relative_cptr(temp_slot);
        let untyped_id = self.create_object(&destination_cnode, temp_slot, blueprint);

        // Mutate the temporary RelativeCPtr to add the realm CNode's guard and store it as
        // the CPtr to the realm's CNode.
        realm_cregion.root.mutate(&temp_rel_cptr, CNodeCapData::new(guard, guard_size).raw())?;

        // Clean up the temporary Slot and RelativeCPtr.
        temp_rel_cptr.delete()?;
        self.cregion.free(temp_slot);

        Ok((realm_cregion, untyped_id, realm_slot))
    }

    // destination_cnode: cptr to the destination cnode
    // slot: slot in which to create the object
    // blueprint: blueprint of the object to be created
    fn create_object(&mut self, destination_cnode: &RelativeCPtr, slot: Slot, blueprint: ObjectBlueprint) -> UntypedId {
        let phys_size_bits = blueprint.physical_size_bits();

        // Find a Node of Untyped to retype.
        let mut untyped_id = self.leaf_nodes.get_leaf(&phys_size_bits);

        // If the returned Untyped is too big, we need to split it.
        if untyped_id.size_bits > phys_size_bits {
            // The difference between phys_size_bits and next_smallest_size
            // identifies how many times we'll have to split the Untyped.
            for _ in phys_size_bits .. untyped_id.size_bits {
                // Split the Untyped into slots in the root CNode.
                let (left_child_untyped_id, right_child_untyped_id) = self.split_untyped(untyped_id);

                // Work down the right side of the tree.
                untyped_id = right_child_untyped_id;
                self.leaf_nodes.remove_leaf(&untyped_id);
            }

            // At this point, untyped_id is an Untyped of the correct size.
        }

        // Find the Node corresponding to the untyped_id
        let node = Node::get_node_mut(&mut self.cap_derivation_tree, &untyped_id);

        // Set the node to consumed, since we're about to retype it.
        node.set_consumed(true);

        // Get the local cptr for the Untyped and retype it into the destination cnode.
        let local_cptr = node.local_cptr(&self.cregion);
        local_cptr.retype(blueprint, &destination_cnode, u64::try_from(slot).unwrap(), 1).unwrap();

        // Return the untyped id of the node that was retyped.
        return untyped_id;
    }

    // Splits an Untyped object and places the two new CPtrs into the CRegion's root CNode.
    fn split_untyped(&mut self, untyped_id: UntypedId) -> (UntypedId, UntypedId) {
        // Create the blueprint for the new Untyped.
        let new_size_bits = untyped_id.size_bits - 1;
        let blueprint = ObjectBlueprint::Untyped { size_bits: new_size_bits };

        // Identify the slot numbers into which the Untyped will be split.
        let left_slot = self.cregion.alloc().unwrap();
        let right_slot = self.cregion.alloc().unwrap();

        // Find the node corresponding to the untyped_id to be split.
        let node = Node::get_node_mut(&mut self.cap_derivation_tree, &untyped_id);
        assert!(!node.is_consumed());

        // Derive a local cptr to the Untyped.
        let local_cptr = node.local_cptr(&self.cregion);

        // Split the Untyped by retyping into two Untyped regions.
        local_cptr.retype(blueprint, &self.cregion.root, u64::try_from(left_slot).unwrap(), 1).unwrap();
        local_cptr.retype(blueprint, &self.cregion.root, u64::try_from(right_slot).unwrap(), 1).unwrap();

        // Add the child Nodes to the parent Node.
        node.left = Some(
            Box::new(
                Node {
                    node_type: NodeType::Accessible {
                        consumed: false,
                        accessible_node_type: AccessibleNodeType::Managed {
                            slot: left_slot,
                        },
                    },
                    left: None,
                    right: None,
                })
        );

        node.right = Some(
            Box::new(
                Node {
                    node_type: NodeType::Accessible {
                        consumed: false,
                        accessible_node_type: AccessibleNodeType::Managed {
                            slot: right_slot,
                        },
                    },
                    left: None,
                    right: None,
                })
        );

        // Add the new children to leaf_nodes.
        let left_child_untyped_id = UntypedId {
            paddr: untyped_id.paddr,
            size_bits: new_size_bits,
        };
        self.leaf_nodes.add_leaf(&left_child_untyped_id);

        let right_child_untyped_id = UntypedId {
           paddr: untyped_id.paddr + (1 << new_size_bits),
            size_bits: new_size_bits,
        };
        self.leaf_nodes.add_leaf(&right_child_untyped_id);

        (left_child_untyped_id, right_child_untyped_id)
    }

    // Creates multiple objects in the provided cregion based on the provided blueprints.
    // TODO: Refactor to create all the objects from a single Untyped to reduce syscalls.
    pub fn create_objects(&mut self, realm_cregion: &mut CRegion,
                          blueprints: &[ObjectBlueprint]) -> Fallible<(Vec<Slot>, Vec<UntypedId>)> {

        let mut slots = Vec::new();
        let mut untyped_ids = Vec::new();

        for (idx, blueprint) in blueprints.iter().enumerate() {
            let slot = realm_cregion.alloc().unwrap();
            let untyped_id = self.create_object(&realm_cregion.root, slot, *blueprint);
            slots.push(slot);
            untyped_ids.push(untyped_id);
        }

        Ok((slots, untyped_ids))
    }

    /// Recursively searches the capability derivation tree for the given
    /// UntypedId, revokes the Node's capability, frees the Untyped block
    /// to be reused, and then returns back up the tree, revoking and freeing
    /// parent Nodes that no longer have used child Nodes.
    pub fn revoke_and_free(&mut self, untyped_id: &UntypedId) -> Fallible<()> {
        // The root node is held by the capability derivation tree

        // TODO:  Cloning here and cloning back to avoid the "you can't borrow *self mutably twice"
        // error.  This strongly indicates a flaw in the structure or organisation and should be
        // fixed.
        let mut node = &mut self.cap_derivation_tree.clone();
        let low_addr = 0;
        let high_addr = 0xFFFF_FFFF_FFFF_FFFF;
        let depth_from_root = 0;

        self.revoke_and_free_helper(&mut node, low_addr, high_addr,
                                    depth_from_root, untyped_id)?;

        self.cap_derivation_tree = node.clone();

        Ok(())
    }

    // Recursive helper function for revoke_and_free()
    fn revoke_and_free_helper(&mut self, node: &mut Node, low_addr: usize,
                              high_addr: usize, depth_from_root: usize,
                              untyped_id: &UntypedId) -> Fallible<()> {
        // Check if we're at the correct level of the tree.
        if (64 - depth_from_root) == untyped_id.size_bits {
            // Enforce the invariant that we only revoke and free accessible,
            // consumed, nodes without children.
            assert!(node.is_accessible());
            assert!(node.is_consumed());
            assert!(node.left.is_none() && node.right.is_none());

            // TODO: The invariant that the paddr is aligned to size bits should be
            // enforced on UntypedId.
            assert_eq!(low_addr, untyped_id.paddr);

            // Revoke the capability pointed to by the Node.
            node.relative_cptr(&self.cregion).revoke()?;

            // Set consumed to false.
            node.set_consumed(false);

            // Add the freed Untyped to the leaf_nodes structure.
            self.leaf_nodes.add_leaf(&untyped_id);

            // We don't need to free the slot in the realm CNode because this
            // function only gets called when the realm is being destroyed, so
            // we aren't at risk of leaking slots.

        // If we're too high in the tree, recurse down.
        } else {
            // Verify the paddr is in bounds
            assert!(untyped_id.paddr >= low_addr && untyped_id.paddr <= high_addr);

            let half_addr = low_addr + ((high_addr - low_addr) >> 1) + 1;
            if untyped_id.paddr < half_addr {
                // Recurse down the left child.
                assert!(!node.left.is_none());
                self.revoke_and_free_helper(node.left.as_mut().unwrap(), low_addr,
                                            half_addr - 1, depth_from_root + 1,
                                            untyped_id)?;
            } else {
                // Recurse down the right child.
                assert!(!node.right.is_none());
                self.revoke_and_free_helper(node.right.as_mut().unwrap(), half_addr,
                                            high_addr, depth_from_root + 1,
                                            untyped_id)?;
            }

            // If the node is accessible and its children are deletable (or empty),
            // revoke the Node's capability, add it to LeafNodes, and delete the children.
            if node.is_accessible() &&
                (node.left.is_none() || node.left.as_ref().unwrap().is_deletable()) &&
                (node.right.is_none() || node.right.as_ref().unwrap().is_deletable()) {

                // Clean up the children.
                if !node.left.is_none() {
                    // Free the child's slot in the Managed CNode.
                    self.cregion.free(node.left.as_ref().unwrap().get_slot());

                    // Derive the child's UntypedId and remove it from the leaf_nodes structure.
                    let untyped_id = UntypedId {
                        paddr: low_addr,
                        size_bits: 64 - (depth_from_root + 1),
                    };
                    self.leaf_nodes.remove_leaf(&untyped_id);

                    // Delete child nodes.
                    node.left = None;
                }

                if !node.right.is_none() {
                    // Free the child's slot in the Managed CNode.
                    self.cregion.free(node.right.as_ref().unwrap().get_slot());

                    // Derive the child's UntypedId and remove it from the leaf_nodes structure.
                    let half_addr = low_addr + ((high_addr - low_addr) >> 1) + 1;
                    let untyped_id = UntypedId {
                        paddr: half_addr,
                        size_bits: 64 - (depth_from_root + 1),
                    };
                    self.leaf_nodes.remove_leaf(&untyped_id);

                    // Delete child nodes.
                    node.right = None;
                }

                // Invoke revoke() on this node's capability (to revoke it's children)
                node.relative_cptr(&self.cregion).revoke()?;

                // Derive the node's UntypedId.
                let untyped_id = UntypedId {
                    paddr: low_addr,
                    size_bits: 64 - depth_from_root,
                };

                // Add the node's freed Untyped to the leaf_nodes structure.
                self.leaf_nodes.add_leaf(&untyped_id);

            }
        }
        Ok(())
    }
}
