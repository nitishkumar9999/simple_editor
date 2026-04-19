use std::cell::{Cell, RefCell};
use crate::data::Block;
use crate::rope::node::{Node, InternalNode, LeafNode, valuation, depth};

pub fn new_leaf(
    text: String,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let block = parser(&text);
    Box::new(Node::Leaf(LeafNode {
        text,
        block: RefCell::new(block.clone()),
        dirty: Cell::new(false),
        ast_cache: RefCell::new(Some(block)),
    }))
}

pub fn new_internal(
    left: Box<Node>,
    right: Box<Node>,
) -> Box<Node> {
    let total = left.total() + right.total();
    let weight = left.total();
    let d = 1 + depth(&left).max(depth(&right));
    Box::new(Node::Internal(InternalNode {
        weight,
        total,
        valuation: valuation(total),
        depth: d,
        left,
        right,
    }))
}

pub fn build_rope_from_document(
    input: &str,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let blocks = crate::document_parser::parse_document(input);

    if blocks.is_empty() {
        return new_leaf(String::new(), parser);
    }

    let raw_lines: Vec<&str> = input.lines().collect();
    let mut line_idx = 0;

    let mut leaves: Vec<Box<Node>> = blocks
        .into_iter()
        .map(|b| {
            let start = line_idx;
            while line_idx < raw_lines.len() {
                let l = raw_lines[line_idx].trim();
                if line_idx > start
                    && l.starts_with('$')
                    && !l.starts_with("    ")
                {
                    break;
                }
                line_idx += 1;
            }
            let raw = raw_lines[start..line_idx].join("\n");

            Box::new(Node::Leaf(LeafNode {
                text: raw,
                dirty: Cell::new(false),
                block: RefCell::new(b.clone()),
                ast_cache: RefCell::new(Some(b)),
            }))
        })
        .collect();

    leaves.retain(|n| n.total() > 0);

    if leaves.is_empty() {
        return new_leaf(String::new(), parser);
    }

    crate::rope::balance::rebuild(leaves)
}
