#!/bin/bash
# Nexus Singularity: Birth Notification Sentinel

TARGET="./target/debug/nexus_singularity"
echo ">> STANDING GUARD. WAITING FOR BINARY ASSEMBLY..."

until [ -f "$TARGET" ]; do
  sleep 15 # Poll every 15 seconds to save battery
done

# Trigger Android System Notification
termux-notification --title "Nexus Singularity" --content "Build Complete: Binary is Live" --id "nexus_birth"

# Trigger Physical Haptics
termux-vibrate -d 1000
echo -e "\n\033[1;32m>> BIRTH DETECTED: NEXUS_SINGULARITY IS LIVE!\033[0m"
