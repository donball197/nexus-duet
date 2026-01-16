import http.server
import socketserver
import json
import subprocess
import os
import shutil

class NexusHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/stats':
            # Battery Check (Universal Android/Termux command)
            try:
                bat_output = subprocess.getoutput("termux-battery-status")
                battery = json.loads(bat_output).get('percentage', 0)
            except:
                battery = "N/A"

            # Universal Storage %
            total, used, free = shutil.disk_usage("/")
            storage_pct = round((used / total) * 100, 1)
            
            stats = {
                'cpu': battery, # We'll repurpose the CPU label for Battery
                'storage': storage_pct
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(stats).encode())
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/api/exec':
            length = int(self.headers['Content-Length'])
            data = json.loads(self.rfile.read(length))
            cmd = data.get('command')
            output = subprocess.getoutput(cmd)
            self.send_response(200)
            self.end_headers()
            self.wfile.write(output.encode())
        else:
            super().do_POST()

PORT = 8000
print("NEXUS MOBILE: Monitoring Active on Port " + str(PORT))
socketserver.TCPServer(("", PORT), NexusHandler).serve_forever()
