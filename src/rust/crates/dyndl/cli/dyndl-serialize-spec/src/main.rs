use std::{
    env,
    fs::File,
    io::{self, Read, Seek, Write},
    path::Path,
};

use dyndl_types::*;

fn main() -> Result<(), io::Error> {
    let dir = env::args().nth(1).unwrap();
    let dir = Path::new(&dir);
    let output: CapDLToolOutput = serde_json::from_reader(io::stdin())?;
    let objects = output.objects;
    let num_nodes = count_nodes(&objects); // HACK
    let mut model = Model { num_nodes, objects };
    let suffix = add_fill(&mut model, &dir)?;
    io::stdout().write_all(&postcard::to_allocvec(&model).unwrap())?;
    io::stdout().write_all(&suffix)?;
    Ok(())
}

fn add_fill(model: &mut Model, dir: &Path) -> Result<Vec<u8>, io::Error> {
    let mut suffix = vec![];
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
                    entry.content = vec![]; // TODO put digest here
                    suffix.extend(&content);
                }
            }
        }
    }
    Ok(suffix)
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
        .map_or(0, |affinity| affinity + 1)
}
