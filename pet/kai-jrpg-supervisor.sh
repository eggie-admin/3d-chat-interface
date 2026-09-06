#!/usr/bin/env bash
set -euo pipefail

ROOT="${HOME}/kai9000/pet-cathedral"
PET_DIR="${PET_DIR:-$ROOT}"
STATE_DIR="${HOME}/.local/state/kai-jrpg"
PID_FILE="$STATE_DIR/pet.pid"
LOG_FILE="$STATE_DIR/pet.log"
HOST="127.0.0.1"
PET_PORT="8772"

mkdir -p "$STATE_DIR"

probe_port() {
  local port="$1"
  python3 - "$port" <<'PY'
import socket, sys
port = int(sys.argv[1])
s = socket.socket()
s.settimeout(0.2)
try:
    s.connect(("127.0.0.1", port))
    print("GREEN")
except OSError:
    print("OFF")
finally:
    s.close()
PY
}

start_pet() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "pet already running pid=$(cat "$PID_FILE")"
    return 0
  fi
  cd "$PET_DIR"
  nohup python3 server.py >>"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  sleep 0.3
  if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "pet failed to start; see $LOG_FILE" >&2
    exit 1
  fi
  echo "pet started pid=$(cat "$PID_FILE")"
}

stop_pet() {
  if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
  echo "pet stopped"
}

status() {
  echo "=== KAI 9000 JRPG COCKPIT ==="
  printf 'VNC       5901  %s\n' "$(probe_port 5901)"
  printf 'WebSocket 6080  %s\n' "$(probe_port 6080)"
  printf 'AcodeX    8767  %s\n' "$(probe_port 8767)"
  printf 'Lum Pet   8772  %s\n' "$(probe_port 8772)"
  echo
  echo "Doctrine: ordinary Termux owns daemons; Secure Folder is cockpit/client."
}

case "${1:-status}" in
  start) start_pet; status ;;
  stop) stop_pet ;;
  restart) stop_pet; start_pet; status ;;
  status) status ;;
  logs) tail -n 120 "$LOG_FILE" 2>/dev/null || true ;;
  probe) status ;;
  *) echo "usage: $0 {start|stop|restart|status|logs|probe}"; exit 2 ;;
esac
