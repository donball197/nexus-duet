#!/bin/bash
# Motorola G to Lenovo Duet: Environment Transporter

echo ">> MIGRATOR: Packaging Nexus Singularity for Duet deployment..."

# 1. Create a compressed archive of the project and libraries
# We exclude the 'target' folder to save space, but keep the final binary
tar -czvf nexus_transport.tar.gz \
    --exclude='nexus_singularity/target/debug/build' \
    --exclude='nexus_singularity/target/debug/deps' \
    ~/nexus_singularity \
    ~/ort_lib \
    ~/.bashrc

echo ">> SUCCESS: nexus_transport.tar.gz is ready."
echo ">> INSTRUCTION: Move this file to your Duet via Google Drive, USB, or Scp."
