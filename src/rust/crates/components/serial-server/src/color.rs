use icecap_std::prelude::*;

pub struct Color(BaseColor, Style);

#[allow(dead_code)]
#[derive(Copy, Clone)]
pub enum BaseColor {
    Black = 0,
    Red = 1,
    Green = 2,
    Yellow = 3,
    Blue = 4,
    Magenta = 5,
    Cyan = 6,
    White = 7,
}

pub enum Style {
    Normal,
    Bold,
}

use BaseColor::*;
use Style::*;

impl Color {
    pub fn set(&self) {
        print!("\x1B[3{}", self.0 as i32);
        if let Bold = self.1 {
            print!(";1");
        }
        print!("m");
    }

    pub fn clear() {
        print!("\x1B[0m");
    }
}

pub const COLORS: [Color; 12] = [
    Color(Red, Normal),
    Color(Green, Normal),
    Color(Blue, Normal),
    Color(Magenta, Normal),
    Color(Yellow, Normal),
    Color(Cyan, Normal),
    Color(Red, Bold),
    Color(Green, Bold),
    Color(Blue, Bold),
    Color(Magenta, Bold),
    Color(Yellow, Bold),
    Color(Cyan, Bold),
];
