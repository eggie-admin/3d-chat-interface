#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/build/kai9000-chatgpt-samsung-no-root.apk"
GODOT_BIN="${GODOT_BIN:-godot}"

mkdir -p "$ROOT/build"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot executable not found: $GODOT_BIN" >&2
  exit 1
fi

cd "$ROOT"
"$GODOT_BIN" --headless --editor --path "$ROOT" --quit
"$GODOT_BIN" --headless --path "$ROOT" --export-debug "Samsung ChatGPT No Root" "$OUT"

if [[ ! -s "$OUT" ]]; then
  echo "APK export failed: $OUT" >&2
  exit 1
fi

sha256sum "$OUT"
echo "APK ready: $OUT"
