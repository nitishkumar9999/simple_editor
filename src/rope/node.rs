use std::cell::{Cell, RefCell};
use crate::data::Block;


// Constants

/// The depth growth constant: max allowed depth = DEPTH_CONSTANT × log₂(total).
pub const DEPTH_CONSTANT: f64 = 2.0;


// Struct definitions

pub struct InternalNode {
    pub weight:     usize,   // byte length of the left subtree
    pub total:      usize,   // byte length of the entire subtree
    pub valuation:  usize,   // cached valuation(total)
    pub depth:      usize,   // height of this subtree
    pub line_count: usize,   // total '\n' count in subtree
    pub leaf_count: usize,   // number of leaves in subtree
    pub char_count: usize,   // total Unicode scalar count in subtree
    pub has_dirty:  bool,    // true if any descendant leaf is dirty
    pub left:       Box<Node>,
    pub right:      Box<Node>,
}

pub struct LeafNode {
    pub text:      String,
    pub block:     RefCell<Block>,
    pub dirty:     Cell<bool>,
    pub ast_cache: RefCell<Option<Block>>,
}

pub enum Node {
    Internal(InternalNode),
    Leaf(LeafNode),
}


// impl Node

impl Node {
    /// Total byte length of this subtree.
    pub fn total(&self) -> usize {
        match self {
            Node::Internal(n) => n.total,
            Node::Leaf(n)     => n.text.len(),
        }
    }

    /// Byte length of the left subtree (= total for leaves).
    pub fn weight(&self) -> usize {
        match self {
            Node::Internal(n) => n.weight,
            Node::Leaf(n)     => n.text.len(),
        }
    }

    pub fn is_leaf(&self) -> bool {
        matches!(self, Node::Leaf(_))
    }
}


// impl InternalNode

impl InternalNode {
    pub fn left_has_dirty(&self) -> bool {
        subtree_has_dirty(&self.left)
    }

    pub fn right_has_dirty(&self) -> bool {
        subtree_has_dirty(&self.right)
    }
}

// Private helper shared by left_has_dirty / right_has_dirty.
fn subtree_has_dirty(node: &Node) -> bool {
    match node {
        Node::Leaf(leaf)  => leaf.dirty.get(),
        Node::Internal(n) => n.has_dirty,
    }
}


// Free functions: math primitives

/// Number of trailing zero bits in `n` — used as a merge priority.
/// Returns `usize::MAX` for 0 (treat empty as infinitely valuable to merge).
pub fn valuation(n: usize) -> usize {
    if n == 0 { return usize::MAX; }
    n.trailing_zeros() as usize
}

/// Maximum tree depth allowed for a rope of `total` bytes before rebalancing.
pub fn max_allowed_depth(total: usize) -> usize {
    if total <= 1 { return 1; }
    (DEPTH_CONSTANT * (total as f64).log2()) as usize
}


// Free functions: tree structure queries

/// Height of the subtree rooted at `node`. Leaves have depth 1.
pub fn depth(node: &Node) -> usize {
    match node {
        Node::Leaf(_)     => 1,
        Node::Internal(n) => n.depth,
    }
}

/// Total number of `\n` bytes in the subtree (cached in internal nodes).
pub fn line_count(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf)  => leaf.text.bytes().filter(|&b| b == b'\n').count(),
        Node::Internal(n) => n.line_count,
    }
}

/// Number of leaf nodes in the subtree (cached in internal nodes).
pub fn leaf_count(node: &Node) -> usize {
    match node {
        Node::Leaf(_)     => 1,
        Node::Internal(n) => n.leaf_count,
    }
}


// Free functions: string utilities

/// Advance `i` forward until it lands on a UTF-8 character boundary.
/// Clamps to `s.len()` if `i` is at or past the end.
pub fn to_char_boundary(s: &str, mut i: usize) -> usize {
    if i >= s.len() { return s.len(); }
    while !s.is_char_boundary(i) { i += 1; }
    i
}
