from __future__ import annotations

import json
import sys
import tempfile
import threading
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

PET_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PET_ROOT))

import runtime
import server


class PetServerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.old_state_path = runtime.STATE_PATH
        runtime.STATE_PATH = Path(self.tmp.name) / "state.json"
        self.httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)
        self.thread.start()
        host, port = self.httpd.server_address
        self.base = f"http://{host}:{port}"

    def tearDown(self) -> None:
        self.httpd.shutdown()
        self.httpd.server_close()
        self.thread.join(timeout=2)
        runtime.STATE_PATH = self.old_state_path
        self.tmp.cleanup()

    def get_json(self, path: str) -> tuple[int, dict]:
        with urlopen(self.base + path, timeout=2) as response:
            return response.status, json.loads(response.read().decode("utf-8"))

    def post_json(self, path: str, payload: dict) -> tuple[int, dict]:
        request = Request(
            self.base + path,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urlopen(request, timeout=2) as response:
            return response.status, json.loads(response.read().decode("utf-8"))

    def test_health_is_green(self) -> None:
        status, payload = self.get_json("/health")
        self.assertEqual(status, 200)
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["bind"], "localhost")

    def test_event_round_trip(self) -> None:
        _, before = self.get_json("/api/pet/state")
        status, after = self.post_json("/api/pet/event", {"event": "tap"})
        self.assertEqual(status, 200)
        self.assertGreater(after["revision"], before["revision"])
        self.assertEqual(after["mood"], "happy")

    def test_manifest_is_served(self) -> None:
        status, manifest = self.get_json("/manifest")
        self.assertEqual(status, 200)
        self.assertIn("animations", manifest)
        self.assertIn("idle", manifest["animations"])

    def test_avatar_status_is_shippable(self) -> None:
        status, payload = self.get_json("/api/avatar/status")
        self.assertEqual(status, 200)
        self.assertTrue(payload["ok"])
        avatar = payload["avatar"]
        self.assertTrue(avatar["ship_forward"])
        self.assertTrue(avatar["rig_debug_deferred"])
        self.assertEqual(avatar["runtime"]["preferred_preview_format"], "mp4")
        self.assertFalse(avatar["copyright_firewall"]["destiny_child_assets_embedded"])

    def test_unknown_event_returns_400(self) -> None:
        request = Request(
            self.base + "/api/pet/event",
            data=b'{"event":"nope"}',
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with self.assertRaises(HTTPError) as ctx:
            urlopen(request, timeout=2)
        self.assertEqual(ctx.exception.code, 400)


if __name__ == "__main__":
    unittest.main()
