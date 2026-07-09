#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

git submodule sync --recursive
git submodule update --init --recursive --jobs 4

echo "Submodules ready:"
git submodule status --recursive
