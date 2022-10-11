use chunk::{Chunk, OpCode};
use vm::VM;

pub mod chunk;
pub mod vec;
pub mod vm;

fn main() {
    let mut chunk = Chunk::default();

    chunk.write_constant(1.2, 123);

    chunk.write(OpCode::Return as u8, 123);

    // for i in 0..=u8::MAX {
    //     chunk.write_constant(i.into(), 123);
    // }

    // chunk.write_constant(0.0, 123);

    // chunk.disassemble("test chunk");

    let vm = VM::new(chunk);
    vm.interpret();
}
