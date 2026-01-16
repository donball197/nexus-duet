#!/bin/bash
TARGET="./target/debug/nexus_singularity"
echo ">> STANDING GUARD. WAITING FOR BINARY ASSEMBLY..."

until [ -f "$TARGET" ]; do
  # Check every 10 seconds to save CPU/RAM
  sleep 10
done

echo -e "\n\033[1;32m>> BIRTH DETECTED: NEXUS_SINGULARITY IS LIVE!\033[0m"
ls -lh "$TARGET"

# Use Termux API to alert you if you're not looking at the screen
termux-vibrate -d 500
termux-notification --title "Singularity Update" --content "Binary Assembly Complete"
