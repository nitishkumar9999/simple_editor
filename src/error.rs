use std::fmt;

#[derive(Debug)]
pub enum EditorError {
    Io(std::io::Error),
    Serialize(serde_json::Error),
    Rope(String),
}

impl fmt::Display for EditorError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            EditorError::Io(e) => write!(f, "IO error: {}", e),
            EditorError::Serialize(e) => write!(f, "Serialize error: {}", e),
            EditorError::Rope(msg) => write!(f, "Rope error: {}", msg),
        }
    }
}

impl From<std::io::Error> for EditorError {
    fn from(e: std::io::Error) -> Self { EditorError::Io(e) }
}

impl From<serde_json::Error> for EditorError {
    fn from(e: serde_json::Error) -> Self { EditorError::Serialize(e) }
}

// Lets WASM functions return Result<T, EditorError> directly
impl From<EditorError> for wasm_bindgen::JsValue {
    fn from(e: EditorError) -> Self {
        wasm_bindgen::JsValue::from_str(&e.to_string())
    }
}
