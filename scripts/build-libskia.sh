#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/libskia/libskia"

cargo build --release --features skia_mac
codesign --force --sign - target/release/libSkia.dylib
codesign --verify --verbose=4 target/release/libSkia.dylib
