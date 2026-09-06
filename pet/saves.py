from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAVE_DIR = ROOT / "save-slots"
VALID_SLOTS = {1, 2, 3}


def _slot_path(slot: int) -> Path:
    value = int(slot)
    if value not in VALID_SLOTS:
        raise ValueError("save slot must be 1, 2, or 3")
    SAVE_DIR.mkdir(parents=True, exist_ok=True)
    return SAVE_DIR / f"slot-{value}.json"


def save_slot(slot: int, rpg: dict, quest: dict) -> dict:
    path = _slot_path(slot)
    payload = {
        "slot": int(slot),
        "saved_at": datetime.now(timezone.utc).isoformat(),
        "rpg": dict(rpg),
        "quest": dict(quest),
    }
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return payload


def load_slot(slot: int) -> dict:
    path = _slot_path(slot)
    if not path.exists():
        raise ValueError("save slot is empty")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or int(payload.get("slot", 0)) != int(slot):
        raise ValueError("save slot is invalid")
    if not isinstance(payload.get("rpg"), dict) or not isinstance(payload.get("quest"), dict):
        raise ValueError("save slot payload is invalid")
    return payload


def list_slots() -> list[dict]:
    slots: list[dict] = []
    for slot in sorted(VALID_SLOTS):
        path = _slot_path(slot)
        if not path.exists():
            slots.append({"slot": slot, "occupied": False})
            continue
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            rpg = payload.get("rpg", {})
            quest = payload.get("quest", {})
            slots.append({
                "slot": slot,
                "occupied": True,
                "saved_at": payload.get("saved_at"),
                "level": int(rpg.get("level", 1)),
                "role_class": str(rpg.get("role_class", "Rune Coder")),
                "task": str(quest.get("active_task", ""))[:80],
            })
        except Exception:
            slots.append({"slot": slot, "occupied": True, "invalid": True})
    return slots
