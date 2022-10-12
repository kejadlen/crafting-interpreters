use chunk::{Chunk, OpCode};

mod chunk;
mod value;

fn main() {
    let mut chunk = Chunk::default();

    chunk.push_constant(1.2, 123);
    chunk.push(OpCode::Return, 123);

    chunk.disassemble("test chunk");
}
