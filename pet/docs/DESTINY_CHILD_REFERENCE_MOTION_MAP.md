# Destiny Child reference audit: Mona -> Lum

This document is a **reference-only technical audit**. It does not authorize redistribution of Destiny Child art, audio, Live2D models, or `.pck` payloads.

## Mona identity

The shared art-pack archive contains `asset/character/c001_01.pck`. Community model databases identify `c001_01` as **Mona**. Related costume IDs include `c001_02` (Battlesuit Mona), `c001_16` (Swimsuit Mona), and `c001_17` (Petit Mona).

## Package format

Destiny Child character packs use a custom `PCK\0` container. Community tooling parses an 8-byte PCK identifier, entry count, per-entry hashes, flags, offsets and compressed/original sizes. Packed entries may be AES-decrypted and Yappy-decompressed before file-type classification.

The extracted character layer is Live2D Cubism 2-era content. Community renderers explicitly load Live2D model data, textures and motion files.

## Mona motion inventory

For `c001_01`, the stable public viewer/tooling contract exposes three primary motion groups:

- `idle`
- `attack`
- `hit`

Expressions are stored separately from motion groups and should be treated as an orthogonal facial-state layer.

## Lum mapping

We use the **motion vocabulary only**, never the proprietary pixels or rig.

| Reference group | Lum 2D sprite tree | Lum 3D animation tree | Dating/JRPG use |
| --- | --- | --- | --- |
| `idle` | `idle`, `blink`, `breathe`, `look_l`, `look_r` | `Idle`, `Idle_Breathe`, `Idle_Look` | conversation idle, party idle, camp idle |
| `attack` | `cast`, `attack`, `victory` | `Cast`, `Attack`, `Spell`, `Victory` | combat command, critical, level-up |
| `hit` | `hurt`, `shock`, `recover` | `Hit`, `Stagger`, `Recover` | damage reaction, failed roll, story shock |
| expressions | `happy`, `smug`, `jealous`, `angry`, `sad`, `cute` | facial blendshape/pose layer | dating choices, banter, affection feedback |

## Cathedral rule

Destiny Child assets stay in `legacy_external` / reference-only lanes. Runtime content must be one of:

1. Lum-owned original art/models.
2. Original generated content with provenance.
3. Community assets with a verified redistributable license, preferably CC0 or MIT.

The goal is to preserve the animation *grammar* while replacing the copyrighted implementation.
