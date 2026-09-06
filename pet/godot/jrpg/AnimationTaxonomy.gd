extends RefCounted
class_name AnimationTaxonomy

const REFERENCE_TO_LUM_2D := {
    "idle": ["idle", "blink", "breathe", "look_l", "look_r"],
    "attack": ["cast", "attack", "victory"],
    "hit": ["hurt", "shock", "recover"],
    "expressions": ["happy", "smug", "jealous", "angry", "sad", "cute"],
}

const REFERENCE_TO_LUM_3D := {
    "idle": ["Idle", "Idle_Breathe", "Idle_Look"],
    "attack": ["Cast", "Attack", "Spell", "Victory"],
    "hit": ["Hit", "Stagger", "Recover"],
    "expressions": ["Face_Happy", "Face_Smug", "Face_Jealous", "Face_Angry", "Face_Sad", "Face_Cute"],
}

static func sprite_actions(reference_group: String) -> Array:
    return REFERENCE_TO_LUM_2D.get(reference_group, []).duplicate()

static func model_actions(reference_group: String) -> Array:
    return REFERENCE_TO_LUM_3D.get(reference_group, []).duplicate()

static func is_reference_group(value: String) -> bool:
    return REFERENCE_TO_LUM_2D.has(value)
