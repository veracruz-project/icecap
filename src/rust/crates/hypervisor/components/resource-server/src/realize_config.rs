use dyndl_realize::*;
use icecap_resource_server_config::*;
use icecap_std::prelude::*;

pub fn realize_initialization_resources(
    x: &ConfigSubsystemObjectInitializationResources,
) -> SubsystemObjectInitializationResources {
    SubsystemObjectInitializationResources {
        pgd: x.pgd,
        asid_pool: x.asid_pool,
        tcb_authority: x.tcb_authority,
        small_page_addr: x.small_page_addr,
        large_page_addr: x.large_page_addr,
    }
}

pub fn realize_cregion(x: &ConfigCRegion) -> CRegion {
    let root = x.root.root.relative_cptr(x.root.cptr, x.root.depth);
    CRegion::new(root, x.guard, x.guard_size, x.slots_size_bits)
}

pub fn realize_extern(x: &ConfigExtern) -> Extern {
    Extern {
        ty: x.ty,
        cptr: Unspecified::from_raw(x.cptr),
    }
}

pub fn realize_externs(x: &ConfigExterns) -> Externs {
    x.iter()
        .map(|(k, v)| (k.clone(), realize_extern(v)))
        .collect()
}
