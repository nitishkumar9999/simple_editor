use crate::rope::node::{Node, line_count};


// Public types

#[derive(Debug, Clone, Copy)]
pub struct CursorPos {
    pub byte_offset:  usize,
    pub line:         usize,
    pub col:          usize,
    pub block_index:  usize,
}


// Public API

/// Convert a byte offset in the rope to a (line, col, block_index) position.
pub fn offset_to_pos(root: &Node, offset: usize) -> CursorPos {
    let mut s = OffsetState {
        target_byte:    offset,
        consumed_bytes: 0,
        consumed_lines: 0,
        block_index:    0,
        found_line:     0,
        found_col:      0,
        found:          false,
    };
    walk_to_offset(root, &mut s);
    CursorPos {
        byte_offset:  offset,
        line:         s.found_line,
        col:          s.found_col,
        block_index:  s.block_index,
    }
}

/// Convert a (line, col) position to a byte offset. Returns None if the
/// line doesn't exist in the rope.
pub fn pos_to_offset(root: &Node, line: usize, col: usize) -> Option<usize> {
    let mut s = LineState {
        target_line:    line,
        target_col:     col,
        consumed_bytes: 0,
        consumed_lines: 0,
        result:         None,
    };
    walk_to_line(root, &mut s);
    s.result
}

/// Convert a char index (Unicode scalar count) to a byte offset.
/// Returns `root.total()` if char_index is past the end.
pub fn char_to_byte_offset(root: &Node, char_index: usize) -> usize {
    let mut s = CharWalkState {
        target_char:    char_index,
        consumed_chars: 0,
        consumed_bytes: 0,
        result:         None,
    };
    walk_char_to_byte(root, &mut s);
    s.result.unwrap_or_else(|| root.total())
}

/// Count the total number of Unicode scalar values in the subtree.
/// Internal nodes cache this; leaf nodes count on demand.
pub fn count_chars(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf)     => leaf.text.chars().count(),
        Node::Internal(n)    => n.char_count,
    }
}


// Private utilities

fn leaf_count(node: &Node) -> usize {
    match node {
        Node::Leaf(_)        => 1,
        Node::Internal(n)    => leaf_count(&n.left) + leaf_count(&n.right),
    }
}


// offset_to_pos internals

struct OffsetState {
    target_byte:    usize,
    consumed_bytes: usize,
    consumed_lines: usize,
    block_index:    usize,
    found_line:     usize,
    found_col:      usize,
    found:          bool,
}

fn walk_to_offset(node: &Node, s: &mut OffsetState) {
    if s.found { return; }

    match node {
        Node::Internal(n) => {
            let left_end = s.consumed_bytes + n.weight;
            if s.target_byte < left_end {
                walk_to_offset(&n.left, s);
            } else {
                s.consumed_bytes += n.weight;
                s.consumed_lines += line_count(&n.left);
                s.block_index    += leaf_count(&n.left);
                walk_to_offset(&n.right, s);
            }
        }

        Node::Leaf(leaf) => {
            let text  = &leaf.text;
            let local = s.target_byte - s.consumed_bytes;
            let mut line = s.consumed_lines;
            let mut col  = 0usize;

            for (i, ch) in text.char_indices() {
                if i == local {
                    s.found_line = line;
                    s.found_col  = col;
                    s.found      = true;
                    return;
                }
                if ch == '\n' { line += 1; col = 0; }
                else          { col += ch.len_utf8(); }
            }

            // offset is at or past end of this leaf
            if local >= text.len() {
                s.found_line = line;
                s.found_col  = col;
                s.found      = true;
            }
        }
    }
}


// pos_to_offset internals

struct LineState {
    target_line:    usize,
    target_col:     usize,
    consumed_bytes: usize,
    consumed_lines: usize,
    result:         Option<usize>,
}

fn walk_to_line(node: &Node, s: &mut LineState) {
    if s.result.is_some() { return; }

    match node {
        Node::Internal(n) => {
            let left_lines = line_count(&n.left);
            if s.target_line < s.consumed_lines + left_lines {
                walk_to_line(&n.left, s);
            } else {
                s.consumed_bytes += n.weight;
                s.consumed_lines += left_lines;
                walk_to_line(&n.right, s);
            }
        }

        Node::Leaf(leaf) => {
            let text         = &leaf.text;
            let mut cur_line = s.consumed_lines;
            let mut pos      = s.consumed_bytes;

            for (i, ch) in text.char_indices() {
                if cur_line == s.target_line {
                    let line_text    = &text[i..];
                    let mut col_bytes = 0usize;

                    for (j, c) in line_text.char_indices() {
                        if c == '\n' { break; }
                        if col_bytes == s.target_col {
                            s.result = Some(pos + i + j);
                            return;
                        }
                        col_bytes += c.len_utf8();
                    }

                    // col is past end of line — clamp to end
                    let end  = line_text.find('\n').unwrap_or(line_text.len());
                    s.result = Some(pos + i + end);
                    return;
                }
                if ch == '\n' { cur_line += 1; }
            }

            s.consumed_bytes += text.len();
            s.consumed_lines += line_count(node);
        }
    }
}


// char_to_byte_offset internals

struct CharWalkState {
    target_char:    usize,
    consumed_chars: usize,
    consumed_bytes: usize,
    result:         Option<usize>,
}

fn walk_char_to_byte(node: &Node, s: &mut CharWalkState) {
    if s.result.is_some() { return; }

    match node {
        Node::Internal(n) => {
            let left_chars = count_chars(&n.left);
            if s.target_char < s.consumed_chars + left_chars {
                walk_char_to_byte(&n.left, s);
            } else {
                s.consumed_chars += left_chars;
                s.consumed_bytes += n.weight;
                walk_char_to_byte(&n.right, s);
            }
        }

        Node::Leaf(leaf) => {
            for (byte_i, _) in leaf.text.char_indices() {
                if s.consumed_chars == s.target_char {
                    s.result = Some(s.consumed_bytes + byte_i);
                    return;
                }
                s.consumed_chars += 1;
            }
            s.consumed_bytes += leaf.text.len();
            s.consumed_chars += leaf.text.chars().count();
        }
    }
}
