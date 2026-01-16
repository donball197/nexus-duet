#!/bin/bash
while true; do
    # Listen for 3 seconds of speech
    TEXT=$(termux-speech-to-text)
    if [ ! -z "$TEXT" ]; then
        echo "- $TEXT" > ~/nexus_singularity/inbox/voice_cmd_$(date +%s).md
        termux-tts-speak "Command received: $TEXT"
    fi
    sleep 1
done
