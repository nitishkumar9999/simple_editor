mod data;
mod metadata_parser;
mod line_parser;
mod inline_parser;
mod document_parser;
mod rope;
mod server;

fn main() {
    server::run_server();
}
