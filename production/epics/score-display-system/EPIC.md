# Epic: Score Display System

> **Layer**: Presentation
> **GDD**: design/gdd/score-display-system.md
> **Architecture Module**: Presentation / UI
> **Status**: Ready
> **Stories**: 2 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Score Display System renders the player-facing HUD elements: current score (6-digit zero-padded), current level ("LV N"), and current combo ("xN" when combo > 0, hidden when 0). It is signal-driven — subscribes to `score_changed`, `combo_changed` from ComboScoring and `level_up` from SpeedProgression, and updates `Label` nodes in a `CanvasLayer`.

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-ARCH-009: Score Display | `Label` nodes in `CanvasLayer`, signal-driven updates via `_ready()` connections | LOW |

---

## GDD Requirements

| TR-ID | Requirement | Status |
|-------|-------------|--------|
| TR-score-001 | Score format: 6-digit zero-padded (e.g. 001250), caps at 999999+ overflow | Active |
| TR-score-002 | HUD labels: score (6-digit), level (LV N), combo (xN when combo>0, hidden when 0) | Active |
| TR-score-003 | Next piece preview: piece type 1-7 rendered as mini-grid | Active (Vertical Slice) |

---

## Definition of Done

This epic is complete when:
- `score_display.gd` is implemented as `class_name ScoreDisplay extends Control` in `src/score_display/`
- 3 `Label` children: `score_label`, `level_label`, `combo_label` — updated via signal handlers
- All acceptance criteria from `design/gdd/score-display-system.md` verified by tests
- Tests: `tests/unit/score_display/` (signal handler logic can be unit tested with mocked signals)

---

## Stories

| # | Story | Type | Status | Dependencies |
|---|-------|------|--------|--------------|
| 001 | Score + Level Display — 6-digit zero-padded score, "LV N" level | UI | Ready | combo-scoring-system stories, speed-progression-system stories |
| 002 | Combo Display — "xN" label visible when combo>0, hidden when 0 | UI | Ready | combo-scoring-system stories |

## Dependency Order

`score-display-system` depends on:
- `combo-scoring-system` stories (for `score_changed`, `combo_changed`, `combo_x5` signals)
- `speed-progression-system` stories (for `level_up` signal)

Advance both Feature epics before starting Presentation stories.