use crate::data::{Block, BlockKind, BlockContent, Align};
use crate::line_parser::parse_line;
use crate::metadata_parser::parse_metadata;

pub fn parse_document(input: &str) -> Vec<Block> {
    let mut blocks: Vec<Block> = Vec::new();
    let mut lines = input.lines().peekable();

    while let Some(line) = lines.next() {
        let trimmed = line.trim();
        
        if trimmed.is_empty() {
            continue;
        }

        if trimmed.starts_with("$BQ") && !trimmed.contains(" - ") {
            let (kind, align) = parse_metadata(trimmed);
            
            let mut quote_lines = Vec::new();
            let mut attribution = None;

            while let Some(next_line) = lines.peek() {
                let is_indented = next_line.starts_with("    ")
                    || next_line.starts_with(" ")
                    || next_line.starts_with("\t");
                if is_indented {
                    let trimmed_line = next_line.trim().to_string();
                    if trimmed_line.starts_with("--")  {
                        attribution = Some(trimmed_line[2..].trim().to_string());
                    } else {
                        quote_lines.push(trimmed_line);
                    }
                    lines.next();
                } else {
                    break;
                }
            }

            let quote_text = if quote_lines.is_empty() {
                match &kind {
                    BlockKind::BlockQuote { .. } => String::new(),
                    _ => String::new(),
                }
            } else {
                quote_lines.join(" ")
            };

            blocks.push(Block {
                kind: BlockKind::BlockQuote { attribution },
                align,
                content: BlockContent::Text(quote_text),
            });
            continue;
        }

        if trimmed.starts_with("$CODE") {
            let lang = if let Some((_,lang)) = trimmed.split_once(" - ") {
                lang.trim().to_string()
            } else {
                trimmed
                    .strip_prefix("$CODE")
                    .unwrap_or("")
                    .trim()
                    .to_string()
            };

            let lang = if lang.is_empty() {
                "plain".to_string()
            } else {
                lang
            };

            let mut raw = String::new();
            while let Some(next_line) = lines.peek() {
               let is_new_command = next_line.trim().starts_with('$')
                   && !next_line.starts_with("    ")
                   && !next_line.starts_with("\t")
                   && !next_line.trim().is_empty();
                   
               if is_new_command {
                   break;
                }

               let line = *next_line;
               let content = if line.starts_with("    ") {
                   &line[4..]
                } else {
                    line
                };
                raw.push_str(content);
                raw.push('\n');
                lines.next();

            }

            blocks.push(Block {
                kind: BlockKind::Code(lang),
                align: Align::Left, 
                content: BlockContent::Text(raw.trim_end().to_string()),
            });
            continue;
         }

         if trimmed.starts_with('$') && !trimmed.contains(" - ") {
             let (kind, align) = parse_metadata(trimmed);

             let mut raw = String::new();
             while let Some(next_line) = lines.peek() {
                 let is_indented = next_line.starts_with("    ")
                     || next_line.starts_with(" ")
                     || next_line.starts_with("\t");
                 if is_indented {
                     raw.push_str(next_line.trim());
                     raw.push('\n');
                     lines.next();
                 } else {
                     break;
                 }
             }

             let raw = raw.trim_end().to_string();
             let content =make_content(&kind, raw);
             blocks.push(Block { kind, align, content });
             continue;
         }

         blocks.push(parse_line(trimmed));

    }  

    blocks
}

fn make_content(kind: &BlockKind, raw: String) -> BlockContent {
    match kind {
        BlockKind::UnorderedList | BlockKind::OrderedList => {
            let items = raw
                .lines()
                .map(|l| l.trim().to_string())
                .filter(|l| !l.is_empty())
                .collect();
            BlockContent::Items(items)
        }

        BlockKind::Table => {
            let rows: Vec<Vec<String>> = raw
                .lines()
                .map(|l| l.trim().to_string())
                .filter(|l| !l.is_empty() && l.contains('|'))
                .filter(|l| !l.split('|').all(|cell| cell.trim().chars().all(|c| c == '-' || c == ' ')))
                .map(|l| {
                    l.split('|')
                        .map(|cell| cell.trim().to_string())
                        .filter(|cell| !cell.is_empty())
                        .collect()
                })
                .collect();

            if rows.is_empty() {
                BlockContent::Rows(vec![])
            } else {
                let mut all_rows = vec![rows[0].clone()];
                all_rows.extend_from_slice(&rows[1..]);
                BlockContent::Rows(all_rows)
            }
    
        },
        _ => BlockContent::Text(raw),

    }
}

