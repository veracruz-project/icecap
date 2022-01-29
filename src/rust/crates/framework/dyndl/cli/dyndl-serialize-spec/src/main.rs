use std::{
    env,
    fs::File,
    io::{self, Read, Seek, Write},
    path::Path,
};

use sha2::{Digest, Sha256};

use dyndl_types::*;

fn main() -> Result<(), io::Error> {
    let dir = env::args().nth(1).unwrap();
    let dir = Path::new(&dir);
    let capdl_tool_output: CapDLToolOutput = serde_json::from_reader(io::stdin())?;
    let objects = capdl_tool_output.objects;
    let num_nodes = count_nodes(&objects);
    let mut model = Model { num_nodes, objects };
    let fill_blob = add_fill(&mut model, &dir)?;
    io::stdout().write_all(&postcard::to_allocvec(&model).unwrap())?;
    io::stdout().write_all(&fill_blob)?;
    Ok(())
}

fn add_fill(model: &mut Model, dir: &Path) -> Result<Vec<u8>, io::Error> {
    let mut fill_blob = vec![];
    for obj in &mut model.objects {
        if let AnyObj::Local(obj) = &mut obj.object {
            if let Some(fill) = match obj {
                Obj::SmallPage(obj::SmallPage { fill }) => Some(fill),
                Obj::LargePage(obj::LargePage { fill }) => Some(fill),
                _ => None,
            } {
                for entry in fill {
                    let path = dir.join(&entry.file);
                    let mut f = File::open(path)?;
                    f.seek(io::SeekFrom::Start(entry.file_offset as u64))?;
                    let mut content = vec![0; entry.length];
                    f.read_exact(&mut content)?;
                    let digest = {
                        let mut hasher = Sha256::new();
                        hasher.update(&content);
                        hasher.finalize()
                    };
                    entry.content = digest.as_slice().to_vec();
                    fill_blob.extend(&content);
                }
            }
        }
    }
    Ok(fill_blob)
}

fn count_nodes(objects: &Objects) -> usize {
    objects
        .iter()
        .filter_map(|obj| {
            if let AnyObj::Local(Obj::TCB(obj::TCB { affinity, .. })) = &obj.object {
                Some(*affinity as usize)
            } else {
                None
            }
        })
        .max()
        .map_or(0, |max_affinity| max_affinity + 1)
}
