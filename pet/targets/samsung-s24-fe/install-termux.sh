#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="${HOME}/kai9000/s24fe-jrpg"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p "${HOME}/kai9000"
rm -rf "$ROOT"
cp -a "$SRC" "$ROOT"

chmod +x "$ROOT/run-termux.sh" "$ROOT/kai-jrpg-supervisor.sh" 2>/dev/null || true

printf '%s\n' \
  'KAI 9000 // Samsung S24 FE target installed' \
  "Root: $ROOT" \
  'Runtime owner: ordinary Termux' \
  'Secure Folder role: cockpit/client only' \
  'JRPG API: http://127.0.0.1:8772' \
  '' \
  "Start:  $ROOT/kai-jrpg-supervisor.sh start" \
  "Status: $ROOT/kai-jrpg-supervisor.sh status" \
  "Logs:   $ROOT/kai-jrpg-supervisor.sh logs"
