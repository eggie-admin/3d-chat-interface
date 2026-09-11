# KAI 9000 ChatGPT Samsung No-Root Companion

Canonical branch: `chatgpt-inapp-samsung-no-root`

Current integration seal: `LUHMOS_ULTIMA_TESTING_GREEN_20260910`

This subtree is the Samsung Android companion lane for using the official ChatGPT app as the front door while preserving a strict no-root boundary.

## Runtime doctrine

- Official ChatGPT Android app / Android link resolver is the user-facing AI entry point.
- Godot 4 provides the companion cockpit, local JRPG/pet UI, local save crystals, and authored visual/audio behavior.
- Normal operation requires **no Termux, no Shizuku, no root, no ADB, no hidden APIs, no localhost daemon, and no cross-Knox process control**.
- The companion never patches, injects into, impersonates, or controls the official ChatGPT app.
- ChatGPT is opened only through an ordinary user-visible Android link action.
- App-local save data lives under Godot `user://` storage and requires no broad storage permission.

## Android contract

- Package: `art.eggiebagelface.kai9000`
- Label: `KAI 9000 ChatGPT Companion`
- Target SDK: 36
- ABI: `arm64-v8a`
- Internet permission only
- Camera: disabled
- Microphone: disabled
- Legacy external storage permissions: disabled

## LuHm OS merge

The LuHm OS ULTIMA testing milestone is imported as a verified sibling-artifact contract, not as a runtime dependency.

- Source repo: `eggie-admin/hydra-shell-android`
- Testing commit: `7495266b649cdb605cc8f4a67070c265e2770589`
- Workflow run: `34556629871`
- LuHm package: `art.eggiebagelface.luhmos`
- LuHm version: `1.0.0` / code `100`
- SDK 36 / ARM64 / 16 KB alignment gate: GREEN
- Exact testing APK SHA-256: `bb250075b39a3976ce3eea577973ed16cd75c0fbcfbf879676613f87ac286937`
- LuHm signing state: ephemeral testing signer only

The companion intentionally keeps its own package identity so it can coexist with LuHm OS without Android signature/package collisions.

## Build

```bash
cd pet/godot/jrpg
./build-s24fe.sh
```

The build produces:

`build/kai9000-chatgpt-samsung-no-root.apk`

Production publication remains blocked until a persistent release signing identity and production gates are green.

## Source rights

Reference-only third-party material must not be redistributed. Release builds may ship only assets explicitly classified as original/generated with recorded provenance.
