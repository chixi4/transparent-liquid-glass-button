#!/bin/bash
set -euo pipefail

# Build the app bundle from the repository root, regardless of the caller's cwd.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="${APP_NAME:-Swap}"
CONFIGURATION="${CONFIGURATION:-debug}"
APP_DIR="${APP_DIR:-$APP_NAME.app}"
BINARY_PATH="${BINARY_PATH:-.build/$CONFIGURATION/TransparentLiquidGlassButton}"
VERSION="${VERSION:-1.0}"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

swift build -c "$CONFIGURATION"

if [[ ! -x "$BINARY_PATH" ]]; then
    echo "❌ 找不到可执行文件：$BINARY_PATH" >&2
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BINARY_PATH" "$MACOS_DIR/$APP_NAME"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.swap.app</string>
    <key>CFBundleName</key>
    <string>Swap</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ 已生成 $APP_DIR"
echo ""
echo "启动方式："
echo "  open $APP_DIR"
echo "或拖到 Applications 文件夹中"
