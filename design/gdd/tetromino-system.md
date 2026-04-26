# Tetromino System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

## Overview

The Tetromino System defines the seven standard tetromino shapes (I, O, T, S, Z, J, L), implements the Super Rotation System (SRS) for piece rotation, manages current piece state (position, rotation), and handles piece locking when landing. It is the primary interactive element — every player action (move, rotate, drop) operates on the currently active tetromino. The system reads grid state from the Grid System and validates moves through the Collision System before confirming any position change.

## Player Fantasy

"The piece is an extension of my intention." The player feels complete control over each tetromino — when they rotate, the piece rotates exactly as expected; when they move, the piece moves precisely. Wall kicks feel fair because the system tried every reasonable offset before rejecting the move. The piece never drifts, slides, or behaves unexpectedly. Mastery comes from perfectly understanding how each shape behaves in every situation.

## Detailed Design

### Core Rules

**Tetromino Shapes (SRS Standard):**

| Piece | Type | Shape (relative cells) |
|-------|------|------------------------|
| I | 1 | [(0,0), (1,0), (2,0), (3,0)] |
| O | 2 | [(0,0), (1,0), (0,1), (1,1)] |
| T | 3 | [(0,0), (1,0), (2,0), (1,1)] |
| S | 4 | [(1,0), (2,0), (0,1), (1,1)] |
| Z | 5 | [(0,0), (1,0), (1,1), (2,1)] |
| J | 6 | [(0,0), (0,1), (1,1), (2,1)] |
| L | 7 | [(2,0), (0,1), (1,1), (2,1)] |

**SRS Rotation States:**
Each tetromino has 4 rotation states (0, 1, 2, 3). Rotation right (clockwise) increments state mod 4; rotation left decrements mod 4.

**SRS Wall Kick Data:**
When basic rotation fails (collision at target position), SRS tests offset positions. The wall kick offsets from the collision-system.md:

```
offsets = [(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]
for each (dx, dy) in offsets:
  if can_move_to(tx + dx, ty + dy, rotated_shape): return true
return false
```

**Piece Spawning:**
- Spawn position: x=4, y=19 (centered at top of grid)
- Spawn rotation: 0 (default orientation)
- Piece locks after LOCK_DELAY (500ms default) when movement down is blocked

**Lock Condition:**
- When can_move_to(x, y-1, shape) returns false (blocked below)
- Start LOCK_DELAY timer
- If piece is still blocked after timer expires → lock piece to grid
- Any successful move resets the lock timer

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| ACTIVE | Piece is controllable | Spawn completes | Lock or game over |
| LOCKING | Lock timer counting | Blocked below | Timer expires → LOCKED |
| LOCKED | Piece written to grid | Timer expires | Next piece spawns |

**Internal State:**
- position: (x, y) — top-left reference cell
- rotation: 0-3 — current SRS rotation state
- type: 1-7 — which tetromino

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Collision System | Input | `can_move_to(x, y, shape) -> bool` |
| Grid System | Output | Writes locked piece cells via `set_cell()` |
| Input System | Input | Receives `move_left`, `move_right`, `soft_drop`, `hard_drop`, `rotate_cw`, `rotate_ccw` signals |
| Game State System | Output | Emits `piece_locked` signal; receives game state for pause behavior |

## Formulas

**Rotation Matrix (SRS):**
```
CW: (x, y) -> (y, -x)
CCW: (x, y) -> (-y, x)
```

**Lock Delay Formula:**
```
lock_timer >= LOCK_DELAY -> lock_piece()
```

**Movement Validation:**
```
can_move_to(tx, ty, shape) = AND(
  for all (cx, cy) in shape:
    is_valid_position(tx + cx, ty + cy) AND is_empty(tx + cx, ty + cy)
)
```

## Edge Cases

- **If piece spawns into occupied cell**: Immediate game over (spawn failure)
- **If piece is on hold and new piece spawns**: No clipping — spawn check prevents
- **If rotation would cause collision after all wall kicks**: Rotation rejected, no state change
- **If hard drop while lock timer running**: Immediate lock, timer cancelled
- **If game paused while lock timer running**: Timer pauses, resumes on unpause
- **If rotation during DAS movement**: Process rotation after current move cycle

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Grid System | `is_empty(x, y)`, `is_valid_position(x, y)` | Provides occupancy and bounds data |
| Collision System | `can_move_to(x, y, shape) -> bool` | Validates all movement/rotation attempts |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Game State System | `piece_locked` signal | Triggers line clear check |
| Ghost Piece System | Current piece position/shape | Reads to calculate ghost position |
| Piece Spawn System | `request_spawn()` | Called when piece locks |

**Hard vs. Soft:**
- **HARD** — Grid System, Collision System (cannot function without both)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| LOCK_DELAY | 500ms | 100-2000ms | Time before piece locks after landing |
| WALL_KICK_ENABLED | true | true/false | Allow rotation near walls |
| WALL_KICK_ATTEMPTS | 6 | 1-10 | Number of offset positions to try |

## Acceptance Criteria

- **GIVEN** piece at spawn position, **WHEN** player presses rotate_cw, **THEN** rotation state changes and piece position updates to pass wall kick if needed.
- **GIVEN** piece is blocked below, **WHEN** LOCK_DELAY passes, **THEN** piece cells are written to grid via `set_cell()`.
- **GIVEN** piece is active, **WHEN** hard_drop is pressed, **THEN** piece immediately locks (no timer wait).
- **GIVEN** piece rotation would collide at target, **WHEN** wall kicks are tested, **THEN** piece moves to first valid offset or rejects rotation.
- **GIVEN** piece type is I at rotation 0, **WHEN** rotated clockwise, **THEN** shape transforms to rotation 1 SRS state.
- **GIVEN** piece cannot move left/right/down and lock timer expires, **WHEN** piece locks, **THEN** `piece_locked` signal is emitted.

## Open Questions

[To be designed]