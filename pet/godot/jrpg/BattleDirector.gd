extends Node

signal battle_started(monster: Dictionary)
signal battle_log(line: String)
signal battle_finished(victory: bool, rewards: Dictionary)

var active := false
var enemy: Dictionary = {}
var enemy_hp := 0
var turn := 0

func start_battle(monster: Dictionary) -> bool:
    if active or monster.is_empty():
        return false
    enemy = monster.duplicate(true)
    enemy_hp = _enemy_max_hp(enemy)
    turn = 1
    active = true
    battle_started.emit(enemy)
    battle_log.emit("A %s blocks the pilgrimage road." % str(enemy.get("name", "monster")))
    return true

func command(action: String, actor_id: String = "lum") -> Dictionary:
    if not active:
        return {"ok": false, "error": "no active battle"}
    var normalized := action.strip_edges().to_lower()
    if normalized not in ["attack", "skill", "guard", "item", "bond", "escape"]:
        return {"ok": false, "error": "unknown battle command"}

    var result := {"ok": true, "action": normalized, "turn": turn}
    match normalized:
        "attack":
            var damage := 8 + turn * 2
            enemy_hp = maxi(0, enemy_hp - damage)
            battle_log.emit("%s attacks for %d." % [actor_id.capitalize(), damage])
        "skill":
            var damage := 14 + turn * 2
            enemy_hp = maxi(0, enemy_hp - damage)
            battle_log.emit("%s invokes a rune for %d." % [actor_id.capitalize(), damage])
        "guard":
            battle_log.emit("%s braces behind the blue ward." % actor_id.capitalize())
        "item":
            battle_log.emit("%s uses a field item." % actor_id.capitalize())
        "bond":
            var bond := DatingDirector.get_bond("lum")
            var power := 10 + int(bond.get("trust", 0)) / 5
            enemy_hp = maxi(0, enemy_hp - power)
            battle_log.emit("Bond art flashes for %d." % power)
        "escape":
            active = false
            battle_log.emit("The party withdraws and regroups.")
            battle_finished.emit(false, {})
            return result

    result["enemy_hp"] = enemy_hp
    if enemy_hp <= 0:
        var rewards := _rewards(enemy)
        active = false
        battle_log.emit("Victory. The road opens.")
        battle_finished.emit(true, rewards)
        result["victory"] = true
        result["rewards"] = rewards
        return result

    turn += 1
    battle_log.emit("%s answers with %s." % [str(enemy.get("name", "Enemy")), str(enemy.get("behavior", "an attack"))])
    return result

func _enemy_max_hp(monster: Dictionary) -> int:
    if str(monster.get("family", "")) == "boss":
        return 180
    var region := str(monster.get("region", ""))
    var tier: int = int({
        "glass_coast": 34,
        "blue_steppe": 48,
        "ashen_canals": 62,
        "starfall_range": 82,
        "cathedral_of_static": 110,
    }.get(region, 40))
    return tier

func _rewards(monster: Dictionary) -> Dictionary:
    return {
        "xp": 20 + turn * 4,
        "drops": monster.get("drops", []).duplicate(),
        "monster_id": monster.get("id", ""),
    }
