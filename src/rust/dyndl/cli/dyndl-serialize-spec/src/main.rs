use std::{
    env,
    io::{self, Read, Write, Seek},
    path::Path,
    fs::File,
};

use dyndl_types::*;

fn main() -> Result<(), io::Error> {
    let dir = env::args().nth(1).unwrap();
    let dir = Path::new(&dir);
    let mut model: Model = serde_json::from_reader(io::stdin())?;
    add_fill(&mut model, &dir)?;
    io::stdout().write_all(&pinecone::to_vec(&model).unwrap())?;
    Ok(())
}

fn add_fill(model: &mut Model, dir: &Path) -> Result<(), io::Error> {
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
                    entry.content = content;
                }
            }
        }
    }
    Ok(())
}
