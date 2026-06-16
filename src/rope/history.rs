#[derive(Clone, Debug)]
pub enum Op {
    Insert {
        byte_pos: usize,
        text: String,
    },
    Delete {
        byte_pos: usize,
        text: String,
    },
    Replace {
        byte_pos: usize,
        old_text: String,
        new_text: String,
    },
}

impl Op {
    pub fn invert(&self) -> Op {
        match self {
            Op::Insert { byte_pos, text } => Op::Delete {
                byte_pos: *byte_pos,
                text: text.clone(),
            },
            Op::Delete { byte_pos, text } => Op::Insert {
                byte_pos: *byte_pos,
                text: text.clone(),
            },
            Op::Replace { byte_pos, old_text, new_text } => Op::Replace {
                byte_pos: *byte_pos,
                old_text: new_text.clone(),
                new_text: old_text.clone(),
            },
        }
    }
}

pub struct History {
    undo_stack: Vec<Op>,
    redo_stack: Vec<Op>,
    max_size: usize,
}

impl History {
    pub fn new() -> Self {
        History {
            undo_stack: Vec::new(),
            redo_stack: Vec::new(),
            max_size: 1000,
        }
    }

    pub fn push(&mut self, op: Op) {
        self.redo_stack.clear();
        self.undo_stack.push(op);
        if self.undo_stack.len() > self.max_size {
            self.undo_stack.remove(0);
        }
    }

    pub fn undo(&mut self) -> Option<Op> {
        let op = self.undo_stack.pop()?;
        let inverse = op.invert();
        self.redo_stack.push(op);
        Some(inverse)
    }

    pub fn redo(&mut self) -> Option<Op> {
        let op = self.redo_stack.pop()?;
        let inverse = op.invert();
        self.undo_stack.push(op);
        Some(inverse)
    }

    pub fn can_undo(&self) -> bool { !self.undo_stack.is_empty() }
    pub fn can_redo(&self) -> bool { !self.redo_stack.is_empty() }
}



