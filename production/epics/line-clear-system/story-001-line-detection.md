# Story 001: Line Detection — scan grid for complete rows

> **Epic**: line-clear-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/line-clearing-system.md`
**Requirement**: `TR-line-clear-001` (line detection: scan rows bottom-to-top, row complete if all 10 cells occupied)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: No dedicated ADR — uses grid API from ADR-ARCH-001. No new architecture decisions; line detection is a direct application of the Grid API.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `line_clear.gd` as `class_name LineClear extends Node`, `detect_and_clear_lines()` returning `int`
- Forbidden: No Autoload, no direct grid instantiation (grid injected via `@export`)
- Guardrail: Line detection runs after `piece_locked` signal; no inline Tetromino logic

---

## Acceptance Criteria

*From GDD line-clearing-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN a grid where row y=0 has all 10 cells occupied, **WHEN** line clear is checked, **THEN** row y=0 is identified as complete.
- [ ] **AC-2**: GIVEN rows y=3 and y=5 are complete, **WHEN** collapse happens, **THEN** all rows above y=5 shift down by 2 and rows y=3 and y=5 are removed.
- [ ] **AC-3**: GIVEN 4 non-adjacent rows are complete, **WHEN** collapse happens, **THEN** all 4 rows are removed and remaining rows shift down by 4.
- [ ] **AC-4**: GIVEN a row has 9 occupied cells and 1 EMPTY cell, **WHEN** line clear is checked, **THEN** that row is NOT cleared.
- [ ] **AC-5**: GIVEN a piece locks and no rows are complete, **WHEN** line clear check runs, **THEN** no rows are cleared and cleared_count = 0.

*Note: AC-2, AC-3 are about collapse — covered in Story 002. AC-1, AC-4, AC-5 are detection-only.*

---

## Implementation Notes

*From GDD Detailed Design:*

```gdscript
# line_clear.gd
class_name LineClear
extends Node

@export var grid: Grid

# Returns count of cleared lines (0-4)
func detect_and_clear_lines() -> int:
    # Step 1: Scan all rows bottom-to-top, collect complete rows
    var cleared_rows: Array[int] = []
    for y in range(20):  # y=0 is bottom
        var is_complete := true
        for x in range(10):
            if grid.is_empty(x, y):
                is_complete = false
                break
        if is_complete:
            cleared_rows.append(y)

    var count := cleared_rows.size()
    if count == 0:
        return 0

    # Step 2: Collapse rows (handled in story 002)
    # For now, just return the count
    return count
```

- Place `line_clear.gd` in `src/line_clear/line_clear.gd`
- Connect to `tetromino.piece_locked` signal in `_ready()`
- `detect_and_clear_lines()` is the main public API

---

## Out of Scope

- Row collapse (Story 002)
- Signal emission to downstream (Story 003)
- Visual effects during line clear

---

## QA Test Cases

**AC-1**: Complete row at y=0 detected
- Given: Grid with all 10 cells at y=0 occupied via `grid.set_cell(x, 0, 1)` for x in 0-9
- When: `line_clear.detect_and_clear_lines()` is called (collapse step skipped)
- Then: Row y=0 is in the cleared rows list
- Edge cases: Row y=19 (top), non-adjacent complete rows

**AC-4**: Row with 1 EMPTY cell NOT cleared
- Given: Grid with row y=5 where 9 cells are occupied but cell (3, 5) is EMPTY
- When: `line_clear.detect_and_clear_lines()` is called
- Then: Row y=5 is NOT in the cleared rows list
- Edge cases: 2 EMPTY cells, EMPTY in different column positions

**AC-5**: No complete rows returns 0
- Given: A grid with no complete rows (e.g., a freshly cleared grid or scattered pieces)
- When: `line_clear.detect_and_clear_lines()` is called
- Then: Return value equals 0

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/line_clear/line_detection_test.gd` — must exist and pass

**Status**: [ ] Not yet created