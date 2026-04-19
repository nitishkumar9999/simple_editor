mod data;
mod metadata_parser;
mod line_parser;
mod inline_parser;
mod document_parser;

use metadata_parser::parse_metadata;
use line_parser::parse_line;
use data::{Align, BlockKind, BlockContent};
use inline_parser::{parse_inline, Fragment};
use document_parser::parse_document;

fn main() {
    let input = r#"$H1 - Hello world
$B - this is bold
$UL 
    item one
    item two
    item three
$CODE - rust
    fn main() {
        let mut i = start;

        while i < lines.len() {
           let line = lines[i];

          // new block = starts at column 0 with $
          if !line.starts_with("    ") && line.starts_with('$') {
             return i;
          }

          i += 1;
        }

        lines.len()
     }
$TB
    | Method | Accuracy | Speed |
    |--------|----------|-------|
    | ours   | 94.2%    | 12ms  |
    | prior  | 91.1%    | 45ms  |
"#;

    let blocks = parse_document(input);

    let json = serde_json::to_string_pretty(&blocks).unwrap();
    println!("{}", json);

    for block in &blocks {
        match &block.content {
            BlockContent::Items(items) => {
                println!("[{:?}|{:?}]", block.kind, block.align);
                for (i, item) in items.iter().enumerate() {
                    println!("  {} {}", i + 1, item);
                }
            }
            BlockContent::Rows(rows) => {
                println!("[{:?}|{:?}]", block.kind, block.align);
                for row in rows {
                    println!("  {:?}", row);
                }
            }
            BlockContent::Text(text) => {
                let fragments = parse_inline(text);
                match &block.kind {
                    BlockKind::Link { label, url } => {
                        println!("[LINK] {} -> {}", label, url);
                    }
                    BlockKind::Image { alt, src } => {
                        println!("[IMAGE] alt={} src={}", alt, src);
                    }
                    BlockKind::HorizontalRule => {
                        println!("[HR]");
                    }
                    kind => {
                        print!("[{:?}|{:?}] ", kind, block.align);
                        for frag in fragments {
                            match frag {
                                Fragment::Text(t) => print!("{}", t),
                                Fragment::Styled(k, t) => print!("[{:?}]{}[END]", k, t),
                                Fragment::Link { label, url } => {
                                    print!("[LINK: {} -> {}]", label, url)
                                }
                            }
                        }
                        println!();
                    }
                }
            }
        }
    }
}
