**What if a rope data structure used p-adic geometry? I built it to find out**

---

I was building a markdown editor for my platform [StringTechHub](https://stringtechhub.com). At some point I needed to decide how to represent the document internally. I could use a plain string, a gap buffer, or a standard rope. Instead I asked a different question: can number theory give us a better way to organize text than size-balanced trees?

This post is about what that means, what I built, what I measured, and what I learned.

---

THE PROBLEM WITH STANDARD APPROACHES

A plain string is simple but expensive. Every insert at position i requires shifting all characters after i — O(n) per edit. For a 30,000 character document that becomes noticeable.

A rope solves this by splitting the document into chunks stored in a binary tree. Insert and delete become O(log n) because you only touch the path from root to the affected leaf. Editors like VS Code and Xi use rope-based structures internally for this reason.

Standard ropes balance by size — keep subtree weights roughly equal, keep the tree shallow. The size-balancing heuristic is correct but blind. It knows nothing about what the text means. A paragraph and a code block of identical byte length are indistinguishable to a standard rope. I wanted the tree to know the difference.

---

WHAT P-ADIC NUMBERS ARE

The 2-adic valuation v₂(n) counts how many times 2 divides n:

v₂(8) = 3, because 8 = 2³

v₂(12) = 2, because 12 = 4 × 3

v₂(7) = 0, because 7 is odd

In the 2-adic metric, two numbers are close when their difference is highly divisible by 2. This is a different notion of proximity than the real number line — one based on arithmetic structure rather than magnitude.

The question: what happens when you use this arithmetic structure to decide which nodes in a rope tree should merge together?

---

THE CORE IDEA

In a standard rope, rebalancing collects all leaf nodes and rebuilds by splitting arrays in half — purely by position. In a p-adic rope, rebalancing collects all leaf nodes and rebuilds by greedily fusing chunks that fit well arithmetically — merging adjacent nodes whose combined size has the highest 2-adic valuation first.

If two adjacent leaves have sizes 174 and 46, their combined size is 220. v₂(220) = 2. If two other adjacent leaves have sizes 171 and 16, their combined size is 187. v₂(187) = 0. The first pair merges first.

The rebuild uses a max-heap ordered by merge score, so the highest valuation pairs always merge first. For p=2, the valuation is a single CPU instruction:

```rust
fn valuation(n: usize) -> usize {
    if n == 0 { return usize::MAX; }
    n.trailing_zeros() as usize
}
```

The result: a tree where subtrees reflect arithmetic affinity between block sizes — not just positional proximity. Certain subtrees become deeper or shallower depending on number-theoretic structure, not size alone.

---

WHAT I BUILT

The data structure has two node types. Internal nodes are lightweight — they store weight, total size, valuation, cached depth, and two child pointers. No content, no metadata. Leaf nodes are rich — they store raw text, a parsed block from the document parser, a dirty flag, and an AST cache.

```rust
pub struct InternalNode {
    pub weight: usize,
    pub total: usize,
    pub valuation: usize,
    pub depth: usize,
    pub left: Box<Node>,
    pub right: Box<Node>,
}

pub struct LeafNode {
    pub text: String,
    pub block: RefCell<Block>,
    pub dirty: Cell<bool>,
    pub ast_cache: RefCell<Option<Block>>,
}
```

Each leaf corresponds to exactly one semantic block. A heading is one leaf. A paragraph is one leaf. A code block including all indented lines is one leaf. Split operations snap to block boundaries — the rope never cuts mid-paragraph.

The depth cap guarantees O(log n) worst case: max_depth = 2.0 × log₂(total). After every concat, depth is checked. If it exceeds the cap, p-adic rebuild runs. If that still violates the cap, strict size-balanced fallback runs. The guarantee always holds.

---

THE SEMANTIC EVOLUTION

While building I noticed something: lists and paragraphs have fundamentally different natural groupings. A paragraph is continuous prose — binary splitting fits naturally. An unordered list is a collection of discrete items — ternary grouping fits better.

So I made the prime adaptive:

```rust
fn block_prime(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf) => match &leaf.block.borrow().kind {
            BlockKind::UnorderedList |
            BlockKind::OrderedList => 3,
            _ => 2,
        },
        Node::Internal(_) => 2,
    }
}

fn merge_score(left: &Node, right: &Node) -> usize {
    let total = left.total() + right.total();
    let p = block_prime(left).max(block_prime(right));
    valuation_p(total, p)
}
```

This is where the idea became more interesting: the prime is no longer fixed — it depends on the content. The math adapts to document structure. This is no longer purely p-adic. It is a mathematically inspired adaptive heuristic. I think that is more interesting than mathematical purity, and more honest than pretending the original idea was perfect.

---

THE CUSTOM DSL

The editor uses a command-based markup language. Every block starts with a dollar-sign command at column zero. Everything indented below belongs to the same block. A new block begins when a $ appears at column zero.

BLOCK COMMANDS

$H1 - heading text

$H2 - heading text

$H3 - heading text

$H4 - heading text

$P - paragraph text

$B - bold block

$I - italic block

$BI - bold italic block

$ST - strikethrough block

$HR

$BQ
    quote content here
    -- attribution
    
$CODE rust
    fn main() {
        println!("hello");
    }
    
$UL
    item one
    item two
    item three
    
$OL
    first item
    second item
    
$IMG - alt text | https://url.com/image.png

$LINK - label text | https://url.com

$FN - footnote content

$TOC

$TB
    | Header 1 | Header 2 | Header 3 |
    |----------|----------|----------|
    | cell     | cell     | cell     |
    | cell     | cell     | cell     |
    

Tables are scaffolded automatically. Type $TB and press Enter — the editor generates the header row, separator row, and data rows. Tab moves between cells, Shift+Tab moves back.

INLINE COMMANDS

Inline formatting uses quoted commands anywhere inside block content:

"$I - italic text"

"$B - bold text"

"$BI - bold italic"

"$ST - strikethrough"

"$I:ST - italic strikethrough"

"$B:ST - bold strikethrough"

"$BI:ST - bold italic strikethrough"

"$ICODE - inline code"

"$LINK - label | https://url.com"


ESCAPE

To write a literal dollar sign command without it being parsed:

!$B - this renders as plain text, not bold

To write literal quotes inside inline content:

"!!this has literal quotes inside"

The explicit $ prefix at column zero makes block boundary detection trivial and unambiguous. No context-sensitive parsing, no lookahead, no ambiguity. This is why the rope can snap splits to block boundaries cleanly — the boundary is always a $ at column zero.

---

WHAT THE MEASUREMENTS SHOWED

I built a baseline using standard size-balanced rebuild and ran both on the same document.

Size-balanced baseline:
depth 6, total internal nodes 27

valuation distribution: flat, stops at v₂=4

P-adic rope after operations:

depth 9-13, total internal nodes 1528
valuation distribution: geometric decay

v₂=0 → 594 nodes

v₂=1 → 505 nodes

v₂=2 → 240 nodes

v₂=3 → 114 nodes

v₂=4 →  49 nodes

v₂=5 →  19 nodes

v₂=6 →   5 nodes

v₂=7 →   2 nodes


The geometric decay is not accidental. In any distribution of natural numbers, roughly half are odd (v₂=0), a quarter divisible by 2 but not 4 (v₂=1), an eighth by 4 but not 8 (v₂=2), and so on. The histogram follows this pattern exactly — the p-adic rebuild is genuinely organizing nodes by number-theoretic properties. This suggests the structure is not arbitrary — it reflects inherent arithmetic distribution.

The size-balanced tree has no such structure. Its valuation distribution is flat and arbitrary.

Rebalance cost: 17µs for a real document.

1000 inserts: 46ms total, 0.046ms per insert.

I have not yet benchmarked against a production rope implementation like ropey. That is the honest next step. Whether p-adic balancing produces faster trees than size-balanced in real editor workloads is an open question. The tree shapes are measurably different. Whether different is better in practice I cannot yet claim.

---

THE EDITOR

The parser compiles to WASM via wasm-pack. The editor is a split-pane textarea with live preview. The rope sits between the parser and the renderer.

Each leaf caches its parsed block. Dirty flags mark which leaves need re-parsing after edits. Only dirty leaves get re-parsed on each update — re-parse cost is O(block size) not O(document size). For a 30,000 character document with a 200-character paragraph being edited, only those 200 characters get re-parsed.

Currently the textarea is the source of truth and the rope is rebuilt from it on each debounce. Making the rope the primary source of truth — intercepting every keystroke and updating incrementally — is the next step. The infrastructure is there. The wiring is not complete.

---

HONEST ASSESSMENT

What works:
- P-adic rebuild produces measurably different tree structure from size-balanced
- Geometric decay in valuation histogram is real and mathematically explainable
- Semantic block-prime scoring connects math to document structure
- Dirty flag incremental parsing is implemented and correct
- Depth cap guarantee holds under adversarial input
- 46ms for 1000 inserts on a real document
- Compiles to WASM, runs in browser, handles 30k character documents without lag

What does not work yet:
- Rope is not the source of truth — full rebuild on each debounce
- True incremental updates not wired end to end
- No undo/redo
- No benchmark against production rope implementations

---

WHAT I LEARNED

The most interesting discovery was not the math. It was that the prime should depend on the content type. The moment I realized lists have a natural ternary structure and paragraphs have a natural binary structure — the math stopped being a curiosity and started being a design tool.

The second thing: building something real with an idea is the only way to find out if the idea works. I could have written about p-adic ropes. Instead I built one and wired it into an editor. The measurements are more honest than the theory.

The open question: does p-adic balancing actually improve real editor workloads, or does it just produce different trees? I do not know yet. That is what makes it worth continuing.
