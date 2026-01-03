import socketio
import requests
import time
import os
import json
import glob

CHAT_SERVER = 'http://localhost:5000'
BRAIN_SERVER = 'http://localhost:8000/trigger'
BOT_NAME = 'Nexus_Omega'

sio = socketio.Client()

@sio.event
def connect():
    print("✅ Visual Bridge connected!")
    sio.emit('set_username', {'username': BOT_NAME})

@sio.event
def new_message(data):
    if data['username'] == BOT_NAME: return
    
    msg = data['message'].lower()
    if "look" in msg:
        sio.emit('send_message', {'message': "📸 Capturing image..."})
        try:
            requests.post(BRAIN_SERVER, data={"task_name": "VisionTask", "prompt": "Identify objects."})
            time.sleep(12) 
            
            # The image path the browser will use (using the new route we made)
            img_url = "http://localhost:5000/captures/final_check.jpg"
            
            # Send the image as HTML
            html_msg = f'<br><img src="{img_url}" style="width:100%; border-radius:10px; margin-top:10px;">'
            sio.emit('send_message', {'message': f"👁️ Analysis Complete! {html_msg}"})
            
        except Exception as e:
            sio.emit('send_message', {'message': f"⚠️ Error: {e}"})

if __name__ == '__main__':
    sio.connect(CHAT_SERVER)
    sio.wait()
