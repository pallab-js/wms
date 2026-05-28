#!/bin/bash
set -euo pipefail

echo "=== Running SwiftLint ==="
swiftlint --strict

echo ""
echo "=== Building all SPM packages ==="
cd Packages/WMSCore && swift build && cd ../..
cd Packages/WMSDesignSystem && swift build && cd ../..
cd Packages/WMSServices && swift build && cd ../..

echo ""
echo "=== All checks passed ==="
