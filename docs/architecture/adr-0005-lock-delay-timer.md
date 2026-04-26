# ADR-ARCH-005: Lock Delay Timer

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

The lock delay uses manual delta-time accumulation in `tetromino.gd`'s `_process()` — no Godot `Timer` node. When the piece is blocked below, `_lock_time` accumulates. Any successful move resets it. Lock fires when `_lock_time >= LOCK_DELAY`. Hard drop fires lock immediately. `_process()` is automatically paused by Godot when the game pauses, so the lock timer pauses and resumes with the game without explicit pause handling.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Timing |
| **Knowledge Risk** | LOW — `_process()` timing and pause behavior are stable Godot fundamentals |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-001 (Grid), ADR-ARCH-004 (Shape Storage) |
| **Enables** | All gameplay system ADRs that involve piece locking |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before Tetromino System implementation |

## Context

### Problem Statement

When a tetromino lands on the floor or a locked piece, it should not lock immediately — the player needs a brief window (LOCK_DELAY, default 500ms) to slide or rotate the piece into a valid position before it becomes permanent. The question is: what mechanism implements this delay, and how does it interact with pause (which must freeze the timer)?

### Constraints

- Default LOCK_DELAY = 500ms (per GDD, safe range 100-2000ms)
- Lock timer must pause when the game pauses and resume from where it left off when unpaused
- Hard drop must cancel the timer and lock immediately
- Any successful move (left, right, down, rotation) must reset the timer
- The timer starts only when the piece is blocked below AND in its final resting position — not when it simply can't move down one row temporarily

### Requirements

- Lock fires 500ms after piece becomes blocked below and remains blocked
- Timer resets on every successful move while blocked
- Hard drop bypasses timer entirely
- Pause freezes timer; unpause resumes it from the same elapsed time
- Lock delay state is observable in the scene tree inspector

## Decision

**Mechanism: `_process()` delta accumulation. No Godot `Timer` node.**

```gdscript
# tetromino.gd
class_name Tetromino
extends Node

const LOCK_DELAY: float = 0.5  # seconds (500ms default)

var _lock_time: float = 0.0    # accumulated time in LOCKING state
var _is_locking: bool = false  # true when piece is blocked below

func _process(delta: float) -> void:
    if not _is_locking:
        return
    _lock_time += delta
    if _lock_time >= LOCK_DELAY:
        _lock_piece_to_grid()

func try_move(dx: int, dy: int) -> bool:
    var new_x := position.x + dx
    var new_y := position.y + dy
    if collision.can_move_to(new_x, new_y, get_current_grid()):
        position.x = new_x
        position.y = new_y
        # Reset lock timer on any successful move
        _reset_lock_timer()
        return true
    return false

func try_rotate_cw() -> bool:
    var new_rotation := (rotation + 1) % 4
    # Test wall kicks...
    if wall_kick_valid(new_rotation):
        rotation = new_rotation
        _reset_lock_timer()
        return true
    return false

func hard_drop() -> void:
    # Immediately lock — no timer
    _lock_piece_to_grid()

func _reset_lock_timer() -> void:
    _lock_time = 0.0
    _is_locking = false

func _check_lock_condition() -> void:
    # Called every frame by _physics_process or after each move
    if can_move_to(position.x, position.y - 1, get_current_grid()):
        # Piece can still move down — not in lock condition
        _reset_lock_timer()
    else:
        # Piece is blocked below — start or continue lock timer
        _is_locking = true
        # Note: do NOT reset _lock_time here — only _is_locking
        # This preserves accumulated time across brief unblock/reblock cycles
```

**Why `_process()` delta accumulation instead of a Godot `Timer` node?**

| Approach | Pros | Cons |
|----------|------|------|
| `Timer` node | Godot-managed, inspector-visible | Requires explicit pause/unpause wiring; extra node in scene tree |
| `_process()` delta accumulation | Auto-pauses with game (no explicit wiring); simpler, no extra node | Slightly more manual; must not be forgotten in `try_move` |

The `_process()` approach is superior for this use case because **pause = `_process()` stops = timer stops**. Godot automatically pauses `_process()` for all nodes when `get_tree().paused = true`. The lock timer pauses and resumes with no explicit code. A `Timer` node would require wiring `pause == true → pause Timer` and `pause == false → resume Timer` — boilerplate that is error-prone.

**Lock timer resets on move, not on release:** The GDD says "Any successful move resets the lock timer." This means any move that results in a valid new position (left, right, down, CW, CCW) resets `_lock_time` to 0 and `_is_locking` to false. The timer only accumulates when the piece is continuously blocked below.

**Brief unblock does NOT reset the timer:** If a piece is locking (timer running) and the player pushes it sideways into a gap where `can_move_to(x, y-1)` becomes true for a frame, we reset `_is_locking` to false (timer stops accumulating). But `_lock_time` value is preserved. When the piece becomes blocked again, the timer resumes from the previous accumulated value — the player doesn't get a fresh 500ms. See edge cases.

**Hard drop is immediate:** `hard_drop()` calls `_lock_piece_to_grid()` directly. No timer check. No `_is_locking` flag. Immediate lock.

## Architecture Diagram

```
tetromino.gd — active piece state machine
  States: ACTIVE → LOCKING → LOCKED → (piece_spawn requests next piece)

  _process(delta):
    if _is_locking:
      _lock_time += delta
      if _lock_time >= LOCK_DELAY:
        → _lock_piece_to_grid()

  try_move(dx, dy):
    if can_move_to(new_x, new_y, grid):
      position = new_x, new_y
      _reset_lock_timer()   ← resets both _lock_time and _is_locking

  hard_drop():
    _lock_piece_to_grid()   ← immediate, no timer

  _check_lock_condition():  (called every frame / after each move)
    if can_move_to(x, y-1):     ← can fall further
      _reset_lock_timer()       ← not blocked below
    else:
      _is_locking = true        ← blocked below, accumulate
```

## Key Interfaces

```gdscript
# tetromino.gd — public API for lock delay
class_name Tetromino
extends Node

const LOCK_DELAY: float = 0.5   # seconds — accessible for tuning

var is_locking: bool            # read-only outside tetromino.gd
var lock_time_elapsed: float    # read-only — useful for visual feedback

func _process(delta: float) -> void:
    # Internal lock timer accumulation

func hard_drop() -> void:
    # Immediately locks piece — cancels any pending lock delay

func try_move(dx: int, dy: int) -> bool:
    # Resets lock timer on success

func try_rotate_cw() -> bool:
    # Resets lock timer on success

func _lock_piece_to_grid() -> void:
    # Writes piece cells to grid via grid.set_cell()
    # Emits piece_locked signal
    # Resets lock timer state
```

## Edge Cases

**Brief unblock (most important edge case):**
- Piece is locking: `_is_locking = true`, `_lock_time = 300ms`
- Player rotates, piece shifts sideways — `can_move_to(x, y-1)` becomes true for 1 frame
- `_is_locking` resets to `false` (timer stops)
- Player moves again, piece is re-blocked below
- `_is_locking` becomes `true` again — `_lock_time` resumes from 300ms, NOT 0ms
- **This prevents exploits** where a player wiggles the piece infinitely by cycling through a 1-frame gap

**Piece never blocks:**
- If a piece can always move down (never rests on anything), `_is_locking` never becomes true
- Timer only starts when the piece genuinely cannot fall further

**Hard drop during lock delay:**
- Calls `_lock_piece_to_grid()` immediately
- `_reset_lock_timer()` is called internally by `_lock_piece_to_grid()` (guards against double-fire)

**Game pause during lock delay:**
- `_process()` is suspended by Godot — `_lock_time` does not increase
- When unpaused, `_process()` resumes and timer continues from current `_lock_time`
- No explicit pause/unpause code needed — this is free from the `_process()` approach

**Multiple pieces cannot lock simultaneously:**
- `tetromino.gd` manages one active piece at a time
- When `piece_locked` fires, `piece_spawn.gd` responds and the next piece spawns before lock timer can affect the new piece

## Alternatives Considered

### Alternative 1: Godot `Timer` node as child of tetromino.gd

- **Description**: `@onready var lock_timer: Timer = $LockTimer` with `lock_timer.wait_time = LOCK_DELAY`. Start on block, stop on move, timeout → lock.
- **Pros**: Inspector-visible, Godot-managed one-shot timing
- **Cons**: Requires explicit wiring to pause/unpause the timer when game pauses (`get_tree().paused = true` does NOT auto-pause `Timer` nodes by default — `Timer.paused` property must be set manually). Adds a node to the scene tree for what is an internal detail of one system.
- **Rejection Reason**: Pause wiring is error-prone and non-obvious. The `_process()` approach auto-pauses with the game. One fewer node in the scene tree.

### Alternative 2: `Timer` with `process_mode = PROCESS_MODE_WHEN_PAUSED`

- **Description**: Set the `Timer` node's `process_mode` to `PROCESS_MODE_WHEN_PAUSED = INHERITED` so it pauses with the game.
- **Pros**: Built-in Godot pause behavior, no manual wiring
- **Cons**: Requires a dedicated `Timer` node. The `_process()` approach achieves the same pause behavior with zero extra nodes and less infrastructure.

### Alternative 3: Reset `_lock_time` to 0 on ANY move (not just when locked)

- **Description**: Move functions always call `_reset_lock_timer()` unconditionally.
- **Pros**: Simpler code — no `if _is_locking` guard needed
- **Cons**: If the piece is in ACTIVE state (not blocked below), resetting the timer has no effect but adds unnecessary function call overhead. The current approach only resets when `_is_locking == true`, which is both correct and more efficient.
- **Rejection Reason**: `_reset_lock_timer()` already checks `_is_locking` internally — the behavior is correct with no performance cost.

## Consequences

### Positive

- Lock timer auto-pauses with the game — no explicit pause wiring needed
- No extra `Timer` node in the scene tree — tetromino.gd manages timing internally
- Timer state is observable via `is_locking` and `lock_time_elapsed` properties
- Hard drop is clean: `_lock_piece_to_grid()` with no conditionals
- Reset-on-move is implemented via one `_reset_lock_timer()` call in every move function

### Negative

- `_process()` approach is slightly less obvious to Godot developers accustomed to `Timer` nodes — requires developer awareness that `_process()` is the timer
- If developer adds a new move function (e.g., a "shove" mechanic) and forgets `_reset_lock_timer()`, the lock timer will not reset — must add to a test checklist

### Neutral

- LOCK_DELAY is a `const` in `tetromino.gd`, not a runtime-configurable value — changing it requires a code edit (acceptable for a tuning knob that rarely changes)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Developer adds new move and forgets `_reset_lock_timer()` | Medium | Piece locks prematurely, player frustration | GUT test: lock timer must not fire if a move is made within LOCK_DELAY window |
| Lock delay state not visible to QA | Low | Cannot verify timer behavior during playtest | Expose `is_locking` and `lock_time_elapsed` as read-only properties for debug output |

## Performance Implications

- **CPU**: Negligible — one `if _is_locking` check per frame, one float add
- **Memory**: Two floats (`_lock_time`, no additional nodes)
- **Load Time**: Negligible
- **Network**: None

## Migration Plan

- Greenfield — no existing lock delay code
- `tetromino.gd` implements `_process()` timing as described
- `lock_timer` property exposed for debug/QA inspection
- No scene file changes required (no new nodes)

## Validation Criteria

- GIVEN piece is blocked below, WHEN 500ms passes without a successful move, THEN `piece_locked` signal fires
- GIVEN piece is blocked below, WHEN a successful move is made at 300ms, THEN lock timer resets and piece does not lock until 500ms from that move
- GIVEN piece is locking (200ms elapsed), WHEN hard_drop is pressed, THEN piece locks immediately with no additional delay
- GIVEN piece is locking (200ms elapsed), WHEN game is paused, THEN timer freezes at 200ms
- GIVEN piece is locking (200ms paused), WHEN game is unpaused, THEN timer resumes from 200ms
- GUT tests verify lock timer state transitions (ACTIVE → LOCKING → LOCKED) and reset behavior

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| tetromino-system.md | Tetromino | Piece locks after LOCK_DELAY (500ms default) when blocked below | `_lock_time` accumulates in `_process()`, fires when `>= LOCK_DELAY` |
| tetromino-system.md | Tetromino | Any successful move resets lock timer | `_reset_lock_timer()` called in all move functions |
| tetromino-system.md | Tetromino | Hard drop locks immediately (no timer wait) | `hard_drop()` calls `_lock_piece_to_grid()` directly |
| tetromino-system.md | Tetromino | Lock timer pauses when game paused, resumes on unpause | `_process()` auto-pauses with game; `_lock_time` is a float, not a Godot Timer |
| game-state-system.md | Game State | Pause freezes all gameplay loops | Lock timer uses `_process()`, which Godot auto-pauses with `get_tree().paused = true` |

## Related

- ADR-ARCH-003 (Scene Tree) — `tetromino.gd` is a child of `main.tscn`
- ADR-ARCH-004 (Shape Storage) — `tetromino.gd` reads shape data via `TetrominoShapes.SHAPES`