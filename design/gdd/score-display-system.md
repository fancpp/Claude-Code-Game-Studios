# Score Display System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 3 — Combo Reward

## Overview

The Score Display System renders the player-facing HUD elements: current score, current level, current combo counter, and (if implemented) next piece preview. It subscribes to score updates from the Combo Scoring System and level updates from the Speed Progression System, rendering the values to screen in real-time. The display updates immediately on every score event so the player always sees their current state.

## Player Fantasy

"The numbers tell the story of your game." Score, level, and combo are always visible and always accurate. The player glances at the HUD and instantly knows where they stand. High combo lights up. Score climbs. Level increases. The display never distracts from gameplay — it enhances it by making achievement visible.

## Detailed Design

### Core Rules

**HUD Elements:**
| Element | Source | Format |
|---------|--------|--------|
| Score | Combo Scoring System | Integer, right-aligned, 0-padded to 6 digits |
| Level | Speed Progression System | Integer, displayed as "LV {N}" |
| Combo | Combo Scoring System | Integer, shown only when combo > 0 |
| Next Piece | Piece Spawn System | Piece type (1-7), rendered as mini-grid |

**Score Display Format:**
- Score displays with leading zeros up to 6 digits (e.g., 001250)
- No commas or separators — pure numeric display
- Maximum displayable: 999999 (7 digits triggers overflow display: "999999+")

**Combo Display:**
- Only visible when combo_counter > 0
- Format: "×N" where N is the combo multiplier (1-5)
- Hidden immediately when combo resets to 0

**Level Display:**
- Always visible during gameplay
- Format: "LV {level}"
- Resets to "LV 1" on new game

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| PLAYING | HUD fully visible | Game starts | Game over → GAME_OVER |
| GAME_OVER | HUD frozen, shows final score | Game over signal | New game → PLAYING |

**Internal State:**
- displayed_score: current score shown
- displayed_level: current level shown
- displayed_combo: current combo shown (0 = hidden)
- displayed_next_piece: next piece type

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Combo Scoring System | Input | Receives `score_changed`, `combo_changed` signals |
| Speed Progression System | Input | Receives `level_up` signal |
| Piece Spawn System | Input | Receives `next_piece` preview data |

## Formulas

**Score Formatting:**
```
display_string = if score > 999999:
  "999999+"
else:
  right_justify(score, 6).pad_start(6, '0')
```

**HUD Position (relative to grid):**
```
score_x = GRID_RIGHT_X + 16  # 16px margin from grid
score_y = GRID_TOP_Y
level_x = GRID_RIGHT_X + 16
level_y = score_y + 24
combo_x = GRID_RIGHT_X + 16
combo_y = level_y + 24
```

**Variable Definitions:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| displayed_score | int | 0-999999+ | Score value shown on HUD |
| displayed_level | int | 1-15 | Level value shown on HUD |
| displayed_combo | int | 0-5 | Combo multiplier shown (0=hidden) |
| GRID_RIGHT_X | int | 320 | Right edge of the play grid in pixels |
| GRID_TOP_Y | int | 0 | Top edge of the play grid in pixels |

## Edge Cases

- **If score exceeds 999999**: Display shows "999999+" — the actual score continues to accumulate internally but the display caps.
- **If combo resets to 0 during render**: Combo display immediately hides (no lingering "×0" shown).
- **If game is paused**: HUD remains visible and static — values do not change during pause.
- **If game is over**: HUD freezes at the final values; score, level, and combo all remain visible.
- **If next piece is requested before queue has content**: Display shows placeholder (e.g., "?" or empty) until queue is populated.
- **If score changes by a large amount (e.g., Tetris with high combo)**: Score updates atomically to the new value — no rolling/counting animation (keep it instant per pillars).

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Combo Scoring System | `score_changed`, `combo_changed` signals | Provides score and combo state for display |
| Speed Progression System | `level_up` signal | Provides current level for display |
| Piece Spawn System | `next_piece` | Provides next piece preview (Vertical Slice, not MVP) |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| (Rendering) | HUD render calls | Rendering system draws the HUD elements |

**Hard vs. Soft:**
- **HARD** — Combo Scoring System (score display is core to the experience)
- **SOFT** — Speed Progression System (level display is important but could be deferred)
- **SOFT** — Piece Spawn System (next piece preview is Vertical Slice, not MVP)

**Note:** Score Display does NOT listen for a `pause` signal from Game State. Pause is handled internally by Game State — the signal-driven display simply stops receiving update signals when the game is paused, which preserves the last-seen values without any explicit pause wiring.

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| SCORE_PADDING | 6 | 4-8 | Number of digits to display (0-padded) |
| HUD_MARGIN | 16px | 8-32px | Space between grid and HUD elements |
| HUD_FONT_SIZE | 16px | 12-24px | Font size for HUD text |
| COMBO_VISIBLE_THRESHOLD | 1 | 1-5 | Minimum combo to show (always show ×1 or only ×2+?) |

## Acceptance Criteria

- **GIVEN** score = 1250, **WHEN** score is rendered, **THEN** display shows "001250".
- **GIVEN** score = 1000000, **WHEN** score is rendered, **THEN** display shows "999999+".
- **GIVEN** combo_counter = 0, **WHEN** HUD is rendered, **THEN** combo display is hidden.
- **GIVEN** combo_counter = 3, **WHEN** HUD is rendered, **THEN** combo display shows "×3".
- **GIVEN** level changes from 5 to 6, **WHEN** level is rendered, **THEN** display shows "LV 6".
- **GIVEN** new game starts, **WHEN** HUD is rendered, **THEN** score shows "000000", level shows "LV 1", and combo is hidden.
- **GIVEN** game is paused, **WHEN** HUD continues to be rendered, **THEN** values remain unchanged from before the pause.

## Open Questions

[To be designed]