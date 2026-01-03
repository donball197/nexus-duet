#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# 🏛️ NEXUS-DUET V6.0: IN-PLACE UPGRADE INSTALLER
# ==============================================================================

INSTALL_DIR="$HOME/nexus-duet-native"
BACKUP_DIR="$HOME/nexus-duet-backup-$(date +%s)"
YELLOW='\033[1;33m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${CYAN}███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗${NC}"
echo -e "${GREEN}   IN-PLACE UPGRADE // TARGET: $INSTALL_DIR${NC}"
sleep 2

# 1. SAFETY BACKUP
echo -e "${YELLOW}🔵 [1/6] Creating Safety Backup...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    cp -r "$INSTALL_DIR" "$BACKUP_DIR"
else
    mkdir -p "$INSTALL_DIR"
fi
cd "$INSTALL_DIR"
mkdir -p backend/core backend/templates rust_agents/nexus_guard/src temp_media

# 2. KEY MIGRATION
echo -e "${YELLOW}🔵 [2/6] Migrating Secrets...${NC}"
if [ -f "athena.env" ] && [ ! -f "nexus.env" ]; then
    cp athena.env nexus.env
fi

# 3. ENVIRONMENT & RUST
echo -e "${YELLOW}🔵 [3/6] Updating Core Dependencies...${NC}"
if [ -n "$TERMUX_VERSION" ]; then
    pkg update -y
    pkg install -y rust clang cmake build-essential binutils termux-api
fi
if [ ! -d "venv" ]; then python3 -m venv venv; fi
source venv/bin/activate
pip install --upgrade pip wheel
pip install fastapi uvicorn jinja2 python-multipart google-genai tenacity numpy shapely maturin pillow

# 4. COMPILING RUST GUARD
echo -e "${YELLOW}🔵 [4/6] Compiling Rust Chaos Guard...${NC}"
cat << 'RUSTEOF' > rust_agents/nexus_guard/src/lib.rs
use pyo3::prelude::*;
#[pyfunction]
fn verify_safety(prompt: String) -> PyResult<bool> {
    let hazards = vec!["rm -rf", "mkfs", ":(){ :|:& };:", "chmod 777"];
    Ok(!hazards.iter().any(|&h| prompt.contains(h)))
}
#[pyfunction]
fn local_reasoning(prompt: String) -> PyResult<String> {
    Ok(format!("(T3 RUST) Logic validated: '{}'", prompt))
}
#[pymodule]
fn nexus_guard(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(verify_safety, m)?)?;
    m.add_function(wrap_pyfunction!(local_reasoning, m)?)?;
    Ok(())
}
RUSTEOF

cat << 'TOMLEOF' > rust_agents/nexus_guard/Cargo.toml
[package]
name = "nexus_guard"
version = "0.1.0"
edition = "2021"
[lib]
name = "nexus_guard"
crate-type = ["cdylib"]
[dependencies]
pyo3 = { version = "0.20.0", features = ["extension-module"] }
TOMLEOF

cd rust_agents/nexus_guard
maturin develop --release
cd ../..

# 5. UPGRADING PYTHON CORE
echo -e "${YELLOW}🔵 [5/6] Upgrading Python Core to v6.0...${NC}"

# DB
cat << 'PYEOF' > backend/core/db.py
import sqlite3
DB_PATH = "backend/tasks.db"
def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute('''CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_type TEXT, prompt TEXT, response TEXT,
        status TEXT DEFAULT 'PENDING', screenshot BLOB,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )''')
    conn.commit(); conn.close()
def db_panic():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("DELETE FROM tasks WHERE screenshot IS NOT NULL")
    conn.commit(); conn.close()
PYEOF

# Guard Wrapper
cat << 'PYEOF' > backend/core/guard.py
import logging
try:
    import nexus_guard
    RUST_ACTIVE = True
except ImportError:
    RUST_ACTIVE = False
def check_safety(prompt):
    return nexus_guard.verify_safety(prompt) if RUST_ACTIVE else "rm -rf" not in prompt
def local_think(prompt):
    return nexus_guard.local_reasoning(prompt) if RUST_ACTIVE else "(Python Local) OK."
PYEOF

# Router
cat << 'PYEOF' > backend/core/router.py
import os
from google import genai
from tenacity import retry, stop_after_attempt, wait_exponential
from PIL import Image
from .guard import check_safety, local_think
MODEL_CASCADE = ["gemini-3-pro-preview", "gemini-2.5-pro", "gemini-2.5-flash"]
class SmartRouter:
    def __init__(self):
        key = os.environ.get("GOOGLE_API_KEY")
        if not key: raise ValueError("GOOGLE_API_KEY missing")
        self.client = genai.Client(api_key=key)
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=2, max=10))
    def generate(self, prompt, image_path=None):
        if not check_safety(prompt): return "🛡️ BLOCKED: T3 Rust Guard detected hazard."
        local_ctx = local_think(prompt)
        inputs = [f"System Context: {local_ctx}\nUser: {prompt}"]
        if image_path and os.path.exists(image_path): inputs.append(Image.open(image_path))
        last_err = None
        for m in MODEL_CASCADE:
            try:
                res = self.client.models.generate_content(model=m, contents=inputs)
                return f"[{m}] {res.text}"
            except Exception as e: last_err = e
        raise last_err
PYEOF

# Main App
cat << 'PYEOF' > backend/main.py
import asyncio, logging, os, sqlite3
from fastapi import FastAPI, Request, Form, Response
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from contextlib import asynccontextmanager
from core.db import init_db, DB_PATH, db_panic
from core.router import SmartRouter

logging.basicConfig(filename="backend/system.log", level=logging.INFO)
router = None

async def worker():
    while True:
        conn = sqlite3.connect(DB_PATH)
        task = conn.execute("SELECT id, task_type, prompt FROM tasks WHERE status='PENDING' LIMIT 1").fetchone()
        conn.close()
        if task:
            t_id, t_type, t_prompt = task
            c = sqlite3.connect(DB_PATH)
            c.execute("UPDATE tasks SET status='PROCESSING' WHERE id=?", (t_id,))
            c.commit(); c.close()
            img_path = None
            if t_type == "VisionTask" or "look" in t_prompt.lower():
                shot = f"temp_media/shot_{t_id}.jpg"
                os.system(f"termux-screenshot -f {shot}")
                await asyncio.sleep(1.5)
                if os.path.exists(shot):
                    img_path = shot
                    with open(shot, 'rb') as f: blob = f.read()
                    c = sqlite3.connect(DB_PATH)
                    c.execute("UPDATE tasks SET screenshot=? WHERE id=?", (blob, t_id))
                    c.commit(); c.close()
            try:
                res = router.generate(t_prompt, img_path)
                c = sqlite3.connect(DB_PATH)
                c.execute("UPDATE tasks SET status='COMPLETED', response=? WHERE id=?", (res, t_id))
                c.commit(); c.close()
                if img_path: os.remove(img_path)
            except Exception as e:
                c = sqlite3.connect(DB_PATH)
                c.execute("UPDATE tasks SET status='FAILED', response=? WHERE id=?", (str(e), t_id))
                c.commit(); c.close()
        else: await asyncio.sleep(2)

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    global router
    try: router = SmartRouter(); asyncio.create_task(worker())
    except: pass
    yield

app = FastAPI(lifespan=lifespan)
templates = Jinja2Templates(directory="backend/templates")
@app.get("/", response_class=HTMLResponse)
async def dash(r: Request):
    c = sqlite3.connect(DB_PATH)
    tasks = c.execute("SELECT * FROM tasks ORDER BY id DESC LIMIT 10").fetchall()
    c.close()
    return templates.TemplateResponse("dashboard.html", {"request": r, "tasks": tasks})
@app.get("/img/{id}")
async def get_img(id: int):
    c = sqlite3.connect(DB_PATH)
    r = c.execute("SELECT screenshot FROM tasks WHERE id=?", (id,)).fetchone()
    c.close()
    return Response(content=r[0], media_type="image/jpeg") if r and r[0] else Response(status_code=404)
@app.post("/trigger")
async def trig(task_name: str = Form(...), prompt: str = Form(...)):
    c = sqlite3.connect(DB_PATH)
    c.execute("INSERT INTO tasks (task_type, prompt) VALUES (?,?)", (task_name, prompt))
    c.commit(); c.close()
    return {"status": "Queued"}
@app.post("/panic")
async def panic():
    db_panic(); os.system("./panic.sh"); return {"status": "Killed"}
PYEOF

# Dashboard
cat << 'HTMLEOF' > backend/templates/dashboard.html
<!DOCTYPE html>
<html>
<head>
<title>NEXUS OMEGA</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="4">
<style>
:root{--bg:#050505;--card:#111;--text:#00ff41;--fail:#ff003c;--dim:#444;}
body{background:var(--bg);color:var(--text);font-family:monospace;padding:10px;margin:0;}
.head{border-bottom:2px solid var(--text);padding-bottom:10px;margin-bottom:15px;display:flex;justify-content:space-between;}
.card{background:var(--card);border:1px solid var(--dim);padding:15px;margin-bottom:10px;border-radius:4px;}
input,select,button{width:100%;padding:12px;margin:5px 0;background:#000;border:1px solid var(--dim);color:#fff;}
button.run{background:var(--text);color:black;font-weight:bold;border:none;}
button.panic{background:var(--fail);color:white;border:1px solid red;font-weight:bold;margin-top:20px;}
.badge{font-size:0.7em;padding:2px 5px;border:1px solid var(--dim);}
.COMPLETED{color:var(--text);border-color:var(--text);} .PROCESSING{color:orange;} .FAILED{color:var(--fail);}
.modal{display:none;position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.95);z-index:99;}
.modal img{margin:10% auto;display:block;max-width:90%;border:2px solid var(--text);}
</style>
</head>
<body>
<div class="head"><div><strong>🏛️ NEXUS OMEGA</strong></div><div>STATUS: <span style="color:var(--text)">ACTIVE</span></div></div>
<div class="card">
<form action="/trigger" method="post">
<select name="task_name">
<option value="General">💬 Neural Uplink</option>
<option value="VisionTask">👁️ Vision Scan</option>
<option value="Code">💻 Logic Core</option>
</select>
<input name="prompt" placeholder="Directive...">
<button class="run" type="submit">EXECUTE</button>
</form>
</div>
{% for t in tasks %}
<div class="card">
<div style="display:flex;justify-content:space-between;margin-bottom:5px;">
<span><span class="badge {{t[4]}}">{{t[4]}}</span> <small>#{{t[0]}}</small></span>
{% if t[6] %}<button onclick="view({{t[0]}})" style="width:auto;padding:2px 8px;margin:0;">IMG</button>{% endif %}
</div>
<div style="color:#fff;margin-bottom:5px;">{{t[2]}}</div>
<div style="color:#888;font-size:0.9em;border-top:1px dashed #333;padding-top:5px;">{{t[3]}}</div>
</div>
{% endfor %}
<form action="/panic" method="post" onsubmit="return confirm('KILL SYSTEM?');"><button class="panic">🚨 KILL SWITCH</button></form>
<div id="vModal" class="modal" onclick="this.style.display='none'"><img id="mImg"></div>
<script>function view(id){document.getElementById('mImg').src='/img/'+id;document.getElementById('vModal').style.display='block';}</script>
</body>
</html>
HTMLEOF

# 6. CONFIG
echo -e "${YELLOW}🔵 [6/6] Finalizing Configuration...${NC}"
cat << 'EOF' > panic.sh
#!/data/data/com.termux/files/usr/bin/bash
pkill -f "uvicorn"
pkill -f "python"
fuser -k 8000/tcp 2>/dev/null
rm -rf temp_media/*
sqlite3 backend/tasks.db "DELETE FROM tasks WHERE screenshot IS NOT NULL;"
echo "🚨 PANIC EXECUTED."
