#!/bin/bash
# Nexus Singularity: Client Data Vault (Lock)

CLIENT=$1
if [ -z "$CLIENT" ]; then
    echo "Usage: nexus-lock [client_name]"
    exit 1
fi

BASE_DIR="$HOME/nexus_singularity/portfolio/$CLIENT"
VAULT_FILE="$BASE_DIR/client_vault.enc"

if [ ! -d "$BASE_DIR" ]; then
    echo ">> ERROR: Client '$CLIENT' not found."
    exit 1
fi

echo -e ">> LOCKING: Securing data for $CLIENT..."
echo -e "Enter a unique passphrase for this client vault:"

# Create encrypted archive and delete the original directories
tar -cz -C "$BASE_DIR" vectors source_docs | \
openssl enc -aes-256-cbc -salt -pbkdf2 -out "$VAULT_FILE"

if [ $? -eq 0 ]; then
    rm -rf "$BASE_DIR/vectors" "$BASE_DIR/source_docs"
    echo -e "\n\033[1;32m>> SUCCESS: $CLIENT data is now encrypted and locked.\033[0m"
else
    echo -e "\n\033[1;31m>> FAILURE: Encryption aborted.\033[0m"
fi
