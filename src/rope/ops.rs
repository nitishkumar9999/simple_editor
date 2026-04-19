use crate::data::Block;
use crate::rope::{
    node::Node,
    builder::{new_leaf, new_internal},
    balance::{rebalance, rebalance_if_needed, find_block_boundary},
};


pub fn index(node: &Node, i: usize) -> Option<char> {
    match node {
        Node::Leaf(leaf) => leaf.text.chars().nth(i),
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
            let boundary_char = lines[..boundary_line]
                .iter()
                .map(|l| l.len() + 1)
                .sum::<usize>()
                .min(leaf.text.len());

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
            let boundary_char = i.min(leaf.text.len());

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
