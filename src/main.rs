mod action_handler;
mod server;
mod brain;
mod agents;
mod init_files;
mod key_loader; // Use the new module you provided

use std::sync::{Arc, Mutex};
use sysinfo::System;
use reqwest::Client;

pub struct AppState {
    pub sys: Mutex<System>,
    pub client: Client,
    pub debian_stdin: Mutex<std::process::ChildStdin>,
    pub debian_stdout: Mutex<std::io::BufReader<std::process::ChildStdout>>,
}

#[tokio::main]
async fn main() {
    // 1. Initialize files
    init_files::ensure_essential_files();
    
    // 2. Use your robust key loader
    key_loader::load_api_key();

    // 3. Spawn the bridge
    let mut child = std::process::Command::new("sh")
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .spawn()
        .expect("Bridge Failed");

    let state = Arc::new(AppState {
        sys: Mutex::new(System::new_all()),
        client: Client::new(),
        debian_stdin: Mutex::new(child.stdin.take().unwrap()),
        debian_stdout: Mutex::new(std::io::BufReader::new(child.stdout.take().unwrap())),
    });

    println!("🏛️  NEXUS SINGULARITY: CONVERGED MODE ONLINE");
    
    // 4. Start Server
    let addr = "0.0.0.0:8080".parse().unwrap();
    axum::Server::bind(&addr)
        .serve(server::router(state).into_make_service())
        .await
        .unwrap();
}
