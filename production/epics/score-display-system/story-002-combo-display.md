# Story 002: Combo Display — "xN" label visible when combo>0, hidden when 0

> **Epic**: score-display-system
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/score-display-system.md`
**Requirement**: `TR-score-002` (combo: "xN" when combo>0, hidden when 0)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-009 (Score Display) — `combo_changed(counter, multiplier)` signal handler controls `combo_label.visible`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Presentation layer)**:
- Required: `combo_label` as `Label` child, `combo_label.visible = false` when counter == 0
- Forbidden: Never show "x0" — label hidden when combo counter is 0
- Guardrail: `combo_changed(counter, multiplier)` — counter is raw counter, multiplier is capped (1-5)

---

## Acceptance Criteria

*From GDD score-display-system.md Acceptance Criteria:*

- [ ] **AC-3**: GIVEN combo_counter = 0, **WHEN** HUD is rendered, **THEN** combo display is hidden.
- [ ] **AC-4**: GIVEN combo_counter = 3, **WHEN** HUD is rendered, **THEN** combo display shows "x3".
- [ ] **AC-6** (combo part): GIVEN new game starts, **WHEN** HUD is rendered, **THEN** combo is hidden.
- [ ] **AC-7** (combo part): GIVEN game is paused, **WHEN** HUD continues to be rendered, **THEN** combo display remains in last state (no change needed).

---

## Implementation Notes

*From ADR-ARCH-009:*

```gdscript
# score_display.gd — combo display addition
const COMBO_VISIBLE_THRESHOLD := 1  # show when counter >= 1

var _displayed_combo: int = 0

func _ready() -> void:
    combo_scoring.combo_changed.connect(_on_combo_changed)
    # ... other connections

func _on_combo_changed(new_combo: int, new_multiplier: int) -> void:
    _displayed_combo = new_combo
    if _displayed_combo >= COMBO_VISIBLE_THRESHOLD:
        combo_label.text = "x%d" % _displayed_combo
        combo_label.visible = true
    else:
        combo_label.visible = false

func _on_new_game() -> void:
    # ... (from story 001)
    _displayed_combo = 0
    combo_label.visible = false
```

**Why `_displayed_combo` is the counter, not the multiplier**: The GDD says combo display shows "xN" where N is the combo counter. `combo_changed(counter, multiplier)` receives both. We display `counter` as the "xN" value.

**Zero state**: `combo_label.visible = false` set BEFORE any text update to avoid flash of "x0" on reset.

**New game reset**: `combo_label.visible = false` in `_on_new_game()`.

---

## Out of Scope

- Score and level display (Story 001)
- The `combo_x5` special glow effect (handled in visual-feedback-system)

---

## QA Test Cases

**AC-3**: Combo 0 = hidden
- Given: `combo_changed(0, 1)` signal received (combo reset to 0)
- When: `_on_combo_changed(0, 1)` runs
- Then: `combo_label.visible == false`
- Edge cases: Rapid transition from combo 5 to 0 (no flash of "x0")

**AC-4**: Combo 3 = "x3"
- Given: `combo_changed(3, 3)` signal received
- When: `_on_combo_changed(3, 3)` runs
- Then: `combo_label.text == "x3"` and `combo_label.visible == true`
- Edge cases: Combo 1 ("x1"), combo 5 ("x5")

**AC-6**: New game hides combo
- Given: Combo is showing "x5"
- When: `new_game` signal fires
- Then: `combo_label.visible == false`

---

## Test Evidence

**Story Type**: UI
**Required evidence**: Manual walkthrough doc OR interaction test at `production/qa/evidence/combo-display-*.md`

**Status**: [ ] Not yet created

**Dependencies**: combo-scoring-system stories (001-003)