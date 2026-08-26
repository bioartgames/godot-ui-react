# Ui React — Developer Guide (as-built)

**Assumption:** This repository is the **portable `ui_react` addon**, not a full game. Gameplay GDD lives outside this repo; this guide describes the **implemented** addon surface so a new developer is not misled.

For product intent, examples, and the long-form control matrix, prefer `addons/ui_react/README.md`. Normative layer docs referenced there (`WIRING_LAYER.md`, `ACTION_LAYER.md`, etc.) may be incomplete or missing in-tree; treat README + this guide + source `##` docs as the current as-built chain until those files exist.

---

## 1. What the system is

**Ui React** provides Godot 4.x **Control** subclasses (`UiReact*`) that bind to typed **`UiState`** Resources for two-way sync, plus optional Inspector-authored:

| Layer | Resources / helpers | Role |
|--------|---------------------|------|
| Binding | `UiBoolState`, `UiIntState`, `UiFloatState`, `UiStringState`, `UiArrayState`, `UiTransactionalState` | Payload + `value_changed` |
| Computed | `UiComputed*`, `UiReactComputedService` | Derive from `sources[]` |
| Wiring | `UiReactWireRule*`, `UiReactWireRuleHelper`, `UiReactHostWireTree` | When X changes, update Y |
| Actions | `UiReactActionTarget`, `UiReactActionTargetHelper`, `UiReactStateOpService` | Focus, visibility, bounded ops |
| Feedback | `audio_targets` / `haptic_targets` helpers | One-shot audio / rumble |
| Animation | `UiAnimTarget`, `UiAnimUtils` | Inspector or code tweens |
| Transactional | `UiTransactionalGroup`, `UiReactTransactionalHostBinding`, `UiReactTransactionalSession` | Draft / Apply / Cancel |

**Lifecycle (typical control):** `_enter_tree` may schedule wire attach → `_ready` connects control signals + `UiReactControlStateWire.bind_value_changed` → deferred `_finish_initialization` clears the two-way init guard → `_exit_tree` / `PREDELETE` teardown unbinds and detaches wires.

**Editor:** `addons/ui_react/editor_plugin/` — bottom dock **Diagnostics** + **Graph** (dependency snapshot, wire list, live debug ingest). Enabled via `plugin.cfg`; not an Autoload.

---

## 2. Adjacent systems

- **Host game / demo** owns scene tree, domain data, and anything outside the four pillars.
- **Godot Control / BaseButton / ItemList / Tree / TabContainer** own native input and selection; Ui React mirrors them into `UiState` — do not invent a parallel input stack.
- **No project Autoload** is required for core binding; computed/wire helpers use static session tables (see `UiReactComputedService` docs for test-only reset).

---

## 3. How to use (do / don’t)

**Do**

- Assign typed state Resources on the control’s `*_state` exports (or `UiState` where the export allows transactional/computed shapes).
- Prefer Inspector / Graph edits that write the same `.tscn` / `.tres` shapes official examples use.
- Mutate payloads through `set_value` / `set_silent` / typed setters so listeners and `emit_changed` run.

**Don’t**

- Treat ticket IDs (`CB-*`) in older comments as architecture authority — traceability belongs in ADR / DAG / this guide / git (`godot-gdscript.mdc`).
- Assume shared `.tres` Resources are safe to mutate as per-instance runtime state (Prototype vs Instance).
- Mutate `UiArrayState` through a getter result — getters return copies; use setters so `value_changed` fires (ADR-0003).
- Expect two runtime `UiReactTabContainer` hosts to share mutable `tab_config` instance state — cfg is localized per host at runtime (ADR-0004).

---

## 4. Common situations

| Situation | Where to look |
|-----------|----------------|
| Toggle / checkbox sync | `UiReactCheckBox` + `UiBoolState` |
| Non-toggle button + `pressed_state` | `UiReactBaseButtonReactive` — **pulse** (`true` then `false` per press); steady state stays `false` (ADR-0001) |
| Target array validation at ready | Helpers filter invalid rows for **runtime** only; `@export` arrays are **not** rewritten (ADR-0002) |
| Apply / Cancel options sheet | `UiTransactionalGroup` + `transactional_host` on Button/TextureButton; nested Array/Dictionary drafts are deep-cloned (ADR-0003) |
| Filter list / selection detail | `wire_rules` on hosts that export them; `UiReactWireRuleHelper` |
| Shop afford / order summary | `UiComputed*` + `UiReactStateOpService` actions |
| Dock false positives / unused `.tres` | Diagnostics tab; Project Settings under `ui_react/settings/` |

---

## 5. Running tests

Contract GUT lives under `res://test/unit/` (outside the shipping addon). GUT is a **dev dependency** — enable it in this repo for contributors/CI; end users only need the Ui React plugin (ADR-0005).

Headless runner (from project root), after GUT is enabled in Project Settings:

```powershell
& "C:\Users\chris\Documents\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

---

## 6. See also

- `addons/ui_react/README.md` — setup, examples, control matrix
- `docs/dag.md` — implementation / audit remediation plan
- `docs/adr/` — accepted architectural decision records
- Examples: `addons/ui_react/examples/*.tscn`
