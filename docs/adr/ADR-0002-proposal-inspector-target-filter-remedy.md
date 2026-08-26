# ADR-0002: Inspector overwrite remedy for validated target arrays

- **Status:** Accepted
- **Date:** 2026-08-25
- **Accepted:** 2026-08-25
- **Audit:** BUG-002, BUG-003, BUG-004
- **Decision gate:** DEC-002 — **A (stop writing back)**

## Context

At control `_ready` / `on_ready`, helpers filter invalid `animation_targets` / `action_targets` / `audio_targets` / `haptic_targets` rows and **`owner.set(...)`** the filtered arrays back onto `@export` properties, discarding Inspector-authored entries without a Hard remedy from godot-core Inspector Authoring Contracts.

## Decision

**A — Stop writing back.** Validate for runtime use into a **non-exported** working store (owner meta / returned validated arrays used by install+trigger paths). Leave `@export` arrays unchanged after play/ready.

## Alternatives considered

| Option | Why not chosen |
|--------|----------------|
| **B — Write back + `push_warning`** | Still mutates authored exports; Inspector lies after first run even with a warning. |
| **C — Document-only** | Weakest Hard-compliant option; teaches authors to ignore mutated exports. |
| Soft-fail keep invalid rows | May null-crash at trigger time. |

## Rationale

Inspector honesty requires authored `@export` values to survive ready. Filtering remains necessary for safe runtime; the validated list is an internal runtime cache, not a silent rewrite of scene data.

## Consequences

- Runtime trigger / state-watch paths **must** use the validated cache, not assume export length equals runnable rows.
- Invalid rows remain visible in the Inspector for authors to fix (dock validators still teach).
- Helper `##` docs must drop “assigns the filtered array back.”
- Developer Guide: one sentence that ready validation does not rewrite target exports.
- GUT / observable: after ready with one invalid row, export size unchanged; triggers still skip invalid rows.

## Related

- `docs/dag.md` DEC-002 / A-05
- godot-core Inspector Authoring Contracts **[Hard]**
- `UiReactAnimTargetHelper.apply_validated_targets`, `UiReactActionTargetHelper.apply_validated_actions_and_merge_triggers`, `UiReactFeedbackTargetHelper.apply_validated_audio_and_haptic_and_merge_triggers`
