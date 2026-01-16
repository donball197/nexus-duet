#!/bin/bash
set -e
echo ">> Stage 1: Initializing Clean Slate..."
pkill -f nexus_lite || true
rm -rf src target index.html Cargo.lock Cargo.toml workspace/sentinel.py
mkdir -p src workspace/logs

echo ">> Stage 2: Deploying Cargo Manifest..."
cat << 'TOML' > Cargo.toml
[package]
name = "nexus_lite"
version = "1.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1.0", features = ["full"] }
tower-http = { version = "0.5", features = ["fs", "cors"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
reqwest = { version = "0.11", features = ["json", "stream"] }
futures-util = "0.3"
async-stream = "0.3"
sysinfo = "0.29"
dotenvy = "0.15"
TOML

echo ">> Stage 3: Deploying Sentinel Safety..."
cat << 'PY' > workspace/sentinel.py
import sys
BLOCKLIST = ["rm -rf /", "mkfs", "dd if=", "pkill -9", "shutdown"]
def audit(cmd):
    for danger in BLOCKLIST:
        if danger in cmd.lower():
            sys.exit(1)
    sys.exit(0)
if __name__ == "__main__":
    if len(sys.argv) > 1:
        audit(sys.argv[1])
PY

echo ">> Stage 4: Deploying Kernel (main.rs)..."
cat << 'RUST' > src/main.rs
use std::{fs, process::{Command, Stdio, ChildStdin, ChildStdout}, sync::{Arc, Mutex}, io::BufReader, env};
use sysinfo::{System, SystemExt};

pub mod server;
pub mod sentinel;
pub mod agent;

pub struct AppState {
    pub client: reqwest::Client,
    pub sys: Mutex<System>,
    pub debian_stdin: Mutex<ChildStdin>,
    pub debian_stdout: Mutex<BufReader<ChildStdout>>,
}

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
    // Attempt to keep CPU awake for compilation/execution
    let _ = Command::new("termux-wake-lock").spawn();
    
    let _ = fs::create_dir_all("workspace");
    let workspace_str = env::current_dir().unwrap().join("workspace").to_string_lossy().into_owned();

    // Spawn Persistent Debian Bridge
    let mut child = Command::new("proot-distro")
        .args(["login", "debian", "--shared-tmp", "--bind", &format!("{}:/workspace", workspace_str)])
        .arg("--").arg("sh").stdin(Stdio::piped()).stdout(Stdio::piped()).spawn()
        .expect("CRITICAL: Failed to spawn Debian Bridge. Run 'proot-distro install debian'");

    let app_state = Arc::new(AppState {
        client: reqwest::Client::new(),
        sys: Mutex::new(System::new_all()),
        debian_stdin: Mutex::new(child.stdin.take().unwrap()),
        debian_stdout: Mutex::new(BufReader::new(child.stdout.take().unwrap())),
    });

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    println!(">> NEXUS PLATINUM ENGAGED | http://localhost:8080");
    axum::serve(listener, server::router(app_state)).await.unwrap();
}
RUST

echo ">> Stage 5: Deploying Server (server.rs)..."
cat << 'RUST' > src/server.rs
use axum::{extract::{Path, State}, response::{sse::Sse, Html}, routing::{get, post}, Json, Router};
use std::sync::Arc;
use crate::{AppState, agent};
use sysinfo::{SystemExt, CpuExt};
use serde_json::{json, Value};

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/", get(|| async { Html(include_str!("../index.html")) }))
        .route("/api/stats", get(get_stats))
        .route("/ask", post(ask_handler))
        .route("/files", get(list_files))
        .route("/load/:name", get(load_file))
        .route("/save/:name", post(save_file))
        .with_state(state)
}

async fn get_stats(State(state): State<Arc<AppState>>) -> Json<Value> {
    let mut sys = state.sys.lock().unwrap();
    sys.refresh_cpu();
    Json(json!({ "cpu_usage": sys.global_cpu_info().cpu_usage() }))
}

async fn ask_handler(State(state): State<Arc<AppState>>, Json(req): Json<Value>) -> Sse<impl futures_util::Stream<Item = Result<axum::response::sse::Event, std::convert::Infallible>>> {
    let p = req["prompt"].as_str().unwrap_or("").to_string();
    let c = req["editor_context"].as_str().map(|s| s.to_string());
    Sse::new(agent::stream_processor(state, p, c))
}

async fn list_files() -> Json<Vec<String>> {
    let mut files = Vec::new();
    if let Ok(entries) = std::fs::read_dir("workspace") {
        for entry in entries.flatten() {
            if let Ok(name) = entry.file_name().into_string() {
                if !name.starts_with('.') { files.push(name); }
            }
        }
    }
    files.sort();
    Json(files)
}

async fn load_file(Path(name): Path<String>) -> String {
    let path = std::path::Path::new("workspace").join(name);
    std::fs::read_to_string(path).unwrap_or_else(|_| "ERROR: File not found".to_string())
}

async fn save_file(Path(name): Path<String>, Json(req): Json<Value>) -> String {
    let path = std::path::Path::new("workspace").join(name);
    let content = req["content"].as_str().unwrap_or("");
    match std::fs::write(path, content) {
        Ok(_) => "SUCCESS".to_string(),
        Err(e) => format!("ERROR: {}", e),
    }
}
RUST

echo ">> Stage 6: Deploying Agent (agent.rs)..."
cat << 'RUST' > src/agent.rs
use crate::{AppState, sentinel};
use axum::response::sse::Event;
use futures_util::StreamExt;
use std::{sync::Arc, io::{BufRead, Write}};

fn run_debian_cmd(state: &AppState, cmd: &str) -> String {
    let mut stdin = state.debian_stdin.lock().unwrap();
    let mut stdout = state.debian_stdout.lock().unwrap();
    // Redirect stderr to stdout so we see errors
    let full_cmd = format!("cd /workspace && ( {} ) 2>&1 ; echo \"\" ; echo ---NEXUS_DONE--- \n", cmd.trim());
    if let Err(e) = stdin.write_all(full_cmd.as_bytes()) {
        return format!("BRIDGE ERROR: {}", e);
    }
    let _ = stdin.flush();
    let mut resp = String::new();
    loop {
        let mut line = String::new();
        if stdout.read_line(&mut line).is_err() || line.contains("---NEXUS_DONE---") { break; }
        resp.push_str(&line);
    }
    resp
}

pub fn stream_processor(state: Arc<AppState>, prompt: String, _ctx: Option<String>) -> impl futures_util::Stream<Item = Result<Event, std::convert::Infallible>> {
    async_stream::stream! {
        // 1. Vital Signs Check
        if let Err(alert) = sentinel::check_vital_signs() {
            yield Ok(Event::default().data(format!("{{\"event\":\"tool_output\",\"data\":\"SYSTEM ALERT: {}\"}}", alert)));
            // We don't return here; we warn but allow operation unless critical
        }

        let api_key = std::env::var("GEMINI_API_KEY").unwrap_or_default();
        // Fallback model if gemma-3 is unavailable
        let url = format!("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:streamGenerateContent?alt=sse&key={}", api_key);
        
        let identity = "You are NEXUS. Mobile AI Commander. Workspace: /workspace. Use [DEBIAN: command] for shell tasks.";
        let full_prompt = format!("{}\n\nTASK: {}", identity, prompt);

        let res = state.client.post(&url).json(&serde_json::json!({"contents":[{"parts":[{"text":full_prompt}]}]})).send().await;

        if let Ok(r) = res {
            let mut byte_stream = r.bytes_stream();
            let mut full_resp = String::new();
            
            while let Some(Ok(bytes)) = byte_stream.next().await {
                let text = String::from_utf8_lossy(&bytes);
                for line in text.lines().filter(|l| l.starts_with("data: ")) {
                    // Gemini API returns a JSON object at "data: "
                    if let Ok(json) = serde_json::from_str::<serde_json::Value>(&line[6..]) {
                        if let Some(chunk) = json["candidates"][0]["content"]["parts"][0]["text"].as_str() {
                            full_resp.push_str(chunk);
                            // Serialize chunk safely for SSE
                            if let Ok(safe_chunk) = serde_json::to_string(chunk) {
                                yield Ok(Event::default().data(format!("{{\"event\":\"token\",\"data\":{}}}", safe_chunk)));
                            }
                        }
                    }
                }
            }
            
            // Tool Execution logic
            if let Some(start) = full_resp.find("[DEBIAN:") {
                if let Some(end) = full_resp[start..].find("]") {
                    let cmd = &full_resp[start+8..start+end];
                    if sentinel::check_safety(cmd).is_ok() {
                        yield Ok(Event::default().data(format!("{{\"event\":\"tool_output\",\"data\":\"[EXECUTING]: {}\"}}", cmd)));
                        let out = run_debian_cmd(&state, cmd);
                        if let Ok(safe_out) = serde_json::to_string(&out) {
                            yield Ok(Event::default().data(format!("{{\"event\":\"tool_output\",\"data\":{}}}", safe_out)));
                        }
                    } else {
                        yield Ok(Event::default().data("{\"event\":\"tool_output\",\"data\":\"⛔ BLOCKED BY SENTINEL\"}".to_string()));
                    }
                }
            }
        } else {
             yield Ok(Event::default().data("{\"event\":\"error\",\"data\":\"API Connection Failed\"}".to_string()));
        }
    }
}
RUST

echo ">> Stage 7: Deploying Sentinel Module (sentinel.rs)..."
cat << 'RUST' > src/sentinel.rs
use std::{fs, process::Command};
use serde_json::Value;

pub fn check_vital_signs() -> Result<(), String> {
    // Termux API must be installed for this to work
    let output = Command::new("termux-battery-status").output();
    if let Ok(out) = output {
        if let Ok(json_str) = String::from_utf8(out.stdout) {
            if let Ok(status) = serde_json::from_str::<Value>(&json_str) {
                let pct = status["percentage"].as_i64().unwrap_or(100);
                let plugged = status["plugged"].as_str().unwrap_or("UNPLUGGED");
                if pct < 15 && plugged == "UNPLUGGED" { 
                    return Err(format!("BATTERY CRITICAL: {}% - PLUG IN NOW", pct)); 
                }
            }
        }
    }
    Ok(())
}

pub fn check_safety(cmd: &str) -> Result<(), String> {
    if fs::metadata("workspace/sentinel.py").is_err() { return Ok(()); }
    let output = Command::new("python3").arg("workspace/sentinel.py").arg(cmd).output();
    match output {
        Ok(out) => {
            if !out.status.success() { return Err("BLOCK".to_string()); }
            Ok(())
        },
        Err(_) => Ok(()) // Fail open if python missing
    }
}
RUST

echo ">> Stage 8: Deploying IDE (index.html)..."
cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>NEXUS PLATINUM IDE</title>
<style>
:root { --bg: #050505; --text: #00ff41; --dim: #008f11; --accent: #0088ff; }
body { margin:0; font-family:monospace; background:var(--bg); color:var(--text); height:100dvh; display:flex; flex-direction:column; overflow:hidden;}
header { padding:10px; border-bottom:1px solid var(--dim); display:flex; justify-content:space-between; align-items:center; background:#000; }
.tabs { display:flex; gap:15px; }
.tab-btn { background:none; border:none; color:var(--text); opacity:0.4; font-weight:bold; cursor:pointer; font-size:12px; }
.tab-btn.active { opacity:1; border-bottom:2px solid var(--text); }
.view { flex:1; display:none; overflow:hidden; }
.view.active { display:flex; flex-direction:column; }
#ide-view { display:flex; height:100%; position:relative; }
#file-panel { width:160px; background:#0a0a0a; border-right:1px solid var(--dim); overflow-y:auto; transition: margin-left 0.3s ease; flex-shrink:0; }
#file-panel.hidden { margin-left:-161px; } 
#editor-container { flex:1; display:flex; flex-direction:column; position:relative; min-width:0; }
#editor { flex:1; background:#111; color:#fff; padding:40px 15px 15px 15px; overflow-y:auto; outline:none; white-space:pre-wrap; font-size:14px; font-family: 'Courier New', monospace; }
#save-indicator { font-size:10px; color:var(--dim); padding:5px; text-align:right; position:absolute; bottom:5px; right:10px; pointer-events:none; }
#hamburger { position:absolute; top:10px; left:10px; font-size:20px; cursor:pointer; color:var(--accent); user-select:none; background:#111; padding:2px 6px; border-radius:4px; border:1px solid #333; z-index:10;}
#save-btn { position:absolute; top:10px; right:10px; padding:5px 10px; background:var(--accent); color:#000; border:none; cursor:pointer; font-size:12px; z-index:10; font-weight:bold; }
#chat-view, #term-view { padding:15px; overflow-y:auto; white-space:pre-wrap; flex:1; }
.u-msg { color:#fff; border-left:2px solid #444; padding-left:8px; margin-top:15px; font-weight:bold; }
.file-item { padding:8px; cursor:pointer; font-size:11px; border-bottom:1px solid #111; }
footer { padding:10px; border-top:1px solid var(--dim); display:flex; gap:10px; background:#000; padding-bottom:calc(10px + env(safe-area-inset-bottom)); }
input { flex:1; background:#111; color:var(--text); border:1px solid var(--dim); padding:12px; outline:none; font-size:16px; }
button { background:#222; color:var(--text); border:1px solid var(--dim); padding:10px 15px; }
</style>
</head>
<body>
<header>
    <div class="tabs">
        <button class="tab-btn active" onclick="openTab(event,'ide-view')">IDE</button>
        <button class="tab-btn" onclick="openTab(event,'chat-view')">BRAIN</button>
        <button class="tab-btn" onclick="openTab(event,'term-view')">MECHANIC</button>
    </div>
    <span id="telemetry" style="font-size:10px;">CPU: --%</span>
</header>
<div id="ide-view" class="view active">
    <div id="file-panel"></div>
    <div id="editor-container">
        <div id="hamburger">&#9776;</div>
        <div id="save-btn" onclick="saveCurrentFile()">SAVE</div>
        <div id="editor" contenteditable="true" oninput="triggerAutoSave()"></div>
        <div id="save-indicator">Ready</div>
    </div>
</div>
<div id="chat-view" class="view">>> NEXUS PLATINUM ONLINE.</div>
<div id="term-view" class="view">> MECHANIC INITIALIZED.</div>
<footer>
    <input type="text" id="prompt" placeholder="Execute..." onkeypress="if(event.key==='Enter') send()">
    <button onclick="send()">EXE</button>
</footer>
<script>
let currentFile=null; let saveTimeout=null; const filePanel=document.getElementById('file-panel');
document.getElementById('hamburger').onclick=()=>{filePanel.classList.toggle('hidden');};
function openTab(evt,tabId){
    document.querySelectorAll('.view').forEach(v=>v.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b=>b.classList.remove('active'));
    document.getElementById(tabId).classList.add('active');
    evt.currentTarget.classList.add('active');
    if(tabId==='ide-view') loadFiles();
}
async function loadFiles(){
    try {
        const res=await fetch('/files'); const files=await res.json();
        filePanel.innerHTML='<div style="padding:10px 5px; font-size:10px; color:#555; font-weight:bold;">WORKSPACE</div>';
        files.forEach(f=>{const div=document.createElement('div'); div.className='file-item'; div.textContent=f; div.onclick=()=>openFile(f); filePanel.appendChild(div); });
    } catch(e) {}
}
async function openFile(name){
    currentFile=name;
    const res=await fetch(`/load/${name}`);
    document.getElementById('editor').innerText=await res.text();
    document.getElementById('save-indicator').textContent=`Editing: ${name}`;
    if(window.innerWidth<600) filePanel.classList.add('hidden');
}
function triggerAutoSave(){
    if(!currentFile) return;
    document.getElementById('save-indicator').textContent="Typing...";
    clearTimeout(saveTimeout); saveTimeout=setTimeout(saveCurrentFile,2000);
}
async function saveCurrentFile(){
    if(!currentFile) {
        currentFile = prompt("Filename?");
        if(!currentFile) return;
    }
    const content=document.getElementById('editor').innerText;
    await fetch(`/save/${currentFile}`,{ method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({content}) });
    document.getElementById('save-indicator').textContent="Saved";
    loadFiles();
}
async function send(){
    const i=document.getElementById('prompt'); const val=i.value.trim(); if(!val) return;
    const chat=document.getElementById('chat-view'); const term=document.getElementById('term-view');
    chat.innerHTML+=`<div class="u-msg">USER> ${val}</div>`; i.value='';
    const wrap=document.createElement("div"); chat.appendChild(wrap);
    try{
        const res=await fetch('/ask',{ method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({prompt:val}) });
        const reader=res.body.getReader(); const decoder=new TextDecoder();
        while(true){
            const {done,value}=await reader.read(); if(done) break;
            decoder.decode(value).split('\n').forEach(line=>{
                if(line.startsWith('data: ')){
                    try{
                        const obj=JSON.parse(line.slice(6));
                        if(obj.event==="token") wrap.textContent+=obj.data;
                        else if(obj.event==="tool_output") {
                            term.innerHTML+=`<div style="color:var(--accent); margin:10px 0;">${obj.data}</div>`;
                            openTab({currentTarget:document.querySelectorAll('.tab-btn')[2]}, 'term-view');
                        }
                        chat.scrollTop=chat.scrollHeight; term.scrollTop=term.scrollHeight;
                    }catch(e){}
                }
            });
        }
    }catch(e){ chat.innerHTML+=`<div>ERROR</div>`; }
}
setInterval(()=>{
    fetch('/api/stats').then(r=>r.json()).then(d=>{document.getElementById('telemetry').innerText=`CPU: ${d.cpu_usage.toFixed(1)}%`; }).catch(()=>{});
},3000);
window.onload=loadFiles;
</script>
</body>
</html>
HTML

echo ">> Stage 9: Compiling and Launching NEXUS PLATINUM..."
cargo run --release
