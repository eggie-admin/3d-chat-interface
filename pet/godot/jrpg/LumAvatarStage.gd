extends SubViewportContainer

const GLB_PATH := "res://assets/lum/lum.glb"
const SPRITE_PATH := "res://assets/lum/lumSpriteAtlas.clean.png"
const PUPPET_SCRIPT := preload("res://LumPuppet2D.gd")

var _viewport: SubViewport
var _world_root: Node3D
var _avatar: Node3D
var _puppet: Node2D
var _avatar_mode := "none"
var _time := 0.0
var _mood := "neutral"
var _base_y := 0.0


func _ready() -> void:
    stretch = true
    _viewport = SubViewport.new()
    _viewport.size = Vector2i(720, 400)
    _viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    _viewport.transparent_bg = false
    add_child(_viewport)

    if _try_load_puppet2d():
        return

    _world_root = Node3D.new()
    _viewport.add_child(_world_root)
    _build_world()
    _load_lum()


func _try_load_puppet2d() -> bool:
    var puppet = PUPPET_SCRIPT.new()
    if not puppet.configure():
        puppet.queue_free()
        return false

    var backdrop := ColorRect.new()
    backdrop.color = Color("080b14")
    backdrop.position = Vector2.ZERO
    backdrop.size = Vector2(720, 400)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _viewport.add_child(backdrop)

    _puppet = puppet
    _viewport.add_child(_puppet)
    _puppet.position = puppet.stage_origin()
    _puppet.scale = Vector2.ONE * puppet.stage_scale()
    _avatar_mode = "puppet2d"
    _puppet.set_mood(_mood)
    return true


func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("080b14")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("53658f")
    environment.ambient_light_energy = 0.7
    env.environment = environment
    _world_root.add_child(env)

    var key := DirectionalLight3D.new()
    key.light_color = Color("d9e6ff")
    key.light_energy = 2.0
    key.rotation_degrees = Vector3(-35, -25, 0)
    _world_root.add_child(key)

    var rim := OmniLight3D.new()
    rim.light_color = Color("7e5cff")
    rim.light_energy = 4.0
    rim.omni_range = 8.0
    rim.position = Vector3(-2.2, 2.6, 1.5)
    _world_root.add_child(rim)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 1.15, 5.4)
    camera.fov = 42.0
    camera.look_at(Vector3(0, 0.75, 0), Vector3.UP)
    camera.current = true
    _world_root.add_child(camera)

    var floor := MeshInstance3D.new()
    var floor_mesh := CylinderMesh.new()
    floor_mesh.top_radius = 1.75
    floor_mesh.bottom_radius = 1.9
    floor_mesh.height = 0.18
    floor.mesh = floor_mesh
    floor.position = Vector3(0, -1.15, 0)
    floor.material_override = _material(Color("18223b"), 0.75, 0.15)
    _world_root.add_child(floor)

    var ring := MeshInstance3D.new()
    var ring_mesh := TorusMesh.new()
    ring_mesh.inner_radius = 1.35
    ring_mesh.outer_radius = 1.5
    ring.mesh = ring_mesh
    ring.rotation_degrees.x = 90
    ring.position = Vector3(0, -1.04, 0)
    ring.material_override = _material(Color("c5a469"), 0.4, 0.3)
    _world_root.add_child(ring)


func _load_lum() -> void:
    if ResourceLoader.exists(GLB_PATH):
        var packed = load(GLB_PATH)
        if packed is PackedScene:
            _avatar = packed.instantiate()
            _world_root.add_child(_avatar)
            _avatar.scale = Vector3.ONE * 1.15
            _avatar.position = Vector3(0, -1.0, 0)
            _base_y = _avatar.position.y
            _avatar_mode = "glb3d"
            return
    _avatar = _build_procedural_lum()
    _world_root.add_child(_avatar)
    _base_y = _avatar.position.y
    _avatar_mode = "procedural3d"


func _build_procedural_lum() -> Node3D:
    var root := Node3D.new()
    root.name = "LumProceduralAvatar"
    root.position = Vector3(0, -0.95, 0)

    var skin := Color("b62e38")
    var skin_dark := Color("7f1e2a")
    var black := Color("16131d")
    var eye := Color("dff8ff")
    var gold := Color("c5a469")

    var torso_mesh := CapsuleMesh.new()
    torso_mesh.radius = 0.48
    torso_mesh.height = 1.42
    root.add_child(_part(torso_mesh, skin, Vector3(0, 0.62, 0), Vector3(1.05, 1.0, 0.82)))

    var hip_mesh := SphereMesh.new()
    hip_mesh.radius = 0.62
    hip_mesh.height = 1.24
    root.add_child(_part(hip_mesh, skin, Vector3(0, -0.05, 0), Vector3(1.05, 0.82, 0.82)))

    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.58
    head_mesh.height = 1.16
    root.add_child(_part(head_mesh, skin, Vector3(0, 1.72, 0), Vector3(0.95, 1.0, 0.92)))

    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.61
    hair_mesh.height = 1.22
    var hair := _part(hair_mesh, black, Vector3(0, 1.92, 0.08), Vector3(1.02, 0.62, 0.96))
    root.add_child(hair)

    var chest_mesh := SphereMesh.new()
    chest_mesh.radius = 0.32
    chest_mesh.height = 0.64
    root.add_child(_part(chest_mesh, skin, Vector3(-0.25, 0.82, 0.39), Vector3(1.05, 0.95, 0.9)))
    root.add_child(_part(chest_mesh, skin, Vector3(0.25, 0.82, 0.39), Vector3(1.05, 0.95, 0.9)))

    var arm_mesh := CapsuleMesh.new()
    arm_mesh.radius = 0.13
    arm_mesh.height = 0.95
    var left_arm := _part(arm_mesh, skin, Vector3(-0.6, 0.58, 0), Vector3.ONE, Vector3(0, 0, -0.15))
    var right_arm := _part(arm_mesh, skin, Vector3(0.6, 0.58, 0), Vector3.ONE, Vector3(0, 0, 0.15))
    root.add_child(left_arm)
    root.add_child(right_arm)

    var leg_mesh := CapsuleMesh.new()
    leg_mesh.radius = 0.18
    leg_mesh.height = 1.0
    root.add_child(_part(leg_mesh, skin_dark, Vector3(-0.25, -0.72, 0), Vector3.ONE))
    root.add_child(_part(leg_mesh, skin_dark, Vector3(0.25, -0.72, 0), Vector3.ONE))

    var boot_mesh := BoxMesh.new()
    boot_mesh.size = Vector3(0.38, 0.22, 0.62)
    root.add_child(_part(boot_mesh, black, Vector3(-0.25, -1.2, 0.12), Vector3.ONE))
    root.add_child(_part(boot_mesh, black, Vector3(0.25, -1.2, 0.12), Vector3.ONE))

    var eye_mesh := SphereMesh.new()
    eye_mesh.radius = 0.08
    eye_mesh.height = 0.16
    root.add_child(_part(eye_mesh, eye, Vector3(-0.2, 1.75, 0.52), Vector3(1.2, 0.55, 0.45)))
    root.add_child(_part(eye_mesh, eye, Vector3(0.2, 1.75, 0.52), Vector3(1.2, 0.55, 0.45)))

    var pupil_mesh := SphereMesh.new()
    pupil_mesh.radius = 0.035
    pupil_mesh.height = 0.07
    root.add_child(_part(pupil_mesh, black, Vector3(-0.2, 1.75, 0.59), Vector3.ONE))
    root.add_child(_part(pupil_mesh, black, Vector3(0.2, 1.75, 0.59), Vector3.ONE))

    var horn_mesh := CylinderMesh.new()
    horn_mesh.top_radius = 0.0
    horn_mesh.bottom_radius = 0.12
    horn_mesh.height = 0.7
    root.add_child(_part(horn_mesh, black, Vector3(-0.28, 2.35, 0), Vector3.ONE, Vector3(0.15, 0, -0.28)))
    root.add_child(_part(horn_mesh, black, Vector3(0.28, 2.35, 0), Vector3.ONE, Vector3(0.15, 0, 0.28)))

    var wing_mesh := QuadMesh.new()
    wing_mesh.size = Vector2(0.78, 0.56)
    var wing_mat := _material(Color(0.12, 0.06, 0.16, 0.92), 0.7, 0.05)
    wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    wing_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var left_wing := MeshInstance3D.new()
    left_wing.mesh = wing_mesh
    left_wing.material_override = wing_mat
    left_wing.position = Vector3(-0.68, -0.02, -0.12)
    left_wing.rotation_degrees = Vector3(8, 28, -28)
    root.add_child(left_wing)
    var right_wing := MeshInstance3D.new()
    right_wing.mesh = wing_mesh
    right_wing.material_override = wing_mat
    right_wing.position = Vector3(0.68, -0.02, -0.12)
    right_wing.rotation_degrees = Vector3(8, -28, 28)
    root.add_child(right_wing)

    var tail_mesh := CapsuleMesh.new()
    tail_mesh.radius = 0.055
    tail_mesh.height = 0.85
    root.add_child(_part(tail_mesh, skin_dark, Vector3(0.36, -0.24, -0.46), Vector3.ONE, Vector3(0.75, 0, 0.42)))
    var tail_tip := SphereMesh.new()
    tail_tip.radius = 0.11
    tail_tip.height = 0.18
    root.add_child(_part(tail_tip, skin_dark, Vector3(0.68, -0.6, -0.58), Vector3(1.15, 0.65, 0.45)))

    var collar_mesh := TorusMesh.new()
    collar_mesh.inner_radius = 0.27
    collar_mesh.outer_radius = 0.33
    var collar := _part(collar_mesh, gold, Vector3(0, 1.23, 0), Vector3.ONE)
    collar.rotation_degrees.x = 90
    root.add_child(collar)

    return root


func _part(mesh: PrimitiveMesh, color: Color, pos: Vector3, scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.scale = scl
    node.rotation = rot
    node.material_override = _material(color, 0.72, 0.08)
    return node


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = metallic
    return mat


func avatar_mode() -> String:
    return _avatar_mode


func set_mood(mood: String) -> void:
    _mood = mood
    if _avatar_mode == "puppet2d" and _puppet != null:
        _puppet.set_mood(mood)


func play_state(state: String) -> void:
    if _avatar_mode == "puppet2d" and _puppet != null:
        _puppet.play_state(state)


func celebrate(critical := false) -> void:
    if _avatar_mode == "puppet2d" and _puppet != null:
        _puppet.play_state("victory")
        var tw2d := create_tween()
        tw2d.tween_property(_puppet, "scale", Vector2.ONE * _puppet.stage_scale() * (1.08 if critical else 1.04), 0.15)
        tw2d.tween_property(_puppet, "scale", Vector2.ONE * _puppet.stage_scale(), 0.25)
        tw2d.tween_interval(0.55)
        tw2d.tween_callback(Callable(self, "_return_puppet_to_mood"))
        return

    if _avatar == null:
        return
    var tw := create_tween()
    tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(_avatar, "scale", Vector3.ONE * (1.18 if critical else 1.1), 0.16)
    tw.tween_property(_avatar, "scale", Vector3.ONE, 0.28)


func _return_puppet_to_mood() -> void:
    if _puppet != null:
        _puppet.set_mood(_mood)


func _process(delta: float) -> void:
    if _avatar_mode == "puppet2d":
        return
    if _avatar == null:
        return
    _time += delta
    var speed := 1.7 if _mood in ["happy", "cute"] else 1.0
    _avatar.position.y = _base_y + sin(_time * 2.0 * speed) * 0.035
    _avatar.rotation.y = sin(_time * 0.65) * 0.13
    if _mood == "angry":
        _avatar.rotation.z = sin(_time * 8.0) * 0.015
    else:
        _avatar.rotation.z = 0.0
