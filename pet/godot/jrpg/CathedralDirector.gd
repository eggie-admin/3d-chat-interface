extends Node

signal region_changed(region: Dictionary)
signal encounter_requested(monster: Dictionary)
signal npc_focus_changed(npc: Dictionary)

const CONTENT_PATH := "res://data/cathedral_content.json"

var content: Dictionary = {}
var current_region_id := "glass_coast"
var focused_npc_id := "lum"
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    _load_content()

func _load_content() -> void:
    if not FileAccess.file_exists(CONTENT_PATH):
        push_error("Cathedral content missing: %s" % CONTENT_PATH)
        content = {}
        return
    var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Cathedral content is not valid JSON")
        content = {}
        return
    content = parsed

func regions() -> Array:
    return content.get("world", {}).get("regions", [])

func npcs() -> Array:
    return content.get("npcs", [])

func monsters() -> Array:
    return content.get("monsters", [])

func get_region(region_id: String) -> Dictionary:
    for region in regions():
        if str(region.get("id", "")) == region_id:
            return region
    return {}

func get_npc(npc_id: String) -> Dictionary:
    for npc in npcs():
        if str(npc.get("id", "")) == npc_id:
            return npc
    return {}

func monsters_for_region(region_id: String) -> Array:
    var result: Array = []
    for monster in monsters():
        if str(monster.get("region", "")) == region_id:
            result.append(monster)
    return result

func travel_to(region_id: String) -> bool:
    var region := get_region(region_id)
    if region.is_empty():
        return false
    current_region_id = region_id
    region_changed.emit(region)
    return true

func focus_npc(npc_id: String) -> bool:
    var npc := get_npc(npc_id)
    if npc.is_empty():
        return false
    focused_npc_id = npc_id
    npc_focus_changed.emit(npc)
    return true

func roll_encounter(force_monster_id: String = "") -> Dictionary:
    var pool := monsters_for_region(current_region_id)
    if pool.is_empty():
        return {}
    var selected: Dictionary = {}
    if not force_monster_id.is_empty():
        for monster in pool:
            if str(monster.get("id", "")) == force_monster_id:
                selected = monster
                break
    if selected.is_empty():
        selected = pool[rng.randi_range(0, pool.size() - 1)]
    encounter_requested.emit(selected)
    return selected

func world_snapshot() -> Dictionary:
    return {
        "region": get_region(current_region_id),
        "npc": get_npc(focused_npc_id),
        "available_monsters": monsters_for_region(current_region_id),
    }
