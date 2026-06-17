use std::cmp::Ordering;
use std::collections::BinaryHeap;
use std::cell::{Cell, RefCell};

use crate::data::{Block, BlockKind, Align, BlockContent};
use crate::document_parser::parse_document;
use crate::rope::{
    node::{Node, LeafNode, valuation, depth, max_allowed_depth},
    builder::{new_internal, new_leaf_empty},
};


const COMPACT_THRESHOLD: usize = 16;

const REBUILD_INVARIANT: &str =
    "heap always has items while nodes.len() > 1 — \
     every merge pushes new candidates for its neighbours";


// Merge scoring 

fn block_prime(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf) => match &leaf.block.borrow().kind {
            BlockKind::UnorderedList | BlockKind::OrderedList => 3,
            _ => 2,
        },
        Node::Internal(_) => 2,
    }
}

fn valuation_p(n: usize, p: usize) -> usize {
    if n == 0 { return usize::MAX; }
    let mut count = 0;
    let mut n = n;
    while n % p == 0 {
        n /= p;
        count += 1;
    }
    count
}

fn merge_score(left: &Node, right: &Node) -> i64 {
    let total = left.total() + right.total();
    let p = block_prime(left).max(block_prime(right)) as i64;
    let val = valuation_p(total as usize, p as usize) as i64;

    let size_diff = (left.total() as i64 - right.total() as i64).abs();
    let penalty = if size_diff > 0 { (size_diff as f64).log2() as i64 } else { 0 };

    val - penalty
}


// MergeCandidate

#[derive(Eq)]
pub struct MergeCandidate {
    pub left:  usize,
    pub right: usize,
    pub score: i64,
}

impl Ord for MergeCandidate {
    fn cmp(&self, other: &Self) -> Ordering { self.score.cmp(&other.score) }
}

impl PartialOrd for MergeCandidate {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> { Some(self.cmp(other)) }
}

impl PartialEq for MergeCandidate {
    fn eq(&self, other: &Self) -> bool { self.score == other.score }
}


// Core tree operations

pub fn collect_leaves(node: Box<Node>) -> Vec<Box<Node>> {
    if node.is_leaf() {
        return vec![node];
    }
    match *node {
        Node::Internal(internal) => {
            let mut leaves = collect_leaves(internal.left);
            leaves.extend(collect_leaves(internal.right));
            leaves
        }
        Node::Leaf(_) => unreachable!("checked is_leaf() above"),
    }
}

pub fn rebuild(mut nodes: Vec<Box<Node>>) -> Box<Node> {
    if nodes.len() == 1 {
        return nodes.remove(0);
    }

    let mut heap = BinaryHeap::new();
    for i in 0..nodes.len().saturating_sub(1) {
        let score = merge_score(&nodes[i], &nodes[i + 1]);
        heap.push(MergeCandidate { left: i, right: i + 1, score });
    }

    while nodes.len() > 1 {
        let MergeCandidate { left, right, .. } = heap.pop()
            .expect(REBUILD_INVARIANT);

        // Stale candidate — indices have shifted since this was pushed
        if left >= nodes.len() - 1 || right != left + 1 {
            continue;
        }

        let right_node = nodes.remove(right);
        let left_node  = nodes.remove(left);
        let merged     = new_internal(left_node, right_node);
        nodes.insert(left, merged);

        if left > 0 {
            let score = merge_score(&nodes[left - 1], &nodes[left]);
            heap.push(MergeCandidate { left: left - 1, right: left, score });
        }
        if left < nodes.len() - 1 {
            let score = merge_score(&nodes[left], &nodes[left + 1]);
            heap.push(MergeCandidate { left, right: left + 1, score });
        }
    }

    nodes.remove(0)
}

pub fn strict_balance(mut leaves: Vec<Box<Node>>) -> Box<Node> {
    if leaves.len() == 1 {
        return leaves.remove(0);
    }
    let mid        = leaves.len() / 2;
    let right      = leaves.split_off(mid);
    let left_node  = strict_balance(leaves);
    let right_node = strict_balance(right);
    new_internal(left_node, right_node)
}


// Public rebalance API 

pub fn rebalance(node: Box<Node>) -> Box<Node> {
    rebalance_if_needed(node)
}

pub fn rebalance_if_needed(node: Box<Node>) -> Box<Node> {
    let d   = depth(&node);
    let cap = max_allowed_depth(node.total());

    let node = if should_compact(&node) { compact(node) } else { node };

    if d <= cap + 2 {
        return node;
    }

    let leaves: Vec<Box<Node>> = collect_leaves(node)
        .into_iter()
        .filter(|n| n.total() > 0)
        .collect();

    if leaves.is_empty() { return new_leaf_empty(); }
    if leaves.len() == 1 {
        return leaves.into_iter().next()
            .expect("just checked len == 1");
    }

    let result = rebuild(leaves);
    if depth(&result) <= cap {
        return result;
    }

    // Still too deep after rebuild — fall back to perfect binary split
    let leaves: Vec<Box<Node>> = collect_leaves(result)
        .into_iter()
        .filter(|n| n.total() > 0)
        .collect();

    strict_balance(leaves)
}


// Compaction

fn should_compact(node: &Node) -> bool {
    let (tiny, total) = count_tiny(node, 0, 0);
    total > 4 && tiny * 2 > total
}

fn count_tiny(node: &Node, tiny: usize, total: usize) -> (usize, usize) {
    match node {
        Node::Leaf(leaf) => {
            if leaf.text.len() < COMPACT_THRESHOLD {
                (tiny + 1, total + 1)
            } else {
                (tiny, total + 1)
            }
        }
        Node::Internal(n) => {
            let (t, total) = count_tiny(&n.left, tiny, total);
            count_tiny(&n.right, t, total)
        }
    }
}

/// Build a leaf node from accumulated text, parsing the block type from it.
fn make_compact_leaf(text: String) -> Box<Node> {
    let block = parse_document(&text)
        .into_iter()
        .next()
        .unwrap_or_else(|| Block {
            kind:    BlockKind::Paragraph,
            align:   Align::Left,
            content: BlockContent::Text(text.clone()),
        });

    Box::new(Node::Leaf(LeafNode {
        text,
        dirty:     Cell::new(false),
        block:     RefCell::new(block.clone()),
        ast_cache: RefCell::new(Some(block)),
    }))
}

pub fn compact(node: Box<Node>) -> Box<Node> {
    let leaves = collect_leaves(node);
    let mut merged: Vec<Box<Node>> = Vec::new();
    let mut acc = String::new();

    for leaf_node in leaves {
        if let Node::Leaf(ref leaf) = *leaf_node {
            if leaf.text.len() < COMPACT_THRESHOLD {
                acc.push_str(&leaf.text);
                continue;
            }
        }
        if !acc.is_empty() {
            merged.push(make_compact_leaf(std::mem::take(&mut acc)));
        }
        merged.push(leaf_node);
    }

    if !acc.is_empty() {
        merged.push(make_compact_leaf(acc));
    }

    if merged.is_empty() {
        return new_leaf_empty();
    }

    rebuild(merged)
}


// Utilities used by ops.rs

/// Walk backwards then forwards from `from` to find the nearest line that
/// starts a new DSL block (starts with `$`, not indented).
pub fn find_block_boundary(lines: &[&str], from: usize) -> usize {
    let mut i = from;
    while i > 0 {
        i -= 1;
        let line = lines[i];
        if !line.starts_with("    ") && line.starts_with('$') {
            return i;
        }
    }

    let mut i = from;
    while i < lines.len() {
        let line = lines[i];
        if !line.starts_with("    ") && line.starts_with('$') {
            return i;
        }
        i += 1;
    }

    lines.len()
}
