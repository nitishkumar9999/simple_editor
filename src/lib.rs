use wasm_bindgen::prelude::*;

pub mod data;
pub mod metadata_parser;
pub mod line_parser;
pub mod inline_parser;
pub mod document_parser;
pub mod rope;

use crate::document_parser::parse_document;
use crate::data::{Block, BlockKind, Align, BlockContent};
use crate::rope::{
    node::{Node, LeafNode},
    builder::build_rope_from_document,
    ops::{insert, delete, rope_concat, collect_text},
    dirty::{mark_dirty, resolve_dirty, count_dirty},
};

fn empty_node() -> Box<Node> {
    Box::new(Node::Leaf(LeafNode {
        text: String::new(),
        block: std::cell::RefCell::new(Block {
            kind: BlockKind::Paragraph,
            align: Align::Left,
            content: BlockContent::Text(String::new()),
        }),
        dirty: std::cell::Cell::new(false),
        ast_cache: std::cell::RefCell::new(None),
    }))
}

fn make_parser_block(text: &str) -> Block {
    parse_document(text)
        .into_iter()
        .next()
        .unwrap_or(Block {
            kind: BlockKind::Paragraph,
            align: Align::Left,
            content: BlockContent::Text(text.to_string()),
        })
}

#[wasm_bindgen]
pub fn debug_rope(input: &str) -> String {
    let rope = EditorRope::new(input);
    debug_node(&rope.rope.as_ref().unwrap())
}

fn debug_node(node: &Node) -> String {
    match node {
        Node::Leaf(leaf) => {
            format!(
                "{{\"type\":\"leaf\",\"len\":{},\"text\":{}}}",
                leaf.text.len(),
                serde_json::to_string(&leaf.text).unwrap_or_default()
            )
        }
        Node::Internal(n) => {
            format!(
                "{{\"type\":\"internal\",\"total\":{},\"v2\":{},\"left\":{},\"right\":{}}}",
                n.total,
                n.valuation,
                debug_node(&n.left),
                debug_node(&n.right)
            )
        }
    }
}

#[wasm_bindgen(start)]
pub fn main() {
    console_error_panic_hook::set_once();
}

#[wasm_bindgen]
pub fn parse_block(input: &str) -> String {
    let blocks = parse_document(input);
    serde_json::to_string(&blocks).unwrap_or_else(|_| "[]".to_string())
}

#[wasm_bindgen]
pub fn parse_full_document(input: &str) -> String {
    let blocks = parse_document(input);
    serde_json::to_string(&blocks).unwrap_or_else(|_| "[]".to_string())
}

#[wasm_bindgen]
pub struct EditorRope {
    rope: Option<Box<Node>>,
}

#[wasm_bindgen]
impl EditorRope {
    #[wasm_bindgen(constructor)]
    pub fn new(input: &str) -> EditorRope {
        EditorRope {
            rope: Some(build_rope_from_document(input, &make_parser_block)),
        }
    }

    pub fn insert(&mut self, pos: usize, text: &str) -> String {
        let old = self.rope.take().unwrap();
        self.rope = Some(insert(old, pos, text.to_string(), &make_parser_block));
        mark_dirty(self.rope.as_mut().unwrap(), pos);
        self.dirty_blocks_json()
    }

    pub fn delete(&mut self, start: usize, end: usize) -> String {
        let old = self.rope.take().unwrap();            
        self.rope = Some(delete(old, start, end, &make_parser_block));
        mark_dirty(self.rope.as_mut().unwrap(), start);
        self.dirty_blocks_json()
    }

    pub fn get_all(&self) -> String {
        let blocks = collect_blocks(self.rope.as_ref().unwrap());
        serde_json::to_string(&blocks).unwrap_or_else(|_| "[]".to_string())
    }

    pub fn get_text(&self) -> String {
        collect_text(self.rope.as_ref().unwrap())
    }
   
    fn dirty_blocks_json(&mut self) -> String {
        resolve_dirty(self.rope.as_mut().unwrap(), &make_parser_block);

        let blocks = collect_blocks(self.rope.as_ref().unwrap());
        serde_json::to_string(&blocks).unwrap_or_else(|_| "[]".to_string())
    }
}

fn collect_blocks(node: &Node) -> Vec<Block> {
    match node {
        Node::Leaf(leaf) => {
            vec![leaf.block.borrow().clone()]
        }
        Node::Internal(n) => {
            let mut blocks = collect_blocks(&n.left);
            blocks.extend(collect_blocks(&n.right));
            blocks
        }
    }
}
