# Story 003: Combo Signals — score_changed, combo_changed, combo_x5 emission

> **Epic**: combo-scoring-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/combo-scoring-system.md`
**Requirement**: `TR-combo-005` (signals emitted: score_changed(new_score), combo_changed(counter, multiplier), combo_x5)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-002 (Signal Bus) — all combo_scoring outputs are signals on the signal bus.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `score_changed(new_score: int)`, `combo_changed(counter: int, multiplier: int)`, `combo_x5` signals declared
- Forbidden: No polling — downstream systems receive updates via signal subscriptions only
- Guardrail: `combo_x5` fires only the FIRST time combo reaches 5 (not on subsequent clears at 5+)

---

## Acceptance Criteria

*From GDD combo-scoring-system.md Acceptance Criteria (all signals):*

- [ ] **AC-signals-1**: GIVEN combo reaches 5 for the first time, **WHEN** the line clear occurs, **THEN** `combo_x5` signal is emitted (distinct chime for audio).
- [ ] **AC-signals-2**: GIVEN `score_changed(new_score)` is emitted, **WHEN** downstream (score_display) receives it, **THEN** score label updates to new formatted value.
- [ ] **AC-signals-3**: GIVEN `combo_changed(counter, multiplier)` is emitted, **WHEN** downstream (score_display) receives it, **THEN** combo label shows "xN" when counter > 0 or hides when counter = 0.

---

## Implementation Notes

*From GDD Signals section and ADR-ARCH-002:*

```gdscript
# combo_scoring.gd — signal declarations
class_name ComboScoring
extends Node

signal score_changed(new_score: int)
signal combo_changed(counter: int, multiplier: int)
signal combo_x5  # no payload — fires when multiplier first reaches 5

var _has_reached_x5_this_game: bool = false  # reset on new_game

func _on_lines_cleared(count: int) -> void:
    if count > 0:
        var old_multiplier := _get_combo_multiplier(combo_counter)
        var earned := _calculate_line_score(count, combo_counter)
        total_score += earned
        combo_counter += 1

        var new_multiplier := _get_combo_multiplier(combo_counter)

        score_changed.emit(total_score)
        combo_changed.emit(combo_counter, new_multiplier)

        # Fire combo_x5 only the first time multiplier reaches 5
        if new_multiplier == 5 and not _has_reached_x5_this_game:
            _has_reached_x5_this_game = true
            combo_x5.emit()

func _on_new_game() -> void:
    _has_reached_x5_this_game = false
    # ... (reset handled in story 001)
```

**`combo_x5` one-shot rule**: Once the player has achieved a ×5 combo, `combo_x5` does not fire again in that game even if the combo briefly drops and returns to 5. This is tracked by `_has_reached_x5_this_game`.

**Signal payload precision**:
- `score_changed(new_score: int)` — the full accumulated total
- `combo_changed(counter: int, multiplier: int)` — both current counter (0+) and capped multiplier (1-5)
- `combo_x5` — no payload, just the signal

---

## Out of Scope

- Combo counter and score calculation logic (Stories 001, 002)
- Downstream system behavior (score_display.gd handles its own label updates)

---

## QA Test Cases

**AC-signals-1**: combo_x5 fires once on first reach of 5
- Given: `combo_counter = 4` in a fresh game (`_has_reached_x5_this_game = false`)
- When: `_on_lines_cleared(1)` is called (clears 1 line, pushing combo to 5)
- Then: `combo_x5` signal fires exactly once
- And: If player drops to combo 3 then reaches 5 again, `combo_x5` does NOT fire again
- Edge cases: combo already at 5 from previous game (should fire on first clear after new_game reset)

**AC-signals-2**: score_changed emits correct total
- Given: `total_score = 500`, combo counter triggers another clear
- When: `_on_lines_cleared(1)` is called, adding 100 to total
- Then: `score_changed(600)` is emitted (not 100 or any other value)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/combo_scoring/combo_signals_test.gd` — must exist and pass

**Status**: [ ] Not yet created

**Dependencies**: combo-scoring-system story-001, combo-scoring-system story-002, line-clear-system stories