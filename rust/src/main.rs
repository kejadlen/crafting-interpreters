use chunk::{Chunk, OpCode};

pub mod chunk;
pub mod vec;

fn main() {
    let mut chunk = Chunk::default();
    chunk.write(OpCode::Return as u8);

    let constant = chunk.add_constant(1.2);
    chunk.write(OpCode::Constant as u8);
    chunk.write(constant);

    chunk.disassemble("test chunk");
}
