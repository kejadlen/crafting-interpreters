use std::alloc::{self, Layout};
use std::marker::PhantomData;
use std::ops::Deref;
use std::ptr::{self, NonNull};

#[repr(u8)]
pub enum OpCode {
    Return,
}

pub struct Chunk {
    count: usize,
    capacity: usize,
    code: NonNull<OpCode>,
    _marker: PhantomData<OpCode>,
}

unsafe impl Send for Chunk {}
unsafe impl Sync for Chunk {}

impl Chunk {
    pub fn new() -> Self {
        Chunk {
            count: 0,
            capacity: 0,
            code: NonNull::dangling(),
            _marker: PhantomData,
        }
    }

    // https://doc.rust-lang.org/nomicon/vec/vec-push-pop.html
    pub fn write(&mut self, op_code: OpCode) {
        if self.count == self.capacity {
            self.grow();
        }

        unsafe {
            ptr::write(self.code.as_ptr().add(self.count), op_code);
        }

        // Can't fail, we'll OOM first.
        self.count += 1;
    }

    pub fn disassemble(&self, name: &str) {
        println!("== {} ==", name);

        let mut offset = 0;
        while offset < self.count {
            offset = self.disassemble_instruction(offset);
        }
    }

    fn disassemble_instruction(&self, offset: usize) -> usize {
        print!("{:04} ", offset);

        match self[offset] {
            OpCode::Return => self.simple_instruction("OP_RETURN", offset),
        }
    }

    fn simple_instruction(&self, name: &str, offset: usize) -> usize {
        println!("{}", name);
        offset + 1
    }

    // https://doc.rust-lang.org/nomicon/vec/vec-alloc.html
    fn grow(&mut self) {
        // Crafting Interpreters: GROW_CAPACITY
        let new_cap = if self.capacity < 8 {
            8
        } else {
            // This can't overflow since self.capacity <= isize::MAX.
            self.capacity * 2
        };

        // `Layout::array` checks that the number of bytes is <= usize::MAX,
        // but this is redundant since old_layout.size() <= isize::MAX,
        // so the `unwrap` should never fail.
        let new_layout = Layout::array::<u8>(new_cap).unwrap();

        // Ensure that the new allocation doesn't exceed `isize::MAX` bytes.
        assert!(
            new_layout.size() <= isize::MAX as usize,
            "Allocation too large"
        );

        // Crafting Interpreters: GROW_ARRAY / reallocate
        //   TODO: Handle shrinking maybe? We may need to
        //         extract these out if it's used elsewhere
        //         in the book
        let new_ptr = if self.capacity == 0 {
            unsafe { alloc::alloc(new_layout) }
        } else {
            let old_layout = Layout::array::<u8>(self.capacity).unwrap();
            let old_ptr = self.code.as_ptr() as *mut u8;
            unsafe { alloc::realloc(old_ptr, old_layout, new_layout.size()) }
        };

        // If allocation fails, `new_ptr` will be null, in which case we abort.
        self.code = match NonNull::new(new_ptr as *mut OpCode) {
            Some(p) => p,
            None => alloc::handle_alloc_error(new_layout),
        };
        self.capacity = new_cap;
    }

    // https://doc.rust-lang.org/nomicon/vec/vec-push-pop.html
    pub fn pop(&mut self) -> Option<OpCode> {
        if self.count == 0 {
            None
        } else {
            self.count -= 1;
            unsafe { Some(ptr::read(self.code.as_ptr().add(self.count))) }
        }
    }
}

impl Default for Chunk {
    fn default() -> Self {
        Self::new()
    }
}

// https://doc.rust-lang.org/nomicon/vec/vec-dealloc.html
impl Drop for Chunk {
    fn drop(&mut self) {
        if self.capacity != 0 {
            while self.pop().is_some() {}
            let layout = Layout::array::<u8>(self.capacity).unwrap();
            unsafe {
                alloc::dealloc(self.code.as_ptr() as *mut u8, layout);
            }
        }
    }
}

impl Deref for Chunk {
    type Target = [OpCode];
    fn deref(&self) -> &[OpCode] {
        unsafe { std::slice::from_raw_parts(self.code.as_ptr(), self.count) }
    }
}
