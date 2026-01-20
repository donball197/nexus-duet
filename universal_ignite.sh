#!/bin/bash
export NODE_ID=$(hostname)
if [[ "$NODE_ID" == *"penguin"* ]]; then
    export NEXUS_ROLE="ORACLE"
else
    export NEXUS_ROLE="SENTINEL"
fi
echo "🚀 NEXUS_ROLE Seated: $NEXUS_ROLE"
