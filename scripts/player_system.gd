extends Node
class_name PlayerSystem

var current_location: Vector2 = Vector2.ZERO
var movement_state: String = "walking"
var noise_level: float = 0.0
var collected_belongings: Array[String] = []
var is_hiding: bool = false


func update_location(new_location: Vector2) -> void:
	current_location = new_location


func set_movement_state(new_state: String) -> void:
	movement_state = new_state

	match movement_state:
		"walking":
			noise_level = 1.0
		"running":
			noise_level = 3.0
		"hiding":
			noise_level = 0.0


func collect_belonging(item_name: String) -> void:
	if item_name not in collected_belongings:
		collected_belongings.append(item_name)


func set_hiding(value: bool) -> void:
	is_hiding = value

	if is_hiding:
		set_movement_state("hiding")
	else:
		set_movement_state("walking")