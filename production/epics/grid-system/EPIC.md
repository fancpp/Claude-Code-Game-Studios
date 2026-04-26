# Epic: Grid System

> **Layer**: Foundation
> **GDD**: design/gdd/grid-system.md
> **Architecture Module**: Grid System (L1 Foundation)
> **Status**: Ready
> **Stories**: 3 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Grid System is the foundational data structure of the game: a 10×20 two-dimensional array where each cell stores either empty or a tetromino block type. It provides the authoritative spatial reference for all gameplay — every piece placement, collision check, and line clear operates on grid coordinates. The grid is read-only for most systems; only the Tetromino System and Line Clearing System modify it.

The implementation is a single `class_name Grid extends RefCounted` — pure data, no Godot engine dependencies, trivially mockable for unit tests. One instance lives on `main.tscn` root and is injected into all systems via `@export var grid: Grid`.

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-ARCH-001: Grid Resource Pattern | Grid as `RefCounted`, `@export var grid: Grid` injection, no Autoload | LOW |

---

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-grid-001 | Grid as single shared RefCounted, not Node or Autoload | ADR-ARCH-001 ✅ |
| TR-grid-002 | 10×20 cell grid, column-major access | ADR-ARCH-001 ✅ |
| TR-grid-003 | Cell states: Empty/Mino/Hint | ADR-ARCH-001 ✅ |

---

## Definition of Done

This epic is complete when:
- `Grid` class is implemented in `src/grid/grid.gd` with all required API methods
- `grid.gd` is registered as `class_name Grid extends RefCounted`
- Grid is instantiated once in `main.gd` as `@onready var grid: Grid = Grid.new()` and wired to all children
- All systems that need grid have `@export var grid: Grid` field
- Each system calls `assert(grid != null, "Grid not wired")` in `_ready()`
- Unit tests in `tests/unit/grid_test.gd` cover all 5 API methods
- All acceptance criteria from `design/gdd/grid-system.md` are verified

---

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Core Grid API — get_cell, set_cell, is_empty, clear_grid | Logic | Ready | ADR-ARCH-001 |
| 002 | Boundary Validation — is_valid_position, out-of-bounds | Logic | Ready | ADR-ARCH-001 |
| 003 | Grid Wiring — instantiate on main.gd, wire to all children | Integration | Ready | ADR-ARCH-003 |

## Next Step

Run `/story-readiness production/epics/grid-system/story-001-core-grid-api.md` to begin implementation, or `/create-stories input-system` for the next epic.