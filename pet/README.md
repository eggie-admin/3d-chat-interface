# Tiny Lum Pet Cathedral

Seal: `TINY_LUM_PET_CATHEDRAL_20260906`

This subtree turns the existing Godot 4 local chat project into a local-first Tiny Lum Pet companion lane.

## Source ingest

The supplied Google Drive archive is treated as a **reference corpus**, not a redistributable runtime dependency. Its notes describe music swaps, JP/KR voice swaps, OSTs, art swaps, wallpapers, fonts, and Android character-package replacement workflows. A comparison report also enumerates many `.pck` character assets.

No third-party game art, audio, voice, `.pck`, or archive bytes are committed here.

## Runtime

- Python stdlib service: `127.0.0.1:8772`
- Godot bridge: `pet/godot/PetBridge.gd`
- State endpoint: `GET /api/pet/state`
- Event endpoint: `POST /api/pet/event`
- Health: `GET /health`
- Sprite contract: `pet/manifests/lumSpriteAtlas.schema.json`

## Start

```bash
cd pet
python3 server.py
```

Then open `web/index.html` through the local server at `http://127.0.0.1:8772/`.

## Termux / KAI 9000 lane

This deliberately avoids current control-plane ports 5901, 6080, and 8767. Ordinary Termux owns the service; Secure Folder / WebView / AcodeX can act as the cockpit client.

## Release rule

`legacy_external` and `unknown` sources are **reference-only**. Release builds may only ship assets explicitly classified as `lum_original` or `generated_original` with provenance.
