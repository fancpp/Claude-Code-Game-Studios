# Epic: Speed Progression System

> **Layer**: Feature
> **GDD**: design/gdd/speed-progression-system.md
> **Architecture Module**: Feature / Speed Progression
> **Status**: Ready
> **Stories**: 2 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Speed Progression System controls the falling speed of tetrominoes based on the current level. Each level increases the drop speed by a fixed increment (linear curve), creating a predictable difficulty arc. Level is driven by lines cleared (not time), and the system provides `drop_interval_ms` to the Tetromino System and emits `level_up` signals for display.

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| (no dedicated ADR — level/speed calculation is pure formula per GDD) | Level = f(lines_cleared), drop_interval = max(100, 1000 - (level-1)*50) | LOW |

---

## GDD Requirements

| TR-ID | Requirement | Status |
|-------|-------------|--------|
| TR-speed-001 | Drop interval formula: max(100ms, 1000ms - (level-1)*50ms) | Active |
| TR-speed-002 | Level-up: every LINES_PER_LEVEL=10 lines cleared, counter resets after level-up | Active |
| TR-speed-003 | Max level 15 (minimum drop interval capped at 100ms) | Active |

---

## Definition of Done

This epic is complete when:
- `speed_progression.gd` implements level tracking and drop interval calculation in `src/speed_progression/`
- `level_up(new_level: int)` signal emits when level crosses threshold
- `drop_interval_ms` is available to tetromino system
- Unit tests in `tests/unit/speed_progression/` cover all level transitions
- All acceptance criteria from `design/gdd/speed-progression-system.md` are verified

---

## Stories

| # | Story | Type | Status | Dependencies |
|---|-------|------|--------|--------------|
| 001 | Drop Interval Formula — speed = f(level) | Logic | Ready | line-clear-system stories |
| 002 | Level Progression — level-up trigger, counter reset | Integration | Ready | line-clear-system stories, story 001 |

## Dependency Order

`speed-progression-system` depends on:
- `line-clear-system` stories (all 3 must be done first) — `lines_cleared(count)` is the trigger

Advance `line-clear-system` to Ready before starting these stories.