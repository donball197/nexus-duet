import subprocess
import time
import requests
import json

def get_temp():
    # Queries the Android battery hardware for thermal data
    res = subprocess.check_output(['termux-battery-status']).decode('utf-8')
    data = json.loads(res)
    # Convert from 350 to 35.0
    return data['temperature'] / 10.0

while True:
    try:
        current_temp = get_temp()
        # Pushes the data to your Dashboard via the Bridge
        payload = {"command": f"LOG: Temperature at {current_temp}°C"}
        requests.post('http://127.0.0.1:8081/execute', json=payload)
        print(f"📡 Pulse Sent: {current_temp}°C")
    except Exception as e:
        print(f"⚠️ Pulse Failed: {e}")
    
    time.sleep(10) # Updates every 10 seconds
