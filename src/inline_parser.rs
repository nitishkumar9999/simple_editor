use crate::data::{TextStyles, BlockKind};

pub enum Fragment {
    Text(String),
    Styled(BlockKind, String),
    Link { label: String, url: String },
}

pub fn parse_inline(text: &str) -> Vec<Fragment> {
     let mut fragments = Vec::new();
     let mut remaining = text;

     loop {
         match remaining.find('"') {
             None => {
                 if !remaining.is_empty() {
                     fragments.push(Fragment::Text(remaining.to_string()));
                 }
                 break;
             }

             Some(start) => {
                 if start > 0 {
                     fragments.push(Fragment::Text(remaining[..start].to_string()));
                 }

                 let after_open = &remaining[start + 1..];

                 match after_open.find('"') {
                     None => {
                         fragments.push(Fragment::Text(remaining[start..].to_string()));
                         break;
                     }

                     Some(end) => {
                         let inside = &after_open[..end];

                         if let Some((cmd, content)) = inside.split_once(" - ") {
                            match cmd.trim() {
                                "$LINK" => {
                                    if let Some((label, url)) = content.split_once(" | ") {
                                        fragments.push(Fragment::Link {
                                            label: label.trim().to_string(),
                                            url: url.trim().to_string(),
                                        });
                                    } else {
                                        // malformed $LINK — no pipe separator, treat as text
                                        fragments.push(Fragment::Text(format!("\"{}\"", inside)));
                                    }
                                }
                                other => {
                                    let kind = match other {
                                        "$I"              => BlockKind::Italic,
                                        "$B"              => BlockKind::Bold,
                                        "$ST"             => BlockKind::Strikethrough,
                                        "$I:ST" | "$ST:I" => BlockKind::ItalicStrike,
                                        "$ICODE"          => BlockKind::InlineCode,
                                        "$BI"             => BlockKind::BoldItalic,
                                        "$B:ST"           => BlockKind::BoldStrike,
                                        "$BI:ST"          => BlockKind::BoldItalicStrike,
                                        _                 => BlockKind::Paragraph,
                                    };
                                    fragments.push(Fragment::Styled(kind, content.to_string()));
                                }
                            }
                        } else {
                            // no " - " separator — literal quoted text
                            fragments.push(Fragment::Text(format!("\"{}\"", inside)));
                        }

                        remaining = &after_open[end + 1..];
                    }
                }
            }
        }
    }

    fragments
}

pub fn parse_inline_style(inside_quotes: &str) -> (TextStyles, String) {
    if inside_quotes.starts_with('!') {
        return (TextStyles::default(), inside_quotes[1..].to_string());
    }
    if let Some((cmd, text)) = inside_quotes.split_once(" - ") {
        let styles = TextStyles::from_cmd(cmd);
        return (styles, text.to_string());
    }
    (TextStyles::default(), inside_quotes.to_string())
}
                         
