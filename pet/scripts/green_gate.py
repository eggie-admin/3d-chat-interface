#!/usr/bin/env python3
from __future__ import annotations

import json
import py_compile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

EXPECTED_ANIMATIONS = {"idle", "blink", "walk", "run", "jump", "cast", "shock", "hurt", "taunt"}
EXPECTED_MOODS = {"neutral", "happy", "smug", "jealous", "angry", "sad", "cute"}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def require_text(path: Path, errors: list[str]) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def main() -> int:
    errors: list[str] = []
    checks: list[str] = []

    config = load_json(ROOT / "config" / "pet.json")
    manifest = load_json(ROOT / "manifests" / "lumSpriteAtlas.schema.json")
    policy = load_json(ROOT / "policy" / "source-policy.json")
    no_root = load_json(ROOT / "policy" / "chatgpt-samsung-no-root.json")
    upstream = load_json(ROOT / "manifests" / "luhmos-ultima-testing-green-20260910.json")
    quality = load_json(ROOT / "manifests" / "pet-quality.baseline.json")
    s24 = load_json(ROOT / "targets" / "samsung-s24-fe" / "profile.json")

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

    android = no_root.get("android_contract", {})
    if no_root.get("project") != "ChatGPT in-app Samsung no-root":
        errors.append("no-root project identity drifted")
    for key in ("root_required", "shizuku_required", "termux_required", "hidden_api_required", "privileged_permissions_required"):
        if android.get(key) is not False:
            errors.append(f"no-root doctrine failed: {key}")
    if android.get("target_sdk") != 36:
        errors.append("no-root target SDK must remain 36")
    if android.get("abi") != "arm64-v8a":
        errors.append("no-root ABI must remain arm64-v8a")
    if not any("no-root" in e.lower() or "sdk" in e.lower() or "abi" in e.lower() for e in errors):
        checks.append("ChatGPT Samsung no-root policy")

    if s24.get("device_model") != "SM-S721U1":
        errors.append("Samsung device profile must remain SM-S721U1")
    if s24.get("runtime_owner") != "android-app-self":
        errors.append("Samsung no-root runtime must be app-owned")
    if s24.get("loopback_services") != {}:
        errors.append("Samsung no-root profile must not require loopback services")
    security = s24.get("security", {})
    for key in ("root_required", "shizuku_required", "termux_required", "adb_required", "localhost_daemon_required"):
        if security.get(key) is not False:
            errors.append(f"Samsung target unexpectedly requires {key}")
    if security.get("cross_knox_pid_control") is not False:
        errors.append("cross-Knox PID control must remain disabled")
    if security.get("arbitrary_shell_endpoint") is not False:
        errors.append("arbitrary shell endpoint must remain disabled")
    chatgpt = s24.get("chatgpt_integration", {})
    if chatgpt.get("front_door") != "official-chatgpt-android-app":
        errors.append("official ChatGPT Android app must remain the front door")
    if chatgpt.get("app_injection") is not False or chatgpt.get("hidden_api") is not False:
        errors.append("ChatGPT integration must not inject or use hidden APIs")
    if not any("Samsung" in e or "ChatGPT" in e or "Knox" in e for e in errors):
        checks.append("Samsung app-owned target contract")

    if upstream.get("milestone") != "LUHMOS_ULTIMA_TESTING_GREEN_20260910":
        errors.append("LuHm ULTIMA milestone identity drifted")
    if upstream.get("source", {}).get("commit") != "7495266b649cdb605cc8f4a67070c265e2770589":
        errors.append("LuHm testing commit drifted")
    if upstream.get("apk", {}).get("sha256") != "bb250075b39a3976ce3eea577973ed16cd75c0fbcfbf879676613f87ac286937":
        errors.append("LuHm APK digest drifted")
    if upstream.get("import_policy", {}).get("depend_on_termux_runtime") is not False:
        errors.append("LuHm import must not depend on Termux")
    if not any("LuHm" in e for e in errors):
        checks.append("LuHm ULTIMA import contract")

    for source in (
        ROOT / "runtime.py",
        ROOT / "server.py",
        ROOT / "roleplay.py",
        ROOT / "quests.py",
        ROOT / "saves.py",
    ):
        try:
            py_compile.compile(str(source), doraise=True)
        except py_compile.PyCompileError as exc:
            errors.append(str(exc))
    if not any("SyntaxError" in e for e in errors):
        checks.append("python reference tooling compile")

    godot_root = ROOT / "godot" / "jrpg"
    cockpit = require_text(godot_root / "JRPGCockpit.gd", errors)
    avatar = require_text(godot_root / "LumAvatarStage.gd", errors)
    fanfare = require_text(godot_root / "OriginalFanfare.gd", errors)
    export_preset = require_text(godot_root / "export_presets.cfg", errors)
    build_script = require_text(godot_root / "build-s24fe.sh", errors)

    if 'const CHATGPT_URL := "https://chatgpt.com/"' not in cockpit:
        errors.append("ChatGPT user-launch URL missing")
    if "OS.shell_open(CHATGPT_URL)" not in cockpit:
        errors.append("ChatGPT user-launch action missing")
    if "DENIED: command is not in the local companion whitelist" not in cockpit:
        errors.append("Godot local command whitelist guard missing")
    forbidden = ("127.0.0.1", "ACODEX", "AcodeX", "OS.execute", "execute_with_pipe", "Runtime.exec", "/data/data/com.termux")
    if any(marker in cockpit for marker in forbidden):
        errors.append("Godot cockpit contains forbidden daemon/shell integration")
    if not any("ChatGPT" in e or "Godot" in e for e in errors):
        checks.append("self-contained ChatGPT companion cockpit")

    if "res://assets/lum/lum.glb" not in avatar or "_build_procedural_lum" not in avatar:
        errors.append("Lum avatar must provide GLB hook and procedural fallback")
    if "hip" not in avatar.lower() or "wing" not in avatar.lower():
        errors.append("Lum procedural avatar must retain hip-wing construction")
    if "AudioStreamWAV" not in fanfare or "play_victory" not in fanfare:
        errors.append("original procedural fanfare generator missing")
    if not any("Lum avatar" in e or "fanfare" in e for e in errors):
        checks.append("Lum avatar and original fanfare")

    if 'name="Samsung ChatGPT No Root"' not in export_preset:
        errors.append("Samsung no-root Android export preset missing")
    if 'gradle_build/target_sdk="36"' not in export_preset:
        errors.append("Samsung export must target SDK 36")
    if "architectures/arm64-v8a=true" not in export_preset:
        errors.append("Samsung export must enable arm64-v8a")
    if 'package/unique_name="art.eggiebagelface.kai9000"' not in export_preset:
        errors.append("Samsung companion package id drifted")
    if "--export-debug \"Samsung ChatGPT No Root\"" not in build_script:
        errors.append("Samsung build helper does not invoke no-root preset")
    if any(token in export_preset for token in (
        "permissions/camera=true",
        "permissions/record_audio=true",
        "permissions/read_external_storage=true",
        "permissions/write_external_storage=true",
    )):
        errors.append("Samsung companion requested a forbidden broad permission")
    if not any("export" in e.lower() or "package" in e.lower() or "arm64" in e.lower() or "permission" in e.lower() for e in errors):
        checks.append("Samsung Android export contract")

    result = {
        "ok": not errors,
        "seal": "KAI9000_CHATGPT_SAMSUNG_NO_ROOT_GREEN_20260910",
        "checks": checks,
        "errors": errors,
        "warnings": quality.get("warnings", []),
    }
    print(json.dumps(result, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
