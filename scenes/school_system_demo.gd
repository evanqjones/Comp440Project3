extends Node3D
## Integration/demo only; Player controller and School services remain independent.

@onready var school = $SchoolFoundation
@onready var bell = $SchoolFoundation/SchoolBell
@onready var player: Node3D = $PlayerPlaceholder
@onready var room_label: Label = $DemoOverlay/Panel/Margin/Rows/Room
@onready var bell_label: Label = $DemoOverlay/Panel/Margin/Rows/Bell
@onready var progress_label: Label = $DemoOverlay/Panel/Margin/Rows/Progress
@onready var challenge_label: Label = $DemoOverlay/Panel/Margin/Rows/Challenge
@onready var route_label: Label = $DemoOverlay/Panel/Margin/Rows/Route
@onready var events = $SchoolFoundation/RoomEvents

@export var simulate_lab_watch: bool = true
@export_range(0.5, 10.0, 0.1) var demo_look_away_seconds: float = 1.0
@export_range(0.5, 10.0, 0.1) var demo_watching_seconds: float = 2.0
@export_range(0.1, 1.0, 0.05) var route_refresh_seconds: float = 0.25

var _demo_progress: int = 0
var _watch_clock: float = 0.0
var _route_clock: float = 0.0
var _route_destination: int = 0
var _watch_lamp: MeshInstance3D


func _ready() -> void:
	player.global_position = school.get_entrance_position() + Vector3(0, 0.05, 0)
	school.set_player_target(player)
	events.bind_environment(school, player)
	events.challenge_completed.connect(_on_challenge_completed)
	events.challenge_failed.connect(func(id: StringName, reason: StringName) -> void:
		print("School room event reset: %s (%s)" % [id, reason]))
	_watch_lamp = MeshInstance3D.new()
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.25
	lamp_mesh.height = 0.5
	_watch_lamp.mesh = lamp_mesh
	var lamp_material := StandardMaterial3D.new()
	lamp_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_watch_lamp.material_override = lamp_material
	add_child(_watch_lamp)
	_watch_lamp.global_position = school.get_cell_position(school.layout.science_goal) + Vector3(0, 2.4, 0)
	school.player_room_changed.connect(_on_room_changed)
	bell.bell_state_changed.connect(_on_bell_changed)
	_on_room_changed(&"", school.get_room_id_at(player.global_position))
	_on_bell_changed(bell.get_bell_snapshot())
	_update_progress()
	bell.start_scheduling()
	_update_challenge_display()


func _physics_process(delta: float) -> void:
	if simulate_lab_watch:
		_watch_clock = fmod(_watch_clock + delta, demo_look_away_seconds + demo_watching_seconds)
		events.report_lab_watch_state(_watch_clock >= demo_look_away_seconds)
	_update_challenge_display()
	_route_clock += delta
	if school.debug_visible and _route_clock >= route_refresh_seconds:
		_route_clock = 0.0
		var targets: Array[Vector2i] = [school.layout.library_checkpoints[-1], school.layout.science_goal, school.layout.entrance_cell]
		school.show_debug_path(player.global_position, school.get_cell_position(targets[_route_destination]))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N:
			school.set_debug_visible(not school.debug_visible)
			return
		if event.keycode == KEY_V:
			_route_destination = (_route_destination + 1) % 3
			school.set_debug_visible(true)
			return
		if event.keycode == KEY_E:
			for id: StringName in [&"library_maze", &"science_stillness"]:
				if not events.request_retry(id):
					events.request_reward(id)
			return
		if event.keycode == KEY_C:
			# Explicit test of the external capture hook, never Monster behavior.
			events.report_player_caught(school.get_room_id_at(player.global_position))
			return
		if event.keycode == KEY_P:
			_demo_progress = mini(6, _demo_progress + 1)
		elif event.keycode == KEY_R:
			_demo_progress = 0
		else:
			return
		bell.set_objective_progress(_demo_progress)
		_update_progress()
		get_viewport().set_input_as_handled()


func _on_room_changed(_previous: StringName, current: StringName) -> void:
	room_label.text = "Room: " + (String(current).replace("_", " ").capitalize() if current != &"" else "Outside")


func _on_bell_changed(snapshot) -> void:
	bell_label.text = "BELL ACTIVE" if snapshot.active else "Bell quiet"
	bell_label.modulate = Color(1.0, 0.35, 0.25) if snapshot.active else Color(0.65, 0.9, 0.85)


func _update_progress() -> void:
	progress_label.text = "Test progress: %d / 6  |  P: advance  R: reset" % _demo_progress


func _on_challenge_completed(id: StringName, reward: StringName) -> void:
	print("School challenge complete: %s, reward hook: %s" % [id, reward])
	_demo_progress = mini(6, _demo_progress + 1)
	bell.set_objective_progress(_demo_progress)
	_update_progress()


func _update_challenge_display() -> void:
	var room: StringName = school.get_room_id_at(player.global_position)
	var snapshot: Dictionary = events.get_challenge_snapshot(&"science_stillness")
	var known: bool = snapshot.get("watch_known", false)
	var watching: bool = snapshot.get("watching", false)
	_watch_lamp.material_override.albedo_color = Color(1, 0.15, 0.1) if watching and known else Color(0.2, 1, 0.4) if known else Color(0.5, 0.5, 0.5)
	if room == &"science_lab":
		var watch_text := "WATCHING - stand still" if watching else "LOOKING AWAY - move"
		if not known:
			watch_text = "Waiting for Monster watch input"
		challenge_label.text = "Lab [%s]: %s\n%s | E: collect / retry at start" % [snapshot.state, watch_text, "SIMULATED watch signal" if simulate_lab_watch else "Monster watch signal"]
	elif room == &"library":
		snapshot = events.get_challenge_snapshot(&"library_maze")
		challenge_label.text = "Library maze [%s]: follow gold checkpoints.\nE: collect book / retry at start. C: test caught hook." % snapshot.state
	else:
		challenge_label.text = "Library: maze + book. Lab: stand still while watched.\nScience lab entrance is through Classroom 103."
	var destination_names := ["Library book", "Science lab coat", "Entrance"]
	route_label.text = "N: navigation debug | V: route to " + destination_names[_route_destination]
