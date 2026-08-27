@tool
## Typed [UiState] for string payloads (labels, line edits, option item text).
class_name UiStringState
extends UiState

@export var value: String = ""


func _init(initial_value: Variant = "") -> void:
	if typeof(initial_value) != TYPE_NIL:
		value = str(initial_value)


## Returns [member value] as [Variant] for [UiState] bindings.
func get_value() -> Variant:
	return value


## Coerces [param new_value] to [String], updates [member value], and emits [signal value_changed] when it changes.
func set_value(new_value: Variant) -> void:
	var v: String = "" if new_value == null else str(new_value)
	if value == v:
		return
	var old: String = value
	value = v
	if not Engine.is_editor_hint():
		value_changed.emit(v, old)
	emit_changed()


## Coerces [param new_value] to [String] and updates [member value] without emitting [signal value_changed].
func set_silent(new_value: Variant) -> void:
	value = "" if new_value == null else str(new_value)
	emit_changed()


## Returns [member value] as [String].
func get_string_value() -> String:
	return value


## Sets [member value] via [method set_value].
func set_string_value(v: String) -> void:
	set_value(v)
