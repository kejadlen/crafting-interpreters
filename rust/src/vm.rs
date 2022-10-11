use std::ptr;

use anyhow::Result;
use thiserror::Error;

use crate::chunk::Chunk;

pub struct VM {
    chunk: Chunk,
    ip: *const u8,
}

#[derive(Error, Debug)]
pub enum DataStoreError {
    #[error("")]
    CompileError,
    #[error("")]
    RuntimeError,
}

impl VM {
    pub fn new(chunk: Chunk) -> Self {
        VM { chunk, ip: &chunk.code.ptr }
    }

    pub fn interpret(&self) -> Result<()> {
        self.run()
    }

    fn run(&self) -> Result<()> {
        todo!()
    }
}
