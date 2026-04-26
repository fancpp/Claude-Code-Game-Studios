# Line Clearing System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 3 — Combo Reward

## Overview

The Line Clearing System detects completed horizontal rows on the grid after each piece locks, removes those rows, and collapses the remaining rows downward to fill the gaps. It identifies 1-4 simultaneous line clears (Single, Double, Triple, Tetris), emits line count to the Combo Scoring System, and handles the visual and data transitions. Row collapse must be atomic — no intermediate states visible to the player.

## Player Fantasy

"The line vanishes and the stack drops with satisfying weight." When a line clears, it feels like a small victory — the row dissolves, the remaining blocks cascade down in one smooth motion, and the score ticks up. Multiple lines cleared at once (especially a Tetris) feel powerful and earned. The visual feedback is immediate and clean; no stutter, no ambiguity about what happened.

## Detailed Design

### Core Rules

**Line Clear Detection:**
After a piece locks, scan all rows from bottom to top (y=0 to y=19). A row is complete when all 10 cells (x=0 to x=9) are occupied. Collect all complete rows into a list.

**Line Clear Types:**
| Name | Lines Cleared | Code |
|------|---------------|------|
| Single | 1 | 1 |
| Double | 2 | 2 |
| Triple | 3 | 3 |
| Tetris | 4 | 4 |

**Row Collapse (stack reduction):**
1. Identify all completed rows
2. Remove all completed rows from the grid (set cells to EMPTY)
3. For each remaining row, count how many completed rows were below it
4. Shift each remaining row down by that count (copy cell data, then clear original position)
5. Clear any rows above the highest cleared row that are now empty at the top

**Collapse Direction:**
Rows collapse from bottom to top. The bottommost cleared row is removed first; rows above drop into the vacated space. The operation is atomic — all cleared rows disappear simultaneously, then all remaining rows shift down together.

**Row Clearing and Stack Integrity:**
- No floating blocks — all occupied cells above a cleared row drop the full distance
- No partial shifts — a row either shifts by the exact count of cleared rows below it or stays in place
- Topmost rows that become empty after collapse are left as EMPTY (no wrapping)

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| IDLE | No lines to clear | Piece just locked, no complete rows found | Next piece spawns |
| CLEARING | Lines detected and being removed | Complete rows found after piece lock | Collapse complete → IDLE |

**Internal State:**
- cleared_rows: list of y-coordinates for rows to clear
- rows_collapsed: count of rows removed in this operation

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Grid System | Input/Output | Reads all rows to detect clears; writes cleared rows to EMPTY; shifts rows down |
| Tetromino System | Input | Receives `piece_locked` signal to trigger line clear check |
| Combo Scoring System | Output | Emits `lines_cleared(count)` with number of lines cleared |
| Speed Progression System | Output | Emits `lines_cleared(count)` for level-up calculation |
| Visual Feedback System | Output | Emits `lines_cleared(count)` for flash/particle effects |

## Formulas

**Line Complete Check:**
```
is_row_complete(y) = AND(
  for x from 0 to 9:
    get_cell(x, y) != EMPTY
)
```

**Row Collapse Calculation:**
```
cleared_count = number of rows where is_row_complete(y) == true
for each remaining row ry:
  shift_amount = count of cleared rows where cleared_y < ry
  new_y = ry - shift_amount
  copy_row(ry, new_y)
  clear_row(ry)
```

**Clear Type Classification:**
```
clear_type = cleared_count
1 -> Single
2 -> Double
3 -> Triple
4 -> Tetris
```

## Edge Cases

- **If 4 lines clear simultaneously (Tetris)**: All 4 rows are removed, then all rows above shift down by 4. This is handled identically to any other multi-line clear — no special casing.
- **If a piece locks and no lines are complete**: No action. Immediately transition to IDLE and trigger next piece spawn.
- **If multiple non-adjacent rows are complete**: All cleared rows are identified, then all are removed, then all remaining rows shift down by the correct amount. No row is skipped.
- **If a row is partially filled (has EMPTY cells)**: That row is not cleared. The scan checks all 10 cells; if any are EMPTY, the row is not in the cleared list.
- **If a row is completely empty (all cells EMPTY)**: Not a completed row. Scanning starts from y=0 (bottom) and goes to y=19 (top); empty rows above the stack don't trigger any action.
- **If collapse results in a row with mixed new/old data**: The collapse operation copies entire rows atomically — no mixed rows. Each row destination is filled from exactly one source row.
- **If a piece locks at the same time as line clear**: The piece lock triggers the line clear check. Both operations happen in sequence: first the piece writes to the grid, then line clear scans and collapses.

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Grid System | `get_cell(x, y)`, `set_cell(x, y, value)` | Reads grid to detect complete rows; writes cleared rows to EMPTY |
| Tetromino System | `piece_locked` signal | Triggers line clear check after each piece locks |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Combo Scoring System | `lines_cleared(count)` | Receives line count for scoring calculation |
| Speed Progression System | `lines_cleared(count)` | Receives line count for level progression |
| Visual Feedback System | `lines_cleared(count)` | Triggers visual effects (flash, particles) |

**Hard vs. Soft:**
- **HARD** — Grid System (cannot function without grid state access)
- **HARD** — Tetromino System (only triggered when piece locks)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| LINE_CLEAR_DELAY | 0ms | 0-500ms | Delay between detecting lines and collapsing (for visual effect timing) |
| SOFT_DROP_LINES | 1 | 1-4 | Minimum lines to clear for soft drop bonus (if applicable) |

## Acceptance Criteria

- **GIVEN** a grid where row y=0 has all 10 cells occupied, **WHEN** line clear is checked, **THEN** row y=0 is identified as complete.
- **GIVEN** rows y=3 and y=5 are complete, **WHEN** collapse happens, **THEN** all rows above y=5 shift down by 2 and rows y=3 and y=5 are removed.
- **GIVEN** 4 non-adjacent rows are complete, **WHEN** collapse happens, **THEN** all 4 rows are removed and remaining rows shift down by 4.
- **GIVEN** a row has 9 occupied cells and 1 EMPTY cell, **WHEN** line clear is checked, **THEN** that row is NOT cleared.
- **GIVEN** a piece locks and no rows are complete, **WHEN** line clear check runs, **THEN** no rows are cleared and cleared_count = 0.
- **GIVEN** 3 lines are cleared, **WHEN** the collapse completes, **THEN** `lines_cleared(3)` signal is emitted to downstream systems.
- **GIVEN** a row at y=10 has occupied cells, **WHEN** 2 rows below it (y=3, y=4) are cleared, **THEN** the row at y=10 shifts to y=8 (moves down by exactly 2).

## Open Questions

[To be designed]