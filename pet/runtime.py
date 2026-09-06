from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STATE_PATH = ROOT / "state.json"


@dataclass
class PetState:
    state: str = "idle"
    mood: str = "neutral"
    energy: int = 80
    attention: int = 50
    affection: int = 50
    last_event: str | None = None
    revision: int = 0

    def clamp(self) -> None:
        self.energy = max(0, min(100, int(self.energy)))
        self.attention = max(0, min(100, int(self.attention)))
        self.affection = max(0, min(100, int(self.affection)))


def load_state() -> PetState:
    try:
        return PetState(**json.loads(STATE_PATH.read_text(encoding="utf-8")))
    except Exception:
        return PetState()


def save_state(state: PetState) -> None:
    state.clamp()
    STATE_PATH.write_text(json.dumps(asdict(state), indent=2), encoding="utf-8")


def apply_event(state: PetState, event: str) -> PetState:
    name = (event or "").strip().lower()
    state.last_event = name
    state.revision += 1

    if name == "tap":
        state.state, state.mood = "idle", "happy"
        state.attention += 8
        state.affection += 2
    elif name == "double_tap":
        state.state, state.mood = "jump", "happy"
        state.energy -= 4
        state.attention += 5
    elif name == "praise":
        state.state, state.mood = "idle", "cute"
        state.affection += 6
        state.attention += 3
    elif name == "message":
        state.state, state.mood = "idle", "smug"
        state.attention += 4
    elif name == "ignore":
        state.state, state.mood = "taunt", "jealous"
        state.attention -= 4
    elif name == "focus":
        state.state, state.mood = "cast", "neutral"
        state.energy -= 2
    elif name == "jump":
        state.state = "jump"
        state.energy -= 4
    elif name == "sleep":
        state.state, state.mood = "sleep", "neutral"
    elif name == "wake":
        state.state, state.mood = "idle", "neutral"
        state.energy += 20
    elif name == "reset":
        state = PetState()
    else:
        raise ValueError(f"unknown event: {event}")

    state.clamp()
    return state
