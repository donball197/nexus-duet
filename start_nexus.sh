#!/bin/bash
# 1. Setup the Android Environment
export LD_LIBRARY_PATH=$PREFIX/lib
export RUST_LOG=info

# 2. Build if needed
cargo build -j1

# 3. Launch
./target/debug/nexus_singularity
