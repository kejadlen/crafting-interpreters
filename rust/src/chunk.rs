#[repr(u8)]
pub enum OpCode {
    Constant,
    Return,
}

type Value = f32;

pub struct Chunk {
    code: Vec<u8>,
    constants: Vec<Value>,
}

impl Chunk {
    pub fn new() -> Self {
        Chunk {
            code: Vec::new(),
            constants: Vec::new(),
        }
    }

    // https://doc.rust-lang.org/nomicon/vec/vec-push-pop.html
    pub fn write(&mut self, byte: u8) {
        self.code.push(byte);
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
        println!("{:<16} {:04} '{}'", name, constant_index, value);
        offset + 2
    }
}

impl Default for Chunk {
    fn default() -> Self {
        Self::new()
    }
}
