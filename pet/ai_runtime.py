# SPDX-License-Identifier: MIT
from __future__ import annotations

import json
import urllib.parse
import urllib.request

BASE = "http://127.0.0.1:8797/api/ai"
MAX_RESPONSE = 1024 * 1024

def _get(path: str) -> dict:
    with urllib.request.urlopen(BASE + path, timeout=8) as resp:
        raw = resp.read(MAX_RESPONSE + 1)
    if len(raw) > MAX_RESPONSE:
        raise RuntimeError("AI response too large")
    return json.loads(raw)

def _post(path: str, payload: dict) -> dict:
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        raw = resp.read(MAX_RESPONSE + 1)
    if len(raw) > MAX_RESPONSE:
        raise RuntimeError("AI response too large")
    return json.loads(raw)

def status() -> dict:
    return _get("/health")

def search_feed(query: str, limit: int = 10) -> dict:
    q = urllib.parse.urlencode({"q": query[:300], "limit": max(1, min(limit, 50))})
    return _get("/rss/search?" + q)

def chat(message: str, search: str | None = None) -> dict:
    return _post("/chat", {"message": message[:4096], "search": search})
