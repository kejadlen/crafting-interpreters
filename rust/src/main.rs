use chunk::{Chunk, OpCode};

pub mod chunk;

fn main() {
    let mut chunk = Chunk::default();
    chunk.write(OpCode::Return);

    chunk.disassemble("test chunk");
}
