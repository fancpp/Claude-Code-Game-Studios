# Speed Progression System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 2 — Rhythm of Growth

## Overview

The Speed Progression System controls the falling speed of tetrominoes based on the current level. Each level increases the drop speed by a fixed increment, creating a linear difficulty curve. The level increases based on lines cleared (not time). The system provides the current drop interval to the Tetromino System and emits level-up events when the threshold is crossed. This system implements Pillar 2 (Rhythm of Growth) — the player feels themselves "growing" as speed increases.

## Player Fantasy

"Falling into a rhythm." As the level climbs, the speed increases imperceptibly at first — then suddenly you realize you're playing faster than you thought possible. The growth feels earned, not imposed. Each level-up is a small victory that proves you've gotten better. The escalating speed creates a natural tension arc; surviving at high levels feels like a genuine achievement.

## Detailed Design

### Core Rules

**Level-Up Trigger:**
- Each line cleared adds to a running "lines cleared" counter
- When lines cleared >= LINES_PER_LEVEL, level increases by 1 and lines cleared counter resets
- Level starts at 1 on new game

**Lines Per Level:**
- LINES_PER_LEVEL = 10 (classic Tetris standard)
- Level N requires N × LINES_PER_LEVEL total lines to reach

**Drop Interval Formula (linear):**
```
drop_interval_ms = max(DROP_INTERVAL_MIN, INITIAL_DROP_INTERVAL - (level - 1) × SPEED_INCREMENT)
```
- Initial drop interval: 1000ms (level 1)
- Speed increment per level: 50ms
- Minimum drop interval: 100ms (cap)

**Level Cap:**
- Maximum level: 15 (after which speed remains at minimum interval)

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| LEVEL_N | Current level is N | Lines threshold crossed | Next level threshold crossed |
| MAX_LEVEL | Cap reached | Level reaches 15 | (no exit — stays at max) |

**Internal State:**
- current_level: int (starts at 1)
- lines_since_last_level: int (resets on level-up)
- current_drop_interval: ms (derived from level)

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Line Clearing System | Input | Receives `lines_cleared(count)` signal |
| Tetromino System | Output | Sends `drop_interval_ms` for gravity timer |
| Score Display System | Output | Sends current `level` for display |

## Formulas

**Drop Interval Calculation:**
```
drop_interval_ms = max(DROP_INTERVAL_MIN, INITIAL_DROP_INTERVAL - (level - 1) × SPEED_INCREMENT)
```

**Level-Up Check:**
```
lines_since_last_level += lines_cleared
if lines_since_last_level >= LINES_PER_LEVEL:
  level += 1
  lines_since_last_level -= LINES_PER_LEVEL
  emit level_up(new_level)
```

**Variable Definitions:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| level | int | 1-15 | Current game level |
| drop_interval_ms | int | 100-1000 | Milliseconds between automatic drops |
| lines_since_last_level | int | 0+ | Accumulated lines since last level-up |
| LINES_PER_LEVEL | int | 10 (fixed) | Lines needed per level-up |

## Edge Cases

- **If multiple lines clear at once and push level past cap**: Level caps at 15. Any remaining lines that would have contributed to level 16+ are lost (no carry-over beyond cap).
- **If game is restarted mid-level**: Level resets to 1, lines counter resets to 0, drop interval resets to INITIAL_DROP_INTERVAL.
- **If game is paused**: Level and lines counter are preserved; drop interval does not change.
- **If Tetris (4 lines) clears**: All 4 lines count toward the lines-per-level total in one event — could trigger multiple level-ups if near a threshold.
- **If lines_since_last_level is already near threshold**: A single multi-line clear could cross the threshold by multiple levels (unlikely but possible at very high speeds — handled by loop in level-up check).

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Line Clearing System | `lines_cleared(count)` signal | Triggers level-up check with line count |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Tetromino System | `drop_interval_ms` | Sets gravity timer interval |
| Score Display System | `level` | Displays current level to player |

**Hard vs. Soft:**
- **HARD** — Line Clearing System (level progression is driven entirely by line clears)
- **SOFT** — Tetromino System (if not connected, game still playable but speed won't increase)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| INITIAL_DROP_INTERVAL | 1000ms | 500-2000ms | Drop interval at level 1 |
| SPEED_INCREMENT | 50ms | 20-100ms | Drop interval reduction per level |
| DROP_INTERVAL_MIN | 100ms | 50-300ms | Minimum drop interval (speed cap) |
| LINES_PER_LEVEL | 10 | 5-20 | Lines required per level-up |
| MAX_LEVEL | 15 | 10-20 | Maximum level before speed caps |

## Acceptance Criteria

- **GIVEN** new game starts, **WHEN** first piece spawns, **THEN** level = 1 and drop_interval = 1000ms.
- **GIVEN** level = 1 and lines_since_last_level = 9, **WHEN** 1 line is cleared, **THEN** level becomes 2 and drop_interval becomes 950ms.
- **GIVEN** level = 5 and drop_interval = 800ms, **WHEN** 10 more lines are cleared, **THEN** level becomes 6 and drop_interval becomes 750ms.
- **GIVEN** level = 14 (drop_interval = 350ms), **WHEN** level-up to 15 occurs, **THEN** drop_interval becomes 100ms (MIN cap).
- **GIVEN** level = 15, **WHEN** more lines are cleared, **THEN** level stays at 15 and drop_interval stays at 100ms.
- **GIVEN** lines_since_last_level = 5, **WHEN** a Tetris (4 lines) is cleared, **THEN** lines_since_last_level becomes 9, triggering level-up to level+1.
- **GIVEN** new game signal received, **WHEN** game resets, **THEN** level = 1, lines_since_last_level = 0, drop_interval = 1000ms.

## Open Questions

[To be designed]