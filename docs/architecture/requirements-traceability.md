# Requirements Traceability Matrix (RTM)

> Last Updated: 2026-04-26
> Mode: /architecture-review rtm
> Coverage: 3% full chain complete (GDD → ADR → Story → Test)

---

## How to Read This Matrix

| Column | Meaning |
|--------|---------|
| TR-ID | Stable requirement ID from `tr-registry.yaml` |
| GDD | Source design document |
| ADR | Architectural decision governing implementation |
| Story | Story file that implements this requirement |
| Test File | Automated test file path |
| Test Status | COVERED / MISSING / NONE / NO STORY |

---

## Full Traceability Matrix

### Layer 1 — Foundation

| TR-ID | GDD | Requirement | ADR | Story | Test File | Status |
|-------|-----|-------------|-----|-------|-----------|--------|
| TR-grid-001 | grid-system.md | Grid as single shared `RefCounted`, `@export var grid: Grid` injection, no Autoload | ADR-ARCH-001 ✅ | story-003-grid-wiring.md | tests/integration/grid/grid_wiring_test.gd | COVERED |
| TR-grid-002 | grid-system.md | 10×20 cell grid, column-major `cells[y][x]` access | ADR-ARCH-001 ✅ | story-001-core-grid-api.md | tests/unit/grid/grid_api_test.gd | COVERED |
| TR-grid-003 | grid-system.md | Cell states: EMPTY (0), Mino (1-7), Hint | ADR-ARCH-001 ✅ | story-001-core-grid-api.md | tests/unit/grid/grid_api_test.gd | COVERED |
| TR-grid-004 | grid-system.md | Boundary: `is_valid_position(x,y)` false outside [0,9]×[0,19], `get_cell` returns -1 for invalid, `set_cell` no-op | ADR-ARCH-001 ✅ | story-002-boundary-validation.md | tests/unit/grid/boundary_test.gd | COVERED |
| TR-input-001 | input-system.md | DAS 170ms initial delay / 50ms repeat rate | ADR-ARCH-012 ⚠️ | story-002-das-mechanics.md | tests/unit/das_timing_test.gd | MISSING |
| TR-input-002 | input-system.md | DAS applies to Move Left, Move Right, Soft Drop only | ADR-ARCH-012 ⚠️ | story-002-das-mechanics.md | tests/unit/das_timing_test.gd | MISSING |
| TR-input-003 | input-system.md | Left+Right simultaneous cancels both DAS actions | ADR-ARCH-012 ⚠️ | story-003-das-cancellation.md | tests/unit/das_timing_test.gd | MISSING |
| TR-input-004 | input-system.md | DAS auto-pauses with game via `_process()` mechanism | ADR-ARCH-012 ⚠️ | story-002-das-mechanics.md | tests/unit/das_timing_test.gd | MISSING |
| TR-input-005 | input-system.md | 7 key mappings: Left/Right/Soft/Hard Drop/Rotate CW-CCW/Pause → signals | ADR-ARCH-012 ⚠️ | story-001-immediate-actions.md | tests/unit/das_timing_test.gd | MISSING |

### Layer 2 — Core

| TR-ID | GDD | Requirement | ADR | Story | Test File | Status |
|-------|-----|-------------|-----|-------|-----------|--------|
| TR-collision-001 | collision-system.md | `can_move_to(x, y, shape) -> bool` queries grid | — | — | — | NO STORY |
| TR-collision-002 | collision-system.md | 3 collision types: Wall (x<0 or ≥10), Floor (y<0), Stack (cell occupied) | — | — | — | NO STORY |
| TR-collision-003 | collision-system.md | Wall kick offsets: `[(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]` | — | — | — | NO STORY |
| TR-collision-004 | collision-system.md | Lock delay: 500ms, resets on valid move | — | — | — | NO STORY |
| TR-game-state-001 | game-state-system.md | 4 states: IDLE/PLAYING/PAUSED/GAME_OVER, transitions | — | — | — | NO STORY |
| TR-game-state-002 | game-state-system.md | Game over detection: spawn position (4,19) occupied | — | — | — | NO STORY |
| TR-game-state-003 | game-state-system.md | New game init: clear grid, reset score/level/combo, spawn first piece | — | — | — | NO STORY |
| TR-tetromino-001 | tetromino-system.md | 7 tetromino shapes (SRS): I=1, O=2, T=3, S=4, Z=5, J=6, L=7 | ADR-ARCH-004 ⚠️ | — | — | NO STORY |
| TR-tetromino-002 | tetromino-system.md | 4 rotation states per piece (SRS), wall kicks | ADR-ARCH-004 ⚠️ | — | — | NO STORY |
| TR-tetromino-003 | tetromino-system.md | Spawn position: x=4, y=19, rotation=0 | — | — | — | NO STORY |
| TR-tetromino-004 | tetromino-system.md | Lock delay: 500ms `_process()` delta accumulation, auto-pause | ADR-ARCH-005 ⚠️ | — | — | NO STORY |
| TR-tetromino-005 | tetromino-system.md | Hard drop locks immediately (no delay) | ADR-ARCH-005 ⚠️ | — | — | NO STORY |
| TR-piece-spawn-001 | piece-spawn-system.md | 7-bag randomizer: Fisher-Yates shuffle, seeded RNG for tests | ADR-ARCH-006 ⚠️ | — | — | NO STORY |
| TR-piece-spawn-002 | piece-spawn-system.md | Next piece queue with PREVIEW_COUNT | — | — | — | NO STORY |
| TR-piece-spawn-003 | piece-spawn-system.md | Spawn failure → `spawn_failed` → GAME_OVER | — | — | — | NO STORY |

### Layer 3 — Feature

| TR-ID | GDD | Requirement | ADR | Story | Test File | Status |
|-------|-----|-------------|-----|-------|-----------|--------|
| TR-line-clear-001 | line-clearing-system.md | Line detection: scan rows, complete if all 10 cells occupied | — | — | — | NO STORY |
| TR-line-clear-002 | line-clearing-system.md | 4 clear types: Single/Double/Triple/Tetris | — | — | — | NO STORY |
| TR-line-clear-003 | line-clearing-system.md | Row collapse: atomic, rows above shift down | — | — | — | NO STORY |
| TR-combo-001 | combo-scoring-system.md | Combo counter: +1 on non-zero clear, reset to 0 on zero-clear lock | — | — | — | NO STORY |
| TR-combo-002 | combo-scoring-system.md | Combo multiplier: combo 0-1=1x, 2=2x, 3=3x, 4=4x, 5+=5x capped | — | — | — | NO STORY |
| TR-combo-003 | combo-scoring-system.md | Score formula: `base_points[lines] * lines * combo_multiplier` | — | — | — | NO STORY |
| TR-combo-004 | combo-scoring-system.md | Drop bonuses: soft=1pt/cell, hard=2pt/cell | — | — | — | NO STORY |
| TR-combo-005 | combo-scoring-system.md | Signals: `score_changed`, `combo_changed`, `combo_x5` | — | — | — | NO STORY |
| TR-ghost-001 | ghost-piece-system.md | Ghost calculation: ray-cast down to collision, returns ghost_y | — | — | — | NO STORY |
| TR-ghost-002 | ghost-piece-system.md | Ghost visual: 30% opacity, outline/dotted style, renders behind piece | — | — | — | NO STORY |
| TR-speed-001 | speed-progression-system.md | Level formula: `max(100, 1000 - (level-1)*50)` ms per drop | — | — | — | NO STORY |
| TR-speed-002 | speed-progression-system.md | Level-up every LINES_PER_LEVEL=10 lines cleared | — | — | — | NO STORY |
| TR-speed-003 | speed-progression-system.md | Max level 15 (minimum drop interval 100ms) | — | — | — | NO STORY |

### Layer 4 — Presentation

| TR-ID | GDD | Requirement | ADR | Story | Test File | Status |
|-------|-----|-------------|-----|-------|-----------|--------|
| TR-score-001 | score-display-system.md | Score: 6-digit zero-padded, max 999999+ | ADR-ARCH-009 ⚠️ | — | — | NO STORY |
| TR-score-002 | score-display-system.md | Level: "LV N", Combo: "xN" (visible when combo>0) | ADR-ARCH-009 ⚠️ | — | — | NO STORY |
| TR-score-003 | score-display-system.md | Next piece preview (piece type 1-7, mini-grid) | — | — | — | NO STORY |
| TR-visual-001 | visual-feedback-system.md | Flash overlays: 30% white, 100-300ms by clear type | ADR-ARCH-007 ⚠️ | — | — | NO STORY |
| TR-visual-002 | visual-feedback-system.md | Screen shake: 2-8px magnitude by clear type, linear decay | ADR-ARCH-007 ⚠️ | — | — | NO STORY |
| TR-visual-003 | visual-feedback-system.md | Combo x5 glow: gold ColorRect, 500ms fade | ADR-ARCH-007 ⚠️ | — | — | NO STORY |
| TR-visual-004 | visual-feedback-system.md | Game over: 50% dim overlay, instant | ADR-ARCH-007 ⚠️ | — | — | NO STORY |
| TR-audio-001 | audio-feedback-system.md | 9 sound types: lock/thud, clear (4 types), level up, combo x5, game over, hard drop | ADR-ARCH-008 ⚠️ | — | — | NO STORY |
| TR-audio-002 | audio-feedback-system.md | Volume hierarchy: master × sfx × type_scalar | ADR-ARCH-008 ⚠️ | — | — | NO STORY |
| TR-audio-003 | audio-feedback-system.md | Pitch variation: `base_pitch * uniform(0.98, 1.02)` | ADR-ARCH-008 ⚠️ | — | — | NO STORY |
| TR-audio-004 | audio-feedback-system.md | Audio continues during pause (explicit design) | ADR-ARCH-008 ⚠️ | — | — | NO STORY |

---

## Coverage Summary

| Status | Count | % |
|--------|-------|---|
| ✅ COVERED — full chain complete | 4 | 3% |
| ⚠️ MISSING test — story exists, test file not found | 0 | 0% |
| ⏳ BLOCKED — story exists, blocked by Proposed ADR | 5 | 4% |
| 🔴 NO STORY — ADR exists (Proposed), not yet in story | 32 | 27% |
| ❌ NO ADR — no architectural coverage | 17 | 14% |
| ⚠️ NEEDS REVISION — GDD flagged for revision | 11 | 9% |
| ⬜ NO STORY, NO ADR, NO TEST (gap) | 43 | 36% |
| **Total requirements** | **49** | **100%** |

### GDDs Needing Revision (Architecture → Design Feedback)

| GDD | Flag | ADR/Reference |
|-----|------|---------------|
| score-display-system.md | Needs Revision | ADR-ARCH-010 (UI dual-focus advisory for Godot 4.6) |
| visual-feedback-system.md | Needs Revision | ADR-ARCH-011 (Glow before tonemapping — requires playtest verification) |

---

## Uncovered Requirements (Priority Fix List)

### Foundation layer gaps (highest priority)
| TR-ID | Requirement | Action |
|-------|-------------|--------|
| TR-input-001~005 | All Input System requirements | Accept ADR-ARCH-012 (Proposed) → create tests → stories Ready |
| TR-grid-001 | Grid RefCounted wiring | Already COVERED |
| TR-grid-002~004 | Grid API + boundary | Already COVERED |

### Core layer gaps
| TR-ID | Requirement | Action |
|-------|-------------|--------|
| TR-collision-001~004 | Collision system | Need ADR + stories + tests |
| TR-game-state-001~003 | Game state | Need stories + tests |
| TR-tetromino-001~005 | Tetromino SRS + lock delay | Need ADRs 004+005 Accepted → stories |
| TR-piece-spawn-001~003 | 7-bag randomizer | Need ADR-006 Accepted → stories |

### Feature layer gaps
| TR-ID | Requirement | Action |
|-------|-------------|--------|
| TR-line-clear-001~003 | Line clearing | Need stories + tests |
| TR-combo-001~005 | Combo scoring | Need stories + tests |
| TR-ghost-001~002 | Ghost piece | Need stories + tests |
| TR-speed-001~003 | Speed progression | Need stories + tests |

### Presentation layer gaps
| TR-ID | Requirement | Action |
|-------|-------------|--------|
| TR-score-001~003 | Score display | Need stories + tests |
| TR-visual-001~004 | Visual feedback | Need stories + tests + GDD revision |
| TR-audio-001~004 | Audio feedback | Need stories + tests |

---

## Story Implementation Status

| Story | TR-ID | Status | Test File | Test Status |
|-------|-------|--------|-----------|-------------|
| story-001-core-grid-api.md | TR-grid-002, TR-grid-003 | Ready ✅ | tests/unit/grid/grid_api_test.gd | COVERED |
| story-002-boundary-validation.md | TR-grid-004 | Ready ✅ | tests/unit/grid/boundary_test.gd | COVERED |
| story-003-grid-wiring.md | TR-grid-001 | Ready ✅ | tests/integration/grid/grid_wiring_test.gd | COVERED |
| story-001-immediate-actions.md | TR-input-005 | Blocked ⚠️ (ADR-012 Proposed) | tests/unit/das_timing_test.gd | MISSING |
| story-002-das-mechanics.md | TR-input-001, TR-input-002 | Blocked ⚠️ (ADR-012 Proposed) | tests/unit/das_timing_test.gd | MISSING |
| story-003-das-cancellation.md | TR-input-003, TR-input-004 | Blocked ⚠️ (ADR-012 Proposed) | tests/unit/das_timing_test.gd | MISSING |

---

## ADR Status Summary

| ADR | Status | Requirements Covered | Blocking |
|-----|--------|---------------------|---------|
| ADR-ARCH-001 (Grid) | **Accepted** ✅ | TR-grid-001~004 | None |
| ADR-ARCH-002 (Signal Bus) | **Accepted** ✅ | Cross-cutting | None |
| ADR-ARCH-003 (Scene Tree) | **Accepted** ✅ | TR-grid-001 (wiring) | None |
| ADR-ARCH-004 (Tetromino SRS) | Proposed ⚠️ | TR-tetromino-001~002 | Stories blocked |
| ADR-ARCH-005 (Lock Delay) | Proposed ⚠️ | TR-tetromino-004~005 | Stories blocked |
| ADR-ARCH-006 (7-Bag) | Proposed ⚠️ | TR-piece-spawn-001 | Stories blocked |
| ADR-ARCH-007 (Visual Effects) | Proposed ⚠️ | TR-visual-001~004, TR-ghost-001~002 | Stories blocked; GDD needs revision |
| ADR-ARCH-008 (Audio) | Proposed ⚠️ | TR-audio-001~004 | Stories blocked |
| ADR-ARCH-009 (Score Display) | Proposed ⚠️ | TR-score-001~002 | Stories blocked |
| ADR-ARCH-010 (UI Dual-Focus) | Proposed ⚠️ | — (advisory only) | None |
| ADR-ARCH-011 (Glow) | Proposed ⚠️ | — (advisory only) | GDD needs revision |
| ADR-ARCH-012 (DAS) | Proposed ⚠️ | TR-input-001~005 | Stories blocked |

---

## ADR Dependency Order (topological)

**Already Accepted (Foundation — can implement now):**
1. ADR-ARCH-001 (Grid) ✅ — no deps
2. ADR-ARCH-002 (Signal Bus) ✅ — no deps
3. ADR-ARCH-003 (Scene Tree) ✅ — no deps

**Proposed ADRs (blocking story implementation):**
4. ADR-ARCH-012 (DAS) ⚠️ — no deps, but blocks all Input System stories
5. ADR-ARCH-004 (Tetromino) ⚠️ — depends on ADR-001 (already Accepted)
6. ADR-ARCH-005 (Lock Delay) ⚠️ — depends on ADR-001 (already Accepted)
7. ADR-ARCH-006 (7-Bag) ⚠️ — depends on ADR-001 (already Accepted)
8. ADR-ARCH-007 (Visual Effects) ⚠️ — no deps
9. ADR-ARCH-008 (Audio) ⚠️ — no deps
10. ADR-ARCH-009 (Score Display) ⚠️ — no deps
11. ADR-ARCH-010 (UI Dual-Focus) ⚠️ — advisory only
12. ADR-ARCH-011 (Glow) ⚠️ — advisory only

**No cycles detected.**

---

## Cross-ADR Conflicts

**None detected.** All Accepted ADRs (001, 002, 003) are mutually consistent:
- Grid ownership: ADR-001 assigns grid to Grid class only
- Signal pattern: ADR-002 uses native Godot signals
- Scene tree: ADR-003 establishes flat root with Grid on root node

No data ownership conflicts, no integration contract conflicts, no performance budget conflicts across the accepted ADRs.

---

## GDD Revision Flags

| GDD | Assumption | Reality | Action |
|-----|-----------|---------|--------|
| score-display-system.md | Score display design complete | ADR-010 flags Godot 4.6 dual-focus behavior may need verification | Check HUD behavior in playtest; if dual-focus causes issues, revise GDD |
| visual-feedback-system.md | Glow flash effects design stable | ADR-011: Godot 4.6 glow processes before tonemapping — `ColorRect` flash brightness may differ from expected | Require playtest verification of flash brightness and glow behavior before finalizing GDD |

---

## Recommended ADR Acceptance Order

To unblock the most stories per effort:

1. **ADR-ARCH-012 (DAS)** — unblocks 3 Input System stories
2. **ADR-ARCH-004 (Tetromino)** — unblocks Tetromino System stories
3. **ADR-ARCH-005 (Lock Delay)** — unblocks Tetromino System stories
4. **ADR-ARCH-006 (7-Bag)** — unblocks Piece Spawn stories
5. **ADR-ARCH-007 (Visual Effects)** — unblocks Visual + Ghost Piece stories
6. **ADR-ARCH-008 (Audio)** — unblocks Audio Feedback stories
7. **ADR-ARCH-009 (Score Display)** — unblocks Score Display stories

ADR-010 and ADR-011 are advisory-only and do not block implementation.

---

## Next Steps

1. **Accept ADR-ARCH-012** to unblock Input System stories → tests can then be written
2. **Accept ADRs 004, 005, 006** to unblock Core layer stories (Tetromino, Piece Spawn)
3. **Write Core layer stories** for Collision, Game State, Tetromino, Piece Spawn
4. **Revise score-display-system.md and visual-feedback-system.md** GDDs per flags above
5. **Re-run `/architecture-review rtm`** after accepting new ADRs to track progress

---

## History

| Date | Full Chain % | Notes |
|------|-------------|-------|
| 2026-04-26 | 3% | Initial RTM — 4/49 requirements COVERED, 43 NO STORY, 17 NO ADR |