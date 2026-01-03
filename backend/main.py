import asyncio, logging, os, sqlite3, sys
from fastapi import FastAPI, Request, Form, Response
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from contextlib import asynccontextmanager

# FIX: Import directly from neighbor folder 'core'
from core.db import init_db, DB_PATH, db_panic
from core.router import SmartRouter

logging.basicConfig(filename="system.log", level=logging.INFO)
router = None

async def worker():
    while True:
        try:
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
                    # Save image to parent's temp folder
                    shot = f"../temp_media/shot_{t_id}.jpg"
                    os.system(f"termux-camera-photo -c 0 {shot}")
                    await asyncio.sleep(2.0)
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
            else:
                await asyncio.sleep(2)
        except Exception as e:
            await asyncio.sleep(5)

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    global router
    try: router = SmartRouter(); asyncio.create_task(worker())
    except: pass
    yield

app = FastAPI(lifespan=lifespan)
templates = Jinja2Templates(directory="templates")

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
    db_panic(); os.system("../panic.sh"); return {"status": "Killed"}
