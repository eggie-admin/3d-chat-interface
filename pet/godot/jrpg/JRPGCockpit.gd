extends Node

const BASE_URL := "http://127.0.0.1:8772"
const GOLD := Color("c5a469")
const DEEP_BLUE := Color("11182b")
const PANEL_BLUE := Color("18223b")
const PANEL_BLUE_2 := Color("223252")
const INK := Color("080a10")
const WHITE := Color("f4f1e8")
const MUTED := Color("9ba8bf")
const GREEN := Color("62d890")
const RED := Color("e06b75")

var _root: Control
var _request: HTTPRequest
var _pending_kind := ""
var _pending_payload: Dictionary = {}

var _level_label: Label
var _class_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _quest_log: RichTextLabel
var _service_grid: GridContainer
var _service_labels: Dictionary = {}
var _curtain_left: ColorRect
var _curtain_right: ColorRect
var _loading_label: Label
var _level_flash: Label
var _last_level := 1


func _ready() -> void:
    _build_ui()
    _request = HTTPRequest.new()
    _request.timeout = 2.0
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)
    _play_boot_curtain()
    _refresh_all()


func _build_ui() -> void:
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_root)

    var bg := ColorRect.new()
    bg.color = INK
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.add_child(bg)

    var glow := ColorRect.new()
    glow.color = Color(0.05, 0.08, 0.16, 1.0)
    glow.position = Vector2(18, 18)
    glow.size = Vector2(1244, 684)
    _root.add_child(glow)

    var outer := VBoxContainer.new()
    outer.position = Vector2(36, 30)
    outer.size = Vector2(1208, 660)
    outer.add_theme_constant_override("separation", 12)
    _root.add_child(outer)

    outer.add_child(_build_header())

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    outer.add_child(body)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(310, 0)
    left.add_theme_constant_override("separation", 10)
    body.add_child(left)
    left.add_child(_build_status_panel())
    left.add_child(_build_service_panel())
    left.add_child(_build_job_panel())

    var center := VBoxContainer.new()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.add_theme_constant_override("separation", 10)
    body.add_child(center)
    center.add_child(_build_quest_panel())
    center.add_child(_build_action_panel())

    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(265, 0)
    right.add_theme_constant_override("separation", 10)
    body.add_child(right)
    right.add_child(_build_roleplay_panel())
    right.add_child(_build_security_panel())

    outer.add_child(_build_footer())
    _build_curtain()


func _panel(title: String) -> VBoxContainer:
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    var sb := StyleBoxFlat.new()
    sb.bg_color = PANEL_BLUE
    sb.border_color = GOLD.darkened(0.25)
    sb.set_border_width_all(2)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 12
    sb.content_margin_bottom = 12
    box.add_theme_stylebox_override("panel", sb)

    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", sb)
    panel.add_child(box)

    var heading := Label.new()
    heading.text = title
    heading.add_theme_color_override("font_color", GOLD)
    heading.add_theme_font_size_override("font_size", 18)
    box.add_child(heading)
    return box


func _build_header() -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size.y = 72
    var sb := StyleBoxFlat.new()
    sb.bg_color = DEEP_BLUE
    sb.border_color = GOLD
    sb.set_border_width_all(2)
    sb.corner_radius_top_left = 12
    sb.corner_radius_top_right = 12
    sb.corner_radius_bottom_left = 12
    sb.corner_radius_bottom_right = 12
    panel.add_theme_stylebox_override("panel", sb)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    panel.add_child(row)

    var title := Label.new()
    title.text = "  KAI 9000 // CATHEDRAL COCKPIT"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", WHITE)
    title.add_theme_font_size_override("font_size", 28)
    row.add_child(title)

    var badge := Label.new()
    badge.text = "  JRPG DEV MODE  "
    badge.add_theme_color_override("font_color", GOLD)
    badge.add_theme_font_size_override("font_size", 16)
    row.add_child(badge)
    return panel


func _build_status_panel() -> Control:
    var panel := PanelContainer.new()
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    _apply_panel_style(panel)

    var heading := _heading("PARTY STATUS")
    box.add_child(heading)

    _level_label = Label.new()
    _level_label.text = "LV 1  Cathedral Initiate"
    _level_label.add_theme_font_size_override("font_size", 20)
    _level_label.add_theme_color_override("font_color", WHITE)
    box.add_child(_level_label)

    _class_label = Label.new()
    _class_label.text = "JOB  Rune Coder"
    _class_label.add_theme_color_override("font_color", MUTED)
    box.add_child(_class_label)

    _xp_bar = ProgressBar.new()
    _xp_bar.min_value = 0
    _xp_bar.max_value = 100
    _xp_bar.value = 0
    _xp_bar.show_percentage = false
    box.add_child(_xp_bar)

    _xp_label = Label.new()
    _xp_label.text = "XP 0 / 100"
    _xp_label.add_theme_color_override("font_color", MUTED)
    box.add_child(_xp_label)
    return panel


func _build_service_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    box.add_child(_heading("LOCAL DAEMONS"))

    _service_grid = GridContainer.new()
    _service_grid.columns = 2
    box.add_child(_service_grid)
    for name in ["vnc", "websocket", "acodex", "pet"]:
        var key := Label.new()
        key.text = name.to_upper()
        key.add_theme_color_override("font_color", MUTED)
        _service_grid.add_child(key)
        var value := Label.new()
        value.text = "CHECKING"
        value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        _service_labels[name] = value
        _service_grid.add_child(value)
    return panel


func _build_job_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    box.add_child(_heading("JOB CRYSTAL"))
    for job in ["Rune Coder", "Daemon Knight", "Patch Mage", "Build Ninja"]:
        var b := Button.new()
        b.text = job
        b.pressed.connect(func(): _set_job(job))
        box.add_child(b)
    return panel


func _build_quest_panel() -> Control:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    box.add_child(_heading("QUEST LOG // ACODE SANCTUM"))

    _quest_log = RichTextLabel.new()
    _quest_log.bbcode_enabled = true
    _quest_log.fit_content = false
    _quest_log.scroll_active = true
    _quest_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _quest_log.custom_minimum_size.y = 320
    _quest_log.add_theme_color_override("default_color", WHITE)
    _quest_log.text = "[color=#c5a469]BOOTING CATHEDRAL...[/color]\n"
    box.add_child(_quest_log)
    return panel


func _build_action_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    box.add_child(_heading("CODING ENCOUNTERS"))

    var grid := GridContainer.new()
    grid.columns = 3
    box.add_child(grid)
    for action in ["compile", "debug", "refactor", "ship", "study"]:
        var b := Button.new()
        b.text = action.to_upper()
        b.custom_minimum_size = Vector2(140, 48)
        b.pressed.connect(func(): _run_action(action))
        grid.add_child(b)

    var refresh := Button.new()
    refresh.text = "REFRESH PARTY"
    refresh.pressed.connect(_refresh_all)
    grid.add_child(refresh)
    return panel


func _build_roleplay_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    box.add_child(_heading("ROLE PLAY RULES"))
    for line in [
        "d20 decides encounter flavor",
        "XP is earned, never lost",
        "Natural 20 = doubled base XP",
        "Level 99 hard cap",
        "No shell commands from GUI",
        "No external network actions",
    ]:
        var l := Label.new()
        l.text = "• " + line
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.add_theme_color_override("font_color", MUTED)
        box.add_child(l)
    return panel


func _build_security_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    box.add_child(_heading("KNOX BOUNDARY"))
    var l := Label.new()
    l.text = "Ordinary Termux owns daemons.\nSecure Folder is cockpit/client only.\nLoopback probes only.\nNo PID control across boundary."
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_color_override("font_color", MUTED)
    box.add_child(l)
    return panel


func _build_footer() -> Control:
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 34
    var l := Label.new()
    l.text = "WHITE ALIGNMENT • BLUE MAGIC • LOCALHOST FIRST • GODOT 4 MOBILE"
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.add_theme_color_override("font_color", MUTED)
    row.add_child(l)
    var seal := Label.new()
    seal.text = "WITCHING HOUR BUILD"
    seal.add_theme_color_override("font_color", GOLD)
    row.add_child(seal)
    return row


func _build_curtain() -> void:
    _curtain_left = ColorRect.new()
    _curtain_left.color = Color("0b1020")
    _curtain_left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
    _curtain_left.size = Vector2(640, 720)
    _curtain_left.z_index = 100
    _root.add_child(_curtain_left)

    _curtain_right = ColorRect.new()
    _curtain_right.color = Color("0b1020")
    _curtain_right.position = Vector2(640, 0)
    _curtain_right.size = Vector2(640, 720)
    _curtain_right.z_index = 100
    _root.add_child(_curtain_right)

    _loading_label = Label.new()
    _loading_label.text = "KAI 9000\nENTERING THE SACRISTY"
    _loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _loading_label.position = Vector2(390, 270)
    _loading_label.size = Vector2(500, 180)
    _loading_label.z_index = 101
    _loading_label.add_theme_font_size_override("font_size", 30)
    _loading_label.add_theme_color_override("font_color", GOLD)
    _root.add_child(_loading_label)

    _level_flash = Label.new()
    _level_flash.text = "LEVEL UP"
    _level_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _level_flash.position = Vector2(390, 130)
    _level_flash.size = Vector2(500, 100)
    _level_flash.z_index = 102
    _level_flash.modulate.a = 0.0
    _level_flash.add_theme_font_size_override("font_size", 42)
    _level_flash.add_theme_color_override("font_color", GOLD)
    _root.add_child(_level_flash)


func _play_boot_curtain() -> void:
    await get_tree().process_frame
    var tw := create_tween().set_parallel(true)
    tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    tw.tween_property(_curtain_left, "position:x", -640.0, 0.9)
    tw.tween_property(_curtain_right, "position:x", 1280.0, 0.9)
    tw.tween_property(_loading_label, "modulate:a", 0.0, 0.6)


func _loading_curtain(text: String) -> void:
    _loading_label.text = text
    _loading_label.modulate.a = 1.0
    var close := create_tween().set_parallel(true)
    close.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    close.tween_property(_curtain_left, "position:x", 0.0, 0.22)
    close.tween_property(_curtain_right, "position:x", 640.0, 0.22)


func _open_curtain() -> void:
    var tw := create_tween().set_parallel(true)
    tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tw.tween_property(_curtain_left, "position:x", -640.0, 0.3)
    tw.tween_property(_curtain_right, "position:x", 1280.0, 0.3)
    tw.tween_property(_loading_label, "modulate:a", 0.0, 0.2)


func _flash_level(level: int, title: String) -> void:
    _level_flash.text = "LEVEL UP  %d\n%s" % [level, title]
    var tw := create_tween()
    tw.tween_property(_level_flash, "modulate:a", 1.0, 0.18)
    tw.tween_interval(1.1)
    tw.tween_property(_level_flash, "modulate:a", 0.0, 0.35)


func _refresh_all() -> void:
    _get("rpg", "/api/rpg/state")


func _refresh_system() -> void:
    _get("system", "/api/system/status")


func _run_action(action: String) -> void:
    _loading_curtain("ROLLING d20\n" + action.to_upper())
    _post("action", "/api/rpg/action", {"action": action})


func _set_job(job: String) -> void:
    _loading_curtain("JOB CHANGE\n" + job.to_upper())
    _post("class", "/api/rpg/class", {"role_class": job})


func _get(kind: String, path: String) -> void:
    if _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return
    _pending_kind = kind
    _pending_payload = {}
    var err := _request.request(BASE_URL + path)
    if err != OK:
        _log("Request failed to start: %s" % err, true)


func _post(kind: String, path: String, payload: Dictionary) -> void:
    if _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        return
    _pending_kind = kind
    _pending_payload = payload
    var headers := PackedStringArray(["Content-Type: application/json"])
    var err := _request.request(BASE_URL + path, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        _log("Request failed to start: %s" % err, true)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var kind := _pending_kind
    _pending_kind = ""
    var data = JSON.parse_string(body.get_string_from_utf8())
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or typeof(data) != TYPE_DICTIONARY:
        _open_curtain()
        _log("LINK FAILURE HTTP %s" % response_code, true)
        return

    match kind:
        "rpg", "action", "class":
            _render_rpg(data)
            _open_curtain()
            _refresh_system()
        "system":
            _render_system(data)


func _render_rpg(data: Dictionary) -> void:
    var level := int(data.get("level", 1))
    var title := String(data.get("title", "Cathedral Initiate"))
    var role := String(data.get("role_class", "Rune Coder"))
    var xp := int(data.get("xp", 0))
    var xp_next := max(1, int(data.get("xp_next", 100)))
    _level_label.text = "LV %d  %s" % [level, title]
    _class_label.text = "JOB  " + role
    _xp_bar.max_value = xp_next
    _xp_bar.value = xp
    _xp_label.text = "XP %d / %d" % [xp, xp_next]
    var result := String(data.get("last_result", "Awaiting command."))
    _log(result, result.contains("NATURAL 20"))
    if level > _last_level:
        _flash_level(level, title)
    _last_level = level


func _render_system(data: Dictionary) -> void:
    var services: Dictionary = data.get("services", {})
    for name in _service_labels.keys():
        var item: Dictionary = services.get(name, {})
        var up := bool(item.get("up", false))
        var port := int(item.get("port", 0))
        var label: Label = _service_labels[name]
        label.text = "%s :%d" % ["GREEN" if up else "OFF", port]
        label.add_theme_color_override("font_color", GREEN if up else RED)


func _log(text: String, highlight := false) -> void:
    if _quest_log == null:
        return
    var color := "#c5a469" if highlight else "#f4f1e8"
    _quest_log.append_text("[color=%s]> %s[/color]\n" % [color, text])
    _quest_log.scroll_to_line(_quest_log.get_line_count())


func _heading(text: String) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_color_override("font_color", GOLD)
    l.add_theme_font_size_override("font_size", 17)
    return l


func _apply_panel_style(panel: PanelContainer) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = PANEL_BLUE
    sb.border_color = GOLD.darkened(0.25)
    sb.set_border_width_all(2)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 12
    sb.content_margin_bottom = 12
    panel.add_theme_stylebox_override("panel", sb)
