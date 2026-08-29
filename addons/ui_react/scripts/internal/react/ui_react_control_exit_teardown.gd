extends RefCounted

## Shared teardown callables for reactive [UiReact*] controls. Call from [constant NOTIFICATION_PREDELETE] only — not [method Node._exit_tree] (reparent).

static func teardown_wire_host(disconnect_states: Callable, wire_exit: Callable) -> void:
	disconnect_states.call()
	wire_exit.call()


static func teardown_no_wire(disconnect_states: Callable) -> void:
	disconnect_states.call()
