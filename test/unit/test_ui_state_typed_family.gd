extends GutTest

## Typed UiState family contracts (TEST-005…009).
## Complements test_ui_state_contracts.gd — does not re-assert base emit-on-change for bool.


# --- TEST-005 UiBoolState ---

func test_bool_set_value_coerces_and_typed_get() -> void:
	var st := UiBoolState.new(false)
	st.set_value(1)
	assert_eq(st.get_value(), true)
	assert_eq(st.get_bool_value(), true)
	st.set_value(0)
	assert_eq(st.get_bool_value(), false)


# --- TEST-006 UiIntState ---

func test_int_null_sets_zero_and_emits() -> void:
	var st := UiIntState.new(5)
	var seen: Array = []
	st.value_changed.connect(func(new_v: Variant, old_v: Variant) -> void:
		seen.append({"new": new_v, "old": old_v})
	)
	st.set_value(null)
	assert_eq(st.get_value(), 0)
	assert_eq(st.get_int_value(), 0)
	assert_eq(seen.size(), 1)
	assert_eq(seen[0]["new"], 0)
	assert_eq(seen[0]["old"], 5)


func test_int_set_silent_rejects_float() -> void:
	var st := UiIntState.new(2)
	st.set_silent(3.14)
	assert_engine_error("float is not supported", "set_silent float reject warns")
	assert_eq(st.get_int_value(), 2)


func test_int_set_int_value_updates() -> void:
	var st := UiIntState.new(0)
	st.set_int_value(9)
	assert_eq(st.get_int_value(), 9)


# --- TEST-007 UiFloatState ---

func test_float_null_sets_zero() -> void:
	var st := UiFloatState.new(1.5)
	st.set_value(null)
	assert_eq(st.get_float_value(), 0.0)


func test_float_approx_equal_skips_value_changed() -> void:
	var st := UiFloatState.new(1.0)
	var count := [0]
	st.value_changed.connect(func(_n: Variant, _o: Variant) -> void:
		count[0] += 1
	)
	st.set_value(1.0 + 1e-10)
	assert_eq(count[0], 0, "is_equal_approx skip must not emit")
	st.set_value(2.0)
	assert_eq(count[0], 1)
	assert_eq(st.get_float_value(), 2.0)


# --- TEST-008 UiStringState ---

func test_string_null_clears_to_empty() -> void:
	var st := UiStringState.new("hi")
	st.set_value(null)
	assert_eq(st.get_string_value(), "")


func test_string_coerces_non_string() -> void:
	var st := UiStringState.new("")
	st.set_value(42)
	assert_eq(st.get_value(), "42")
	assert_eq(st.get_string_value(), "42")


# --- TEST-009 UiArrayState ---

func test_array_set_stores_copy_of_source() -> void:
	var st := UiArrayState.new([])
	var src: Array = [1, 2]
	st.set_value(src)
	src.append(3)
	assert_eq(st.get_array_value(), [1, 2], "mutating source after set must not alter store")


func test_array_get_returns_copy() -> void:
	var st := UiArrayState.new([10])
	var got: Array = st.get_array_value()
	got.append(99)
	assert_eq(st.get_array_value(), [10], "mutating getter result must not alter store")
	var got2: Variant = st.get_value()
	(got2 as Array).append(7)
	assert_eq(st.get_array_value(), [10])


func test_array_null_clears_and_emits() -> void:
	var st := UiArrayState.new([1])
	var count := [0]
	st.value_changed.connect(func(_n: Variant, _o: Variant) -> void:
		count[0] += 1
	)
	st.set_value(null)
	assert_eq(st.get_array_value(), [])
	assert_eq(count[0], 1)


func test_array_rejects_non_array() -> void:
	var st := UiArrayState.new([1])
	var count := [0]
	st.value_changed.connect(func(_n: Variant, _o: Variant) -> void:
		count[0] += 1
	)
	st.set_value("nope")
	assert_engine_error("expects an Array", "set_value reject warns")
	assert_eq(st.get_array_value(), [1])
	assert_eq(count[0], 0)


func test_array_accepts_packed_int32() -> void:
	var st := UiArrayState.new([])
	var packed := PackedInt32Array([4, 5])
	st.set_value(packed)
	assert_eq(st.get_array_value(), [4, 5])


func test_array_set_silent_rejects_non_array() -> void:
	var st := UiArrayState.new([8])
	st.set_silent(123)
	assert_engine_error("expects an Array", "set_silent reject warns")
	assert_eq(st.get_array_value(), [8])


func test_array_resource_duplicate_isolates() -> void:
	var original := UiArrayState.new([1])
	var copy: UiArrayState = original.duplicate() as UiArrayState
	original.set_array_value([1, 2])
	assert_eq(copy.get_array_value(), [1], "Resource.duplicate isolates array payloads")
