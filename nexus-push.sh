#!/bin/bash
# Nexus Singularity: Global Sync

echo ">> SYNC: Pushing local changes to GitHub..."

cd ~/nexus_singularity
git add .
git commit -m "Nexus Node Update: $(date +'%Y-%m-%d %H:%M')"
git push origin main

if [ $? -eq 0 ]; then
    echo -e "\n\033[1;32m>> SUCCESS: GitHub Sync Complete. Golden Command updated.\033[0m"
else
    echo -e "\n\033[1;31m>> FAILURE: Sync failed. Check internet/git credentials.\033[0m"
fi
