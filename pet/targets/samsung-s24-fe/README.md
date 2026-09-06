# Samsung Galaxy S24 FE target

Canonical device profile: `SM-S721U1`, Android 16, aarch64.

## KAI 9000 ownership boundary

- Ordinary Termux owns the localhost daemons and persistent processes.
- Samsung Secure Folder hosts the protected Acode/Godot/WebView cockpit client.
- Secure Folder probes loopback ports instead of trying to inspect ordinary-Termux PIDs across Knox.
- No service binds a public interface by default.

## Canonical loopback map

- `127.0.0.1:5901` TigerVNC
- `127.0.0.1:6080` WebSocket bridge -> VNC
- `127.0.0.1:8767` AcodeX
- `127.0.0.1:8772` KAI 9000 JRPG / Lum Pet API

## Godot cockpit

Use `pet/godot/jrpg/` as the in-app cockpit project. Design target is landscape 1280x720 using Godot 4 mobile renderer. The UI should consume localhost APIs only and must not expose an arbitrary shell execution endpoint.

## Secure Folder probe

From the Acode terminal inside Secure Folder, use TCP reachability checks against the four loopback ports. Treat a failed probe as a client-connectivity problem, not proof that the ordinary-Termux process is absent.

## Hardening

- localhost-only listeners
- deny external actions by default
- no secrets in repo
- no cross-Knox PID control
- no raw shell command API from the JRPG UI
- third-party reference assets stay out of release builds
