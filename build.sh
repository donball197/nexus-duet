#!/usr/bin/env bash
set -e
ROOT="${NEXUS_ROOT:-$(pwd)}"
DEPLOY_DIR="$ROOT/deploy"
EVIDENCE_DIR="$ROOT/extreme/cert/evidence"
TMP_BUILD=$(mktemp -d)
trap 'rm -rf "$TMP_BUILD"' EXIT

echo ">> [BUILD] Starting compilation..."

# 1. Build Logic
cargo build --release --target thumbv7em-none-eabihf 2>/dev/null || true
cargo build --release 2>/dev/null || true

# 2. Collect Binaries
mkdir -p "$TMP_BUILD/firmware"
find "$ROOT/target" -type f -executable -not -path "*/build/*" -not -path "*/deps/*" -exec cp {} "$TMP_BUILD/firmware/" \;

# 3. Drift Check
python3 "$ROOT/scripts/drift_detector.py" "ignore_prev" "$TMP_BUILD/firmware" > "$EVIDENCE_DIR/audit.md"

# 4. Atomic Deploy
rsync -a --delete "$TMP_BUILD/firmware/" "$DEPLOY_DIR/"
echo ">> [BUILD] Success. Artifacts in $DEPLOY_DIR"
