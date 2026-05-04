## Coalesces [method UiReactDock.refresh] into one deferred flush per burst; manual requests preserve unused-cache invalidation until the flush runs.
## Extra non-manual [method UiReactDock.request_refresh] calls while a flush is already queued set [member _burst_pending] so [method UiReactDock._refresh_once_with_coalesce_drain] can run multiple [method UiReactDock.refresh] passes without losing reasons (e.g. [code]startup[/code] vs [code]scene_changed[/code]).
extends RefCounted

var _invalidate_unused_on_next_flush: bool = false
var _flush_scheduled: bool = false
## Set when non-manual [method UiReactDock.request_refresh] fires while [_flush_scheduled] is already true — drained after each [method UiReactDock.refresh] in the deferred flush burst.
var _burst_pending: bool = false
var _dock: Control = null


func setup(dock: Control) -> void:
	_dock = dock


func request_refresh(reason_is_manual: bool) -> void:
	if reason_is_manual:
		_invalidate_unused_on_next_flush = true
	if _dock == null:
		return
	if _flush_scheduled:
		if not reason_is_manual:
			_burst_pending = true
		return
	_flush_scheduled = true
	_dock.call_deferred(&"_dock_coalescer_flush")


func has_burst_pending() -> bool:
	return _burst_pending


func take_burst_pending() -> bool:
	var v := _burst_pending
	_burst_pending = false
	return v


func take_invalidate_unused_for_flush() -> bool:
	var clear := _invalidate_unused_on_next_flush
	_invalidate_unused_on_next_flush = false
	return clear


func acknowledge_flush_started() -> void:
	_flush_scheduled = false
