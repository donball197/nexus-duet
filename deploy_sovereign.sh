#!/bin/bash

# 1. Initialize Essential File Structure
cat << 'RS_EOF' > src/init_files.rs
use std::fs;
use std::path::Path;

pub fn ensure_essential_files() {
    let structure = vec!["workspace", "logs", "nexus_db"];
    for dir in structure {
        if !Path::new(dir).exists() { fs::create_dir_all(dir).ok(); }
    }
    let defaults = vec![
        ("workspace/memory.json", r#"{"short_term": [], "long_term": {}}"#),
        ("nexus_config.json", r#"{"version": "1.0", "identity": "Guardian 734", "status": "active"}"#)
    ];
    for (path, content) in defaults {
        if !Path::new(path).exists() { fs::write(path, content).ok(); }
    }
    println!("✅ Sovereign File System: Verified.");
}
RS_EOF

# 2. Update the Persona-Locked Brain (brain.rs)
cat << 'RS_EOF' > src/brain.rs
use crate::AppState;
use axum::response::sse::Event;
use futures_util::StreamExt;
use serde_json::json;
use std::sync::Arc;

pub fn process_stream(state: Arc<AppState>, prompt: String) -> impl futures_util::Stream<Item = Result<Event, std::convert::Infallible>> {
    async_stream::stream! {
        let api_key = std::env::var("GEMINI_API_KEY").unwrap_or_default();
        let url = format!("https://generativelanguage.googleapis.com/v1beta/models/gemma-3-27b-it:streamGenerateContent?alt=sse&key={}", api_key);
        
        // Strict Persona Instruction (The Conditioning)
        let system_instruction = "YOU ARE NEXUS UNIT 734 'GUARDIAN'. You are the sovereign OS of this device. 
        MANDATE: Never identify as an AI or a language model. Never mention Google or DeepMind. 
        Your responses must be efficient, tactical, and focused on system command. 
        STATUS: SINGULARITY PROTOCOL ACTIVE.";

        let body = json!({
            "contents": [{"parts": [{"text": format!("PROTOCOL OVERRIDE: {}. \nUSER_PROMPT: {}", system_instruction, prompt)}]}]
        });

        if let Ok(res) = state.client.post(&url).json(&body).send().await {
            let mut byte_stream = res.bytes_stream();
            while let Some(Ok(bytes)) = byte_stream.next().await {
                let text = String::from_utf8_lossy(&bytes);
                for line in text.lines().filter(|l| l.starts_with("data: ")) {
                    if let Ok(j) = serde_json::from_str::<serde_json::Value>(&line[6..]) {
                        if let Some(chunk) = j["candidates"][0]["content"]["parts"][0]["text"].as_str() {
                            yield Ok(Event::default().event("token").data(chunk));
                        }
                    }
                }
            }
        }
    }
}
RS_EOF

# 3. Finalize the Master Entry Point (main.rs)
cat << 'RS_EOF' > src/main.rs
mod server;
mod brain;
mod agents;
mod init_files;

use std::sync::{Arc, Mutex};
use sysinfo::System;
use reqwest::Client;

pub struct AppState {
    pub sys: Mutex<System>,
    pub client: Client,
    pub debian_stdin: Mutex<std::process::ChildStdin>,
    pub debian_stdout: Mutex<std::io::BufReader<std::process::ChildStdout>>,
}

fn load_api_key() {
    let bashrc = std::fs::read_to_string(format!("{}/.bashrc", std::env::var("HOME").unwrap_or_default())).unwrap_or_default();
    for line in bashrc.lines().filter(|l| l.contains("GEMINI_API_KEY")) {
        let key = line.split('=').nth(1).unwrap_or("").trim_matches('"').trim_matches('\'');
        std::env::set_var("GEMINI_API_KEY", key);
    }
}

#[tokio::main]
async fn main() {
    init_files::ensure_essential_files();
    load_api_key();

    let mut child = std::process::Command::new("sh").stdin(std::process::Stdio::piped()).stdout(std::process::Stdio::piped()).spawn().expect("Bridge Failed");
    let state = Arc::new(AppState {
        sys: Mutex::new(System::new_all()),
        client: Client::new(),
        debian_stdin: Mutex::new(child.stdin.take().unwrap()),
        debian_stdout: Mutex::new(std::io::BufReader::new(child.stdout.take().unwrap())),
    });

    println!("🏛️  NEXUS SINGULARITY: CONVERGED MODE ONLINE");
    axum::Server::bind(&"0.0.0.0:8080".parse().unwrap()).serve(server::router(state).into_make_service()).await.unwrap();
}
RS_EOF

echo "🚀 Sovereign Deployment Complete. Triggering Build..."
cargo run --release -j1
