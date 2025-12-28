import sys
import os
import hashlib

def calculate_sha256(filepath):
    """Reads a file in chunks and calculates its SHA256 hash."""
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        # Read in 4K chunks to handle large files efficiently
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def main():
    # 1. Check Arguments
    if len(sys.argv) < 3:
        print("Usage: python3 drift_detector.py <mode> <directory>")
        sys.exit(1)

    mode = sys.argv[1]
    directory = sys.argv[2]

    if not os.path.exists(directory):
        print(f"Error: Directory '{directory}' not found.")
        sys.exit(1)

    # 2. Scan and Hash
    # We walk through the directory to find all files
    results = []
    for root, _, files in os.walk(directory):
        for filename in files:
            filepath = os.path.join(root, filename)
            file_hash = calculate_sha256(filepath)
            results.append((filename, file_hash))

    # 3. Output based on mode
    if mode == "ignore_prev":
        print("# Drift Detection Report")
        print("| Filename | SHA256 Hash |")
        print("|---|---|")
        for name, h in results:
            print(f"| {name} | `{h}` |")

if __name__ == "__main__":
    main()
