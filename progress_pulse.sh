#!/bin/bash
# Nexus Singularity: Haptic Progress Sentinel

echo ">> SENTINEL: Haptic Pulse Active. Monitoring Crate Assembly..."

LAST_PULSE=0
# Monitor the number of compiled dependency files in the target directory
DEPS_DIR="./target/debug/deps"

while true; do
    # Count the number of unique compiled crates (.d files)
    CURRENT_COUNT=$(ls -1 $DEPS_DIR/*.d 2>/dev/null | wc -l)
    
    # Calculate progress toward the 254-crate goal
    # Check if we've crossed a 25-crate threshold
    THRESHOLD=$(( (CURRENT_COUNT / 25) * 25 ))

    if [ "$THRESHOLD" -gt "$LAST_PULSE" ] && [ "$THRESHOLD" -le 250 ]; then
        echo -e "\n>> MILESTONE REACHED: $THRESHOLD Crates Compiled"
        
        # Trigger haptic pulse (100ms for milestones)
        termux-vibrate -d 200
        LAST_PULSE=$THRESHOLD
    fi

    # Final "Success" vibration when reaching the birth of the binary
    if [ -f "./target/debug/nexus_singularity" ]; then
        echo ">> BUILD COMPLETE: Final Pulse Triggered."
        termux-vibrate -d 1000
        termux-notification --title "Nexus Singularity" --content "Singularity is Live: 254 Crates Integrated"
        break
    fi

    sleep 10 # Poll every 10 seconds to preserve Motorola G battery
done
