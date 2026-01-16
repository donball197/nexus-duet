#!/bin/bash
# Nexus Singularity: Secure System Snapshot

BACKUP_DIR="/sdcard/Nexus_Backups"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="nexus_snapshot_$TIMESTAMP.tar.gz.enc"

echo ">> SNAPSHOT: Preparing corrected backup (excluding build files)..."

# FIX: --exclude must come BEFORE the source directory
# We also exclude sockets and lock files that cause 'failure status'
tar -czf - --exclude='nexus_singularity/target' --exclude='*.sock' -C "$HOME" nexus_singularity | \
openssl enc -aes-256-cbc -salt -pbkdf2 -out "$BACKUP_DIR/$FILENAME"

if [ $? -eq 0 ]; then
    echo -e "\n\033[1;32m>> SUCCESS: Clean snapshot saved to $BACKUP_DIR/$FILENAME\033[0m"
    termux-notification --title "Nexus Backup" --content "Clean Snapshot Complete: $FILENAME"
else
    echo -e "\n\033[1;31m>> FAILURE: Snapshot failed. Ensure password was entered correctly.\033[0m"
fi
