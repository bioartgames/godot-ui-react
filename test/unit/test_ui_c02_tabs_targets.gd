extends GutTest

## Wave C-02: tab sync + validated target helpers (TEST-023…024).


func test_tab_collection_sync_applies_titles_and_resizes_cfg() -> void:
	var tabs := TabContainer.new()
	add_child(tabs)
	var cfg := UiTabContainerCfg.new()
	cfg.tab_content_states = []
	UiTabCollectionSync.apply_tabs_from_array(tabs, ["Alpha", "Beta"], cfg)
	assert_eq(tabs.get_tab_count(), 2)
	assert_eq(tabs.get_tab_title(0), "Alpha")
	assert_eq(tabs.get_tab_title(1), "Beta")
	assert_gte(cfg.tab_content_states.size(), 2)
	UiTabCollectionSync.apply_tabs_from_array(tabs, ["Only"], cfg)
	assert_eq(tabs.get_tab_count(), 1)
	tabs.queue_free()


func test_tab_selection_resolve_by_title() -> void:
	var tabs := TabContainer.new()
	add_child(tabs)
	UiTabCollectionSync.apply_tabs_from_array(tabs, ["A", "B"], null)
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, "B"), 1)
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, "Z"), -1)
	assert_eq(UiTabSelectionBinding.resolve_tab_index(tabs, 0), 0)
	tabs.queue_free()


func test_apply_validated_targets_does_not_rewrite_export() -> void:
	var typed := _AnimHost.new()
	var child := Control.new()
	child.name = "AnimChild"
	add_child(typed)
	typed.add_child(child)
	await get_tree().process_frame
	var good := UiAnimTarget.new()
	good.target = NodePath("AnimChild")
	good.trigger = UiAnimTarget.Trigger.PRESSED
	good.animation = UiAnimTarget.AnimationAction.FADE_IN
	good.duration = 0.05
	var bad := UiAnimTarget.new()
	bad.target = NodePath("")
	bad.trigger = UiAnimTarget.Trigger.PRESSED
	typed.animation_targets = [good, bad]
	var export_before: int = typed.animation_targets.size()
	var map: Dictionary = UiReactAnimTargetHelper.apply_validated_targets(typed, "TestHost")
	assert_engine_error("no Target NodePath", "invalid row warns at validate")
	assert_eq(typed.animation_targets.size(), export_before, "export must not shrink")
	var runtime: Array[UiAnimTarget] = UiReactAnimTargetHelper.get_runtime_animation_targets(typed)
	assert_eq(runtime.size(), 1, "runtime keeps only valid row")
	assert_true(map.has(UiAnimTarget.Trigger.PRESSED))
	typed.queue_free()


class _AnimHost:
	extends Control
	@export var animation_targets: Array[UiAnimTarget] = []
