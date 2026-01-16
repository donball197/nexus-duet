use axum::{extract::{ws::{WebSocket, WebSocketUpgrade}, State}, response::Response};
use std::sync::Arc;
use crate::{AppState, agents, archivist};

pub async fn ws_handler(ws: WebSocketUpgrade, State(state): State<Arc<AppState>>) -> Response {
    ws.on_upgrade(|socket| handle_socket(socket, state))
}

async fn handle_socket(_socket: WebSocket, _state: Arc<AppState>) {
    // Logic for handling commands via WebSocket
}

pub async fn execute_agent_command(text: &str) -> String {
    if text.contains("janitor") { 
        agents::run_janitor().await; 
        "Janitor: Cleanup complete.".to_string()
    } else if text.contains("archivist") {
        archivist::run_backup().await;
        "Archivist: Backup complete.".to_string()
    } else {
        "NEXUS: Command not recognized.".to_string()
    }
}
