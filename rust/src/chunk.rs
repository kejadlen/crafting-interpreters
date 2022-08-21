use vec::Vec;

use crate::vec;

#[repr(u8)]
pub enum OpCode {
    Constant,
    Return,
}

type Value = f32;

#[derive(Default)]
pub struct Chunk {
    code: Vec<u8>,
    constants: Vec<Value>,
    lines: Lines,
}

impl Chunk {
    pub fn write(&mut self, byte: u8, line: usize) {
        self.code.push(byte);
        self.lines.add(line);
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

        let (line, is_first) = self.lines.get(offset);
        if is_first {
            print!("{:>4} ", line);
        } else {
            print!("   | ");
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

// Lines are stored using run-length encoding, where the first element is the line and the second
// element the number of instructions that are associated with that line
#[derive(Default, Debug)]
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

