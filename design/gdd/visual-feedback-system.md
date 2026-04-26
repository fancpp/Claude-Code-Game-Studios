# Visual Feedback System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

## Overview

The Visual Feedback System provides immediate, satisfying visual responses to gameplay events: screen flash on line clear, shake on Tetris, piece color pulse on lock, and combo glow effects. It transforms mechanical events into felt moments — every action produces visible feedback. The system subscribes to events from other systems (line clears, piece locks, level-ups, game over) and triggers the appropriate visual effect with correct timing and intensity.

## Player Fantasy

"The game responds to every action." When you clear a line, you see it. When you land a Tetris, you feel it. When your combo climbs, the screen lights up with your momentum. The game is never silent or static — every moment of gameplay produces a visual response that confirms what just happened and makes it feel significant.

## Detailed Design

### Core Rules

**Effect Triggers:**

| Event | Effect | Duration | Intensity |
|-------|--------|----------|-----------|
| Single line clear | White screen flash | 100ms | Low |
| Double line clear | White screen flash | 150ms | Medium |
| Triple line clear | White screen flash + slight shake | 200ms | High |
| Tetris (4 lines) | White screen flash + strong shake + background pulse | 300ms | Maximum |
| Piece lock | Brief piece color brightening | 50ms | Low |
| Level up | Green flash on level display | 200ms | Medium |
| Combo ×5 | Gold glow around combo display | 500ms | High |
| Game over | Screen dims to 50% brightness | Instant | N/A |

**Screen Shake:**
- Shake offset applied to entire game canvas
- Shake is random x/y offset within shake magnitude
- Shake magnitude: 2px for Single/Double, 4px for Triple, 8px for Tetris
- Shake decays linearly over shake duration

**Screen Flash:**
- Entire screen overlaid with white at low opacity
- Opacity starts at 30% and decays to 0% over duration
- Flash color: white for all line clears

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| IDLE | No effect active | No events occurring | Effect triggered → EFFECT_ACTIVE |
| EFFECT_ACTIVE | Visual effect playing | Event received | Effect duration expires → IDLE |
| GAME_OVER_EFFECT | Dimmed screen | Game over signal | New game → IDLE |

**Internal State:**
- active_effects: list of currently playing effects
- effect_start_time: timestamp when each effect started
- shake_offset: current (x, y) offset for shake

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Line Clearing System | Input | Receives `lines_cleared(count)` signal |
| Tetromino System | Input | Receives `piece_locked` signal |
| Speed Progression System | Input | Receives `level_up` signal |
| Combo Scoring System | Input | Receives `combo_multiplier` updates |
| Game State System | Input | Receives `game_over` signal |

## Formulas

**Screen Shake Offset:**
```
elapsed = current_time - shake_start_time
progress = elapsed / shake_duration
shake_magnitude = SHAKE_MAGNITUDE × (1 - progress)  # linear decay
shake_offset_x = random(-shake_magnitude, shake_magnitude)
shake_offset_y = random(-shake_magnitude, shake_magnitude)
```

**Screen Flash Opacity:**
```
elapsed = current_time - flash_start_time
progress = elapsed / flash_duration
flash_opacity = FLASH_INITIAL_OPACITY × (1 - progress)
```

**Combo Glow Intensity:**
```
elapsed = current_time - glow_start_time
progress = elapsed / glow_duration
glow_intensity = (1 - progress)  # fades out
glow_color = gold (RGB: 255, 215, 0)
```

**Variable Definitions:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| shake_duration | int | 100-300ms | How long shake lasts |
| shake_magnitude | float | 2-8px | Maximum shake offset |
| flash_initial_opacity | float | 0.3 | Starting flash opacity |
| flash_duration | int | 100-300ms | How long flash lasts |
| glow_duration | int | 500ms | How long combo glow lasts |

## Edge Cases

- **If two effects trigger simultaneously**: Both effects play — they are independent (flash and shake can coexist). Effects are additive.
- **If Tetris triggers while another effect is playing**: New effect starts immediately; existing effect continues. No cancellation.
- **If game is paused mid-effect**: Effect pauses at current frame. Resumes on unpause. This avoids visual discontinuity.
- **If level up and Tetris happen at the same time**: Both effects play. The higher-intensity effect dominates the shake magnitude but both flashes render.
- **If combo glow is active and combo breaks (resets to 0)**: Glow cancels immediately — no fade out. The combo glow was for active combo only.
- **If game over triggers during an effect**: Effects freeze at current state, then game over dim takes full effect.

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Line Clearing System | `lines_cleared(count)` signal | Triggers flash/shake based on line count |
| Tetromino System | `piece_locked` signal | Triggers lock pulse effect |
| Speed Progression System | `level_up` signal | Triggers level-up flash |
| Combo Scoring System | `combo_multiplier` | Triggers combo glow at ×5 |
| Game State System | `game_over` signal | Triggers screen dim |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| (Rendering) | Shake offset, flash overlay, glow | Rendering system applies visual effects |

**Hard vs. Soft:**
- **SOFT** — All dependencies (visual feedback is polish — game is fully playable without it, but the experience is diminished)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| FLASH_INITIAL_OPACITY | 0.3 | 0.1-0.5 | Starting brightness of screen flash |
| SHAKE_MAGNITUDE_SINGLE | 2px | 1-4px | Shake for single line |
| SHAKE_MAGNITUDE_DOUBLE | 2px | 1-4px | Shake for double line |
| SHAKE_MAGNITUDE_TRIPLE | 4px | 2-6px | Shake for triple line |
| SHAKE_MAGNITUDE_TETRIS | 8px | 4-12px | Shake for tetris |
| FLASH_DURATION_SINGLE | 100ms | 50-200ms | Flash duration per clear type |
| FLASH_DURATION_DOUBLE | 150ms | 100-250ms | Flash duration per clear type |
| FLASH_DURATION_TRIPLE | 200ms | 150-300ms | Flash duration per clear type |
| FLASH_DURATION_TETRIS | 300ms | 200-500ms | Flash duration per clear type |
| COMBO_GLOW_DURATION | 500ms | 200-1000ms | How long ×5 combo glow lasts |
| LOCK_PULSE_DURATION | 50ms | 20-100ms | Duration of piece lock brightening |

## Acceptance Criteria

- **GIVEN** a Single line clear, **WHEN** `lines_cleared(1)` is received, **THEN** white flash plays for 100ms at 30% opacity.
- **GIVEN** a Tetris (4 lines), **WHEN** `lines_cleared(4)` is received, **THEN** white flash plays for 300ms at 30% opacity AND screen shakes with 8px magnitude for 300ms.
- **GIVEN** combo multiplier reaches ×5, **WHEN** the event is received, **THEN** gold glow appears around the combo display for 500ms.
- **GIVEN** level up event, **WHEN** received, **THEN** green flash appears on the level display for 200ms.
- **GIVEN** game over signal, **WHEN** received, **THEN** screen dims to 50% brightness.
- **GIVEN** screen shake is playing and game is paused, **WHEN** pause occurs, **THEN** shake freezes at current offset and resumes on unpause.
- **GIVEN** a Tetris triggers while a lock pulse is playing, **WHEN** both events fire, **THEN** both effects play simultaneously without cancellation.

## Open Questions

[To be designed]