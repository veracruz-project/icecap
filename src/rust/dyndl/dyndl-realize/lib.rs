#![no_std]
#![feature(alloc_prelude)]
#![feature(format_args_nl)]
#![allow(unreachable_code)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]

extern crate alloc;

use alloc::prelude::v1::*;
use alloc::collections::btree_map::BTreeMap;
use icecap_core::prelude::*;
use dyndl_types::*;
use core::convert::{TryFrom, TryInto};
use core::slice;
use serde::{Serialize, Deserialize};

mod utils;
mod create;
mod initialize;
use utils::*;
use create::*;

pub struct Initializer {
    pub cnode: CNode,
    pub pd: PGD,
    pub asid_pool: ASIDPool,
    pub tcb_authority: TCB,
    pub small_page_addr: usize,
    pub large_page_addr: usize,
}

pub struct MyExtra {
    // TODO only need SmallPage
    pub small_page: SmallPage,
    pub large_page: LargePage,
    pub free_slot: u64,
    pub untyped: Untyped,
}

pub struct Config {
    pub my: Initializer,
    pub my_extra: MyExtra,
    pub externs: Externs,
}

type Caps = Vec<Unspecified>;
pub type Externs = BTreeMap<String, Extern>;

pub struct Extern {
    pub ty: ExternObj,
    pub cptr: Unspecified,
}

pub struct EvilPlan {
    last_free_slot: u64,
    tcbs: Vec<TCB>,
}

impl Config {

    pub fn init(&self) -> Fallible<()> {
        self.my_extra.small_page.unmap()?;
        self.my_extra.large_page.unmap()?;
        Ok(())
    }

    pub fn realize(&self, model: &Model) -> Fallible<EvilPlan> {
        let free_slot = self.my_extra.free_slot + 1;
        let mut create = Create {
            untyped: self.my_extra.untyped,
            cnode: self.my.cnode,
            free_slot,
        };
        let caps = create.create_objects(model, &self.externs)?;
        let tcbs = self.my.initialize(&caps, model, &mut create)?;
        let last_free_slot = create.free_slot;
        let plan = EvilPlan {
            last_free_slot,
            tcbs,
        };
        Ok(plan)
    }

    pub fn destroy(&self, plan: EvilPlan) -> Fallible<()> {
        for tcb in plan.tcbs {
            tcb.suspend()?;
        }
        // TODO necessary?
        //  - Seems to only be necessary when frame duplication is implemented
        for slot in self.my_extra.free_slot..plan.last_free_slot {
            self.my.cnode.relative(&CPtr::from_raw(slot).deep()).delete()?
        }
        self.my.cnode.relative(self.my_extra.untyped).revoke()?;

        // TODO does this make something strict?
        // {
        //     let dst = self.my.cnode.relative_self();
        //     let dst_offset = self.my_extra.free_slot;
        //     self.my_extra.untyped.retype(ObjectBlueprint::Notification, &dst, dst_offset, 1)?;
        // }

        // abs.cnode_revoke()?;

        Ok(())
    }
}
