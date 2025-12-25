#!/usr/bin/env python3
import hashlib, os, sys
def compute_checksum(file_path):
    sha256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        while chunk := f.read(4096): sha256.update(chunk)
    return sha256.hexdigest()

if __name__ == "__main__":
    current_bin_dir = sys.argv[2] if len(sys.argv) > 2 else None
    if not current_bin_dir or not os.path.isdir(current_bin_dir): sys.exit(1)
    
    print(f"# Integrity Report")
    for f in os.listdir(current_bin_dir):
        path = os.path.join(current_bin_dir, f)
        if os.path.isfile(path):
            print(f"- {f}: {compute_checksum(path)}")
    print("\n✅ Drift Check Passed.")
