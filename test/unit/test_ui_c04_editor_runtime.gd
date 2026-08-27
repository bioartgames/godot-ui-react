extends GutTest

## Wave C-04: validators + runtime debug (TEST-027…029).


func after_each() -> void:
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(false)
	UiReactRuntimeConsoleDebug.clear_test_capture()
	UiReactLiveGraphTransport.reset_capture_registration_for_tests()


func test_anim_validator_flags_empty_target() -> void:
	var host := UiReactButton.new()
	add_child(host)
	await get_tree().process_frame
	var bad := UiAnimTarget.new()
	bad.target = NodePath("")
	bad.trigger = UiAnimTarget.Trigger.PRESSED
	host.animation_targets = [bad]
	var issues: Array = UiReactAnimValidator.validate_anim_targets("UiReactButton", host, NodePath("."))
	assert_gt(issues.size(), 0, "empty anim target should produce diagnostic")
	host.queue_free()


func test_runtime_console_force_capture() -> void:
	UiReactRuntimeConsoleDebug.clear_test_capture()
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(true)
	assert_true(UiReactRuntimeConsoleDebug.effective_enabled())
	var computed := UiComputedBoolInvert.new()
	UiReactRuntimeConsoleDebug.maybe_computed_recompute(computed)
	var snap: Array[String] = UiReactRuntimeConsoleDebug.get_test_capture_snapshot()
	assert_eq(snap.size(), 1)
	assert_true(snap[0].contains("[UiReact:d]"))
	assert_true(snap[0].contains("CMP"))
	UiReactRuntimeConsoleDebug.set_force_enabled_for_tests(false)
	UiReactRuntimeConsoleDebug.clear_test_capture()
	UiReactRuntimeConsoleDebug.maybe_computed_recompute(computed)
	assert_eq(UiReactRuntimeConsoleDebug.get_test_capture_snapshot().size(), 0)


func test_live_graph_transport_maybe_noop_headless() -> void:
	UiReactLiveGraphTransport.reset_capture_registration_for_tests()
	var host := Control.new()
	add_child(host)
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	# Headless: no debugger — must not crash.
	UiReactLiveGraphTransport.maybe_wire(host, rule)
	UiReactLiveGraphTransport.maybe_act(host, "UiReactButton", 0, "test")
	assert_false(UiReactLiveGraphTransport.effective_send_enabled())
	host.queue_free()
