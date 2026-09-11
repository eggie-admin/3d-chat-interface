extends Node

const CHATGPT_URL := "https://chatgpt.com/"
const LUHM_MILESTONE := "LUHMOS_ULTIMA_TESTING_GREEN_20260910"
const LUHM_PACKAGE := "art.eggiebagelface.luhmos"
const COMPANION_PACKAGE := "art.eggiebagelface.kai9000"
const SAVE_PATH := "user://kai9000_chatgpt_companion.cfg"

const GOLD := Color("c5a469")
const DEEP_BLUE := Color("11182b")
const PANEL_BLUE := Color("18223b")
const INK := Color("080a10")
const WHITE := Color("f4f1e8")
const MUTED := Color("9ba8bf")
const GREEN := Color("62d890")
const RED := Color("e06b75")

var _root: Control
var _level_label: Label
var _job_label: Label
var _xp_label: Label
var _xp_bar: ProgressBar
var _quest_log: RichTextLabel
var _terminal: RichTextLabel
var _command_input: LineEdit
var _task_input: LineEdit
var _slot_labels: Dictionary = {}
var _level := 1
var _xp := 0
var _job := "Rune Coder"
var _quest := ""


func _ready() -> void:
    _build_ui()
    _render_state()
    _term("Samsung no-root cockpit online.", GREEN)
    _term("ChatGPT is the front door. No Termux, Shizuku, root, ADB, or localhost daemon required.", MUTED)


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
    left.custom_minimum_size = Vector2(260, 0)
    left.add_theme_constant_override("separation", 8)
    body.add_child(left)
    left.add_child(_build_status_panel())
    left.add_child(_build_doctrine_panel())
    left.add_child(_build_job_panel())

    var center := VBoxContainer.new()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.add_theme_constant_override("separation", 8)
    body.add_child(center)
    center.add_child(_build_chatgpt_panel())
    center.add_child(_build_quest_panel())

    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(370, 0)
    right.add_theme_constant_override("separation", 8)
    body.add_child(right)
    right.add_child(_build_command_panel())
    right.add_child(_build_save_panel())

    outer.add_child(_build_footer())


func _build_header() -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size.y = 62
    _apply_panel_style(panel, DEEP_BLUE, GOLD)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    panel.add_child(row)

    var title := Label.new()
    title.text = "  KAI 9000 // CHATGPT SAMSUNG NO-ROOT"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", WHITE)
    title.add_theme_font_size_override("font_size", 24)
    row.add_child(title)

    var badge := Label.new()
    badge.text = "  ANDROID 16  "
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
    _level_label.add_theme_font_size_override("font_size", 18)
    _level_label.add_theme_color_override("font_color", WHITE)
    box.add_child(_level_label)

    _job_label = Label.new()
    _job_label.add_theme_color_override("font_color", MUTED)
    box.add_child(_job_label)

    _xp_bar = ProgressBar.new()
    _xp_bar.min_value = 0
    _xp_bar.max_value = 100
    _xp_bar.show_percentage = false
    box.add_child(_xp_bar)

    _xp_label = Label.new()
    _xp_label.add_theme_color_override("font_color", MUTED)
    box.add_child(_xp_label)
    return panel


func _build_doctrine_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    panel.add_child(box)
    box.add_child(_heading("NO-ROOT DOCTRINE"))
    for text in [
        "ROOT      OFF",
        "SHIZUKU   OFF",
        "TERMUX    OFF",
        "ADB       OFF",
        "DAEMONS   OFF",
        "CHATGPT   USER LAUNCH"
    ]:
        var label := Label.new()
        label.text = text
        label.add_theme_color_override("font_color", GREEN if "OFF" in text or "CHATGPT" in text else MUTED)
        box.add_child(label)
    return panel


func _build_job_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)
    box.add_child(_heading("JOB CRYSTAL"))
    for job in ["Rune Coder", "Patch Mage", "Build Ninja", "Lore Keeper"]:
        var button := Button.new()
        button.text = job
        button.pressed.connect(_set_job.bind(job))
        box.add_child(button)
    return panel


func _build_chatgpt_panel() -> Control:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel, Color("101729"), GOLD.darkened(0.3))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    box.add_child(_heading("CHATGPT // FRONT DOOR"))

    var status := RichTextLabel.new()
    status.bbcode_enabled = true
    status.custom_minimum_size.y = 190
    status.fit_content = true
    status.text = (
        "[color=#f4f1e8]Official ChatGPT Android app / Android link resolver[/color]\n\n" +
        "This companion does not patch, inject into, impersonate, or control ChatGPT.\n" +
        "It stays inside ordinary Android app permissions and hands control to the user.\n\n" +
        "[color=#c5a469]Upstream LuHm proof[/color]\n" +
        LUHM_MILESTONE + "\n" + LUHM_PACKAGE + "\nSDK 36 • ARM64 • 16 KB gate GREEN"
    )
    box.add_child(status)

    var open_button := Button.new()
    open_button.text = "OPEN CHATGPT"
    open_button.custom_minimum_size.y = 54
    open_button.pressed.connect(_open_chatgpt)
    box.add_child(open_button)

    var actions := GridContainer.new()
    actions.columns = 5
    box.add_child(actions)
    for action in ["compile", "debug", "refactor", "ship", "study"]:
        var button := Button.new()
        button.text = action.to_upper()
        button.custom_minimum_size = Vector2(92, 42)
        button.pressed.connect(_run_action.bind(action))
        actions.add_child(button)
    return panel


func _build_quest_panel() -> Control:
    var panel := PanelContainer.new()
    _apply_panel_style(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    box.add_child(_heading("QUEST OBJECTIVE"))

    var row := HBoxContainer.new()
    box.add_child(row)
    _task_input = LineEdit.new()
    _task_input.placeholder_text = "Describe the next coding quest..."
    _task_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _task_input.text_submitted.connect(func(_text): _generate_quest())
    row.add_child(_task_input)

    var generate := Button.new()
    generate.text = "SET QUEST"
    generate.pressed.connect(_generate_quest)
    row.add_child(generate)

    _quest_log = RichTextLabel.new()
    _quest_log.bbcode_enabled = true
    _quest_log.custom_minimum_size.y = 110
    _quest_log.scroll_active = true
    box.add_child(_quest_log)
    return panel


func _build_command_panel() -> Control:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel, Color("0c111c"), Color("476b55"))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    box.add_child(_heading("SAFE COMMAND MENU"))

    _terminal = RichTextLabel.new()
    _terminal.bbcode_enabled = true
    _terminal.custom_minimum_size.y = 265
    _terminal.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _terminal.scroll_active = true
    _terminal.add_theme_color_override("default_color", Color("b8f4c6"))
    _terminal.text = "[color=#62d890]LOCAL COMPANION[/color]\nNo shell execution. No daemon control.\n/chatgpt /compile /debug /refactor /ship /study\n/quest <task> /save <1-3> /load <1-3>\n/job <rune|patch|ninja|lore> /milestone\n"
    box.add_child(_terminal)

    _command_input = LineEdit.new()
    _command_input.placeholder_text = "command>"
    _command_input.text_submitted.connect(_on_command_submitted)
    box.add_child(_command_input)

    var send := Button.new()
    send.text = "RUN LOCAL MENU COMMAND"
    send.pressed.connect(func(): _on_command_submitted(_command_input.text))
    box.add_child(send)
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
        label.text = "SLOT %d  LOCAL" % slot
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.add_theme_color_override("font_color", MUTED)
        _slot_labels[slot] = label
        row.add_child(label)

        var save := Button.new()
        save.text = "SAVE"
        save.pressed.connect(_save_slot.bind(slot))
        row.add_child(save)

        var load_button := Button.new()
        load_button.text = "LOAD"
        load_button.pressed.connect(_load_slot.bind(slot))
        row.add_child(load_button)
    return panel


func _build_footer() -> Control:
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 30
    var text := Label.new()
    text.text = "SAMSUNG • GODOT 4 • SDK 36 • ARM64 • NO ROOT • NO TERMUX • USER-DRIVEN CHATGPT"
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text.add_theme_color_override("font_color", MUTED)
    row.add_child(text)
    var seal := Label.new()
    seal.text = "ULTIMA GREEN"
    seal.add_theme_color_override("font_color", GOLD)
    row.add_child(seal)
    return row


func _open_chatgpt() -> void:
    _term("Handing control to Android link resolver for ChatGPT...", GOLD)
    var err := OS.shell_open(CHATGPT_URL)
    if err != OK:
        _term("Unable to open ChatGPT link: %s" % error_string(err), RED)


func _run_action(action: String) -> void:
    _xp += 18
    while _xp >= 100:
        _xp -= 100
        _level += 1
        _term("LEVEL UP -> %d" % _level, GOLD)
    _term("Local action staged: %s" % action.to_upper(), GREEN)
    _render_state()


func _set_job(job: String) -> void:
    _job = job
    _term("Job crystal set: %s" % _job, GOLD)
    _render_state()


func _generate_quest() -> void:
    var task := _task_input.text.strip_edges()
    if task.is_empty():
        _term("Quest text required.", RED)
        return
    _quest = task
    _task_input.clear()
    _term("Quest accepted: %s" % _quest, GREEN)
    _render_state()


func _save_slot(slot: int) -> void:
    var cfg := ConfigFile.new()
    cfg.load(SAVE_PATH)
    var section := "slot_%d" % slot
    cfg.set_value(section, "level", _level)
    cfg.set_value(section, "xp", _xp)
    cfg.set_value(section, "job", _job)
    cfg.set_value(section, "quest", _quest)
    var err := cfg.save(SAVE_PATH)
    if err == OK:
        _slot_labels[slot].text = "SLOT %d  SAVED" % slot
        _term("Saved locally to slot %d." % slot, GREEN)
    else:
        _term("Save failed: %s" % error_string(err), RED)


func _load_slot(slot: int) -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load(SAVE_PATH)
    if err != OK:
        _term("No local save file yet.", RED)
        return
    var section := "slot_%d" % slot
    if not cfg.has_section(section):
        _term("Slot %d is empty." % slot, RED)
        return
    _level = int(cfg.get_value(section, "level", 1))
    _xp = int(cfg.get_value(section, "xp", 0))
    _job = str(cfg.get_value(section, "job", "Rune Coder"))
    _quest = str(cfg.get_value(section, "quest", ""))
    _slot_labels[slot].text = "SLOT %d  LOADED" % slot
    _term("Loaded local slot %d." % slot, GREEN)
    _render_state()


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
        "/chatgpt":
            _open_chatgpt()
        "/compile", "/debug", "/refactor", "/ship", "/study":
            _run_action(op.trim_prefix("/"))
        "/quest":
            _task_input.text = arg
            _generate_quest()
        "/save":
            if arg.is_valid_int() and int(arg) >= 1 and int(arg) <= 3:
                _save_slot(int(arg))
            else:
                _term("usage: /save <1-3>", MUTED)
        "/load":
            if arg.is_valid_int() and int(arg) >= 1 and int(arg) <= 3:
                _load_slot(int(arg))
            else:
                _term("usage: /load <1-3>", MUTED)
        "/job":
            var jobs := {"rune": "Rune Coder", "patch": "Patch Mage", "ninja": "Build Ninja", "lore": "Lore Keeper"}
            if jobs.has(arg.to_lower()):
                _set_job(jobs[arg.to_lower()])
            else:
                _term("jobs: rune patch ninja lore", MUTED)
        "/milestone":
            _term("%s // %s // SDK36 ARM64 16KB GREEN" % [LUHM_MILESTONE, LUHM_PACKAGE], GOLD)
        _:
            _term("DENIED: command is not in the local companion whitelist.", RED)


func _render_state() -> void:
    _level_label.text = "LV %d  Cathedral Companion" % _level
    _job_label.text = "JOB  %s" % _job
    _xp_bar.value = _xp
    _xp_label.text = "XP %d / 100" % _xp
    if _quest.is_empty():
        _quest_log.text = "[color=#c5a469]No active quest.[/color]"
    else:
        _quest_log.text = "[color=#62d890]ACTIVE[/color]\n" + _quest


func _term(text: String, color: Color = WHITE) -> void:
    if _terminal == null:
        return
    _terminal.append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), text])
    _terminal.scroll_to_line(max(0, _terminal.get_line_count() - 1))


func _heading(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 16)
    label.add_theme_color_override("font_color", GOLD)
    return label


func _apply_panel_style(panel: PanelContainer, bg: Color = PANEL_BLUE, border: Color = Color("344667")) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = 5
    style.corner_radius_top_right = 5
    style.corner_radius_bottom_left = 5
    style.corner_radius_bottom_right = 5
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", style)
