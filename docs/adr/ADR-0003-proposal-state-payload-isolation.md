# ADR-0003: Array / transactional payload isolation

- **Status:** Accepted
- **Date:** 2026-08-25
- **Accepted:** 2026-08-25
- **Audit:** BUG-008, BUG-009
- **Decision gate:** DEC-003 — **A1 + A2**

## Context

1. **`UiArrayState.get_value` / `get_array_value`** return the live internal array while `set_value` stores `duplicate()` — in-place mutation bypasses `value_changed`.
2. **`UiTransactionalState._clone_variant`** uses shallow `Array`/`Dictionary.duplicate()` — nested containers are shared between draft and committed.

## Decision

### Axis 1 — `UiArrayState` getters

**A1 — Defensive copy on get.** `get_value` and `get_array_value` return a **shallow** `duplicate()` of the stored array (same depth as inbound `set_value`).

### Axis 2 — Transactional clone depth

**A2 — Deep clone containers.** `_clone_variant` uses `duplicate(true)` for Array and Dictionary.

**Documented limit:** Godot still shares nested `Resource` elements under deep Array/Dictionary duplicate — payloads should be value types (primitives, nested Array/Dictionary), not assume Resource deep-copy.

## Alternatives considered

| Option | Why not chosen |
|--------|----------------|
| **B1 — Document live refs** | Leaves a silent public-API footgun. |
| **B2 — Shallow + document** | Falsifies draft/commit isolation for nested mutables. |
| Typed immutable-only payloads | Breaking. |

## Rationale

Matches Resource-Driven Behavior / Prototype vs Instance: readers must not mutate committed instance state through getter identity. Deep clone makes transactional draft/commit meaningful for nested containers. Shallow on `UiArrayState` get matches existing set policy and common list-of-primitives / list-of-dicts use.

## Consequences

- Call sites that already `.duplicate()` after `get_array_value()` remain correct (extra copy).
- Call sites that relied on getter identity for in-place mutation **must** use setters — intentional break of undefined behavior.
- Large arrays: one shallow copy per get — acceptable for UI-scale lists; revisit only with measured hotspots.
- GUT: in-place mutate of getter result does not change subsequent gets without set; mutate nested draft dict does not change committed until apply.

## Related

- `docs/dag.md` DEC-003 / A-06 / A-07
- godot-patterns Resource-Driven Behavior Lifecycle **[Hard]**
- `ui_array_state.gd`, `ui_transactional_state.gd`
