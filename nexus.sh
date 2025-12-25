#!/bin/bash
echo "🚀 Starting NEXUS-DUET v2.0 (Self-Healing)"
echo "   [+] Mode: Cloud-Only Releases"
echo "   [+] Sync: Auto-Rebase Active"

# Loop forever watching for changes
while true; do
  echo "👀 Watching for changes..."
  # Watch specifically for Rust files to avoid false triggers
  inotifywait -q -e modify,create,delete,move ./nexus-core/src/main.rs ./Cargo.toml 2>/dev/null
  
  echo "------------------------------------------------"
  echo "✏️ Change detected! Starting pipeline..."
  
  # 1. Build locally to check for errors
  if cargo build --release; then
      echo "✅ Local Build Success"
      
      # 2. Add and Commit
      git add .
      git commit -m "Auto-update: $(date '+%H:%M:%S')"
      
      # 3. SELF-HEALING SYNC (The Fix)
      echo "🔄 Syncing with Cloud Robot..."
      git pull --rebase origin main
      
      # 4. Push
      echo "🚀 Pushing to GitHub..."
      if git push origin main; then
         echo "✅ Success! Cloud Brain is now deploying."
      else
         echo "❌ Push Failed (Network or Conflict issues)"
      fi
  else
      echo "⚠️ Build Failed. Fix your code!"
  fi
  
  echo "------------------------------------------------"
  # Small delay to let things settle
  sleep 2
done
