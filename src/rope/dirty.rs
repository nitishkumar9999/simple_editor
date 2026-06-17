use crate::data::Block;
use crate::rope::node::Node;


// Public API

/// Re-parse every dirty leaf in the tree, updating its block and cache.
/// Skips entire subtrees where `has_dirty` is false.
/// This is the main entry point — callers should use this, not the internals.
pub fn force_resolve(node: &mut Node, parser: &dyn Fn(&str) -> Block) {
    resolve_dirty_targeted(node, parser);
}

/// Mark the leaf containing byte offset `i` as dirty.
/// Propagates `has_dirty = true` up the ancestor chain.
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
            internal.has_dirty = true;
        }
    }
}

/// Count the number of dirty leaves in the tree.
/// Useful for diagnostics and tests.
pub fn count_dirty(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf)  => usize::from(leaf.dirty.get()),
        Node::Internal(n) => count_dirty(&n.left) + count_dirty(&n.right),
    }
}


// Private implementation 

fn subtree_has_dirty(node: &Node) -> bool {
    match node {
        Node::Leaf(leaf)  => leaf.dirty.get(),
        Node::Internal(n) => n.has_dirty,
    }
}

fn resolve_dirty_targeted(node: &mut Node, parser: &dyn Fn(&str) -> Block) {
    if !subtree_has_dirty(node) { return; }

    match node {
        Node::Leaf(leaf) => {
            if leaf.dirty.get() {
                let block = parser(&leaf.text);
                *leaf.ast_cache.borrow_mut() = Some(block.clone());
                *leaf.block.borrow_mut()     = block;
                leaf.dirty.set(false);
            }
        }
        Node::Internal(internal) => {
            resolve_dirty_targeted(&mut internal.left,  parser);
            resolve_dirty_targeted(&mut internal.right, parser);
            internal.has_dirty = internal.left_has_dirty() || internal.right_has_dirty();
        }
    }
}
