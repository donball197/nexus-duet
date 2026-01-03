#!/bin/bash
# ==============================================================================
# 🔧 NEXUS PATH FIXER
# Forces Python to recognize the project root using PYTHONPATH
# ==============================================================================

PROJECT_DIR=$(pwd)
echo "🔵 [1/3] Stopping existing processes..."
pkill -f "uvicorn"
pkill -f "python"

echo "🔵 [2/3] Verifying Directory Structure..."
# Explicitly ensure the directories exist
mkdir -p backend/core
mkdir -p backend/templates

# Re-create package markers so Python treats folders as packages
touch backend/__init__.py
touch backend/core/__init__.py

echo "🔵 [3/3] rewriting Launcher with PYTHONPATH..."

# We rewrite the launcher to explicitly export PYTHONPATH
cat << 'EOF' > launch_omega.sh
#!/data/data/com.termux/files/usr/bin/bash

# 1. Get current directory
PROJECT_ROOT=$(pwd)

# 2. Force Python to look in the current directory for modules
export PYTHONPATH=$PROJECT_ROOT

# 3. Load Secrets
if [ -f "nexus.env" ]; then source nexus.env; fi
if [ -z "$GOOGLE_API_KEY" ]; then 
    echo "⚠️ API KEY MISSING in nexus.env"
fi

# 4. Clean Start
./panic.sh > /dev/null 2>&1
source venv/bin/activate

echo "🚀 NEXUS OMEGA ONLINE"
echo "   📂 Root: $PROJECT_ROOT"
echo "   📱 UI:   http://localhost:8000"

# 5. Start Uvicorn
# We run it as a module (-m) or direct script, but PYTHONPATH fixes the import resolution
nohup uvicorn backend.main:app --host 0.0.0.0 --port 8000 > backend/system.log 2>&1 &

PID=$!
echo "   ✅ PID: $PID"
EOF

chmod +x launch_omega.sh

echo "✅ PATCH COMPLETE."
echo "--------------------------------------"
echo "1. Run the new launcher:"
echo "   ./launch_omega.sh"
echo ""
echo "2. Watch the logs:"
echo "   tail -f backend/system.log"
echo "--------------------------------------"
