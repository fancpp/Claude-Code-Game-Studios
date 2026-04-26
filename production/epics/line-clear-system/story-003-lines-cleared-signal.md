# Story 003: lines_cleared Signal — emit to downstream systems

> **Epic**: line-clear-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/line-clearing-system.md`
**Requirement**: `TR-line-clear-002` (4 clear types: Single/Double/Triple/Tetris), `TR-line-clear-003` (row collapse atomic)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-002 (Signal Bus) — `lines_cleared(count)` is a signal on the signal bus. All downstream systems (combo_scoring, speed_progression, visual_feedback) subscribe to this signal.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `lines_cleared(count: int)` signal declared in `line_clear.gd`
- Forbidden: No signal emission before collapse completes (must be atomic)
- Guardrail: Signal emitted exactly once per piece lock event

---

## Acceptance Criteria

*From GDD line-clearing-system.md Acceptance Criteria:*

- [ ] **AC-7**: GIVEN 3 lines are cleared, **WHEN** the collapse completes, **THEN** `lines_cleared(3)` signal is emitted to downstream systems.

---

## Implementation Notes

*From ADR-ARCH-002 Signal Bus and GDD Signal Emissions:*

```gdscript
# line_clear.gd — signal declaration
class_name LineClear
extends Node

@export var grid: Grid

signal lines_cleared(count: int)

func _ready() -> void:
    tetromino.piece_locked.connect(_on_piece_locked)

func _on_piece_locked() -> void:
    var count := detect_and_clear_lines()
    if count > 0:
        lines_cleared.emit(count)  # emitted exactly once, after collapse
```

**Atomic signal emission rule**: The `lines_cleared` signal must only be emitted AFTER the entire collapse operation is complete. Downstream systems (combo_scoring, speed_progression) receive the signal and perform their own state updates atomically. If the signal is emitted before collapse completes, downstream systems will read a partially-collapsed grid.

**Signal payload**: `count: int` with values 1-4 (or 0 when no lines cleared — signal not emitted for 0).

**Downstream signal connections**:
- `combo_scoring.gd` subscribes to `line_clear.lines_cleared` → triggers score calculation
- `speed_progression.gd` subscribes to `line_clear.lines_cleared` → triggers level-up check
- `visual_feedback.gd` subscribes to `line_clear.lines_cleared` → triggers flash/shake

---

## Out of Scope

- Line detection (Story 001) and row collapse (Story 002) implementation details — those are prerequisites
- Downstream system behavior (handled by their own stories)

---

## QA Test Cases

**AC-7**: 3 lines cleared emits lines_cleared(3) once
- Given: Grid with 3 complete rows ready to collapse
- When: `piece_locked` signal fires (or `_on_piece_locked()` is called directly)
- Then: `lines_cleared` signal is emitted exactly once with count=3
- And: Signal is emitted only after full collapse completes
- Edge cases: 0 lines cleared (no signal emitted), 1 line, 4 lines (Tetris)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/line_clear/lines_cleared_signal_test.gd` — must exist and pass

**Status**: [ ] Not yet created

**Dependencies**: line-clear-system story-001, line-clear-system story-002, grid-system stories (001-003), tetromino-system stories