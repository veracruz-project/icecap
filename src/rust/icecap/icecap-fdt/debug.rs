use core::{cmp, fmt};

use crate::types::*;

const INDENT_WIDTH: usize = 4;

impl fmt::Display for DeviceTree {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        Formatter { f }.device_tree(self)
    }
}

impl fmt::Display for Node {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        Formatter { f }.node(self, 0)
    }
}

impl fmt::Display for Value {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        Formatter { f }.value(self, 0)
    }
}

struct Formatter<'a, 'b> {
    f: &'a mut fmt::Formatter<'b>,
}

impl<'a, 'b> Formatter<'a, 'b> {

    fn device_tree(&mut self, dt: &DeviceTree) -> fmt::Result {
        for ReserveEntry { address, size } in &dt.mem_rsvmap {
            writeln!(self.f, "/memreserve/ 0x{:x} 0x{:x}", address, size)?;
        }
        write!(self.f, "/ ")?;
        self.node(&dt.root, 0)?;
        Ok(())
    }

    fn node(&mut self, node: &Node, level: usize) -> fmt::Result {
        writeln!(self.f, "{{")?;
        for (k, v) in &node.properties {
            self.indent(level + 1)?;
            write!(self.f, "{}", k)?;
            if v.raw.len() > 0 {
                write!(self.f, " = ")?;
                self.value(v, level + 1)?;
            }
            writeln!(self.f, ";")?;
        }
        for (k, child) in &node.children {
            self.indent(level + 1)?;
            write!(self.f, "{} ", k)?;
            self.node(child, level + 1)?;
            writeln!(self.f)?;
        }
        self.indent(level)?;
        write!(self.f, "}}")?;
        Ok(())
    }

    fn value(&mut self, value: &Value, level: usize) -> fmt::Result {
        writeln!(self.f, "[")?;
        let char_width_hint = 100 - (level + 1) * INDENT_WIDTH;
        let width = cmp::max(8, (char_width_hint - 3) / 4);
        for (i, chunk) in value.raw.chunks(width).enumerate() {
            self.indent(level + 1)?;
            for b in chunk {
                write!(self.f, "{:02x} ", b)?;
            }
            if i > 0 {
                for _ in chunk.len()..width {
                    write!(self.f, "   ")?;
                }
            }
            write!(self.f, "// ")?;
            for &b in chunk {
                write!(self.f, "{}", pretty(b))?;
            }
            writeln!(self.f)?;
        }
        self.indent(level)?;
        write!(self.f, "]")?;
        Ok(())
    }

    fn indent(&mut self, level: usize) -> fmt::Result {
        for _ in 0 .. level * INDENT_WIDTH {
            write!(self.f, " ")?
        }
        Ok(())
    }
}

const UGLY: char = '.';

fn pretty(b: u8) -> char {
    if b.is_ascii() && !b.is_ascii_control() {
        b as char
    } else {
        UGLY
    }
}
