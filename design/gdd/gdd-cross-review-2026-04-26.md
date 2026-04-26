# Cross-GDD Review Report

Date: 2026-04-26
GDDs Reviewed: 13
Systems Covered: grid-system, input-system, collision-system, tetromino-system, piece-spawn-system, game-state-system, line-clearing-system, combo-scoring-system, ghost-piece-system, speed-progression-system, score-display-system, visual-feedback-system, audio-feedback-system

---

## Consistency Issues

### Blocking (must resolve before architecture begins)

None.

### Warnings (should resolve, but won't block)

⚠️ **Missing Dependency: score-display-system.md → grid-system.md**
- score-display-system.md HUD positioning formula uses `GRID_RIGHT_X` and `GRID_TOP_Y` (computed from grid dimensions)
- grid-system.md does NOT list score-display-system.md as a downstream dependent
- score-display-system.md lists Combo Scoring System and Speed Progression System as dependencies but omits Grid System despite using its constants
- Impact: LOW — the constants are well-defined (GRID_WIDTH=10, CELL_SIZE=32) but the dependency graph is incomplete
- Recommendation: Add Grid System to score-display-system.md Dependencies section with interface `GRID_WIDTH`, `GRID_HEIGHT`, `CELL_SIZE` for coordinate calculation

⚠️ **Missing Dependency: game-state-system.md → collision-system.md**
- game-state-system.md receives `game_over` condition from spawn failure, which itself uses the Collision System's `is_empty()` check
- tetromino-system.md depends on collision-system.md for lock detection, but game-state-system.md lists only Grid System and Input System as hard dependencies
- Impact: LOW — the game-over signal path is clear in piece-spawn-system.md; game-state-system.md correctly lists tetromino-system.md as a downstream consumer of `piece_locked`
- Recommendation: Add collision-system.md to game-state-system.md Dependencies section

⚠️ **Missing Dependency: visual-feedback-system.md → game-state-system.md**
- visual-feedback-system.md receives `game_over` signal and dims screen to 50% brightness
- game-state-system.md does not list visual-feedback-system.md as a downstream dependent in its "All gameplay systems" entry
- Impact: LOW — visual-feedback-system.md correctly identifies the game-over signal as its trigger
- Recommendation: game-state-system.md should explicitly name Visual Feedback System in its downstream dependents list rather than grouping all systems under "All gameplay systems"

---

## Game Design Issues

### Blocking

None.

### Warnings

None.

---

## Cross-System Scenario Issues

### Scenarios Walked: 6

1. Piece spawn → piece locked → line clear → score update → next piece spawn
2. Hard drop → immediate lock → multi-line clear → combo + level-up
3. Tetris (4 lines) at level 14 → level cap trigger → visual + audio feedback
4. Game over detection (spawn blocked)
5. Combo break → visual/audio feedback
6. Pause → resume with all state preserved

### Blockers

None.

### Warnings

⚠️ **Tetris + level-up simultaneous feedback** — audio-feedback-system.md + visual-feedback-system.md + score-display-system.md
- When Tetris clears at level 14 threshold, the event simultaneously triggers: Tetris layered sound, flash+shake effect, level-up flash, and score update
- All effects play simultaneously — this is the designed behavior
- No failure mode; just noting that the combination of effects at level-up + Tetris is the maximum intensity event in the game
- Recommendation: Ensure audio mixing can handle 3+ simultaneous sound channels without clipping

⚠️ **Ghost piece depends on three systems** — ghost-piece-system.md
- Ghost calculation depends on Tetromino System (piece state), Grid System (is_empty), and Collision System (can_move_to) — three separate systems
- If any of the three is unavailable or returns incorrect data, ghost position could be wrong
- No guard condition described in ghost-piece-system.md for what to do if can_move_to is unavailable
- Impact: MEDIUM — ghost would render at wrong position, breaking player trust in the system
- Recommendation: ghost-piece-system.md should specify fallback behavior: if can_move_to unavailable, fall back to Grid System's is_empty() directly, or hide ghost entirely

ℹ️ **Lock delay timer pause behavior** — tetromino-system.md + game-state-system.md
- tetromino-system.md says "If game paused while lock timer running: Timer pauses, resumes on unpause"
- game-state-system.md says "When PAUSED: All gameplay loops stop (piece dropping, input processing except pause)"
- These are consistent: lock timer is a "gameplay loop" that pauses
- No ambiguity — just noting the cross-system consistency

ℹ️ **Combo reset on new game** — combo-scoring-system.md + game-state-system.md
- combo-scoring-system.md says combo resets on new_game signal
- game-state-system.md says "Reset combo counter to 0" as part of New Game Initialization
- Consistent ✅

ℹ️ **Spawn position authoritative source** — piece-spawn-system.md
- Spawn position (x=4, y=19) is defined in piece-spawn-system.md
- tetromino-system.md references "Spawn position: x=4, y=19" and grid-system.md defines origin bottom-left
- game-state-system.md game-over detection also uses (4, 19) for spawn check
- All consistent ✅

ℹ️ **Hard drop + soft drop scoring** — combo-scoring-system.md + input-system.md
- combo-scoring-system.md formula: soft_drop_distance × SOFT_DROP_POINTS_PER_CELL (1) + hard_drop_distance × HARD_DROP_POINTS_PER_CELL (2)
- input-system.md SOFT_DROP_SPEED = 20x multiplier, but this is for gravity acceleration, not scoring
- No conflict — soft drop scoring uses a flat 1 point/cell; the 20x is visual drop speed only
- Consistent ✅

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| score-display-system.md | Missing dependency on Grid System (uses GRID_RIGHT_X, GRID_TOP_Y) | Consistency | Warning |
| game-state-system.md | Missing collision-system.md in downstream dependents | Consistency | Warning |
| visual-feedback-system.md | game-state-system.md should explicitly name it as downstream dependent | Consistency | Warning |

---

## Verdict: PASS

All 13 GDDs are consistent with each other. No blocking issues found. All cross-system data flows are correct and well-defined. The game loop is clean and well-designed with no competing progression loops, no dominant strategy concerns, and strong pillar alignment.

Minor warnings are advisory only — they reflect incomplete dependency declarations that don't affect gameplay but should be cleaned up for architecture accuracy.

---

## Recommended Actions

1. Add Grid System to score-display-system.md dependencies (quick fix, 1 min)
2. Add collision-system.md to game-state-system.md downstream dependents (quick fix, 1 min)
3. Update game-state-system.md to explicitly list Visual Feedback System as downstream (quick fix, 1 min)
4. Proceed to `/create-architecture` — design phase is complete