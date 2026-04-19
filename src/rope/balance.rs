use std::cmp::Ordering;
use std::collections::BinaryHeap;
use crate::data::{Block, BlockKind};
use crate::rope::{
    node::
    {
        Node, valuation, depth, max_allowed_depth, LeafNode
    },
    builder::new_internal,
};


fn block_prime(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf) => {
            match &leaf.block.borrow().kind {
                BlockKind::UnorderedList |
                BlockKind::OrderedList => 3,
                _ => 2,
            }
        }
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

fn merge_score(left: &Node, right: &Node) -> usize {
    let total = left.total() + right.total();
    let p = block_prime(left).max(block_prime(right));
    valuation_p(total, p)
}


#[derive(Eq)]
pub struct MergeCandidate {
    pub left: usize,
    pub right: usize,
    pub score: usize,
}

impl Ord for MergeCandidate {
    fn cmp(&self, other: &Self) -> Ordering {
        self.score.cmp(&other.score)
    }
}

impl PartialOrd for MergeCandidate {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl PartialEq for MergeCandidate {
    fn eq(&self, other: &Self) -> bool {
        self.score == other.score
    }
}


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
        Node::Leaf(_) => unreachable!(),
    }
}


pub fn rebuild(
    mut nodes: Vec<Box<Node>>,
) -> Box<Node> {
    if nodes.len() == 1 {
        return nodes.remove(0);
    }

    let mut heap = BinaryHeap::new();

    for i in 0..nodes.len().saturating_sub(1) {
        let score = merge_score(&nodes[i], &nodes[i + 1]);
        heap.push(MergeCandidate { left: i, right: i + 1, score });
    }

    while nodes.len() > 1 {
        let MergeCandidate { left, right, .. } = heap.pop().unwrap();

        if left >= nodes.len() - 1 || right != left + 1 {
            continue;
        }

        let right_node = nodes.remove(right);
        let left_node = nodes.remove(left);

        let merged = new_internal(left_node, right_node);
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


pub fn strict_balance(
    mut leaves: Vec<Box<Node>>,
) -> Box<Node> {
    if leaves.len() == 1 {
        return leaves.remove(0);
    }
    let mid = leaves.len() / 2;
    let right = leaves.split_off(mid);
    let left_node = strict_balance(leaves);
    let right_node = strict_balance(right);
    new_internal(left_node, right_node)
}


pub fn rebalance(
    node: Box<Node>,
) -> Box<Node> {
    rebalance_if_needed(node)
}

pub fn rebalance_if_needed(
    node: Box<Node>,
) -> Box<Node> {
    let d = depth(&node);
    let cap = max_allowed_depth(node.total());

    if d > cap + 2 {
        let leaves = collect_leaves(node);
        let result = rebuild(leaves);

        if depth(&result) > cap {
            let leaves = collect_leaves(result);
            return strict_balance(leaves);
        }
        result
    } else {
        node
    }
}


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
