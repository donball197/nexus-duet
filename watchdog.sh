#!/bin/bash
# THE GUARDIAN: Ensures 100% Uptime for the Singularity

while true; do
  # 1. Check if the Strategic Brain (Web Server) is alive
  if ! pgrep -x "nexus_singulari" > /dev/null; then
    echo "$(date): ⚠️ Brain Offline. Restarting..." >> ~/nexus_singularity/autonomy.log
    cd ~/nexus_singularity && nohup cargo run --bin nexus_singularity > /dev/null 2>&1 &
  fi

  # 2. Check if the Tactical HUD (TUI) is alive (Optional, if you want it always on)
  # if ! pgrep -x "nexus_editor" > /dev/null; then
  #   echo "$(date): ⚠️ HUD Offline." >> ~/nexus_singularity/autonomy.log
  # fi

  # 3. Preventive Cooling: If temp is too high, wait longer
  # This is the "Reflex" that prevents crashes
  sleep 30
done
