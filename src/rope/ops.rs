use crate::data::Block;
use crate::rope::{
    node::{Node, LeafNode, to_char_boundary},
    builder::{new_leaf, new_internal},
    balance::{rebalance_if_needed, find_block_boundary},
};


// Concatenation

/// Join two ropes, rebalancing if the result is too deep.
/// Returns the non-empty side directly when one side is empty.
pub fn rope_concat(left: Box<Node>, right: Box<Node>) -> Box<Node> {
    if left.total()  == 0 { return right; }
    if right.total() == 0 { return left; }
    rebalance_if_needed(new_internal(left, right))
}


// Split operations

/// Split at an exact byte offset, creating two new leaves at the cut point.
/// Used by insert, delete, and replace — does not respect block boundaries.
pub fn split_exact(
    node:   Box<Node>,
    i:      usize,
    parser: &dyn Fn(&str) -> Block,
) -> (Box<Node>, Box<Node>) {
    match *node {
        Node::Leaf(ref leaf) => {
            let boundary = to_char_boundary(&leaf.text, i.min(leaf.text.len()));

            if boundary == 0               { return (new_leaf(String::new(), parser), node); }
            if boundary >= leaf.text.len() { return (node, new_leaf(String::new(), parser)); }

            let left_text  = leaf.text[..boundary].to_string();
            let right_text = leaf.text[boundary..].to_string();
            (new_leaf(left_text, parser), new_leaf(right_text, parser))
        }

        Node::Internal(internal) => {
            if i == internal.weight {
                (internal.left, internal.right)
            } else if i < internal.weight {
                let (sl, sr) = split_exact(internal.left, i, parser);
                (sl, rope_concat(sr, internal.right))
            } else {
                let (sl, sr) = split_exact(internal.right, i - internal.weight, parser);
                (rope_concat(internal.left, sl), sr)
            }
        }
    }
}

/// Split at the nearest block boundary to byte offset `i`.
/// Prefers keeping DSL blocks intact rather than splitting mid-block.
pub fn split(
    node:   Box<Node>,
    i:      usize,
    parser: &dyn Fn(&str) -> Block,
) -> (Box<Node>, Box<Node>) {
    match *node {
        Node::Leaf(ref leaf) => {
            let lines: Vec<&str> = leaf.text.lines().collect();
            let mut char_count   = 0;
            let mut line_idx     = 0;

            for (idx, line) in lines.iter().enumerate() {
                let line_len = line.len() + 1;
                if char_count + line_len > i {
                    line_idx = idx;
                    break;
                }
                char_count += line_len;
                line_idx    = idx + 1;
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

            if boundary_char == 0               { return (new_leaf(String::new(), parser), node); }
            if boundary_char >= leaf.text.len() { return (node, new_leaf(String::new(), parser)); }

            let left_text  = leaf.text[..boundary_char].to_string();
            let right_text = leaf.text[boundary_char..].to_string();
            (new_leaf(left_text, parser), new_leaf(right_text, parser))
        }

        Node::Internal(internal) => {
            if i == internal.weight {
                (internal.left, internal.right)
            } else if i < internal.weight {
                let (sl, sr) = split(internal.left, i, parser);
                (sl, rope_concat(sr, internal.right))
            } else {
                let (sl, sr) = split(internal.right, i - internal.weight, parser);
                (rope_concat(internal.left, sl), sr)
            }
        }
    }
}


// Mutations

pub fn insert(
    node:   Box<Node>,
    i:      usize,
    s:      String,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let (left, right) = split_exact(node, i, parser);
    let middle        = new_leaf(s, parser);
    rope_concat(rope_concat(left, middle), right)
}

pub fn delete(
    node:   Box<Node>,
    i:      usize,
    j:      usize,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let (left, right)             = split_exact(node, i, parser);
    let (_deleted, right_remainder) = split_exact(right, j - i, parser);
    rope_concat(left, right_remainder)
}

pub fn replace(
    node:   Box<Node>,
    i:      usize,
    j:      usize,
    s:      String,
    parser: &dyn Fn(&str) -> Block,
) -> Box<Node> {
    let (left, rest)  = split_exact(node, i, parser);
    let (_mid, right) = split_exact(rest, j - i, parser);
    let middle        = new_leaf(s, parser);
    rope_concat(rope_concat(left, middle), right)
}


// Text extraction

/// Concatenate the text of every leaf in document order.
pub fn collect_text(node: &Node) -> String {
    match node {
        Node::Leaf(leaf)  => leaf.text.clone(),
        Node::Internal(n) => {
            let mut s = collect_text(&n.left);
            s.push_str(&collect_text(&n.right));
            s
        }
    }
}

/// Extract the bytes in the range `[i, j)`.
pub fn substring(node: &Node, i: usize, j: usize) -> String {
    if i >= j { return String::new(); }
    match node {
        Node::Leaf(leaf) => {
            let start = to_char_boundary(&leaf.text, i.min(leaf.text.len()));
            let end   = to_char_boundary(&leaf.text, j.min(leaf.text.len()));
            leaf.text[start..end].to_string()
        }
        Node::Internal(internal) => {
            if j <= internal.weight {
                substring(&internal.left, i, j)
            } else if i >= internal.weight {
                substring(&internal.right, i - internal.weight, j - internal.weight)
            } else {
                let left_part  = substring(&internal.left, i, internal.weight);
                let right_part = substring(&internal.right, 0, j - internal.weight);
                left_part + &right_part
            }
        }
    }
}

/// Return the text of the nth line (0-indexed), or None if out of range.
pub fn line_at(node: &Node, n: usize) -> Option<String> {
    let mut target = n;
    line_at_inner(node, &mut target)
}

fn line_at_inner(node: &Node, remaining: &mut usize) -> Option<String> {
    match node {
        Node::Leaf(leaf) => {
            for line in leaf.text.lines() {
                if *remaining == 0 { return Some(line.to_string()); }
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


// Navigation and search

/// Find the leaf node that covers byte offset `pos`.
pub fn find_leaf_at(node: &Node, pos: usize) -> Option<&LeafNode> {
    match node {
        Node::Leaf(leaf)     => Some(leaf),
        Node::Internal(n)    => {
            if pos < n.weight {
                find_leaf_at(&n.left, pos)
            } else {
                find_leaf_at(&n.right, pos - n.weight)
            }
        }
    }
}

/// Return the block index (0-based leaf ordinal) that contains byte offset `target`.
pub fn block_index_at(node: &Node, target: usize) -> usize {
    let mut count = 0;
    let mut pos   = 0;
    walk_for_block(node, target, &mut pos, &mut count);
    count
}

/// Walk the tree looking for the leaf covering `target`.
/// Returns `true` when found so callers can short-circuit — O(log n).
fn walk_for_block(node: &Node, target: usize, pos: &mut usize, count: &mut usize) -> bool {
    match node {
        Node::Leaf(leaf) => {
            if target >= *pos && target < *pos + leaf.text.len() {
                return true; // found — stop walking
            }
            *pos   += leaf.text.len();
            *count += 1;
            false
        }
        Node::Internal(n) => {
            if walk_for_block(&n.left,  target, pos, count) { return true; }
            walk_for_block(&n.right, target, pos, count)
        }
    }
}

/// Return the character at byte offset `i`, snapping to the nearest char boundary.
pub fn index(node: &Node, i: usize) -> Option<char> {
    match node {
        Node::Leaf(leaf)  => {
            let i = to_char_boundary(&leaf.text, i);
            leaf.text[i..].chars().next()
        }
        Node::Internal(n) => {
            if i < n.weight {
                index(&n.left, i)
            } else {
                index(&n.right, i - n.weight)
            }
        }
    }
}
