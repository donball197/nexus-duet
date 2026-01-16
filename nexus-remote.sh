#!/bin/bash
# Nexus Singularity: Secure Global Bridge

echo ">> REMOTE: Initializing secure internet tunnel..."

# 1. Ensure SSH is running
sshd

# 2. Launch Ngrok Tunnel
# This makes your local SSH (8022) available at a public URL
nohup ngrok tcp 8022 > ~/nexus_singularity/ngrok.log 2>&1 &

sleep 5
REMOTE_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

echo -e "\n\033[1;36m==========================================${NC}"
echo -e "      REMOTE ACCESS READY (GLOBAL)        "
echo -e "=========================================="
echo -e "URL: $REMOTE_URL"
echo -e "DUET COMMAND: ssh -p [PORT] [USER]@[HOST]"
echo -e "==========================================${NC}"
