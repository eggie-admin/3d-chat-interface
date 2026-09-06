extends Node

@export var bridge_path: NodePath
@export var sprite_path: NodePath
@export var fallback_animation := "idle"

var _bridge: Node
var _sprite: AnimatedSprite2D


func _ready() -> void:
    _bridge = get_node_or_null(bridge_path)
    _sprite = get_node_or_null(sprite_path) as AnimatedSprite2D
    if _bridge == null or _sprite == null:
        push_warning("PetAnimator is missing its bridge or AnimatedSprite2D")
        return
    if _bridge.has_signal("pet_state_updated"):
        _bridge.pet_state_updated.connect(_on_pet_state_updated)
    if _bridge.has_method("refresh_state"):
        _bridge.refresh_state()


func _on_pet_state_updated(state: Dictionary) -> void:
    var requested := String(state.get("state", fallback_animation))
    if requested == "sleep" and not _has_animation("sleep"):
        requested = "idle"
    if not _has_animation(requested):
        requested = _mood_animation(String(state.get("mood", "neutral")))
    if not _has_animation(requested):
        requested = fallback_animation
    if _has_animation(requested) and _sprite.animation != requested:
        _sprite.play(requested)


func _mood_animation(mood: String) -> String:
    match mood:
        "happy", "cute":
            return "blink"
        "smug", "jealous":
            return "taunt"
        "angry":
            return "cast"
        "sad":
            return "hurt"
        _:
            return "idle"


func _has_animation(name: String) -> bool:
    return _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(name)
