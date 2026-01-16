from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess

app = Flask(__name__)
# Explicitly allowing 127.0.0.1 to bypass Chrome's strict CORS hurdles
CORS(app, resources={r"/*": {"origins": "*"}})

@app.route('/execute', methods=['POST'])
def execute():
    data = request.json
    cmd = data.get('command', '')
    
    print(f"📡 SIGNAL RECEIVED: {cmd}") # This will show up in your terminal!

    if cmd.startswith('!'):
        system_cmd = cmd[1:]
        try:
            # Added -f to force vibration even if phone is in silent mode
            subprocess.run(f"{system_cmd} -f", shell=True)
            return jsonify({"status": "success"})
        except Exception as e:
            return jsonify({"status": "error", "output": str(e)})
    
    return jsonify({"status": "error", "output": "Invalid Prefix"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081, debug=False)
