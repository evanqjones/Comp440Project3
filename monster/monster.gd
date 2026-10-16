extends Node3D
## Drop this visual under your game's CharacterBody3D. Motion/AI stays on the parent.
signal animation_finished(animation_name: StringName)
signal phase_changed(phase_number: int)

const MODELS = [
 preload("res://monster/models/phase_0.glb"),
 preload("res://monster/models/phase_1.glb"),
 preload("res://monster/models/phase_2.glb"),
 preload("res://monster/models/phase_3.glb")
]
const ANIMATION_DATA = preload("res://monster/animation_data.gd")
@export_range(0, 3, 1) var phase: int = 0:
 set(value):
  phase = clampi(value, 0, 3)
  if is_node_ready():
   _activate_phase(phase)
@export var autoplay: StringName = &""
var current_animation: StringName = &""
var manifest: Dictionary = ANIMATION_DATA.DATA.duplicate(true)
var _instances: Dictionary = {}
var _players: Dictionary = {}
var _active_phase: int = -1

func _ready() -> void:
 _activate_phase(phase)
 if not autoplay.is_empty():
  play_animation(autoplay)

func _activate_phase(number: int) -> void:
 if _active_phase == number:
  return
 for old_phase in _instances:
  _instances[old_phase].visible = false
  _players[old_phase].stop()
 if not _instances.has(number):
  var model: Node3D = MODELS[number].instantiate()
  model.name = "Phase%d" % number
  add_child(model)
  _enable_false_eye_glow(model)
  var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
  if player == null:
   push_error("Monster: imported phase %d has no AnimationPlayer" % number)
   model.queue_free()
   return
  _instances[number] = model
  _players[number] = player
  player.animation_finished.connect(_on_animation_finished)
  for animation_name in player.get_animation_list():
   var plain := _plain_name(animation_name)
   if manifest.get("animations", {}).has(plain):
    var animation := player.get_animation(animation_name)
    animation.loop_mode = Animation.LOOP_LINEAR if manifest.animations[plain].loop else Animation.LOOP_NONE
 _instances[number].visible = true
 _active_phase = number
 current_animation = &""
 phase_changed.emit(number)
 var default_name := "idle%d" % number
 if manifest.get("animations", {}).has(default_name):
  _play_on_active(StringName(default_name), 0.0)

func _enable_false_eye_glow(model: Node) -> void:
 for candidate in model.find_children("*", "MeshInstance3D", true, false):
  var mesh_instance := candidate as MeshInstance3D
  if not String(mesh_instance.name).to_lower().contains("white eye circle") or mesh_instance.mesh == null:
   continue
  for surface_index in mesh_instance.mesh.get_surface_count():
   var source_material := mesh_instance.get_active_material(surface_index) as StandardMaterial3D
   if source_material == null:
    continue
   var glowing_material := source_material.duplicate() as StandardMaterial3D
   glowing_material.emission_enabled = true
   glowing_material.emission = Color.WHITE
   glowing_material.emission_energy_multiplier = 1.5
   mesh_instance.set_surface_override_material(surface_index, glowing_material)

func _plain_name(name: StringName) -> String:
 var result := String(name)
 if result.contains("/"):
  result = result.get_slice("/", result.get_slice_count("/") - 1)
 return result

func _play_on_active(animation_name: StringName, blend: float) -> bool:
 if not _players.has(_active_phase):
  return false
 var player: AnimationPlayer = _players[_active_phase]
 for imported_name in player.get_animation_list():
  if _plain_name(imported_name) == String(animation_name):
   player.play(imported_name, blend)
   player.advance(0.0)
   current_animation = animation_name
   return true
 push_error("Monster animation missing after import: " + String(animation_name))
 return false

func play_animation(animation_name: StringName, blend: float = 0.12) -> bool:
 if not manifest.get("animations", {}).has(String(animation_name)):
  push_error("Unknown monster animation: " + String(animation_name))
  return false
 var target_phase: int = int(manifest.animations[String(animation_name)].phase)
 var switched := target_phase != _active_phase
 phase = target_phase
 return _play_on_active(animation_name, 0.0 if switched else blend)

func set_phase(number: int) -> void:
 phase = number

func get_animation_names() -> PackedStringArray:
 var names := PackedStringArray(manifest.get("animations", {}).keys())
 names.sort()
 return names

func get_animation_player() -> AnimationPlayer:
 return _players.get(_active_phase) as AnimationPlayer

func _on_animation_finished(imported_name: StringName) -> void:
 animation_finished.emit(StringName(_plain_name(imported_name)))
