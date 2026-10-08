extends Node3D

@export var generate_school_collision: bool = true

@onready var school: Node3D = $School
@onready var player: CharacterBody3D = $PlayerPlaceholder
@onready var monster: CharacterBody3D = $MonsterPlaceholder
@onready var preview_environment: WorldEnvironment = $WorldEnvironment
@onready var preview_light: DirectionalLight3D = $PreviewLight
@onready var bell_status: Label = $DebugOverlay/BellStatus
@onready var spawn_help: Label = $DebugOverlay/SpawnHelp
@onready var item_help: Label = $DebugOverlay/ItemHelp

const NORMAL_BACKGROUND := Color(0.055, 0.07, 0.1, 1.0)
const NORMAL_AMBIENT := Color(0.55, 0.62, 0.75, 1.0)
const BELL_BACKGROUND := Color(0.12, 0.018, 0.028, 1.0)
const BELL_AMBIENT := Color(0.68, 0.075, 0.095, 1.0)
const PREVIEW_RELOCATION_INTERVAL := 10.0
const HALLWAY_SPAWN_FIRST_CHANCE := 0.75
const PREVIEW_DOOR_SCRIPT := preload("res://scenes/preview_school_door.gd")
const PREVIEW_ITEMS: Array[Dictionary] = [
	{"id": &"school_keys", "name": "School Keys", "room": &"main_office", "floor": "main office floor", "encounter": &"", "u": 0.5, "v": 0.5},
	{"id": &"weight", "name": "Weight", "room": &"locker_room", "floor": "locker room floor", "encounter": &"weight", "u": 0.5, "v": 0.12},
	{"id": &"book", "name": "Book", "room": &"library", "floor": "library floor", "encounter": &"book", "u": 0.9, "v": 0.1},
	{"id": &"brush", "name": "Brush", "room": &"artroom", "floor": "cafeteria floor", "encounter": &"brush", "u": 0.5, "v": 0.5},
	{"id": &"lab_coat", "name": "Lab Coat", "room": &"lab_room", "floor": "lab room floor", "encounter": &"", "u": 0.12, "v": 0.12},
	{"id": &"ruler", "name": "Ruler", "room": &"classroom_b", "floor": "classroom b floor", "encounter": &"ruler", "u": 0.5, "v": 0.5},
	{"id": &"snack", "name": "Snack", "room": &"cafeteria", "floor": "cafe floor", "encounter": &"snack", "u": 0.5, "v": 0.5},
	{"id": &"front_door_key", "name": "Front Door Key", "room": &"storage_closet", "floor": "storage closet floor", "encounter": &"final_key", "u": 0.5, "v": 0.5}
]
const PREVIEW_ROOM_FLOORS: Array[Dictionary] = [
	{"id": &"auditorium", "floor": "auditorium floor"},
	{"id": &"lobby", "floor": "lobby floor"},
	{"id": &"gym", "floor": "gym floor"},
	{"id": &"cafeteria", "floor": "cafe floor"},
	{"id": &"library", "floor": "library floor"},
	{"id": &"science_classroom", "floor": "science classroom floor"},
	{"id": &"classroom_a", "floor": "classroom a floor"},
	{"id": &"classroom_b", "floor": "classroom b floor"},
	{"id": &"classroom_c", "floor": "classroom c floor"},
	{"id": &"classroom_d", "floor": "classroom d floor"},
	{"id": &"classroom_e", "floor": "classroom e floor"},
	{"id": &"nurse_office", "floor": "nurse office floor"},
	{"id": &"main_office", "floor": "main office floor"},
	{"id": &"bathroom", "floor": "bathroom floor"},
	{"id": &"artroom", "floor": "cafeteria floor"},
	{"id": &"lab_room", "floor": "lab room floor"},
	{"id": &"locker_room", "floor": "locker room floor"}
]
const PREVIEW_WINDOW_SIDES: Array[Dictionary] = [
	{"id": &"lobby_south", "room": &"lobby", "floor": "lobby floor", "side": "south"},
	{"id": &"lobby_east", "room": &"lobby", "floor": "lobby floor", "side": "east"},
	{"id": &"classroom_e_west", "room": &"classroom_e", "floor": "classroom e floor", "side": "west"},
	{"id": &"classroom_e_north", "room": &"classroom_e", "floor": "classroom e floor", "side": "north"},
	{"id": &"classroom_c_west", "room": &"classroom_c", "floor": "classroom c floor", "side": "west"},
	{"id": &"classroom_d_east", "room": &"classroom_d", "floor": "classroom d floor", "side": "east"},
	{"id": &"cafeteria_south", "room": &"cafeteria", "floor": "cafe floor", "side": "south"},
	{"id": &"cafeteria_north", "room": &"cafeteria", "floor": "cafe floor", "side": "north"},
	{"id": &"science_west", "room": &"science_classroom", "floor": "science classroom floor", "side": "west"},
	{"id": &"science_south", "room": &"science_classroom", "floor": "science classroom floor", "side": "south"},
	{"id": &"lab_room_north", "room": &"lab_room", "floor": "lab room floor", "side": "north"},
	{"id": &"lab_room_classroom_shared", "room": &"lab_room", "floor": "lab room floor", "side": "west"},
	{"id": &"classroom_a_west", "room": &"classroom_a", "floor": "classroom a floor", "side": "west"},
	{"id": &"classroom_a_north", "room": &"classroom_a", "floor": "classroom a floor", "side": "north"},
	{"id": &"classroom_b_north", "room": &"classroom_b", "floor": "classroom b floor", "side": "north"},
	{"id": &"classroom_b_south", "room": &"classroom_b", "floor": "classroom b floor", "side": "south"},
	{"id": &"gym_south", "room": &"gym", "floor": "gym floor", "side": "south"},
	{"id": &"gym_east", "room": &"gym", "floor": "gym floor", "side": "east"},
	{"id": &"library_north", "room": &"library", "floor": "library floor", "side": "north"},
	{"id": &"library_south", "room": &"library", "floor": "library floor", "side": "south"}
]

var _bell_debug_active := false
var _spawn_markers: Array[Node3D] = []
var _spawn_marker_nodes_visible := true
var _preview_relocation_elapsed := 0.0
var _camera_hallway_spawn: Node3D
var _camera_hallway_spawn_valid := false
var _door_navigation_links: Dictionary = {}
var _active_safe_room_ids: Array[StringName] = []
var _safe_room_lights: Dictionary = {}
var _window_lurk_markers: Dictionary = {}
var _item_markers: Dictionary = {}
var _collected_preview_items: Dictionary = {}
var _item_room_bounds: Dictionary = {}
var _active_preview_encounter: StringName = &""
var _final_bell_started := false
var _science_encounter_started := false
var _science_spawn_pending := false
var _science_window_spawn_pending := false
var _locker_spots: Array[Dictionary] = []
var _active_locker_index := -1
var _player_locker_return_position := Vector3.ZERO
var _player_locker_return_visible := true
var _player_locker_return_layer := 1
var _player_locker_return_mask := 1

func _ready() -> void:
	_load_school_model()
	if generate_school_collision:
		_add_school_collisions(school)
	_create_school_doors()
	_build_school_navigation()
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _wait_for_navigation_map()
	_create_school_door_navigation_links()
	_register_preview_room_floors()
	_create_preview_items()
	_create_locker_placeholders()
	_create_window_lurk_markers()
	_place_player_at_nurse_office()
	_place_monster_deeper_in_hallway()
	monster.set_player_target(player)
	player.noise_emitted.connect(monster.receive_noise)
	monster.noise_relocation_requested.connect(_relocate_nearest_spawn_to_noise)
	_create_monster_spawn_locations()
	_camera_hallway_spawn = _make_spawn_panel(
		{"id": "behind_camera_hallway", "kind": "Behind camera hallway"},
		Vector3.ZERO
	)
	_camera_hallway_spawn.visible = false
	_apply_bell_debug_state()

func _process(delta: float) -> void:
	_update_preview_item_encounter()
	_update_locker_prompt()
	_try_science_room_encounter_spawn()
	_try_science_window_stalk_spawn()
	_camera_hallway_spawn_valid = _update_follow_camera_hallway_spawn()
	_camera_hallway_spawn.visible = _spawn_marker_nodes_visible and _camera_hallway_spawn_valid
	var chase_active: bool = monster.current_state == &"SHORT_CHASE" or monster.current_state == &"BELL_CHASE"
	if _bell_debug_active or chase_active or monster.current_state == &"INVESTIGATE" or _active_preview_encounter != &"" or monster.is_preview_weight_escape_active() or _science_window_spawn_pending or monster.is_preview_window_stalking() or monster.is_preview_window_sliding() or monster.is_preview_book_sinking():
		_update_spawn_debug_label()
		return
	_preview_relocation_elapsed += delta
	if _preview_relocation_elapsed >= PREVIEW_RELOCATION_INTERVAL:
		_preview_relocation_elapsed = 0.0
		_try_debug_offscreen_relocation()
	_update_spawn_debug_label()

func _update_spawn_debug_label() -> void:
	var countdown_text := "%.1fs" % maxf(0.0, PREVIEW_RELOCATION_INTERVAL - _preview_relocation_elapsed)
	if _bell_debug_active:
		countdown_text = "paused (Bell)"
	elif monster.current_state == &"SHORT_CHASE" or monster.current_state == &"BELL_CHASE":
		countdown_text = "paused (chase)"
	elif monster.current_state == &"INVESTIGATE":
		countdown_text = "paused (investigating)"
	elif _active_preview_encounter != &"":
		countdown_text = "paused (item encounter)"
	elif monster.is_preview_weight_escape_active():
		countdown_text = "paused (Weight escape)"
	elif _science_window_spawn_pending:
		countdown_text = "waiting for off-camera window spawn"
	elif monster.is_preview_window_sliding():
		countdown_text = "paused (window slide)"
	elif monster.is_preview_book_sinking():
		countdown_text = "paused (book sink)"
	var spawn_count := _spawn_markers.size() + int(_camera_hallway_spawn_valid)
	spawn_help.text = "Spawn panels: %d   Auto relocate: %s   Hallway bias: 75%%   M: toggle   X: test" % [spawn_count, countdown_text]

func _create_preview_items() -> void:
	for item in PREVIEW_ITEMS:
		var floor_node := _find_room_floor(school, item["floor"])
		if floor_node == null or floor_node.mesh == null:
			push_warning("Preview item floor not found for %s: %s" % [item["name"], item["floor"]])
			continue
		var bounds: AABB = floor_node.global_transform * floor_node.mesh.get_aabb()
		_item_room_bounds[item["room"]] = bounds
		var position := Vector3(
			lerpf(bounds.position.x, bounds.end.x, float(item["u"])),
			bounds.position.y + bounds.size.y + 0.08,
			lerpf(bounds.position.z, bounds.end.z, float(item["v"]))
		)
		var marker := Node3D.new()
		marker.name = "PreviewItem_" + String(item["id"])
		marker.position = position
		marker.set_meta("item_id", item["id"])
		var circle := MeshInstance3D.new()
		circle.name = "TemporaryItemCircle"
		var ring := TorusMesh.new()
		ring.inner_radius = 0.26
		ring.outer_radius = 0.36
		circle.mesh = ring
		circle.rotation_degrees.x = 90.0
		circle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.albedo_color = _preview_item_color(item["id"])
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.45
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		circle.material_override = material
		marker.add_child(circle)
		var label := Label3D.new()
		label.name = "ItemName"
		label.text = item["name"]
		label.position.y = 0.3
		label.font_size = 32
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = material.albedo_color
		marker.add_child(label)
		school.add_child(marker)
		_item_markers[item["id"]] = marker

func _preview_item_color(item_id: StringName) -> Color:
	match item_id:
		&"school_keys", &"front_door_key": return Color(1.0, 0.78, 0.14)
		&"weight": return Color(0.25, 0.85, 1.0)
		&"book": return Color(0.4, 0.75, 1.0)
		&"brush": return Color(1.0, 0.4, 0.75)
		&"lab_coat": return Color(0.9, 0.95, 1.0)
		&"ruler": return Color(1.0, 0.85, 0.25)
		&"snack": return Color(0.5, 1.0, 0.3)
	return Color.WHITE

func _update_preview_item_encounter() -> void:
	if _final_bell_started:
		item_help.text = "FINAL BELL: reach the entrance | E: collect a nearby item"
		return
	var science_bounds: AABB = _item_room_bounds.get(&"science_classroom", AABB())
	var player_in_science := science_bounds.size != Vector3.ZERO and _point_inside_room(player.global_position, science_bounds)
	if player_in_science and not _collected_preview_items.has(&"lab_coat"):
		if not _science_encounter_started:
			_science_encounter_started = true
			_science_spawn_pending = true
		_active_preview_encounter = &"science_classroom"
		if _science_spawn_pending:
			item_help.text = "Science Classroom encounter: the monster appears in the southeast corner when it is off-camera"
		else:
			item_help.text = "Science Classroom: sneak past the southeast corner; walking or running turns its spotlight"
		return
	var current_item: Dictionary = {}
	for item in PREVIEW_ITEMS:
		if item["encounter"] == &"" or _collected_preview_items.has(item["id"]):
			continue
		if item["encounter"] == &"final_key":
			continue
		if not _item_markers.has(item["id"]) or not _item_room_bounds.has(item["room"]):
			continue
		var bounds: AABB = _item_room_bounds[item["room"]]
		if _point_inside_room(player.global_position, bounds):
			current_item = item
			break
	if current_item.is_empty():
		if _science_encounter_started:
			var lab_bounds: AABB = _item_room_bounds.get(&"lab_room", AABB())
			var player_in_lab := lab_bounds.size != Vector3.ZERO and _point_inside_room(player.global_position, lab_bounds)
			if player_in_lab:
				_science_window_spawn_pending = true
			_science_encounter_started = false
			_science_spawn_pending = false
		_active_preview_encounter = &""
		monster.end_preview_item_encounter()
		item_help.text = "Item circles: E to collect when close | School Keys have no monster encounter"
		return
	var encounter: StringName = current_item["encounter"]
	if _active_preview_encounter != encounter:
		_active_preview_encounter = encounter
		var bounds: AABB = _item_room_bounds[current_item["room"]]
		var marker := _item_markers[current_item["id"]] as Node3D
		var points := _item_encounter_points(bounds, encounter)
		if encounter == &"weight":
			points = _locker_room_patrol_points(bounds)
			if not points.is_empty():
				monster.global_position = points[0]
		if encounter == &"book":
			monster.global_position = _library_northwest_spawn(bounds)
		monster.begin_preview_item_encounter(encounter, bounds, marker.global_position, points)
	var item_marker := _item_markers[current_item["id"]] as Node3D
	if player.global_position.distance_to(item_marker.global_position) <= 1.65:
		item_help.text = "%s encounter | E: collect %s | E near a locker to hide" % [_encounter_hint(encounter), current_item["name"]]
	else:
		item_help.text = "%s | Find the %s circle" % [_encounter_hint(encounter), current_item["name"]]

func _item_encounter_points(bounds: AABB, encounter: StringName) -> Array[Vector3]:
	var fractions: Array[Vector2] = []
	match encounter:
		&"weight": fractions = [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.75, 0.75), Vector2(0.25, 0.75)]
		&"book": fractions = [Vector2(0.2, 0.2), Vector2(0.8, 0.2), Vector2(0.8, 0.8), Vector2(0.2, 0.8)]
		&"brush": fractions = [Vector2(0.2, 0.2), Vector2(0.8, 0.2), Vector2(0.8, 0.8), Vector2(0.2, 0.8), Vector2(0.5, 0.25)]
		&"science_classroom": fractions = [Vector2(0.88, 0.88)]
		&"ruler": fractions = [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.75, 0.75), Vector2(0.25, 0.75)]
		&"snack": fractions = [Vector2(0.2, 0.25), Vector2(0.8, 0.25), Vector2(0.8, 0.75), Vector2(0.2, 0.75)]
	var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
	var result: Array[Vector3] = []
	for fraction in fractions:
		var desired := Vector3(
			lerpf(bounds.position.x, bounds.end.x, fraction.x),
			bounds.position.y + bounds.size.y,
			lerpf(bounds.position.z, bounds.end.z, fraction.y)
		)
		var snapped: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, desired)
		if snapped.distance_to(desired) <= 1.5 and _point_inside_room(snapped, bounds):
			result.append(snapped)
	return result

func _encounter_hint(encounter: StringName) -> String:
	match encounter:
		&"weight": return "Sneak to the north Weight; hide in a locker | Monster investigates noise"
		&"book": return "Maze: monster slowly searches; it vanishes when the Book is collected"
		&"brush": return "Don't disturb the room: look away and it may switch figures"
		&"science_classroom": return "Sneak past the southeast corner; walking or running slowly turns its spotlight"
		&"ruler": return "Darkness: follow the glowing smile as it shifts around the room"
		&"snack": return "Line of sight: monster patrols between tables; use cover"
	return ""

func _point_inside_room(position: Vector3, bounds: AABB) -> bool:
	return position.x >= bounds.position.x and position.x <= bounds.end.x and position.z >= bounds.position.z and position.z <= bounds.end.z

func _library_northwest_spawn(bounds: AABB) -> Vector3:
	var desired := Vector3(
		bounds.position.x + bounds.size.x * 0.1,
		bounds.end.y,
		bounds.position.z + bounds.size.z * 0.1
	)
	var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
	var snapped: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, desired)
	if snapped.distance_to(desired) <= 1.35 and _point_inside_room(snapped, bounds):
		return snapped
	return desired

func _try_collect_preview_item() -> bool:
	var nearest_item: Dictionary = {}
	var nearest_distance := INF
	for item in PREVIEW_ITEMS:
		if _collected_preview_items.has(item["id"]) or not _item_markers.has(item["id"]):
			continue
		if not _item_room_bounds.has(item["room"]) or not _point_inside_room(player.global_position, _item_room_bounds[item["room"]]):
			continue
		var marker := _item_markers[item["id"]] as Node3D
		var distance := player.global_position.distance_to(marker.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_item = item
	if nearest_item.is_empty() or nearest_distance > 1.65:
		return false
	var item_id: StringName = nearest_item["id"]
	_collected_preview_items[item_id] = true
	(_item_markers[item_id] as Node3D).visible = false
	player.noise_emitted.emit(NoiseEvent.new(player.global_position, NoiseEvent.NoiseLevel.LOUD, item_id))
	monster.on_preview_item_collected(item_id)
	if item_id == &"weight" and _item_room_bounds.has(&"gym"):
		var gym_bounds: AABB = _item_room_bounds[&"gym"]
		var gym_center := Vector3(gym_bounds.position.x + gym_bounds.size.x * 0.5, gym_bounds.end.y, gym_bounds.position.z + gym_bounds.size.z * 0.5)
		var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
		var gym_destination: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, gym_center)
		if gym_destination.distance_to(gym_center) > 2.0:
			gym_destination = gym_center
		monster.begin_preview_weight_escape(gym_destination)
	if item_id == &"lab_coat":
		_start_lab_coat_window_slide()
	_active_preview_encounter = &""
	if item_id == &"front_door_key":
		_science_window_spawn_pending = false
		_final_bell_started = true
		_bell_debug_active = true
		_apply_bell_debug_state()
		_active_safe_room_ids.clear()
		for safe_light in _safe_room_lights.values():
			(safe_light as OmniLight3D).queue_free()
		_safe_room_lights.clear()
		_sync_safe_room_door_links()
		monster.set_safe_rooms([])
		bell_status.text = "FINAL BELL: ON | Escape to the entrance"
		item_help.text = "Front Door Key collected: permanent Bell chase started. Reach the entrance."
	else:
		item_help.text = "%s collected" % nearest_item["name"]
	return true

func _create_locker_placeholders() -> void:
	var bounds: AABB = _item_room_bounds.get(&"locker_room", AABB())
	if bounds.size == Vector3.ZERO:
		return
	# Keep the doorway approaches open: lockers sit along both long sides and
	# avoid the east-side opening near the middle of the room.
	var positions := [
		Vector2(0.12, 0.17), Vector2(0.12, 0.40), Vector2(0.12, 0.80),
		Vector2(0.88, 0.17), Vector2(0.88, 0.38), Vector2(0.88, 0.80)
	]
	for i in positions.size():
		var fraction: Vector2 = positions[i]
		var center := Vector3(lerpf(bounds.position.x, bounds.end.x, fraction.x), bounds.end.y, lerpf(bounds.position.z, bounds.end.z, fraction.y))
		var face_inward := 1.0 if fraction.x < 0.5 else -1.0
		var locker := Node3D.new()
		locker.name = "LockerPlaceholder_%02d" % (i + 1)
		locker.position = center
		school.add_child(locker)
		var width := 0.82
		var depth := 0.78
		var height := 2.05
		_add_locker_panel(locker, Vector3(-face_inward * depth * 0.42, height * 0.5, 0.0), Vector3(0.12, height, width), Color(0.25, 0.34, 0.42))
		_add_locker_panel(locker, Vector3(face_inward * depth * 0.5, height * 0.5, -width * 0.5), Vector3(depth, height, 0.1), Color(0.31, 0.41, 0.49))
		_add_locker_panel(locker, Vector3(face_inward * depth * 0.5, height * 0.5, width * 0.5), Vector3(depth, height, 0.1), Color(0.31, 0.41, 0.49))
		_add_locker_panel(locker, Vector3(face_inward * depth * 0.5, height, 0.0), Vector3(depth, 0.1, width), Color(0.36, 0.46, 0.54))
		_locker_spots.append({"node": locker, "inside": center + Vector3(face_inward * depth * 0.15, 0.0, 0.0), "outside": center + Vector3(face_inward * (depth + 0.72), 0.0, 0.0), "normal": Vector3(face_inward, 0.0, 0.0)})

func _add_locker_panel(parent: Node3D, local_position: Vector3, size: Vector3, color: Color) -> void:
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	panel.mesh = box
	panel.position = local_position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	panel.material_override = material
	parent.add_child(panel)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	panel.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _locker_room_patrol_points(bounds: AABB) -> Array[Vector3]:
	var center_x := bounds.position.x + bounds.size.x * 0.5
	var north_z := bounds.position.z + bounds.size.z * 0.16
	var south_z := bounds.position.z + bounds.size.z * 0.84
	return [Vector3(center_x, bounds.end.y, north_z), Vector3(center_x, bounds.end.y, south_z)]

func _try_toggle_locker_hide() -> bool:
	if _active_locker_index >= 0:
		var spot: Dictionary = _locker_spots[_active_locker_index]
		player.global_position = spot["outside"]
		player.visible = _player_locker_return_visible
		player.collision_layer = _player_locker_return_layer
		player.collision_mask = _player_locker_return_mask
		player.set_physics_process(true)
		monster.set_preview_player_hidden(false)
		_active_locker_index = -1
		item_help.text = "You left the locker"
		return true
	if not _item_room_bounds.has(&"locker_room") or not _point_inside_room(player.global_position, _item_room_bounds[&"locker_room"]):
		return false
	var closest_index := -1
	var closest_distance := INF
	for index in _locker_spots.size():
		var spot: Dictionary = _locker_spots[index]
		var distance: float = player.global_position.distance_to(spot["outside"])
		if distance < closest_distance:
			closest_distance = distance
			closest_index = index
	if closest_index < 0 or closest_distance > 1.5:
		return false
	var selected: Dictionary = _locker_spots[closest_index]
	_player_locker_return_position = player.global_position
	_player_locker_return_visible = player.visible
	_player_locker_return_layer = player.collision_layer
	_player_locker_return_mask = player.collision_mask
	player.global_position = selected["inside"]
	player.visible = false
	player.collision_layer = 0
	player.collision_mask = 0
	player.set_physics_process(false)
	monster.set_preview_player_hidden(true)
	_active_locker_index = closest_index
	item_help.text = "Hidden in locker | E: leave locker"
	return true

func _update_locker_prompt() -> void:
	if _active_locker_index >= 0:
		item_help.text = "Hidden in locker | E: leave locker"
		return
	if not _item_room_bounds.has(&"locker_room") or not _point_inside_room(player.global_position, _item_room_bounds[&"locker_room"]):
		return
	for spot in _locker_spots:
		if player.global_position.distance_to(spot["outside"]) <= 1.5:
			item_help.text = "Locker | E: hide"
			return

func _try_science_window_stalk_spawn() -> void:
	if not _science_window_spawn_pending or _bell_debug_active:
		return
	var lab_windows: Array = _window_lurk_markers.get(&"lab_room", [])
	var north_window: Node3D
	for marker_node in lab_windows:
		var marker := marker_node as Node3D
		if is_instance_valid(marker) and String(marker.get_meta("window_id", "")) == "lab_room_north":
			north_window = marker
			break
	var destination := Vector3.ZERO
	if is_instance_valid(north_window):
		destination = north_window.global_position
	else:
		var lab_floor := _find_room_floor(school, "lab room floor")
		if lab_floor == null or lab_floor.mesh == null:
			return
		var lab_bounds: AABB = lab_floor.global_transform * lab_floor.mesh.get_aabb()
		var window_position := Vector3(
			lab_bounds.position.x + lab_bounds.size.x * 0.5,
			lab_bounds.position.y + lab_bounds.size.y,
			lab_bounds.position.z - 0.75
		)
		var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
		destination = NavigationServer3D.map_get_closest_point(navigation_map, window_position)
		if destination.distance_to(window_position) > 2.0 or _point_inside_room(destination, lab_bounds):
			return
	if destination == Vector3.ZERO:
		return
	if monster.try_preview_offscreen_teleport(destination, player.player_camera, false, 0.5):
		var lab_floor: MeshInstance3D = _find_room_floor(school, "lab room floor")
		if lab_floor != null and lab_floor.mesh != null:
			var lab_bounds: AABB = lab_floor.global_transform * lab_floor.mesh.get_aabb()
			monster.start_preview_window_stalk(Vector3.FORWARD, lab_bounds.position + lab_bounds.size * 0.5)
		else:
			monster.start_preview_window_stalk(Vector3.FORWARD)
		_science_window_spawn_pending = false
		print("Monster is holding still beyond the Lab Room north window")
		if _collected_preview_items.has(&"lab_coat"):
			_start_lab_coat_window_slide()

func _start_lab_coat_window_slide() -> void:
	if not monster.is_preview_window_stalking():
		return
	var lab_floor := _find_room_floor(school, "lab room floor")
	if lab_floor == null or lab_floor.mesh == null:
		return
	var lab_bounds: AABB = lab_floor.global_transform * lab_floor.mesh.get_aabb()
	var left_direction := -monster.global_basis.x
	left_direction.y = 0.0
	if left_direction.length_squared() < 0.001:
		return
	left_direction = left_direction.normalized()
	var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
	for slide_distance in [2.0, 3.0, 4.0]:
		var desired_position: Vector3 = monster.global_position + left_direction * float(slide_distance)
		var destination: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, desired_position)
		if destination.distance_to(desired_position) > 0.9 or _point_inside_room(destination, lab_bounds):
			continue
		monster.start_preview_window_left_slide(destination)
		print("Lab Coat collected: monster sliding left from Lab Room north window")
		return

func _try_science_room_encounter_spawn() -> void:
	if not _science_spawn_pending or _collected_preview_items.has(&"lab_coat") or _bell_debug_active:
		return
	var science_bounds: AABB = _item_room_bounds.get(&"science_classroom", AABB())
	if science_bounds.size == Vector3.ZERO:
		return
	var points := _item_encounter_points(science_bounds, &"science_classroom")
	if points.is_empty():
		return
	if monster.try_preview_offscreen_teleport(points[0], player.player_camera, false, 0.5):
		var lab_coat_marker := _item_markers.get(&"lab_coat") as Node3D
		var coat_position := lab_coat_marker.global_position if is_instance_valid(lab_coat_marker) else points[0]
		monster.begin_preview_item_encounter(&"science_classroom", science_bounds, coat_position, points)
		_science_spawn_pending = false
		print("Science Classroom corner encounter started before Lab Coat collection")

func _wait_for_navigation_map() -> void:
	var navigation_agent: NavigationAgent3D = monster.get_node("NavigationAgent3D")
	var navigation_map: RID = navigation_agent.get_navigation_map()
	var nurse_floor: MeshInstance3D = _find_nurse_floor(school)
	if nurse_floor == null or nurse_floor.mesh == null:
		return
	var bounds: AABB = nurse_floor.global_transform * nurse_floor.mesh.get_aabb()
	var sample_position := Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.position.y + bounds.size.y,
		bounds.position.z + bounds.size.z * 0.5
	)
	for frame_index in range(120):
		if NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
			var nearest_point: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, sample_position)
			if nearest_point.distance_to(sample_position) <= 1.35:
				return
		await get_tree().physics_frame

func _build_school_navigation() -> void:
	var region := NavigationRegion3D.new()
	region.name = "MonsterNavigation"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.agent_radius = 0.1
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_climb = 0.2
	nav_mesh.cell_size = 0.1
	nav_mesh.cell_height = 0.1
	nav_mesh.sample_partition_type = NavigationMesh.SAMPLE_PARTITION_MONOTONE
	region.navigation_mesh = nav_mesh
	var school_transform := school.global_transform
	remove_child(school)
	add_child(region)
	region.add_child(school)
	school.global_transform = school_transform
	NavigationServer3D.map_set_cell_size(region.get_navigation_map(), nav_mesh.cell_size)
	NavigationServer3D.map_set_cell_height(region.get_navigation_map(), nav_mesh.cell_height)
	region.bake_navigation_mesh(false)
	if region.navigation_mesh.get_polygon_count() == 0:
		push_error("Monster navigation mesh bake produced no walkable polygons.")

func _create_school_door_navigation_links() -> void:
	var navigation_agent: NavigationAgent3D = monster.get_node("NavigationAgent3D")
	var navigation_map: RID = navigation_agent.get_navigation_map()
	NavigationServer3D.map_set_link_connection_radius(navigation_map, 1.0)
	var region := get_node("MonsterNavigation") as NavigationRegion3D
	var created := 0
	for door in get_tree().get_nodes_in_group("preview_school_doors"):
		var door_node := door as Node3D
		var normal: Vector3 = door_node.global_basis * Vector3.BACK
		var start_world := NavigationServer3D.map_get_closest_point(navigation_map, door_node.global_position + normal * 1.1)
		var end_world := NavigationServer3D.map_get_closest_point(navigation_map, door_node.global_position - normal * 1.1)
		if start_world.distance_to(end_world) < 0.5:
			push_warning("Skipping door navigation link with coincident endpoints: %s" % door_node.name)
			continue
		var link := NavigationLink3D.new()
		link.name = "OpenDoorNavigation_%s" % String(door_node.get("door_id")).replace(" ", "_")
		link.bidirectional = true
		link.navigation_layers = 1
		link.enabled = false
		link.start_position = region.to_local(start_world)
		link.end_position = region.to_local(end_world)
		region.add_child(link)
		_door_navigation_links[door_node.get("door_id")] = link
		created += 1
	print("Door navigation links created: %d" % created)

func _on_preview_door_state_changed(door_id: StringName, is_open: bool) -> void:
	var link: NavigationLink3D = _door_navigation_links.get(door_id)
	if link == null:
		return
	var enable_link := is_open and not _door_connects_active_safe_room(link)
	link.enabled = enable_link
	if enable_link:
		_refresh_monster_navigation_after_door_open()

func _register_preview_room_floors() -> void:
	for room in PREVIEW_ROOM_FLOORS:
		var floor_node := _find_room_floor(school, room["floor"])
		if floor_node == null or floor_node.mesh == null:
			continue
		var bounds: AABB = floor_node.global_transform * floor_node.mesh.get_aabb()
		floor_node.add_to_group("preview_safe_room_floors")
		floor_node.set_meta("preview_room_id", room["id"])
		floor_node.set_meta("preview_room_bounds", bounds)
		_item_room_bounds[room["id"]] = bounds

func _create_window_lurk_markers() -> void:
	var navigation_map: RID = monster.get_node("NavigationAgent3D").get_navigation_map()
	var rejected_floors: Array[String] = []
	for room in PREVIEW_ROOM_FLOORS:
		rejected_floors.append(room["floor"])
	for window in PREVIEW_WINDOW_SIDES:
		var floor_node := _find_room_floor(school, window["floor"])
		if floor_node == null or floor_node.mesh == null:
			continue
		var bounds: AABB = floor_node.global_transform * floor_node.mesh.get_aabb()
		var window_world := bounds.position + bounds.size * 0.5
		var outside_direction := Vector3.ZERO
		match window["side"]:
			"north":
				window_world.z = bounds.position.z
				outside_direction = Vector3.BACK
			"south":
				window_world.z = bounds.end.z
				outside_direction = Vector3.FORWARD
			"west":
				window_world.x = bounds.position.x
				outside_direction = Vector3.LEFT
			"east":
				window_world.x = bounds.end.x
				outside_direction = Vector3.RIGHT
		window_world.y = bounds.position.y + bounds.size.y
		var desired_position := window_world + outside_direction * 0.75
		var hallway_position: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, desired_position)
		if hallway_position.distance_to(desired_position) > 1.25 or _position_in_excluded_floor(hallway_position, rejected_floors):
			continue
		var room_id: StringName = window["room"]
		var marker := Node3D.new()
		marker.name = "WindowLurk_" + String(window["id"])
		marker.set_meta("preview_room_id", room_id)
		marker.set_meta("window_id", window["id"])
		marker.set_meta("lurk_angle", atan2(hallway_position.z - (bounds.position.z + bounds.size.z * 0.5), hallway_position.x - (bounds.position.x + bounds.size.x * 0.5)))
		marker.add_to_group("preview_window_lurk_points")
		marker.add_to_group("preview_bell_lurk_points")
		var tile := MeshInstance3D.new()
		tile.name = "PurpleWindowLurkTile"
		var tile_mesh := QuadMesh.new()
		tile_mesh.size = Vector2(0.62, 0.62)
		tile.mesh = tile_mesh
		tile.position.y = 0.035
		tile.rotation_degrees.x = 90.0
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tile_material := StandardMaterial3D.new()
		tile_material.albedo_color = Color(0.72, 0.16, 1.0, 1.0)
		tile_material.emission_enabled = true
		tile_material.emission = Color(0.48, 0.04, 0.9, 1.0)
		tile_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tile.material_override = tile_material
		marker.add_child(tile)
		school.add_child(marker)
		marker.global_position = hallway_position
		if not _window_lurk_markers.has(room_id):
			_window_lurk_markers[room_id] = []
		_window_lurk_markers[room_id].append(marker)
	_create_safe_room_orbit_points(navigation_map, rejected_floors)
	var room_marker_counts: Array[String] = []
	for room_id in _window_lurk_markers:
		room_marker_counts.append("%s=%d" % [String(room_id), _window_lurk_markers[room_id].size()])
	print("Hallway window lurk tiles created: %d; Bell orbit points: %d (%s)" % [get_tree().get_nodes_in_group("preview_window_lurk_points").size(), get_tree().get_nodes_in_group("preview_bell_lurk_points").size(), ", ".join(room_marker_counts)])

func _create_safe_room_orbit_points(navigation_map: RID, rejected_floors: Array[String]) -> void:
	for room in PREVIEW_ROOM_FLOORS:
		var room_id: StringName = room["id"]
		var floor_node := _room_floor_for_id(room_id)
		if floor_node == null:
			continue
		var bounds: AABB = floor_node.get_meta("preview_room_bounds")
		var center := bounds.position + bounds.size * 0.5
		var margin := 0.9
		var orbit_positions: Array[Vector3] = [
			Vector3(bounds.position.x - margin, bounds.end.y, bounds.position.z - margin),
			Vector3(bounds.end.x + margin, bounds.end.y, bounds.position.z - margin),
			Vector3(bounds.end.x + margin, bounds.end.y, bounds.end.z + margin),
			Vector3(bounds.position.x - margin, bounds.end.y, bounds.end.z + margin)
		]
		for orbit_index in orbit_positions.size():
			var desired_position := orbit_positions[orbit_index]
			var hallway_position: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, desired_position)
			if hallway_position.distance_to(desired_position) > 1.5 or _position_in_excluded_floor(hallway_position, rejected_floors):
				continue
			var duplicate_position := false
			for existing in get_tree().get_nodes_in_group("preview_bell_lurk_points"):
				if existing.get_meta("preview_room_id", &"") == room_id and (existing as Node3D).global_position.distance_to(hallway_position) < 0.6:
					duplicate_position = true
					break
			if duplicate_position:
				continue
			var waypoint := Node3D.new()
			waypoint.name = "RoomOrbit_%s_%d" % [String(room_id), orbit_index]
			waypoint.set_meta("preview_room_id", room_id)
			waypoint.set_meta("lurk_angle", atan2(hallway_position.z - center.z, hallway_position.x - center.x))
			waypoint.add_to_group("preview_bell_lurk_points")
			school.add_child(waypoint)
			waypoint.global_position = hallway_position

func _choose_preview_safe_rooms() -> void:
	_active_safe_room_ids.clear()
	var eligible_rooms: Array[StringName] = []
	for waypoint in get_tree().get_nodes_in_group("preview_bell_lurk_points"):
		var room_id: StringName = waypoint.get_meta("preview_room_id", &"")
		if room_id != &"" and room_id != &"lobby" and not eligible_rooms.has(room_id):
			eligible_rooms.append(room_id)
	eligible_rooms.shuffle()
	for index in mini(3, eligible_rooms.size()):
		_active_safe_room_ids.append(eligible_rooms[index])
	for room_id in _safe_room_lights:
		(_safe_room_lights[room_id] as OmniLight3D).queue_free()
	_safe_room_lights.clear()
	for room_id in _active_safe_room_ids:
		var floor_node := _room_floor_for_id(room_id)
		if floor_node == null or floor_node.mesh == null:
			continue
		var bounds: AABB = floor_node.global_transform * floor_node.mesh.get_aabb()
		var safe_light := OmniLight3D.new()
		safe_light.name = "ActiveSafeRoomLight_" + String(room_id)
		safe_light.light_color = Color(1.0, 0.78, 0.46)
		safe_light.light_energy = 2.2
		safe_light.omni_range = maxf(bounds.size.x, bounds.size.z) * 0.75 + 3.0
		safe_light.shadow_enabled = false
		safe_light.position = school.to_local(Vector3(bounds.position.x + bounds.size.x * 0.5, bounds.end.y + 2.0, bounds.position.z + bounds.size.z * 0.5))
		school.add_child(safe_light)
		_safe_room_lights[room_id] = safe_light
	print("Bell preview active safe rooms (%d): %s" % [_active_safe_room_ids.size(), ", ".join(PackedStringArray(_active_safe_room_ids.map(func(id: StringName) -> String: return String(id))))])

func _room_floor_for_id(room_id: StringName) -> MeshInstance3D:
	for floor_node in get_tree().get_nodes_in_group("preview_safe_room_floors"):
		if floor_node.get_meta("preview_room_id", &"") == room_id:
			return floor_node as MeshInstance3D
	return null

func _door_connects_active_safe_room(link: NavigationLink3D) -> bool:
	var start_world: Vector3 = link.global_transform * link.start_position
	var end_world: Vector3 = link.global_transform * link.end_position
	for room_id in _active_safe_room_ids:
		var floor_node := _room_floor_for_id(room_id)
		if floor_node == null:
			continue
		var bounds: AABB = floor_node.get_meta("preview_room_bounds")
		if _point_is_inside_room_xz(start_world, bounds) or _point_is_inside_room_xz(end_world, bounds):
			return true
	return false

func _point_is_inside_room_xz(point: Vector3, bounds: AABB) -> bool:
	return point.x >= bounds.position.x and point.x <= bounds.end.x and point.z >= bounds.position.z and point.z <= bounds.end.z

func _sync_safe_room_door_links() -> void:
	for door_id in _door_navigation_links:
		var link: NavigationLink3D = _door_navigation_links[door_id]
		var door: Node3D
		for candidate in get_tree().get_nodes_in_group("preview_school_doors"):
			if candidate.get("door_id") == door_id:
				door = candidate as Node3D
				break
		link.enabled = is_instance_valid(door) and door.get("_opened") and not _door_connects_active_safe_room(link)

func _refresh_monster_navigation_after_door_open() -> void:
	await get_tree().physics_frame
	monster.refresh_preview_navigation()

func _create_school_doors() -> void:
	var headers: Array[MeshInstance3D] = []
	_collect_door_headers(school, headers)
	var centers: Array[Vector3] = []
	var locker_floor := _find_room_floor(school, "locker room floor")
	var locker_center := Vector3.ZERO
	if locker_floor != null and locker_floor.mesh != null:
		var locker_bounds: AABB = locker_floor.global_transform * locker_floor.mesh.get_aabb()
		locker_center = locker_bounds.position + locker_bounds.size * 0.5
	for header in headers:
		if header.mesh == null:
			continue
		var bounds: AABB = header.global_transform * header.mesh.get_aabb()
		var center := bounds.get_center()
		var duplicate := false
		for existing in centers:
			if Vector2(existing.x, existing.z).distance_to(Vector2(center.x, center.z)) < 0.55:
				duplicate = true
				break
		if duplicate:
			continue
		var width := maxf(bounds.size.x, bounds.size.z)
		var thickness := minf(bounds.size.x, bounds.size.z)
		if width < 0.72:
			continue
		centers.append(center)
		var one_way := header.name.to_lower().contains("locker room hallway")
		var allowed_side := Vector3.ZERO
		if one_way:
			allowed_side = locker_center - center
			allowed_side.y = 0.0
		var door := PREVIEW_DOOR_SCRIPT.new()
		door.name = "Door_%s" % String(header.name).replace("Door Header Wall Infill - ", "").replace(" ", "_")
		door.configure(
			StringName(header.name),
			Vector3(center.x, 0.14, center.z),
			minf(width, 2.8),
			2.15,
			maxf(0.08, minf(thickness, 0.18)),
			player,
			monster,
			width >= 1.8,
			one_way,
			allowed_side,
			bounds.size.z > bounds.size.x
		)
		door.opened.connect(_on_preview_door_opened)
		door.open_state_changed.connect(_on_preview_door_state_changed)
		door.add_to_group("preview_school_doors")
		school.add_child(door)
	print("Preview doors created: %d" % centers.size())

func _collect_door_headers(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.name.to_lower().contains("door header wall infill"):
		result.append(node)
	for child in node.get_children():
		_collect_door_headers(child, result)

func _on_preview_door_opened(door_id: StringName, world_position: Vector3, loudness: float) -> void:
	print("Door opened: %s (noise %.0f%%)" % [door_id, loudness * 100.0])
	monster.receive_preview_door_noise(world_position, loudness)

func _relocate_nearest_spawn_to_noise(source_position: Vector3) -> void:
	if _bell_debug_active or monster.current_state not in [&"PATROL", &"INVESTIGATE"]:
		return
	var candidates: Array[Node3D] = _spawn_markers.duplicate()
	if _camera_hallway_spawn_valid:
		candidates.append(_camera_hallway_spawn)
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(source_position) < b.global_position.distance_squared_to(source_position)
	)
	for marker in candidates:
		if monster.try_preview_offscreen_teleport(marker.global_position, player.player_camera, _is_hallway_spawn(marker)):
			print("Monster relocated off-camera to investigate sound: %s" % marker.get_meta("spawn_id", marker.name))
			monster.begin_preview_investigation(source_position)
			return

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_E:
		if _active_locker_index >= 0:
			_try_toggle_locker_hide()
		elif not _try_collect_preview_item():
			_try_toggle_locker_hide()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_Z and not _final_bell_started:
		_bell_debug_active = not _bell_debug_active
		_apply_bell_debug_state()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_M:
		_spawn_marker_nodes_visible = not _spawn_marker_nodes_visible
		for marker in _spawn_markers:
			marker.visible = _spawn_marker_nodes_visible
		if is_instance_valid(_camera_hallway_spawn):
			_camera_hallway_spawn.visible = _spawn_marker_nodes_visible and _camera_hallway_spawn_valid
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_X:
		_try_debug_offscreen_relocation()
		get_viewport().set_input_as_handled()

func _create_monster_spawn_locations() -> void:
	# Fractions are measured across the named room floor bounds. Entries are
	# preview candidates only; excluded rooms are checked again before creation.
	var candidates: Array[Dictionary] = [
		{"id": "hall_corner_lobby_west", "floor": "lobby floor", "u": 0.12, "v": 0.22, "kind": "Beyond hallway corner"},
		{"id": "hall_corner_lobby_east", "floor": "lobby floor", "u": 0.92, "v": 0.78, "kind": "Beyond hallway corner"},
		{"id": "hall_corner_auditorium_wing", "floor": "school site floor - circulation", "x": 6.5, "z": -5.0, "kind": "Beyond hallway corner"},
		{"id": "hall_corner_cafe_science", "floor": "school site floor - circulation", "x": 22.5, "z": 11.0, "kind": "Beyond hallway corner"},
		{"id": "hall_corner_classroom_cd", "floor": "school site floor - circulation", "x": 20.0, "z": 15.5, "kind": "Beyond hallway corner"},
		{"id": "hall_corner_science_class_e", "floor": "school site floor - circulation", "x": 28.0, "z": 16.0, "kind": "Beyond hallway corner"},
		{"id": "t_intersection_lobby", "floor": "lobby floor", "u": 0.70, "v": 0.48, "kind": "T-intersection"},
		{"id": "behind_lobby_pillar", "floor": "lobby floor", "u": 0.49, "v": 0.83, "kind": "Behind pillar"},
		{"id": "behind_locker_bank_hall", "floor": "", "u": 0.0, "v": 0.0, "kind": "Behind lockers (hall side)"},
		{"id": "behind_player_nurse", "floor": "nurse office floor", "u": 0.78, "v": 0.80, "kind": "Behind player"},
		{"id": "far_end_lobby_hall", "floor": "lobby floor", "u": 0.96, "v": 0.45, "kind": "Far end of hall"},
		{"id": "class_a_door", "floor": "classroom a floor", "u": 0.36, "v": 0.68, "kind": "Inside classroom doorway"},
		{"id": "class_c_door", "floor": "classroom c floor", "u": 0.48, "v": 0.73, "kind": "Inside classroom doorway"},
		{"id": "class_d_door", "floor": "classroom d floor", "u": 0.48, "v": 0.73, "kind": "Inside classroom doorway"},
		{"id": "class_e_door", "floor": "classroom e floor", "u": 0.42, "v": 0.79, "kind": "Inside classroom doorway"},
		{"id": "class_a_window_west", "floor": "classroom a floor", "u": 0.15, "v": 0.45, "kind": "Behind classroom window"},
		{"id": "class_a_window_north", "floor": "classroom a floor", "u": 0.76, "v": 0.16, "kind": "Behind classroom window"},
		{"id": "class_c_window_west", "floor": "classroom c floor", "u": 0.15, "v": 0.44, "kind": "Behind classroom window"},
		{"id": "class_d_window_east", "floor": "classroom d floor", "u": 0.85, "v": 0.45, "kind": "Behind classroom window"},
		{"id": "class_e_window_west", "floor": "classroom e floor", "u": 0.14, "v": 0.48, "kind": "Behind classroom window"},
		{"id": "class_e_window_north", "floor": "classroom e floor", "u": 0.76, "v": 0.15, "kind": "Behind classroom window"},
		{"id": "inside_auditorium", "floor": "auditorium floor", "u": 0.84, "v": 0.18, "kind": "Inside room"},
		{"id": "inside_gym", "floor": "gym floor", "u": 0.18, "v": 0.82, "kind": "Inside room"},
		{"id": "inside_class_a", "floor": "classroom a floor", "u": 0.80, "v": 0.78, "kind": "Inside room"},
		{"id": "inside_class_c", "floor": "classroom c floor", "u": 0.80, "v": 0.24, "kind": "Inside room"},
		{"id": "inside_class_d", "floor": "classroom d floor", "u": 0.20, "v": 0.24, "kind": "Inside room"},
		{"id": "inside_class_e", "floor": "classroom e floor", "u": 0.82, "v": 0.54, "kind": "Inside room"},
		{"id": "inside_nurse_office", "floor": "nurse office floor", "u": 0.25, "v": 0.24, "kind": "Inside room"},
		{"id": "inside_bathroom", "floor": "bathroom floor", "u": 0.24, "v": 0.75, "kind": "Inside room"}
	]
	var excluded_floor_names: Array[String] = [
		"main office floor", "locker room floor", "library floor", "artroom floor",
		"art room floor", "lab room floor", "classroom b floor", "cafeteria floor", "cafe floor",
		"outside floor", "storage closet floor"
	]
	var navigation_agent: NavigationAgent3D = monster.get_node("NavigationAgent3D")
	var navigation_map: RID = navigation_agent.get_navigation_map()
	for candidate in candidates:
		var spawn_position: Vector3
		if candidate.has("x") and candidate.has("z"):
			var circulation_floor := _find_room_floor(school, candidate["floor"])
			if circulation_floor == null or circulation_floor.mesh == null:
				continue
			var circulation_bounds: AABB = circulation_floor.global_transform * circulation_floor.mesh.get_aabb()
			spawn_position = Vector3(float(candidate["x"]), circulation_bounds.position.y + circulation_bounds.size.y, float(candidate["z"]))
		elif candidate["id"] == "behind_locker_bank_hall":
			var locker_floor := _find_room_floor(school, "locker room floor")
			if locker_floor == null or locker_floor.mesh == null:
				continue
			var locker_bounds: AABB = locker_floor.global_transform * locker_floor.mesh.get_aabb()
			spawn_position = Vector3(locker_bounds.end.x + 0.75, locker_bounds.position.y + locker_bounds.size.y, locker_bounds.position.z + locker_bounds.size.z * 0.5)
		else:
			var room_floor := _find_room_floor(school, candidate["floor"])
			if room_floor == null or room_floor.mesh == null:
				continue
			var bounds: AABB = room_floor.global_transform * room_floor.mesh.get_aabb()
			spawn_position = Vector3(
				bounds.position.x + bounds.size.x * float(candidate["u"]),
				bounds.position.y + bounds.size.y,
				bounds.position.z + bounds.size.z * float(candidate["v"])
			)
		if _position_in_excluded_floor(spawn_position, excluded_floor_names):
			continue
		var closest_nav_point: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, spawn_position)
		if closest_nav_point.distance_to(spawn_position) > 1.35:
			continue
		if _position_in_excluded_floor(closest_nav_point, excluded_floor_names):
			continue
		_spawn_markers.append(_make_spawn_panel(candidate, closest_nav_point))
	_update_spawn_debug_label()

func _make_spawn_panel(candidate: Dictionary, spawn_position: Vector3) -> Node3D:
	var marker := Node3D.new()
	marker.name = "Spawn_" + String(candidate["id"])
	marker.position = spawn_position
	marker.add_to_group("monster_spawn_points")
	marker.set_meta("spawn_kind", candidate["kind"])
	marker.set_meta("spawn_id", candidate["id"])
	var panel := MeshInstance3D.new()
	panel.name = "TemporaryGreenPanel"
	var panel_mesh := QuadMesh.new()
	panel_mesh.size = Vector2(0.48, 0.48)
	panel.mesh = panel_mesh
	panel.position.y = 1.0
	panel.rotation_degrees.x = 90.0
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var panel_material := StandardMaterial3D.new()
	panel_material.albedo_color = Color(0.12, 1.0, 0.18, 1.0)
	panel_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	panel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel.material_override = panel_material
	marker.add_child(panel)
	school.add_child(marker)
	return marker

func _position_in_excluded_floor(position: Vector3, excluded_names: Array[String]) -> bool:
	for floor_name in excluded_names:
		var floor_node := _find_room_floor(school, floor_name)
		if floor_node == null or floor_node.mesh == null:
			continue
		var bounds: AABB = floor_node.global_transform * floor_node.mesh.get_aabb()
		var inside_x := position.x >= bounds.position.x and position.x <= bounds.end.x
		var inside_z := position.z >= bounds.position.z and position.z <= bounds.end.z
		if inside_x and inside_z:
			return true
	return false

func _try_debug_offscreen_relocation() -> void:
	if _bell_debug_active or (_spawn_markers.is_empty() and not _camera_hallway_spawn_valid):
		return
	var hallway_markers: Array[Node3D] = []
	var other_markers: Array[Node3D] = []
	if _camera_hallway_spawn_valid:
		hallway_markers.append(_camera_hallway_spawn)
	for marker in _spawn_markers:
		if _is_hallway_spawn(marker):
			hallway_markers.append(marker)
		else:
			other_markers.append(marker)
	var hallway_first := randf() < HALLWAY_SPAWN_FIRST_CHANCE
	if hallway_first:
		hallway_markers.shuffle()
		for marker in hallway_markers:
			if monster.try_preview_offscreen_teleport(marker.global_position, player.player_camera, true):
				return
		other_markers.shuffle()
		for marker in other_markers:
			if monster.try_preview_offscreen_teleport(marker.global_position, player.player_camera, false):
				return
	else:
		other_markers.shuffle()
		for marker in other_markers:
			if monster.try_preview_offscreen_teleport(marker.global_position, player.player_camera, false):
				return
		hallway_markers.shuffle()
		for marker in hallway_markers:
			if monster.try_preview_offscreen_teleport(marker.global_position, player.player_camera, true):
				return

func _is_hallway_spawn(marker: Node3D) -> bool:
	var spawn_kind := String(marker.get_meta("spawn_kind", ""))
	return spawn_kind in ["Beyond hallway corner", "T-intersection", "Far end of hall", "Behind lockers (hall side)", "Behind camera hallway"]

func _update_follow_camera_hallway_spawn() -> bool:
	if not is_instance_valid(_camera_hallway_spawn) or not is_instance_valid(player.player_camera):
		return false
	var camera: Camera3D = player.player_camera
	var backward := camera.global_basis.z
	backward.y = 0.0
	if backward.length_squared() < 0.001:
		return false
	backward = backward.normalized()
	var desired_position := camera.global_position + backward * 4.0
	desired_position.y = player.global_position.y
	var navigation_agent: NavigationAgent3D = monster.get_node("NavigationAgent3D")
	var navigation_map: RID = navigation_agent.get_navigation_map()
	var hallway_position: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, desired_position)
	if hallway_position.distance_to(desired_position) > 0.8:
		return false
	var camera_forward := -backward
	if (hallway_position - camera.global_position).dot(camera_forward) > -0.5:
		return false
	var excluded_floor_names: Array[String] = [
		"main office floor", "locker room floor", "library floor", "artroom floor",
		"art room floor", "lab room floor", "classroom b floor", "cafeteria floor", "cafe floor",
		"outside floor", "storage closet floor", "auditorium floor", "gym floor",
		"classroom a floor", "classroom c floor", "classroom d floor", "classroom e floor",
		"nurse office floor", "bathroom floor"
	]
	if _position_in_excluded_floor(hallway_position, excluded_floor_names):
		return false
	var nearest_hall_marker_distance := INF
	for marker in _spawn_markers:
		if not _is_hallway_spawn(marker):
			continue
		nearest_hall_marker_distance = minf(nearest_hall_marker_distance, hallway_position.distance_to(marker.global_position))
	if nearest_hall_marker_distance > 8.0:
		return false
	_camera_hallway_spawn.global_position = hallway_position
	return true

func _load_school_model() -> void:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error: Error = document.append_from_file("res://assets/school_blockout.glb", state)
	if error != OK:
		push_error("Could not load assets/school_blockout.glb (error %s)." % error)
		return
	var model: Node = document.generate_scene(state)
	model.name = "SchoolModel"
	school.add_child(model)

func _add_school_collisions(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var lower_name: String = node.name.to_lower()
		if lower_name.contains("wall") or lower_name.contains("floor") or lower_name.contains("roof"):
			var shape: Shape3D = node.mesh.create_trimesh_shape()
			if shape != null:
				var body := StaticBody3D.new()
				body.name = "StaticCollision"
				body.collision_layer = 1
				body.collision_mask = 1
				node.add_child(body)
				var collision := CollisionShape3D.new()
				collision.shape = shape
				body.add_child(collision)

	for child in node.get_children():
		_add_school_collisions(child)

func _place_player_at_nurse_office() -> void:
	var nurse_floor: MeshInstance3D = _find_nurse_floor(school)
	if nurse_floor != null and nurse_floor.mesh != null:
		var bounds: AABB = nurse_floor.global_transform * nurse_floor.mesh.get_aabb()
		player.global_position = Vector3(
			bounds.position.x + bounds.size.x * 0.5,
			bounds.position.y + bounds.size.y,
			bounds.position.z + bounds.size.z * 0.5
		)
	else:
		player.position = Vector3(38.6, 0.14, 28.35)

func _place_monster_deeper_in_hallway() -> void:
	var lobby_floor: MeshInstance3D = _find_room_floor(school, "lobby floor")
	if lobby_floor == null or lobby_floor.mesh == null:
		monster.global_position = player.global_position + Vector3(-8.0, 0.0, -3.0)
		monster.start_preview_hallway_patrol(Vector3.RIGHT)
		return

	var bounds: AABB = lobby_floor.global_transform * lobby_floor.mesh.get_aabb()
	var center := bounds.position + bounds.size * 0.5
	var inner_room_floor: MeshInstance3D = _find_room_floor(school, "classroom d floor")
	var inner_target := center + Vector3(-2.0, 0.0, -3.0)
	if inner_room_floor != null and inner_room_floor.mesh != null:
		var inner_bounds: AABB = inner_room_floor.global_transform * inner_room_floor.mesh.get_aabb()
		inner_target = inner_bounds.position + inner_bounds.size * 0.5
	var direction := inner_target - center
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
	else:
		direction = Vector3(0.0, 0.0, -1.0)

	monster.global_position = Vector3(
		center.x + direction.x * 2.5,
		bounds.position.y + bounds.size.y,
		center.z + direction.z * 2.5
	)
	monster.start_preview_hallway_patrol(Vector3.RIGHT)

func _apply_bell_debug_state() -> void:
	preview_environment.environment.background_color = BELL_BACKGROUND if _bell_debug_active else NORMAL_BACKGROUND
	preview_environment.environment.ambient_light_color = BELL_AMBIENT if _bell_debug_active else NORMAL_AMBIENT
	preview_light.light_color = Color(1.0, 0.12, 0.16) if _bell_debug_active else Color.WHITE
	if _bell_debug_active:
		_choose_preview_safe_rooms()
		bell_status.text = "BELL DEBUG: ON (Z) | SAFE: %s" % ", ".join(PackedStringArray(_active_safe_room_ids.map(func(id: StringName) -> String: return String(id))))
	else:
		_active_safe_room_ids.clear()
		for safe_light in _safe_room_lights.values():
			(safe_light as OmniLight3D).queue_free()
		_safe_room_lights.clear()
		bell_status.text = "BELL DEBUG: OFF (Z)"
	_sync_safe_room_door_links()
	monster.set_safe_rooms(_active_safe_room_ids)
	monster.call("set_preview_bell_active", _bell_debug_active)

func _find_room_floor(node: Node, room_name: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name.to_lower().contains(room_name):
		return node
	for child in node.get_children():
		var found: MeshInstance3D = _find_room_floor(child, room_name)
		if found != null:
			return found
	return null

func _find_nurse_floor(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.name.to_lower().contains("nurse office floor"):
		return node
	for child in node.get_children():
		var found: MeshInstance3D = _find_nurse_floor(child)
		if found != null:
			return found
	return null
