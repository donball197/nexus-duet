#!/bin/bash

# --- CLOUD MODE (Runs only on GitHub) ---
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
echo "💻 LOCAL MODE: AUTONOMOUS WATCHER v3.0"
echo "   [+] Watcher Active. Waiting for you..."

while true; do
  # Wait for file changes
  inotifywait -q -e modify,create,delete,move ./nexus-core/src/main.rs ./Cargo.toml 2>/dev/null
  
  echo "✏️ Change detected! Syncing..."
  
  # Self-Healing: Pull changes first to avoid conflicts
  git pull --rebase origin main
  
  # Push the changes
  git add .
  git commit -m "Auto-update: $(date '+%H:%M:%S')"
  
  echo "🚀 Pushing to Cloud..."
  if git push origin main; then
     echo "✅ Upload Successful. Cloud Brain taking over."
  else
     echo "⚠️ Push failed (Network issue?)"
  fi
  
  echo "------------------------------------------------"
  sleep 2
done
