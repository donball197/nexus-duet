#!/bin/bash
# Nexus Singularity: Local Network Bridge

# 1. Identify Local IP Address
LOCAL_IP=$(ifconfig wlan0 | grep 'inet ' | awk '{print $2}')
PORT=8080

echo ">> BRIDGE: Local IP detected at $LOCAL_IP"
echo ">> BRIDGE: Reconfiguring server to listen on $LOCAL_IP:$PORT..."

# 2. Kill the existing local-only server in Session 4
pkill -9 nexus_singularity

# 3. Launch the Network-Aware Server
# We use 0.0.0.0 to bind to all available interfaces
export LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib:$LD_LIBRARY_PATH
export ORT_STRATEGY=system

echo ">> IGNITION: Launching Global Node..."
nohup ./target/debug/nexus_singularity --host 0.0.0.0 --port $PORT > server.log 2>&1 &

echo -e "\n\033[1;32m>> SUCCESS: Node is now reachable at http://$LOCAL_IP:$PORT\033[0m"
echo ">> Use this URL on your Lenovo Duet to access this Neural Core."
