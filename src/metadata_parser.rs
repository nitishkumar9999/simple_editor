use crate::data::{Align, BlockKind};

pub fn parse_metadata(raw: &str) -> (BlockKind, Align) {
    let cmd_part = raw.split_whitespace().next().unwrap_or("");

    // compound commands — must match before splitting on :
    let compound = match cmd_part {
        "$BI:ST" | "$ST:BI" => Some(BlockKind::BoldItalicStrike),
        "$B:ST"  | "$ST:B"  => Some(BlockKind::BoldStrike),
        "$I:ST"  | "$ST:I"  => Some(BlockKind::ItalicStrike),
        _ => None,
    };

    if let Some(kind) = compound {
        return (kind, Align::Left);
    }

    // split on : to separate command from alignment modifier
    let mut parts = cmd_part.splitn(2, ':');
    let cmd = parts.next().unwrap_or("").trim();
    let modifier = parts.next().unwrap_or("").trim();

    // $CODE is special — language comes after $CODE prefix
    if cmd.starts_with("$CODE") {
        let lang = cmd
            .strip_prefix("$CODE")
            .unwrap_or("")
            .trim()
            .to_string();
        let lang = if lang.is_empty() {
            "plain".to_string()
        } else {
            lang
        };
        return (BlockKind::Code(lang), Align::Left);
    }

    let kind = match cmd {
        "$H1"   => BlockKind::Heading(1),
        "$H2"   => BlockKind::Heading(2),
        "$H3"   => BlockKind::Heading(3),
        "$H4"   => BlockKind::Heading(4),
        "$B"    => BlockKind::Bold,
        "$I"    => BlockKind::Italic,
        "$BI"   => BlockKind::BoldItalic,
        "$ST"   => BlockKind::Strikethrough,
        "$BQ"   => BlockKind::BlockQuote { attribution: None },
        "$CODE" => BlockKind::Code("plain".to_string()),
        "$TB"   => BlockKind::Table,
        "$TOC"  => BlockKind::TableOfContents,
        "$FN"   => BlockKind::Footnote,
        "$ICODE" => BlockKind::InlineCode,
        "$UL"   => BlockKind::UnorderedList,
        "$OL"   => BlockKind::OrderedList,
        "$HR"   => BlockKind::HorizontalRule,
        _       => BlockKind::Paragraph,
    };

    let align = match modifier {
        "C" => Align::Center,
        "R" => Align::Right,
        _   => Align::Left,
    };

    (kind, align)
}
