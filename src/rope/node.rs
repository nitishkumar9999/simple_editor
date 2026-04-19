use std::cell::{Cell, RefCell};
use crate::data::Block;

pub const DEPTH_CONSTANT: f64 = 2.0;

pub struct InternalNode {
    pub weight: usize,        
    pub total: usize,         
    pub valuation: usize,     
    pub depth: usize,
    pub left: Box<Node>,
    pub right: Box<Node>,
}

pub struct LeafNode {
    pub text: String,
    pub block: RefCell<Block>,
    pub dirty: Cell<bool>,
    pub ast_cache: RefCell<Option<Block>>,
}

pub enum Node {
    Internal(InternalNode),
    Leaf(LeafNode),
}

impl Node {
    pub fn total(&self) -> usize {
        match self {
            Node::Internal(n) => n.total,
            Node::Leaf(n) => n.text.len(),
        }
    }

    pub fn weight(&self) -> usize {
        match self {
            Node::Internal(n) => n.weight,
            Node::Leaf(n) => n.text.len(),
        }
    }

    pub fn valuation(&self) -> usize {
        match self {
            Node::Internal(n) => n.valuation,
            Node::Leaf(n) => valuation(n.text.len()),
        }
    }

    pub fn is_leaf(&self) -> bool {
        matches!(self, Node::Leaf(_))
    }
}

pub fn valuation(n: usize) -> usize {
    if n == 0 { return usize::MAX; }
    n.trailing_zeros() as usize
}

pub fn depth(node: &Node) -> usize {
    match node {
        Node::Leaf(_) => 1,
        Node::Internal(n) => n.depth,
    }
}

pub fn max_allowed_depth(total: usize) -> usize {
    if total <= 1 { return 1; }
    (DEPTH_CONSTANT * (total as f64).log2()) as usize
}
