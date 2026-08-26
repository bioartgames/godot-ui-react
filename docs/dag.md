# Implementation DAG — Ui React

**Assumption:** Knowledge-chain bootstrap for this **portable addon** repo (not a game GDD project). Status labels below are authoritative for PREFLIGHT predecessor checks.

## Status vocabulary

| Status | Meaning |
|--------|---------|
| `TODO` | Scheduled, not started |
| `IN PROGRESS` | Active work |
| `BLOCKED` | Waiting on a named decision, predecessor, or artifact |
| `DONE` | Complete; Acceptance gate passed where applicable |

## Node types (non-trivial work)

Per `godot-workflow.mdc`: `PLAN` → `PREFLIGHT` → `IMPL`. Trivial items (all four Triviality criteria) may use a single task row without PLAN/PREFLIGHT.

## Milestone: M-AUDIT — Quality audit remediation

Source: confirmed findings only (BUG-/GDS-/ARCH-/PAT-/TEST-). Do not expand into style preferences outside those IDs.

### Decisions (accepted 2026-08-25)

| ID | Topic | ADR | Choice | Status |
|----|-------|-----|--------|--------|
| **DEC-001** | Non-toggle `pressed_state` | [ADR-0001](adr/ADR-0001-proposal-pressed-state-nontoggle.md) | **B** rising-edge pulse | `DONE` |
| **DEC-002** | Inspector target-array overwrite | [ADR-0002](adr/ADR-0002-proposal-inspector-target-filter-remedy.md) | **A** stop write-back | `DONE` |
| **DEC-003** | Array getter + transactional clone | [ADR-0003](adr/ADR-0003-proposal-state-payload-isolation.md) | **A1+A2** | `DONE` |
| **DEC-004** | `UiTabContainerCfg` instance isolation | [ADR-0004](adr/ADR-0004-proposal-tab-config-instance-state.md) | **B** duplicate at runtime | `DONE` |
| **DEC-005** | Portable addon contract GUT | [ADR-0005](adr/ADR-0005-proposal-portable-addon-gut-contracts.md) | defaults accepted | `DONE` |

---

## Wave A — Correctness (bugs)

**Goal:** Restore or decide public contracts that produce incorrect runtime / authoring behavior.  
**Priority:** before Preferable GDS hygiene.

### Wave A work items

| Node ID | Audit IDs | Status | Significance | Triviality | Bug class | Doc sync | Pipeline | Notes |
|---------|-----------|--------|--------------|------------|-----------|----------|----------|-------|
| **A-01** | BUG-005 | `DONE` | routine | **trivial** | Implementation | none | single IMPL (no PLAN) | Add `sync_initial_state` after action validate on LineEdit |
| **A-02** | BUG-006 | `DONE` | routine | **trivial** | Implementation | none | single IMPL | `is_instance_valid` before `is_inside_tree` in wire callbacks |
| **A-03** | BUG-007 | `DONE` | routine | **trivial** | Implementation | none | single IMPL | `set_silent` reject path match `set_value` |
| **A-04** | BUG-001 | `DONE` | SIGNIFICANT | non-trivial | Design / Framework | ADR-0001 Accepted | PLAN→PREFLIGHT→IMPL | Pulse contract |
| **A-05** | BUG-002, BUG-003, BUG-004 | `DONE` | SIGNIFICANT | non-trivial | Framework | ADR-0002 Accepted | PLAN→PREFLIGHT→IMPL | Stop export write-back |
| **A-06** | BUG-008 | `DONE` | SIGNIFICANT | non-trivial | Framework | ADR-0003 | PLAN→PREFLIGHT→IMPL | Getter copy |
| **A-07** | BUG-009 | `DONE` | SIGNIFICANT | non-trivial | Framework | ADR-0003 | PLAN→PREFLIGHT→IMPL | Deep clone |
| **A-08** | BUG-010, ARCH-001, PAT-001 | `DONE` | SIGNIFICANT | non-trivial | Architecture | ADR-0004 | PLAN→PREFLIGHT→IMPL | Runtime cfg duplicate |

**Dependency note:** A-01…A-03 do not require DEC-*. Prefer dispatching them first. IMPL turns for bugs still open with `godot-bugs.mdc` Evidence Ledger. Non-trivial A-04…A-08 require PREFLIGHT at dispatch (not at plan time).

---

### PLAN A-04 (BUG-001) — `TODO` (complete)

| Field | Content |
|-------|---------|
| **Objective** | Non-toggle `pressed_state` pulses on each press: listeners observe `true` then `false`; steady-state after the press handler is `false`. Toggle-mode mirroring via `toggled` is unchanged. |
| **Files in scope** | **Write:** `addons/ui_react/scripts/internal/react/ui_react_base_button_reactive.gd`; `docs/developer-guide.md` only if §4 pulse wording drifts (already updated at accept — touch only if IMPL needs a one-liner fix). **Read:** `ui_react_button.gd`, `ui_react_texture_button.gd`, `ui_bool_state.gd`, inventory example that binds `pressed_state`. |
| **Approach** | 1. In `_on_pressed`, keep early returns (`ps` missing, `toggle_mode`, `_bind.updating`). 2. Under `_bind.updating = true`, call `ps.set_value(true)` then `ps.set_value(false)` (both `set_value`, not `set_silent`, so `value_changed` fires for both edges). 3. Clear `_bind.updating`. 4. Do **not** change `_on_toggled` or non-toggle branch of `_on_pressed_state_changed` (still no state→UI for non-toggle). 5. Optionally extend `##` on `pressed_state` exports on Button/TextureButton if they describe latch — only if such wording exists. |
| **Constraints** | ADR-0001 Accepted (B); godot-core Decision Gate already cleared; Premise Challenge: do not collapse BaseButton `button_pressed` into a custom held-state system — pulse is UI→state only; no ADR/DAG/CB IDs in shipping comments (`godot-gdscript.mdc`); do not expand toggle redesign. |
| **Acceptance gate** | **Temporary observable (until B-00):** non-toggle Button with `pressed_state` UiBoolState; invoke press path once; final `pressed_state.get_bool_value() == false`. **Preferred when GUT exists (C-03 / B smoke):** assert `value_changed` sequence includes true then false and final false; toggle_mode still mirrors `button_pressed`. |
| **Out of scope** | Toggle-mode redesign; removing `pressed_state`; action/anim targets; press/release mirror (A); latch documentation (C). |

**PREFLIGHT A-04:** run at IMPL dispatch — not yet.  
**IMPL A-04:** after PREFLIGHT go.

---

### PLAN A-05 (BUG-002/003/004) — `TODO` (complete)

| Field | Content |
|-------|---------|
| **Objective** | Ready-time validation of animation/action/audio/haptic target arrays no longer writes filtered arrays back onto `@export` properties. Invalid rows stay in Inspector; runtime install/trigger paths use a validated non-export store. |
| **Files in scope** | **Write:** `addons/ui_react/scripts/internal/react/ui_react_anim_target_helper.gd`, `ui_react_action_target_helper.gd`, `ui_react_feedback_target_helper.gd`; any host that passes raw `animation_targets` / `action_targets` / feedback arrays into trigger/play helpers after validate if those paths would still execute invalid rows — minimally ensure trigger/state-watch use validated lists (prefer helper getters so control files stay untouched when possible). **Read:** control `_validate_animation_targets` call sites; `ui_react_base_button_reactive.gd` `_animation_targets_from_host`; ItemList/Tree row-play paths. **Write docs:** helper `##` that currently say “assigns … back”; Dev Guide already states ADR-0002 — amend only if IMPL wording needs it. |
| **Approach** | 1. **Anim:** In `apply_validated_targets`, remove `owner.set(animation_targets_property, …)`. After validate, store `result.animation_targets` on owner meta (e.g. `StringName` key owned by the helper, clear/replace each apply). Return `trigger_map` as today. Add a small public/static getter e.g. `get_runtime_animation_targets(owner, property)` → meta if present else current export (post-validate hosts should always have meta). 2. **Action / feedback:** Same — remove `owner.set` on `action_targets` / `audio_targets` / `haptic_targets`; keep using the local `valid` array for `_install_state_watch_bindings` and trigger merges; store validated arrays in meta if any later path re-reads exports for firing. 3. **Consumers:** Change `_animation_targets_from_host` and any `trigger_animations(self, animation_targets, …)` / row collectors that run after validate to use the runtime getter so invalid export rows are not applied. Prefer centralizing in helpers so not every control must change — if a control still passes the export into `trigger_animations` after validate, update either the control **or** make `trigger_animations` resolve via meta when owner is a Control that has meta. Document the chosen single pattern in the IMPL outcome. 4. Update helper class docs to state exports are not mutated. 5. Do not strip invalid rows from the scene file. |
| **Constraints** | ADR-0002 Accepted (A); godot-core Inspector Authoring **[Hard]** — remedy is stop write-back, not warn/docs; no ticket IDs in shipping comments; do not change which triggers are legal; Graph dock validators out of scope. |
| **Acceptance gate** | **Temporary observable:** Control with one valid + one intentionally invalid animation (or action) row; after `_ready`, Inspector/`get(animation_targets)` size still includes the invalid row; triggers/state-watch still skip invalid (no crash). **GUT when available:** same assertions in unit/smoke. |
| **Out of scope** | Changing legal triggers; Graph dock validators; GDS hygiene batches; remedy B/C. |

**PREFLIGHT A-05 / IMPL A-05:** at dispatch.

---

### PLAN A-06 (BUG-008) — `TODO` (complete)

| Field | Content |
|-------|---------|
| **Objective** | `UiArrayState.get_value` / `get_array_value` return a shallow copy so in-place mutation of the result does not alter stored state or skip `value_changed`. |
| **Files in scope** | **Write:** `addons/ui_react/scripts/api/models/ui_array_state.gd`. **Read:** call sites of `get_array_value` / `get_value` on arrays (e.g. `ui_react_wire_sort_array_by_key.gd`) — do not change them unless identity reliance breaks tests (extra `.duplicate()` is fine). **Docs:** class `##` one line that getters copy; Dev Guide already notes — touch only if needed. |
| **Approach** | 1. `get_array_value()` → `return value.duplicate()` (shallow). 2. `get_value()` → return the same shallow duplicate (typed as Variant). 3. Leave `set_value` / `set_silent` inbound duplicate policy unchanged (A-03 may still fix `set_silent` reject separately). 4. Do not deep-duplicate on get (ADR axis A1 = shallow). |
| **Constraints** | ADR-0003 A1; Resource-Driven Behavior; no private test hooks required; no CB/ADR IDs in source comments. |
| **Acceptance gate** | **Temporary / GUT:** `set_array_value([1])`; `var a = get_array_value(); a.append(2)`; `get_array_value() == [1]` (or equivalent); a subsequent `set` still notifies. Wire sort that already `.duplicate()` still sorts correctly. |
| **Out of scope** | Transactional clone (A-07); wire rule redesign; deep get. |

**PREFLIGHT A-06 / IMPL A-06:** at dispatch. May ship in same wave as A-07; separate PREFLIGHT each if dispatched separately.

---

### PLAN A-07 (BUG-009) — `TODO` (complete)

| Field | Content |
|-------|---------|
| **Objective** | `UiTransactionalState` draft/commit cloning deep-copies Array and Dictionary containers so nested mutable payloads are not shared between draft and committed. |
| **Files in scope** | **Write:** `addons/ui_react/scripts/api/models/ui_transactional_state.gd` (`_clone_variant` only unless docs on class). **Read:** transactional session/host bind callers. |
| **Approach** | 1. In `_clone_variant`, for Array and Dictionary use `duplicate(true)` instead of shallow `duplicate()`. 2. Leave Resource / other types behavior as today. 3. Add a brief class or method `##` note: nested Resources remain shared per Godot deep-duplicate rules. |
| **Constraints** | ADR-0003 A2; do not invent a custom deep-clone for Resources; no ADR IDs in shipping comments. |
| **Acceptance gate** | **Temporary / GUT:** committed `{"k": {"n": 1}}`; begin edit; mutate nested draft dict value; read committed nested value unchanged until apply; after apply, committed matches draft. |
| **Out of scope** | `UiArrayState` getters (A-06); tab cfg (A-08). |

**PREFLIGHT A-07 / IMPL A-07:** at dispatch.

---

### PLAN A-08 (BUG-010 / ARCH-001 / PAT-001) — `TODO` (complete)

| Field | Content |
|-------|---------|
| **Objective** | Two runtime `UiReactTabContainer` hosts that start from the same packed `UiTabContainerCfg` Resource do not couple via `tab_content_states.resize` — each host mutates a private duplicate. |
| **Files in scope** | **Write:** `addons/ui_react/scripts/controls/ui_react_tab_container.gd` (localize in setter/`_ready` path). **Read:** `ui_tab_collection_sync.gd` (leave resize as-is on the local cfg), `ui_tab_container_cfg.gd`, editor rebind paths that already duplicate. **Docs:** Dev Guide already states runtime localization — amend only if IMPL detail needs it. |
| **Approach** | 1. Add a private helper e.g. `_localize_tab_config_for_runtime()`: if `Engine.is_editor_hint()` or `_tab_config == null`, no-op; else if not yet localized (meta flag on the instance or “replace with duplicate(true) and mark”), set `_tab_config = _tab_config.duplicate(true)` and mark so double-ready does not compound. 2. Call after export hydrate in `_ready` before `_connect_tab_config_signals`, and in the `tab_config` setter when `is_node_ready()` and not editor hint (disconnect → localize → reconnect). 3. Do **not** duplicate under editor hint so Inspector/Graph keep editing the authored asset. 4. Leave `UiTabCollectionSync.apply_tabs_from_array` resize logic unchanged. 5. Do not implement share-forbid validator (option C) in this item. |
| **Constraints** | ADR-0004 Accepted (B); godot-patterns Ownership **[Hard]** satisfied by per-host instance; Prototype vs Instance; no option A API move; no CB/ADR IDs in comments. |
| **Acceptance gate** | **Temporary observable / GUT:** two runtime TabContainers; assign same cfg Resource identity before ready (or equivalent test setup); grow tabs on host A via tabs_state so resize runs; host B’s cfg `tab_content_states.size()` unchanged relative to A’s post-resize size (B’s private copy). Editor open of shared asset still edits one resource when `is_editor_hint`. |
| **Out of scope** | Moving `tab_content_states` onto the Node (A); share validator (C); tab animation polish; wire rules. |

**PREFLIGHT A-08 / IMPL A-08:** at dispatch.

---

### Trivial IMPL specs (ready — no PLAN node)

#### IMPL A-01 (BUG-005) — `TODO`

- **File (write):** `addons/ui_react/scripts/controls/ui_react_line_edit.gd`
- **Change:** After `apply_validated_actions_and_merge_triggers`, call `UiReactActionTargetHelper.sync_initial_state(self, "UiReactLineEdit", action_targets)` (mirror CheckBox / OptionButton).
- **Acceptance:** LineEdit with `state_watch` action applies once at ready when bool already true; no double-apply regression vs other controls.
- **Evidence Ledger:** required on IMPL turn.

#### IMPL A-02 (BUG-006) — `TODO`

- **File (write):** `addons/ui_react/scripts/internal/react/ui_react_wire_rule_helper.gd`
- **Change:** In `_make_rule_cb`, copy-detail `sel_cb`, and bool-pulse lambda: `is_instance_valid(host)` **before** `host.is_inside_tree()`.
- **Acceptance:** Freed-host path returns without error (instrument or GUT when available).
- **Evidence Ledger:** required on IMPL turn.

#### IMPL A-03 (BUG-007) — `TODO`

- **File (write):** `addons/ui_react/scripts/api/models/ui_array_state.gd`
- **Change:** `set_silent` else-branch: `push_warning` + `return` (no `value = []`), matching `set_value`. **Note:** If A-06 IMPL lands in the same file later, keep both changes; A-03 does not add getter copies.
- **Acceptance:** Unsupported type leaves prior `value` unchanged; no spurious `emit_changed` from wipe.
- **Evidence Ledger:** required on IMPL turn.

---

## Wave B — Portable contract tests (foundation)

| Node ID | Audit IDs | Status | Significance | Triviality | Doc sync | Pipeline |
|---------|-----------|--------|--------------|------------|-----------|----------|
| **B-00** | TEST foundation / DEC-005 | `DONE` | SIGNIFICANT | non-trivial | ADR-0005 + Dev Guide §5 | PLAN→PREFLIGHT→IMPL |
| **B-01** | TEST-001…004 | `TODO` | SIGNIFICANT (with B-00) | non-trivial | none beyond B-00 | after B-00 DONE |
| **B-02** | TEST-005…009 | `TODO` | — | non-trivial | — | UiState concrete family |
| **B-03** | TEST-010…011 | `TODO` | — | non-trivial | — | Transactional |
| **B-04** | TEST-012…013 | `TODO` | — | non-trivial | — | Computed resources |
| **B-05** | TEST-014 | `TODO` | — | non-trivial | — | Wire rule `apply` / pulse |
| **B-06** | TEST-015 | `TODO` | — | non-trivial | — | `UiAnimTarget` apply contracts |
| **B-07** | TEST-016…018 | `TODO` | — | non-trivial | — | ComputedService, WireRuleHelper, TransactionalSession |

### PLAN B-00 — `TODO` (complete)

| Field | Content |
|-------|---------|
| **Objective** | Contributors can run headless GUT against `res://test/unit/` with at least one smoke `GutTest` proving the harness works; GUT is a documented dev dependency; shipping `addons/ui_react/` has no test tree. |
| **Files in scope** | **Write:** GUT install under `addons/gut/` (upstream addon as used by this machine/project convention); `project.godot` plugin enable for GUT if required; `res://test/unit/` + one minimal smoke test script; `docs/developer-guide.md` §5 with exact PowerShell headless command using Godot 4.7 console path from host tooling. **Read:** ADR-0005; existing `*_for_tests` hooks (do not call from smoke unless needed). **Do not write:** tests inside `addons/ui_react/`. |
| **Approach** | 1. Add GUT as repo-local addon (vendor or documented install steps if vendoring is preferred — prefer vendoring so clone-and-run works). 2. Enable GUT plugin in `project.godot`. 3. Create `test/unit/test_harness_smoke.gd` extending `GutTest` with one trivial assert (`assert_true(true)` or `assert_eq(1,1)`). 4. Document headless command in Dev Guide §5 matching `godot-local-tooling.mdc` binary + `-gdir=res://test/unit` + `-gexit`. 5. Run once; smoke passes. |
| **Constraints** | ADR-0005 Accepted; `godot-testing.mdc` Pre-Test Questions apply to later suites — smoke may be harness-only; no private `_` poking in future contract tests; GUT not required for end users of Ui React alone. |
| **Acceptance gate** | Headless GUT exits 0 with the smoke test passing; Dev Guide §5 documents the command; no `GutTest` under `addons/ui_react/`. |
| **Out of scope** | Full Wave B-01…B-07 contract suites (separate PLAN/IMPL); CI YAML unless already in repo and trivial to point at the same command. |

**PREFLIGHT B-00 / IMPL B-00:** at dispatch. B-01… require separate PLANs when scheduled (Approach = named contracts per TEST IDs).

---

## Wave C — Remaining Hard test floors

| Node ID | Audit IDs | Status | Depends |
|---------|-----------|--------|---------|
| **C-01** | TEST-019…022 | `TODO` (after B) | B-00 DONE |
| **C-02** | TEST-023…024 | `TODO` | B-00; may follow A-05/A-08 |
| **C-03** | TEST-025…026 | `TODO` | B-00; A-04 pressed_state pulse |
| **C-04** | TEST-027…029 | `TODO` | B-00 |

All Wave C: SIGNIFICANT-as-verification / non-trivial multi-file suites; PLAN nodes when Wave B foundation is DONE.

---

## Wave D — GDScript hygiene (batched)

Batch Continuous Improvement patterns. All **routine** for Significance unless a batch changes public API docs surface materially. All batches below are **multi-file ⇒ non-trivial** (short PLAN when dispatched).

| Node ID | Audit IDs | Status | Theme | Explicit file scope (from audit) |
|---------|-----------|--------|-------|----------------------------------|
| **D-01** | GDS-001…021 | `TODO` | Remove ticket IDs (`CB-*`) from shipping `##` / comments; replace with durable local intent | explain_graph_view, dock_explain_panel, dock, dock_config, wire_rules_section, explain_menu_ids, wire_rule_shallow_editor, runtime_console_debug, live_graph_protocol, live_graph_transport, graph_node_state_resolver, wire_rule_catalog, dock_live_graph_controller, computed_resource_mounts, wire_graph_edit_service, computed_graph_rebind, explain_graph_layout, explain_graph_builder, wire_rule_stack_catalog, graph_new_binding_service, explain_graph_narrative |
| **D-02** | GDS-022…038 | `TODO` | Add class-level `##` | All listed controls + dock + wiring_panel + live_graph_editor_debugger_plugin + anim_target_helper |
| **D-03** | GDS-039…051 | `TODO` | Export before member vars (script organization) | All UiReact* controls listed in audit |
| **D-04** | GDS-052…059 | `TODO` | Virtual order: `_ready` before `_exit_tree` | button, texture_button, check_box, line_edit, option_button, item_list, tab_container, tree |
| **D-05** | GDS-060…065 | `TODO` | Inner classes last | computed_service, action_target_helper, feedback_target_helper, anim_target_helper, snapshot_store, explain_graph_builder |
| **D-06** | GDS-066…069 | `TODO` | Typed null locals | opacity_color_animations, transform_effects (×2), dock_wire_rules_section |
| **D-07** | GDS-070…076, GDS-090 | `TODO` | Public API `##` on UiState family + wire_rule.apply + compute_bool | ui_state, ui_*_state, ui_react_wire_rule, ui_computed_bool_invert |
| **D-08** | GDS-077…080 | `TODO` | Double-quote tween property paths | opacity/scale/slide/transform anim files |
| **D-09** | GDS-081…088 | `TODO` | Delete restating comments | check_box, line_edit, label, option_button, item_list, slider, progress_bar, opacity_color_animations |
| **D-10** | GDS-089 | `TODO` | Two blank lines between top-level funcs | `ui_anim_opacity_color_animations.gd` |

**Out of wave (explicit):** bulk 100-char line wrap (audit measured 1261 lines) — schedule only if a later milestone opens a formatting wave; not required to close M-AUDIT correctness.

**PLAN stubs:** create six-field PLANs when a D-* batch is selected for IMPL; keep Approach mechanical (search/replace + organization reorder only).

---

## Full audit triage index

### Confirmed bugs

| Audit ID | Wave item | Severity | Significance | Triviality | Bug class | Doc sync |
|----------|-----------|----------|--------------|------------|-----------|----------|
| BUG-001 | A-04 | High | SIGNIFICANT | non-trivial | Design/Framework | ADR-0001 Accepted |
| BUG-002 | A-05 | High | SIGNIFICANT | non-trivial | Framework | ADR-0002 Accepted |
| BUG-003 | A-05 | High | SIGNIFICANT | non-trivial | Framework | ADR-0002 Accepted |
| BUG-004 | A-05 | High | SIGNIFICANT | non-trivial | Framework | ADR-0002 Accepted |
| BUG-005 | A-01 | High | routine | trivial | Implementation | none |
| BUG-006 | A-02 | High | routine | trivial | Implementation | none |
| BUG-007 | A-03 | High | routine | trivial | Implementation | none |
| BUG-008 | A-06 | High | SIGNIFICANT | non-trivial | Framework | ADR-0003 Accepted |
| BUG-009 | A-07 | High | SIGNIFICANT | non-trivial | Framework | ADR-0003 Accepted |
| BUG-010 | A-08 | High | SIGNIFICANT | non-trivial | Architecture | ADR-0004 Accepted |

### Architecture / pattern

| Audit ID | Wave item | Tier | Significance | Triviality | Doc sync |
|----------|-----------|------|--------------|------------|----------|
| ARCH-001 | A-08 | Preferable | SIGNIFICANT (with BUG-010) | non-trivial | ADR-0004 |
| PAT-001 | A-08 | Hard (pattern Ownership) | SIGNIFICANT | non-trivial | ADR-0004 |

### Test gaps

| Audit IDs | Wave | Status |
|-----------|------|--------|
| TEST-001…018 | B | `TODO` after B-00 (DEC-005 `DONE`) |
| TEST-019…029 | C | after B |

### GDScript

| Audit IDs | Wave batch |
|-----------|------------|
| GDS-001…021 | D-01 |
| GDS-022…038 | D-02 |
| GDS-039…051 | D-03 |
| GDS-052…059 | D-04 |
| GDS-060…065 | D-05 |
| GDS-066…069 | D-06 |
| GDS-070…076, 090 | D-07 |
| GDS-077…080 | D-08 |
| GDS-081…088 | D-09 |
| GDS-089 | D-10 |

---

## Recommended dispatch order

1. ~~User confirms DEC-001…005~~ **DONE** (2026-08-25).
2. ~~IMPL **A-01 → A-02 → A-03**~~ **DONE**
3. ~~For each of **A-04…A-08**: PREFLIGHT → IMPL~~ **DONE**
4. ~~PREFLIGHT → IMPL **B-00**~~ **DONE**; then PLAN/IMPL **B-01…**.
5. Wave C, then Wave D batches.

## Continuous Improvement (proposals only — not applied)

CI-1 / CI-2 from governance kickoff still need explicit user approval before MDC edits.

## Related artifacts

- [Developer Guide](developer-guide.md)
- [ADR index](adr/README.md)
