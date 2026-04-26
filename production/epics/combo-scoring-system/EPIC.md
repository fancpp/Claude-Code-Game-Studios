# Epic: Combo Scoring System

> **Layer**: Feature
> **GDD**: design/gdd/combo-scoring-system.md
> **Architecture Module**: Feature / Combo Scoring
> **Status**: Ready
> **Stories**: 3 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Combo Scoring System tracks consecutive line clears across a game, applies a combo multiplier that rewards sustained play, and calculates the total score earned per line clear event. The combo counter increments with each line clear and resets when a piece lands without clearing any lines. Score = base_points x lines_cleared x combo_multiplier. The system is the primary driver of Pillar 3 (Combo Reward) — it makes consecutive clears feel progressively more valuable.

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| (no dedicated ADR — combo logic is pure calculation per GDD formulas) | Combo counter, multiplier, and scoring per GDD formulas | LOW |

---

## GDD Requirements

| TR-ID | Requirement | Status |
|-------|-------------|--------|
| TR-combo-001 | Combo counter: +1 on non-zero line clear, resets to 0 when piece locks with 0 lines | Active |
| TR-combo-002 | Combo multiplier: combo 0-1=1x, 2=2x, 3=3x, 4=4x, 5+=5x (capped) | Active |
| TR-combo-003 | Score formula: base_points[lines] * lines * combo_multiplier, added to total | Active |
| TR-combo-004 | Drop bonuses: soft drop = 1pt per cell, hard drop = 2pt per cell | Active |
| TR-combo-005 | Signals emitted: score_changed, combo_changed, combo_x5 | Active |

---

## Definition of Done

This epic is complete when:
- `combo_scoring.gd` implements all combo counter and scoring logic in `src/combo_scoring/`
- Signals `score_changed(new_score)`, `combo_changed(counter, multiplier)`, `combo_x5` are emitted correctly
- Unit tests in `tests/unit/combo_scoring/` cover all formulas and edge cases
- All acceptance criteria from `design/gdd/combo-scoring-system.md` are verified

---

## Stories

| # | Story | Type | Status | Dependencies |
|---|-------|------|--------|--------------|
| 001 | Combo Counter — increment/reset logic | Logic | Ready | line-clear-system stories |
| 002 | Score Calculation — base points, multiplier, drop bonuses | Logic | Ready | line-clear-system stories, story 001 |
| 003 | Combo Signals — score_changed, combo_changed, combo_x5 emission | Integration | Ready | line-clear-system stories, story 001, story 002 |

## Dependency Order

`combo-scoring-system` depends on:
- `line-clear-system` stories (all 3 must be done first) — `lines_cleared(count)` is the trigger

Advance `line-clear-system` to Ready before starting these stories.