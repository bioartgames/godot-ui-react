# ADR index

**Status vocabulary for this folder**

| Status | Meaning |
|--------|---------|
| `PROPOSAL` | Draft for user approval — **not** project law |
| `Accepted` | Decision recorded; cite from DAG Related links |
| `Superseded` | Replaced by a later ADR |

Do **not** paste ADR numbers into shipping `.gd` comments. Traceability: this folder, `docs/dag.md`, `docs/developer-guide.md`, git.

## Accepted

| ID | Title | Decision | Blocks closed |
|----|-------|----------|---------------|
| [ADR-0001](ADR-0001-proposal-pressed-state-nontoggle.md) | Non-toggle `pressed_state` contract | **B** rising-edge pulse | DEC-001 / BUG-001 |
| [ADR-0002](ADR-0002-proposal-inspector-target-filter-remedy.md) | Inspector overwrite remedy for validated target arrays | **A** stop write-back | DEC-002 / BUG-002–004 |
| [ADR-0003](ADR-0003-proposal-state-payload-isolation.md) | Array / transactional payload isolation | **A1+A2** copy on get + deep clone | DEC-003 / BUG-008–009 |
| [ADR-0004](ADR-0004-proposal-tab-config-instance-state.md) | `UiTabContainerCfg` vs instance tab runtime state | **B** duplicate cfg at runtime | DEC-004 / BUG-010 / ARCH-001 / PAT-001 |
| [ADR-0005](ADR-0005-proposal-portable-addon-gut-contracts.md) | Contract GUT for portable addon public API | defaults accepted | DEC-005 / Wave B–C |
| [ADR-0006](ADR-0006-reparent-survives-bindings.md) | Bindings survive reparent | Teardown on PREDELETE only | M-REPARENT |

Proposals awaiting confirmation: *(none)*
