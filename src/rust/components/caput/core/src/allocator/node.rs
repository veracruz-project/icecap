use alloc::collections::BTreeMap;

use icecap_core::prelude::*;
use crate::{CRegion, Slot, UntypedId};

// TODO: Encode the invariant that a consumed node never has children.
// TODO: Encode that a built-in will never have a built-in as a child.
#[derive(Clone, Debug)]
pub(crate) struct Node {
    pub(crate) node_type: NodeType,
    pub(crate) left: Option<Box<Node>>,
    pub(crate) right: Option<Box<Node>>,
}

impl Node {
    pub(crate) fn new() -> Self {
        Self {
            node_type: NodeType::Inaccessible,
            left: None,
            right: None,
        }
    }

    pub(crate) fn is_accessible(&self) -> bool {
        match self.node_type {
            NodeType::Accessible { .. } => true,
            _ => false,
        }
    }

    // Returns a reference to a Node's AccessibleNodeType variant
    pub(crate) fn get_accessible_node_type(&self) -> &AccessibleNodeType {
        match &self.node_type {
            NodeType::Inaccessible => panic!("Attempting to access members of an Inaccessible Node"),
            NodeType::Accessible { consumed, accessible_node_type } => &accessible_node_type,
        }
    }

    pub(crate) fn get_slot(&self) -> Slot {
        assert!(self.is_managed());

        let accessible_node_type = self.get_accessible_node_type();
        if let AccessibleNodeType::Managed { slot } = accessible_node_type {
            return *slot;
        } else {
            panic!("Can only get a slot from a Managed Node");
        }
    }

    pub(crate) fn is_managed(&self) -> bool {
        if self.is_accessible() {
            if let NodeType::Accessible { consumed, accessible_node_type } = &self.node_type {
                if let AccessibleNodeType::Managed { .. } = accessible_node_type {
                    return true;
                }
            }
        }
        return false;
    }

    pub(crate) fn is_consumed(&self) -> bool {
        if self.is_accessible() {
            if let NodeType::Accessible { consumed, .. } = self.node_type {
                if consumed {
                    return true;
                }
            }
        }
        return false;
    }

    /// Marks an Untyped as consumed.
    ///
    /// panics if the Untyped is already consumed.
    pub(crate) fn set_consumed(&mut self, set_consumed: bool) {
        assert!(!self.is_consumed());
        if self.is_accessible() {
            if let NodeType::Accessible { consumed, .. } = &mut self.node_type {
                *consumed = set_consumed;
            }
        } else {
            panic!("Attempting to set consumed on an inaccessible Node");
        }
    }

    // Gets the local local_cptr for the node.
    pub(crate) fn local_cptr(&self, cregion: &CRegion) -> Untyped {
        assert!(self.is_accessible());

        let accessible_node_type = self.get_accessible_node_type();

        match accessible_node_type {
            AccessibleNodeType::BuiltIn { local_cptr } => {
                *local_cptr
            }
            AccessibleNodeType::Managed { slot } => {
                cregion.cptr_with_depth(*slot).local_cptr_hack::<Untyped>()
            }
        }
    }

    // Gets the relative cptr for the node.
    pub(crate) fn relative_cptr(&self, cregion: &CRegion) -> RelativeCPtr {
        assert!(self.is_accessible());

        let accessible_node_type = self.get_accessible_node_type();

        match accessible_node_type {
            AccessibleNodeType::BuiltIn { local_cptr } => {
                cregion.context().relative(*local_cptr)
            }
            AccessibleNodeType::Managed { slot } => {
                cregion.relative_cptr(*slot)
            }
        }
    }

    // Gets a reference to the node corresponding to untyped_id.
    //
    // Progresses through the tree from the root of the
    // capability derivation tree to the Node specified by UntypedId.
    //
    // panics if the Node is not in the tree.
    pub(crate) fn get_node<'a>(root_node: &'a Node, untyped_id: &UntypedId) -> &'a Node {
        let mut depth = 64;
        let mut low_addr = 0;
        let mut high_addr = 0xFFFF_FFFF_FFFF_FFFF;
        let mut node = root_node;

        // Verify the paddr is in bounds
        assert!(untyped_id.paddr >= low_addr && untyped_id.paddr <= high_addr);

        while depth > untyped_id.size_bits {
            let half_addr = low_addr + ((high_addr - low_addr) >> 1) + 1;

            if untyped_id.paddr < half_addr {
                assert!(!node.left.is_none());
                high_addr = half_addr - 1;
                node = node.left.as_ref().unwrap();
            } else {
                assert!(!node.right.is_none());
                low_addr = half_addr;
                node = node.right.as_ref().unwrap();
            }
            depth -= 1;
        }

        // At this point, we should be at the requested Node.
        assert_eq!(depth, untyped_id.size_bits);
        node
    }

    // Gets a mutable reference to the node corresponding to untyped_id.
    //
    // Progresses through the tree from the root of the
    // capability derivation tree to the Node specified by UntypedId.
    //
    // panics if the Node is not in the tree.
    pub(crate) fn get_node_mut<'a>(root_node: &'a mut Node, untyped_id: &UntypedId) -> &'a mut Node {
        let mut depth = 64;
        let mut low_addr = 0;
        let mut high_addr = 0xFFFF_FFFF_FFFF_FFFF;
        let mut node = root_node;

        // Verify the paddr is in bounds
        assert!(untyped_id.paddr >= low_addr && untyped_id.paddr <= high_addr);

        while depth > untyped_id.size_bits {
            let half_addr = low_addr + ((high_addr - low_addr) >> 1) + 1;

            if untyped_id.paddr < half_addr {
                assert!(!node.left.is_none());
                high_addr = half_addr - 1;
                node = node.left.as_mut().unwrap();
            } else {
                assert!(!node.right.is_none());
                low_addr = half_addr;
                node = node.right.as_mut().unwrap();
            }
            depth -= 1;
        }

        // At this point, we should be at the requested Node.
        assert_eq!(depth, untyped_id.size_bits);
        node
    }
}

#[derive(Clone, Debug)]
pub(crate) enum NodeType {
    Inaccessible,
    Accessible {
        consumed: bool,
        accessible_node_type: AccessibleNodeType,
    }
}

#[derive(Clone, Debug)]
pub(crate) enum AccessibleNodeType {
    BuiltIn {
        local_cptr: Untyped,
    },
    Managed {
        slot: Slot,
    },
}

/// Structure for conveniently finding consumable leaf nodes in the capability
/// derivation tree without having to search the tree.  Once the UntypedId
/// of a consumable leaf node is found, however, the capability derivation
/// tree still needs to be traversed to find the associated Node.
///
/// The structure indexes UntypedIds by the size of the Untyped, allowing
/// for a simple lookup of a Untyped of a given size (or the next smallest
/// size if splitting will be required).
#[derive(Clone, Debug)]
pub(crate) struct LeafNodes {
    leaf_nodes: BTreeMap<usize, Vec<UntypedId>>,
}

impl LeafNodes {
    /// Initialise an empty LeafNodes structure.
    pub(crate) fn new() -> Self {
        Self {
            leaf_nodes: BTreeMap::new(),
        }
    }

    /// Insert an UntypedId into the LeafNodes structure.
    pub(crate) fn add_leaf(&mut self, untyped_id: &UntypedId) {
        match self.leaf_nodes.get_mut(&untyped_id.size_bits) {
            Some(untyped_ids) => untyped_ids.push(untyped_id.clone()),
            None => {
                self.leaf_nodes.insert(untyped_id.size_bits, vec![untyped_id.clone()]);
            }
        }
    }

    /// Returns an UntypedId with the specified size.  If a leaf of the
    /// specified size is not available, it returns the next smallest
    /// size.
    ///
    /// Removes the Untyped from the LeafNodes struct.
    ///
    /// panics if all Untypeds are smaller than the specified size.
    pub(crate) fn get_leaf(&mut self, size_bits: &usize) -> UntypedId {
        match self.leaf_nodes.get_mut(&size_bits) {
            Some(untyped_ids) => {
                // There is an Untyped region of exactly the right size.
                let untyped_id = untyped_ids.pop().unwrap();

                // If this is the last Untyped region of the size,
                // update leaf_nodes to reflect None.
                if untyped_ids.len() == 0 {
                    self.leaf_nodes.remove(&size_bits);
                }

                untyped_id
            }
            None => {
                // Find the next smallest Untyped region.
                let mut next_smallest_size = 0;
                for untyped_size in self.leaf_nodes.keys() {
                    if untyped_size > size_bits {
                        next_smallest_size = *untyped_size;
                        break;
                    }
                }
                assert!(next_smallest_size != 0);

                // Get an Untyped with the specified size.
                let untyped_ids = self.leaf_nodes.get_mut(&next_smallest_size).unwrap();

                let untyped_id = untyped_ids.pop().unwrap();

                // If this is the last Untyped region of the size,
                // update leaf_nodes to reflect None.
                if untyped_ids.len() == 0 {
                    self.leaf_nodes.remove(&next_smallest_size);
                }

                untyped_id
            }
        }
    }

    /// Remove an UntypedId from the LeafNodes structure.
    pub(crate) fn remove_leaf(&mut self, untyped_id_to_remove: &UntypedId) {
        match self.leaf_nodes.get_mut(&untyped_id_to_remove.size_bits) {
            Some(untyped_ids) => {
                // At this point, all the size_bits of Untypeds in untyped_ids
                // should match that of untyped_id_to_remove.
                for (idx, untyped_id) in untyped_ids.iter().enumerate() {
                    // If we find a match, remove it and break.
                    if untyped_id.paddr == untyped_id_to_remove.paddr {
                        untyped_ids.remove(idx);
                        break;
                    }
                }
            }
            _ => {}
        }
    }

    /// Identify the total consumable space available in LeafNodes.
    /// NOTE: This doesn't guarantee that an Untyped of a specific size is
    /// available; it only provides the sum of all the Untyped space.
    pub(crate) fn consumable_space(&self) -> usize {
        let mut consumable_space = 0;

        for (size_bits, untyped_ids) in self.leaf_nodes.iter() {
            consumable_space += (1 << size_bits) * untyped_ids.len();
        }

        consumable_space
    }
}
