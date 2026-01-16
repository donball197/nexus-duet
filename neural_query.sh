#!/data/data/com.termux/files/usr/bin/bash
# Trigger the Sovereign Brain using the shared home path
~/nexus_singularity/env/bin/python3 -c "
import onnxruntime as ort
import os

# Use the path as seen from inside the Debian container
model_path = '/data/data/com.termux/files/home/nexus_singularity/models/nexus_core.onnx'

if os.path.exists(model_path):
    print(f'>> SUCCESS: Model found at {model_path}')
    try:
        session = ort.InferenceSession(model_path)
        print('>> SUCCESS: Neural Engine Initialized (ONNX)')
    except Exception as e:
        print(f'>> ERROR: Engine failed - {e}')
else:
    print(f'>> STANDBY: Path not detected inside Debian: {model_path}')
"
