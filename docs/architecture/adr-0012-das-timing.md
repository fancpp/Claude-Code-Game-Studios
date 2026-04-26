# ADR-ARCH-012: Input DAS Timing

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /architecture-review)

## Summary

The Input System implements Delayed Auto Shift (DAS) for held movement keys using delta-time accumulation in `_process()`. Each DAS action (Move Left, Move Right, Soft Drop) tracks its own independent DAS state: elapsed time, repeat count, and whether the initial delay has fired. DAS auto-pauses with the game via the `_process()` mechanism. DAS is pure GDScript — no Godot Timer nodes, no engine API surface.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Foundation / Input |
| **Knowledge Risk** | LOW — `_process()` timing and Input API are stable from Godot 2.x through 4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — foundation layer, no dependencies |
| **Enables** | Input System implementation, all Tetromino System movement |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before Input System implementation begins |

## Context

### Problem Statement

The game has 3 DAS actions (Move Left, Move Right, Soft Drop) where holding the key should first wait an initial delay, then repeat at a fixed interval. The question is: how is DAS state tracked per action, what are the exact timing constants, how does DAS interact with game pause, and what is the signal output pattern?

### Constraints

- DAS applies to: Move Left, Move Right, Soft Drop
- DAS does NOT apply to: Hard Drop, Rotate CW, Rotate CCW, Pause
- Initial delay: 170ms (standard Tetris convention)
- Repeat rate: 50ms (standard Tetris convention)
- DAS must pause when the game pauses and resume from the same elapsed time
- DAS state is per-action — holding left and right simultaneously cancels both
- The player presses and releases the key; DAS does not auto-fire on game start

### Requirements

- DAS state tracked per action independently
- Initial delay fires exactly once before repeat begins
- Repeat fires at a fixed interval after initial delay
- Holding both left and right simultaneously cancels both DAS actions
- DAS state resets completely on key release
- DAS auto-pauses with game

## Decision

**Pattern: Per-action DAS state in `_process()`, signal-emit on initial fire and each repeat.**

### DAS State Per Action

```gdscript
# input_handler.gd
class_name InputHandler
extends Node

const DAS_INITIAL_DELAY_MS := 170
const DAS_REPEAT_RATE_MS := 50

# Per-action DAS state
var _das_left_time_ms: int = 0
var _das_left_repeat_count: int = 0
var _das_left_initial_fired: bool = false

var _das_right_time_ms: int = 0
var _das_right_repeat_count: int = 0
var _das_right_initial_fired: bool = false

var _das_soft_drop_time_ms: int = 0
var _das_soft_drop_repeat_count: int = 0
var _das_soft_drop_initial_fired: bool = false

var _key_left_held: bool = false
var _key_right_held: bool = false
var _key_soft_drop_held: bool = false

func _process(delta_ms: float) -> void:
    var dt_ms := int(delta_ms * 1000.0)

    # DAS cancellation: left + right simultaneously = no movement
    if _key_left_held and _key_right_held:
        _das_left_time_ms = 0
        _das_left_repeat_count = 0
        _das_left_initial_fired = false
        _das_right_time_ms = 0
        _das_right_repeat_count = 0
        _das_right_initial_fired = false
        return  # cancel both

    if _key_left_held:
        _das_left_time_ms += dt_ms
        if not _das_left_initial_fired:
            if _das_left_time_ms >= DAS_INITIAL_DELAY_MS:
                emit_signal("move_left")
                _das_left_initial_fired = true
                _das_left_repeat_count = 1
        else:
            var elapsed_since_first := _das_left_time_ms - DAS_INITIAL_DELAY_MS
            var expected_repeats := elapsed_since_first / DAS_REPEAT_RATE_MS
            if _das_left_repeat_count <= expected_repeats:
                emit_signal("move_left")
                _das_left_repeat_count += 1

    if _key_right_held:
        _das_right_time_ms += dt_ms
        if not _das_right_initial_fired:
            if _das_right_time_ms >= DAS_INITIAL_DELAY_MS:
                emit_signal("move_right")
                _das_right_initial_fired = true
                _das_right_repeat_count = 1
        else:
            var elapsed_since_first := _das_right_time_ms - DAS_INITIAL_DELAY_MS
            var expected_repeats := elapsed_since_first / DAS_REPEAT_RATE_MS
            if _das_right_repeat_count <= expected_repeats:
                emit_signal("move_right")
                _das_right_repeat_count += 1

    if _key_soft_drop_held:
        _das_soft_drop_time_ms += dt_ms
        if not _das_soft_drop_initial_fired:
            if _das_soft_drop_time_ms >= DAS_INITIAL_DELAY_MS:
                emit_signal("soft_drop")
                _das_soft_drop_initial_fired = true
                _das_soft_drop_repeat_count = 1
        else:
            var elapsed_since_first := _das_soft_drop_time_ms - DAS_INITIAL_DELAY_MS
            var expected_repeats := elapsed_since_first / DAS_REPEAT_RATE_MS
            if _das_soft_drop_repeat_count <= expected_repeats:
                emit_signal("soft_drop")
                _das_soft_drop_repeat_count += 1

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("move_left"):
        _key_left_held = true
    if event.is_action_released("move_left"):
        _key_left_held = false
        _das_left_time_ms = 0
        _das_left_repeat_count = 0
        _das_left_initial_fired = false

    if event.is_action_pressed("move_right"):
        _key_right_held = true
    if event.is_action_released("move_right"):
        _key_right_held = false
        _das_right_time_ms = 0
        _das_right_repeat_count = 0
        _das_right_initial_fired = false

    if event.is_action_pressed("soft_drop"):
        _key_soft_drop_held = true
    if event.is_action_released("soft_drop"):
        _key_soft_drop_held = false
        _das_soft_drop_time_ms = 0
        _das_soft_drop_repeat_count = 0
        _das_soft_drop_initial_fired = false

    # Non-DAS actions: immediate, no hold
    if event.is_action_pressed("hard_drop"):
        emit_signal("hard_drop")
    if event.is_action_pressed("rotate_cw"):
        emit_signal("rotate_cw")
    if event.is_action_pressed("rotate_ccw"):
        emit_signal("rotate_ccw")
    if event.is_action_pressed("pause"):
        emit_signal("pause")
```

**Pause behavior:** `_process()` automatically pauses when `get_tree().paused = true`. All DAS state (`_das_*_time_ms`) is a simple integer that is not affected by Godot's pause — it just stops incrementing when `_process()` stops. On unpause, DAS resumes from the exact elapsed time. No explicit pause/unpause wiring needed.

**DAS cancellation:** If both left and right are held simultaneously, all DAS state is reset to zero and no signals fire. This implements the GDD rule "If left and right are pressed simultaneously: Cancel both."

**Key release resets all DAS state** for that action, including initial fired flag. A new press starts fresh from zero.

## Architecture Diagram

```
input_handler.gd
  ├── _das_left_time_ms, _das_left_initial_fired, _das_left_repeat_count
  ├── _das_right_time_ms, _das_right_initial_fired, _das_right_repeat_count
  ├── _das_soft_drop_time_ms, _das_soft_drop_initial_fired, _das_soft_drop_repeat_count
  │
  ├── _unhandled_input(event):
  │     on key press → set _key_*_held = true, emit initial signal if DAS
  │     on key release → reset _key_*_held and ALL DAS state for that action
  │
  ├── _process(delta):
  │     if left+right held: reset all DAS state for both, return
  │     per held action: accumulate time, emit signal on initial delay or each repeat
  │
  └── signals emitted: move_left, move_right, soft_drop, hard_drop, rotate_cw,
        rotate_ccw, pause

Note: hard_drop, rotate_cw, rotate_ccw, pause are NOT DAS — emitted immediately
on key press, no hold behavior.
```

## DAS Timing Summary

| Action | DAS | Initial Delay | Repeat Rate |
|--------|-----|---------------|-------------|
| Move Left | Yes | 170ms | 50ms |
| Move Right | Yes | 170ms | 50ms |
| Soft Drop | Yes | 170ms | 50ms |
| Hard Drop | No | — | Immediate on press |
| Rotate CW | No | — | Immediate on press |
| Rotate CCW | No | — | Immediate on press |
| Pause | No | — | Immediate on press |

## DAS Formula

```
if not initial_fired:
    if elapsed_time_ms >= DAS_INITIAL_DELAY_MS:
        emit signal (first fire)
        initial_fired = true
        repeat_count = 1
else:
    expected_repeats = (elapsed_time_ms - DAS_INITIAL_DELAY_MS) / DAS_REPEAT_RATE_MS
    if repeat_count <= expected_repeats:
        emit signal
        repeat_count += 1
```

## Alternatives Considered

### Alternative 1: Godot Timer per action

- **Description**: One `Timer` node per DAS action with `wait_time = DAS_REPEAT_RATE_MS`. Initial delay handled by a separate one-shot timer.
- **Pros**: Godot-managed timing
- **Cons**: Requires pause/unpause wiring for all 3 timers; extra nodes in scene tree; more complex than needed for a simple integer accumulator
- **Rejection Reason**: `_process()` delta accumulation achieves identical behavior with zero extra nodes and no pause wiring needed.

### Alternative 2: `Input.is_action_just_repeated()` (Godot built-in repeat)

- **Description**: Use Godot's built-in input repeat detection via `Input.is_action_just_repeated()` which handles DAS automatically.
- **Cons**: Godot's built-in repeat uses system settings (OS repeat rate), not the game's fixed 170ms/50ms values. It also doesn't expose the initial delay vs. repeat distinction in a configurable way.
- **Rejection Reason**: The game requires precise, fixed DAS timing regardless of OS settings. Manual `_process()` accumulation gives full control over the timing constants.

### Alternative 3: Single shared DAS timer for all actions

- **Description**: One global DAS accumulator that fires on a fixed interval, all held keys share it.
- **Cons**: Cannot independently cancel only left (or right) when both are held — the GDD requires simultaneous left+right to cancel both DAS actions. Separate state per action is required.
- **Rejection Reason**: Per-action DAS state is required by the GDD rule for simultaneous cancellation.

## Consequences

### Positive

- DAS timing constants (170ms, 50ms) are `const` values — easy to tune
- `_process()` auto-pause means DAS freezes and resumes correctly with the game
- Per-action DAS state correctly handles simultaneous left+right cancellation
- Key release resets all DAS state — fresh start on next press
- No Godot Timer nodes, no extra scene tree nodes, no pause wiring
- Pure GDScript, trivially testable — just call `_process(delta)` with fake time

### Negative

- If player holds a key, releases briefly, and re-holds before DAS resets (within the same frame), the behavior depends on the order of `_unhandled_input` vs `_process`. Mitigation: key release fires in `_unhandled_input` synchronously, resetting state immediately.

### Neutral

- DAS constants are hardcoded in `input_handler.gd` — changing them requires a code edit (acceptable for tuning knobs that rarely change)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Left+right simultaneous release order causes inconsistent state | Low | DAS state for one action could be non-zero when it shouldn't | Reset both actions atomically in `_process()` check, not on individual key release |
| Floating point drift in delta accumulation | Very Low | DAS fires at slightly wrong times over long holds | Use integer milliseconds — no floating point in timing state |

## Performance Implications

- **CPU**: Negligible — 3 integer comparisons and additions per frame
- **Memory**: 9 integers (~36 bytes) for DAS state
- **Load Time**: Negligible
- **Network**: None

## Migration Plan

- Greenfield — no existing input code
- `input_handler.gd` implements DAS as described
- `tetromino.gd` receives `move_left`, `move_right`, `soft_drop` signals and responds identically to both DAS-repeat and single-press

## Validation Criteria

- GIVEN key held for 170ms, WHEN `_process()` accumulates time past 170ms, THEN `move_left` signal fires exactly once (first fire)
- GIVEN key held for 220ms, WHEN `_process()` fires at 170ms and again at 220ms, THEN `move_left` fires twice (initial + first repeat)
- GIVEN left and right held simultaneously, WHEN DAS timer accumulates, THEN no `move_left` or `move_right` signals fire
- GIVEN key released after 300ms, WHEN key is pressed again, THEN DAS starts fresh from 0ms
- GIVEN soft drop held for 170ms, WHEN initial delay fires, THEN `soft_drop` signal fires (not `move_left`/`move_right`)
- GIVEN hard drop pressed, WHEN pressed, THEN `hard_drop` signal fires immediately with no DAS delay
- GIVEN game pauses with DAS running at 200ms, WHEN unpaused, THEN DAS resumes from 200ms (not from 0ms)
- GUT test: simulate `_process(0.200)` (200ms) and assert signals emitted match expected repeat count

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| input-system.md | Input System | DAS initial delay 170ms | `_das_*_time_ms` accumulator triggers first signal at 170ms |
| input-system.md | Input System | DAS repeat rate 50ms | After initial, each 50ms window triggers one additional signal |
| input-system.md | Input System | DAS applies to Move Left, Move Right, Soft Drop | Three independent DAS state structs, all with same timing |
| input-system.md | Input System | DAS does NOT apply to Hard Drop, Rotate, Pause | Hard drop / rotate / pause emit immediately on `_unhandled_input` |
| input-system.md | Input System | Left+right simultaneous cancels both | `_process()` checks both held flags and resets state |
| input-system.md | Input System | DAS pauses with game | `_process()` auto-pauses with game; no explicit wiring |
| input-system.md | Input System | Key release resets DAS | `_unhandled_input` key release handlers reset all DAS state for that action |

## Related

- ADR-ARCH-002 (Signal Bus) — DAS output is via signals `move_left`, `move_right`, `soft_drop`
- ADR-ARCH-003 (Scene Tree) — `input_handler.gd` is a direct child of `main.tscn`
- `design/gdd/input-system.md` — authoritative source for DAS parameters