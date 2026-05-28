#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Building integration tests..."
swiftc \
    -parse-as-library \
    -I .build/arm64-apple-macosx/debug/Modules \
    -L .build/arm64-apple-macosx/debug \
    Packages/WMSCore/Sources/WMSCore/**/*.swift \
    Packages/WMSData/Sources/WMSData/**/*.swift \
    Packages/WMSServices/Sources/WMSServices/**/*.swift \
    Tests/IntegrationTests/RunTests.swift \
    -o /tmp/wms-tests 2>&1

echo ""
/tmp/wms-tests
