#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ensure_submodule() {
  local path="$1"
  local url="$2"

  if git config --file .gitmodules --get "submodule.${path}.url" >/dev/null 2>&1 \
    && git ls-files --stage -- "$path" | grep -q '160000'; then
    return 0
  fi

  if [ -e "$path" ] && [ ! -d "$path/.git" ]; then
    echo "Refusing to add submodule '$path': path exists and is not a git checkout." >&2
    exit 1
  fi

  if [ -d "$path/.git" ]; then
    echo "Registering existing checkout as submodule: $path"
    git submodule absorbgitdirs "$path" || true
    git add "$path" .gitmodules
  else
    echo "Adding submodule: $path"
    git submodule add "$url" "$path"
  fi
}

ensure_submodule "Bloc" "git@github.com:JupiterJones/Bloc.git"
ensure_submodule "sparta" "git@github.com:JupiterJones/sparta.git"
ensure_submodule "compositor-rs" "git@github.com:JupiterJones/compositor-rs.git"
ensure_submodule "libskia" "git@github.com:JupiterJones/libskia.git"

git submodule sync --recursive
git submodule update --init --recursive --jobs 4

echo
echo "Submodules ready:"
git submodule status --recursive
