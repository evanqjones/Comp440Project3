extends CharacterBody3D
class_name PlayerSystem

# Read the body's live 3D position instead of maintaining a second location.
var current_location: Vector3:
	get:
		return get_world_position()

var movement_state: StringName:
	get:
		return _movement_state

var _movement_state: StringName = &"idle"


func get_world_position() -> Vector3:
	return global_position


func _update_movement_state(is_running: bool) -> void:
	# Call after move_and_slide(): walls and gravity alone must not count as walking.
	var real_velocity := get_real_velocity()
	var horizontal_speed_squared := Vector2(real_velocity.x, real_velocity.z).length_squared()

	if horizontal_speed_squared <= 0.0001:
		_movement_state = &"idle"
	elif is_running:
		_movement_state = &"running"
	else:
		_movement_state = &"walking"
