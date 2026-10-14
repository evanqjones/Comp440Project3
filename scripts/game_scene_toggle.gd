extends CanvasLayer
## Persistent scene switcher. Switching starts a fresh game in the selected scene.

const MAIN_GAME := "res://scenes/demo_scene.tscn"
const SCHOOL_SYSTEM := "res://scenes/after_school.tscn"

var _button: Button
var _switching := false
var _using_toggle := false
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	layer = 100
	var layout := Control.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button = Button.new()
	layout.add_child(_button)
	_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_button.offset_left = -230
	_button.offset_right = 230
	_button.offset_top = -82
	_button.offset_bottom = -16
	_button.add_theme_font_size_override("font_size", 18)
	_button.focus_mode = Control.FOCUS_NONE
	_button.tooltip_text = "Hold Tab to use the mouse and click. F2 switches instantly. Switching starts a fresh game."
	_button.pressed.connect(_toggle_scene)
	get_tree().scene_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_switching = false
	_button.disabled = false
	var scene := get_tree().current_scene
	_button.text = "Switch to Main Game [F2]\nHold Tab + click while playing"
	if scene != null and scene.scene_file_path == MAIN_GAME:
		_button.text = "Main Game → School System [F2]\nHold Tab + click while playing"
	if _using_toggle:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		if event.echo:
			return
		if event.pressed:
			_previous_mouse_mode = Input.mouse_mode
			_using_toggle = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			_using_toggle = false
			Input.mouse_mode = _previous_mouse_mode
		return
	# Keep the player from recapturing the cursor on clicks outside the button.
	if _using_toggle and event is InputEventMouseButton:
		if not _button.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		get_viewport().set_input_as_handled()
		_toggle_scene()


func _toggle_scene() -> void:
	if _switching:
		return
	_switching = true
	_button.disabled = true
	var scene := get_tree().current_scene
	var target := MAIN_GAME
	if scene != null and scene.scene_file_path == MAIN_GAME:
		target = SCHOOL_SYSTEM
	# Defer removal until the current input callback has finished.
	_change_scene.call_deferred(target)


func _change_scene(target: String) -> void:
	var result := get_tree().change_scene_to_file(target)
	if result != OK:
		push_error("Could not switch game scene: %s" % error_string(result))
		_refresh()
