extends GutTest

## Wave C-03: ItemList / two-way control smoke (TEST-025…026).


func test_item_list_selection_index() -> void:
	var list := UiReactItemList.new()
	var items := UiArrayState.new(["A", "B", "C"])
	var selected := UiIntState.new(1)
	list.items_state = items
	list.selected_state = selected
	add_child(list)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(list.get_animation_selection_index(), 1)
	assert_true(list.is_selected(1))
	selected.set_value(2)
	await get_tree().process_frame
	assert_eq(list.get_animation_selection_index(), 2)
	list.queue_free()


func test_checkbox_two_way() -> void:
	var box := UiReactCheckBox.new()
	var st := UiBoolState.new(false)
	box.checked_state = st
	add_child(box)
	await get_tree().process_frame
	await get_tree().process_frame
	st.set_value(true)
	await get_tree().process_frame
	assert_true(box.button_pressed)
	box.button_pressed = false
	box.toggled.emit(false)
	await get_tree().process_frame
	assert_eq(st.get_bool_value(), false)
	box.queue_free()


func test_line_edit_two_way() -> void:
	var edit := UiReactLineEdit.new()
	var st := UiStringState.new("")
	edit.text_state = st
	add_child(edit)
	await get_tree().process_frame
	await get_tree().process_frame
	st.set_value("hi")
	await get_tree().process_frame
	assert_eq(edit.text, "hi")
	edit.text = "bye"
	edit.text_changed.emit("bye")
	await get_tree().process_frame
	assert_eq(st.get_string_value(), "bye")
	edit.queue_free()


func test_button_pressed_state_pulses() -> void:
	var btn := UiReactButton.new()
	btn.toggle_mode = false
	var ps := UiBoolState.new(false)
	btn.pressed_state = ps
	add_child(btn)
	await get_tree().process_frame
	await get_tree().process_frame
	var edges: Array = []
	ps.value_changed.connect(func(n: Variant, _o: Variant) -> void:
		edges.append(n)
	)
	btn.pressed.emit()
	assert_eq(ps.get_bool_value(), false, "steady state after pulse is false")
	assert_true(edges.size() >= 2)
	assert_eq(edges[0], true)
	assert_eq(edges[1], false)
	btn.queue_free()
