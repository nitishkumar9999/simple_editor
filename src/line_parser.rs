use crate::data::{Block, BlockKind, BlockContent, Align};
use crate::metadata_parser::parse_metadata;

pub fn parse_line(line: &str) -> Block {
    let trimmed = line.trim();

    if trimmed.starts_with("!$") {
        return Block {
            kind: BlockKind::Paragraph,
            align: Align::Left,
            content: BlockContent::Text(trimmed[1..].to_string()),
        };
    }

    if let Some((meta_part, content)) = trimmed.split_once(" - ") {
        let (kind, align) = parse_metadata(meta_part);

        if meta_part.trim() == "$LINK" {
            if let Some((label, url)) = content.split_once(" | ") {
                return Block {
                   kind: BlockKind::Link {
                       label: label.trim().to_string(),
                       url: url.trim().to_string(),
                   },
                   align, 
                   content: BlockContent::Text(String::new()),
                };
            }
        }

      if meta_part.trim() == "$IMG"  {
           if let Some((alt, src)) = content.split_once(" | ") {
               return Block {
                  kind: BlockKind::Image {
                      alt: alt.trim().to_string(),
                      src: src.trim().to_string(),
                 },
                 align,
                 content: BlockContent::Text(String::new()),
              };
           }
       }
      if meta_part.trim() == "$BQ" {
          if let Some((quote, attr)) = content.split_once(" | ") {
              return Block {
                 kind: BlockKind::BlockQuote {
                     attribution: Some(attr.trim().to_string()),
                 },
              
                 align,
                 content: BlockContent::Text(quote.trim().to_string()),
              };
          }
          return Block {
              kind: BlockKind::BlockQuote { attribution: None },
              align,
              content: BlockContent::Text(content.to_string()),
          };
      } 
      return Block {
          kind,
          align,
          content: BlockContent::Text(content.to_string()),
      };
    }

    if trimmed.starts_with('$') {
        let (kind, align) = parse_metadata(trimmed);
        return Block {
            kind,
            align,
            content: BlockContent::Text(String::new()),
        };    
    }


    Block {
        kind: BlockKind::Paragraph,
        align: Align::Left,
        content: BlockContent::Text(trimmed.to_string()),
    }
}
