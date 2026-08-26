# ADR-0004: `UiTabContainerCfg` vs instance tab runtime state

- **Status:** Accepted
- **Date:** 2026-08-25
- **Accepted:** 2026-08-25
- **Audit:** BUG-010, ARCH-001, PAT-001
- **Decision gate:** DEC-004 — **B (duplicate cfg on ready)**

## Context

`UiTabCollectionSync.apply_tabs_from_array` calls `tab_config.tab_content_states.resize(new_count)` on the exported `UiTabContainerCfg` Resource. Shared `.tres` assignment then couples hosts.

Violates Resource-Driven Behavior **[Hard]** (instance mutation on Resource) and architecture Prototype vs Instance (ARCH-001 Preferable).

## Decision

**B — Duplicate cfg for runtime hosts.** When a `UiReactTabContainer` localizes config for play/runtime, assign `_tab_config = tab_config.duplicate(true)` (once per assignment path) so resize and other mutations touch a **host-private** instance. Keep `tab_content_states` on the cfg type (no API move in this remediation).

**Editor path:** Do not localize in `@tool` / editor-hint so Graph and Inspector continue editing the authored asset. Localize when leaving editor hint (`_ready` / runtime reassignment).

**Long-term note:** Option **A** (runtime table on Node) remains the cleaner Ownership end-state if cfg responsibilities keep growing; not required to close BUG-010.

## Alternatives considered

| Option | Why not chosen (now) |
|--------|----------------------|
| **A — Move runtime array to Node** | Best Ownership long-term; larger authoring/API change than needed for the bug. |
| **C — Forbid shared assets alone** | Incomplete — single host still resizes a Resource that may be a packed scene asset; useful as a later validator add-on, not the fix. |
| `resource_local_to_scene` only | Easy to forget on new `.tres`. |

## Rationale

**B** satisfies pattern Ownership Hard with a small, localized change: each runtime host mutates **its** copy. Same spirit as editor code that already duplicates tab cfg when editing. Documents the contract: do not expect cross-host shared mutation of `tab_content_states` at runtime.

## Consequences

- Authors who relied on two runtime hosts mutating one shared cfg instance will see isolation (intended).
- Nested Resources inside cfg are duplicated with `duplicate(true)` — each host gets its own nested state Resources at runtime.
- Developer Guide: assigned `tab_config` is localized per host at runtime.
- GUT / observable: two runtime hosts given the same packed cfg Resource; grow tabs on A; B’s `tab_content_states.size()` unchanged.

## Related

- `docs/dag.md` DEC-004 / A-08
- `ui_tab_collection_sync.gd`, `ui_react_tab_container.gd`, `ui_tab_container_cfg.gd`
- godot-patterns Resource-Driven Behavior Ownership **[Hard]**
