#!/bin/bash

# --- CONFIGURATION ---
REPO_DIR="$HOME/athenafusionx"
CONTAINER_NAME="athenafusionx_ollama_1"
BACKEND_CONTAINER="athenafusionx_backend_1"
MODEL_FILE="pirate.gguf"   # The file we expect from Colab
CUSTOM_MODEL_NAME="my-custom-model"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Nexus-Duet Deployment Manager Active ===${NC}"
echo -e "${BLUE}Watching for code changes and new brain models...${NC}"

while true; do
    cd "$REPO_DIR" || exit

    # 1. CHECK FOR CODE UPDATES (From GitHub)
    # We fetch silently to check if local is behind remote
    git fetch origin
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo -e "${YELLOW}[UPDATE DETECTED] Pulling new code from GitHub...${NC}"
        git pull
        
        echo -e "${YELLOW}Rebuilding Backend...${NC}"
        docker-compose up -d --build backend
        echo -e "${GREEN}[SUCCESS] Backend updated to latest version.${NC}"
    fi

    # 2. CHECK FOR NEW BRAIN (From Colab)
    # If a new .gguf file appears in the folder, we install it.
    if [ -f "$MODEL_FILE" ]; then
        echo -e "${YELLOW}[NEW BRAIN DETECTED] Installing $MODEL_FILE...${NC}"
        
        # Move file into Docker container
        docker cp "$MODEL_FILE" "$CONTAINER_NAME":/root/
        
        # Create Modelfile on the fly inside container
        docker exec "$CONTAINER_NAME" bash -c "echo 'FROM /root/$MODEL_FILE' > /root/Modelfile"
        docker exec "$CONTAINER_NAME" bash -c "echo 'SYSTEM You are a helpful AI assistant.' >> /root/Modelfile"
        
        # Build the model inside Ollama
        docker exec "$CONTAINER_NAME" ollama create "$CUSTOM_MODEL_NAME" -f /root/Modelfile
        
        # Delete local file so we don't reinstall it in a loop
        rm "$MODEL_FILE"
        
        echo -e "${GREEN}[SUCCESS] New Brain ($CUSTOM_MODEL_NAME) is active!${NC}"
        
        # Optional: Restart backend to ensure it connects cleanly
        docker restart "$BACKEND_CONTAINER"
    fi

    # Sleep for 60 seconds before checking again
    sleep 60
done
