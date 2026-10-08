class_name NoiseEvent
extends RefCounted

enum NoiseLevel { QUIET, LOUD }

var source_position: Vector3
var level: NoiseLevel
var source_id: StringName

func _init(position: Vector3, noise_level: NoiseLevel, id: StringName) -> void:
	source_position = position
	level = noise_level
	source_id = id
