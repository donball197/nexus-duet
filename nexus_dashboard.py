import http.server
import socketserver
import subprocess
import json
import urllib.parse

PORT = 8081

class NexusHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/api/onboard':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')
            params = urllib.parse.parse_qs(post_data)
            client_name = params.get('name', [''])[0]
            
            if client_name:
                # Execute your existing onboarding logic
                subprocess.run(["bash", "/data/data/com.termux/files/home/nexus_singularity/create_client.sh", client_name])
                self.send_response(200)
                self.end_headers()
                self.wfile.write(f"Client {client_name} provisioned successfully.".encode())
            else:
                self.send_response(400)
                self.end_headers()

    def do_GET(self):
        if self.path == '/api/status':
            temp = subprocess.getoutput("termux-battery-status | jq -r '.temperature'")
            ram = subprocess.getoutput("free -m | awk '/Mem:/ { print $3 \"/\" $2 \"MB\" }'")
            clients = subprocess.getoutput("ls /data/data/com.termux/files/home/nexus_singularity/portfolio").split('\n')
            data = {"temp": temp, "ram": ram, "clients": [c for c in clients if c]}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        else:
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html = """
            <html>
            <head><title>Nexus Pro Dashboard</title>
            <style>
                body { font-family: 'Courier New', monospace; background: #0a0a0a; color: #00ff41; padding: 20px; }
                .card { border: 1px solid #00ff41; padding: 20px; margin-bottom: 20px; box-shadow: 0 0 10px #00ff41; }
                input { background: #000; color: #00ff41; border: 1px solid #00ff41; padding: 5px; }
                button { background: #00ff41; color: #000; border: none; padding: 5px 15px; cursor: pointer; font-weight: bold; }
                h1, h2 { color: #00d4ff; text-transform: uppercase; }
            </style>
            </head>
            <body>
                <h1>NEXUS SINGULARITY :: SYSTEM OPS</h1>
                <div class="card">
                    <h2>Node Vitals</h2>
                    <p id="vitals">Scanning hardware...</p>
                </div>
                <div class="card">
                    <h2>Client Onboarding</h2>
                    <form action="/api/onboard" method="post">
                        <input type="text" name="name" placeholder="Client Name" required>
                        <button type="submit">PROVISION SLOT</button>
                    </form>
                </div>
                <div class="card">
                    <h2>Active Portfolio Slots</h2>
                    <ul id="clients"></ul>
                </div>
                <script>
                    function updateStatus() {
                        fetch('/api/status').then(r => r.json()).then(data => {
                            document.getElementById('vitals').innerText = `TEMP: ${data.temp}°C | RAM: ${data.ram}`;
                            document.getElementById('clients').innerHTML = data.clients.map(c => `<li>[TENANT] ${c}</li>`).join('');
                        });
                    }
                    setInterval(updateStatus, 5000);
                    updateStatus();
                </script>
            </body>
            </html>
            """
            self.wfile.write(html.encode())

with socketserver.TCPServer(("", PORT), NexusHandler) as httpd:
    httpd.serve_forever()
