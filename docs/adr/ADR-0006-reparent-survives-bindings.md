# ADR-0006: Bindings survive reparent

| Field | Value |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-29 |
| **Deciders** | Project lead |
| **Related** | [Developer Guide](../developer-guide.md), [DAG M-REPARENT](../dag.md) |

## Context

`Node.reparent` / `add_child` after a node is already in the tree fires `_exit_tree` then `_enter_tree`. `_ready` does not run again. `UiReact*` controls tore down `value_changed` and `UiState` wires in `_exit_tree` (and again on `NOTIFICATION_PREDELETE`). After reparent, the thumb still moved but drafts stayed at the committed value. Re-assigning the same `value_state` no-ops the setter, so hosts could not repair the binding.

## Decision

Reactive teardown runs on **`NOTIFICATION_PREDELETE` only**. Bindings and subscription scopes survive reparent. If a control later rebinds on `_enter_tree`, it must allocate a **new** `UiReactSubscriptionScope` (`dispose()` latches `_disposed`).

## Alternatives considered

| Alternative | Why not |
|---|---|
| Deferred `_exit_tree` teardown | Still races reparent; pretends exit is delete |
| Rebind on `_enter_tree` using the disposed scope | `dispose()` latches; connects become no-ops |
| Host-only “don’t reparent” | Leaves the portable contract broken for every other consumer |

## Consequences

- Hosts may reparent `UiReact*` after `_ready` without losing two-way state.
- Controls stay bound until they are actually freed.
- Wire-rule `_enter_tree` attach still refreshes via `attach` → `detach` first.

## See also

- GUT: `test/unit/test_ui_c03_controls.gd` — `test_slider_value_state_updates_after_reparent`
