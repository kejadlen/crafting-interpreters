use std::mem;

use vec::Vec;

use crate::vec;

#[repr(u8)]
pub enum OpCode {
    Constant,
    LongConstant,
    Return,
}

type Value = f32;

#[derive(Default)]
pub struct Chunk {
    pub code: Vec<u8>,
    constants: Vec<Value>,
    lines: Lines,
}

impl Chunk {
    pub fn write(&mut self, byte: u8, line: usize) {
        self.code.push(byte);
        self.lines.add(line);
    }

    pub fn write_constant(&mut self, value: Value, line: usize) {
        self.constants.push(value);
        let index = self.constants.len() - 1;

        if let Ok(index) = index.try_into() {
            self.write(OpCode::Constant as u8, line);
            self.write(index, line);
        } else {
            self.write(OpCode::LongConstant as u8, line);
            for byte in index.to_ne_bytes() {
                self.write(byte, line);
            }
        }
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

        let (line, is_first) = self.lines.get(offset);
        if is_first {
            print!("{:>4} ", line);
        } else {
            print!("   | ");
        }

        match self.code[offset] {
            0 => self.constant_instruction("OP_CONSTANT", offset),
            1 => self.constant_long_instruction("OP_CONSTANT_LONG", offset),
            2 => self.simple_instruction("OP_RETURN", offset),
            _ => unreachable!(),
        }
    }

    fn simple_instruction(&self, name: &str, offset: usize) -> usize {
        println!("{}", name);
        offset + 1
    }

    fn constant_instruction(&self, name: &str, offset: usize) -> usize {
        let constant_index = self.code[offset + 1];
        let value = self.constants[constant_index as usize];
        println!("{:<16} {:>4} '{}'", name, constant_index, value);
        offset + 2
    }

    fn constant_long_instruction(&self, name: &str, offset: usize) -> usize {
        let index_len = mem::size_of::<usize>();
        let index_bytes = &self.code[offset + 1..offset + 1 + index_len];

        let (int_bytes, _) = index_bytes.split_at(std::mem::size_of::<usize>());
        let constant_index = usize::from_ne_bytes(int_bytes.try_into().unwrap());

        let value = self.constants[constant_index as usize];
        println!("{:<16} {:>4} '{}'", name, constant_index, value);
        offset + 1 + index_len
    }
}

#[test]
fn test_constant_long() {
    let mut chunk = Chunk::default();

    for i in 0..=u8::MAX {
        chunk.write_constant(i.into(), 123);
    }

    chunk.write_constant(0.0, 123);

    // TODO Make the disassembler testable
}

// Lines are stored using run-length encoding, where the first element is the line and the second
// element the number of instructions that are associated with that line
#[derive(Debug, Default)]
struct Lines(std::vec::Vec<(usize, usize)>);

impl Lines {
    fn add(&mut self, line: usize) {
        if let Some(last) = self.0.last_mut() {
            last.1 += 1;
        } else {
            self.0.push((line, 1));
        }
    }

    fn get(&self, offset: usize) -> (usize, bool) {
        let mut offset = offset;
        for (line, run) in self.0.iter() {
            if offset == 0 {
                return (*line, true);
            }

            if offset < *run {
                return (*line, false);
            }

            offset -= run;
        }

        unreachable!()
    }
}

#[test]
fn test_get_line() {
    let lines = Lines(vec![(1_usize, 2_usize), (2_usize, 2_usize)]);
    assert_eq!(lines.get(0), (1, true));
    assert_eq!(lines.get(1), (1, false));
    assert_eq!(lines.get(2), (2, true));
    assert_eq!(lines.get(3), (2, false));
}
