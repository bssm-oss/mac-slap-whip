#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MacWhip"
APP_VERSION="${MACWHIP_VERSION:-0.1.3}"
APP_DIR="$ROOT_DIR/dist/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BRANDING_DIR="$ROOT_DIR/Branding"

mkdir -p "$ROOT_DIR/dist"

if [ ! -f "$BRANDING_DIR/AppIcon.icns" ] || [ ! -f "$ROOT_DIR/Sources/MacWhip/Resources/MenuBarIconTemplate.png" ]; then
  python3 "$ROOT_DIR/scripts/generate_brand_assets.py"
fi

swift build -c release --product "$APP_NAME" --package-path "$ROOT_DIR"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "$BRANDING_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacWhip</string>
    <key>CFBundleIdentifier</key>
    <string>oss.bssm.macwhip</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacWhip</string>
    <key>CFBundleDisplayName</key>
    <string>MacWhip</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

echo "Built app bundle at $APP_DIR"
