extends CanvasLayer

# Presentation only: receives Player state without polling gameplay internals.
@onready var stamina_bar: ProgressBar = $Stamina/Bar
var _fill_style: StyleBoxFlat


func _ready() -> void:
	_fill_style = stamina_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	stamina_bar.add_theme_stylebox_override("fill", _fill_style)


func update_stamina(current: float, capacity: float, exhausted: bool) -> void:
	stamina_bar.max_value = capacity
	stamina_bar.value = current
	var fraction := clampf(current / maxf(capacity, 0.001), 0.0, 1.0)
	_fill_style.bg_color = Color(0.95, 0.28, 0.22) if exhausted else Color(0.25, 0.88, 0.52).lerp(Color(1.0, 0.66, 0.2), 1.0 - fraction)
