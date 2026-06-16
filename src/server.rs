use std::net::{TcpListener, TcpStream};
use std::io::{self, Read, Write, BufReader, BufRead};
use std::fs;

const SAVE_PATH: &str = "document.dsl";

pub fn run_server() {
    let listener = TcpListener::bind("127.0.0.1:8080")
        .expect("Failed to bind to port 8080 — is it already in use?");
    println!("Server running at http://127.0.0.1:8080");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                if let Err(e) = handle_connection(stream) {
                    eprintln!("Connection error: {}", e);
                }
            }
            Err(e) => eprintln!("Failed to accept connection: {}", e),
        }
    }
}

fn handle_connection(mut stream: TcpStream) -> io::Result<()> {
    let mut reader = BufReader::new(&stream);

    let mut request_line = String::new();
    reader.read_line(&mut request_line)?;

    let mut content_length: usize = 0;
    loop {
        let mut line = String::new();
        reader.read_line(&mut line)?;
        if line == "\r\n" { break; }
        if line.to_lowercase().starts_with("content-length:") {
            content_length = line
                .split(':')
                .nth(1)
                .unwrap_or("0")
                .trim()
                .parse()
                .unwrap_or(0);
        }
    }

    let parts: Vec<&str> = request_line.split_whitespace().collect();
    if parts.len() < 2 { return Ok(()); }
    let method = parts[0];
    let path   = parts[1];

    match (method, path) {
        ("GET", "/load") => {
            let body = fs::read_to_string(SAVE_PATH).unwrap_or_default();
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: text/plain; charset=utf-8\r\n\
                 Content-Length: {}\r\nCache-Control: no-store\r\n\r\n",
                body.len()
            );
            stream.write_all(response.as_bytes())?;
            stream.write_all(body.as_bytes())?;
        }
        ("POST", "/save") => {
            let mut body = vec![0u8; content_length];
            reader.read_exact(&mut body)?;
            let text = String::from_utf8_lossy(&body);
            fs::write(SAVE_PATH, text.as_bytes())?;
            stream.write_all(
                b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\nCache-Control: no-store\r\n\r\nok"
            )?;
        }
        ("GET", p) => {
            let file_path = if p == "/" { "./index.html".to_string() }
                            else { format!(".{}", p) };

            match fs::read(&file_path) {
                Ok(bytes) => {
                    let mime = mime_type(&file_path);
                    let response = format!(
                        "HTTP/1.1 200 OK\r\nContent-Type: {}\r\n\
                         Content-Length: {}\r\nCache-Control: no-store\r\n\r\n",
                        mime, bytes.len()
                    );
                    stream.write_all(response.as_bytes())?;
                    stream.write_all(&bytes)?;
                }
                Err(e) if e.kind() == io::ErrorKind::NotFound => {
                    stream.write_all(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")?;
                }
                Err(e) => {
                    eprintln!("Failed to read file {}: {}", file_path, e);
                    stream.write_all(b"HTTP/1.1 500 Internal Server Error\r\nContent-Length: 0\r\n\r\n")?;
                }
            }
        }
        _ => {
            stream.write_all(b"HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\n\r\n")?;
        }
    }

    Ok(())
}

fn mime_type(path: &str) -> &'static str {
    if path.ends_with(".html") { "text/html" }
    else if path.ends_with(".js") { "application/javascript" }
    else if path.ends_with(".wasm") { "application/wasm" }
    else if path.ends_with(".css") { "text/css" }
    else { "application/octet-stream" }
}
