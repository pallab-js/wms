#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Running all tests..."
swift test 2>&1
