from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STATE_PATH = ROOT / "quest-state.json"
MAX_TASK_CHARS = 240
MAX_OBJECTIVES = 6


@dataclass
class QuestState:
    active_task: str = ""
    objectives: list[dict] = field(default_factory=list)
    completed: int = 0
    revision: int = 0

    def clamp(self) -> None:
        self.active_task = str(self.active_task)[:MAX_TASK_CHARS]
        self.objectives = list(self.objectives)[:MAX_OBJECTIVES]
        self.completed = sum(1 for item in self.objectives if bool(item.get("done")))
        self.revision = max(0, int(self.revision))


def load_quest_state() -> QuestState:
    try:
        state = QuestState(**json.loads(STATE_PATH.read_text(encoding="utf-8")))
        state.clamp()
        return state
    except Exception:
        return QuestState()


def save_quest_state(state: QuestState) -> None:
    state.clamp()
    STATE_PATH.write_text(json.dumps(asdict(state), indent=2), encoding="utf-8")


def _clean_task(task: str) -> str:
    text = re.sub(r"[\x00-\x1f\x7f]", " ", str(task or ""))
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        raise ValueError("coding task is required")
    return text[:MAX_TASK_CHARS]


def _objective(label: str, action: str) -> dict:
    return {"label": label, "action": action, "done": False}


def generate_quest(task: str) -> QuestState:
    text = _clean_task(task)
    lowered = text.lower()
    objectives: list[dict] = []

    if any(word in lowered for word in ("bug", "debug", "error", "fail", "crash")):
        objectives.append(_objective("Reproduce the failure and capture the smallest useful signal.", "debug"))
    else:
        objectives.append(_objective("Define the smallest testable change for this task.", "study"))

    if any(word in lowered for word in ("godot", "gdscript", "scene", "sprite", "avatar", "3d")):
        objectives.append(_objective("Mutate the Godot scene or script without breaking the cockpit contract.", "refactor"))
    elif any(word in lowered for word in ("python", "fastapi", "server", "api")):
        objectives.append(_objective("Implement the Python change behind the localhost-only API boundary.", "refactor"))
    else:
        objectives.append(_objective("Implement the smallest safe code change.", "refactor"))

    if any(word in lowered for word in ("android", "apk", "samsung", "s24", "export")):
        objectives.append(_objective("Validate the Samsung Android export profile and arm64 target.", "compile"))
    elif any(word in lowered for word in ("termux", "acode", "acodex", "localhost")):
        objectives.append(_objective("Probe the localhost service contract without crossing the Knox process boundary.", "compile"))
    else:
        objectives.append(_objective("Compile or run the relevant validation gate.", "compile"))

    objectives.append(_objective("Run the green gate and review failures before shipping.", "debug"))
    objectives.append(_objective("Save a checkpoint with a concise change summary.", "ship"))

    state = QuestState(active_task=text, objectives=objectives[:MAX_OBJECTIVES], revision=1)
    state.clamp()
    save_quest_state(state)
    return state


def complete_objective(state: QuestState, index: int) -> QuestState:
    if index < 0 or index >= len(state.objectives):
        raise ValueError("invalid quest objective")
    state.objectives[index]["done"] = True
    state.revision += 1
    state.clamp()
    return state


def complete_for_action(state: QuestState, action: str) -> QuestState:
    action = str(action or "").strip().lower()
    for item in state.objectives:
        if not item.get("done") and str(item.get("action", "")).lower() == action:
            item["done"] = True
            state.revision += 1
            break
    state.clamp()
    return state
