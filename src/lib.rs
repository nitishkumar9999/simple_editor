use wasm_bindgen::prelude::*;

pub mod data;
pub mod error;
pub mod metadata_parser;
pub mod line_parser;
pub mod inline_parser;
pub mod document_parser;
pub mod rope;

use crate::data::{Block, BlockKind, Align, BlockContent, InlineFragment};
use crate::error::EditorError;
use crate::inline_parser::{parse_inline, Fragment};
use crate::document_parser::parse_document;
use crate::rope::{
    node::Node,
    builder::{build_rope_from_document, new_leaf_empty},
    ops::{insert, delete, replace, substring, collect_text, block_index_at},
    dirty::force_resolve,
    cursor::{offset_to_pos, pos_to_offset, char_to_byte_offset},
    history::{History, Op},
};


// Private helpers

fn make_parser_block(text: &str) -> Block {
    parse_document(text)
        .into_iter()
        .next()
        .unwrap_or_else(|| Block {
            kind: BlockKind::Paragraph,
            align: Align::Left,
            content: BlockContent::Text(text.to_string()),
        })
}

fn collect_blocks(node: &Node) -> Vec<Block> {
    parse_document(&collect_text(node))
}

fn debug_node(node: &Node) -> String {
    match node {
        Node::Leaf(leaf) => format!(
            "{{\"type\":\"leaf\",\"len\":{},\"text\":{}}}",
            leaf.text.len(),
            serde_json::to_string(&leaf.text).unwrap_or_default()
        ),
        Node::Internal(n) => format!(
            "{{\"type\":\"internal\",\"total\":{},\"depth\":{},\"left\":{},\"right\":{}}}",
            n.total,
            n.depth,
            debug_node(&n.left),
            debug_node(&n.right)
        ),
    }
}


// WASM initialisation

#[wasm_bindgen(start)]
pub fn main() {
    console_error_panic_hook::set_once();
}


// Parse a DSL string and return the blocks as JSON.
// Useful for one-shot parsing without creating an EditorRope.
#[wasm_bindgen]
pub fn parse_full_document(input: &str) -> String {
    serde_json::to_string(&parse_document(input))
        .unwrap_or_else(|_| "[]".to_string())
}

// Parse a single block from a DSL string.
#[wasm_bindgen]
pub fn parse_block(input: &str) -> String {
    serde_json::to_string(&parse_document(input))
        .unwrap_or_else(|_| "[]".to_string())
}

// Parse inline DSL spans into typed fragments (bold, italic, links, etc.)
// JS calls this to render inline content without re-implementing parsing.
#[wasm_bindgen]
pub fn parse_inline_fragments(text: &str) -> String {
    let fragments: Vec<InlineFragment> = parse_inline(text)
        .into_iter()
        .map(|f| match f {
            Fragment::Text(s)                              => InlineFragment::Text(s),
            Fragment::Styled(BlockKind::Bold, s)           => InlineFragment::Bold(s),
            Fragment::Styled(BlockKind::Italic, s)         => InlineFragment::Italic(s),
            Fragment::Styled(BlockKind::BoldItalic, s)     => InlineFragment::BoldItalic(s),
            Fragment::Styled(BlockKind::Strikethrough, s)  => InlineFragment::Strike(s),
            Fragment::Styled(BlockKind::ItalicStrike, s)   => InlineFragment::ItalicStrike(s),
            Fragment::Styled(BlockKind::BoldStrike, s)     => InlineFragment::BoldStrike(s),
            Fragment::Styled(BlockKind::InlineCode, s)     => InlineFragment::InlineCode(s),
            Fragment::Link { label, url }                  => InlineFragment::Link { label, url },
            Fragment::Styled(_, s)                         => InlineFragment::Text(s),
        })
        .collect();

    serde_json::to_string(&fragments)
        .unwrap_or_else(|_| "[]".to_string())
}

/// Generate a DSL table scaffold for $TB blocks.
#[wasm_bindgen]
pub fn build_table_scaffold(cols: usize, rows: usize) -> String {
    let headers: Vec<String> = (1..=cols).map(|i| format!("Header {}", i)).collect();
    let header_row = format!("    | {} |", headers.join(" | "));
    let sep        = format!("    |{}", "----------|".repeat(cols));
    let data_row   = format!("    | {} |", vec!["cell     "; cols].join("| "));

    let mut lines = vec![header_row, sep];
    lines.extend(std::iter::repeat(data_row).take(rows));
    lines.join("\n") + "\n"
}

/// Dump the rope tree as JSON for debugging.
#[wasm_bindgen]
pub fn debug_rope(input: &str) -> String {
    let rope = EditorRope::new(input);
    debug_node(
        rope.rope.as_ref()
            .expect("rope is always Some immediately after construction"),
    )
}


// EditorRope

const ROPE_INVARIANT: &str =
    "rope is always Some between public calls — None only during take/put";

#[wasm_bindgen]
pub struct EditorRope {
    rope: Option<Box<Node>>,
    history: History,
}

#[wasm_bindgen]
impl EditorRope {

    // Constructor

    #[wasm_bindgen(constructor)]
    pub fn new(input: &str) -> EditorRope {
        EditorRope {
            rope: Some(build_rope_from_document(input, &make_parser_block)),
            history: History::new(),
        }
    }

    // Writes

    pub fn insert(&mut self, byte_pos: usize, text: &str) -> Result<String, EditorError> {
        self.history.push(Op::Insert {
            byte_pos,
            text: text.to_string(),
        });
        let old = self.rope.take().expect(ROPE_INVARIANT);
        self.rope = Some(insert(old, byte_pos, text.to_string(), &make_parser_block));
        force_resolve(self.rope.as_mut().expect(ROPE_INVARIANT), &make_parser_block);
        self.blocks_json()
    }

    pub fn delete(&mut self, start: usize, end: usize) -> Result<String, EditorError> {
        let deleted = substring(self.rope.as_ref().expect(ROPE_INVARIANT), start, end);
        self.history.push(Op::Delete { byte_pos: start, text: deleted });
        let old = self.rope.take().expect(ROPE_INVARIANT);
        self.rope = Some(delete(old, start, end, &make_parser_block));
        force_resolve(self.rope.as_mut().expect(ROPE_INVARIANT), &make_parser_block);
        self.blocks_json()
    }

    pub fn replace_range(
        &mut self,
        start: usize,
        end: usize,
        new_text: &str,
    ) -> Result<String, EditorError> {
        let old_text = substring(self.rope.as_ref().expect(ROPE_INVARIANT), start, end);
        self.history.push(Op::Replace {
            byte_pos: start,
            old_text,
            new_text: new_text.to_string(),
        });
        let old = self.rope.take().expect(ROPE_INVARIANT);
        self.rope = Some(replace(old, start, end, new_text.to_string(), &make_parser_block));
        force_resolve(self.rope.as_mut().expect(ROPE_INVARIANT), &make_parser_block);
        self.blocks_json()
    }

    // History 

    pub fn undo(&mut self) -> Result<String, EditorError> {
        match self.history.undo() {
            None     => self.blocks_json(),
            Some(op) => self.apply_op(op),
        }
    }

    pub fn redo(&mut self) -> Result<String, EditorError> {
        match self.history.redo() {
            None     => self.blocks_json(),
            Some(op) => self.apply_op(op),
        }
    }

    pub fn can_undo(&self) -> bool { self.history.can_undo() }
    pub fn can_redo(&self) -> bool { self.history.can_redo() }

    // Reads

    pub fn get_all(&self) -> Result<String, EditorError> {
        self.blocks_json()
    }

    pub fn get_text(&self) -> String {
        collect_text(self.rope.as_ref().expect(ROPE_INVARIANT))
    }

    pub fn total(&self) -> usize {
        self.rope.as_ref().expect(ROPE_INVARIANT).total()
    }

    pub fn substring(&self, start: usize, end: usize) -> String {
        substring(self.rope.as_ref().expect(ROPE_INVARIANT), start, end)
    }

    pub fn block_index_at(&self, pos: usize) -> usize {
        block_index_at(self.rope.as_ref().expect(ROPE_INVARIANT), pos)
    }

    // Cursor

    pub fn cursor_pos(&self, byte_offset: usize) -> String {
        let pos = offset_to_pos(self.rope.as_ref().expect(ROPE_INVARIANT), byte_offset);
        format!(
            r#"{{"byte_offset":{},"line":{},"col":{},"block_index":{}}}"#,
            pos.byte_offset, pos.line, pos.col, pos.block_index
        )
    }

    pub fn offset_at(&self, line: usize, col: usize) -> i64 {
        match pos_to_offset(self.rope.as_ref().expect(ROPE_INVARIANT), line, col) {
            Some(o) => o as i64,
            None    => -1,
        }
    }

    pub fn offset_at_char(&self, char_index: usize) -> usize {
        char_to_byte_offset(self.rope.as_ref().expect(ROPE_INVARIANT), char_index)
    }

    pub fn compact(&mut self) {
        let old = self.rope.take().expect(ROPE_INVARIANT);
        self.rope = Some(crate::rope::balance::compact(old));
        force_resolve(self.rope.as_mut().expect(ROPE_INVARIANT), &make_parser_block);
    }

    // helpers 

    fn blocks_json(&self) -> Result<String, EditorError> {
        let rope = self.rope.as_ref().expect(ROPE_INVARIANT);
        serde_json::to_string(&collect_blocks(rope))
            .map_err(EditorError::Serialize)
    }

    fn apply_op(&mut self, op: Op) -> Result<String, EditorError> {
        let old = self.rope.take().expect(ROPE_INVARIANT);
        self.rope = Some(match op {
            Op::Insert { byte_pos, text } =>
                insert(old, byte_pos, text, &make_parser_block),
            Op::Delete { byte_pos, text } =>
                delete(old, byte_pos, byte_pos + text.len(), &make_parser_block),
            Op::Replace { byte_pos, old_text, new_text } =>
                replace(old, byte_pos, byte_pos + old_text.len(), new_text, &make_parser_block),
        });
        force_resolve(self.rope.as_mut().expect(ROPE_INVARIANT), &make_parser_block);
        self.blocks_json()
    }
}      
