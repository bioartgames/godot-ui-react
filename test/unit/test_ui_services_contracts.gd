extends GutTest

## Service / helper contracts (TEST-016…018).


func before_each() -> void:
	UiReactComputedService.reset_internal_state_for_tests()


func after_each() -> void:
	UiReactComputedService.reset_internal_state_for_tests()


func test_computed_service_supports_and_wires() -> void:
	var src := UiBoolState.new(true)
	var computed := UiComputedBoolInvert.new()
	computed.sources = [src]
	var consumer := Node.new()
	add_child(consumer)
	assert_true(UiReactComputedService.supports_computed_wiring(computed))
	UiReactComputedService.ensure_wired(computed, consumer, &"checked_state")
	assert_true(UiReactComputedService.debug_is_wired_for_tests(computed))
	UiReactComputedService.release_wired(computed, consumer, &"checked_state")
	UiReactComputedService.reset_internal_state_for_tests()
	assert_true(UiReactComputedService.debug_static_tables_empty_for_tests())
	consumer.queue_free()


func test_computed_service_cycle_detection() -> void:
	var a := UiComputedBoolInvert.new()
	var b := UiComputedBoolInvert.new()
	a.sources = [b]
	b.sources = [a]
	assert_true(UiReactComputedService.sources_dependency_graph_has_cycle(a))


func test_computed_service_auto_recompute_on_source_change() -> void:
	var src := UiBoolState.new(false)
	var computed := UiComputedBoolInvert.new()
	computed.sources = [src]
	computed.recompute()
	assert_eq(computed.get_bool_value(), true)
	var consumer := Control.new()
	add_child(consumer)
	UiReactComputedService.ensure_wired(computed, consumer, &"checked_state")
	src.set_value(true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(computed.get_bool_value(), false)
	UiReactComputedService.release_wired(computed, consumer, &"checked_state")
	consumer.queue_free()


func test_wire_helper_dispatch_count() -> void:
	assert_eq(UiReactWireRuleHelper.debug_wire_bind_dispatch_count_for_tests(), 6)


func test_wire_helper_attach_detach_with_exported_rules() -> void:
	var bool_st := UiBoolState.new(true)
	var dest := UiStringState.new("")
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	rule.bool_state = bool_st
	rule.target_string_state = dest
	rule.line_prefix = "v="
	rule.run_apply_on_attach = true
	var host := _WireHost.new()
	host.wire_rules = [rule]
	add_child(host)
	await get_tree().process_frame
	UiReactWireRuleHelper.attach(host)
	assert_eq(dest.get_string_value(), "v=true")
	UiReactWireRuleHelper.detach(host)
	host.queue_free()


func test_transactional_session_apply_on_press() -> void:
	var st := UiTransactionalState.new(0)
	st.set_value(5)
	var group := UiTransactionalGroup.new()
	group.states = [st]
	var btn := Button.new()
	add_child(btn)
	await get_tree().process_frame
	UiReactTransactionalSession.register_host(
		btn, group, int(UiReactTransactionalSession.Role.APPLY_ALL), null
	)
	btn.pressed.emit()
	assert_eq(st.get_committed_value(), 5)
	UiReactTransactionalSession.unregister_host(btn)
	btn.queue_free()


class _WireHost:
	extends Control
	@export var wire_rules: Array[UiReactWireRule] = []
