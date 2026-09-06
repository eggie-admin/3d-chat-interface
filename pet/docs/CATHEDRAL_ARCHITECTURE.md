# Tiny Lum Pet Cathedral Architecture

Seal: `TINY_LUM_PET_CATHEDRAL_20260906`

## Purpose

Turn Tiny Lum Pet into a reusable, local-first companion runtime without welding the pet to one art pack, one model provider, or one front end.

## Cathedral lanes

```text
legacy Drive archive
       |
       v
metadata / provenance index
       |
       +--> reference-only registry -----+
       |                                 |
       v                                 v
rights gate                       Lum-owned/generated source
       |                                 |
       +---------------+-----------------+
                       |
                       v
                sprite build lane
                       |
                       v
                 atlas QA gate
                       |
                       v
             Tiny Lum Pet runtime
                       |
                127.0.0.1:8772
                       |
             +---------+----------+
             |                    |
         Godot 4              Web cockpit
```

## 1. Source registry

Every asset source belongs to one lane:

- `legacy_external`: inspect/index only.
- `lum_original`: authored Lum material approved for runtime.
- `generated_original`: generated Lum material with provenance.
- `unknown`: quarantine until reviewed.

The release builder must never silently promote `legacy_external` or `unknown` content.

## 2. Sprite contract

The runtime consumes a provider-neutral atlas manifest. Baseline cell contract is 64x64 with 2px padding and rows for:

`idle, blink, walk, run, jump, cast, shock, hurt, taunt`

Emotion names map to animation states so art filenames can change without rewriting pet behavior.

## 3. Pet state machine

The Python runtime owns only local state:

- state
- mood
- energy
- attention
- affection
- last event
- revision

Values are bounded to 0..100. Jealous / tsundere behavior is theatrical flavor, not coercive pressure.

## 4. Provider antenna

Future language-model responses sit behind an adapter:

```text
pet state -> prompt envelope -> provider adapter -> response -> renderer
```

Local Ollama can be default. OpenAI can be optional. The pet still boots and animates with no model available.

## 5. Godot bridge

`godot/PetBridge.gd` talks to the local Python service over HTTP. Godot remains responsible for rendering, scene animation, audio, and eventual 3D/avatar presentation rather than duplicating state logic.

## 6. Legacy archive doctrine

The supplied Drive archive is useful for studying:

- asset taxonomy
- art-swap organization
- audio / voice replacement organization
- character package naming
- periodic art-pack update patterns

It is not a runtime dependency. Do not ship those game files in a PET APK, web bundle, or public repository unless rights are independently confirmed.

## 7. QA gate

The sealed Tiny Lum baseline enforces:

- jump must leave the idle baseline
- landing must return within 2px
- look-center drift must remain at or below 4px
- look-width ratio must remain at or below 1.15
- hard errors block release
- local frame-difference outliers remain visible warnings

## 8. Android / KAI 9000 lane

Recommended service ownership:

- owner: ordinary Termux
- bind: `127.0.0.1`
- port: `8772`
- client: Secure Folder / WebView / AcodeX / Godot cockpit
- public listener: off by default

This avoids the current KAI control-plane ports 5901, 6080, and 8767.

## 9. Ten-pass release audit

1. Source identity and URI recorded.
2. Rights lane assigned.
3. SHA-256 captured for approved runtime assets.
4. Archive paths checked before extraction.
5. File type classified without execution.
6. Sprite registration tested.
7. Animation continuity tested.
8. Runtime bound to localhost by default.
9. State values clamped and external actions denied by default.
10. Release manifest records provenance and refuses hard QA errors.
