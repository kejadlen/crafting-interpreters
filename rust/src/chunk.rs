use std::fmt;

use crate::value::Value;

#[derive(Debug)]
pub enum OpCode {
    Constant(usize),
    Return,
}

#[derive(Debug)]
pub struct Instruction {
    op_code: OpCode,
    line: usize,
}

#[derive(Debug, Default)]
pub struct Chunk {
    pub code: Vec<Instruction>,
    pub constants: Vec<Value>,
}

impl Chunk {
    pub fn push(&mut self, op_code: OpCode, line: usize) {
        self.code.push(Instruction { op_code, line });
    }

    pub fn push_constant(&mut self, value: Value, line: usize) {
        self.constants.push(value);
        self.push(OpCode::Constant(self.constants.len() - 1), line)
    }

    pub fn disassemble(&self, name: &str) {
        println!("== {} ==\n{}", name, self);
    }
}

impl fmt::Display for Chunk {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let mut last_line: Option<usize> = None;

        for (i, instruction) in self.code.iter().enumerate() {
            write!(f, "{:04} ", i)?;
            if last_line == Some(instruction.line) {
                write!(f, "   | ")?;
            } else {
                write!(f, "{:>4} ", instruction.line)?;
            }
            last_line = Some(instruction.line);

            match instruction.op_code {
                OpCode::Constant(constant) => {
                    let value = self.constants[constant];
                    writeln!(f, "{:<16} {:4} '{}'", "OP_CONSTANT", constant, value)?;
                }
                OpCode::Return => writeln!(f, "OP_RETURN")?,
            }
        }

        Ok(())
    }
}
