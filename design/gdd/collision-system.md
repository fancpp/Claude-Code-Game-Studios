# Collision System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

---

## Overview

The Collision System determines whether a tetromino can occupy a specific position on the grid. It checks if the target cells are within bounds and unoccupied. All movement requests (left, right, down, rotation) pass through collision detection before being confirmed — if a move would collide, it is rejected. The system is a pure query: it reads the grid state and returns true/false, never modifying the grid.

## Player Fantasy

"The piece goes exactly where I intend it — and stops precisely where it should." The player feels collision as the boundary of their power: when rotation is blocked by a wall, when a piece lands perfectly flush, when movement stops at the stack. Every collision response confirms the player's skill. If collision were buggy — pieces passing through walls or overlapping — the sense of mastery would shatter.

## Detailed Design

### Core Rules

**Collision Check API:**
```
can_move_to(x: int, y: int, tetromino_shape: Array) -> bool
```

The function checks if all cells of the tetromino shape can occupy the target position:
1. For each cell in tetromino_shape (relative coordinates)
2. Calculate absolute position: absolute_x = x + cell_x, absolute_y = y + cell_y
3. Check: is_valid_position(absolute_x, absolute_y) AND is_empty(absolute_x, absolute_y)
4. If all cells pass → return true. If any cell fails → return false.

**Collision Types:**
| Type | Condition | Behavior |
|------|-----------|----------|
| Wall collision | x < 0 or x >= GRID_WIDTH | Reject move |
| Floor collision | y < 0 | Reject downward move |
| Stack collision | Grid cell is OCCUPIED | Reject move |
| Valid move | All cells empty and in bounds | Allow move |

**Lock Condition:**
When a piece cannot move down (collision detected), it locks in place after the lock delay. The piece's cells are written to the grid at that point.

### States and Transitions

| State | Description |
|-------|-------------|
| COLLIDING | Current position has a collision — cannot occupy |
| FREE | Target position is valid — movement allowed |

This system has no internal state transitions. It is a pure function.

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Grid System | Input | Queries `is_valid_position()`, `is_empty()` |
| Tetromino System | Output | Receives true/false for move requests |
| Game State System | Output | Receives lock event when piece cannot move down |

## Formulas

### Collision Detection

The `can_move_to` function checks all cells of a tetromino shape.

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Target X | tx | int | 0-9 | Target grid X position |
| Target Y | ty | int | 0-19 | Target grid Y position |
| Cell Relative X | cx | int | -3 to 3 | Cell offset from piece origin |
| Cell Relative Y | cy | int | -3 to 3 | Cell offset from piece origin |
| Absolute X | ax | int | computed | tx + cx |
| Absolute Y | ay | int | computed | ty + cy |

**Collision Check Formula:**
```
can_move_to(tx, ty, shape) = AND(
  for all (cx, cy) in shape:
    is_valid_position(tx + cx, ty + cy) AND is_empty(tx + cx, ty + cy)
)
```

**Wall Kick Check (for rotation):**
When basic collision fails, test offset positions:
```
offsets = [(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]
for each (dx, dy) in offsets:
  if can_move_to(tx + dx, ty + dy, shape): return true
return false
```

## Edge Cases

- **If tetromino shape extends partially outside left boundary**: Reject move. Return false.
- **If tetromino shape extends partially outside right boundary**: Reject move. Return false.
- **If tetromino shape extends below floor (y < 0)**: Reject move. Return false.
- **If shape has empty cells (gap in tetromino)**: Only check non-empty cells. Empty cells always pass.
- **If shape is completely empty (invalid shape)**: Return false — no move is valid.
- **If checking a position with no collision**: Return true — move is allowed.

## Dependencies

**Upstream Dependencies:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Grid System | `is_valid_position()`, `is_empty()` | Provides grid bounds and occupancy data |

**Downstream Dependents:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Tetromino System | `can_move_to()` result | Uses collision to allow/deny moves |
| Game State System | Lock signal | Receives lock event when piece lands |

**Hard vs. Soft:**
- **HARD** — All dependencies are hard. Collision cannot function without Grid System.

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| LOCK_DELAY | 500ms | 100-2000ms | Time before piece locks after landing |
| WALL_KICK_ENABLED | true | true/false | Allow rotation near walls |
| WALL_KICK_ATTEMPTS | 6 | 1-10 | Number of offset positions to try |

## Acceptance Criteria

- **GIVEN** a tetromino at position (5, 10), **WHEN** `can_move_to(5, 9, shape)` is called with all cells empty below, **THEN** it returns true.
- **GIVEN** a tetromino at position (0, 10), **WHEN** `can_move_to(-1, 10, shape)` is called, **THEN** it returns false (wall collision).
- **GIVEN** a tetromino at position (5, 0), **WHEN** `can_move_to(5, -1, shape)` is called, **THEN** it returns false (floor collision).
- **GIVEN** a tetromino with a shape containing only empty cells, **WHEN** `can_move_to(5, 10, shape)` is called, **THEN** it returns false.
- **GIVEN** wall kick is enabled, **WHEN** rotation is blocked at x=0, **THEN** system tests offset positions (-1, 0), (1, 0), etc.

## Open Questions

[To be designed]