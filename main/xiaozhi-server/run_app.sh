#!/bin/bash
# Startup script to suppress onnxruntime GPU discovery warnings on Jetson

# Suppress onnxruntime warnings (Jetson-specific)
export ORT_LOGGING_LEVEL=3

# Activate virtual environment and run app
cd "$(dirname "$0")"
source .venv/bin/activate
python app.py "$@"
