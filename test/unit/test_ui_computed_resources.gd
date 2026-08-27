extends GutTest

## Computed resource contracts (TEST-012…013).


func test_bool_invert_empty_sources_is_true() -> void:
	var c := UiComputedBoolInvert.new()
	c.sources = []
	c.recompute()
	assert_eq(c.get_bool_value(), true)


func test_bool_invert_recompute_from_source() -> void:
	var src := UiBoolState.new(true)
	var c := UiComputedBoolInvert.new()
	c.sources = [src]
	c.recompute()
	assert_eq(c.get_bool_value(), false)
	src.set_value(false)
	c.recompute()
	assert_eq(c.get_bool_value(), true)


func test_bool_invert_recompute_emits_when_changed() -> void:
	var src := UiBoolState.new(false)
	var c := UiComputedBoolInvert.new()
	c.sources = [src]
	c.recompute()
	var count := [0]
	c.value_changed.connect(func(_n: Variant, _o: Variant) -> void:
		count[0] += 1
	)
	src.set_value(true)
	c.recompute()
	assert_eq(count[0], 1)
	c.recompute()
	assert_eq(count[0], 1, "equal recompute must not emit")


func test_order_summary_string_recompute() -> void:
	var gold := UiFloatState.new(10.0)
	var price := UiFloatState.new(3.0)
	var qty := UiFloatState.new(2.0)
	var c := UiComputedOrderSummaryThreeFloatString.new()
	c.sources = [gold, price, qty]
	c.recompute()
	var text := c.get_string_value()
	assert_true(text.contains("Can afford"), "affordable order should say Can afford")
	assert_true(text.contains("6.00") or text.contains("6"), "total should reflect price*qty")
