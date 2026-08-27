extends GutTest

## Contract suite for shared UiState API (TEST-001…004).
## Uses concrete subclasses as public observers of the abstract contract.


func test_value_changed_emits_once_on_real_change() -> void:
	var st := UiBoolState.new(false)
	var seen: Array = []
	st.value_changed.connect(func(new_v: Variant, old_v: Variant) -> void:
		seen.append({"new": new_v, "old": old_v})
	)
	st.set_value(true)
	assert_eq(seen.size(), 1, "value_changed emits once on real change")
	assert_eq(seen[0]["new"], true)
	assert_eq(seen[0]["old"], false)


func test_value_changed_skips_when_set_value_equal() -> void:
	var st := UiBoolState.new(true)
	var count := [0]
	st.value_changed.connect(func(_n: Variant, _o: Variant) -> void:
		count[0] += 1
	)
	st.set_value(true)
	assert_eq(count[0], 0, "equal set_value must not emit value_changed")
	assert_eq(st.get_value(), true)


func test_get_value_returns_payload_after_set() -> void:
	var st := UiBoolState.new(false)
	st.set_value(true)
	assert_eq(st.get_value(), true)
	assert_eq(st.get_bool_value(), true)


func test_set_silent_updates_without_value_changed() -> void:
	var st := UiBoolState.new(false)
	var count := [0]
	st.value_changed.connect(func(_n: Variant, _o: Variant) -> void:
		count[0] += 1
	)
	st.set_silent(true)
	assert_eq(st.get_value(), true, "set_silent updates payload")
	assert_eq(count[0], 0, "set_silent must not emit value_changed")


func test_int_set_value_rejects_float_without_change() -> void:
	var st := UiIntState.new(3)
	var count := [0]
	st.value_changed.connect(func(_n: Variant, _o: Variant) -> void:
		count[0] += 1
	)
	st.set_value(1.5)
	assert_engine_error("float is not supported", "reject path warns")
	assert_eq(st.get_value(), 3, "float reject leaves prior int")
	assert_eq(count[0], 0, "float reject must not emit value_changed")


func test_shared_resource_instance_shares_payload() -> void:
	var shared := UiBoolState.new(false)
	var a: UiBoolState = shared
	var b: UiBoolState = shared
	a.set_value(true)
	assert_eq(b.get_value(), true, "same Resource instance shares payload")
	b.set_silent(false)
	assert_eq(a.get_value(), false)
