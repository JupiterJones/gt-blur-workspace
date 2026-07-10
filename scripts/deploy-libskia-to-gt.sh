#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$ROOT/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

: "${GT_APP:?Set GT_APP in .env, e.g. /opt/TestNewBVC/MyProject/devkit/MyProject.app}"

BUILT_LIB="$ROOT/libskia/target/release/libSkia.dylib"
PLUGIN="$GT_APP/Contents/MacOS/Plugins/libSkia.dylib"

"$ROOT/scripts/build-libskia.sh"

test -f "$BUILT_LIB"
test -d "$GT_APP"
test -d "$(dirname "$PLUGIN")"

if [ -f "$PLUGIN" ] && [ ! -f "$PLUGIN.bak" ]; then
  cp "$PLUGIN" "$PLUGIN.bak"
fi

cp "$BUILT_LIB" "$PLUGIN"

codesign --force --sign - "$PLUGIN"
codesign --verify --verbose=4 "$PLUGIN"

codesign --force --deep --sign - "$GT_APP"
codesign --verify --deep --strict --verbose=4 "$GT_APP"

echo "Deployed $PLUGIN"
