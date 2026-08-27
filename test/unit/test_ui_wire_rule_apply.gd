extends GutTest

## Wire rule apply / pulse contracts (TEST-014).


func test_map_int_to_string_apply() -> void:
	var src := UiIntState.new(2)
	var dest := UiStringState.new("")
	var hint := UiStringState.new("")
	var rule := UiReactWireMapIntToString.new()
	rule.source_int_state = src
	rule.target_string_state = dest
	rule.hint_state = hint
	rule.index_to_string = {0: "", 1: "weapon", 2: "consumable"}
	rule.hint_labels_by_index = {2: "Consumables"}
	rule.apply(null)
	assert_eq(dest.get_string_value(), "consumable")
	assert_true(hint.get_string_value().contains("Consumables"))


func test_sync_bool_debug_line_apply() -> void:
	var b := UiBoolState.new(true)
	var dest := UiStringState.new("")
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	rule.bool_state = b
	rule.target_string_state = dest
	rule.line_prefix = "pressed="
	rule.apply(null)
	assert_eq(dest.get_string_value(), "pressed=true")


func test_sort_array_by_key_apply() -> void:
	var items := UiArrayState.new([
		{"name": "b", "qty": 1},
		{"name": "a", "qty": 2},
	])
	var key := UiStringState.new("name")
	var desc := UiBoolState.new(false)
	var rule := UiReactWireSortArrayByKey.new()
	rule.items_state = items
	rule.sort_key_state = key
	rule.descending_state = desc
	rule.apply(null)
	var out: Array = items.get_array_value()
	assert_eq((out[0] as Dictionary)["name"], "a")
	assert_eq((out[1] as Dictionary)["name"], "b")


func test_bool_pulse_rising_edge_writes_template() -> void:
	var pulse := UiBoolState.new(false)
	var dest := UiStringState.new("")
	var selected := UiIntState.new(0)
	var items := UiArrayState.new([{"name": "Potion", "kind": "consumable", "qty": 3}])
	var rule := UiReactWireSetStringOnBoolPulse.new()
	rule.pulse_bool = pulse
	rule.target_string_state = dest
	rule.selected_state = selected
	rule.items_state = items
	rule.template_rising = "{name}:{kind}:{qty}"
	rule.require_rising_edge = true
	rule.apply_from_pulse(null, true, false)
	assert_eq(dest.get_string_value(), "Potion:consumable:3")
	dest.set_value("keep")
	rule.apply_from_pulse(null, false, true)
	assert_eq(dest.get_string_value(), "keep", "falling edge must not write when rising required")


func test_disabled_rule_apply_is_noop() -> void:
	var dest := UiStringState.new("x")
	var rule := UiReactWireSyncBoolStateDebugLine.new()
	rule.enabled = false
	rule.bool_state = UiBoolState.new(true)
	rule.target_string_state = dest
	rule.line_prefix = "p="
	rule.apply(null)
	assert_eq(dest.get_string_value(), "x")
