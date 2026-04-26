# Combo Scoring System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 3 — Combo Reward

## Overview

The Combo Scoring System tracks consecutive line clears across a game, applies a combo multiplier that rewards sustained play, and calculates the total score earned per line clear event. The combo counter increments with each line clear and resets when a piece lands without clearing any lines. Score = base_points × lines_cleared × combo_multiplier. The system is the primary driver of Pillar 3 (Combo Reward) — it makes consecutive clears feel progressively more valuable.

## Player Fantasy

"Each line clears for more than the last." The combo counter climbing feels like momentum building. When the combo hits 5 or 10, the player feels unstoppable. Breaking a long combo feels like a small loss — a streak interrupted. The score isn't just a number; it's a measure of how well the player is playing. Maintaining a high combo for many pieces is more satisfying than a lucky Tetris with no combo.

## Detailed Design

### Core Rules

**Combo Counter:**
- Starts at 0 on new game
- Increments by 1 each time lines are cleared (any non-zero clear count)
- Resets to 0 when a piece locks with 0 lines cleared

**Combo Multiplier:**
The combo multiplier increases the score of each cleared line based on how many consecutive clears have occurred.

| Combo Value | Multiplier |
|-------------|------------|
| 0 | 1× |
| 1 | 1× |
| 2 | 2× |
| 3 | 3× |
| 4 | 4× |
| 5+ | 5× (capped) |

**Base Point Values (per line):**
| Clear Type | Base Points |
|------------|-------------|
| Single (1 line) | 100 |
| Double (2 lines) | 300 |
| Triple (3 lines) | 500 |
| Tetris (4 lines) | 800 |

**Score Formula:**
```
line_points = BASE_POINTS[lines_cleared]
combo_multiplier = min(combo_counter, MAX_COMBO_MULTIPLIER)
score_earned = line_points × lines_cleared × combo_multiplier
total_score += score_earned
```

**Soft Drop Bonus:**
Soft drop adds 1 point per cell dropped.

**Hard Drop Bonus:**
Hard drop adds 2 points per cell dropped.

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| COMBO_ACTIVE | Consecutive clears ongoing | Combo counter > 0 | Piece locks with 0 lines → COMBO_BROKEN |
| COMBO_BROKEN | No lines cleared this piece | Lines cleared = 0 | Next line clear → COMBO_ACTIVE |

**Internal State:**
- combo_counter: int (starts at 0)
- total_score: int (cumulative score)
- current_combo_multiplier: int (derived from counter)

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Line Clearing System | Input | Receives `lines_cleared(count)` signal |
| Score Display System | Output | Emits `score_changed(new_score)`, `combo_changed(counter, multiplier)` signals |
| Game State System | Input | Receives `new_game` signal to reset score/combo |
| Audio Feedback System | Output | Emits `combo_x5` signal when combo first reaches 5 |
| Input System | Input | Receives `soft_drop` and `hard_drop` signals for drop score |

## Formulas

**Combo Multiplier:**
```
combo_multiplier = min(combo_counter, MAX_COMBO_MULTIPLIER)
# MAX_COMBO_MULTIPLIER = 5 (capped)
```

**Score Per Clear:**
```
score_earned = BASE_POINTS[lines_cleared] × lines_cleared × combo_multiplier
```

**Total Score:**
```
total_score = sum(score_earned for each clear event) + soft_drop_score + hard_drop_score
```

**Soft Drop Score:**
```
soft_drop_score = soft_drop_distance × SOFT_DROP_POINTS_PER_CELL
# SOFT_DROP_POINTS_PER_CELL = 1
```

**Hard Drop Score:**
```
hard_drop_score = hard_drop_distance × HARD_DROP_POINTS_PER_CELL
# HARD_DROP_POINTS_PER_CELL = 2
```

**Variable Definitions:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| combo_counter | int | 0+ | Current consecutive clear count |
| total_score | int | 0+ | Running total score |
| lines_cleared | int | 1-4 | Lines cleared this piece |
| combo_multiplier | int | 1-5 | Current multiplier (capped) |

## Edge Cases

- **If piece locks with 0 lines cleared**: Combo resets to 0. This is the only way the combo breaks.
- **If combo counter reaches 100+**: Multiplier stays capped at 5× (no overflow). The counter still increments for display purposes.
- **If game is restarted**: Total score resets to 0, combo counter resets to 0.
- **If game is paused during play**: Score and combo state are preserved (no change).
- **If hard drop and line clear happen simultaneously**: Both bonuses apply — hard drop distance × 2, plus line clear score with current combo.
- **If soft drop and line clear happen simultaneously**: Both bonuses apply — soft drop distance × 1, plus line clear score with current combo.
- **If player tops out (game over) without clearing lines**: Final score is whatever was accumulated; combo counter is irrelevant at that point.

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Line Clearing System | `lines_cleared(count)` signal | Triggers score calculation; provides line count |
| Input System | `soft_drop`, `hard_drop` signals | Provides drop distance for drop scoring |
| Game State System | `new_game` signal | Resets score and combo on game restart |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Score Display System | `score_changed`, `combo_changed` | Receives score and combo updates for display |
| Audio Feedback System | `combo_x5` | Triggers special combo chime sound when combo reaches ×5 |

**Signals Emitted:**
| Signal | Arguments | When |
|--------|-----------|------|
| `score_changed` | `new_score: int` | Score changes (after line clear, soft drop, hard drop) |
| `combo_changed` | `counter: int, multiplier: int` | Combo counter or multiplier changes |
| `combo_x5` | — | Combo multiplier first reaches 5 (triggers distinct audio chime) |

**Hard vs. Soft:**
- **HARD** — Line Clearing System (scoring depends entirely on line clear events)
- **SOFT** — Input System (drop scoring is additive, game is playable without it)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| MAX_COMBO_MULTIPLIER | 5 | 3-10 | Cap on combo multiplier |
| BASE_SINGLE | 100 | 50-200 | Points for clearing 1 line |
| BASE_DOUBLE | 300 | 150-500 | Points for clearing 2 lines |
| BASE_TRIPLE | 500 | 250-800 | Points for clearing 3 lines |
| BASE_TETRIS | 800 | 400-1500 | Points for clearing 4 lines |
| SOFT_DROP_POINTS_PER_CELL | 1 | 1-5 | Score per cell of soft drop |
| HARD_DROP_POINTS_PER_CELL | 2 | 1-10 | Score per cell of hard drop |

## Acceptance Criteria

- **GIVEN** new game starts, **WHEN** first piece is placed, **THEN** combo_counter = 0 and total_score = 0.
- **GIVEN** combo_counter = 0, **WHEN** a Single (1 line) is cleared, **THEN** score_earned = 100 × 1 × 1 = 100 and combo_counter becomes 1.
- **GIVEN** combo_counter = 2, **WHEN** a Double (2 lines) is cleared, **THEN** score_earned = 300 × 2 × 2 = 1200 and combo_counter becomes 3.
- **GIVEN** combo_counter = 4, **WHEN** a Tetris (4 lines) is cleared, **THEN** score_earned = 800 × 4 × 4 = 12800 and combo_counter becomes 5.
- **GIVEN** combo_counter = 100 (or any value > 5), **WHEN** a line is cleared, **THEN** combo_multiplier = 5 (capped) and score uses 5× multiplier.
- **GIVEN** combo_counter = 3, **WHEN** a piece locks with 0 lines cleared, **THEN** combo_counter resets to 0.
- **GIVEN** hard drop of 10 cells, **WHEN** piece locks, **THEN** hard_drop_score = 10 × 2 = 20 added to total.
- **GIVEN** new game signal received, **WHEN** game resets, **THEN** total_score = 0 and combo_counter = 0.

## Open Questions

[To be designed]