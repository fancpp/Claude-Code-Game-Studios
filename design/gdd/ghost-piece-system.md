# Ghost Piece System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

## Overview

The Ghost Piece System calculates and renders a translucent preview showing where the current tetromino will land if dropped straight down. It ray-casts downward from the active piece's current position through the Grid System until it hits an occupied cell or the floor, then displays the ghost at that position. The ghost uses the same shape and rotation as the active piece but with a distinct transparent visual style. It updates in real-time as the player moves or rotates the piece.

## Player Fantasy

"I can see exactly where my piece will land." The ghost removes the need to mentally project the drop — the answer is always visible. This makes precision placement effortless and confident. The player can focus entirely on strategy (where to place it) rather than mechanics (where will it land). The ghost is always there when needed, never intrusive, never misleading.

## Detailed Design

### Core Rules

**Ghost Calculation:**
1. Get the current piece position (x, y) and shape
2. Starting from current y, test each cell below: is (x, y-1) empty and valid?
3. If blocked, the ghost position is the current (x, y)
4. If not blocked, decrement y and repeat until blocked or floor reached

**Ghost Position Formula:**
```
ghost_y = current_y
while can_move_to(current_x, ghost_y - 1, shape):
  ghost_y -= 1
```

**Ghost Visibility:**
- Ghost renders at the drop destination, not along the path
- Ghost shows exact final position after a hard drop
- Ghost uses same rotation state as active piece — updates when piece rotates

**Visual Style:**
- Ghost cells are rendered with the same color as the active piece but at ~30% opacity
- Ghost uses a dotted or outline-only cell style (does not fill the cell)
- Ghost renders behind (below) the active piece in the draw order

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| GHOST_VISIBLE | Ghost piece is rendered | Active piece exists | Piece locks → GHOST_HIDDEN |
| GHOST_HIDDEN | No ghost to show | Active piece locked or game over | New piece spawns → GHOST_VISIBLE |

**Internal State:**
- ghost_position: (x, y) of ghost piece center
- ghost_shape: current piece shape (mirrors active piece)

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Tetromino System | Input | Receives current piece position and shape |
| Grid System | Input | Queries `is_empty()` to calculate drop distance |
| Collision System | Input | Uses `can_move_to()` to test valid downward movement |

## Formulas

**Ghost Drop Calculation:**
```
ghost_y = piece_y
while can_move_to(piece_x, ghost_y - 1, piece_shape):
  ghost_y -= 1
```

**Drop Distance:**
```
drop_distance = piece_y - ghost_y
```

**Ghost Cell Positions:**
```
for each (cx, cy) in piece_shape:
  ghost_cell_x = piece_x + cx
  ghost_cell_y = ghost_y + cy
```

**Variable Definitions:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| piece_x | int | 0-9 | Current piece X position |
| piece_y | int | 0-19 | Current piece Y position |
| ghost_y | int | 0-19 | Calculated ghost piece Y position |
| drop_distance | int | 0-19 | Cells the piece will fall |
| piece_shape | array | 4 cells | Current piece shape |

## Edge Cases

- **If piece is already on the floor**: ghost_y = piece_y (same position, no gap)
- **If piece is at the top of the grid and cannot move down**: ghost_y = piece_y
- **If piece rotation changes**: Ghost recalculates immediately using the new shape
- **If piece moves left/right**: Ghost recalculates immediately at the new x position
- **If grid is empty (piece at spawn)**: Ghost drops to the floor (y = 0) for the piece's shape
- **If game is paused**: Ghost remains visible at its last calculated position (static)
- **If game is over**: Ghost is hidden (no active piece)

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Tetromino System | Current piece position/shape | Provides piece state to calculate ghost |
| Grid System | `is_empty(x, y)` | Queries grid occupancy for drop calculation |
| Collision System | `can_move_to(x, y, shape)` | Tests downward movement validity |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| (Rendering only) | Ghost position/shape | Rendering system reads ghost data to draw |

**Hard vs. Soft:**
- **HARD** — Tetromino System (cannot calculate ghost without current piece)
- **SOFT** — Grid System, Collision System (can render ghost without if systems not ready, but position may be inaccurate)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| GHOST_OPACITY | 30% | 10-50% | Visual transparency of ghost piece |
| GHOST_STYLE | outline | outline/fill/dotted | Rendering style for ghost cells |

## Acceptance Criteria

- **GIVEN** piece at position (5, 15) on an empty grid, **WHEN** ghost is calculated, **THEN** ghost appears at position (5, 0).
- **GIVEN** piece at position (5, 10) with a stack at y=5, **WHEN** ghost is calculated, **THEN** ghost appears at position (5, 6).
- **GIVEN** piece is at the floor (cannot move down), **WHEN** ghost is calculated, **THEN** ghost position equals piece position (no visible gap).
- **GIVEN** piece at position (5, 15), **WHEN** player moves piece to (3, 15), **THEN** ghost recalculates and moves to the correct drop position.
- **GIVEN** piece at position (5, 15) with rotation state 0, **WHEN** player rotates the piece, **THEN** ghost recalculates with the new shape.
- **GIVEN** game is paused, **WHEN** the game resumes, **THEN** ghost appears at the same position as before the pause.
- **GIVEN** game is in GAME_OVER state, **WHEN** rendering occurs, **THEN** no ghost is rendered.

## Open Questions

[To be designed]