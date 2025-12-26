#!/bin/bash

# --- CLOUD MODE (Runs only on GitHub Actions) ---
if [ "$CI" = "true" ]; then
    echo "☁️ CLOUD DETECTED: Starting Production Build..."
    
    # 1. Build the binary
    cargo build --release
    
    # 2. Package it (Create the file you can download)
    tar -czf nexus-core.tar.gz -C target/release nexus-core
    
    # 3. Create Release using the GitHub Token
    # We use the date as a unique version number
    VERSION="v0.2.$(date +%s)"
    
    echo "📦 Creating Release $VERSION..."
    gh release create "$VERSION" nexus-core.tar.gz --title "Production Release $VERSION" --notes "Automated Build from Level 4 Pipeline"
    
    echo "✅ Release Published Successfully. Shutting down Cloud Brain."
    exit 0
fi

# --- LOCAL MODE (Runs only on Chromebook) ---
echo "💻 LOCAL MODE: AUTONOMOUS WATCHER v3.1 (Fixed)"
echo "   [+] Watcher Active. Waiting for you..."

while true; do
  # Wait for file changes
  # Monitors main.rs and Cargo.toml for any modification
  inotifywait -q -e modify,create,delete,move ./nexus-core/src/main.rs ./Cargo.toml 2>/dev/null
  
  echo "✏️ Change detected! Syncing..."
  
  # 1. Add and Commit first
  git add .
  git commit -m "Auto-update: $(date '+%H:%M:%S')"
  
  echo "🚀 Pushing to Cloud..."
  
  # 2. Try to push. Only pull if the push FAILS.
  # This prevents the infinite loop caused by unconditional pulling.
  if git push origin main; then
     echo "✅ Upload Successful. Cloud Brain taking over."
  else
     echo "⚠️ Push failed (Remote changes detected). Healing..."
     # NOW it is safe to pull/rebase, because we need to sync with the remote.
     git pull --rebase origin main
     # Retry the push after rebase
     git push origin main
  fi
  
  echo "------------------------------------------------"
  # Sleep for 5 seconds to let the file system settle and prevent rapid-fire triggers
  sleep 5
done
