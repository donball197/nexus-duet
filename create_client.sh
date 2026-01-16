#!/bin/bash
# Nexus Singularity: Client Tenant Provisioning

CLIENT_NAME=$1

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: ./create_client.sh [client_name]"
    exit 1
fi

BASE_DIR="$HOME/nexus_singularity/portfolio/$CLIENT_NAME"

# Create secure client structure
mkdir -p "$BASE_DIR"/{vectors,config,backups,source_docs}

echo -e "\n>> PORTFOLIO: Provisioned secure slot for: ${CLIENT_NAME}"
echo ">> PATH: $BASE_DIR"

# Generate a unique Specialist Config for this client
cat << CONFIG > "$BASE_DIR/config/specialist.yaml"
client_id: "$CLIENT_NAME"
neural_path: "$BASE_DIR/vectors/"
context_limit: 4096
persistence: true
CONFIG

echo ">> SUCCESS: Specialist configuration initialized."
