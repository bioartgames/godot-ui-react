@tool
## [UiComputedBoolState]: [code]not bool(sources[0])[/code] when [member sources] is non-empty; if empty or [code]sources[0][/code] is null, returns [code]true[/code] (matches former buy-disabled example).
class_name UiComputedBoolInvert
extends UiComputedBoolState


## Returns [code]not[/code] the first source value, or [code]true[/code] when [member sources] is empty.
func compute_bool() -> bool:
	if sources.is_empty() or sources[0] == null:
		return true
	return not bool(sources[0].get_value())
