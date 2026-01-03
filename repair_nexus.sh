#!/bin/bash
# ==============================================================================
# 🔧 NEXUS REPAIR PATCH (v1.1)
# Fixes "ModuleNotFoundError" by forcing absolute import paths
# ==============================================================================

PROJECT_DIR=$(pwd)
echo "🔵 [1/4] Stopping old processes..."
pkill -f "uvicorn"
pkill -f "python"

echo "🔵 [2/4] Patching Package Structure..."
# Create package markers so Python sees folders as modules
touch backend/__init__.py
touch backend/core/__init__.py

# Ensure temp directory exists for Vision
mkdir -p temp_media

echo "🔵 [3/4] Rewriting Core Files with Correct Imports..."

# 1. REWRITE MAIN.PY (Fixes 'from core.db' -> 'from backend.core.db')
cat << 'EOF' > backend/main.py
import asyncio, logging, os, sqlite3, signal
from fastapi import FastAPI, Request, Form, Response
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from contextlib import asynccontextmanager

# --- FIXED IMPORTS ---
from backend.core.db import init_db, DB_PATH, db_panic
from backend.core.router import SmartRouter

logging.basicConfig(filename="backend/system.log", level=logging.INFO, format='%(asctime)s %(message)s')
logger = logging.getLogger("NexusOmega")
router = None

async def worker():
    logger.info("👷 Omega Worker Active")
    while True:
        try:
            conn = sqlite3.connect(DB_PATH)
            task = conn.execute("SELECT id, task_type, prompt FROM tasks WHERE status='PENDING' LIMIT 1").fetchone()
            conn.close()
            
            if task:
                t_id, t_type, t_prompt = task
                
                # Set Status: Processing
                c = sqlite3.connect(DB_PATH)
                c.execute("UPDATE tasks SET status='PROCESSING' WHERE id=?", (t_id,))
                c.commit(); c.close()
                
                img_path = None
                
                # --- VISION LOGIC ---
                if t_type == "VisionTask":
                    shot = f"temp_media/shot_{t_id}.jpg"
                    # Capture Screenshot
                    os.system(f"termux-screenshot -f {shot}")
                    await asyncio.sleep(1.5)
                    
                    if os.path.exists(shot):
                        img_path = shot
                        with open(shot, 'rb') as f: blob = f.read()
                        c = sqlite3.connect(DB_PATH)
                        c.execute("UPDATE tasks SET screenshot=? WHERE id=?", (blob, t_id))
                        c.commit(); c.close()

                # --- INFERENCE LOGIC ---
                try:
                    res = router.generate(t_prompt, img_path)
                    
                    c = sqlite3.connect(DB_PATH)
                    c.execute("UPDATE tasks SET status='COMPLETED', response=? WHERE id=?", (res, t_id))
                    c.commit(); c.close()
                    
                    if img_path and os.path.exists(img_path): 
                        os.remove(img_path)
                        
                except Exception as e:
                    logger.error(f"Inference Error: {e}")
                    c = sqlite3.connect(DB_PATH)
                    c.execute("UPDATE tasks SET status='FAILED', response=? WHERE id=?", (str(e), t_id))
                    c.commit(); c.close()
            else:
                await asyncio.sleep(2)
        except Exception as e:
            logger.error(f"Worker Loop Critical Error: {e}")
            await asyncio.sleep(5)

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    global router
    try: 
        router = SmartRouter()
        asyncio.create_task(worker())
    except Exception as e: 
        logger.critical(f"Router Init Failed: {e}")
    yield

app = FastAPI(lifespan=lifespan)
# Ensure templates directory is absolute or correctly relative
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
    db_panic()
    os.system("./panic.sh")
    return {"status": "Killed"}
EOF

# 2. REWRITE ROUTER.PY (Fixes 'from .guard' -> 'from backend.core.guard')
cat << 'EOF' > backend/core/router.py
import os
import logging
from google import genai
from tenacity import retry, stop_after_attempt, wait_exponential
from PIL import Image

# --- FIXED IMPORTS ---
from backend.core.guard import check_safety, local_think

MODEL_CASCADE = ["gemini-3-pro-preview", "gemini-2.5-pro", "gemini-2.5-flash"]

class SmartRouter:
    def __init__(self):
        key = os.environ.get("GOOGLE_API_KEY")
        if not key: raise ValueError("GOOGLE_API_KEY missing in environment")
        self.client = genai.Client(api_key=key)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=2, max=10))
    def generate(self, prompt, image_path=None):
        # 1. Safety
        if not check_safety(prompt): 
            return "🛡️ BLOCKED: T3 Rust Guard detected malicious content."
        
        # 2. Local Context
        local_ctx = local_think(prompt)
        
        # 3. Cloud Cascade
        inputs = [f"System Context: {local_ctx}\nUser: {prompt}"]
        if image_path and os.path.exists(image_path):
            inputs.append(Image.open(image_path))

        last_err = None
        for m in MODEL_CASCADE:
            try:
                res = self.client.models.generate_content(model=m, contents=inputs)
                return f"[{m}] {res.text}"
            except Exception as e:
                last_err = e
        if last_err:
            raise last_err
        return "Error: No response generated."
EOF

echo "🔵 [4/4] Restarting Nexus Omega..."

# Make sure we are in the venv
source venv/bin/activate

# Start Uvicorn
nohup uvicorn backend.main:app --host 0.0.0.0 --port 8000 > backend/system.log 2>&1 &

echo "✅ REPAIR COMPLETE."
echo "   PID: $!"
echo "   Log Monitor: tail -f backend/system.log"
