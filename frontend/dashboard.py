from flask import Flask, render_template
import os
import datetime
import sqlite3

app = Flask(__name__)
DB_PATH = "/root/nexus-duet/athenafusionx.db"

def get_status():
    # Detects if T1 is listening on Port 18080
    t1_check = os.system("lsof -Pi :18080 -sTCP:LISTEN -t >/dev/null")
    t1_status = "ONLINE" if t1_check == 0 else "OFFLINE"
    t1_class = "online" if t1_status == "ONLINE" else "offline"
    
    # Check Database Tasks
    try:
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM tasks WHERE status='pending'")
        pending = cur.fetchone()[0]
        conn.close()
    except:
        pending = "0"
        
    return t1_status, t1_class, pending

@app.route('/')
def index():
    t1_status, t1_class, pending = get_status()
    now = datetime.datetime.now().strftime("%H:%M:%S")
    return render_template('index.html', t1_status=t1_status, t1_class=t1_class, 
                           pending_tasks=pending, timestamp=now)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
