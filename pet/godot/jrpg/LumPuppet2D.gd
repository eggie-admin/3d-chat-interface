extends Node2D
class_name LumPuppet2D

signal state_changed(state: String)

const CONFIG_PATH := "res://assets/lum/puppet/lum_puppet.json"

const DEFAULT_PARAMETERS := {
    "angle_x": 0.0,
    "angle_y": 0.0,
    "angle_z": 0.0,
    "body_sway": 0.25,
    "breath": 0.35,
    "eye_open": 1.0,
    "mouth_open": 0.0,
    "mouth_smile": 0.0,
    "hair_sway": 0.35,
    "tail_sway": 0.45,
    "wing_open": 0.15,
}

const STATE_TARGETS := {
    "idle": {"body_sway": 0.25, "breath": 0.35, "eye_open": 1.0, "mouth_smile": 0.0, "wing_open": 0.15},
    "blink": {"eye_open": 0.05},
    "happy": {"mouth_smile": 1.0, "body_sway": 0.4, "breath": 0.45, "eye_open": 0.9},
    "smug": {"mouth_smile": 0.75, "angle_z": 0.08, "angle_x": 0.15, "eye_open": 0.75},
    "jealous": {"mouth_smile": 0.1, "angle_z": -0.06, "eye_open": 0.7, "tail_sway": 0.8},
    "angry": {"mouth_smile": 0.0, "angle_z": -0.04, "eye_open": 0.65, "wing_open": 0.45, "body_sway": 0.55},
    "sad": {"mouth_smile": 0.0, "angle_z": 0.03, "angle_y": -0.12, "eye_open": 0.55, "body_sway": 0.12},
    "cute": {"mouth_smile": 1.0, "angle_z": 0.06, "eye_open": 0.95, "breath": 0.5},
    "cast": {"mouth_open": 0.35, "wing_open": 0.7, "body_sway": 0.65, "angle_x": 0.18},
    "hurt": {"mouth_open": 0.2, "eye_open": 0.45, "angle_z": -0.11, "body_sway": 0.0},
    "victory": {"mouth_smile": 1.0, "wing_open": 1.0, "body_sway": 0.7, "breath": 0.55, "eye_open": 1.0},
}

var parameters := DEFAULT_PARAMETERS.duplicate(true)
var targets := DEFAULT_PARAMETERS.duplicate(true)
var _groups: Dictionary = {}
var _layers: Dictionary = {}
var _base_positions: Dictionary = {}
var _base_rotations: Dictionary = {}
var _base_scales: Dictionary = {}
var _time := 0.0
var _state := "idle"
var _loaded_layers := 0
var _stage_origin := Vector2(360.0, 380.0)
var _stage_scale := 0.36


func configure(path := CONFIG_PATH) -> bool:
    if not FileAccess.file_exists(path):
        return false
    var raw := FileAccess.get_file_as_string(path)
    var parsed = JSON.parse_string(raw)
    if not (parsed is Dictionary):
        return false

    _stage_origin = _vec2(parsed.get("stage_origin", [360.0, 380.0]), _stage_origin)
    _stage_scale = float(parsed.get("stage_scale", _stage_scale))
    _build_group_tree()

    for layer_data in parsed.get("layers", []):
        if not (layer_data is Dictionary):
            continue
        var texture_path := str(layer_data.get("texture", ""))
        if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
            continue
        var texture = load(texture_path)
        if not (texture is Texture2D):
            continue

        var layer_name := str(layer_data.get("name", "layer_%d" % _loaded_layers))
        var group_name := str(layer_data.get("group", "body"))
        var parent: Node2D = _groups.get(group_name, self)
        var sprite := Sprite2D.new()
        sprite.name = layer_name
        sprite.texture = texture
        sprite.centered = true
        sprite.position = _vec2(layer_data.get("position", [0.0, 0.0]), Vector2.ZERO)
        sprite.scale = _vec2(layer_data.get("scale", [1.0, 1.0]), Vector2.ONE)
        sprite.rotation = deg_to_rad(float(layer_data.get("rotation_deg", 0.0)))
        sprite.z_index = int(layer_data.get("z", _loaded_layers))
        parent.add_child(sprite)
        _layers[layer_name] = sprite
        _loaded_layers += 1

    _capture_base_transforms()
    play_state("idle", true)
    return _loaded_layers > 0


func _build_group_tree() -> void:
    var body := Node2D.new()
    body.name = "BodyRig"
    add_child(body)
    _groups["body"] = body

    var head := Node2D.new()
    head.name = "HeadRig"
    body.add_child(head)
    _groups["head"] = head

    for group_name in ["hair_back", "face", "eyes", "mouth", "hair_front"]:
        var node := Node2D.new()
        node.name = str(group_name).capitalize().replace(" ", "") + "Rig"
        head.add_child(node)
        _groups[group_name] = node

    for group_name in ["outfit", "wings", "tail", "accessories"]:
        var node := Node2D.new()
        node.name = str(group_name).capitalize().replace(" ", "") + "Rig"
        body.add_child(node)
        _groups[group_name] = node


func _capture_base_transforms() -> void:
    for key in _groups.keys():
        var node: Node2D = _groups[key]
        _base_positions[key] = node.position
        _base_rotations[key] = node.rotation
        _base_scales[key] = node.scale


func _vec2(value, fallback: Vector2) -> Vector2:
    if value is Array and value.size() >= 2:
        return Vector2(float(value[0]), float(value[1]))
    return fallback


func is_ready_for_stage() -> bool:
    return _loaded_layers > 0


func loaded_layer_count() -> int:
    return _loaded_layers


func stage_origin() -> Vector2:
    return _stage_origin


func stage_scale() -> float:
    return _stage_scale


func set_parameter(name: String, value: float) -> void:
    if targets.has(name):
        targets[name] = value


func play_state(state: String, immediate := false) -> void:
    var resolved := state if STATE_TARGETS.has(state) else "idle"
    _state = resolved
    targets = DEFAULT_PARAMETERS.duplicate(true)
    for key in STATE_TARGETS[resolved].keys():
        targets[key] = STATE_TARGETS[resolved][key]
    if immediate:
        parameters = targets.duplicate(true)
    state_changed.emit(_state)


func set_mood(mood: String) -> void:
    var mood_to_state := {
        "neutral": "idle",
        "happy": "happy",
        "smug": "smug",
        "jealous": "jealous",
        "angry": "angry",
        "sad": "sad",
        "cute": "cute",
    }
    play_state(str(mood_to_state.get(mood, "idle")))


func _process(delta: float) -> void:
    _time += delta
    var blend := clamp(delta * 8.0, 0.0, 1.0)
    for key in parameters.keys():
        parameters[key] = lerpf(float(parameters[key]), float(targets[key]), blend)
    _apply_parameters()


func _apply_parameters() -> void:
    if _groups.is_empty():
        return

    var blink_phase := fmod(_time, 4.2)
    var auto_eye := 0.05 if blink_phase > 4.02 else 1.0
    var eye_open: float = min(float(parameters["eye_open"]), auto_eye)
    var breath := sin(_time * 2.0) * float(parameters["breath"])
    var sway := sin(_time * 1.25) * float(parameters["body_sway"])
    var hair := sin(_time * 1.7 + 0.8) * float(parameters["hair_sway"])
    var tail := sin(_time * 2.1 + 1.6) * float(parameters["tail_sway"])

    var body: Node2D = _groups["body"]
    body.position = _base_positions["body"] + Vector2(sway * 5.0, -breath * 4.0)
    body.rotation = _base_rotations["body"] + sway * 0.012
    body.scale = _base_scales["body"] * Vector2(1.0 + breath * 0.01, 1.0 - breath * 0.006)

    var head: Node2D = _groups["head"]
    head.position = _base_positions["head"] + Vector2(float(parameters["angle_x"]) * 8.0, float(parameters["angle_y"]) * 7.0)
    head.rotation = _base_rotations["head"] + float(parameters["angle_z"]) + sway * 0.02

    for key in ["hair_back", "hair_front"]:
        var hair_group: Node2D = _groups[key]
        hair_group.rotation = _base_rotations[key] + hair * 0.04 - float(parameters["angle_x"]) * 0.02

    var wings: Node2D = _groups["wings"]
    var wing_open := clamp(float(parameters["wing_open"]), 0.0, 1.0)
    wings.rotation = _base_rotations["wings"] + sin(_time * 2.4) * 0.025 * wing_open
    wings.scale = _base_scales["wings"] * Vector2(1.0 + wing_open * 0.08, 1.0 + wing_open * 0.05)

    var tail_group: Node2D = _groups["tail"]
    tail_group.rotation = _base_rotations["tail"] + tail * 0.09

    var eyes: Node2D = _groups["eyes"]
    eyes.scale = _base_scales["eyes"] * Vector2(1.0, max(0.08, eye_open))

    var mouth_open := clamp(float(parameters["mouth_open"]), 0.0, 1.0)
    var mouth_group: Node2D = _groups["mouth"]
    mouth_group.scale = _base_scales["mouth"] * Vector2(1.0, 1.0 + mouth_open * 0.22)

    _set_layer_alpha("mouth_neutral", 1.0 - clamp(float(parameters["mouth_smile"]), 0.0, 1.0))
    _set_layer_alpha("mouth_smile", clamp(float(parameters["mouth_smile"]), 0.0, 1.0))
    _set_layer_alpha("eyes_open", eye_open)
    _set_layer_alpha("eyes_closed", 1.0 - eye_open)


func _set_layer_alpha(layer_name: String, alpha: float) -> void:
    if not _layers.has(layer_name):
        return
    var sprite: Sprite2D = _layers[layer_name]
    var color := sprite.modulate
    color.a = clamp(alpha, 0.0, 1.0)
    sprite.modulate = color
