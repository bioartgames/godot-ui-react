## Runtime (**CB-018** live graph pulses): forwards wire/computed/action taps to [EngineDebugger]
## **`graph_live_pulses`** ([member UiReactDockConfig.KEY_RUNTIME_GRAPH_LIVE_PULSES_ENABLED]): synced from **Graph** tab **Play in editor** via **`UiReactDockConfig.sync_runtime_keys_from_editor_play_mode`** — runtime reads this bool only.
## **`EngineDebugger.is_active()`**, and **`OS.is_debug_build()`**. Editor consumes via [EditorDebuggerPlugin].
extends RefCounted
class_name UiReactLiveGraphTransport

## Must remain identical to [constant UiReactDockConfig.KEY_RUNTIME_GRAPH_LIVE_PULSES_ENABLED].
const PS_GRAPH_LIVE_PULSES := "ui_react/settings/runtime/graph_live_pulses_enabled"

const _Prot := preload("res://addons/ui_react/scripts/runtime/ui_react_live_graph_protocol.gd")

static var _capture_registered: bool = false


static func _ensure_registered() -> void:
	if _capture_registered:
		return
	EngineDebugger.register_message_capture(_Prot.CAPTURE_PREFIX, Callable(UiReactLiveGraphTransport, "_runtime_capture_in_game"))
	_capture_registered = true


static func _runtime_capture_in_game(_message: String, _data: Variant) -> bool:
	return false


static func reset_capture_registration_for_tests() -> void:
	_capture_registered = false


static func effective_send_enabled() -> bool:
	return (
		OS.is_debug_build()
		and EngineDebugger.is_active()
		and bool(ProjectSettings.get_setting(PS_GRAPH_LIVE_PULSES, false))
	)


static func scene_relative_paths(node: Node) -> Dictionary:
	var out := {&"scene_path": &"", &"relpath": &""}
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return out
	var tree := node.get_tree()
	if tree == null:
		return out
	var cs := tree.current_scene
	if cs == null:
		return out
	if not (cs == node or cs.is_ancestor_of(node)):
		return out
	var sp := String(cs.scene_file_path).strip_edges()
	if sp.is_empty():
		return out
	out[&"scene_path"] = sp
	out[&"relpath"] = str(cs.get_path_to(node))
	return out


static func wire_rule_index(host: Node, rule: UiReactWireRule) -> int:
	if host == null or rule == null or not &"wire_rules" in host:
		return -1
	var raw: Variant = host.get(&"wire_rules")
	if typeof(raw) != TYPE_ARRAY:
		return -1
	var i := 0
	for it in raw as Array:
		if it == rule:
			return i
		i += 1
	return -1


static func _resource_script_basename(res: Resource) -> String:
	if res == null:
		return ""
	var scr: Variant = res.get_script()
	if scr != null and scr is Script:
		var p := (scr as Script).resource_path
		if p != "":
			return p.get_file()
	return ""


static func maybe_wire(host: Node, rule: UiReactWireRule) -> void:
	if not effective_send_enabled():
		return
	_ensure_registered()
	var rel := scene_relative_paths(host)
	var sp := String(rel.get(&"scene_path", ""))
	if sp.is_empty():
		return
	var rp := String(rel.get(&"relpath", ""))
	var rid: String = rule.rule_id if rule.rule_id != "" else rule.resource_path
	var payload: Array = [
		sp,
		rp,
		wire_rule_index(host, rule),
		rid,
		_resource_script_basename(rule),
	]
	EngineDebugger.send_message(_Prot.MSG_V1_WIRE, payload)


static func maybe_cmp(computed: UiState, correlator_node: Node) -> void:
	if computed == null or not effective_send_enabled():
		return
	_ensure_registered()
	var rel := scene_relative_paths(correlator_node)
	var sp := String(rel.get(&"scene_path", ""))
	if sp.is_empty():
		return
	var res_path := String(computed.resource_path)
	var rp_corr := String(rel.get(&"relpath", ""))
	var payload: Array = [sp, res_path, computed.get_instance_id(), rp_corr]
	EngineDebugger.send_message(_Prot.MSG_V1_CMP, payload)


static func maybe_act(owner: Node, component_name: String, row_index: int, kind_label: String) -> void:
	if not effective_send_enabled():
		return
	_ensure_registered()
	var rel := scene_relative_paths(owner)
	var sp := String(rel.get(&"scene_path", ""))
	if sp.is_empty():
		return
	var rp := String(rel.get(&"relpath", ""))
	var payload: Array = [sp, rp, component_name, row_index, kind_label]
	EngineDebugger.send_message(_Prot.MSG_V1_ACT, payload)
