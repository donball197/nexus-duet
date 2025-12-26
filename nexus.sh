#!/bin/bash

# --- CLOUD MODE (Runs only on GitHub Actions) ---
if [ "$CI" = "true" ]; then
    echo "☁️ CLOUD DETECTED: Starting Production Build..."
    
    # 1. Build the binary
    cargo build --release
    
    # 2. Package it
    # We assume the binary name in Cargo.toml is "nexus-core"
    tar -czf nexus-core.tar.gz -C target/release nexus-core
    
    # 3. Create Release
    VERSION="v0.2.$(date +%s)"
    
    echo "📦 Creating Release $VERSION..."
    gh release create "$VERSION" nexus-core.tar.gz --title "Production Release $VERSION" --notes "Automated Build from Level 4 Pipeline"
    
    echo "✅ Release Published Successfully. Shutting down Cloud Brain."
    exit 0
fi

# --- LOCAL MODE (Runs only on Chromebook) ---
echo "💻 LOCAL MODE: AUTONOMOUS WATCHER v3.2 (Re-calibrated)"
echo "   [+] Watcher Active. Waiting for you..."

while true; do
  # Wait for file changes
  # UPDATED PATH: We removed 'nexus-core/' because files are now at root
  inotifywait -q -e modify,create,delete,move ./src/main.rs ./Cargo.toml 2>/dev/null
  
  echo "✏️ Change detected! Syncing..."
  
  # 1. Add and Commit first
  git add .
  git commit -m "Auto-update: $(date '+%H:%M:%S')"
  
  echo "🚀 Pushing to Cloud..."
  
  # 2. Try to push. Only pull if the push FAILS.
  if git push origin main; then
     echo "✅ Upload Successful. Cloud Brain taking over."
  else
     echo "⚠️ Push failed (Remote changes detected). Healing..."
     git pull --rebase origin main
     git push origin main
  fi
  
  echo "------------------------------------------------"
  sleep 5
done
