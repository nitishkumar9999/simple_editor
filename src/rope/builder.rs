use std::cell::{Cell, RefCell};

use crate::data::{Block, BlockKind, Align, BlockContent};
use crate::rope::{
    node::{Node, InternalNode, LeafNode, valuation, depth, line_count, leaf_count},
    cursor::count_chars,
};


// helpers

/// Normalise line endings and ensure every block-level `$CMD` starts on
/// its own line. Inline `"$CMD - ..."` spans inside quotes are left alone.
fn normalize_document(input: &str) -> String {
    let mut result       = String::with_capacity(input.len() + 64);
    let mut prev_newline = true;
    let mut in_quotes    = false;
    let mut chars        = input.chars().peekable();

    while let Some(ch) = chars.next() {
        match ch {
            '\r' => {
                if chars.peek() == Some(&'\n') { chars.next(); }
                result.push('\n');
                prev_newline = true;
                in_quotes    = false;
            }
            '\n' => {
                result.push('\n');
                prev_newline = true;
                in_quotes    = false;
            }
            '"' => {
                in_quotes = !in_quotes;
                result.push(ch);
                prev_newline = false;
            }
            '$' if !prev_newline && !in_quotes => {
                let next_is_upper = chars.peek()
                    .map(|c| c.is_uppercase())
                    .unwrap_or(false);

                // Don't break `!$CMD` escape sequences
                if next_is_upper && !result.ends_with('!') {
                    result.push('\n');
                }
                result.push(ch);
                prev_newline = false;
            }
            _ => {
                result.push(ch);
                prev_newline = false;
            }
        }
    }

    result
}


// Node constructors

/// An empty leaf — used as a neutral element for empty documents or
/// empty sides of a split.
pub fn new_leaf_empty() -> Box<Node> {
    Box::new(Node::Leaf(LeafNode {
        text:      String::new(),
        dirty:     Cell::new(false),
        block:     RefCell::new(Block {
            kind:    BlockKind::Paragraph,
            align:   Align::Left,
            content: BlockContent::Text(String::new()),
        }),
        ast_cache: RefCell::new(None),
    }))
}

/// A leaf node whose block type is determined by running `parser` on `text`.
pub fn new_leaf(text: String, parser: &dyn Fn(&str) -> Block) -> Box<Node> {
    let block = parser(&text);
    Box::new(Node::Leaf(LeafNode {
        text,
        block:     RefCell::new(block.clone()),
        dirty:     Cell::new(false),
        ast_cache: RefCell::new(Some(block)),
    }))
}

/// An internal node whose metadata is derived from its two children.
pub fn new_internal(left: Box<Node>, right: Box<Node>) -> Box<Node> {
    let total      = left.total() + right.total();
    let weight     = left.total();
    let d          = 1 + depth(&left).max(depth(&right));
    let lc         = line_count(&left)  + line_count(&right);
    let leafc      = leaf_count(&left)  + leaf_count(&right);
    let char_count = count_chars(&left) + count_chars(&right);

    Box::new(Node::Internal(InternalNode {
        weight,
        total,
        valuation:  valuation(total),
        depth:      d,
        line_count: lc,
        leaf_count: leafc,
        char_count,
        has_dirty:  false,
        left,
        right,
    }))
}


// Document builder

/// Build a rope from a raw DSL string. Each top-level block becomes one
/// leaf node; the leaves are then assembled by `balance::rebuild`.
pub fn build_rope_from_document(
    input:  &str,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let normalized = normalize_document(input);
    let input      = normalized.as_str();
    let blocks     = crate::document_parser::parse_document(input);

    if blocks.is_empty() {
        return new_leaf(String::new(), parser);
    }

    let raw_lines: Vec<&str>   = input.lines().collect();
    let mut line_idx            = 0;
    let mut leaves: Vec<Box<Node>> = Vec::with_capacity(blocks.len());

    for b in blocks {
        let start = line_idx;

        while line_idx < raw_lines.len() {
            let raw_line = raw_lines[line_idx];
            if line_idx > start
                && raw_line.starts_with('$')
                && !raw_line.starts_with("    ")
                && !raw_line.starts_with('\t')
            {
                break;
            }
            line_idx += 1;
        }

        let raw = raw_lines[start..line_idx].join("\n") + "\n";
        leaves.push(Box::new(Node::Leaf(LeafNode {
            text:      raw,
            dirty:     Cell::new(false),
            block:     RefCell::new(b.clone()),
            ast_cache: RefCell::new(Some(b)),
        })));
    }

    leaves.retain(|n| n.total() > 0);

    if leaves.is_empty() {
        return new_leaf(String::new(), parser);
    }

    crate::rope::balance::rebuild(leaves)
}
