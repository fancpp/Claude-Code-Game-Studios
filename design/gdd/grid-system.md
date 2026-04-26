# Grid System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

---

## Overview

The Grid System is the foundational data structure of the game: a 10×20 two-dimensional array where each cell stores either empty or a tetromino block type. It provides the authoritative spatial reference for all gameplay — every piece placement, collision check, and line clear operates on grid coordinates. The grid is read-only for most systems; only the Tetromino System and Line Clearing System modify it.

## Player Fantasy

"The grid is invisible — it simply IS." The player doesn't think about the underlying data structure; they see perfect piece alignment, crisp edges, and predictable behavior. When they rotate a piece against the wall and it fits exactly as expected, that's the grid working. The grid's precision creates the player's sense of mastery — every successful placement validates their control.

## Detailed Design

### Core Rules

**Grid Dimensions:**
- Width: 10 columns (X = 0 to 9, left to right)
- Height: 20 rows (Y = 0 to 19, bottom to top)
- Coordinate system: Origin (0,0) at bottom-left corner

**Cell Data Structure:**
- Each cell stores one of two states: `EMPTY` (0) or `OCCUPIED` (tetromino type 1-7)
- 2D array indexed as `grid[Y][X]` — row-major order
- Total cells: 200 (10 × 20)

**Cell Access API:**
- `get_cell(x: int, y: int) -> int` — Returns 0 (empty) or 1-7 (tetromino type)
- `set_cell(x: int, y: int, value: int) -> void`
- `is_empty(x: int, y: int) -> bool`
- `is_valid_position(x: int, y: int) -> bool`

**Boundary Rules:**
- X valid range: 0 to 9
- Y valid range: 0 to 19
- Any access outside bounds returns INVALID — systems must check bounds first

**Clearing:**
- `clear_grid()` — Resets all cells to EMPTY. Called on new game.

### States and Transitions

| State | Description |
|-------|-------------|
| EMPTY | Cell is unoccupied — piece can pass through |
| OCCUPIED | Cell contains a locked block — collision required |

No transitions exist within the Grid System itself — it is a passive data store. Transitions (piece locking, line clearing) are initiated by other systems.

### Interactions with Other Systems

| System | Interface | Direction |
|--------|-----------|-----------|
| Collision System | `is_valid_position(x, y)` | Grid → Collision |
| Tetromino System | `get_cell`, `set_cell` | Grid ↔ Tetromino |
| Ghost Piece System | `is_empty(x, y)` | Grid → Ghost |
| Line Clearing System | `set_cell` (row clear) | Grid ← Line Clearing |

## Formulas

### Grid-to-Pixel Coordinate Conversion

The grid uses cell coordinates; rendering uses pixel coordinates. Cell size is 32 pixels at 1x scale.

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Cell X | x | int | 0-9 | Grid column |
| Cell Y | y | int | 0-19 | Grid row |
| Cell Size | C | int | 32 (fixed) | Pixels per cell |

**Formulas:**
```
pixel_x = x * C
pixel_y = y * C
```

**Example:** Cell (3, 5) → Pixel (96, 160)

**Output Range:** pixel_x: 0-288, pixel_y: 0-608

## Edge Cases

- **If `get_cell(x, y)` is called with x < 0 or x > 9**: Return -1 (invalid). Caller must check bounds first.
- **If `get_cell(x, y)` is called with y < 0 or y > 19**: Return -1 (invalid).
- **If `set_cell(x, y, value)` is called with invalid coordinates**: No-op. Log warning.
- **If `set_cell` is called on an already-occupied cell**: Overwrite the existing value (no merge needed — piece locks in place).

## Dependencies

**Upstream Dependencies (none):**
This system has no dependencies. It is the foundation upon which all other systems are built.

**Downstream Dependents:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Collision System | `is_valid_position(x, y)` | Queries grid to check if a position is empty and within bounds |
| Tetromino System | `get_cell`, `set_cell` | Reads grid to check collisions; writes locked pieces |
| Ghost Piece System | `is_empty(x, y)` | Queries grid to calculate ghost piece position |
| Line Clearing System | `set_cell` (row clear) | Sets entire row to EMPTY when lines are cleared |

**Hard vs. Soft:**
- All dependencies are **HARD** — these systems cannot function without the Grid System

## Tuning Knobs

**Grid dimensions are fixed constants — not tunable at runtime:**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| GRID_WIDTH | 10 | Standard Tetris width |
| GRID_HEIGHT | 20 | Standard Tetris height |
| CELL_SIZE | 32 | Art bible specification |

These are compile-time constants in GDScript. Changing them requires code changes and is not part of normal development tuning.

## Acceptance Criteria

- **GIVEN** a fresh grid, **WHEN** `get_cell(0, 0)` is called, **THEN** it returns 0 (EMPTY).
- **GIVEN** a grid with cell (5, 5) set to OCCUPIED, **WHEN** `get_cell(5, 5)` is called, **THEN** it returns the tetromino type (1-7).
- **GIVEN** a fresh grid, **WHEN** `clear_grid()` is called, **THEN** all 200 cells return 0 (EMPTY).
- **GIVEN** any coordinates, **WHEN** `is_valid_position(-1, 5)` is called, **THEN** it returns false.
- **GIVEN** any coordinates, **WHEN** `is_valid_position(10, 5)` is called, **THEN** it returns false.
- **GIVEN** valid coordinates (0-9, 0-19), **WHEN** `is_valid_position(x, y)` is called, **THEN** it returns true.
- **GIVEN** cell (3, 5) is OCCUPIED, **WHEN** `set_cell(3, 5, 0)` is called, **THEN** `get_cell(3, 5)` returns 0.

## Open Questions

[To be designed]