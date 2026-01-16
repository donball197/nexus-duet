#!/bin/bash
# Nexus Singularity: Master Ecosystem Launch

echo ">> MASTER: Launching all core systems..."

# 1. Start the AI Server Node
nohup ~/nexus_singularity/nexus_singularity > server.log 2>&1 &
echo ">> [1/4] AI Server Node: ONLINE"

# 2. Start the Health Sentinel
nohup ~/nexus_singularity/nexus_health.sh > health.log 2>&1 &
echo ">> [2/4] Health Sentinel: ONLINE"

# 3. Start Thermal Protection
nohup ~/nexus_singularity/thermal_throttle.sh > throttle.log 2>&1 &
echo ">> [3/4] Thermal Protection: ENGAGED"

# 4. Start Singularity Voice
nohup ~/nexus_singularity/voice_alert.sh > voice.log 2>&1 &
echo ">> [4/4] Singularity Voice: ACTIVE"

termux-wake-lock # Prevent Android sleep
echo -e "\n>> SUCCESS: Full Singularity Ecosystem is running."
nohup python ~/nexus_singularity/nexus_dashboard.py > dashboard.log 2>&1 &
>> [5/5] Client Web Dashboard: ONLINE
nohup ~/nexus_singularity/nexus_cleanup.sh > cleanup.log 2>&1 &
>> [6/6] Security Cleanup Sentinel: ACTIVE
