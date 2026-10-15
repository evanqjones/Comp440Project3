extends Node
## Scene-local sound presentation. Never publishes gameplay noise or Bell state.
## This local event is for presentation checks, not a frozen gameplay contract.
signal cue_started(cue: StringName)

const WALK = preload("res://assets/audio/footstep_walk.wav")
const SPRINT = preload("res://assets/audio/footstep_sprint.wav")
const DOOR = preload("res://assets/audio/door_open.wav")
const PICKUP = preload("res://assets/audio/item_pickup.wav")
const BELL = preload("res://assets/audio/school_bell.wav")
const AMBIENCE = preload("res://assets/audio/school_ambience.wav")
const TENSION = preload("res://assets/audio/chase_tension.wav")
const CAPTURE = preload("res://assets/audio/capture_hit.wav")

var _player: PlayerSystem
var _steps: AudioStreamPlayer
var _pickup: AudioStreamPlayer
var _bell: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _tension: AudioStreamPlayer
var _capture: AudioStreamPlayer
var _doors: Array[AudioStreamPlayer3D] = []
var _step_remaining := 0.0
var _bell_requested := false
var _capturing := false
var _ended := false


func _ready() -> void:
	_steps = _voice("Footsteps", WALK, -10)
	_pickup = _voice("Pickup", PICKUP, -10)
	_bell = _voice("Bell", _loop(BELL), -14)
	_ambience = _voice("SchoolAmbience", _loop(AMBIENCE), -28)
	_tension = _voice("ChaseTension", _loop(TENSION), -23)
	_capture = _voice("Capture", CAPTURE, -8)
	_ambience.play()


func configure(player: PlayerSystem) -> void:
	_player = player


func _voice(label: String, stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.name = label
	voice.stream = stream
	voice.volume_db = volume
	add_child(voice)
	return voice


func _loop(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	return stream


func set_bell_active(active: bool) -> void:
	_bell_requested = active
	_sync_bell()


func _sync_bell() -> void:
	var audible := _bell_requested and not _capturing and not _ended
	for voice in [_bell, _tension]:
		if audible and not voice.playing:
			voice.play()
			cue_started.emit(&"bell" if voice == _bell else &"tension")
		elif not audible:
			voice.stop()


func play_door(position: Vector3) -> void:
	if _ended:
		return
	# Small bounded pool, including simultaneous automatic doorway openings.
	for i in range(_doors.size() - 1, -1, -1):
		if not is_instance_valid(_doors[i]) or not _doors[i].playing:
			_doors.remove_at(i)
	if _doors.size() >= 4:
		var oldest := _doors.pop_front() as AudioStreamPlayer3D
		oldest.stop()
		oldest.queue_free()
	var voice := AudioStreamPlayer3D.new()
	voice.name = "DoorSound"
	voice.stream = DOOR
	voice.volume_db = -8
	voice.unit_size = 5
	voice.max_distance = 24
	add_child(voice)
	voice.global_position = position
	voice.finished.connect(voice.queue_free)
	_doors.append(voice)
	voice.play()
	cue_started.emit(&"door")


func play_pickup() -> void:
	if not _ended:
		_pickup.play()
		cue_started.emit(&"pickup")


func _physics_process(delta: float) -> void:
	if _ended or not is_instance_valid(_player):
		return
	var capturing := _player.capture_presentation_active
	if capturing != _capturing:
		_capturing = capturing
		if capturing:
			_steps.stop()
			_capture.play()
			cue_started.emit(&"capture")
		_ambience.volume_db = -34 if capturing else -28
		_sync_bell()
	if capturing or not _player.is_physics_processing() or not _player.is_on_floor():
		_step_remaining = 0
		return
	var speed := _player.get_real_velocity()
	if Vector2(speed.x, speed.z).length_squared() < 0.04 or _player.movement_state == &"idle":
		_step_remaining = 0
		return
	_step_remaining -= delta
	if _step_remaining > 0:
		return
	var running := _player.movement_state == &"running"
	var sneaking := _player.movement_state == &"crouching"
	_steps.stream = SPRINT if running else WALK
	_steps.volume_db = -22 if sneaking else (-8 if running else -10)
	_steps.play()
	_step_remaining = 0.72 if sneaking else (0.31 if running else 0.5)
	cue_started.emit(&"sprint_step" if running else &"walk_step")


func finish_run() -> void:
	if _ended:
		return
	_ended = true
	_bell_requested = false
	for voice in [_steps, _pickup, _bell, _ambience, _tension, _capture]:
		voice.stop()
	for voice in _doors:
		if is_instance_valid(voice):
			voice.stop()
	_step_remaining = 0
