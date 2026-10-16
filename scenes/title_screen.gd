extends Node3D

const SCHOOL_MODEL: PackedScene = preload("res://assets.blend")
const MONSTER_SCENE: PackedScene = preload("res://scenes/monster_placeholder.tscn")
const TITLE_AMBIENCE: AudioStream = preload("res://sound/after_school_title_ambience.wav")
const GAME_SCENE := "res://scenes/demo_scene.tscn"
const ORBIT_SPEED := 0.12
const ORBIT_RADIUS := 5.5
const ORBIT_HEIGHT := 2.25

var _camera: Camera3D
var _monster: CharacterBody3D
var _orbit_center := Vector3.ZERO
var _orbit_angle := 0.0

func _ready() -> void:
	_build_lobby()
	_build_monster()
	_build_camera()
	_build_menu()
	_play_title_ambience()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _play_title_ambience() -> void:
	var music := AudioStreamPlayer.new()
	music.name = "TitleAmbience"
	music.stream = TITLE_AMBIENCE
	music.volume_db = -8.0
	add_child(music)
	music.finished.connect(music.play)
	music.play()

func _process(delta: float) -> void:
	_orbit_angle = wrapf(_orbit_angle + ORBIT_SPEED * delta, 0.0, TAU)
	if is_instance_valid(_camera):
		_camera.global_position = _orbit_center + Vector3(cos(_orbit_angle) * ORBIT_RADIUS, ORBIT_HEIGHT, sin(_orbit_angle) * ORBIT_RADIUS)
		_camera.look_at(_orbit_center + Vector3.UP * 1.35, Vector3.UP)

func _build_lobby() -> void:
	var school := SCHOOL_MODEL.instantiate()
	school.name = "SchoolLobby"
	add_child(school)
	var lobby_floor := _find_node_named(school, "Lobby Floor") as MeshInstance3D
	if lobby_floor != null and lobby_floor.mesh != null:
		var bounds: AABB = lobby_floor.global_transform * lobby_floor.mesh.get_aabb()
		_orbit_center = Vector3(bounds.position.x + bounds.size.x * 0.5, bounds.position.y + bounds.size.y, bounds.position.z + bounds.size.z * 0.5)
	else:
		_orbit_center = Vector3.ZERO
	_hide_room_labels(school)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.45, 0.49, 0.58)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key_light.light_energy = 0.7
	key_light.shadow_enabled = true
	add_child(key_light)

func _build_monster() -> void:
	_monster = MONSTER_SCENE.instantiate() as CharacterBody3D
	_monster.name = "TitleMonster"
	_monster.collision_layer = 0
	_monster.collision_mask = 0
	_monster.position = _orbit_center
	add_child(_monster)
	_monster.set_physics_process(false)
	_monster.set_process(false)
	_monster.set_process_input(false)
	_monster.set_process_unhandled_input(false)
	for audio in _monster.find_children("*", "AudioStreamPlayer3D", true, false):
		audio.stop()
	var visual := _monster.get_node_or_null("AnimatedMonsterVisual")
	if visual != null and visual.has_method("play_animation"):
		visual.call("play_animation", &"idle0", 0.0)
	_monster.call("set_preview_search_cone_visible", false)
	_monster.rotation.y = PI

func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "OrbitCamera"
	_camera.current = true
	_camera.fov = 58.0
	_camera.near = 0.05
	add_child(_camera)

func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.045, 0.56)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(56.0, 0.0)
	panel.size = Vector2(390.0, 720.0)
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 48.0
	panel.offset_right = 430.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 20)
	stack.add_theme_constant_override("margin_left", 32)
	stack.add_theme_constant_override("margin_right", 32)
	panel.add_child(stack)
	var eyebrow := Label.new()
	eyebrow.text = "WELCOME TO"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color(0.66, 0.79, 0.86))
	stack.add_child(eyebrow)
	var title := Label.new()
	title.text = "AFTER\nSCHOOL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.94, 0.94, 0.86))
	stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "The halls are never empty."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.76, 0.79))
	stack.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 22.0
	stack.add_child(spacer)
	var start := _make_button("START GAME")
	start.pressed.connect(_start_game)
	stack.add_child(start)
	var exit := _make_button("EXIT")
	exit.pressed.connect(_exit_game)
	stack.add_child(exit)
	var footer := Label.new()
	footer.text = "WASD MOVE   ·   SHIFT SPRINT   ·   E INTERACT"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.55, 0.61, 0.65))
	stack.add_child(footer)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.065, 0.93)
	style.border_color = Color(0.37, 0.52, 0.58, 0.7)
	style.border_width_right = 1
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	return style

func _make_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0.0, 56.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.94, 0.95, 0.91))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.22, 0.27, 0.96)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.19, 0.36, 0.41, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.09, 0.18, 0.23, 1.0)))
	return button

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.48, 0.66, 0.69, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func _find_node_named(root: Node, target: String) -> Node:
	if root.name == target:
		return root
	for child in root.get_children():
		var result := _find_node_named(child, target)
		if result != null:
			return result
	return null

func _hide_room_labels(root: Node) -> void:
	for candidate in root.find_children("*", "Node3D", true, false):
		var label_name := String(candidate.name)
		if label_name.ends_with(" Label") and not label_name.contains("Door"):
			(candidate as Node3D).visible = false

func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _exit_game() -> void:
	get_tree().quit()
