#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$(dirname "$PLUGIN_DIR")"

mkdir -p "$PLUGIN_DIR/dist"

echo "Compiling Dart formatter to JavaScript..."
dart compile js \
  -O2 \
  -o "$PLUGIN_DIR/dist/blade-formatter.js" \
  "$PROJECT_DIR/tool/js_bridge.dart"

cp "$PROJECT_DIR/LICENSE" "$PLUGIN_DIR/LICENSE"

echo "Done. Output: dist/blade-formatter.js"
ls -lh "$PLUGIN_DIR/dist/blade-formatter.js"
