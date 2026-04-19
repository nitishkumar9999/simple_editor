use crate::data::Block;
use crate::rope::node::Node;

pub fn mark_dirty(node: &mut Node, i: usize) {
    match node {
        Node::Leaf(leaf) => {
            leaf.dirty.set(true);
            *leaf.ast_cache.borrow_mut() = None;
        }
        Node::Internal(internal) => {
            if i < internal.weight {
                mark_dirty(&mut internal.left, i);
            } else {
                mark_dirty(&mut internal.right, i - internal.weight);
            }
        }
    }
}

pub fn resolve_dirty(node: &mut Node, parser: &dyn Fn(&str) -> Block) {
    match node {
        Node::Leaf(leaf) => {
            if leaf.dirty.get() {
                let block = parser(&leaf.text);
                *leaf.ast_cache.borrow_mut() = Some(block.clone());
                *leaf.block.borrow_mut() = block;
                leaf.dirty.set(false);
            }
        }
        Node::Internal(internal) => {
            resolve_dirty(&mut internal.left, parser);
            resolve_dirty(&mut internal.right, parser);
        }
    }
}

pub fn count_dirty(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf) => if leaf.dirty.get() { 1 } else { 0 },
        Node::Internal(n) => count_dirty(&n.left) + count_dirty(&n.right),
    }
}
