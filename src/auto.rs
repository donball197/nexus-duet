use axum::{extract::{ws::{Message, WebSocket, WebSocketUpgrade}, State}, response::IntoResponse, routing::get, Router};
use std::sync::Arc;
use crate::AppState;
use tokio::time::{sleep, Duration};

pub fn router(state: Arc<AppState>) -> Router { Router::new().route("/", get(ws_handler)).with_state(state) }
async fn ws_handler(ws: WebSocketUpgrade, State(state): State<Arc<AppState>>) -> impl IntoResponse { ws.on_upgrade(|socket| handle_socket(socket, state)) }

async fn handle_socket(mut socket: WebSocket, state: Arc<AppState>) {
    loop {
        let (cpu, ram) = {
            let mut sys = state.sys.lock().unwrap();
            sys.refresh_cpu_usage(); // 0.30 API
            sys.refresh_memory();
            let cpu_use = sys.global_cpu_info().cpu_usage();
            (format!("{:.1}%", cpu_use), format!("{} MB", sys.used_memory() / 1024 / 1024))
        };
        let payload = serde_json::json!({"cpu_load": cpu, "ram_usage": ram, "status": "ONLINE"});
        if socket.send(Message::Text(payload.to_string())).await.is_err() { break; }
        sleep(Duration::from_secs(1)).await;
    }
}
