# Story 003: Grid Wiring — instantiate on main.gd, wire to all children

> **Epic**: grid-system
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/grid-system.md`
**Requirement**: `TR-grid-001` (Grid as single shared RefCounted, injected via `@export var grid: Grid`)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-001 (Grid Resource Pattern) + ADR-ARCH-003 (Scene Tree)
**ADR Decision Summary**: One `Grid` instance via `Grid.new()` on `main.tscn` root as `@onready var grid`. All children receive via `@export var grid: Grid`. Explicit wiring in `main.gd`'s `_ready()`. No Autoloads.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: No post-cutoff APIs. `@onready` and `@export` patterns are stable Godot patterns.

**Control Manifest Rules (Foundation layer)**:
- Required: `Grid.new()` on main.tscn root, `@onready var grid: Grid`, `@export var grid: Grid` on all children, `assert(grid != null)` in each system's `_ready()`
- Forbidden: No Autoload for grid, no `get_node("...")` for grid access, no intermediate group nodes in scene tree
- Guardrail: Grid memory <1KB, 13 nodes as direct children of root (flat hierarchy)

---

## Acceptance Criteria

*From ADR-ARCH-001 and ADR-ARCH-003:*

- [ ] **AC-1**: `main.gd` has `@onready var grid: Grid = Grid.new()` — one Grid instance created at scene load time
- [ ] **AC-2**: In `main.gd`'s `_ready()`, grid is wired to all children: `collision.grid = grid`, `tetromino.grid = grid`, `piece_spawn.grid = grid`, `line_clear.grid = grid`, `ghost_piece.grid = grid`, `combo_scoring.grid = grid`, `speed_progression.grid = grid`
- [ ] **AC-3**: All 7 systems that need grid declare `@export var grid: Grid`
- [ ] **AC-4**: Each of those 7 systems calls `assert(grid != null, "Grid not wired")` in its `_ready()`
- [ ] **AC-5**: No Autoload for grid in `project.godot` — grid is NOT registered as an Autoload singleton
- [ ] **AC-6**: In GUT tests, `Grid.new()` can be instantiated directly and injected into a mock Main scene without Autoload involvement

---

## Implementation Notes

*From ADR-ARCH-003 Decision section:*

```gdscript
# main.gd (script on main.tscn root)
class_name Main
extends Node2D

@onready var grid: Grid = Grid.new()

func _ready() -> void:
    # Wire grid to all children that need it
    collision.grid = grid
    tetromino.grid = grid
    piece_spawn.grid = grid
    line_clear.grid = grid
    ghost_piece.grid = grid
    combo_scoring.grid = grid
    speed_progression.grid = grid
    # game_state and input_handler don't need grid directly
```

**Scene tree structure** (from ADR-ARCH-003):
```
main.tscn (Node2D)
  ├── Grid (RefCounted — class_name Grid, single shared instance)
  ├── input_handler.gd
  ├── game_state.gd
  ├── collision.gd      ← needs grid
  ├── tetromino.gd      ← needs grid
  ├── piece_spawn.gd    ← needs grid
  ├── line_clear.gd     ← needs grid
  ├── combo_scoring.gd  ← needs grid
  ├── ghost_piece.gd    ← needs grid
  ├── speed_progression.gd ← needs grid
  ├── visual_feedback.gd
  ├── audio_feedback.gd
  └── ui_layer (CanvasLayer)
        └── score_display.gd
```

**All 7 systems** that need grid: collision, tetromino, piece_spawn, line_clear, combo_scoring, ghost_piece, speed_progression.

---

## Out of Scope

*Handled by neighbouring stories:*
- Story 001: Grid core API implementation (get_cell, set_cell, etc.)
- Story 002: is_valid_position boundary checks

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: main.gd instantiates Grid once
- Given: A Main scene loaded in Godot editor
- When: The scene enters tree ( `_ready()` fires)
- Then: `main.grid` is not null and `main.grid is Grid` evaluates true
- Edge cases: Grid instance is the same reference for all children (not a new Grid per child)

**AC-2**: grid wired to all 7 children in main.gd _ready()
- Given: Main scene with all children present and `@export var grid: Grid` fields declared
- When: `main._ready()` completes
- Then: Each child's `grid` property references the same `main.grid` instance
- Specifically: collision.grid == tetromino.grid == piece_spawn.grid == line_clear.grid == ghost_piece.grid == combo_scoring.grid == speed_progression.grid == main.grid
- Edge cases: Children that don't need grid (input_handler, game_state, visual_feedback, audio_feedback, score_display) are not assigned

**AC-3**: All 7 systems declare @export var grid: Grid
- Given: All 7 system scripts (collision, tetromino, piece_spawn, line_clear, combo_scoring, ghost_piece, speed_progression)
- When: Each script is opened in Godot editor
- Then: Each declares `@export var grid: Grid` at class level
- Edge cases: None — all 7 must have the field

**AC-4**: assert(grid != null) in each system's _ready()
- Given: All 7 system scripts with `@export var grid: Grid`
- When: Each system's `_ready()` method runs with grid unassigned (null)
- Then: Godot prints a runtime assertion failure with message "Grid not wired"
- And when: grid IS assigned, no assertion fires
- Edge cases: Test with grid deliberately left null to confirm assertion fires

**AC-5**: No Autoload for grid
- Given: project.godot opened in text editor
- When: The [autoload] section is examined
- Then: No entry maps to Grid or grid.gd
- Edge cases: Godot-required Autoloads are fine (e.g., Performance), but Grid must not be among them

**AC-6**: GUT test can create Grid.new() and inject it
- Given: A GUT test file that instantiates `Grid.new()`
- When: `var g = Grid.new()` is called and methods are invoked
- Then: All Grid API methods return correct values without any Autoload or scene tree involvement
- Edge cases: Test that a mock Grid can replace a real Grid in a test harness

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/grid/grid_wiring_test.gd` — must exist and pass (OR documented playtest confirmation that grid wiring works at runtime)

**Status**: [ ] Not yet created