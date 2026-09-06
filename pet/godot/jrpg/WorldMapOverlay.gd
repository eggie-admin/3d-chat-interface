extends CanvasLayer

var _map_root: Control
var _map_button: Button

func _ready() -> void:
    layer = 90
    _map_button = Button.new()
    _map_button.text = "WORLD MAP"
    _map_button.position = Vector2(22, 650)
    _map_button.size = Vector2(150, 46)
    _map_button.pressed.connect(_toggle_map)
    add_child(_map_button)

func _toggle_map() -> void:
    if is_instance_valid(_map_root):
        _map_root.queue_free()
        _map_root = null
        _map_button.text = "WORLD MAP"
        return

    _map_root = Control.new()
    _map_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_map_root)

    var dim := ColorRect.new()
    dim.color = Color(0.02, 0.03, 0.06, 0.96)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _map_root.add_child(dim)

    var map_scene := load("res://OverworldMap.tscn")
    var map: Control = map_scene.instantiate()
    map.position = Vector2(40, 56)
    map.size = Vector2(1200, 610)
    map.travel_requested.connect(_on_travel)
    _map_root.add_child(map)

    var title := Label.new()
    title.text = "KAI 9000 // PILGRIMAGE OVERWORLD"
    title.position = Vector2(48, 14)
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color("c8a85a"))
    _map_root.add_child(title)

    var close := Button.new()
    close.text = "CLOSE"
    close.position = Vector2(1120, 12)
    close.size = Vector2(110, 36)
    close.pressed.connect(_toggle_map)
    _map_root.add_child(close)
    _map_button.text = "CLOSE MAP"

func _on_travel(region_id: String) -> void:
    var region := CathedralDirector.get_region(region_id)
    _map_button.text = "MAP: %s" % str(region.get("name", region_id))
