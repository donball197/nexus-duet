#!/bin/bash
while true; do
  clear
  echo -e "\033[1;36m>> NEXUS SINGULARITY: HYBRID OPERATIONAL DASHBOARD <<\033[0m"
  echo "--------------------------------------------------------"
  
  # 1. System Vitals (The Physical)
  MEM_INFO=$(free -m | grep Mem)
  TOTAL=$(echo $MEM_INFO | awk '{print $2}')
  USED=$(echo $MEM_INFO | awk '{print $3}')
  SWAP=$(free -m | grep Swap | awk '{print $3}')
  echo -e "\033[1;33m[SYSTEM PHYSICAL]\033[0m"
  echo "RAM Usage:  $USED / $TOTAL MB ($(( USED * 100 / TOTAL ))%)"
  echo "Swap Used:  $SWAP MB (Buffer Security)"

  # 2. Project Vitals (The Logical)
  TARGET_SIZE=$(du -sh target/debug 2>/dev/null | awk '{print $1}')
  echo -e "\n\033[1;34m[FORGE STATUS]\033[0m"
  echo "Build Size: ${TARGET_SIZE:-0B} (Linking Progress)"

  # 3. Neural Vitals (The Semantic)
  # This checks your Sled database for indexed nodes
  if [ -d "nexus_memory" ]; then
    NODE_COUNT=$(ls nexus_memory/ | wc -l)
    echo -e "\n\033[1;32m[NEURAL ENGINE]\033[0m"
    echo "ONNX Model: MiniLM-L6-v2 (Active)"
    echo "Neural Nodes: $NODE_COUNT indexed vectors"
  else
    echo -e "\n\033[1;31m[NEURAL ENGINE]\033[0m"
    echo "Status: Awaiting first Semantic Sweep..."
  fi
  
  echo "--------------------------------------------------------"
  echo "Press Ctrl+C to exit HUD."
  sleep 5
done
