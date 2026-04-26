# Story 001: Ghost Calculation — ray-cast down to find drop destination

> **Epic**: ghost-piece-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/ghost-piece-system.md`
**Requirement**: `TR-ghost-001` (ghost calculation: ray-cast down from current position until collision, returns ghost_y)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: No dedicated ADR — pure calculation using grid `is_empty()` and collision `can_move_to()` APIs.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `calculate_ghost_y(piece_x: int, piece_y: int, piece_shape: Array) -> int`
- Forbidden: No direct grid state mutation — ghost is read-only calculation
- Guardrail: Ghost calculation must match the hard-drop landing position

---

## Acceptance Criteria

*From GDD ghost-piece-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN piece at position (5, 15) on an empty grid, **WHEN** ghost is calculated, **THEN** ghost appears at position (5, 0).
- [ ] **AC-2**: GIVEN piece at position (5, 10) with a stack at y=5, **WHEN** ghost is calculated, **THEN** ghost appears at position (5, 6).
- [ ] **AC-3**: GIVEN piece is at the floor (cannot move down), **WHEN** ghost is calculated, **THEN** ghost position equals piece position (no visible gap).
- [ ] **AC-6**: GIVEN game is in GAME_OVER state, **WHEN** rendering occurs, **THEN** no ghost is rendered (handled by rendering layer — ghost_piece provides position data only).

---

## Implementation Notes

*From GDD Formulas section:*

```gdscript
# ghost_piece.gd
class_name GhostPiece
extends Node

@export var grid: Grid
@export var collision: Collision

# Returns the Y coordinate where the ghost piece should be rendered
# piece_shape is an array of (offset_x, offset_y) cell positions
func calculate_ghost_y(piece_x: int, piece_y: int, piece_shape: Array) -> int:
    var ghost_y := piece_y
    while _can_ghost_move_to(piece_x, ghost_y - 1, piece_shape):
        ghost_y -= 1
    return ghost_y

# Internal helper — tests if all cells of the piece shape can occupy (x, y)
func _can_ghost_move_to(x: int, y: int, shape: Array) -> bool:
    for cell in shape:
        var cx: int = cell[0]
        var cy: int = cell[1]
        var grid_x := x + cx
        var grid_y := y + cy
        # Must be within grid bounds and not overlapping a locked cell
        if not grid.is_valid_position(grid_x, grid_y):
            return false  # out of bounds (floor/wall)
        if not grid.is_empty(grid_x, grid_y):
            return false  # occupied
    return true
```

**Ghost calculation must match hard drop destination**: The `calculate_ghost_y` algorithm must produce the exact same Y position as a hard drop would land at. This is critical — if they differ, the ghost is misleading.

**Drop distance** (optional utility):
```gdscript
func get_drop_distance(piece_y: int, ghost_y: int) -> int:
    return piece_y - ghost_y
```

---

## Out of Scope

- Ghost rendering (Story 002) — ghost_piece.gd provides position data; rendering is separate
- Visual style (outline/dotted, opacity) — defined in GDD but handled by rendering layer

---

## QA Test Cases

**AC-1**: Ghost on empty grid drops to floor
- Given: Piece at (5, 15) on a completely empty grid
- When: `calculate_ghost_y(5, 15, shape)` is called
- Then: Return value equals 0
- Edge cases: Different starting Y positions, different piece shapes (I-piece reaches floor differently)

**AC-2**: Ghost stops at stack top
- Given: Piece at (5, 10), grid has occupied cells at y=5 forming a stack
- When: `calculate_ghost_y(5, 10, shape)` is called
- Then: Return value equals 6 (one above the top of the stack at y=5)
- Edge cases: Stack with a notch (ghost drops into gap), multiple stack heights

**AC-3**: Ghost equals piece when on floor
- Given: Piece at (5, 0) with floor blocking further movement
- When: `calculate_ghost_y(5, 0, shape)` is called
- Then: Return value equals 0 (same as piece position)
- Edge cases: Piece wedged in corner (x=0 or x=9 with floor)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ghost_piece/ghost_calculation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

**Dependencies**: grid-system stories (001-003), tetromino-system stories (for piece state interface)