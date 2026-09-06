extends Node

signal scene_started(scene: Dictionary)
signal choice_resolved(result: Dictionary)

const SCENES := {
    "lum_camp_01": {
        "npc_id": "lum",
        "beat": "camp_banter",
        "prompt": "The camp terminal hums while Lum pretends not to watch you debug by firelight.",
        "choices": [
            {"id":"ask_help","text":"Ask her to review the patch.","delta":{"trust":6,"respect":5,"spark":2,"jealousy":0}},
            {"id":"tease","text":"Tell her the bug is obviously afraid of her.","delta":{"trust":2,"respect":0,"spark":5,"jealousy":1}},
            {"id":"focus","text":"Finish the work first, then share the result.","delta":{"trust":3,"respect":7,"spark":0,"jealousy":0}}
        ]
    },
    "mara_camp_01": {
        "npc_id": "mara_voss",
        "beat": "quiet_scene",
        "prompt": "Mara repairs a dented shield and asks why you keep taking impossible jobs.",
        "choices": [
            {"id":"duty","text":"Because somebody has to finish them.","delta":{"trust":4,"respect":7,"spark":1,"jealousy":0}},
            {"id":"people","text":"Because the people beside me matter.","delta":{"trust":7,"respect":3,"spark":5,"jealousy":0}}
        ]
    },
    "nyx_camp_01": {
        "npc_id": "nyx_arden",
        "beat": "camp_banter",
        "prompt": "Nyx has rewritten the weather station to predict ghosts instead of rain.",
        "choices": [
            {"id":"encourage","text":"Ask for the source code.","delta":{"trust":4,"respect":6,"spark":4,"jealousy":0}},
            {"id":"rollback","text":"Make her put the weather back first.","delta":{"trust":1,"respect":5,"spark":1,"jealousy":2}}
        ]
    }
}

func scene(scene_id: String) -> Dictionary:
    var value: Dictionary = SCENES.get(scene_id, {}).duplicate(true)
    if not value.is_empty():
        value["scene_id"] = scene_id
        scene_started.emit(value)
    return value

func choose(scene_id: String, choice_id: String) -> Dictionary:
    var data: Dictionary = SCENES.get(scene_id, {})
    if data.is_empty():
        return {"ok": false, "error": "unknown scene"}
    for choice in data.get("choices", []):
        if str(choice.get("id", "")) == choice_id:
            var npc_id := str(data.get("npc_id", ""))
            var bond := DatingDirector.apply_choice(npc_id, choice.get("delta", {}))
            var result := {
                "ok": true,
                "scene_id": scene_id,
                "choice_id": choice_id,
                "npc_id": npc_id,
                "bond": bond,
            }
            choice_resolved.emit(result)
            return result
    return {"ok": false, "error": "unknown choice"}

func available_scenes(npc_id: String = "") -> Array:
    var result: Array = []
    for scene_id in SCENES:
        var scene_data: Dictionary = SCENES[scene_id]
        if npc_id.is_empty() or str(scene_data.get("npc_id", "")) == npc_id:
            result.append(scene_id)
    return result
