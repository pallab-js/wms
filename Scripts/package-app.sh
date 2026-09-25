#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="WarehouseOS"
BUNDLE_ID="com.warehouseos.app"
BINARY=".build/release/$APP_NAME"
DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ZIP_NAME="$APP_NAME-macos.zip"

VERSION="${1:-$(git describe --tags --always 2>/dev/null || echo 0.0.0)}"

# CFBundleShortVersionString / CFBundleVersion must be period-separated integers
CLEAN_VERSION="$(printf '%s' "${VERSION#v}" | sed -E 's/[^0-9.].*$//; s/^$/0/; s/\.$//')"
BUNDLE_VERSION="$(printf '%s' "$CLEAN_VERSION" | sed -E 's/[^0-9.]/./g; s/\.\.+/./g; s/^\.//; s/\.+$//')"
if [ -z "$BUNDLE_VERSION" ]; then
    BUNDLE_VERSION="0"
fi

if [ ! -f "$BINARY" ]; then
    echo "error: $BINARY not found. Run: swift build -c release" >&2
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BINARY" "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$CLEAN_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUNDLE_VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.business</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>WarehouseOS</string>
</dict>
</plist>
PLIST

printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

codesign --force --sign - "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

rm -f "$DIST_DIR/$ZIP_NAME"
ditto -c -k --keepParent "$APP_DIR" "$DIST_DIR/$ZIP_NAME"

echo "Packaged $DIST_DIR/$ZIP_NAME (version $CLEAN_VERSION, build $BUNDLE_VERSION)"
