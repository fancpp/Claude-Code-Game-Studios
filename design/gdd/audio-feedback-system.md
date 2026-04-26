# Audio Feedback System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

## Overview

The Audio Feedback System provides satisfying sound effects that reinforce every gameplay event: a crisp click on piece lock, a rising tone on line clear (pitch increases with combo), a decisive sound on Tetris, and a tone shift on level up. Sounds are short, punchy, and layered — they confirm actions without overwhelming. The system subscribes to game events and triggers the appropriate audio samples with correct timing and layering.

## Player Fantasy

"The game sounds as good as it plays." Every action has a sound — satisfying, immediate, never annoying. Clearing a line feels rewarding. A Tetris feels triumphant. The audio builds the rhythm of the game; players often find themselves settling into the sound of piece drops and line clears. Sound is not decoration — it is feedback that makes the game feel alive.

## Detailed Design

### Core Rules

**Sound Triggers:**

| Event | Sound | Duration | Behavior |
|-------|-------|----------|----------|
| Piece lock | Sharp click/thud | 50ms | Plays immediately on lock |
| Single clear | Mid-tone beep | 100ms | Fixed pitch |
| Double clear | Higher-tone beep | 150ms | Fixed pitch |
| Triple clear | Higher-tone beep | 200ms | Fixed pitch |
| Tetris | Chord + rising tone | 400ms | Triumphant, layered |
| Level up | Ascending arpeggio | 300ms | 3-note rising scale |
| Combo ×5 | Special chime | 200ms | Distinct from normal clears |
| Game over | Descending tone | 500ms | Final, conclusive |
| Hard drop | Heavy thud | 30ms | Lower pitch than soft drop |

**Sound Layering:**
- Multiple sounds can play simultaneously (e.g., lock click + clear beep)
- No sound cancellation — sounds that overlap simply mix
- Audio bus architecture allows independent volume control per sound type

**Volume Levels:**
- Master volume: user-controllable (0-100%)
- Sound effect volume: 80% of master by default
- Music volume: 50% of master by default (if background music added)

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| IDLE | Audio system ready | No sounds playing | Event received → PLAYING |
| PLAYING | Sound effect playing | Playback started | Playback finished → IDLE |

**Internal State:**
- active_sounds: list of currently playing audio instances
- master_volume: float (0.0 to 1.0)
- sfx_volume: float (0.0 to 1.0, relative to master)

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Tetromino System | Input | Receives `piece_locked`, `hard_drop` signals |
| Line Clearing System | Input | Receives `lines_cleared(count)` signal |
| Speed Progression System | Input | Receives `level_up` signal |
| Combo Scoring System | Input | Receives `combo_multiplier` updates |
| Game State System | Input | Receives `game_over` signal |

## Formulas

**Effective Volume Calculation:**
```
effective_volume = master_volume × sfx_volume × sound_type_scalar
# sound_type_scalar: lock=0.7, clear=0.8, tetris=1.0, etc.
```

**Pitch Variation (subtle):**
```
actual_pitch = base_pitch × uniform_random(0.98, 1.02)
# Prevents same sound from being perfectly repetitive
```

**Layered Sound (Tetris):**
```
play("tetris_base")  # 200ms chord
play("tetris_rise")  # 400ms rising tone, starts at 50ms
play("tetris_crash") # 200ms crash, starts at 150ms
```

**Variable Definitions:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| master_volume | float | 0.0-1.0 | User-set master volume |
| sfx_volume | float | 0.0-1.0 | Sound effects volume (relative) |
| effective_volume | float | 0.0-1.0 | Final playback volume |
| base_pitch | float | 0.98-1.02 | Random variation multiplier |

## Edge Cases

- **If two sounds trigger simultaneously**: Both sounds play — they mix together in the audio bus. No cancellation.
- **If sound is triggered while previous instance of same sound is playing**: New instance plays alongside the previous one (allow overlapping sounds, not queuing).
- **If game is paused**: Audio continues playing — no pause on sound. This is a design choice; pausing audio on pause is also valid.
- **If volume is set to 0**: All sounds are silent but events are still processed (no errors). Audio system is effectively muted.
- **If audio device is unavailable**: Sound calls are no-ops — game continues without sound. No crash.
- **If Tetris and level up happen on same piece**: Both sounds play simultaneously (tetris sound + level-up arpeggio).
- **If hard drop and lock happen on same piece**: Hard drop thud plays, then lock click plays on landing.

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Tetromino System | `piece_locked`, `hard_drop` signals | Triggers lock click and drop thud |
| Line Clearing System | `lines_cleared(count)` signal | Triggers clear sounds by line count |
| Speed Progression System | `level_up` signal | Triggers level-up arpeggio |
| Combo Scoring System | `combo_multiplier` | Triggers ×5 combo chime |
| Game State System | `game_over` signal | Triggers game over sound |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| (Audio Engine) | Playback calls | Godot AudioStreamPlayer or equivalent |

**Hard vs. Soft:**
- **SOFT** — All dependencies (audio is polish — game is fully playable without it, but experience is diminished)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| MASTER_VOLUME | 0.8 | 0.0-1.0 | Master volume level |
| SFX_VOLUME | 1.0 | 0.0-1.0 | Sound effects volume (relative to master) |
| LOCK_SOUND_VOLUME | 0.7 | 0.5-1.0 | Lock click volume scalar |
| CLEAR_SOUND_VOLUME | 0.8 | 0.5-1.0 | Clear beep volume scalar |
| TETRIS_SOUND_VOLUME | 1.0 | 0.8-1.0 | Tetris sound volume scalar |
| PITCH_VARIANCE | 0.02 | 0.0-0.05 | Random pitch variation range |
| SOUND_ENABLED | true | true/false | Master toggle for all sounds |

## Acceptance Criteria

- **GIVEN** a piece locks, **WHEN** `piece_locked` signal is received, **THEN** lock click sound plays at LOCK_SOUND_VOLUME.
- **GIVEN** a Tetris (4 lines) clears, **WHEN** `lines_cleared(4)` is received, **THEN** Tetris layered sound plays at TETRIS_SOUND_VOLUME.
- **GIVEN** level up occurs, **WHEN** `level_up` signal is received, **THEN** ascending arpeggio plays for 300ms.
- **GIVEN** combo multiplier reaches ×5, **WHEN** the event is received, **THEN** special combo chime plays distinct from normal clears.
- **GIVEN** game over, **WHEN** `game_over` signal is received, **THEN** descending tone plays for 500ms.
- **GIVEN** hard drop, **WHEN** `hard_drop` signal is received, **THEN** heavy thud plays immediately.
- **GIVEN** SOUND_ENABLED is set to false, **WHEN** any sound event occurs, **THEN** no sound plays but no error occurs.

## Open Questions

[To be designed]