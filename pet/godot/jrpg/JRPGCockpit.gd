extends Node

const BASE_URL := "http://127.0.0.1:8772"
const ACODEX_URL := "http://127.0.0.1:8767"
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
var _level_label: Label
var _class_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _quest_log: RichTextLabel
var _terminal: RichTextLabel
var _command_input: LineEdit
var _task_input: LineEdit
var _acodex_label: Label
var _service_labels: Dictionary = {}
var _slot_labels: Dictionary = {}
var _curtain_left: ColorRect
var _curtain_right: ColorRect
var _loading_label: Label
var _level_flash: Label
var _avatar_stage: Control
var _fanfare: Node
var _last_level := 1


func _ready() -> void:
    _build_ui()
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

    var outer := VBoxContainer.new()
    outer.position = Vector2(24, 18)
    outer.size = Vector2(1232, 684)
    outer.add_theme_constant_override("separation", 10)
    _root.add_child(outer)

    outer.add_child(_build_header())

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 10)
    outer.add_child(body)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(250, 0)
    left.add_theme_constant_override("separation", 8)
    body.add_child(left)
    left.add_child(_build_status_panel())
    left.add_child(_build_service_panel())
    left.add_child(_build_job_panel())

    var center := VBoxContainer.new()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.add_theme_constant_override("separation", 8)
    body.add_child(center)
    center.add_child(_build_avatar_panel())
    center.add_child(_build_quest_panel())

    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(360, 0)
    right.add_theme_constant_override("separation", 8)
    body.add_child(right)
    right.add_child(_build_acodex_panel())
    right.add_child(_build_save_panel())

    outer.add_child(_build_footer())
    _build_curtain()

    var fanfare_script = load("res://OriginalFanfare.gd")
    _fanfare = fanfare_script.new()
    add_child(_fanfare)


func _build_header() -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size.y = 62
    _apply_panel_style(panel, DEEP_BLUE, GOLD)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    panel.add_child(row)

    var title := Label.new()
    title.text = "  KAI 9000 // SAMSUNG CATHEDRAL COCKPIT"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", WHITE)
    title.add_theme_font_size_override("font_size", 25)
    row.add_child(title)

    var badge := Label.new()
    badge.text = "  JRPG DEV MODE  "
    badge.add_theme_color_override("font_color", GOLD)
    badge.add_theme_font_size_override("font_size", 15)
    row.add_child(badge)
    return panel


func _build_status_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 7)
    panel.add_child(box)
    box.add_child(_heading("PARTY STATUS"))

    _level_label = Label.new()
    _level_label.text = "LV 1  Cathedral Initiate"
    _level_label.add_theme_font_size_override("font_size", 18)
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
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    box.add_child(_heading("LOCAL DAEMONS"))

    var grid := GridContainer.new()
    grid.columns = 2
    box.add_child(grid)
    for name in ["vnc", "websocket", "acodex", "pet"]:
        var key := Label.new()
        key.text = name.to_upper()
        key.add_theme_color_override("font_color", MUTED)
        grid.add_child(key)
        var value := Label.new()
        value.text = "CHECKING"
        value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        _service_labels[name] = value
        grid.add_child(value)
    return panel


func _build_job_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)
    box.add_child(_heading("JOB CRYSTAL"))
    for job in ["Rune Coder", "Daemon Knight", "Patch Mage", "Build Ninja"]:
        var b := Button.new()
        b.text = job
        b.pressed.connect(_set_job.bind(job))
        box.add_child(b)
    return panel


func _build_avatar_panel() -> Control:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel, Color("101729"), GOLD.darkened(0.3))
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_child(_heading("LUM // CENTER BATTLE STAGE"))

    var stage_script = load("res://LumAvatarStage.gd")
    _avatar_stage = stage_script.new()
    _avatar_stage.custom_minimum_size = Vector2(0, 330)
    _avatar_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(_avatar_stage)

    var actions := GridContainer.new()
    actions.columns = 5
    box.add_child(actions)
    for action in ["compile", "debug", "refactor", "ship", "study"]:
        var b := Button.new()
        b.text = action.to_upper()
        b.custom_minimum_size = Vector2(92, 42)
        b.pressed.connect(_run_action.bind(action))
        actions.add_child(b)
    return panel


func _build_quest_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    box.add_child(_heading("QUEST OBJECTIVES"))

    var row := HBoxContainer.new()
    box.add_child(row)
    _task_input = LineEdit.new()
    _task_input.placeholder_text = "Describe coding task: fix Android export, debug server, mutate avatar..."
    _task_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _task_input.text_submitted.connect(func(_text): _generate_quest())
    row.add_child(_task_input)
    var generate := Button.new()
    generate.text = "GENERATE QUEST"
    generate.pressed.connect(_generate_quest)
    row.add_child(generate)

    _quest_log = RichTextLabel.new()
    _quest_log.bbcode_enabled = true
    _quest_log.custom_minimum_size.y = 145
    _quest_log.scroll_active = true
    _quest_log.add_theme_color_override("default_color", WHITE)
    _quest_log.text = "[color=#c5a469]No active coding quest.[/color]"
    box.add_child(_quest_log)
    return panel


func _build_acodex_panel() -> Control:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel, Color("0c111c"), Color("476b55"))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    box.add_child(_heading("ACODEX // COMMAND MENU"))

    _acodex_label = Label.new()
    _acodex_label.text = "127.0.0.1:8767  CHECKING"
    _acodex_label.add_theme_color_override("font_color", MUTED)
    box.add_child(_acodex_label)

    _terminal = RichTextLabel.new()
    _terminal.bbcode_enabled = true
    _terminal.custom_minimum_size.y = 250
    _terminal.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _terminal.scroll_active = true
    _terminal.add_theme_color_override("default_color", Color("b8f4c6"))
    _terminal.text = "[color=#62d890]KAI SAFE SHELL[/color]\nWhitelisted commands only. No arbitrary shell execution.\n/compile /debug /refactor /ship /study\n/quest <task>  /save <1-3>  /load <1-3>\n/job <class>  /acode  /refresh\n"
    box.add_child(_terminal)

    _command_input = LineEdit.new()
    _command_input.placeholder_text = "command>"
    _command_input.text_submitted.connect(_on_command_submitted)
    box.add_child(_command_input)

    var row := HBoxContainer.new()
    box.add_child(row)
    var send := Button.new()
    send.text = "EXECUTE MENU COMMAND"
    send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    send.pressed.connect(func(): _on_command_submitted(_command_input.text))
    row.add_child(send)
    var open_acode := Button.new()
    open_acode.text = "OPEN ACODEX"
    open_acode.pressed.connect(_open_acodex)
    row.add_child(open_acode)
    return panel


func _build_save_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)
    box.add_child(_heading("SAVE CRYSTALS"))

    for slot in [1, 2, 3]:
        var row := HBoxContainer.new()
        box.add_child(row)
        var label := Label.new()
        label.text = "SLOT %d  EMPTY" % slot
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.add_theme_color_override("font_color", MUTED)
        _slot_labels[slot] = label
        row.add_child(label)
        var save := Button.new()
        save.text = "SAVE"
        save.pressed.connect(_save_slot.bind(slot))
        row.add_child(save)
        var load_btn := Button.new()
        load_btn.text = "LOAD"
        load_btn.pressed.connect(_load_slot.bind(slot))
        row.add_child(load_btn)
    return panel


func _build_footer() -> Control:
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 30
    var l := Label.new()
    l.text = "S24 FE • GODOT 4 MOBILE • LOCALHOST FIRST • ORIGINAL AUDIO • NO CROSS-KNOX PID CONTROL"
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.add_theme_color_override("font_color", MUTED)
    row.add_child(l)
    var seal := Label.new()
    seal.text = "WITCHING HOUR"
    seal.add_theme_color_override("font_color", GOLD)
    row.add_child(seal)
    return row


func _build_curtain() -> void:
    _curtain_left = ColorRect.new()
    _curtain_left.color = Color("0b1020")
    _curtain_left.position = Vector2(0, 0)
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
    _loading_label.position = Vector2(350, 255)
    _loading_label.size = Vector2(580, 190)
    _loading_label.z_index = 101
    _loading_label.add_theme_font_size_override("font_size", 30)
    _loading_label.add_theme_color_override("font_color", GOLD)
    _root.add_child(_loading_label)

    _level_flash = Label.new()
    _level_flash.text = "LEVEL UP"
    _level_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _level_flash.position = Vector2(350, 100)
    _level_flash.size = Vector2(580, 100)
    _level_flash.z_index = 102
    _level_flash.modulate.a = 0.0
    _level_flash.add_theme_font_size_override("font_size", 42)
    _level_flash.add_theme_color_override("font_color", GOLD)
    _root.add_child(_level_flash)


func _play_boot_curtain() -> void:
    await get_tree().process_frame
    var tw := create_tween().set_parallel(true)
    tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
    tw.tween_property(_curtain_left, "position:x", -640.0, 0.85)
    tw.tween_property(_curtain_right, "position:x", 1280.0, 0.85)
    tw.tween_property(_loading_label, "modulate:a", 0.0, 0.55)


func _loading_curtain(text: String) -> void:
    _loading_label.text = text
    _loading_label.modulate.a = 1.0
    var close := create_tween().set_parallel(true)
    close.tween_property(_curtain_left, "position:x", 0.0, 0.18)
    close.tween_property(_curtain_right, "position:x", 640.0, 0.18)


func _open_curtain() -> void:
    var tw := create_tween().set_parallel(true)
    tw.tween_property(_curtain_left, "position:x", -640.0, 0.24)
    tw.tween_property(_curtain_right, "position:x", 1280.0, 0.24)
    tw.tween_property(_loading_label, "modulate:a", 0.0, 0.18)


func _flash_level(level: int, title: String) -> void:
    _level_flash.text = "LEVEL UP  %d\n%s" % [level, title]
    var tw := create_tween()
    tw.tween_property(_level_flash, "modulate:a", 1.0, 0.15)
    tw.tween_interval(0.95)
    tw.tween_property(_level_flash, "modulate:a", 0.0, 0.3)


func _refresh_all() -> void:
    _get("rpg", "/api/rpg/state")
    _get("quest", "/api/quests")
    _get("system", "/api/system/status")
    _get("saves", "/api/saves")
    _get("acodex", "/api/acodex/status")


func _run_action(action: String) -> void:
    _loading_curtain("ENCOUNTER\n" + action.to_upper())
    _post("action", "/api/rpg/action", {"action": action})


func _set_job(job: String) -> void:
    _post("class", "/api/rpg/class", {"role_class": job})


func _generate_quest() -> void:
    var task := _task_input.text.strip_edges()
    if task.is_empty():
        _term("DENIED: coding task required.", RED)
        return
    _post("quest_generate", "/api/quests/generate", {"task": task})


func _save_slot(slot: int) -> void:
    _post("save", "/api/saves/save", {"slot": slot})


func _load_slot(slot: int) -> void:
    _loading_curtain("LOAD CRYSTAL\nSLOT %d" % slot)
    _post("load", "/api/saves/load", {"slot": slot})


func _open_acodex() -> void:
    _term("Opening AcodeX localhost cockpit...", GOLD)
    OS.shell_open(ACODEX_URL)


func _on_command_submitted(raw: String) -> void:
    var command := raw.strip_edges()
    _command_input.clear()
    if command.is_empty():
        return
    _term("> " + command, WHITE)

    var parts := command.split(" ", false, 1)
    var op := parts[0].to_lower()
    var arg := parts[1].strip_edges() if parts.size() > 1 else ""

    match op:
        "/compile", "/debug", "/refactor", "/ship", "/study":
            _run_action(op.trim_prefix("/"))
        "/quest":
            if arg.is_empty():
                _term("usage: /quest <coding task>", MUTED)
            else:
                _task_input.text = arg
                _generate_quest()
        "/save":
            if arg.is_valid_int():
                _save_slot(int(arg))
            else:
                _term("usage: /save <1-3>", MUTED)
        "/load":
            if arg.is_valid_int():
                _load_slot(int(arg))
            else:
                _term("usage: /load <1-3>", MUTED)
        "/job":
            var jobs := {"rune": "Rune Coder", "daemon": "Daemon Knight", "patch": "Patch Mage", "ninja": "Build Ninja"}
            if jobs.has(arg.to_lower()):
                _set_job(jobs[arg.to_lower()])
            else:
                _term("jobs: rune daemon patch ninja", MUTED)
        "/acode":
            _open_acodex()
        "/refresh":
            _refresh_all()
        _:
            _term("DENIED: not in KAI command whitelist.", RED)


func _get(kind: String, path: String) -> void:
    _request_json(kind, path, HTTPClient.METHOD_GET, {})


func _post(kind: String, path: String, payload: Dictionary) -> void:
    _request_json(kind, path, HTTPClient.METHOD_POST, payload)


func _request_json(kind: String, path: String, method: int, payload: Dictionary) -> void:
    var req := HTTPRequest.new()
    req.timeout = 2.5
    add_child(req)
    req.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
        _on_request_completed(kind, req, result, code, body)
    )
    var headers := PackedStringArray(["Content-Type: application/json"])
    var body := JSON.stringify(payload) if method == HTTPClient.METHOD_POST else ""
    var err := req.request(BASE_URL + path, headers, method, body)
    if err != OK:
        _term("request failed to start: %s" % error_string(err), RED)
        req.queue_free()


func _on_request_completed(kind: String, req: HTTPRequest, result: int, code: int, body: PackedByteArray) -> void:
    req.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
        _term("%s failed: HTTP %d" % [kind, code], RED)
        _open_curtain()
        return
    var parsed = JSON.parse_string(body.get_string_from_utf8())
    if typeof(parsed) != TYPE_DICTIONARY:
        _term("%s returned invalid JSON" % kind, RED)
        _open_curtain()
        return
    var data: Dictionary = parsed

    match kind:
        "rpg":
            _apply_rpg(data)
        "quest":
            _apply_quest(data)
        "system":
            _apply_system(data)
        "saves":
            _apply_saves(data)
        "acodex":
            _apply_acodex(data)
        "class":
            _apply_rpg(data)
            _term("JOB CHANGE: " + String(data.get("role_class", "?")), GOLD)
        "quest_generate":
            _apply_quest(data)
            _term("QUEST FORGED: " + String(data.get("active_task", "")), GOLD)
        "save":
            _term("SAVE CRYSTAL SLOT %d SEALED" % int(data.get("slot", 0)), GREEN)
            _get("saves", "/api/saves")
        "load":
            _apply_rpg(Dictionary(data.get("rpg", {})))
            _apply_quest(Dictionary(data.get("quest", {})))
            _term("SAVE CRYSTAL RESTORED", GREEN)
            _get("saves", "/api/saves")
            _open_curtain()
        "action":
            var rpg := Dictionary(data.get("rpg", {}))
            var quest := Dictionary(data.get("quest", {}))
            _apply_action_result(rpg, quest)
            _open_curtain()


func _apply_rpg(state: Dictionary) -> void:
    var level := int(state.get("level", 1))
    var title := String(state.get("title", "Cathedral Initiate"))
    var role_class := String(state.get("role_class", "Rune Coder"))
    var xp := int(state.get("xp", 0))
    var xp_next := max(1, int(state.get("xp_next", 100)))
    _level_label.text = "LV %d  %s" % [level, title]
    _class_label.text = "JOB  " + role_class
    _xp_bar.max_value = xp_next
    _xp_bar.value = xp
    _xp_label.text = "XP %d / %d" % [xp, xp_next]

    if level > _last_level:
        _flash_level(level, title)
        if _fanfare != null:
            _fanfare.play_victory(true)
        if _avatar_stage != null and _avatar_stage.has_method("celebrate"):
            _avatar_stage.celebrate(true)
    _last_level = level


func _apply_action_result(rpg: Dictionary, quest: Dictionary) -> void:
    var result := String(rpg.get("last_result", "Encounter complete."))
    var critical := "NATURAL 20" in result
    _apply_rpg(rpg)
    _apply_quest(quest)
    _term(result, GOLD if critical else GREEN)
    if _fanfare != null:
        _fanfare.play_victory(critical)
    if _avatar_stage != null:
        if _avatar_stage.has_method("set_mood"):
            _avatar_stage.set_mood("happy" if critical else "smug")
        if _avatar_stage.has_method("celebrate"):
            _avatar_stage.celebrate(critical)


func _apply_quest(state: Dictionary) -> void:
    var task := String(state.get("active_task", ""))
    var objectives: Array = state.get("objectives", [])
    if task.is_empty():
        _quest_log.text = "[color=#c5a469]No active coding quest.[/color]"
        return
    var lines := "[color=#c5a469]" + task + "[/color]\n"
    var index := 1
    for raw in objectives:
        var item: Dictionary = raw
        var done := bool(item.get("done", false))
        var mark := "[color=#62d890][✓][/color]" if done else "[color=#9ba8bf][ ][/color]"
        lines += "%s %d. %s\n" % [mark, index, String(item.get("label", "objective"))]
        index += 1
    _quest_log.text = lines


func _apply_system(data: Dictionary) -> void:
    var services: Dictionary = data.get("services", {})
    for name in _service_labels.keys():
        var info: Dictionary = services.get(name, {})
        var up := bool(info.get("up", false))
        var label: Label = _service_labels[name]
        label.text = "GREEN" if up else "OFF"
        label.add_theme_color_override("font_color", GREEN if up else RED)


func _apply_acodex(data: Dictionary) -> void:
    var up := bool(data.get("up", false))
    _acodex_label.text = "127.0.0.1:8767  " + ("GREEN" if up else "OFF")
    _acodex_label.add_theme_color_override("font_color", GREEN if up else RED)


func _apply_saves(data: Dictionary) -> void:
    var slots: Array = data.get("slots", [])
    for raw in slots:
        var item: Dictionary = raw
        var slot := int(item.get("slot", 0))
        if not _slot_labels.has(slot):
            continue
        var label: Label = _slot_labels[slot]
        if not bool(item.get("occupied", false)):
            label.text = "SLOT %d  EMPTY" % slot
        elif bool(item.get("invalid", false)):
            label.text = "SLOT %d  INVALID" % slot
        else:
            label.text = "SLOT %d  LV%d %s" % [slot, int(item.get("level", 1)), String(item.get("role_class", "Rune Coder"))]


func _term(text: String, color := WHITE) -> void:
    if _terminal == null:
        return
    _terminal.append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), text])
    _terminal.scroll_to_line(max(0, _terminal.get_line_count() - 1))


func _heading(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_color_override("font_color", GOLD)
    label.add_theme_font_size_override("font_size", 16)
    return label


func _apply_panel_style(panel: PanelContainer, bg := PANEL_BLUE, border := GOLD.darkened(0.35)) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(2)
    sb.corner_radius_top_left = 9
    sb.corner_radius_top_right = 9
    sb.corner_radius_bottom_left = 9
    sb.corner_radius_bottom_right = 9
    sb.content_margin_left = 10
    sb.content_margin_right = 10
    sb.content_margin_top = 8
    sb.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", sb)
