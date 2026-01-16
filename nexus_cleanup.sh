#!/bin/bash
# Nexus Singularity: Auto-Lock & Session Cleanup

echo ">> SENTINEL: Monitoring connection for security..."

while true; do
    # 1. Check if SSH tunnel is active
    # (Matches current Ngrok/SSH connections)
    TUNNEL_ACTIVE=$(pgrep -f "sshd")

    if [ -z "$TUNNEL_ACTIVE" ]; then
        echo ">> SECURITY: No active connection. Commencing auto-lock in 10m..."
        sleep 600 # 10 minute grace period

        # Check again after 10m
        TUNNEL_RECONNECTED=$(pgrep -f "sshd")
        if [ -z "$TUNNEL_RECONNECTED" ]; then
             echo ">> LOCKING: Connection lost. Encrypting all active portfolios..."
             for client in ~/nexus_singularity/portfolio/*; do
                 [ -d "$client" ] && bash ~/nexus_singularity/nexus-lock.sh "$(basename "$client")"
             done
             termux-notification --title "Nexus Security" --content "Inactivity detected. All vaults locked."
        fi
    fi
    sleep 60 # Check every minute
done
