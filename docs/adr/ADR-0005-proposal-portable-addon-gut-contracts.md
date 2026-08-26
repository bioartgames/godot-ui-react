# ADR-0005: Contract GUT for portable addon public API

- **Status:** Accepted
- **Date:** 2026-08-25
- **Accepted:** 2026-08-25
- **Audit:** TEST-001…029
- **Decision gate:** DEC-005 — **proposal defaults accepted**

## Context

The addon exposes Services/utilities and Resource APIs consumed outside their scenes. `godot-testing.mdc` Hard-obligates contract GUT for those classifications. The repo has **zero** `GutTest` scripts and no GUT addon path. Several `*_for_tests` hooks already exist on production types.

## Decision

| Topic | Accepted default |
|-------|------------------|
| **Test root** | `res://test/unit/` (repo root), not under `addons/ui_react/` shipping tree |
| **Runner** | Headless GUT via machine Godot 4.7 console binary (host `godot-local-tooling.mdc`); document command in Developer Guide |
| **v1 Hard floors in scope** | UiState family + transactional + computed service + wire helper + control two-way smoke for BUG regressions (Wave B); expand Wave C to helpers/validators/signals |
| **Assertion style** | Behavioral contracts / Pre-Test Questions — **no** private `_` member access |
| **Addon packaging** | GUT as **dev dependency** (documented enable path); not required for end users enabling only Ui React |

## Alternatives considered

| Option | Why not chosen |
|--------|----------------|
| Ship tests inside `addons/ui_react/test/` | Couples consumer projects to test assets. |
| Manual-only verification | Fails Hard obligation for portable public API. |

## Rationale

Hard testing obligation applies to portable public API. Keeping suites outside the shipping addon tree preserves consumer hygiene. Existing `*_for_tests` hooks anticipate this bootstrap.

## Consequences

- Contributors / CI must install and enable GUT.
- Wave A Acceptance gates may name GUT asserts once B-00 lands; until then PLANs may use **explicit temporary** observable/manual gates labeled as such.
- Developer Guide gains “Running tests.”

## Related

- `docs/dag.md` Waves B–C / B-00
- `godot-testing.mdc` Test Obligation table
- Existing hooks: `UiReactComputedService.reset_internal_state_for_tests`, etc.
