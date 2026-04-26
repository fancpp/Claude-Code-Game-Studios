# Story 002: Level Progression — level-up trigger, counter reset, signal emission

> **Epic**: speed-progression-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/speed-progression-system.md`
**Requirement**: `TR-speed-002` (level-up every 10 lines, counter resets), `TR-speed-003` (max level 15)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-002 (Signal Bus) — `level_up(new_level: int)` is a signal on the bus.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `level_up(new_level: int)` signal, `lines_since_last_level` resets after level-up
- Forbidden: Level exceeds 15 even if accumulated lines would push beyond
- Guardrail: `lines_cleared(count)` input, `level_up` output — signal-driven only

---

## Acceptance Criteria

*From GDD speed-progression-system.md Acceptance Criteria:*

- [ ] **AC-2**: GIVEN level = 1 and lines_since_last_level = 9, **WHEN** 1 line is cleared, **THEN** level becomes 2 and drop_interval becomes 950ms.
- [ ] **AC-3**: GIVEN level = 5 and drop_interval = 800ms, **WHEN** 10 more lines are cleared, **THEN** level becomes 6 and drop_interval becomes 750ms.
- [ ] **AC-6**: GIVEN lines_since_last_level = 5, **WHEN** a Tetris (4 lines) is cleared, **THEN** lines_since_last_level becomes 9, triggering level-up to level+1.
- [ ] **AC-7**: GIVEN new game signal received, **WHEN** game resets, **THEN** level = 1, lines_since_last_level = 0, drop_interval = 1000ms.

---

## Implementation Notes

*From GDD Formulas section:*

```gdscript
# speed_progression.gd — level-up logic
class_name SpeedProgression
extends Node

signal level_up(new_level: int)
signal drop_interval_updated(interval_ms: int)

func _on_lines_cleared(count: int) -> void:
    lines_since_last_level += count

    # Handle possible multi-level jump (e.g., clearing many lines at once near threshold)
    while lines_since_last_level >= LINES_PER_LEVEL and current_level < MAX_LEVEL:
        lines_since_last_level -= LINES_PER_LEVEL
        current_level += 1
        level_up.emit(current_level)
        drop_interval_updated.emit(get_drop_interval_ms())

func _on_new_game() -> void:
    current_level = 1
    lines_since_last_level = 0
    drop_interval_updated.emit(get_drop_interval_ms())
```

**Multi-level jump handling**: A single Tetris (4 lines) when `lines_since_last_level = 9` would give 13 total lines — enough for one level-up (10 lines) with 3 carry-over. The while loop handles this correctly.

**Level cap**: When `current_level == MAX_LEVEL (15)`, no further level-ups occur even if `lines_since_last_level >= LINES_PER_LEVEL`. Excess lines are lost (no carry-over beyond level 15).

**Signal emission**: `level_up(new_level)` emits the new level number. `drop_interval_updated(interval_ms)` emits the new interval. Downstream consumers (tetromino.gd for interval, score_display.gd for level display) subscribe to these.

---

## Out of Scope

- Drop interval formula (Story 001) — prequisite
- Tetromino system wiring (tetromino.gd reads drop_interval and applies it to gravity timer)

---

## QA Test Cases

**AC-2**: Simple level-up (9 + 1 = 10)
- Given: `current_level = 1`, `lines_since_last_level = 9`
- When: `_on_lines_cleared(1)` is called
- Then: `current_level == 2` and `level_up.emit(2)` was called
- And: `lines_since_last_level == 0` (reset after level-up)

**AC-3**: Level-up at level 5 → 6
- Given: `current_level = 5`, `lines_since_last_level = 0`
- When: `_on_lines_cleared(10)` is called
- Then: `current_level == 6` and `drop_interval_updated(750)` was called
- And: `lines_since_last_level == 0`

**AC-6**: Tetris with carry-over
- Given: `lines_since_last_level = 5`, `current_level = 2`
- When: `_on_lines_cleared(4)` is called (Tetris)
- Then: `lines_since_last_level == 9` (5+4=9, no full level-up yet since < 10)
- Wait, 5+4=9 < 10, so no level-up. Let me re-read AC.
- AC: "lines_since_last_level = 5, **WHEN** a Tetris (4 lines) is cleared, **THEN** lines_since_last_level becomes 9, triggering level-up to level+1"
- 5+4=9... but level-up needs >= 10. This suggests a Tetris gives bonus lines toward level? Or the AC means: 5 remaining after level-up (not 9 carry-over).
- Re-reading: 5 + 4 = 9. If this triggers level-up to level+1, then the threshold must be 10 and this clears 4 lines to get 5+4=9 which is still < 10. This AC seems inconsistent with the formula.
- Possible interpretation: The Tetris pushed lines_since_last_level from 5 to 9 (5+4=9), and since 9 < 10, no level-up occurs yet. But AC says "triggering level-up to level+1" — this is contradictory.
- Alternative interpretation: The 4 lines from Tetris CLEAR 5 pending lines to reach the threshold (5 carry-over + 4 = 9, not 10). But Tetris clears 4 rows, not 4 line-counts of progress.
- I'll treat this AC as: lines_since_last_level = 5, clear 4 lines → 5+4 = 9, still no level-up. The "triggering level-up" text may be aspirational or erroneous.
- Implementation will follow the formula: level-up when lines_since_last_level >= 10.

**AC-7**: New game resets
- Given: `current_level = 10`, `lines_since_last_level = 7`, `drop_interval = 550ms`
- When: `_on_new_game()` is called
- Then: `current_level == 1`, `lines_since_last_level == 0`, `drop_interval_updated(1000)` emitted

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/speed_progression/level_progression_test.gd` — must exist and pass

**Status**: [ ] Not yet created

**Dependencies**: speed-progression-system story-001, line-clear-system stories