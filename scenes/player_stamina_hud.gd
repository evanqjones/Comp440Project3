extends CanvasLayer

# Presentation only: receives Player state without polling gameplay internals.
@onready var value_label: Label = $Stamina/Value
@onready var stamina_bar: ProgressBar = $Stamina/Bar
@onready var status_label: Label = $Stamina/Status


func update_stamina(current: float, capacity: float, exhausted: bool) -> void:
	stamina_bar.max_value = capacity
	stamina_bar.value = current
	value_label.text = "Stamina: %.0f / %.0f" % [current, capacity]
	status_label.text = "Exhausted - recovering" if exhausted else "Ready"
	status_label.modulate = Color(1.0, 0.65, 0.35) if exhausted else Color.WHITE
