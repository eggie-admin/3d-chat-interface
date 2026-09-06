from __future__ import annotations

import json
import secrets
from dataclasses import asdict, dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STATE_PATH = ROOT / "rpg-state.json"

ROLE_CLASSES = ("Rune Coder", "Daemon Knight", "Patch Mage", "Build Ninja")
ACTIONS = {
    "compile": {"xp": 12, "label": "Compile Encounter"},
    "debug": {"xp": 18, "label": "Debug Hunt"},
    "refactor": {"xp": 22, "label": "Refactor Trial"},
    "ship": {"xp": 30, "label": "Release Boss"},
    "study": {"xp": 10, "label": "Lore Study"},
}


@dataclass
class RPGState:
    level: int = 1
    xp: int = 0
    xp_next: int = 100
    role_class: str = "Rune Coder"
    title: str = "Cathedral Initiate"
    streak: int = 0
    quests_completed: int = 0
    last_roll: int = 0
    last_action: str | None = None
    last_result: str = "Awaiting command."
    revision: int = 0

    def clamp(self) -> None:
        self.level = max(1, min(99, int(self.level)))
        self.xp = max(0, int(self.xp))
        self.xp_next = max(25, int(self.xp_next))
        self.streak = max(0, min(999, int(self.streak)))
        self.quests_completed = max(0, int(self.quests_completed))
        if self.role_class not in ROLE_CLASSES:
            self.role_class = ROLE_CLASSES[0]


def load_rpg_state() -> RPGState:
    try:
        return RPGState(**json.loads(STATE_PATH.read_text(encoding="utf-8")))
    except Exception:
        return RPGState()


def save_rpg_state(state: RPGState) -> None:
    state.clamp()
    STATE_PATH.write_text(json.dumps(asdict(state), indent=2), encoding="utf-8")


def _level_up(state: RPGState) -> list[str]:
    notes: list[str] = []
    while state.level < 99 and state.xp >= state.xp_next:
        state.xp -= state.xp_next
        state.level += 1
        state.xp_next = int(round(state.xp_next * 1.18))
        state.title = _title_for_level(state.level)
        notes.append(f"LEVEL UP {state.level}: {state.title}")
    return notes


def _title_for_level(level: int) -> str:
    if level >= 50:
        return "Cathedral Architect"
    if level >= 30:
        return "Blue Magic Engineer"
    if level >= 20:
        return "Daemon Tamer"
    if level >= 10:
        return "Senior Rune Coder"
    if level >= 5:
        return "Patch Adept"
    return "Cathedral Initiate"


def perform_action(state: RPGState, action: str) -> RPGState:
    name = (action or "").strip().lower()
    if name not in ACTIONS:
        raise ValueError(f"unknown RPG action: {action}")

    roll = secrets.randbelow(20) + 1
    base_xp = ACTIONS[name]["xp"]
    bonus = 0
    result = "SUCCESS"

    if roll == 20:
        bonus = base_xp
        result = "NATURAL 20"
    elif roll == 1:
        result = "COMPILE GREMLIN"
        state.streak = 0
    elif roll >= 15:
        bonus = 8
        result = "CRITICAL CLEAN"
    elif roll <= 5:
        bonus = -min(5, base_xp - 1)
        result = "PATCH REQUIRED"

    gained = max(1, base_xp + bonus)
    state.xp += gained
    state.streak += 1
    state.quests_completed += 1
    state.last_roll = roll
    state.last_action = name
    state.revision += 1

    notes = _level_up(state)
    suffix = f" | {' / '.join(notes)}" if notes else ""
    state.last_result = f"{ACTIONS[name]['label']}: d20={roll} {result}, +{gained} XP{suffix}"
    state.clamp()
    return state


def set_role_class(state: RPGState, role_class: str) -> RPGState:
    if role_class not in ROLE_CLASSES:
        raise ValueError("invalid role class")
    state.role_class = role_class
    state.revision += 1
    state.last_result = f"Job changed to {role_class}."
    return state
