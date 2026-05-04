## Pure helpers: correlate debugger payloads → graph **draw edge** indices and node ids (**CB-018** live pulses).
class_name UiReactDockLiveGraphController
extends RefCounted


static func _candidate_valid_for_follow(root: Node, candidate: String) -> bool:
	if root == null or candidate.is_empty():
		return false
	if not root.has_node(NodePath(candidate)):
		return false
	var node: Node = root.get_node(NodePath(candidate))
	if not (node is Control):
		return false
	if not UiReactScannerService.is_react_node(node as Control):
		return false
	return node == root or root.is_ancestor_of(node)


## From a path under [param root] (edited scene root), walk up to the nearest [UiReactScannerService] react [Control] scope (same rules as follow targets).
static func first_react_scope_relpath_under_root(root: Node, start_relpath: String) -> String:
	var s := start_relpath.strip_edges()
	if root == null or s.is_empty():
		return ""
	if not root.has_node(NodePath(s)):
		return ""
	var node: Node = root.get_node(NodePath(s))
	var cur: Node = node
	while cur != null:
		if cur is Control:
			var rp := str(root.get_path_to(cur))
			if _candidate_valid_for_follow(root, rp):
				return rp
		if cur == root:
			break
		cur = cur.get_parent()
	return ""


static func scope_host_path_for_computed_node_id(
	snap: UiReactExplainGraphSnapshot, computed_node_id: String
) -> String:
	if snap == null or computed_node_id.is_empty():
		return ""
	var k_cmp := int(UiReactExplainGraphSnapshot.EdgeKind.COMPUTED_SOURCE)
	for raw: Variant in snap.edges:
		if raw is not Dictionary:
			continue
		var ed: Dictionary = raw as Dictionary
		if int(ed.get(&"kind", -1)) != k_cmp:
			continue
		if str(ed.get(&"to_id", "")) != computed_node_id:
			continue
		var hp := str(ed.get(&"host_path", "")).strip_edges()
		if not hp.is_empty():
			return hp
	return ""


## First FIFO [UiReactLiveGraphProtocol] payload that yields a valid react scope under [param root] (no prior graph snapshot). [br]
## [code]CMP[/code] uses optional 4th element: correlator relpath from [method UiReactLiveGraphTransport.maybe_cmp].
static func bootstrap_scope_host_path_from_batch(batch: Array, scene_path: String, root: Node) -> String:
	var sp := scene_path.strip_edges()
	if sp.is_empty():
		return ""
	for item: Variant in batch:
		if item is not Dictionary:
			continue
		var w: Dictionary = item as Dictionary
		var msg := String(w.get(&"m", ""))
		var plv: Variant = w.get(&"p", [])
		if plv is not Array:
			continue
		var tpl: Array = plv as Array
		if tpl.is_empty():
			continue
		if String(tpl[0]) != sp:
			continue
		var start := ""
		match msg:
			UiReactLiveGraphProtocol.MSG_V1_WIRE:
				if tpl.size() < 5:
					continue
				start = String(tpl[1]).strip_edges()
			UiReactLiveGraphProtocol.MSG_V1_ACT:
				if tpl.size() < 5:
					continue
				start = String(tpl[1]).strip_edges()
			UiReactLiveGraphProtocol.MSG_V1_CMP:
				if tpl.size() < 4:
					continue
				start = String(tpl[3]).strip_edges()
			_:
				continue
		var cand := first_react_scope_relpath_under_root(root, start)
		if not cand.is_empty():
			return cand
	return ""


## First FIFO payload that yields a different, valid host scope under [param root].
static func follow_scope_host_path_from_batch(
	snap: UiReactExplainGraphSnapshot,
	batch: Array,
	scene_path: String,
	current_focus_host_path: String,
	root: Node,
) -> String:
	var sp := scene_path.strip_edges()
	var curf := current_focus_host_path.strip_edges()
	if sp.is_empty():
		return ""
	for item: Variant in batch:
		if item is not Dictionary:
			continue
		var w: Dictionary = item as Dictionary
		var msg := String(w.get(&"m", ""))
		var plv: Variant = w.get(&"p", [])
		if plv is not Array:
			continue
		var tpl: Array = plv as Array
		if tpl.is_empty():
			continue
		if String(tpl[0]) != sp:
			continue
		var cand := ""
		match msg:
			UiReactLiveGraphProtocol.MSG_V1_WIRE:
				if tpl.size() < 5:
					continue
				cand = String(tpl[1]).strip_edges()
			UiReactLiveGraphProtocol.MSG_V1_ACT:
				if tpl.size() < 5:
					continue
				cand = String(tpl[1]).strip_edges()
			UiReactLiveGraphProtocol.MSG_V1_CMP:
				if tpl.size() < 3:
					continue
				if snap == null:
					continue
				var nid := resolve_computed_node_id(snap.nodes, String(tpl[1]), int(tpl[2]))
				if nid.is_empty():
					continue
				cand = scope_host_path_for_computed_node_id(snap, nid).strip_edges()
			_:
				continue
		if cand.is_empty() or cand == curf:
			continue
		if _candidate_valid_for_follow(root, cand):
			return cand
	return ""


static func descendant_or_equal_event_to_focus(event_relpath: String, focus_relpath: String) -> bool:
	var ef := focus_relpath.strip_edges()
	if ef.is_empty():
		return true
	var ev := event_relpath.strip_edges()
	return ev == ef or ev.begins_with(ef + "/")


static func edge_draw_indices_wire(
	draw_edges: Array, edge_kind_wire: int, host_relpath: String, rule_index: int
) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in range(draw_edges.size()):
		var raw: Variant = draw_edges[i]
		if raw is not Dictionary:
			continue
		var d: Dictionary = raw as Dictionary
		if int(d.get(&"kind", -999)) != edge_kind_wire:
			continue
		if str(d.get(&"wire_host_path", "")) != host_relpath:
			continue
		if int(d.get(&"wire_rule_index", -2)) != rule_index:
			continue
		out.append(i)
	return out


static func resolve_computed_node_id(snapshot_nodes: Array, resource_path_str: String, iid: int) -> String:
	var rp := resource_path_str.strip_edges()
	if not rp.is_empty():
		var candidate := "state:%s" % rp
		for it: Variant in snapshot_nodes:
			if it is not Dictionary:
				continue
			var nid := str((it as Dictionary).get(&"id", ""))
			if nid == candidate:
				return candidate
	elif iid != 0:
		var suf := "#%d" % iid
		for it2: Variant in snapshot_nodes:
			if it2 is not Dictionary:
				continue
			var nid2 := str((it2 as Dictionary).get(&"id", ""))
			if nid2.ends_with(suf):
				return nid2
	return ""
