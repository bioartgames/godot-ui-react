## Dock quick-edit strip for descriptor-allowlisted [code]wire_rules[/code] fields (CB-058 Milestone 2).
class_name UiReactDockWireRuleShallowEditor
extends VBoxContainer

const _FIELD_KIND_STRING := &"string"
const _FIELD_KIND_BOOL := &"bool"

## Fixed label column width so long [code]display_label[/code] strings wrap instead of shifting controls.
const _FORM_LABEL_COL_W := 200

var _actions: UiReactActionController
var _after_wire_mutated: Callable = Callable()

var _host: Control = null
var _rule_index: int = -1
var _rule_class_name: StringName = &""

var _rule_id_edit: LineEdit
var _rule_grid: GridContainer
var _fields_host: VBoxContainer
var _fields_grid: GridContainer
var _empty_hint_lbl: Label

var _field_string_edits: Dictionary = {}
var _field_bool_checks: Dictionary = {}
var _syncing := false

var _panel_signal_lifecycle: UiReactEditorSignalLifecycle
var _descriptor_rows_scope: UiReactSubscriptionScope


func setup(
	actions: UiReactActionController,
	after_wire_mutated: Callable = Callable(),
) -> void:
	_actions = actions
	_after_wire_mutated = after_wire_mutated
	if _panel_signal_lifecycle == null:
		_panel_signal_lifecycle = UiReactEditorSignalLifecycle.new(self)
		_build_ui()


func clear() -> void:
	if _descriptor_rows_scope != null:
		_descriptor_rows_scope.dispose()
		_descriptor_rows_scope = null
	_host = null
	_rule_index = -1
	_rule_class_name = &""
	visible = false
	_syncing = true
	if _rule_id_edit != null:
		_rule_id_edit.text = ""
	_syncing = false
	_field_string_edits.clear()
	_field_bool_checks.clear()
	_rebuild_descriptor_rows([])


func set_context(host: Control, _root: Node, rule_index: int) -> void:
	_host = host
	_rule_index = rule_index
	if host == null or rule_index < 0:
		clear()
		return
	var wr: Variant = host.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if rule_index < 0 or rule_index >= arr.size():
		clear()
		return
	var item: Variant = arr[rule_index]
	if item == null or not (item is UiReactWireRule):
		clear()
		return
	var rule := item as UiReactWireRule
	var gname := UiReactWireGraphEditService._rule_script_class_name(rule)
	_rule_class_name = gname
	visible = true
	_syncing = true
	_rule_id_edit.text = rule.rule_id
	_syncing = false
	var descriptors: Array = UiReactWireGraphEditService.shallow_field_descriptors_for_rule(rule)
	_rebuild_descriptor_rows(descriptors)
	_sync_descriptor_values(rule, descriptors)


func _build_ui() -> void:
	if _rule_id_edit != null:
		return
	add_theme_constant_override(&"separation", 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visible = false

	_rule_grid = GridContainer.new()
	_rule_grid.columns = 2
	_rule_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rule_grid.add_theme_constant_override(&"h_separation", 6)
	_rule_grid.add_theme_constant_override(&"v_separation", 4)
	var rid_tt := (
		"Identifier for this rule. Graph edges reference it; keep it unique and avoid renaming "
		+ "unless you update wiring that points at it."
	)
	_rule_grid.add_child(_make_form_label_cell("Rule id", rid_tt))
	_rule_id_edit = LineEdit.new()
	_rule_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rule_id_edit.placeholder_text = "Rule id"
	_rule_id_edit.tooltip_text = rid_tt
	_panel_signal_lifecycle.scope.connect_bound(_rule_id_edit.focus_exited, _commit_rule_id_if_needed)
	_panel_signal_lifecycle.scope.connect_bound(
		_rule_id_edit.text_submitted,
		func(_s: String) -> void: _commit_rule_id_if_needed()
	)
	_rule_grid.add_child(_rule_id_edit)
	add_child(_rule_grid)

	var sep := HSeparator.new()
	add_child(sep)

	_fields_host = VBoxContainer.new()
	_fields_host.add_theme_constant_override(&"separation", 4)
	_fields_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_fields_host)

	_fields_grid = GridContainer.new()
	_fields_grid.columns = 2
	_fields_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_grid.add_theme_constant_override(&"h_separation", 6)
	_fields_grid.add_theme_constant_override(&"v_separation", 4)
	# Parented from [_rebuild_descriptor_rows] when the rule exposes shallow fields.

	_empty_hint_lbl = Label.new()
	_empty_hint_lbl.text = "Edit in Inspector for this rule type."
	_empty_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_hint_lbl.modulate = Color(1, 1, 1, 0.75)
	_fields_host.add_child(_empty_hint_lbl)


func _rebuild_descriptor_rows(descriptors: Array) -> void:
	if _fields_host == null or _fields_grid == null:
		return
	if _descriptor_rows_scope != null:
		_descriptor_rows_scope.dispose()
	_descriptor_rows_scope = UiReactSubscriptionScope.new()
	for i: int in range(_fields_grid.get_child_count() - 1, -1, -1):
		_fields_grid.get_child(i).queue_free()
	if _empty_hint_lbl != null and is_instance_valid(_empty_hint_lbl):
		_empty_hint_lbl.queue_free()
		_empty_hint_lbl = null
	if _fields_grid.get_parent() == _fields_host:
		_fields_host.remove_child(_fields_grid)
	_field_string_edits.clear()
	_field_bool_checks.clear()
	if descriptors.is_empty():
		if _descriptor_rows_scope != null:
			_descriptor_rows_scope.dispose()
			_descriptor_rows_scope = null
		_empty_hint_lbl = Label.new()
		_empty_hint_lbl.text = "Edit in Inspector for this rule type."
		_empty_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_empty_hint_lbl.modulate = Color(1, 1, 1, 0.75)
		_fields_host.add_child(_empty_hint_lbl)
		return
	_empty_hint_lbl = null
	_fields_host.add_child(_fields_grid)
	for desc: Dictionary in descriptors:
		var kind := String(desc.get(&"kind", "")).strip_edges()
		var prop_v: Variant = desc.get(&"prop", &"")
		var prop: StringName = prop_v if prop_v is StringName else StringName(str(prop_v))
		if prop == &"":
			continue
		if kind == _FIELD_KIND_STRING:
			_add_string_field_row(desc, prop)
		elif kind == _FIELD_KIND_BOOL:
			_add_bool_field_row(desc, prop)


func _desc_display_label(desc: Dictionary) -> String:
	var dl: Variant = desc.get(&"display_label", "")
	if dl is String and not (dl as String).is_empty():
		return dl as String
	var lb: Variant = desc.get(&"label", "")
	if lb is String and not (lb as String).is_empty():
		return lb as String
	var pv: Variant = desc.get(&"prop", &"")
	return str(pv)


func _desc_designer_help(desc: Dictionary) -> String:
	var dh: Variant = desc.get(&"designer_help", "")
	if dh is String and not (dh as String).strip_edges().is_empty():
		return (dh as String).strip_edges()
	var hp: Variant = desc.get(&"help", "")
	if hp is String:
		return (hp as String).strip_edges()
	return ""


func _make_form_label_cell(text: String, tooltip_text: String = "") -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(_FORM_LABEL_COL_W, 0)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if not tooltip_text.is_empty():
		lbl.tooltip_text = tooltip_text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 0
	lbl.offset_top = 0
	lbl.offset_right = 0
	lbl.offset_bottom = 0
	holder.add_child(lbl)
	return holder


func _make_bool_row_spacer() -> Control:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(_FORM_LABEL_COL_W, 0)
	sp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sp


func _add_string_field_row(desc: Dictionary, prop: StringName) -> void:
	var help := _desc_designer_help(desc)
	var lbl_cell := _make_form_label_cell(_desc_display_label(desc), help)
	_fields_grid.add_child(lbl_cell)
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not help.is_empty():
		edit.tooltip_text = help
		var short := help
		if short.length() > 96:
			short = short.substr(0, 93) + "…"
		edit.placeholder_text = short
	_descriptor_rows_scope.connect_bound(
		edit.focus_exited,
		func() -> void: _commit_shallow_string_if_needed(prop, edit)
	)
	_descriptor_rows_scope.connect_bound(
		edit.text_submitted,
		func(_s: String) -> void: _commit_shallow_string_if_needed(prop, edit)
	)
	_fields_grid.add_child(edit)
	_field_string_edits[prop] = edit


func _add_bool_field_row(desc: Dictionary, prop: StringName) -> void:
	_fields_grid.add_child(_make_bool_row_spacer())
	var cb := CheckBox.new()
	cb.text = _desc_display_label(desc)
	cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var help := _desc_designer_help(desc)
	if not help.is_empty():
		cb.tooltip_text = help
	_descriptor_rows_scope.connect_bound(
		cb.toggled,
		func(on: bool) -> void: _on_descriptor_bool_toggled(prop, on, cb)
	)
	_fields_grid.add_child(cb)
	_field_bool_checks[prop] = cb


func _get_rule_at_index() -> UiReactWireRule:
	if _host == null or _rule_index < 0:
		return null
	var wr: Variant = _host.get(&"wire_rules")
	var arr: Array = wr as Array if wr is Array else []
	if _rule_index >= arr.size():
		return null
	var item: Variant = arr[_rule_index]
	return item as UiReactWireRule if item is UiReactWireRule else null


func _sync_descriptor_values(rule: UiReactWireRule, descriptors: Array) -> void:
	_syncing = true
	for desc: Dictionary in descriptors:
		var prop_v: Variant = desc.get(&"prop", &"")
		var prop: StringName = prop_v if prop_v is StringName else StringName(str(prop_v))
		if prop == &"" or not prop in rule:
			continue
		var kind := String(desc.get(&"kind", "")).strip_edges()
		if kind == _FIELD_KIND_STRING and _field_string_edits.has(prop):
			var edit: LineEdit = _field_string_edits[prop] as LineEdit
			if edit != null:
				edit.text = str(rule.get(prop))
		elif kind == _FIELD_KIND_BOOL and _field_bool_checks.has(prop):
			var cb: CheckBox = _field_bool_checks[prop] as CheckBox
			if cb != null:
				cb.set_block_signals(true)
				cb.button_pressed = bool(rule.get(prop))
				cb.set_block_signals(false)
	_syncing = false


func _notify_mutated() -> void:
	if _after_wire_mutated.is_valid():
		_after_wire_mutated.call()


func _resync_rule_id_edit() -> void:
	var rule := _get_rule_at_index()
	if rule == null or _rule_id_edit == null:
		return
	_syncing = true
	_rule_id_edit.text = rule.rule_id
	_syncing = false


func _resync_string_edit_from_rule(prop: StringName, edit: LineEdit) -> void:
	var rule := _get_rule_at_index()
	if rule == null or edit == null or not prop in rule:
		return
	_syncing = true
	edit.text = str(rule.get(prop))
	_syncing = false


func _commit_rule_id_if_needed() -> void:
	if _syncing or _host == null or _actions == null or _rule_index < 0 or _rule_id_edit == null:
		return
	var rule := _get_rule_at_index()
	if rule == null:
		return
	var trimmed := _rule_id_edit.text.strip_edges()
	if trimmed.is_empty():
		_resync_rule_id_edit()
		return
	if trimmed == rule.rule_id:
		_syncing = true
		_rule_id_edit.text = rule.rule_id
		_syncing = false
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_id(
		_host, _rule_index, _rule_id_edit.text, _actions
	):
		_resync_rule_id_edit()
		return
	_notify_mutated()


func _commit_shallow_string_if_needed(prop: StringName, edit: LineEdit) -> void:
	if _syncing or _host == null or _actions == null or _rule_index < 0 or _rule_class_name == &"" or edit == null:
		return
	var rule := _get_rule_at_index()
	if rule == null or not prop in rule:
		return
	var t := edit.text.strip_edges()
	if t == str(rule.get(prop)).strip_edges():
		_syncing = true
		edit.text = str(rule.get(prop))
		_syncing = false
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_shallow_field(
		_host,
		_rule_index,
		_rule_class_name,
		prop,
		edit.text,
		_actions
	):
		_resync_string_edit_from_rule(prop, edit)
		return
	_notify_mutated()


func _on_descriptor_bool_toggled(prop: StringName, on: bool, cb: CheckBox) -> void:
	if _syncing or _host == null or _actions == null or _rule_index < 0 or _rule_class_name == &"":
		return
	if not UiReactWireGraphEditService.try_commit_wire_rule_shallow_field(
		_host,
		_rule_index,
		_rule_class_name,
		prop,
		on,
		_actions
	):
		if cb != null:
			_syncing = true
			cb.set_block_signals(true)
			cb.button_pressed = not on
			cb.set_block_signals(false)
			_syncing = false
		return
	_notify_mutated()
