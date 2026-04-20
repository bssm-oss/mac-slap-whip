#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MacWhip"
APP_DIR="$ROOT_DIR/dist/${APP_NAME}.app"
ZIP_PATH="$ROOT_DIR/dist/${APP_NAME}.zip"

zsh "$ROOT_DIR/scripts/build_release_app.sh"

rm -f "$ZIP_PATH"
xattr -cr "$APP_DIR" || true
dot_clean "$APP_DIR" || true
find "$APP_DIR" -name '._*' -delete || true
COPYFILE_DISABLE=1 ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo "Packaged release zip at $ZIP_PATH"
