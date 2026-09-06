#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "godot" / "jrpg" / "data" / "cathedral_content.json"
RUNTIME = ROOT / "godot" / "jrpg"

ALLOWED_LICENSES = {"CC0-1.0", "MIT"}
FORBIDDEN_EXTENSIONS = {".pck", ".moc", ".mtn"}
FORBIDDEN_NAME_TOKENS = {"destiny_child", "destiny-child"}


def main() -> int:
    errors: list[str] = []
    checks: list[str] = []

    data = json.loads(CONTENT.read_text(encoding="utf-8"))
    regions = data.get("world", {}).get("regions", [])
    npcs = data.get("npcs", [])
    monsters = data.get("monsters", [])
    assets = data.get("community_assets", [])

    if len(regions) < 5:
        errors.append("need at least five overworld regions")
    else:
        checks.append("overworld regions")

    if len(npcs) < 5:
        errors.append("need at least five NPCs")
    else:
        checks.append("NPC roster")

    if len(monsters) < 6:
        errors.append("need at least six monsters")
    else:
        checks.append("monster roster")

    romance_npcs = [npc for npc in npcs if npc.get("romance")]
    if not romance_npcs:
        errors.append("dating layer needs at least one romance-enabled NPC")
    for npc in romance_npcs:
        if not npc.get("route"):
            errors.append(f"romance NPC missing route: {npc.get('id')}")
    if romance_npcs and all(npc.get("route") for npc in romance_npcs):
        checks.append("dating routes")

    for asset in assets:
        if asset.get("license") not in ALLOWED_LICENSES:
            errors.append(f"unapproved community asset license: {asset.get('id')}={asset.get('license')}")
    if assets and not any("unapproved community asset license" in e for e in errors):
        checks.append("community license registry")

    leaked = []
    for path in RUNTIME.rglob("*"):
        if not path.is_file():
            continue
        name = path.name.lower()
        if path.suffix.lower() in FORBIDDEN_EXTENSIONS or any(token in name for token in FORBIDDEN_NAME_TOKENS):
            leaked.append(str(path.relative_to(ROOT)))
    if leaked:
        errors.append("reference-only proprietary formats found in runtime: " + ", ".join(leaked))
    else:
        checks.append("proprietary runtime firewall")

    required_scripts = [
        RUNTIME / "CathedralDirector.gd",
        RUNTIME / "DatingDirector.gd",
        RUNTIME / "RoleplayDirector.gd",
        RUNTIME / "BattleDirector.gd",
        RUNTIME / "OverworldMap.gd",
        RUNTIME / "AnimationTaxonomy.gd",
    ]
    missing = [str(p.relative_to(ROOT)) for p in required_scripts if not p.exists()]
    if missing:
        errors.append("missing JRPG systems: " + ", ".join(missing))
    else:
        checks.append("JRPG system scripts")

    result = {
        "ok": not errors,
        "seal": "KAI9000_JRPG_DATING_CATHEDRAL_GREEN_20260906",
        "checks": checks,
        "errors": errors,
        "counts": {
            "regions": len(regions),
            "npcs": len(npcs),
            "monsters": len(monsters),
            "romance_npcs": len(romance_npcs),
            "community_assets": len(assets),
        },
    }
    print(json.dumps(result, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
