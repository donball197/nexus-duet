#!/bin/bash
# Nexus Singularity: Cross-Device Data Mirror

BACKUP_PATH="/sdcard/Nexus_Backups"

echo ">> MIRROR: Phone side logic initialized."
echo ">> Ready to transmit encrypted vaults to Duet workstation..."

# List available vaults for the Duet to see
ls -lh $BACKUP_PATH/*.enc
