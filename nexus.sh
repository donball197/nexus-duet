# --- LOCAL MODE (Runs only on Chromebook) ---
echo "💻 LOCAL MODE: AUTONOMOUS WATCHER v3.1 (Fixed)"
echo "   [+] Watcher Active. Waiting for you..."

while true; do
  # Wait for file changes
  inotifywait -q -e modify,create,delete,move ./nexus-core/src/main.rs ./Cargo.toml 2>/dev/null
  
  echo "✏️ Change detected! Syncing..."
  
  # 1. Add and Commit first
  git add .
  git commit -m "Auto-update: $(date '+%H:%M:%S')"
  
  echo "🚀 Pushing to Cloud..."
  
  # 2. Try to push. Only pull if the push FAILS.
  if git push origin main; then
     echo "✅ Upload Successful."
  else
     echo "⚠️ Push failed (Remote changes?). Healing..."
     # NOW it is safe to pull, because we expect a re-trigger anyway, 
     # but it won't happen endlessly if the push succeeds next time.
     git pull --rebase origin main
     git push origin main
  fi
  
  echo "------------------------------------------------"
  # Increased sleep to let the file system settle
  sleep 5
done
