use serde::Serialize;

#[derive(Debug, Serialize,Clone)]
pub enum Align {
    Left,
    Right,
    Center,
}

#[derive(Debug, Serialize, Clone)]
pub enum BlockKind {
    Heading(u8),
    Paragraph,
    Bold,
    Italic,
    Strikethrough,
    BlockQuote { attribution: Option<String> },
    Code(String),
    InlineCode,
    Image { alt: String, src: String },
    Link { label: String, url: String },
    UnorderedList,
    OrderedList,
    Table,
    TableOfContents,
    HorizontalRule,
    Footnote,
    ItalicStrike,
    BoldItalic,
    BoldStrike,
    BoldItalicStrike,
}

#[derive(Debug, Serialize, Clone)]
pub enum BlockContent {
    Text(String),
    Items(Vec<String>),
    Rows(Vec<Vec<String>>),
}

#[derive(Debug, Serialize, Clone)]
pub struct Block {
    pub kind: BlockKind,
    pub align: Align,
    pub content: BlockContent,
}

#[derive(Debug, Default, Clone, Copy, Serialize)]
pub struct TextStyles {
    pub bold: bool,
    pub italic: bool,
    pub strike: bool,
    pub inline_code: bool
}

impl TextStyles {
    pub fn from_cmd(cmd: &str) -> Self {
        let mut styles = TextStyles::default();
        
        for part in cmd.strip_prefix('$').unwrap_or(cmd).split(':') {
            match part {
                "B" => styles.bold = true,
                "I" => styles.italic = true,
                "ST" => styles.strike = true,
                "IC" => styles.inline_code = true,
                _ => {}
            }
        }
        styles
    }
}



