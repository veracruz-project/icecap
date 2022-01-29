#![no_std]

use dyndl_realize::*;
use dyndl_realize_simple_config::*;
use dyndl_types::*;
use icecap_core::prelude::*;

pub fn initialize_simple_realizer_from_config(config: &RealizerConfig) -> Fallible<Realizer> {
    // Unmap dummy pages
    config.small_page.unmap()?;
    config.large_page.unmap()?;

    let cregion = {
        let config = &config.allocator_cregion;
        let root = config
            .root
            .root
            .relative_cptr(config.root.cptr, config.root.depth);
        CRegion::new(
            root,
            config.guard,
            config.guard_size,
            config.slots_size_bits,
        )
    };

    let allocator = {
        let mut builder = AllocatorBuilder::new(cregion);
        for DynamicUntyped {
            slot,
            size_bits,
            paddr,
            ..
        } in &config.untyped
        {
            builder.add_untyped(ElaboratedUntyped {
                cptr: *slot,
                untyped_id: UntypedId {
                    size_bits: *size_bits,
                    paddr: paddr.unwrap(), // HACK
                },
            });
        }
        builder.build()
    };

    let initialization_resources = {
        let config = &config.initialization_resources;
        SubsystemObjectInitializationResources {
            pgd: config.pgd,
            asid_pool: config.asid_pool,
            tcb_authority: config.tcb_authority,
            small_page_addr: config.small_page_addr,
            large_page_addr: config.large_page_addr,
        }
    };

    let externs = config
        .externs
        .iter()
        .map(|(k, v)| {
            (
                k.clone(),
                Extern {
                    ty: v.ty,
                    cptr: Unspecified::from_raw(v.cptr),
                },
            )
        })
        .collect();

    Ok(Realizer::new(initialization_resources, allocator, externs))
}

pub fn fill_frames_simple(
    realizer: &Realizer,
    partial_subsystem: &PartialSubsystem,
    fill_blob: &[u8],
) -> Fallible<()> {
    let mut offset = 0;
    for (i, obj) in partial_subsystem.model.objects.iter().enumerate() {
        if let AnyObj::Local(obj) = &obj.object {
            if let Some(fill) = match obj {
                Obj::SmallPage(frame) => Some(&frame.fill),
                Obj::LargePage(frame) => Some(&frame.fill),
                _ => None,
            } {
                for (j, entry) in fill.iter().enumerate() {
                    let next_offset = offset + entry.length;
                    realizer.realize_continue(
                        partial_subsystem,
                        i,
                        j,
                        &fill_blob[offset..next_offset],
                    )?;
                    offset = next_offset;
                }
            }
        }
    }
    Ok(())
}
