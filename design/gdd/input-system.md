# Input System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

---

## Overview

The Input System captures and translates keyboard events into game actions. It is the player's primary interface — every keypress is interpreted as a command (move left, rotate, soft drop, hard drop, pause). The system maps physical keys to abstract actions and emits signals that other systems subscribe to. It does not execute game logic; it only translates input into intent.

## Player Fantasy

"The controls are invisible — only the response is felt." The player never thinks about the input system; they think "I pressed left, the piece moved left." The fantasy is total responsiveness and precision — every action feels immediate and exactly executed. If the input system has latency or missed inputs, the illusion shatters and the player feels disconnected from the piece.

## Detailed Design

### Core Rules

**Key Mappings:**
| Action | Primary Key | Signal Emitted |
|--------|-------------|----------------|
| Move Left | Left Arrow | `move_left` |
| Move Right | Right Arrow | `move_right` |
| Soft Drop | Down Arrow | `soft_drop` |
| Hard Drop | Space | `hard_drop` |
| Rotate Clockwise | X | `rotate_cw` |
| Rotate Counter-Clockwise | Z | `rotate_ccw` |
| Pause | Escape or P | `pause` |

**Delayed Auto Shift (DAS):**
- Initial delay: 170ms (time before first repeat)
- Repeat rate: 50ms (interval between repeats)
- Applies to: Move Left, Move Right, Soft Drop
- Does NOT apply to: Hard Drop, Rotation, Pause

**Input States:**
| State | Description |
|-------|-------------|
| IDLE | No keys pressed |
| MOVING | Left/Right arrow held — triggers DAS repeat |
| DROPPING | Soft drop active — piece descends faster |
| LOCKING | Hard drop triggered — immediate lock |

**Signal Interface:**
The Input System emits Godot signals. Other systems connect to these signals:
```
signal move_left
signal move_right
signal soft_drop
signal hard_drop
signal rotate_cw
signal rotate_ccw
signal pause
```

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Tetromino System | Output | Subscribes to all input signals |

## Formulas

### DAS (Delayed Auto Shift) Timing

The DAS formula controls repeat behavior for held movement keys.

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Initial Delay | D_initial | int | 0-500ms | Time before first repeat |
| Repeat Rate | R | int | 0-200ms | Time between repeats |
| Elapsed Time | T | int | ms | Time since key press |
| Repeat Count | N | int | 0+ | Number of repeats triggered |

**DAS Trigger Formula:**
```
N = floor((T - D_initial) / R) when T > D_initial, else N = 0
```

**Default Values:**
- D_initial = 170ms (standard Tetris convention)
- R = 50ms

**Output Range:** N: 0 to unlimited under sustained hold

## Edge Cases

- **If left and right are pressed simultaneously**: Cancel both — no movement occurs. Prevents accidental double-tap behavior.
- **If rotate is pressed while moving**: Process both — piece moves first, then rotation applies to new position.
- **If pause is pressed during hard drop**: Hard drop completes before pause activates — no interruption mid-drop.
- **If key is pressed before game starts**: Buffer the input until game begins, then process.

## Dependencies

**Upstream Dependencies (none):**
This system has no dependencies. It is a foundation layer.

**Downstream Dependents:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Tetromino System | Input signals (move_left, move_right, rotate_cw, etc.) | Receives input events and executes game actions |

**Hard vs. Soft:**
- All dependencies are **HARD** — Tetromino System cannot function without input events

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| DAS_INITIAL_DELAY | 170ms | 100-300ms | Lower = more responsive but potential accidental repeats |
| DAS_REPEAT_RATE | 50ms | 30-100ms | Lower = faster repeat, more control |
| SOFT_DROP_SPEED | 20x normal | 5-50x | Multiplier for soft drop speed |

## Acceptance Criteria

- **GIVEN** the game is running, **WHEN** Left Arrow is pressed, **THEN** `move_left` signal is emitted.
- **GIVEN** Left Arrow is held for 200ms, **WHEN** DAS triggers, **THEN** `move_left` signal is emitted again.
- **GIVEN** Left and Right are pressed simultaneously, **WHEN** either key is released, **THEN** no movement occurs.
- **GIVEN** game is not paused, **WHEN** Escape is pressed, **THEN** `pause` signal is emitted.
- **GIVEN** game is paused, **WHEN** Escape is pressed, **THEN** `pause` signal is emitted (toggles).
- **GIVEN** hard drop is triggered, **WHEN** Space is pressed, **THEN** `hard_drop` signal is emitted immediately (no DAS).

## Open Questions

[To be designed]