# Architecture Review Report

**Date:** 2026-04-26
**Engine:** Godot 4.6
**GDDs Reviewed:** 13 (all MVP + Vertical Slice systems)
**ADRs Reviewed:** 11 (ARCH-001 through ARCH-011)
**Reviewer:** Technical Director (self-review via /architecture-review)
**Mode:** full

---

## Traceability Summary

**Total requirements extracted:** 45 TR-IDs across 13 GDDs
✅ Covered: 42
⚠️ Partial: 0
❌ Gaps: 3

All foundational and gameplay requirements have ADRs covering them. The 3 gaps are narrow and well-understood.

---

## Coverage Gaps (no ADR exists)

### Gap 1 — TR-input-001: DAS Timing Parameters

| Field | Value |
|-------|-------|
| **GDD** | input-system.md |
| **System** | Input System |
| **Requirement** | DAS initial delay 170ms, repeat rate 50ms, applies to move left/right/soft drop |
| **Suggested ADR** | `/architecture-decision Input DAS Timing` |
| **Domain** | Input / Timing |
| **Engine Risk** | LOW — pure GDScript timing math, no engine API |

**Why no ADR yet:** DAS parameters are tuning knobs deferred from ARCH-002 (Signal Bus). The Signal Bus ADR covers the signal interface but not the DAS timing constants.

---

### Gap 2 — TR-spawn-002: Preview Queue Size

| Field | Value |
|-------|-------|
| **GDD** | piece-spawn-system.md |
| **System** | Piece Spawn System |
| **Requirement** | `PREVIEW_COUNT` (default 1, range 1-5) — number of next pieces shown |
| **Suggested ADR** | Extend ADR-ARCH-006 (7-Bag Randomizer) or `/architecture-decision Piece Preview Queue` |
| **Domain** | Gameplay / UI |
| **Engine Risk** | LOW |

**Why no ADR yet:** The GDD defines the knob but no ADR covers the queue implementation details. Deferred as Vertical Slice.

---

### Gap 3 — TR-collision-002: Wall Kick Data Ownership

| Field | Value |
|-------|-------|
| **GDD** | collision-system.md + tetromino-system.md |
| **System** | Collision System / Tetromino System |
| **Requirement** | Wall kick offsets `[(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]` defined identically in both GDDs |
| **Suggested ADR** | `/architecture-decision Wall Kick Data Ownership` — designate one GDD as source of truth |
| **Domain** | Core / Data Consistency |
| **Engine Risk** | LOW |

**Why no ADR yet:** This is a GDD consistency issue, not an ADR gap. Both GDDs define the same offsets. One should be the authoritative source.

---

## Cross-ADR Conflicts

### CONFLICT 1: Signal mismatch — `combo_x5` missing from Combo Scoring GDD

**Type:** Integration contract — signal name referenced in one ADR does not exist in the GDD it claims to serve

**Documents involved:** ADR-0008 (Audio Architecture) vs combo-scoring-system.md (GDD)

| Document | Claim |
|----------|-------|
| ADR-0008 Audio | Connects to `combo_scoring.combo_x5` signal |
| Combo Scoring GDD | Defines `combo_changed(counter, multiplier)` — no `combo_x5` signal exists |

**Impact:** Audio Feedback System will fail to connect to `combo_x5` at runtime. The GDD notes that a "special chime" plays at combo ×5, but never defines the signal that triggers it.

**Resolution options:**
1. **Option A (recommended):** Add `combo_x5` signal to Combo Scoring GDD — it fires when `combo_counter` first reaches 5. Keep `combo_changed` as the general signal for score/level display updates.
2. **Option B:** Remove `combo_x5` from Audio ADR-0008; Audio connects to `combo_changed` and checks counter value in the callback to detect ×5.

---

### CONFLICT 2: Signal mismatch — `level_changed` vs `level_up`

**Type:** Integration contract — Score Display expects a signal name different from what Speed Progression GDD defines

**Documents involved:** ADR-0009 (Score Display) vs speed-progression-system.md (GDD)

| Document | Signal |
|----------|--------|
| ADR-0009 Score Display | Connects to `speed_progression.level_changed(level: int)` |
| Speed Progression GDD | Emits `level_up(new_level: int)` — different name |

**Impact:** Score Display never receives level update events. HUD level display stays at "LV 1".

**Resolution:** Align on `level_up(new_level: int)` as the canonical signal name (matches GDD). Update ADR-0009 to connect to `level_up` instead of `level_changed`.

---

### CONFLICT 3: Dead signal connection — `game_state.pause`

**Type:** Integration contract — Score Display connects to a signal Game State never emits

**Documents involved:** ADR-0009 (Score Display) vs game-state-system.md (GDD)

| Document | Claim |
|----------|-------|
| ADR-0009 Score Display | Connects to `game_state.pause` signal |
| Game State GDD | Pause is handled internally — no `pause` signal emitted |

**Impact:** Dead `connect()` call. No runtime error, but the connection silently does nothing. The Game State GDD does not emit a pause signal — pause state is internal to Game State.

**Resolution:** Remove the `game_state.pause` connection from Score Display ADR-0009. Pause behavior does not require a signal to Score Display — HUD values freeze because the signal-driven display only updates on state-change signals (which stop firing when game is paused).

---

### No other conflicts found

- **Data ownership:** No two ADRs claim exclusive ownership of the same data differently. Grid, Line Clear, and Combo Scoring each have consistent ownership across all ADRs.
- **Performance budgets:** No ADR allocates frame time or makes conflicting resource claims.
- **Dependency cycles:** None found.
- **Architecture pattern conflicts:** All ADRs consistently use signal-driven communication per ARCH-002.

---

## ADR Dependency Order

```
Foundation (no dependencies):
  1. ADR-0001: Grid System Resource Pattern        [Accepted]
  2. ADR-0002: Signal Bus Architecture             [Proposed]
  3. ADR-0003: Scene Tree Structure                [Proposed]

Core (depends on foundation):
  4. ADR-0004: Tetromino Shape Storage             [Proposed]
  5. ADR-0005: Lock Delay Timer                    [Proposed]
  6. ADR-0006: 7-Bag Randomizer                    [Proposed]

Feature / Presentation (depends on core):
  7. ADR-0007: Visual Effects Architecture         [Proposed]
  8. ADR-0008: Audio Architecture                  [Proposed]
  9. ADR-0009: Score Display                       [Proposed]

Advisory (no blocking dependencies):
  10. ADR-0010: UI Dual-Focus (Godot 4.6)          [Proposed]
  11. ADR-0011: Glow + Tonemapping (Godot 4.6)     [Proposed]
```

**⚠️ Unresolved dependency note:** ADR-0002 (Signal Bus) and ADR-0003 (Scene Tree) are both **Proposed**. All subsequent ADRs (0004–0011) depend on them. Signal Bus and Scene Tree should be **Accepted** before gameplay implementation begins. This is a soft blocker — implementation can proceed cautiously using the Proposed decisions, but formal acceptance is needed before a release.

---

## GDD Revision Flags

These GDD assumptions conflict with accepted ADRs or verified engine behavior. The GDD should be revised before its system enters implementation.

| GDD | Assumption | Reality | Action |
|-----|-----------|---------|--------|
| combo-scoring-system.md | No `combo_x5` signal defined | Audio ADR-008 references `combo_x5` which doesn't exist in GDD | Add `combo_x5` signal to Combo Scoring GDD (fires when combo reaches 5) |
| score-display-system.md | Connects to `level_changed` | Speed Progression GDD defines `level_up` | Rename signal reference to `level_up` |
| score-display-system.md | Connects to `game_state.pause` | Game State GDD never emits `pause` signal | Remove dead `pause` signal connection |
| collision-system.md + tetromino-system.md | Wall kick offsets defined separately in both GDDs | Risk of future divergence | Designate one GDD as authoritative source of truth for wall kick offsets |

**Should I flag these GDDs for revision in systems-index.md?** Ask confirmed before writing.

---

## Engine Compatibility Issues

**Engine:** Godot 4.6 (pinned 2026-02-12)
**LLM Training Cutoff:** ~4.3 — HIGH risk for post-cutoff APIs

### Phase 5 Audit Results

**ADRs with Engine Compatibility section:** 11 / 11 ✅

**Deprecated API References:** None found. No ADR uses deprecated APIs from `deprecated-apis.md`.

**Post-Cutoff API Verification:**

| ADR | API Used | Reference | Result |
|-----|----------|-----------|--------|
| ARCH-002 | No engine APIs | — | ✅ OK |
| ARCH-003 | No engine APIs | — | ✅ OK |
| ARCH-004 | No engine APIs | — | ✅ OK |
| ARCH-005 | `_process()` delta | Stable since 2.x | ✅ OK |
| ARCH-006 | `RandomNumberGenerator` | Stable | ✅ OK |
| ARCH-007 | `ColorRect`, `Node2D`, `_process()` | Stable | ✅ OK |
| ARCH-008 | `AudioStreamPlayer` | Stable | ✅ OK |
| ARCH-009 | `Label`, `CanvasLayer` | Stable | ✅ OK |
| ARCH-010 | `focus_mode`, `grab_focus()`, `mouse_filter` | Post-cutoff 4.6 — dual-focus system | ⚠️ VERIFY with tests |
| ARCH-011 | Glow rendering behavior | Post-cutoff 4.6 — glow-before-tonemapping | ⚠️ VERIFY with playtest |

### HIGH-Risk Engine Findings

**Finding 1 — ARCH-010: UI Dual-Focus (Godot 4.6)**

`grab_focus()` behavior in 4.6 differs from pre-4.6 — mouse/touch focus and keyboard/gamepad focus are now separate. Interactive UI (pause menu, game over screen) must be tested with both input methods. MVP HUD (`Label` nodes) is unaffected — Labels don't take focus.

**Finding 2 — ARCH-011: Glow + Tonemapping (Godot 4.6)**

Glow is now applied **before** tonemapping (was after). The white `ColorRect` flash overlay at 30% opacity may appear brighter/differently in 4.6. `FLASH_INITIAL_OPACITY = 0.3` must be verified in playtesting before visual effects sign-off.

### No GDD Revision Flags from Engine Audit

No GDD assumptions contradict verified 4.6 engine behavior for the systems that are designed.

---

## Architecture Document Coverage

- ✅ All 13 systems from `systems-index.md` appear in `architecture.md`
- ✅ All 5 layers (Foundation → Core → Feature → Presentation) are defined
- ✅ Signal communication map covers all cross-system communication from GDDs
- ✅ No orphaned architecture (no system in architecture.md without a corresponding GDD)
- ✅ `architecture.md` correctly references all 11 ADRs

---

## Verdict: PASS ✅

All requirements are covered or near-covered. No blocking cross-ADR conflicts remain. The 3 gaps (DAS timing, preview count, wall kick data ownership) are well-understood and non-blocking.

**2026-04-26 re-run:** All 3 signal conflicts from the initial review have been resolved:
- CONFLICT 1: `combo_x5` signal added to Combo Scoring GDD (fires when combo reaches 5)
- CONFLICT 2: `level_changed` renamed to `level_up` throughout Score Display GDD and ADR-0009
- CONFLICT 3: dead `game_state.pause` connection removed from Score Display design

---

## Remaining Issues (non-blocking)

The following are minor gaps, not blocking issues:

| ID | Gap | Priority | Notes |
|----|-----|----------|-------|
| TR-input-001 | DAS Timing ADR | HIGH | Deferred from ARCH-002; unblocks Input System |
| TR-spawn-002 | Preview Queue size | MEDIUM | GDD defines the knob; no blocking gap |
| TR-collision-002 | Wall Kick Data Ownership | LOW | Designate collision-system.md as authoritative |

---

## Required ADRs (prioritized)

| Priority | ADR | Gap Addressed | Notes |
|----------|-----|--------------|-------|
| HIGH | `/architecture-decision Input DAS Timing` | TR-input-001 — DAS 170ms/50ms parameters | Deferred from ARCH-002; unblocks Input System implementation |
| MEDIUM | Extend ARCH-006 for Preview Queue | TR-spawn-002 — PREVIEW_COUNT | GDD already defines the knob |
| LOW | Wall Kick Data Ownership | TR-collision-002 — GDD consistency | Designate collision-system.md as source of truth |

---

## Signal Fix Checklist — ALL RESOLVED ✅

| Fix | File | Change | Status |
|-----|------|--------|--------|
| Add `combo_x5` signal | combo-scoring-system.md (GDD) + ADR-0008 | Fire when `combo_counter` reaches 5 | ✅ DONE |
| Rename `level_changed` → `level_up` | score-display-system.md (GDD) + ADR-0009 | Score Display listens for `level_up` | ✅ DONE |
| Remove `pause` dead connection | score-display-system.md (GDD) + ADR-0009 | Game State doesn't emit `pause` signal | ✅ DONE |

---

## Immediate Actions

1. **Accept ARCH-002 and ARCH-003** — Signal Bus and Scene Tree are foundations that should be Accepted before heavy implementation begins
2. **Write DAS Timing ADR** — fills the remaining HIGH-priority gap and unblocks Input System
3. **Run `/gate-check pre-production`** — architecture is PASS; advance to next gate
4. **Re-run `/architecture-review`** after each new ADR to verify coverage

**Gate guidance:** Architecture review is PASS. Run `/gate-check pre-production` to advance to pre-production.

**Rerun trigger:** Re-run `/architecture-review` after DAS Timing ADR (or any new ADR) to verify coverage improves.