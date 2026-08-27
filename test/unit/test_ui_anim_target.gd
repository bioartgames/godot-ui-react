extends GutTest

## UiAnimTarget apply contracts (TEST-015).


func test_apply_empty_target_returns_empty_signal() -> void:
	var owner := Control.new()
	add_child(owner)
	var anim := UiAnimTarget.new()
	anim.target = NodePath("")
	anim.animation = UiAnimTarget.AnimationAction.FADE_IN
	anim.duration = 0.05
	var sig: Signal = anim.apply(owner)
	assert_eq(sig, Signal(), "empty target must return empty Signal")
	owner.queue_free()


func test_apply_to_control_fade_in_awaits_completion() -> void:
	var owner := Control.new()
	var target := Control.new()
	add_child(owner)
	owner.add_child(target)
	await get_tree().process_frame
	var anim := UiAnimTarget.new()
	anim.animation = UiAnimTarget.AnimationAction.FADE_IN
	anim.duration = 0.05
	target.modulate.a = 0.0
	var sig: Signal = anim.apply_to_control(owner, target)
	assert_ne(sig, Signal(), "valid fade must return a completion Signal")
	await sig
	assert_gt(target.modulate.a, 0.5)
	owner.queue_free()


func test_apply_to_control_null_target_returns_empty() -> void:
	var owner := Control.new()
	add_child(owner)
	var anim := UiAnimTarget.new()
	anim.animation = UiAnimTarget.AnimationAction.FADE_IN
	anim.duration = 0.05
	var sig: Signal = anim.apply_to_control(owner, null)
	assert_engine_error("UiAnimUtils", "guard warns on null target")
	assert_eq(sig, Signal())
	owner.queue_free()
