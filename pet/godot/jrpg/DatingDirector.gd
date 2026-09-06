extends Node

signal bond_changed(npc_id: String, state: Dictionary)
signal route_locked(npc_id: String)

const CONTENT_PATH := "res://data/cathedral_content.json"
const STAT_KEYS := ["trust", "spark", "respect", "jealousy"]

var bonds: Dictionary = {}
var locked_route := ""

func _ready() -> void:
    _seed_routes()

func _seed_routes() -> void:
    var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    for npc in parsed.get("npcs", []):
        if bool(npc.get("romance", false)):
            var npc_id := str(npc.get("id", ""))
            bonds[npc_id] = {"trust": 10, "spark": 0, "respect": 10, "jealousy": 0, "stage": "strangers"}

func apply_choice(npc_id: String, deltas: Dictionary) -> Dictionary:
    if not bonds.has(npc_id):
        return {}
    var state: Dictionary = bonds[npc_id].duplicate(true)
    for key in STAT_KEYS:
        if deltas.has(key):
            state[key] = clampi(int(state.get(key, 0)) + int(deltas[key]), 0, 100)
    state["stage"] = _route_stage(state)
    bonds[npc_id] = state
    bond_changed.emit(npc_id, state)
    return state

func _route_stage(state: Dictionary) -> String:
    var trust := int(state.get("trust", 0))
    var spark := int(state.get("spark", 0))
    var respect := int(state.get("respect", 0))
    if trust >= 80 and spark >= 70 and respect >= 70:
        return "route_ready"
    if trust >= 55 and respect >= 45:
        return "confidante"
    if trust >= 30 or spark >= 25:
        return "warming"
    return "strangers"

func can_lock_route(npc_id: String) -> bool:
    if locked_route != "" or not bonds.has(npc_id):
        return false
    return str(bonds[npc_id].get("stage", "")) == "route_ready"

func lock_route(npc_id: String) -> bool:
    if not can_lock_route(npc_id):
        return false
    locked_route = npc_id
    route_locked.emit(npc_id)
    return true

func get_bond(npc_id: String) -> Dictionary:
    return bonds.get(npc_id, {}).duplicate(true)

func save_payload() -> Dictionary:
    return {"bonds": bonds.duplicate(true), "locked_route": locked_route}

func load_payload(payload: Dictionary) -> void:
    var restored = payload.get("bonds", {})
    if typeof(restored) == TYPE_DICTIONARY:
        bonds = restored.duplicate(true)
    locked_route = str(payload.get("locked_route", ""))
