#!/bin/bash
# Nexus Singularity [Phase 5]: Production Ignition

# 1. Force System Library Discovery
export LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib:$LD_LIBRARY_PATH
export ORT_STRATEGY=system

# 2. Launch the Engine with Performance Logging
echo ">> IGNITION: Launching Nexus Singularity Engine..."
RUST_LOG=info ./target/debug/nexus_singularity
