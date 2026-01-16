use crate::AppState;
use axum::{extract::{State, Json}, http::StatusCode, response::sse::{Event, Sse}, routing::{get, post}, Router};
use futures_util::Stream;
use serde::{Deserialize, Serialize};
use std::{sync::Arc, fs, io::Write};

#[derive(Deserialize)] pub struct PromptRequest { pub prompt: String }
#[derive(Deserialize)] pub struct TerminalRequest { pub command: String }
#[derive(Serialize)] pub struct TerminalResponse { pub output: String }
#[derive(Serialize)] pub struct FileList { pub files: Vec<String> }

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/", get(|| async { axum::response::Html(include_str!("../index.html")) }))
        .route("/ask", post(ask_handler))
        .route("/terminal", post(exec_terminal))
        .route("/restore", post(restore_handler))
        .route("/files", get(list_files))
        .route("/read/:name", get(read_file))
        .route("/save", post(save_file))
        .route("/build", post(build_handler))
        .route("/stats", get(sys_stats))
        .with_state(state)
}

async fn ask_handler(State(s): State<Arc<AppState>>, Json(r): Json<PromptRequest>) -> Sse<impl Stream<Item = Result<Event, std::convert::Infallible>>> {
    Sse::new(crate::brain::process_stream(s, r.prompt))
}

async fn exec_terminal(State(s): State<Arc<AppState>>, Json(r): Json<TerminalRequest>) -> (StatusCode, Json<TerminalResponse>) {
    let mut stdin = s.debian_stdin.lock().unwrap();
    let _ = writeln!(stdin, "{}", r.command);
    let _ = stdin.flush();
    (StatusCode::OK, Json(TerminalResponse { output: format!("Sent: {}", r.command) }))
}

async fn restore_handler() -> Json<TerminalResponse> {
    let out = crate::action_handler::restore_last_snapshot().await;
    Json(TerminalResponse { output: out })
}

async fn list_files() -> Json<FileList> {
    let paths = fs::read_dir(".").unwrap().filter_map(|e| e.ok()).map(|e| e.file_name().into_string().unwrap()).collect();
    Json(FileList { files: paths })
}

async fn read_file(axum::extract::Path(name): axum::extract::Path<String>) -> (axum::http::StatusCode, String) {
    match fs::read_to_string(format!("./{}", name)) {
        Ok(content) => (axum::http::StatusCode::OK, content),
        Err(_) => (axum::http::StatusCode::NOT_FOUND, "File not found".to_string()),
    }
}

#[derive(Deserialize)]
pub struct SaveRequest { pub name: String, pub content: String }

async fn save_file(Json(req): Json<SaveRequest>) -> StatusCode {
    match fs::write(format!("./{}", req.name), req.content) {
        Ok(_) => StatusCode::OK,
        Err(_) => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

async fn build_handler() -> (StatusCode, Json<TerminalResponse>) {
    println!("🛠️  FORGE: Initiating Build Sequence...");
    let output = std::process::Command::new("cargo")
        .args(&["build", "--release", "-j1"])
        .output();

    match output {
        Ok(out) => {
            let res = String::from_utf8_lossy(&out.stdout).to_string();
            let err = String::from_utf8_lossy(&out.stderr).to_string();
            (StatusCode::OK, Json(TerminalResponse { output: format!("BUILD LOG:\n{}\n{}", res, err) }))
        },
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(TerminalResponse { output: format!("BUILD FAILED: {}", e) })),
    }
}

#[derive(Serialize)]
pub struct SystemStats {
    pub cpu_usage: f32,
    pub ram_used: u64,
    pub ram_total: u64,
}

async fn sys_stats(State(state): State<Arc<AppState>>) -> Json<SystemStats> {
    let mut sys = state.sys.lock().unwrap();
    sys.refresh_all();
    
    Json(SystemStats {
        cpu_usage: sys.global_cpu_info().cpu_usage(),
        ram_used: sys.used_memory() / 1024 / 1024, // Convert to MB
        ram_total: sys.total_memory() / 1024 / 1024,
    })
}
