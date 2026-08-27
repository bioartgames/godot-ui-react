extends GutTest

## Transactional contracts (TEST-010…011).


func test_txn_init_draft_matches_committed() -> void:
	var st := UiTransactionalState.new(5.0)
	assert_eq(st.get_value(), 5.0)
	assert_eq(st.get_committed_value(), 5.0)
	assert_false(st.has_pending_changes())


func test_txn_set_value_updates_draft_only() -> void:
	var st := UiTransactionalState.new(5.0)
	var seen: Array = []
	st.value_changed.connect(func(n: Variant, o: Variant) -> void:
		seen.append({"new": n, "old": o})
	)
	st.set_value(7.0)
	assert_eq(st.get_draft_value(), 7.0)
	assert_eq(st.get_committed_value(), 5.0)
	assert_true(st.has_pending_changes())
	assert_eq(seen.size(), 1)
	assert_eq(seen[0]["new"], 7.0)
	assert_eq(seen[0]["old"], 5.0)


func test_txn_apply_and_cancel() -> void:
	var st := UiTransactionalState.new(1.0)
	st.set_value(2.0)
	st.apply_draft()
	assert_eq(st.get_committed_value(), 2.0)
	assert_false(st.has_pending_changes())
	st.set_value(9.0)
	st.cancel_draft()
	assert_eq(st.get_draft_value(), 2.0)
	assert_eq(st.get_committed_value(), 2.0)


func test_txn_nested_dict_draft_isolated_from_committed() -> void:
	var st := UiTransactionalState.new({"k": {"n": 1}})
	st.begin_edit()
	var draft: Variant = st.get_draft_value()
	assert_true(draft is Dictionary)
	((draft as Dictionary)["k"] as Dictionary)["n"] = 99
	st.set_value(draft)
	var committed: Variant = st.get_committed_value()
	assert_eq(((committed as Dictionary)["k"] as Dictionary)["n"], 1, "nested draft mutate must not alias committed")


func test_txn_matches_expected_binding_class() -> void:
	var st := UiTransactionalState.new(true)
	assert_true(st.matches_expected_binding_class(&"UiBoolState"))
	assert_false(st.matches_expected_binding_class(&"UiStringState"))


func test_group_batch_apply_cancel_skips_null() -> void:
	var a := UiTransactionalState.new(0)
	var b := UiTransactionalState.new(0)
	var group := UiTransactionalGroup.new()
	group.states = [a, null, b]
	group.begin_edit_all()
	a.set_value(1)
	b.set_value(2)
	assert_true(group.has_pending_changes())
	group.apply_all()
	assert_eq(a.get_committed_value(), 1)
	assert_eq(b.get_committed_value(), 2)
	assert_false(group.has_pending_changes())
	a.set_value(3)
	group.cancel_all()
	assert_eq(a.get_draft_value(), 1)
