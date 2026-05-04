@tool
class_name UiReactLiveGraphEditorDebuggerPlugin
extends EditorDebuggerPlugin

const _LiveGraphProt := preload("res://addons/ui_react/scripts/runtime/ui_react_live_graph_protocol.gd")

## Callable(message: String, data: Variant) -> forwarded to Graph / Dependency Graph ingest.
var _sink: Callable = Callable()


func set_sink(sink: Callable) -> void:
	_sink = sink


func _has_capture(capture: String) -> bool:
	return capture == _LiveGraphProt.CAPTURE_PREFIX


func _capture(message: String, data: Variant, session_id: int) -> bool:
	if not _sink.is_valid():
		return false
	var ok := false
	match message:
		_LiveGraphProt.MSG_V1_WIRE, _LiveGraphProt.MSG_V1_CMP, _LiveGraphProt.MSG_V1_ACT:
			if data is Array:
				_sink.call(message, data)
				ok = true
	return ok


func _setup_session(session_id: int) -> void:
	pass
