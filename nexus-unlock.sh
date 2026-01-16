#!/bin/bash
# Nexus Singularity: Client Data Vault (Unlock)

CLIENT=$1
VAULT_FILE="$HOME/nexus_singularity/portfolio/$CLIENT/client_vault.enc"

if [ ! -f "$VAULT_FILE" ]; then
    echo ">> ERROR: No encrypted vault found for '$CLIENT'."
    exit 1
fi

echo -e ">> UNLOCKING: Accessing $CLIENT vault..."
openssl enc -aes-256-cbc -d -salt -pbkdf2 -in "$VAULT_FILE" | tar -xz -C "$(dirname "$VAULT_FILE")"

if [ $? -eq 0 ]; then
    rm "$VAULT_FILE"
    echo -e "\n\033[1;32m>> SUCCESS: $CLIENT data restored for active session.\033[0m"
else
    echo -e "\n\033[1;31m>> FAILURE: Incorrect passphrase.\033[0m"
fi
