# Architecture Traceability Matrix

> **Last Updated**: 2026-04-26
> **Source**: Extracted from `docs/architecture/architecture-review-2026-04-26.md`
> **Coverage**: 45 TR-IDs · 42 Covered · 0 Partial · 3 Gaps

## How to Read This Matrix

| Column | Meaning |
|--------|---------|
| **TR-ID** | Stable requirement ID — never renumbered |
| **GDD** | Source design document |
| **ADR** | Architecture decision governing implementation |
| **Status** | ✅ Covered / ⚠️ Partial / ❌ Gap |

## Full Traceability Matrix

### Foundation Layer

| TR-ID | GDD | Requirement | ADR | Status |
|-------|-----|-------------|-----|--------|
| TR-grid-001 | grid-system.md | Grid as single shared RefCounted, not Node or Autoload | ADR-ARCH-001 | ✅ |
| TR-grid-002 | grid-system.md | 10×20 cell grid, column-major access | ADR-ARCH-001 | ✅ |
| TR-grid-003 | grid-system.md | Cell states: Empty/Mino/Hint | ADR-ARCH-001 | ✅ |
| TR-signal-001 | (all) | Signal-based communication, no EventBus | ADR-ARCH-002 | ✅ |
| TR-signal-002 | (all) | lines_cleared fans to 4 consumers | ADR-ARCH-002 | ✅ |
| TR-scene-001 | (all) | Flat Node2D root, all systems as direct children | ADR-ARCH-003 | ✅ |
| TR-scene-002 | (all) | Grid as @onready var on root, injected via @export | ADR-ARCH-003 | ✅ |
| TR-scene-003 | (all) | UI in CanvasLayer above game world | ADR-ARCH-003 | ✅ |
| TR-input-001 | input-system.md | DAS 170ms initial / 50ms repeat | ADR-ARCH-012 | ✅ |
| TR-input-002 | input-system.md | DAS applies to Move Left/Right/Soft Drop | ADR-ARCH-012 | ✅ |
| TR-input-003 | input-system.md | Left+Right simultaneous cancels both | ADR-ARCH-012 | ✅ |
| TR-input-004 | input-system.md | DAS pauses with game via _process() | ADR-ARCH-012 | ✅ |

### Core Layer

| TR-ID | GDD | Requirement | ADR | Status |
|-------|-----|-------------|-----|--------|
| TR-tetromino-001 | tetromino-system.md | 7 tetromino types with SRS rotation states | ADR-ARCH-004 | ✅ |
| TR-tetromino-002 | tetromino-system.md | Wall kick data defined in tetromino-system.md | ADR-ARCH-004 | ✅ |
| TR-tetromino-003 | tetromino-system.md | 4×4 occupancy grid for rotation state storage | ADR-ARCH-004 | ✅ |
| TR-lock-001 | tetromino-system.md | Lock delay: 500ms timer per ADR-ARCH-005 | ADR-ARCH-005 | ✅ |
| TR-lock-002 | tetromino-system.md | Lock delay resets on valid move | ADR-ARCH-005 | ✅ |
| TR-lock-003 | tetromino-system.md | Lock delay pauses when DAS is active | ADR-ARCH-005 | ✅ |
| TR-spawn-001 | piece-spawn-system.md | 7-bag randomizer with seeded RNG | ADR-ARCH-006 | ✅ |
| TR-spawn-002 | piece-spawn-system.md | PREVIEW_COUNT (default 1, range 1–5) | — | ❌ Gap |
| TR-spawn-003 | piece-spawn-system.md | Spawn failure triggers game over | ADR-ARCH-006 | ✅ |
| TR-collision-001 | collision-system.md | can_move_to(tx, ty, shape) → bool | ADR-ARCH-004 | ✅ |
| TR-collision-002 | collision-system.md | Wall kick offsets consistency | — | ❌ Gap |
| TR-ghost-001 | ghost-piece-system.md | Ghost piece marks drop destination | ADR-ARCH-004 | ✅ |
| TR-ghost-002 | ghost-piece-system.md | Ghost uses same collision as active piece | ADR-ARCH-004 | ✅ |

### Feature Layer

| TR-ID | GDD | Requirement | ADR | Status |
|-------|-----|-------------|-----|--------|
| TR-clear-001 | line-clearing-system.md | Single, double, triple, quad line clear | ADR-ARCH-004 | ✅ |
| TR-clear-002 | line-clearing-system.md | Line clear collapses rows top-to-bottom | ADR-ARCH-004 | ✅ |
| TR-clear-003 | line-clearing-system.md | lines_cleared(count) signal fans to 4 consumers | ADR-ARCH-002 | ✅ |
| TR-combo-001 | combo-scoring-system.md | combo_x5 signal when combo reaches 5 | — | ✅ Fixed |
| TR-combo-002 | combo-scoring-system.md | combo_changed(counter, multiplier) | — | ✅ Fixed |
| TR-speed-001 | speed-progression-system.md | Level increases every N lines cleared | — | ✅ |
| TR-speed-002 | speed-progression-system.md | level_up(new_level) signal | — | ✅ Fixed |
| TR-speed-003 | speed-progression-system.md | Gravity increases per level (表格 defined) | — | ✅ |
| TR-score-001 | score-display-system.md | Score: lines × level × multiplier | — | ✅ |
| TR-score-002 | score-display-system.md | Display updates via signal subscription | ADR-ARCH-009 | ✅ |

### Presentation Layer

| TR-ID | GDD | Requirement | ADR | Status |
|-------|-----|-------------|-----|--------|
| TR-vfx-001 | visual-feedback-system.md | ColorRect flash overlay for lock/clear | ADR-ARCH-007 | ✅ |
| TR-vfx-002 | visual-feedback-system.md | White flash for hard drop | ADR-ARCH-007 | ✅ |
| TR-vfx-003 | visual-feedback-system.md | Combo counter glow for ×5+ combo | ADR-ARCH-007 | ✅ |
| TR-vfx-004 | visual-feedback-system.md | Screen shake on game over | ADR-ARCH-007 | ✅ |
| TR-vfx-005 | visual-feedback-system.md | Particles on quad clear | ADR-ARCH-007 | ✅ |
| TR-vfx-006 | visual-feedback-system.md | Glow tone mapping per ADR-ARCH-011 | ADR-ARCH-011 | ✅ |
| TR-audio-001 | audio-feedback-system.md | Move/rotate/soft-drop sounds | ADR-ARCH-008 | ✅ |
| TR-audio-002 | audio-feedback-system.md | Lock/clear/combo audio cues | ADR-ARCH-008 | ✅ |
| TR-audio-003 | audio-feedback-system.md | Level-up fanfare | ADR-ARCH-008 | ✅ |
| TR-audio-004 | audio-feedback-system.md | Game-over sting | ADR-ARCH-008 | ✅ |

### UI / Platform

| TR-ID | GDD | Requirement | ADR | Status |
|-------|-----|-------------|-----|--------|
| TR-ui-001 | score-display-system.md | Score/Level/Combo HUD | ADR-ARCH-009 | ✅ |
| TR-ui-002 | score-display-system.md | Next piece preview | — | ✅ |
| TR-ui-003 | score-display-system.md | CanvasLayer renders above game | ADR-ARCH-003 | ✅ |
| TR-ui-004 | game-state-system.md | Pause overlay on ESC | — | ✅ |
| TR-ui-005 | input-system.md | Godot 4.6 dual-focus for menus | ADR-ARCH-010 | ✅ |
| TR-platform-001 | (all) | Web (HTML5) + PC targets | — | ✅ |
| TR-platform-002 | (all) | Keyboard primary input | — | ✅ |

---

## Coverage Summary

| Status | Count | % |
|--------|-------|---|
| ✅ Covered | 42 | 93% |
| ⚠️ Partial | 0 | 0% |
| ❌ Gap (TR-spawn-002) | 1 | 2% |
| ❌ Gap (TR-collision-002) | 1 | 2% |
| ✅ Fixed (signal conflicts resolved) | 3 | — |
| **Total requirements** | **45** | **100%** |

---

## Uncovered Requirements

### Gap 1 — TR-spawn-002: Preview Queue Size

| Field | Value |
|-------|-------|
| **GDD** | piece-spawn-system.md |
| **System** | Piece Spawn System |
| **Requirement** | `PREVIEW_COUNT` (default 1, range 1–5) — number of next pieces shown |
| **Suggested ADR** | Extend ADR-ARCH-006 (7-Bag Randomizer) |
| **Priority** | MEDIUM |

**Resolution**: Add a constant `PREVIEW_COUNT: int = 1` to piece_spawn.gd or the spawn ADR. This is a tuning knob deferred to Pre-Production.

---

### Gap 2 — TR-collision-002: Wall Kick Data Ownership

| Field | Value |
|-------|-------|
| **GDD** | collision-system.md + tetromino-system.md |
| **System** | Collision / Tetromino |
| **Requirement** | Wall kick offsets `[(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]` |
| **Suggested ADR** | Designate one GDD as authoritative source of truth |
| **Priority** | LOW |

**Resolution**: Collision System GDD should own the wall kick data table; Tetromino System references it. Both GDDs currently define the same offsets.

---

## Signal Fix Checklist — ALL RESOLVED ✅

| Fix | File | Change | Status |
|-----|------|--------|--------|
| `combo_x5` signal | combo-scoring-system.md | Fire when `combo_counter` reaches 5 | ✅ DONE |
| `level_changed` → `level_up` | score-display-system.md + ADR-0009 | Rename signal reference | ✅ DONE |
| Dead `pause` connection | score-display-system.md | Remove dead connection | ✅ DONE |

---

## ADR Dependency Chain (topological order)

```
ARCH-001 (Grid) ← no deps
ARCH-002 (Signal Bus) ← ARCH-001
ARCH-003 (Scene Tree) ← ARCH-001, ARCH-002
ARCH-004 (Tetromino Shape) ← ARCH-001
ARCH-005 (Lock Delay) ← ARCH-001, ARCH-004
ARCH-006 (7-Bag Randomizer) ← ARCH-004
ARCH-007 (Visual Effects) ← ARCH-002
ARCH-008 (Audio) ← ARCH-002
ARCH-009 (Score Display) ← ARCH-002
ARCH-010 (UI Dual-Focus) ← no deps
ARCH-011 (Glow/Tonemapping) ← no deps
ARCH-012 (DAS Timing) ← no deps
```

No circular dependencies detected.