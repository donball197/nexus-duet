#!/bin/bash

# --- CLOUD MODE (Runs only on GitHub Actions) ---
if [ "$CI" = "true" ]; then
    echo "☁️ CLOUD DETECTED: Starting Production Build..."
    
    cargo build --release
    tar -czf nexus-core.tar.gz -C target/release nexus-core
    
    VERSION="v0.2.$(date +%s)"
    echo "📦 Creating Release $VERSION..."
    gh release create "$VERSION" nexus-core.tar.gz --title "Production Release $VERSION" --notes "Automated Build from Level 4 Pipeline"
    
    echo "✅ Release Published Successfully."
    exit 0
fi

# --- LOCAL MODE (Runs only on Chromebook) ---
echo "💻 LOCAL MODE: AUTONOMOUS WATCHER v4.0 (Polling)"
echo "   [+] System Active. Scanning for changes every 5 seconds..."

while true; do
  # CHECK: Ask Git if there are any changes (modified, new, or deleted files)
  if [ -n "$(git status --porcelain)" ]; then
      echo "------------------------------------------------"
      echo "✏️  Work detected! Syncing..."
      
      # 1. Add and Commit
      git add .
      git commit -m "Auto-update: $(date '+%H:%M:%S')"
      
      echo "🚀 Pushing to Cloud..."
      
      # 2. Push with Auto-Healing
      if git push origin main; then
         echo "✅ Upload Successful."
      else
         echo "⚠️ Push failed. Healing..."
         git pull --rebase origin main
         git push origin main
      fi
      echo "✅ Done. Returning to watch mode."
  fi
  
  # Wait 5 seconds before checking again (Saves CPU)
  sleep 5
done
