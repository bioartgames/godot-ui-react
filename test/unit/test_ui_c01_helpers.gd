extends GutTest

## Wave C-01: wire / scope / binding / ops helpers (TEST-019…022).


func before_each() -> void:
	UiReactComputedService.reset_internal_state_for_tests()


func after_each() -> void:
	UiReactComputedService.reset_internal_state_for_tests()


func test_control_state_wire_bind_initial_and_unbind() -> void:
	var owner := Node.new()
	add_child(owner)
	var st := UiBoolState.new(false)
	var seen: Array = []
	var cb := func(n: Variant, o: Variant) -> void:
		seen.append({"new": n, "old": o})
	UiReactControlStateWire.bind_value_changed(owner, st, &"checked_state", cb, false)
	assert_eq(seen.size(), 1, "bind calls on_changed once with current value")
	assert_eq(seen[0]["new"], false)
	st.set_value(true)
	assert_eq(seen.size(), 2)
	UiReactControlStateWire.unbind_value_changed(owner, st, &"checked_state", cb, false)
	st.set_value(false)
	assert_eq(seen.size(), 2, "unbind stops further callbacks")
	owner.queue_free()


func test_subscription_scope_dedupe_and_dispose() -> void:
	var btn := Button.new()
	add_child(btn)
	var scope := UiReactSubscriptionScope.new()
	var count := [0]
	var cb := func() -> void:
		count[0] += 1
	scope.connect_bound(btn.pressed, cb)
	scope.connect_bound(btn.pressed, cb)
	assert_eq(scope.debug_tracked_count_for_tests(), 1)
	btn.pressed.emit()
	assert_eq(count[0], 1)
	scope.dispose()
	assert_true(scope.is_disposed())
	assert_eq(scope.debug_tracked_count_for_tests(), 0)
	btn.pressed.emit()
	assert_eq(count[0], 1)
	scope.dispose()
	btn.queue_free()


func test_binding_helper_coerce_and_expect_array() -> void:
	assert_eq(UiReactStateBindingHelper.coerce_bool(null), false)
	assert_eq(UiReactStateBindingHelper.coerce_bool(1), true)
	assert_eq(UiReactStateBindingHelper.coerce_bool(""), false)
	assert_eq(UiReactStateBindingHelper.coerce_float(null, 7.5), 7.5)
	assert_true(UiReactStateBindingHelper.approx_equal_float(1.0, 1.0 + 1e-10))
	var arr: Array = [1, 2]
	assert_eq(UiReactStateBindingHelper.expect_array_state("T", "n", "f", arr), arr)
	var bad: Variant = UiReactStateBindingHelper.expect_array_state("T", "n", "f", "nope")
	assert_engine_error("must be an Array", "non-array warns")
	assert_eq(bad, null)


func test_state_op_afford_subtract_transfer() -> void:
	var gold := UiFloatState.new(100.0)
	var price := UiFloatState.new(10.0)
	var qty := UiFloatState.new(5.0)
	assert_true(UiReactStateOpService.afford_floats(gold, price, qty))
	UiReactStateOpService.subtract_product_from_accumulator(gold, price, qty)
	assert_eq(gold.get_float_value(), 50.0)
	var poor := UiFloatState.new(40.0)
	UiReactStateOpService.subtract_product_from_accumulator(poor, price, qty)
	assert_eq(poor.get_float_value(), 40.0, "insufficient gold is no-op")
	var from_s := UiFloatState.new(30.0)
	var to_s := UiFloatState.new(0.0)
	var fa := UiFloatState.new(10.0)
	var fb := UiFloatState.new(5.0)
	UiReactStateOpService.transfer_float_product_clamped(from_s, to_s, fa, fb)
	assert_eq(from_s.get_float_value(), 0.0)
	assert_eq(to_s.get_float_value(), 30.0)
