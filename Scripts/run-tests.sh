#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Running all tests..."
swift test 2>&1

echo "Running package tests..."
for package in Packages/*/; do
    if [ -d "$package/Tests" ]; then
        echo "--- $package"
        (cd "$package" && swift test 2>&1)
    fi
done
