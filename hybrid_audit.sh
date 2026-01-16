#!/bin/bash
echo "--- HYBRID PATH AUDIT START ---"

# 1. Check ONNX Runtime Location
echo -e "\n[1] Checking ONNX Libs:"
if [ -d "$ORT_LIB_LOCATION" ]; then
    echo "SUCCESS: ORT_LIB_LOCATION found at $ORT_LIB_LOCATION"
    ls -1 "$ORT_LIB_LOCATION" | grep ".so" | head -n 3
else
    echo "ERROR: ORT_LIB_LOCATION not found!"
fi

# 2. Check for libc++_shared.so (The Linker's "Ghost")
echo -e "\n[2] Locating libc++_shared.so:"
find /data/data/com.termux/files/usr/lib /usr/lib -name "libc++_shared.so" 2>/dev/null

# 3. Verify Linker Paths
echo -e "\n[3] Active LD_LIBRARY_PATH:"
echo $LD_LIBRARY_PATH | tr ':' '\n'

# 4. Check for Cargo/Rust context
echo -e "\n[4] Rust Environment:"
cargo --version || echo "ERROR: Cargo not found in current shell!"

echo -e "\n--- HYBRID PATH AUDIT END ---"
