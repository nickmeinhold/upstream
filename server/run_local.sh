#!/bin/bash

# Local development script for Downstream server
# Usage: ./run_local.sh

# Load environment variables from .env file
# Using a line-by-line approach to preserve JSON with special characters
if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
      # Extract key and value, preserving the value exactly
      key="${line%%=*}"
      value="${line#*=}"
      export "$key=$value"
    fi
  done < .env
fi

echo "Starting Downstream server..."
echo "FIREBASE_PROJECT_ID: $FIREBASE_PROJECT_ID"

dart run bin/server.dart
