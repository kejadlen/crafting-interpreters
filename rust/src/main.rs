use chunk::{Chunk, OpCode};

pub mod chunk;
pub mod vec;

fn main() {
    let mut chunk = Chunk::default();

    let constant = chunk.add_constant(1.2);
    chunk.write(OpCode::Constant as u8, 123);
    chunk.write(constant, 123);

    chunk.write(OpCode::Return as u8, 123);

    chunk.disassemble("test chunk");
}
