extends Control
class_name OverworldMap

signal travel_requested(region_id: String)

const PIN_POSITIONS := {
    "glass_coast": Vector2(0.14, 0.72),
    "blue_steppe": Vector2(0.34, 0.54),
    "ashen_canals": Vector2(0.55, 0.66),
    "starfall_range": Vector2(0.72, 0.32),
    "cathedral_of_static": Vector2(0.88, 0.18),
}

var _buttons: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()
    call_deferred("_build_pins")

func _build_pins() -> void:
    for child in get_children():
        child.queue_free()
    _buttons.clear()
    for region in CathedralDirector.regions():
        var region_id := str(region.get("id", ""))
        var button := Button.new()
        button.text = str(region.get("name", region_id))
        button.tooltip_text = "%s\nLv %s-%s\nHub: %s" % [
            str(region.get("theme", "")),
            str(region.get("level_band", [0, 0])[0]),
            str(region.get("level_band", [0, 0])[1]),
            str(region.get("hub", "")),
        ]
        button.custom_minimum_size = Vector2(160, 44)
        var uv: Vector2 = PIN_POSITIONS.get(region_id, Vector2(0.5, 0.5))
        button.position = Vector2(size.x * uv.x - 80.0, size.y * uv.y - 22.0)
        button.pressed.connect(_on_pin_pressed.bind(region_id))
        add_child(button)
        _buttons[region_id] = button

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_inside_tree():
        for region_id in _buttons:
            var button: Button = _buttons[region_id]
            var uv: Vector2 = PIN_POSITIONS.get(region_id, Vector2(0.5, 0.5))
            button.position = Vector2(size.x * uv.x - 80.0, size.y * uv.y - 22.0)
        queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("0b1320"), true)
    var ordered := ["glass_coast", "blue_steppe", "ashen_canals", "starfall_range", "cathedral_of_static"]
    var points := PackedVector2Array()
    for region_id in ordered:
        var uv: Vector2 = PIN_POSITIONS[region_id]
        points.append(Vector2(size.x * uv.x, size.y * uv.y))
    if points.size() > 1:
        draw_polyline(points, Color("4d78b5"), 4.0, true)
    for p in points:
        draw_circle(p, 11.0, Color("c8a85a"))
        draw_circle(p, 5.0, Color("17263a"))

func _on_pin_pressed(region_id: String) -> void:
    if CathedralDirector.travel_to(region_id):
        travel_requested.emit(region_id)
        queue_redraw()
