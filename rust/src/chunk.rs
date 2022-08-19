#[repr(u8)]
pub enum OpCode {
    Return,
}

type Value = f32;

pub struct Chunk {
    code: Vec<OpCode>,
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
    pub fn write(&mut self, op_code: OpCode) {
        self.code.push(op_code);
    }

    pub fn add_constant(&mut self, value: Value) -> usize{
        self.constants.push(value);
        self.constants.len() - 1
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
            OpCode::Return => self.simple_instruction("OP_RETURN", offset),
        }
    }

    fn simple_instruction(&self, name: &str, offset: usize) -> usize {
        println!("{}", name);
        offset + 1
    }
}

impl Default for Chunk {
    fn default() -> Self {
        Self::new()
    }
}
