# ADR-0001: Non-toggle `pressed_state` contract

- **Status:** Accepted
- **Date:** 2026-08-25
- **Accepted:** 2026-08-25
- **Audit:** BUG-001
- **Decision gate:** DEC-001 — **B (rising-edge pulse)**

## Context

`UiReactBaseButtonReactive._on_pressed` writes `pressed_state.set_value(true)` when `toggle_mode` is false and never writes `false`. Godot `BaseButton` returns `button_pressed` to false on release. Bound `UiBoolState` can latch `true`.

For non-toggle hosts, `_on_pressed_state_changed` does **not** push state into `button_pressed` — `pressed_state` is already a one-way UI→state event channel, not a full two-way mirror. Inventory and rising-edge wire rules expect repeated `false → true` edges.

## Decision

**B — Rising-edge pulse.** On each non-toggle press, set `pressed_state` to `true` then immediately to `false` (both via `set_value` so listeners see both edges). Steady-state remains `false`. Toggle mode is unchanged (`toggled` ↔ `pressed_state`).

## Alternatives considered

| Option | Why not chosen |
|--------|----------------|
| **A — Press/release mirror** | Would need a release-signal path and still would not get state→UI without expanding `_on_pressed_state_changed`; larger contract than the current event-channel design. |
| **C — Document latch** | Leaves rising-edge / repeated-click bindings broken; only valid if product wants sticky “ever pressed.” |
| Remove `pressed_state` for non-toggle | Breaks existing scenes. |

## Rationale

Non-toggle `pressed_state` is an event channel. A pulse matches wire rules (`require_rising_edge`), demo debug lines, and the existing asymmetry (no state→UI for non-toggle). Steady `false` keeps the Resource honest between clicks.

## Consequences

- Public binding semantics for non-toggle `pressed_state`: expect a pulse per press, not a held `true`.
- Developer Guide §4 and any README examples that imply latch must match.
- GUT (Wave B/C): after one non-toggle press handler run, final `get_bool_value()` is `false`; `value_changed` observed true then false (or equivalent contract).
- Call sites that treated latch-as-feature must clear or rebind differently — none are intentional per audit.

## Related

- `docs/dag.md` Wave A / A-04
- `docs/developer-guide.md` §4
- `addons/ui_react/scripts/internal/react/ui_react_base_button_reactive.gd`
