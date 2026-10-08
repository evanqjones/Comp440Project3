extends CanvasLayer

# Presentation only: receives Player state without polling gameplay internals.
@onready var value_label: Label = $Stamina/Value
@onready var stamina_bar: ProgressBar = $Stamina/Bar


func update_stamina(current: float, capacity: float, _exhausted: bool) -> void:
	stamina_bar.max_value = capacity
	stamina_bar.value = current
	value_label.text = "Stamina: %.0f / %.0f" % [current, capacity]
