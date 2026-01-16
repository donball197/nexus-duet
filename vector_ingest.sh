#!/bin/bash
# Nexus Singularity: Business Data Vector Ingestion

ENDPOINT="http://127.0.0.1:8080/v1/ingest"

echo ">> INGESTION: Preparing business data for neural indexing..."

# Sample business data for ingestion
DATA='{
  "documents": [
    {"id": "doc_001", "text": "Mobile AI nodes utilize ARM-optimized ONNX runtimes for low-power inference."},
    {"id": "doc_002", "text": "Nexus Singularity Phase 5 supports multi-agent coordination via local REST API."},
    {"id": "doc_003", "text": "Business operations on Motorola G hardware require 1.3GiB swap for stability."}
  ]
}'

curl -s -X POST $ENDPOINT \
     -H "Content-Type: application/json" \
     -d "$DATA" | jq '.'

if [ $? -eq 0 ]; then
    echo -e "\n\033[1;32m>> SUCCESS: Data indexed. Neural core knowledge updated.\033[0m"
else
    echo -e "\n\033[1;31m>> FAILURE: Ingestion failed. Check Session 4 for server errors.\033[0m"
fi
