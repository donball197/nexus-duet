#!/data/data/com.termux/files/usr/bin/bash
if [ -f "nexus.env" ]; then source nexus.env; elif [ -f "athena.env" ]; then source athena.env; fi
if [ -z "$GOOGLE_API_KEY" ]; then echo "⚠️ API KEY MISSING"; exit 1; fi

./panic.sh > /dev/null 2>&1
source venv/bin/activate

echo "🚀 NEXUS OMEGA ONLINE"
echo "   📱 UI: http://localhost:8000"

# CHANGE: Go inside backend so imports are simple
cd backend
# Run main.py directly
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > system.log 2>&1 &
