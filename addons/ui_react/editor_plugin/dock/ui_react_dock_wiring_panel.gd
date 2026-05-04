extends MarginContainer
class_name UiReactDockWiringPanel

const _ExplainPanelScript := preload("res://addons/ui_react/editor_plugin/dock/ui_react_dock_explain_panel.gd")

## Matches [member UiReactDockExplainPanel] outer margins so the footer lines up with the graph column.
const _FOOTER_MARGIN_PX := 8

const _TT_EDITOR_PLAY_MODE_CONTROL := (
	"Choose how Ui React behaves while you play from the editor (debug build, active debugger). "
	+ "Open the list and hover an item for that mode. Runtime gates apply on the next run after you change mode."
)

const _TT_EDITOR_PLAY_OFF := "No Output trace and no live graph pulses while playing from the editor."

const _TT_EDITOR_PLAY_OUTPUT := (
	"Mirror WIRE, CMP, and ACT activity to the Godot Output panel. Requires debug build, Play from Editor, and a debugger session."
)

const _TT_EDITOR_PLAY_GRAPH := (
	"Pulse highlights on the dependency graph when the live graph matches the saved scene scope."
)

const _TT_EDITOR_PLAY_GRAPH_FOLLOW := (
	"Live graph, plus move Local scene selection toward pulse hosts and rebuild graph scope; pans to the first pulsed node. "
	+ "Does not use the Remote Scene tree."
)

const _TT_EDITOR_PLAY_OUTPUT_GRAPH := "Output trace and live graph (non-follow) combined."

const _TT_EDITOR_PLAY_OUTPUT_GRAPH_FOLLOW := "Output trace plus live graph with follow behavior."

var _plugin: EditorPlugin
var _actions: UiReactActionController

var _opt_editor_play_mode: OptionButton
var _suppress_editor_play_signals: bool = false

## [UiReactDockExplainPanel]
var _explain: Variant = null


func setup(plugin: EditorPlugin, actions: UiReactActionController, request_dock_refresh: Callable = Callable()) -> void:
	_plugin = plugin
	_actions = actions
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override(&"margin_left", 0)
	add_theme_constant_override(&"margin_right", 0)
	add_theme_constant_override(&"margin_top", 0)
	add_theme_constant_override(&"margin_bottom", 0)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var ex := _ExplainPanelScript.new()
	ex.callv(&"setup", [_plugin, _actions, request_dock_refresh])
	_explain = ex
	ex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(ex)

	var footer_wrap := MarginContainer.new()
	footer_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	footer_wrap.add_theme_constant_override(&"margin_left", _FOOTER_MARGIN_PX)
	footer_wrap.add_theme_constant_override(&"margin_right", _FOOTER_MARGIN_PX)
	footer_wrap.add_theme_constant_override(&"margin_bottom", _FOOTER_MARGIN_PX)

	var footer := HBoxContainer.new()
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.tooltip_text = _TT_EDITOR_PLAY_MODE_CONTROL
	opt.add_item("Off", UiReactDockConfig.EDITOR_PLAY_MODE_OFF)
	opt.add_item("Output trace", UiReactDockConfig.EDITOR_PLAY_MODE_OUTPUT)
	opt.add_item("Live graph", UiReactDockConfig.EDITOR_PLAY_MODE_GRAPH)
	opt.add_item("Live graph (follow)", UiReactDockConfig.EDITOR_PLAY_MODE_GRAPH_FOLLOW)
	opt.add_item("Output + graph", UiReactDockConfig.EDITOR_PLAY_MODE_OUTPUT_GRAPH)
	opt.add_item("Output + graph (follow)", UiReactDockConfig.EDITOR_PLAY_MODE_OUTPUT_GRAPH_FOLLOW)
	opt.set_item_tooltip(0, _TT_EDITOR_PLAY_OFF)
	opt.set_item_tooltip(1, _TT_EDITOR_PLAY_OUTPUT)
	opt.set_item_tooltip(2, _TT_EDITOR_PLAY_GRAPH)
	opt.set_item_tooltip(3, _TT_EDITOR_PLAY_GRAPH_FOLLOW)
	opt.set_item_tooltip(4, _TT_EDITOR_PLAY_OUTPUT_GRAPH)
	opt.set_item_tooltip(5, _TT_EDITOR_PLAY_OUTPUT_GRAPH_FOLLOW)
	opt.item_selected.connect(_on_editor_play_mode_selected)
	_opt_editor_play_mode = opt

	_restore_editor_play_mode_option_select()

	footer.add_child(opt)
	footer_wrap.add_child(footer)
	root.add_child(footer_wrap)

	add_child(root)


func _restore_editor_play_mode_option_select() -> void:
	if _opt_editor_play_mode == null:
		return
	var mode := UiReactDockConfig.clamp_editor_play_mode(
		int(ProjectSettings.get_setting(UiReactDockConfig.KEY_EDITOR_PLAY_MODE, UiReactDockConfig.DEF_EDITOR_PLAY_MODE))
	)
	_suppress_editor_play_signals = true
	for i in range(_opt_editor_play_mode.get_item_count()):
		if _opt_editor_play_mode.get_item_id(i) == mode:
			_opt_editor_play_mode.select(i)
			_suppress_editor_play_signals = false
			return
	_opt_editor_play_mode.select(0)
	_suppress_editor_play_signals = false


func _on_editor_play_mode_selected(index: int) -> void:
	if _suppress_editor_play_signals or _opt_editor_play_mode == null:
		return
	var mode := UiReactDockConfig.clamp_editor_play_mode(_opt_editor_play_mode.get_item_id(index))
	UiReactDockConfig.save_editor_play_mode(mode)


func ingest_live_graph_debug_message(message: String, data: Variant) -> void:
	if _explain != null and _explain.has_method(&"ingest_live_graph_debug_message"):
		_explain.call(&"ingest_live_graph_debug_message", message, data)


func refresh() -> void:
	if _explain != null and _explain.has_method(&"refresh"):
		_explain.call(&"refresh")


func capture_session_for_persist() -> void:
	if _explain != null and _explain.has_method(&"capture_wiring_session_for_persist"):
		_explain.call(&"capture_wiring_session_for_persist")


func restore_session_from_settings() -> bool:
	var got := false
	if _explain != null and _explain.has_method(&"restore_wiring_session_from_project_settings"):
		got = (_explain.call(&"restore_wiring_session_from_project_settings") as bool)
	if _opt_editor_play_mode != null:
		_restore_editor_play_mode_option_select()
	return got
