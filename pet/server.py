from __future__ import annotations

import json
import mimetypes
import socket
from dataclasses import asdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

from quests import (
    QuestState,
    complete_for_action,
    complete_objective,
    generate_quest,
    load_quest_state,
    save_quest_state,
)
from roleplay import RPGState, load_rpg_state, perform_action, save_rpg_state, set_role_class
from runtime import apply_event, load_state, save_state
from saves import list_slots, load_slot, save_slot

ROOT = Path(__file__).resolve().parent
CFG = json.loads((ROOT / "config" / "pet.json").read_text(encoding="utf-8"))
WEB = ROOT / "web"
MANIFEST = ROOT / "manifests" / "lumSpriteAtlas.schema.json"
MAX_BODY = 16 * 1024
LOCAL_SERVICES = {
    "vnc": 5901,
    "websocket": 6080,
    "acodex": 8767,
    "pet": int(CFG.get("port", 8772)),
}


def _port_open(port: int, timeout: float = 0.15) -> bool:
    try:
        with socket.create_connection(("127.0.0.1", int(port)), timeout=timeout):
            return True
    except OSError:
        return False


class Handler(BaseHTTPRequestHandler):
    server_version = "TinyLumPet/0.3"

    def _json(self, code: int, payload: dict) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'",
        )
        self.end_headers()
        self.wfile.write(body)

    def _payload(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length < 0 or length > MAX_BODY:
            raise ValueError("request body too large")
        raw = self.rfile.read(length) if length else b"{}"
        data = json.loads(raw)
        if not isinstance(data, dict):
            raise ValueError("JSON object required")
        return data

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path == "/health":
            return self._json(200, {"ok": True, "service": "tiny-lum-pet", "bind": "localhost"})
        if path == "/api/pet/state":
            return self._json(200, asdict(load_state()))
        if path == "/api/rpg/state":
            return self._json(200, asdict(load_rpg_state()))
        if path == "/api/quests":
            return self._json(200, asdict(load_quest_state()))
        if path == "/api/saves":
            return self._json(200, {"slots": list_slots()})
        if path == "/api/acodex/status":
            up = _port_open(LOCAL_SERVICES["acodex"])
            return self._json(200, {
                "ok": True,
                "up": up,
                "url": "http://127.0.0.1:8767",
                "mode": "in-app-safe-command-menu",
                "shell_execution": False,
                "note": "The Godot pane is a whitelisted command menu. Full AcodeX UI may be opened on localhost.",
            })
        if path == "/api/system/status":
            return self._json(200, {
                "ok": True,
                "host": "127.0.0.1",
                "services": {name: {"port": port, "up": _port_open(port)} for name, port in LOCAL_SERVICES.items()},
                "ownership": "ordinary Termux owns daemon processes; Secure Folder is cockpit/client",
            })
        if path == "/manifest":
            return self._json(200, json.loads(MANIFEST.read_text(encoding="utf-8")))

        target = WEB / "index.html" if path == "/" else (WEB / path.lstrip("/"))
        target = target.resolve()
        if target != WEB.resolve() / "index.html" and WEB.resolve() not in target.parents:
            return self._json(403, {"error": "forbidden"})
        if not target.exists() or not target.is_file():
            return self._json(404, {"error": "not found"})

        body = target.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", mimetypes.guess_type(str(target))[0] or "application/octet-stream")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        try:
            payload = self._payload()
            if path == "/api/pet/event":
                state = apply_event(load_state(), payload.get("event", ""))
                save_state(state)
                return self._json(200, asdict(state))

            if path == "/api/rpg/action":
                action = str(payload.get("action", ""))
                state = perform_action(load_rpg_state(), action)
                save_rpg_state(state)
                quest = complete_for_action(load_quest_state(), action)
                save_quest_state(quest)
                return self._json(200, {"rpg": asdict(state), "quest": asdict(quest)})

            if path == "/api/rpg/class":
                state = set_role_class(load_rpg_state(), str(payload.get("role_class", "")))
                save_rpg_state(state)
                return self._json(200, asdict(state))

            if path == "/api/quests/generate":
                state = generate_quest(str(payload.get("task", "")))
                return self._json(200, asdict(state))

            if path == "/api/quests/complete":
                state = complete_objective(load_quest_state(), int(payload.get("index", -1)))
                save_quest_state(state)
                return self._json(200, asdict(state))

            if path == "/api/saves/save":
                slot = int(payload.get("slot", 0))
                snap = save_slot(slot, asdict(load_rpg_state()), asdict(load_quest_state()))
                return self._json(200, {"ok": True, "slot": snap["slot"], "saved_at": snap["saved_at"]})

            if path == "/api/saves/load":
                slot = int(payload.get("slot", 0))
                snap = load_slot(slot)
                rpg = RPGState(**snap["rpg"])
                quest = QuestState(**snap["quest"])
                rpg.clamp()
                quest.clamp()
                save_rpg_state(rpg)
                save_quest_state(quest)
                return self._json(200, {"ok": True, "rpg": asdict(rpg), "quest": asdict(quest)})

            return self._json(404, {"error": "not found"})
        except Exception as exc:
            return self._json(400, {"error": str(exc)})

    def log_message(self, fmt: str, *args) -> None:
        pass


def main() -> None:
    host = CFG.get("host", "127.0.0.1")
    if host not in {"127.0.0.1", "localhost"}:
        raise SystemExit("refusing non-local bind")
    port = int(CFG.get("port", 8772))
    print(f"Tiny Lum Pet Cathedral: http://{host}:{port}")
    ThreadingHTTPServer((host, port), Handler).serve_forever()


if __name__ == "__main__":
    main()
