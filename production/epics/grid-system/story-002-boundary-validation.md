# Story 002: Boundary Validation — is_valid_position, out-of-bounds

> **Epic**: grid-system
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/grid-system.md`
**Requirement**: `TR-grid-002` (10×20 cell grid), `TR-grid-003` (cell states)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-001: Grid Resource Pattern
**ADR Decision Summary**: Grid is a `class_name Grid extends RefCounted` with `is_valid_position(x, y)` that returns false for out-of-bounds coordinates.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript class — no engine API surface.

**Control Manifest Rules (Foundation layer)**:
- Required: `is_valid_position(x, y)` returns false outside bounds; `get_cell` returns -1 for invalid coordinates
- Forbidden: No Autoload, no `get_node()` for grid access
- Guardrail: Grid memory <1KB

---

## Acceptance Criteria

*From GDD grid-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN any coordinates, WHEN `is_valid_position(-1, 5)` is called, THEN it returns false.
- [ ] **AC-2**: GIVEN any coordinates, WHEN `is_valid_position(10, 5)` is called, THEN it returns false.
- [ ] **AC-3**: GIVEN valid coordinates (0-9, 0-19), WHEN `is_valid_position(x, y)` is called, THEN it returns true for all x in [0,9] and y in [0,19].
- [ ] **AC-4**: GIVEN grid dimensions are GRID_WIDTH=10, GRID_HEIGHT=20 (constants), WHEN coordinates at exactly (9, 19) are validated, THEN true; at (10, 19) or (9, 20) THEN false.

---

## Implementation Notes

*From GDD grid-system.md Detailed Design and Edge Cases:*

```gdscript
const GRID_WIDTH: int = 10
const GRID_HEIGHT: int = 20

func is_valid_position(x: int, y: int) -> bool:
    return x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT
```

**Edge case handling** (from GDD Edge Cases):
- `get_cell(x, y)` with x < 0 or x > 9: Return -1 (invalid)
- `get_cell(x, y)` with y < 0 or y > 19: Return -1 (invalid)
- `set_cell(x, y, value)` with invalid coordinates: No-op, log warning

**Implementation must:**
1. Define `GRID_WIDTH = 10` and `GRID_HEIGHT = 20` as module-level constants
2. `is_valid_position` uses `x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT`
3. `get_cell` checks `is_valid_position` first — if false, return -1 immediately
4. `set_cell` checks `is_valid_position` first — if false, log warning and return without modifying

---

## Out of Scope

*Handled by neighbouring stories:*
- Story 001: `get_cell`, `set_cell`, `is_empty`, `clear_grid` core API
- Story 003: Grid instantiation on main.gd root node and wiring to all children

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1 / AC-2**: is_valid_position rejects out-of-bounds X
- Given: A fresh Grid via `Grid.new()`
- When: `grid.is_valid_position(-1, 5)` is called
- Then: Returns false
- And when: `grid.is_valid_position(10, 5)` is called
- Then: Returns false
- Edge cases: -1, 10, 11 all return false; 0 and 9 return true

**AC-3**: is_valid_position accepts all valid coordinates
- Given: A fresh Grid
- When: `is_valid_position(x, y)` is called for all x in range(0, 10) and y in range(0, 20)
- Then: Every call returns true
- Edge cases: Specifically test (0,0), (9,0), (0,19), (9,19) — all four corners

**AC-4**: Boundary edge cases at exact limits
- Given: A fresh Grid with constants GRID_WIDTH=10, GRID_HEIGHT=20
- When:
  - `is_valid_position(9, 19)` → should return true (last valid cell)
  - `is_valid_position(10, 19)` → should return false (x at limit)
  - `is_valid_position(9, 20)` → should return false (y at limit)
  - `is_valid_position(10, 20)` → should return false (both at limit)
- Then: Results match the expected booleans above
- Edge cases: Negative values on both axes simultaneously (-1, -1) returns false

**get_cell returns -1 for invalid coordinates**:
- Given: A fresh Grid
- When: `grid.get_cell(-1, 5)` is called
- Then: Returns -1 (not 0, not a crash)
- And when: `grid.get_cell(10, 5)` is called
- Then: Returns -1
- Edge cases: get_cell(-1, -1), get_cell(10, 20) all return -1

**set_cell no-ops for invalid coordinates**:
- Given: A fresh Grid, capture grid state before
- When: `grid.set_cell(-1, 5, 3)` is called
- Then: No modification occurs — all cells remain 0 (no crash, no exception)
- And when: `grid.set_cell(10, 5, 3)` is called
- Then: No modification occurs
- Edge cases: set_cell(-1, -1), set_cell(10, 20) no-op; valid set_cell afterward still works

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/grid/boundary_test.gd` — must exist and pass

**Status**: [ ] Not yet created