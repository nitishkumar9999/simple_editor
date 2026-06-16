use crate::data::Block;
use crate::rope::{
    node::{Node, LeafNode, to_char_boundary},
    builder::{new_leaf, new_internal},
    balance::{rebalance, rebalance_if_needed, find_block_boundary},
};

pub fn find_leaf_at(node: &Node, pos: usize) -> Option<&LeafNode> {
    match node {
        Node::Leaf(leaf) => Some(leaf),
        Node::Internal(internal) => {
            if pos < internal.weight {
                find_leaf_at(&internal.left, pos)
            } else {
                find_leaf_at(&internal.right, pos - internal.weight)
            }
        }
    }
}

pub fn block_index_at(node: &Node, target: usize) -> usize {
    let mut count = 0;
    let mut pos = 0;
    walk_for_block(node, target, &mut pos, &mut count);
    count
}

fn walk_for_block(node: &Node, target: usize, pos: &mut usize, count: &mut usize) {
    match node {
        Node::Leaf(leaf) => {
            if target >= *pos && target < *pos + leaf.text.len() {
                return;
            }
            *pos += leaf.text.len();
            *count += 1;
        }
        Node::Internal(n) => {
            walk_for_block(&n.left, target, pos, count);
            walk_for_block(&n.right, target, pos, count);
        }
    }
}

pub fn index(node: &Node, i: usize) -> Option<char> {
    match node {
        Node::Leaf(leaf) => {
            let s = &leaf.text;
            let i = to_char_boundary(s, i);
            s[i..].chars().next()
        },
        Node::Internal(internal) => {
            if i < internal.weight {
                index(&internal.left, i)
            } else {
                index(&internal.right, i - internal.weight)
            }
        }
    }
}

pub fn rope_concat(
    left: Box<Node>,
    right: Box<Node>,
) -> Box<Node> {
    if left.total() == 0 { return right; }
    if right.total() == 0 { return left; }

    let node = new_internal(left, right);

    rebalance_if_needed(node)
}

pub fn split(
    node: Box<Node>,
    i: usize,
    parser: &dyn Fn(&str) -> Block,
) -> (Box<Node>, Box<Node>) {
    match *node {
        Node::Leaf(ref leaf) => {
            let lines: Vec<&str> = leaf.text.lines().collect();
            let mut char_count = 0;
            let mut line_idx = 0;
            for (idx, line) in lines.iter().enumerate() {
                let line_len = line.len() + 1;
                if char_count + line_len > i {
                    line_idx = idx;
                    break;
                }
                char_count += line_len;
                line_idx = idx + 1;
            }

            let boundary_line = find_block_boundary(&lines, line_idx);
            let boundary_char = to_char_boundary(
                &leaf.text,
                lines[..boundary_line]
                    .iter()
                    .map(|l| l.len() + 1)
                    .sum::<usize>()
                    .min(leaf.text.len()),
            );

            if boundary_char == 0 {
                return (new_leaf(String::new(), parser), node);
            }

            if boundary_char >= leaf.text.len() {
                return (node, new_leaf(String::new(), parser));
            }

            let left_text = leaf.text[..boundary_char].to_string();
            let right_text = leaf.text[boundary_char..].to_string();

            (
                new_leaf(left_text, parser),
                new_leaf(right_text, parser),
            )
        }

        Node::Internal(internal) => {
            if i == internal.weight {
                (internal.left, internal.right)
            } else if i < internal.weight {
                let (sl, sr) = split(internal.left, i, parser);
                (sl, rope_concat(sr, internal.right))
            } else {
                let (sl, sr) = split(
                    internal.right,
                    i - internal.weight,
                    parser,
                );
                (rope_concat(internal.left, sl), sr)
            }
        }
    }
}

pub fn split_exact (
    node: Box<Node>,
    i: usize,
    parser: &dyn Fn(&str) -> Block,
) -> (Box<Node>, Box<Node>) {
    match *node {
        Node::Leaf(ref leaf) => {
            let boundary = to_char_boundary(&leaf.text, i.min(leaf.text.len()));

            if boundary == 0 {
                return (new_leaf(String::new(), parser), node);
            }
            if boundary >= leaf.text.len() {
                return (node, new_leaf(String::new(), parser));
            }

            let left_text = leaf.text[..boundary].to_string();
            let right_text = leaf.text[boundary..].to_string();

            (
                new_leaf(left_text, parser),
                new_leaf(right_text, parser),
            )
        }
        Node::Internal(internal) => {
            if i == internal.weight {
                (internal.left, internal.right)
            } else if i < internal.weight {
                let (sl, sr) = split_exact(internal.left, i, parser);
                (sl, rope_concat(sr, internal.right))
            } else {
                let (sl, sr) = split_exact(
                    internal.right,
                    i - internal.weight,
                    parser,
                );
                (rope_concat(internal.left, sl), sr)
            }
        }
    }
}

pub fn insert(
    node: Box<Node>,
    i: usize,
    s: String,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let (left, right) = split_exact(node, i, parser);
    let middle = new_leaf(s, parser);
    rope_concat(rope_concat(left, middle), right)
}

pub fn delete(
    node: Box<Node>,
    i: usize,
    j: usize,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let (left, right) = split_exact(node, i, parser);
    let (_middle, right_remainder) = split_exact(right, j - i, parser);
    rope_concat(left, right_remainder)
}

pub fn collect_text(node: &Node) -> String {
    match node {
        Node::Leaf(leaf) => leaf.text.clone(),
        Node::Internal(n) => {
            let mut s = collect_text(&n.left);
            s.push_str(&collect_text(&n.right));
            s
        }
    }
}

fn save_document(
     rope: &Node,
     file_path: &str,
) {

    let text = collect_text(rope);

    std::fs::write(file_path, text).expect("failed to save");
}
pub fn substring(node: &Node, i: usize, j: usize) -> String {
    if i >= j { return String::new(); }
    match node {
        Node::Leaf(leaf) => {
            let start = to_char_boundary(&leaf.text, i.min(leaf.text.len()));
            let end = to_char_boundary(&leaf.text, j.min(leaf.text.len()));
            leaf.text[start..end].to_string()
        }
        Node::Internal(internal) => {
            if j <= internal.weight {
                substring(&internal.left, i, j)
            } else if i >= internal.weight {
                substring(&internal.right, i - internal.weight, j - internal.weight)
            } else {
                let left_part = substring(&internal.left, i, internal.weight);
                let right_part = substring(&internal.right, 0, j - internal.weight);
                left_part + &right_part
            }
        }
    }
}

pub fn line_at(node: &Node, n: usize) -> Option<String> {
    let mut target = n;
    line_at_inner(node, &mut target)
}

fn line_at_inner(node: &Node, remaining: &mut usize) -> Option<String> {
    match node {
        Node::Leaf(leaf) => {
            for line in leaf.text.lines() {
                if *remaining == 0 {
                    return Some(line.to_string());
                }
                *remaining -= 1;
            }
            None
        }
        Node::Internal(n) => {
            line_at_inner(&n.left, remaining)
                .or_else(|| line_at_inner(&n.right, remaining))
        }
    }
}

pub fn replace(
    node: Box<Node>,
    i: usize,
    j: usize,
    s: String,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let (left, rest)     = split_exact(node, i, parser);
    let (_mid, right)    = split_exact(rest,  j - i, parser);
    let middle           = new_leaf(s, parser);
    rope_concat(rope_concat(left, middle), right)
}

use std::cell::Ref;

pub struct BlockIter<'a> {
    stack: Vec<&'a Node>,
}

impl<'a> BlockIter<'a> {
    pub fn new(root: &'a Node) -> Self {
        BlockIter { stack: vec![root] }
    }
}

impl<'a> Iterator for BlockIter<'a> {
    type Item = Ref<'a, crate::data::Block>;

    fn next(&mut self) -> Option<Self::Item> {
        while let Some(node) = self.stack.pop() {
            match node {
                Node::Leaf(leaf) => return Some(leaf.block.borrow()),
                Node::Internal(n) => {
                    self.stack.push(&n.right);
                    self.stack.push(&n.left);
                }
            }
        }
        None
    }
}

pub fn iter_blocks(root: &Node) -> BlockIter<'_> {
    BlockIter::new(root)
}
