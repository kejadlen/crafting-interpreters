use vec::Vec;

use crate::vec;

#[repr(u8)]
pub enum OpCode {
    Constant,
    Return,
}

type Value = f32;

pub struct Chunk {
    code: Vec<u8>,
    constants: Vec<Value>,
    lines: Vec<usize>,
}

impl Chunk {
    pub fn new() -> Self {
        Chunk {
            code: Vec::new(),
            constants: Vec::new(),
            lines: Vec::new(),
        }
    }

    pub fn write(&mut self, byte: u8, line: usize) {
        self.code.push(byte);
        self.lines.push(line);
    }

    pub fn add_constant(&mut self, value: Value) -> u8 {
        self.constants.push(value);

        assert!(self.constants.len() <= u8::MAX.into(), "Too many constants");

        (self.constants.len() - 1) as u8
    }

    pub fn disassemble(&self, name: &str) {
        println!("== {} ==", name);

        let mut offset = 0;
        while offset < self.code.len() {
            offset = self.disassemble_instruction(offset);
        }
    }

    fn disassemble_instruction(&self, offset: usize) -> usize {
        print!("{:04} ", offset);

        if offset > 0 && self.lines[offset] == self.lines[offset - 1] {
            print!("   | ");
        } else {
            print!("{:>4} ", self.lines[offset]);
        }

        match self.code[offset] {
            0 => self.constant_instruction("OP_CONSTANT", offset),
            1 => self.simple_instruction("OP_RETURN", offset),
            _ => unreachable!(),
        }
    }

    fn simple_instruction(&self, name: &str, offset: usize) -> usize {
        println!("{}", name);
        offset + 1
    }

    fn constant_instruction(&self, name: &str, offset: usize) -> usize {
        let constant_index = self.code[offset+1];
        let value = self.constants[constant_index as usize];
        println!("{:<16} {:>4} '{}'", name, constant_index, value);
        offset + 2
    }
}

impl Default for Chunk {
    fn default() -> Self {
        Self::new()
    }
}
