@tool
## Typed [UiState] for numeric payloads (sliders, spin boxes, progress bars).
class_name UiFloatState
extends UiState

@export var value: float = 0.0


func _init(initial_value: Variant = 0.0) -> void:
	if typeof(initial_value) != TYPE_NIL:
		value = float(initial_value)


## Returns [member value] as [Variant] for [UiState] bindings.
func get_value() -> Variant:
	return value


## Coerces [param new_value] to [float], updates [member value], and emits [signal value_changed] when it changes.
func set_value(new_value: Variant) -> void:
	var v: float = 0.0 if new_value == null else float(new_value)
	if is_equal_approx(value, v):
		return
	var old: float = value
	value = v
	if not Engine.is_editor_hint():
		value_changed.emit(v, old)
	emit_changed()


## Coerces [param new_value] to [float] and updates [member value] without emitting [signal value_changed].
func set_silent(new_value: Variant) -> void:
	value = 0.0 if new_value == null else float(new_value)
	emit_changed()


## Returns [member value] as [float].
func get_float_value() -> float:
	return value


## Sets [member value] via [method set_value].
func set_float_value(v: float) -> void:
	set_value(v)
