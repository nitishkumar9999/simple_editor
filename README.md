# Vadic — A P-Adic Valuation Rope for a Command-Prefixed DSL Document Editor

---

## 1. Overview

**Vadic** is a structured document editor built on a p-adic valuation rope — a binary tree of text chunks where merge priority is determined by the p-adic valuation of the merged block size, weighted by block type. It is implemented in Rust and compiled to WebAssembly. Documents are written in a command-prefixed DSL where block-level constructs begin with a `$CMD` on their own line and inline formatting lives inside `"$CMD - content"` spans. The entire document model — parsing, rope operations, dirty-flag propagation, cursor arithmetic, undo history — lives in Rust. JavaScript handles only the DOM.

---

## 2. The DSL

I use EndeavourOS. Most of my workflow is command-based, and I have always found that way of working faster and more natural than reaching for a mouse or remembering which button does what. When I started writing longer documents I kept running into the same frustration with markdown — I had to stop and think about the syntax. Is it `**` or `*` for bold? Does this list need a blank line before it? Does this heading need a space after the hash? Every one of those moments breaks the flow of writing.

I also did not like editors that put formatting buttons at the top. You write something, then move your hand to click bold, then come back and find your cursor. That friction adds up.

So I designed a syntax around commands, because commands are what I know. Every block starts with `$CMD`. You type it and keep going. There is no ambiguity — a block command starts a line, an inline command lives inside quotes. That is the entire rule. You learn it once and you never think about it again.

The other thing I wanted was for the document to be readable in the editor while you type it — not just in the preview. With command prefixes, every line tells you what it is. `$H2 - Title` is obviously a heading. `$BQ` followed by indented lines is obviously a block quote. You do not need the preview to understand what you are writing.

### Block commands

| Command | Output |
|---|---|
| `$H1` – `$H4` | Headings level 1 through 4 |
| `$P` | Paragraph |
| `$B` | Bold paragraph |
| `$I` | Italic paragraph |
| `$BI` | Bold italic paragraph |
| `$ST` | Strikethrough paragraph |
| `$BQ` | Block quote |
| `$CODE - lang` | Code block with language tag |
| `$UL` | Unordered list |
| `$OL` | Ordered list |
| `$TB` | Table |
| `$HR` | Horizontal rule |
| `$TOC` | Table of contents, auto-generated from headings |
| `$FN` | Footnote reference |
| `$ICODE` | Inline code block |
| `$LINK - label \| url` | Standalone link |
| `$IMG - alt \| src` | Image |

Block commands that take a body use indentation. Anything indented four spaces or a tab under a command belongs to that command:

```
$BQ
    The most dangerous kind of waste is the waste we do not recognize.
    -- Shigeo Shingo

$UL
    First item
    Second item
    Third item

$CODE - rust
    fn main() {
        println!("Hello, Vadic");
    }
```

Block quotes support an optional `--` attribution line. `$TOC` auto-generates from all headings — just place it where you want it and it builds itself.

### Alignment

Any block command accepts a colon modifier:

```
$P:C - This paragraph is centered
$H2:R - This heading is right aligned
```

`:C` for center, `:R` for right. Default is left.

### Tables

Tables use `$TB` with indented pipe-delimited rows. First row is the header, second is the separator, rest are data:

```
$TB
    | Name        | Role       | Status   |
    |-------------|------------|----------|
    | Ada         | Architect  | Active   |
    | Alan        | Theorist   | Active   |
```

Typing `$TB 4|5` and pressing Enter scaffolds a 4-column, 5-row table automatically. Tab moves between cells, Shift+Tab goes backwards. The separator row is skipped during navigation.

### Inline formatting

Inline commands live inside double quotes following the pattern `"$CMD - content"`:

| Syntax | Output |
|---|---|
| `"$B - text"` | **text** |
| `"$I - text"` | *text* |
| `"$BI - text"` | ***text*** |
| `"$ST - text"` | ~~text~~ |
| `"$I:ST - text"` | *~~text~~* |
| `"$B:ST - text"` | **~~text~~** |
| `"$BI:ST - text"` | ***~~text~~*** |
| `"$ICODE - text"` | `text` |
| `"$LINK - label \| url"` | [label](url) |

A paragraph with inline formatting:

```
$P - Vadic is written in "$B - Rust" and compiled to "$ICODE - .wasm".
The source is at "$LINK - github | https://github.com/nitishkumar9999/vadic".
```

### Escaping

Prefix any command with `!` to output it literally. `!$P - text` renders as the plain string `$P - text` instead of a paragraph block.

---

## 3. The Data Model

Every document in Vadic is a sequence of `Block` values. A `Block` is the atomic unit of the document model — one parsed DSL block, fully typed, with no reference to the raw text it came from.

```rust
pub struct Block {
    pub kind:    BlockKind,
    pub align:   Align,
    pub content: BlockContent,
}

pub enum Align {
    Left,
    Center,
    Right,
}
```

`BlockKind` carries the full set of block types. Variants that need extra data carry it directly:

```rust
pub enum BlockKind {
    Heading(u8),
    Paragraph,
    Bold,
    Italic,
    BoldItalic,
    Strikethrough,
    ItalicStrike,
    BoldStrike,
    BoldItalicStrike,
    BlockQuote { attribution: Option<String> },
    Code(String),
    InlineCode,
    UnorderedList,
    OrderedList,
    Table,
    TableOfContents,
    HorizontalRule,
    Footnote,
    Image { alt: String, src: String },
    Link  { label: String, url: String },
}
```

`BlockContent` carries the body. A block contains flat text, a list of items, or a grid of rows:

```rust
pub enum BlockContent {
    Text(String),
    Items(Vec<String>),
    Rows(Vec<Vec<String>>),
}
```

There are no nested blocks, no recursive content trees, no inline AST nodes inside `BlockContent`. Inline formatting is carried as raw DSL text inside `BlockContent::Text` and resolved at render time by the inline parser. The document model stays flat intentionally — it keeps the parser simple and the data predictable.

### A concrete parse

Take this block:

```
$BQ
    The most dangerous kind of waste is the waste we do not recognize.
    -- Shigeo Shingo
```

The parser produces exactly one `Block`:

```rust
Block {
    kind: BlockKind::BlockQuote {
        attribution: Some("Shigeo Shingo".to_string()),
    },
    align:   Align::Left,
    content: BlockContent::Text(
        "The most dangerous kind of waste is the waste we do not recognize.".to_string()
    ),
}
```

The attribution is lifted out of the body and stored in the `kind` variant. The body is stored flat. The render layer just reads `kind.attribution` and `content` — it does no parsing of its own.

### Inline fragments

The inline parser runs on `BlockContent::Text` strings and produces a flat list of typed fragments:

```rust
pub enum InlineFragment {
    Text(String),
    Bold(String),
    Italic(String),
    BoldItalic(String),
    Strike(String),
    ItalicStrike(String),
    BoldStrike(String),
    BoldItalicStrike(String),
    InlineCode(String),
    Link { label: String, url: String },
}
```

Given this text:

```
Vadic is written in "$B - Rust" and compiled to "$ICODE - .wasm".
```

The inline parser produces:

```rust
[
    InlineFragment::Text("Vadic is written in ".to_string()),
    InlineFragment::Bold("Rust".to_string()),
    InlineFragment::Text(" and compiled to ".to_string()),
    InlineFragment::InlineCode(".wasm".to_string()),
    InlineFragment::Text(".".to_string()),
]
```

This gets serialised to JSON at the WASM boundary and handed to the JavaScript render layer, which maps each variant to a DOM element. The render layer has no parsing logic at all.

### What the model does not do

`Block` has no reference to line numbers, byte offsets, or position in the document. It does not know where it came from in the source text. Position is the rope's concern. Keeping these two things separate is the decision that everything else in Vadic's architecture follows from.

---

## 4. The Rope

### P-adic numbers in one paragraph

In number theory, the p-adic valuation of an integer n with respect to a prime p — written νₚ(n) — is the largest exponent k such that pᵏ divides n. The 2-adic valuation of 12 is 2, because 2² divides 12 but 2³ does not. The 3-adic valuation of 27 is 3, because 3³ divides 27 exactly. Numbers with high p-adic valuation are, in a precise sense, highly structured with respect to p. This property, applied to the sizes of merged text chunks, drives Vadic's balancing strategy.

### Why I built a custom rope

Honestly, the main reason I built the rope was because I wanted to build a data structure from scratch. That was the goal. The DSL came first — I built the parser and the editor before any of the rope code existed. Then when I looked at what kind of data structure would fit this problem well, p-adic valuation came up and it matched what I needed. So I went with it.

A standard string pays O(n) on every insert and delete. A gap buffer helps for local edits but gets slow for non-local ones. A rope — a binary tree of text chunks — gives O(log n) insert, delete, split, and concat regardless of where in the document the edit lands. For a document with large code blocks, long block quotes, and multi-item lists, that matters.

### Node structure

Every node is either a leaf or an internal node:

```rust
pub struct LeafNode {
    pub text:      String,
    pub block:     RefCell<Block>,
    pub dirty:     Cell<bool>,
    pub ast_cache: RefCell<Option<Block>>,
}

pub struct InternalNode {
    pub weight:     usize,   // byte length of left subtree
    pub total:      usize,   // byte length of entire subtree
    pub valuation:  usize,   // cached valuation(total)
    pub depth:      usize,
    pub line_count: usize,
    pub char_count: usize,
    pub leaf_count: usize,
    pub has_dirty:  bool,
    pub left:       Box<Node>,
    pub right:      Box<Node>,
}
```

Each leaf holds a raw text chunk — the literal DSL bytes for one block — alongside a cached `Block` and a dirty flag. Internal nodes cache aggregate metadata. These caches are what make O(log n) cursor arithmetic possible without walking the entire tree on every keypress.

### The dirty flag system

Reparsing the whole document on every keystroke would be too slow. Vadic uses a lazy dirty-flag system instead. When a leaf's text changes, its `dirty` flag is set. The `has_dirty` field on every ancestor internal node is also set. On the next render call, `force_resolve` walks the tree and skips any subtree where `has_dirty` is `false` — only the affected leaves get reparsed:

```rust
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
            internal.has_dirty =
                internal.left_has_dirty() || internal.right_has_dirty();
        }
    }
}
```

### The p-adic merge scoring

When the rope rebalances, it does not use a simple midpoint split. Adjacent leaf pairs are scored and merged in priority order using a max-heap. The score is determined by the p-adic valuation of their combined size, where the prime p is chosen based on block type:

```rust
fn block_prime(node: &Node) -> usize {
    match node {
        Node::Leaf(leaf) => match &leaf.block.borrow().kind {
            BlockKind::UnorderedList |
            BlockKind::OrderedList   => 3,
            _                        => 2,
        },
        Node::Internal(_) => 2,
    }
}

fn merge_score(left: &Node, right: &Node) -> i64 {
    let total = left.total() + right.total();
    let p     = block_prime(left).max(block_prime(right)) as i64;
    let val   = valuation_p(total as usize, p as usize) as i64;

    let size_diff = (left.total() as i64 - right.total() as i64).abs();
    let penalty   = if size_diff > 0 {
        (size_diff as f64).log2() as i64
    } else {
        0
    };

    val - penalty
}
```

List blocks are assigned prime 3 rather than 2. The reasoning was intuitive — lists tend to be larger and structurally heavier than single-line blocks, so giving them a different prime felt right. Whether this actually produces better tree balance than using a uniform prime across all block types I have not formally tested. That is an open question and probably worth benchmarking properly at some point.

The size imbalance penalty keeps the tree from becoming lopsided. If the heap-based rebuild still produces a tree deeper than `2.0 × log₂(total_bytes)`, the rope falls back to a strict binary midpoint split as a hard depth ceiling.

### The architectural constraint

The rope splits text at exact byte offsets for editing efficiency. The document model needs semantically complete blocks. These are two different things and they conflict — an insert mid-word splits a leaf into two fragments, each of which gets independently parsed. A fragment like `"y"` has no `$UL` context, so it parses as a paragraph. The rope text is always correct but the per-leaf cached `Block` values are not.

The fix is a clean boundary: the rope handles all text operations, and rendering always re-parses from the full concatenated text:

```rust
fn collect_blocks(node: &Node) -> Vec<Block> {
    parse_document(&collect_text(node))
}
```

This means a full reparse on every render. The dirty flag system handles keystroke-level efficiency. The full reparse handles correctness. They serve different purposes and do not get mixed up.

---

## 5. The WASM Boundary

The rule is simple: Rust owns everything that touches the document, JavaScript owns everything that touches the screen.

### What lives in Rust

- Document parsing — `parse_document`, `parse_inline_fragments`
- The rope — all insert, delete, replace, split, concat, and rebalance operations
- Cursor arithmetic — byte offset to line/col, char index to byte offset, block index at position
- Undo and redo history
- Dirty flag propagation and lazy reparse
- Table scaffold generation
- Document normalisation — ensuring every block command starts on its own line before parsing

### What lives in JavaScript

- The DOM — building and updating the preview from the block list
- Input event handling — translating keystrokes into rope operations
- Scroll synchronisation between the editor and preview panes
- Cursor sync — scrolling the preview to the block at the current cursor position
- Save scheduling — debounced HTTP POST on every change

### The boundary

The Rust side exposes a single struct — `EditorRope` — via `wasm_bindgen`. Every write operation returns the updated block list as a JSON string. JavaScript parses that and rebuilds the preview. No shared memory, no callbacks, no event system across the boundary — just function calls in and JSON strings out.

```
JS keystroke → rope.insert(byte_pos, char) → JSON block list → DOM update
JS keystroke → rope.delete(start, end)      → JSON block list → DOM update
JS keystroke → rope.undo()                  → JSON block list → DOM update
```

Inline fragments work the same way. JavaScript calls `parse_inline_fragments(text)` and gets back a typed fragment list as JSON. The render layer maps each fragment to a DOM element. There is no parsing logic in JavaScript.

### The server

The server is a bare TCP listener in Rust with no framework. Three routes — `GET /load` returns the saved document, `POST /save` writes it to disk, `GET /*` serves static files. Every response carries `Cache-Control: no-store` so the browser always fetches the latest WASM binary after a rebuild.

---

## 6. Performance

Vadic has a benchmark suite in the browser console. `benchRope(n)` runs n random operations on the live rope and reports timing stats. The mix is 40% inserts, 30% deletes, 10% full document parses, 10% cursor lookups, 10% char-to-byte conversions. The character set includes `$`, `\n`, and DSL-like sequences — so this is an adversarial workload, not typical writing. Real usage numbers would be better.

Four runs of `benchRope(10000)` at increasing document sizes, all times in milliseconds:

### 19KB — ~200 blocks

| Operation | n | avg | p50 | p95 | p99 |
|---|---|---|---|---|---|
| insert | 4018 | 0.2817 | 0.0000 | 1.0000 | 1.0000 |
| delete | 2944 | 0.2945 | 0.0000 | 1.0000 | 2.0000 |
| get_all | 968 | 0.2417 | 0.0000 | 1.0000 | 1.0000 |
| cursor_pos | 1058 | 0.0057 | 0.0000 | 0.0000 | 0.0000 |
| offset_at_char | 1012 | 0.0000 | 0.0000 | 0.0000 | 0.0000 |

### 60KB — ~600 blocks

| Operation | n | avg | p50 | p95 | p99 |
|---|---|---|---|---|---|
| insert | 3980 | 0.9887 | 1.0000 | 2.0000 | 2.0000 |
| delete | 2911 | 0.9876 | 1.0000 | 2.0000 | 2.0000 |
| get_all | 1056 | 0.8371 | 1.0000 | 2.0000 | 2.0000 |
| cursor_pos | 1008 | 0.0228 | 0.0000 | 0.0000 | 1.0000 |
| offset_at_char | 1045 | 0.0010 | 0.0000 | 0.0000 | 0.0000 |

### 119KB — ~1200 blocks

| Operation | n | avg | p50 | p95 | p99 |
|---|---|---|---|---|---|
| insert | 4002 | 1.9775 | 2.0000 | 3.0000 | 3.0000 |
| delete | 2996 | 1.9746 | 2.0000 | 3.0000 | 3.0000 |
| get_all | 1035 | 1.7285 | 2.0000 | 3.0000 | 3.0000 |
| cursor_pos | 972 | 0.0412 | 0.0000 | 0.0000 | 1.0000 |
| offset_at_char | 995 | 0.0000 | 0.0000 | 0.0000 | 0.0000 |

### 296KB — ~3000 blocks

| Operation | n | avg | p50 | p95 | p99 |
|---|---|---|---|---|---|
| insert | 3974 | 3.9409 | 4.0000 | 5.0000 | 6.0000 |
| delete | 3042 | 3.9270 | 4.0000 | 5.0000 | 6.0000 |
| get_all | 1016 | 3.6270 | 4.0000 | 5.0000 | 5.0000 |
| cursor_pos | 977 | 0.0461 | 0.0000 | 0.0000 | 1.0000 |
| offset_at_char | 991 | 0.0020 | 0.0000 | 0.0000 | 0.0000 |

### What the numbers say

cursor_pos and offset_at_char are fast at every size. From 19KB to 296KB — 15x document growth — cursor_pos average goes from 0.006ms to 0.046ms. The p99 never hits 1ms. The cached metadata in internal nodes is doing its job.

Insert and delete scale linearly, not logarithmically. Document size grows 15x and operation time grows 14x. The rope operations themselves are O(log n) but `force_resolve` calls `parse_document` on the full text after every edit and that dominates everything. At 296KB the p50 insert is 4ms — fine for normal use. At 1MB it would be around 13ms. The dirty flag infrastructure for true incremental reparsing exists but block-boundary-aware splitting is not implemented yet. That is the main performance work remaining.

---

## Conclusion

Vadic is still early. The DSL is complete and working. The rope is built and the WASM boundary is clean. The benchmarks are honest about where the performance currently stands.

The next concrete thing to build is true incremental reparsing — using the dirty flags and per-leaf block cache that are already in place, instead of reparsing the full document on every render. That alone would bring edit performance in line with navigation performance.

After that the plan is to expand the command set. Math notation, cross-references, custom block types, etc.... The architecture makes this straightforward — adding a block type means extending `BlockKind`, adding a parser branch, and adding a render case. Nothing structural changes.

The p-adic prime assignment is also something I want to test properly at some point. Right now prime 3 for list blocks was an intuitive choice, not a measured one. It might be the right call, it might not be. Worth finding out.

If you find this useful or have thoughts on the design, the issues are open.
