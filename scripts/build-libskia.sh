#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/libskia/libskia"

cargo build --locked --release --features skia_mac
codesign --force --sign - "$ROOT/libskia/target/release/libSkia.dylib"
codesign --verify --verbose=4 "$ROOT/libskia/target/release/libSkia.dylib"
