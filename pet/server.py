from __future__ import annotations

import json
import mimetypes
from dataclasses import asdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

from runtime import apply_event, load_state, save_state

ROOT = Path(__file__).resolve().parent
CFG = json.loads((ROOT / "config" / "pet.json").read_text(encoding="utf-8"))
WEB = ROOT / "web"
MANIFEST = ROOT / "manifests" / "lumSpriteAtlas.schema.json"


class Handler(BaseHTTPRequestHandler):
    server_version = "TinyLumPet/0.1"

    def _json(self, code: int, payload: dict) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path == "/health":
            return self._json(200, {"ok": True, "service": "tiny-lum-pet", "bind": "localhost"})
        if path == "/api/pet/state":
            return self._json(200, asdict(load_state()))
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
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        if urlparse(self.path).path != "/api/pet/event":
            return self._json(404, {"error": "not found"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length) or b"{}")
            state = apply_event(load_state(), payload.get("event", ""))
            save_state(state)
            return self._json(200, asdict(state))
        except Exception as exc:
            return self._json(400, {"error": str(exc)})

    def log_message(self, fmt: str, *args) -> None:
        pass


def main() -> None:
    host = CFG.get("host", "127.0.0.1")
    port = int(CFG.get("port", 8772))
    print(f"Tiny Lum Pet Cathedral: http://{host}:{port}")
    ThreadingHTTPServer((host, port), Handler).serve_forever()


if __name__ == "__main__":
    main()
