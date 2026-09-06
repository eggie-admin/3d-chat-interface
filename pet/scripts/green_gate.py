#!/usr/bin/env python3
from __future__ import annotations

import json
import py_compile
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EXPECTED_ANIMATIONS = {"idle", "blink", "walk", "run", "jump", "cast", "shock", "hurt", "taunt"}
EXPECTED_MOODS = {"neutral", "happy", "smug", "jealous", "angry", "sad", "cute"}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    checks: list[str] = []

    config = load_json(ROOT / "config" / "pet.json")
    manifest = load_json(ROOT / "manifests" / "lumSpriteAtlas.schema.json")
    policy = load_json(ROOT / "policy" / "source-policy.json")
    quality = load_json(ROOT / "manifests" / "pet-quality.baseline.json")

    if config.get("host") != "127.0.0.1":
        errors.append("pet host must remain localhost-only")
    else:
        checks.append("localhost bind")

    if int(config.get("port", 0)) != 8772:
        errors.append("canonical pet port must remain 8772")
    else:
        checks.append("canonical port")

    animations = set(manifest.get("animations", {}))
    missing = EXPECTED_ANIMATIONS - animations
    if missing:
        errors.append(f"missing animation states: {sorted(missing)}")
    else:
        checks.append("animation contract")

    moods = set(config.get("moods", []))
    missing_moods = EXPECTED_MOODS - moods
    if missing_moods:
        errors.append(f"missing moods: {sorted(missing_moods)}")
    else:
        checks.append("mood contract")

    lanes = policy.get("lanes", {})
    for lane in ("legacy_external", "unknown"):
        if lanes.get(lane, {}).get("copy_into_release") is not False:
            errors.append(f"rights firewall failed for {lane}")
    if not errors:
        checks.append("rights firewall")

    if quality.get("errors"):
        errors.append(f"QA baseline contains hard errors: {quality['errors']}")
    else:
        checks.append("QA baseline")

    for source in (ROOT / "runtime.py", ROOT / "server.py"):
        try:
            py_compile.compile(str(source), doraise=True)
        except py_compile.PyCompileError as exc:
            errors.append(str(exc))
    if not any("SyntaxError" in e for e in errors):
        checks.append("python compile")

    result = {
        "ok": not errors,
        "seal": "TINY_LUM_PET_CATHEDRAL_GREEN_20260906",
        "checks": checks,
        "errors": errors,
        "warnings": quality.get("warnings", []),
    }
    print(json.dumps(result, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
