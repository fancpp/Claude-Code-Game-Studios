# Game State System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 4 — Instant Retry

---

## Overview

The Game State System manages the high-level state machine of the game: IDLE, PLAYING, PAUSED, and GAME_OVER. It controls which subsystems are active, responds to pause input, detects game-over conditions, and orchestrates new game initialization. It is the top-level coordinator — other systems run only when this system permits them.

## Player Fantasy

"The game is always ready for me." Starting feels instant — no splash screens, no menus. Pausing is a breath, not a commitment. Game over is a clean break, not a dead end. Every state transition is seamless and the "Play Again" moment is always less than 2 seconds away. The player never waits for the game; the game waits for the player.

## Detailed Design

### Core Rules

**Game States:**
| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| IDLE | Initial state, waiting to start | Game load complete | Player presses start |
| PLAYING | Active gameplay | From IDLE on start | Game over or pause |
| PAUSED | Gameplay frozen | From PLAYING on pause key | From PAUSED on pause key |
| GAME_OVER | No more moves possible | New piece cannot spawn | Player presses restart |

**State Transitions:**
```
IDLE -> PLAYING: Start game
PLAYING -> PAUSED: Pause key
PLAYING -> GAME_OVER: Game over condition met
PAUSED -> PLAYING: Pause key
GAME_OVER -> PLAYING: Restart (new game)
```

**Game Over Detection:**
- Trigger: When the Spawn System attempts to place a new piece and finds the spawn position (x=4, y=19) is already occupied.
- Action: Transition to GAME_OVER state, emit `game_over` signal.

**New Game Initialization:**
1. Clear grid (`clear_grid()`)
2. Reset score to 0
3. Reset level to 1
4. Reset combo counter to 0
5. Request first piece spawn
6. Transition to PLAYING

**Pause Behavior:**
- When PAUSED: All gameplay loops stop (piece dropping, input processing except pause)
- When UNPAUSED: All gameplay loops resume from exact state

### States and Transitions

| Current State | Event | Next State | Actions |
|---------------|-------|------------|---------|
| IDLE | start_input | PLAYING | Init game, spawn piece |
| PLAYING | pause_input | PAUSED | Freeze all loops |
| PLAYING | game_over_condition | GAME_OVER | Stop loops, show game over |
| PAUSED | pause_input | PLAYING | Resume loops |
| GAME_OVER | restart_input | PLAYING | New game init |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| All Systems | Control | State machine drives gameplay loops — all systems act based on current state |
| Speed Progression System | Output | Emits `new_game` signal — triggers level/speed reset |
| Score Display System | Output | Emits `new_game` signal — triggers score/level/combo reset |
| Combo Scoring System | Output | Emits `new_game` signal — triggers combo counter reset |
| Visual Feedback System | Output | Emits `game_over` signal — triggers game over visual |
| Audio Feedback System | Output | Emits `game_over` signal — triggers game over sound |

## Formulas

This system is a state machine with no mathematical formulas. State transitions are event-driven:

```
current_state = IDLE | PLAYING | PAUSED | GAME_OVER
```

All logic is boolean conditions and state assignments, not calculations.

## Edge Cases

- **If pause is pressed during game over**: No-op. Pause only works during PLAYING.
- **If start is pressed during PLAYING**: No-op. Start only works during IDLE.
- **If restart is pressed during PLAYING**: No-op. Restart only works during GAME_OVER.
- **If pause key is held**: Trigger once on press, not on hold. No continuous toggling.
- **If game over happens during pause**: Queue game over. Apply when unpaused.
- **If new game started while in GAME_OVER**: Immediate transition to PLAYING, no intermediate IDLE.

## Dependencies

**Upstream Dependencies:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Grid System | `clear_grid()` | Resets grid for new game |
| Input System | `pause` signal | Pauses/unpauses game |

**Downstream Dependents:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| All gameplay systems | State signals | Enable/disable based on game state |
| Score Display System | Score reset | Receives reset on new game |
| Speed Progression System | Level reset | Receives reset on new game |
| Combo Scoring System | Combo reset | Receives reset on new game |

**Hard vs. Soft:**
- **HARD** — Grid System (for new game init)
- **SOFT** — Input System (game can run without pause if input broken)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| NEW_GAME_INIT_TIME | 0ms | 0-500ms | Time to initialize new game (should be instant) |
| GAME_OVER_DELAY | 0ms | 0-1000ms | Delay before game over screen appears |

## Acceptance Criteria

- **GIVEN** game is in IDLE state, **WHEN** player presses start, **THEN** state becomes PLAYING and piece spawns.
- **GIVEN** game is in PLAYING state, **WHEN** player presses pause, **THEN** state becomes PAUSED.
- **GIVEN** game is in PAUSED state, **WHEN** player presses pause, **THEN** state becomes PLAYING.
- **GIVEN** game is in PLAYING state, **WHEN** game over condition is met, **THEN** state becomes GAME_OVER.
- **GIVEN** game is in GAME_OVER state, **WHEN** player presses restart, **THEN** state becomes PLAYING and grid is cleared.
- **GIVEN** game is in PLAYING state, **WHEN** pause is pressed and held, **THEN** pause only triggers once (not toggling).

## Open Questions

[To be designed]