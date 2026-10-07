extends Node3D
## Integration/demo only; Player controller and School services remain independent.

@onready var school = $SchoolFoundation
@onready var bell = $SchoolFoundation/SchoolBell
@onready var player: Node3D = $PlayerPlaceholder
@onready var room_label: Label = $DemoOverlay/Panel/Margin/Rows/Room
@onready var bell_label: Label = $DemoOverlay/Panel/Margin/Rows/Bell
@onready var progress_label: Label = $DemoOverlay/Panel/Margin/Rows/Progress

var _demo_progress: int = 0


func _ready() -> void:
	player.global_position = school.get_entrance_position() + Vector3(0, 0.05, 0)
	school.set_player_target(player)
	school.player_room_changed.connect(_on_room_changed)
	bell.bell_state_changed.connect(_on_bell_changed)
	_on_room_changed(&"", school.get_room_id_at(player.global_position))
	_on_bell_changed(bell.get_bell_snapshot())
	_update_progress()
	bell.start_scheduling()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
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
