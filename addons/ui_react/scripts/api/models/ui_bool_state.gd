@tool
## Typed [UiState] for boolean payloads (toggles, pressed/disabled flags).
class_name UiBoolState
extends UiState

@export var value: bool = false


func _init(initial_value: Variant = false) -> void:
	if typeof(initial_value) != TYPE_NIL:
		value = bool(initial_value)


## Returns [member value] as [Variant] for [UiState] bindings.
func get_value() -> Variant:
	return value


## Coerces [param new_value] to [bool], updates [member value], and emits [signal value_changed] when it changes.
func set_value(new_value: Variant) -> void:
	var v := bool(new_value)
	if value == v:
		return
	var old: bool = value
	value = v
	if not Engine.is_editor_hint():
		value_changed.emit(v, old)
	emit_changed()


## Coerces [param new_value] to [bool] and updates [member value] without emitting [signal value_changed].
func set_silent(new_value: Variant) -> void:
	value = bool(new_value)
	emit_changed()


## Returns [member value] as [bool].
func get_bool_value() -> bool:
	return value


## Sets [member value] via [method set_value].
func set_bool_value(v: bool) -> void:
	set_value(v)
