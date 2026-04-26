# Story 001: Core Grid API — get_cell, set_cell, is_empty, clear_grid

> **Epic**: grid-system
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/grid-system.md`
**Requirement**: `TR-grid-002` (10×20 cell grid, column-major access), `TR-grid-003` (cell states: Empty/Mino/Hint)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-001: Grid Resource Pattern
**ADR Decision Summary**: Grid is a `class_name Grid extends RefCounted` with `get_cell`, `set_cell`, `is_empty`, `is_valid_position`, `clear_grid` API. One instance on main.tscn root, injected via `@export var grid: Grid`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript class — no engine API surface. ADR-001 explicitly states no post-cutoff APIs.

**Control Manifest Rules (Foundation layer)**:
- Required: `class_name Grid extends RefCounted`, Grid API: `get_cell`, `set_cell`, `is_empty`, `is_valid_position`, `clear_grid`
- Forbidden: No Autoload, no `get_node()` for grid access
- Guardrail: Grid memory <1KB

---

## Acceptance Criteria

*From GDD grid-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN a fresh grid, WHEN `get_cell(0, 0)` is called, THEN it returns 0 (EMPTY).
- [ ] **AC-2**: GIVEN a grid with cell (5, 5) set to OCCUPIED (value 1-7), WHEN `get_cell(5, 5)` is called, THEN it returns the tetromino type (1-7).
- [ ] **AC-3**: GIVEN a fresh grid, WHEN `clear_grid()` is called, THEN all 200 cells return 0 (EMPTY).
- [ ] **AC-4**: GIVEN a fresh grid, WHEN `is_empty(3, 5)` is called, THEN it returns true.
- [ ] **AC-5**: GIVEN cell (3, 5) is OCCUPIED (set via `set_cell(3, 5, 3)`), WHEN `is_empty(3, 5)` is called, THEN it returns false.
- [ ] **AC-6**: GIVEN cell (3, 5) is OCCUPIED, WHEN `set_cell(3, 5, 0)` is called, THEN `get_cell(3, 5)` returns 0 and `is_empty(3, 5)` returns true.
- [ ] **AC-7**: GIVEN grid uses column-major 2D array `cells[y][x]` (row = y, column = x), THEN `get_cell(x, y)` returns `cells[y][x]`.

---

## Implementation Notes

*From ADR-ARCH-001 Decision section:*

```gdscript
class_name Grid
extends RefCounted

var cells: Array  # 10×20, cells[y][x], 0=EMPTY, 1-7=tetromino type

func _init() -> void:
    cells = []
    for i in range(20):
        cells.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

func get_cell(x: int, y: int) -> int:
    return cells[y][x]

func set_cell(x: int, y: int, value: int) -> void:
    cells[y][x] = value

func is_empty(x: int, y: int) -> bool:
    return cells[y][x] == 0

func clear_grid() -> void:
    for y in range(20):
        for x in range(10):
            cells[y][x] = 0
```

- Place the Grid class in `src/grid/grid.gd`
- No `@export`, no Node lifecycle methods (`_ready`, `_process`)
- Pure data class — testable by instantiating `Grid.new()` directly

---

## Out of Scope

*Handled by neighbouring stories:*
- Story 002: `is_valid_position` boundary checks (separate story per GDD acceptance criteria grouping)
- Story 003: Grid instantiation on main.gd root node and wiring to all children

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: Fresh grid, get_cell(0,0) returns 0
- Given: A freshly instantiated Grid via `Grid.new()`
- When: `grid.get_cell(0, 0)` is called
- Then: Return value equals 0 (EMPTY constant)
- Edge cases: Also verify `get_cell(9, 19)` returns 0 (opposite corner)

**AC-2**: Occupied cell returns tetromino type
- Given: A Grid with cell (5,5) set via `grid.set_cell(5, 5, 3)`
- When: `grid.get_cell(5, 5)` is called
- Then: Return value equals 3
- Edge cases: Values 1-7 all returned correctly; value 0 (EMPTY) distinguishable from unset

**AC-3**: clear_grid() resets all 200 cells
- Given: A Grid with multiple cells set to non-zero values via `set_cell` calls
- When: `grid.clear_grid()` is called
- Then: Every cell `get_cell(x, y)` for x in 0-9, y in 0-19 returns 0
- Edge cases: Boundary cells (0,0), (9,19) specifically verified; clear called twice in a row is idempotent

**AC-4 / AC-5**: is_empty true/false
- Given: A fresh Grid (AC-4) / A Grid with cell (3,5) set to value 3 (AC-5)
- When: `grid.is_empty(3, 5)` is called
- Then: AC-4 returns true, AC-5 returns false
- Edge cases: is_empty on (0,0) also true on fresh grid

**AC-6**: set_cell to 0 clears cell
- Given: A Grid with cell (3,5) set to value 3
- When: `grid.set_cell(3, 5, 0)` is called, then `grid.get_cell(3,5)` and `grid.is_empty(3,5)`
- Then: get_cell returns 0, is_empty returns true
- Edge cases: Overwriting a non-zero with another non-zero value (e.g., set_cell(3,5,5))

**AC-7**: Column-major array access (cells[y][x])
- Given: A fresh Grid
- When: `grid.set_cell(3, 5, 7)` is called
- Then: `grid.get_cell(3, 5)` returns 7 and `grid.cells[5][3]` equals 7 (array access matches API)
- Edge cases: Verify `cells` is not a flat 200-element array — it must be 2D (20 rows × 10 columns)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/grid/grid_api_test.gd` — must exist and pass

**Status**: [ ] Not yet created