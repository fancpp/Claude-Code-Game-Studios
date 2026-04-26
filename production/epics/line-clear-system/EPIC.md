# Epic: Line Clear System

> **Layer**: Feature
> **GDD**: design/gdd/line-clearing-system.md
> **Architecture Module**: Feature / Line Clearing
> **Status**: Ready
> **Stories**: 3 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Line Clear System detects completed horizontal rows on the grid after each piece locks, removes those rows, and collapses the remaining rows downward to fill the gaps. It classifies 1-4 simultaneous line clears (Single, Double, Triple, Tetris), emits `lines_cleared(count)` to downstream systems, and handles the row collapse atomically with no visible intermediate state.

Row collapse is atomic: all cleared rows disappear simultaneously, then all remaining rows shift down together. This is a pure logic epic — the visual representation of the collapse is handled by Visual Feedback System.

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| (no dedicated ADR — uses grid API from ADR-ARCH-001 and tetromino piece_locked signal) | Line detection via grid cell scan, atomic row collapse | LOW |

---

## GDD Requirements

| TR-ID | Requirement | Status |
|-------|-------------|--------|
| TR-line-clear-001 | Line detection: scan rows bottom-to-top (y=0 to 19), row complete if all 10 cells occupied | Active |
| TR-line-clear-002 | 4 clear types: Single (1), Double (2), Triple (3), Tetris (4) | Active |
| TR-line-clear-003 | Row collapse: atomic, rows above cleared rows shift down by cleared count | Active |

---

## Definition of Done

This epic is complete when:
- `line_clear.gd` implements `detect_and_clear_lines()` returning cleared row count
- Row collapse is atomic (no intermediate states visible)
- `lines_cleared(count)` signal emits to downstream (combo_scoring, speed_progression, visual_feedback)
- All acceptance criteria from `design/gdd/line-clearing-system.md` are verified by unit tests
- Tests: `tests/unit/line_clear/line_detection_test.gd`, `tests/unit/line_clear/row_collapse_test.gd`

---

## Stories

| # | Story | Type | Status | ADR | Dependencies |
|---|-------|------|--------|-----|--------------|
| 001 | Line Detection — scan grid for complete rows | Logic | Ready | Grid ADR | grid-system stories (001-003) |
| 002 | Row Collapse — atomic removal and downward shift | Logic | Ready | Grid ADR | grid-system stories, story 001 |
| 003 | lines_cleared Signal — emit to downstream systems | Integration | Ready | Signal Bus ADR | grid-system stories, tetromino-system stories |

## Dependency Order

`line-clear-system` depends on:
- `grid-system` stories (all 3 must be done)
- `tetromino-system` stories (piece_locked signal source)

Advance `grid-system` to Ready before starting these stories.