use alloc::prelude::v1::*;
use dyndl_types::*;
use crate::blueprint_of;

pub struct ModelView {
    pub local_objects: Vec<usize>, // sorted by size_bits and then by type
    pub extern_objects: Vec<usize>,
    pub reverse: Vec<usize>,
}

impl ModelView {

    pub fn new(model: &Model) -> Self {
        let mut view = Self {
            local_objects: vec![],
            extern_objects: vec![],
            reverse: vec![0; model.objects.len()],
        };

        for (i, obj) in model.objects.iter().enumerate() {

            match &obj.object {
                AnyObj::Local(_) => {
                    view.local_objects.push(i);
                }
                AnyObj::Extern(_) => {
                    view.reverse[i] = view.extern_objects.len();
                    view.extern_objects.push(i);
                }
            }

            view.local_objects.sort_by_key(|i| {
                let blueprint = blueprint_of(match &model.objects[*i].object {
                    AnyObj::Local(obj) => &obj,
                    _ => panic!(),
                });
                (blueprint.physical_size_bits(), blueprint)
            });

            for (i, j) in view.local_objects.iter().enumerate() {
                view.reverse[*j] = i;
            }
        }

        view
    }
}
