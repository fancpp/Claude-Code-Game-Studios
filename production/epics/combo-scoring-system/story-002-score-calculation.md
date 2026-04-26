# Story 002: Score Calculation — base points, multiplier, drop bonuses

> **Epic**: combo-scoring-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/combo-scoring-system.md`
**Requirement**: `TR-combo-002` (combo multiplier: combo 0-1=1x, 2=2x, 3=3x, 4=4x, 5+=5x), `TR-combo-003` (score formula), `TR-combo-004` (drop bonuses)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: No dedicated ADR — pure calculation logic per GDD formulas.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `calculate_score(lines: int) -> int`, `SOFT_DROP_POINTS_PER_CELL = 1`, `HARD_DROP_POINTS_PER_CELL = 2`
- Forbidden: Hardcoded magic numbers inline — use named constants
- Guardrail: All arithmetic uses int (no floating point)

---

## Acceptance Criteria

*From GDD combo-scoring-system.md Acceptance Criteria:*

- [ ] **AC-2**: GIVEN combo_counter = 0, **WHEN** a Single (1 line) is cleared, **THEN** score_earned = 100 x 1 x 1 = 100 and combo_counter becomes 1.
- [ ] **AC-3**: GIVEN combo_counter = 2, **WHEN** a Double (2 lines) is cleared, **THEN** score_earned = 300 x 2 x 2 = 1200 and combo_counter becomes 3.
- [ ] **AC-4** (partial): GIVEN combo_counter = 4, **WHEN** a Tetris (4 lines) is cleared, **THEN** score_earned = 800 x 4 x 4 = 12800 and combo_counter becomes 5.
- [ ] **AC-5**: GIVEN combo_counter = 100 (or any value > 5), **WHEN** a line is cleared, **THEN** combo_multiplier = 5 (capped) and score uses 5x multiplier.
- [ ] **AC-7**: GIVEN hard drop of 10 cells, **WHEN** piece locks, **THEN** hard_drop_score = 10 x 2 = 20 added to total.

---

## Implementation Notes

*From GDD Formulas section:*

```gdscript
# combo_scoring.gd — additional fields and methods

const MAX_COMBO_MULTIPLIER := 5
const SOFT_DROP_POINTS_PER_CELL := 1
const HARD_DROP_POINTS_PER_CELL := 2

const BASE_POINTS: Array[int] = [0, 100, 300, 500, 800]  # index = line count

# Combo multiplier calculation
func _get_combo_multiplier(counter: int) -> int:
    return mini(counter, MAX_COMBO_MULTIPLIER)  # capped at 5

# Score per clear event
func _calculate_line_score(lines: int, combo_counter: int) -> int:
    var base := BASE_POINTS[lines]  # 100/300/500/800
    var multiplier := _get_combo_multiplier(combo_counter)
    return base * lines * multiplier

# Called when lines_cleared(count) fires
func _on_lines_cleared(count: int) -> void:
    if count > 0:
        var earned := _calculate_line_score(count, combo_counter)
        total_score += earned
        combo_counter += 1  # increment AFTER score calculation uses current counter value
        combo_counter_changed.emit(combo_counter)

# Drop bonus accumulation
func add_soft_drop_score(distance: int) -> void:
    total_score += distance * SOFT_DROP_POINTS_PER_CELL

func add_hard_drop_score(distance: int) -> void:
    total_score += distance * HARD_DROP_POINTS_PER_CELL
```

**Score formula key properties**:
- `base_points[lines]` is the base per clear type (100/300/500/800)
- Score = `base_points[lines] * lines * combo_multiplier`
- Tetris at combo 4: 800 * 4 * 4 = 12800 (AC-4)
- Multiplier is derived from combo_counter BEFORE increment for that clear

**Drop bonuses**: Soft drop and hard drop scores are added to total_score separately from line clear scores. Both can apply in the same piece lock event.

---

## Out of Scope

- Combo counter increment/reset (Story 001)
- Signal emission to downstream (Story 003)

---

## QA Test Cases

**AC-2**: Single at combo 0 = 100 points
- Given: `combo_counter = 0`, `total_score = 0`
- When: `_on_lines_cleared(1)` is called
- Then: `total_score == 100` and `combo_counter == 1`
- Edge cases: combo 1 also gives 1x multiplier (100 * 1 * 1 = 100)

**AC-3**: Double at combo 2 = 1200 points
- Given: `combo_counter = 2`, `total_score = 0`
- When: `_on_lines_cleared(2)` is called
- Then: `total_score == 1200` and `combo_counter == 3`
- Edge cases: Double at combo 0 (100 * 2 * 1 = 200), Double at combo 5 (300 * 2 * 5 = 3000)

**AC-4**: Tetris at combo 4 = 12800
- Given: `combo_counter = 4`, `total_score = 0`
- When: `_on_lines_cleared(4)` is called
- Then: `total_score == 12800` and `combo_counter == 5`
- Edge cases: Tetris at combo 5 (800 * 4 * 5 = 16000, multiplier capped at 5)

**AC-5**: Combo 100+ uses multiplier 5x
- Given: `combo_counter = 100`, `total_score = 0`
- When: `_on_lines_cleared(1)` is called
- Then: multiplier == 5 (not 100), score == 100 * 1 * 5 = 500

**AC-7**: Hard drop 10 cells = 20 points
- Given: `total_score = 0`
- When: `add_hard_drop_score(10)` is called
- Then: `total_score == 20`
- Edge cases: soft drop (1pt/cell), 0 distance (no change)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combo_scoring/score_calculation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

**Dependencies**: combo-scoring-system story-001, line-clear-system stories