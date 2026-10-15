extends CanvasLayer
## Presentation only. School calls this after its existing entrance slam.

var _shown := false
var _restarting := false
var _restart: Button


func show_victory() -> void:
	if _shown:
		return
	_shown = true
	layer = 100
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var shade := ColorRect.new()
	shade.name = "Fade"
	shade.color = Color.BLACK
	shade.modulate.a = 0.0
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var content := VBoxContainer.new()
	content.name = "Ending"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 22)
	content.modulate.a = 0.0
	center.add_child(content)
	var title := Label.new()
	title.text = "YOU ESCAPED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.87, 0.83, 0.78))
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "You made it out of the school."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.59, 0.59, 0.62))
	content.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	content.add_child(spacer)
	_restart = _button("Restart", content, _on_restart_pressed)
	_button("Quit", content, _on_quit_pressed)
	var fade := create_tween()
	fade.tween_property(shade, "modulate:a", 1.0, 1.2)
	fade.tween_property(content, "modulate:a", 1.0, 0.55)
	fade.tween_callback(_restart.grab_focus)


func _button(text: String, parent: Control, callback: Callable) -> Button:
	var button := Button.new()
	button.name = text
	button.text = text
	button.custom_minimum_size = Vector2(280, 48)
	button.add_theme_font_size_override("font_size", 19)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.055, 0.055, 0.065) if state == "normal" else Color(0.16, 0.075, 0.08)
		style.border_color = Color(0.34, 0.25, 0.25)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		button.add_theme_stylebox_override(state, style)
	button.disabled = true
	parent.add_child(button)
	button.pressed.connect(callback)
	get_tree().create_timer(1.75).timeout.connect(func() -> void: button.disabled = false)
	return button


func _on_restart_pressed() -> void:
	if _restarting:
		return
	_restarting = true
	var error := get_tree().reload_current_scene()
	if error != OK:
		_restarting = false
		push_error("Could not restart game: %s" % error_string(error))


func _on_quit_pressed() -> void:
	get_tree().quit()
