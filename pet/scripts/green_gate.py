#!/usr/bin/env python3
from __future__ import annotations

import json
import py_compile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EXPECTED_ANIMATIONS = {"idle", "blink", "walk", "run", "jump", "cast", "shock", "hurt", "taunt"}
EXPECTED_MOODS = {"neutral", "happy", "smug", "jealous", "angry", "sad", "cute"}
EXPECTED_PORTS = {"vnc": 5901, "websocket": 6080, "acodex": 8767, "jrpg_pet": 8772}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    errors: list[str] = []
    checks: list[str] = []

    config = load_json(ROOT / "config" / "pet.json")
    manifest = load_json(ROOT / "manifests" / "lumSpriteAtlas.schema.json")
    policy = load_json(ROOT / "policy" / "source-policy.json")
    quality = load_json(ROOT / "manifests" / "pet-quality.baseline.json")
    s24 = load_json(ROOT / "targets" / "samsung-s24-fe" / "profile.json")

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
    if all(lanes.get(lane, {}).get("copy_into_release") is False for lane in ("legacy_external", "unknown")):
        checks.append("rights firewall")

    if quality.get("errors"):
        errors.append(f"QA baseline contains hard errors: {quality['errors']}")
    else:
        checks.append("QA baseline")

    if s24.get("device_model") != "SM-S721U1":
        errors.append("Samsung S24 FE model profile must remain SM-S721U1")
    if s24.get("runtime_owner") != "ordinary-termux":
        errors.append("Samsung S24 FE runtime owner must remain ordinary-termux")
    if s24.get("secure_folder_role") != "client-only":
        errors.append("Secure Folder must remain client-only")
    if s24.get("loopback_services") != EXPECTED_PORTS:
        errors.append("Samsung S24 FE loopback port map drifted")
    security = s24.get("security", {})
    if security.get("bind") != "127.0.0.1" or security.get("public_listeners") is not False:
        errors.append("Samsung S24 FE target must remain localhost-only")
    if security.get("cross_knox_pid_control") is not False:
        errors.append("cross-Knox PID control must remain disabled")
    if security.get("arbitrary_shell_endpoint") is not False:
        errors.append("arbitrary shell endpoint must remain disabled")
    if not any(e.startswith("Samsung S24 FE") or "Secure Folder" in e or "Knox" in e or "shell endpoint" in e for e in errors):
        checks.append("Samsung S24 FE target contract")

    for source in (ROOT / "runtime.py", ROOT / "server.py", ROOT / "roleplay.py"):
        try:
            py_compile.compile(str(source), doraise=True)
        except py_compile.PyCompileError as exc:
            errors.append(str(exc))
    if not any("SyntaxError" in e for e in errors):
        checks.append("python compile")

    result = {
        "ok": not errors,
        "seal": "KAI9000_S24FE_JRPG_COCKPIT_GREEN_20260906",
        "checks": checks,
        "errors": errors,
        "warnings": quality.get("warnings", []),
    }
    print(json.dumps(result, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
