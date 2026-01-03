#!/bin/bash
termux-wake-lock
echo "[*] Wake Lock Acquired."

# Get current directory
PROJECT_DIR=$(pwd)
DASHBOARD_FILE="$PROJECT_DIR/frontend/dashboard.py"
LOG_FILE="$PROJECT_DIR/dashboard.log"

if [ -f "$DASHBOARD_FILE" ]; then
    echo "[*] Launching T7 Dashboard..."
    
    # Change to frontend directory so the app finds its local files
    cd "$PROJECT_DIR/frontend" || exit
    
    # Run dashboard and save log to the main folder
    nohup python3 -u dashboard.py > "$LOG_FILE" 2>&1 &
    
    # Return to main directory
    cd "$PROJECT_DIR"
    
    echo "[+] Dashboard launched in background."
    echo "[!] View logs with: cat dashboard.log"
else
    echo "[-] ERROR: dashboard.py not found at $DASHBOARD_FILE"
fi

echo "[!] Note: main.py is a CLI tool. Run it manually: python3 main.py 'Your Idea'"
