# ADR-ARCH-003: Scene Tree Architecture

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture), Lead Programmer

## Summary

The main scene (`main.tscn`) uses a flat `Node2D` root with all 13 gameplay systems as direct children. One `Grid` RefCounted instance lives as a property on the root and is injected into children via `@export var grid: Grid`. No Autoload singletons. UI lives in its own `CanvasLayer` as a child of root.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scene Structure |
| **Knowledge Risk** | LOW — Godot scene tree and node hierarchy are stable from 2.x through 4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-001 (Grid Resource Pattern), ADR-ARCH-002 (Signal Bus) |
| **Enables** | ADR-ARCH-004 through ARCH-011 (all gameplay system ADRs), all implementation |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before implementation of any system begins |

## Context

### Problem Statement

The game has 13 systems across 5 layers that must coexist in the scene tree. The question is: what is the node hierarchy, where does the `Grid` instance live, where does UI live, and how is everything wired together?

### Current State

Architecture.md (Phase 2) establishes a 5-layer dependency model:
- Platform (L0): Godot engine
- Foundation (L1): Grid System, Input System
- Core (L2): Collision, Game State, Tetromino, Piece Spawn
- Feature (L3): Line Clear, Combo Scoring, Ghost Piece, Speed Progression
- Presentation (L4): Score Display, Visual Feedback, Audio Feedback

Architecture.md (Phase 3) establishes the signal routing: 15 signals fan out across producers and consumers, all via native Godot signal `connect()`.

The remaining structural question is how these map to `main.tscn`.

### Constraints

- All systems must be reachable from `main.tscn` for wiring (no hidden autoloads)
- The `Grid` must be a single shared instance — multiple Grid copies = divergent state
- All UI must share the same game state context
- Systems must be independently testable (mockable grid, mockable producers)
- No Autoload singletons (forbidden by ADR-ARCH-001 and ARCH-002)
- Must account for Godot 4.6 dual-focus UI (keyboard/gamepad focus separate from mouse focus)

### Requirements

- All 13 systems must exist as nodes in `main.tscn` or its direct children
- One `Grid` instance shared across all systems that need it
- UI in a `CanvasLayer` so it renders above gameplay
- Wiring must use `@export var` dependency injection (no path-based `get_node()` coupling)
- Init order must respect layer dependencies: Foundation before Core, Core before Feature, Feature before Presentation

## Decision

**`main.tscn` root: `Node2D` (or `Node` in a 2D-specific scene).**

```
main.tscn (Node2D)
  ├── Grid (RefCounted instance — class_name Grid, created via Grid.new())
  ├── input_handler.gd (Node)
  ├── game_state.gd (Node)
  ├── collision.gd (Node)
  ├── tetromino.gd (Node)
  ├── piece_spawn.gd (Node)
  ├── line_clear.gd (Node)
  ├── combo_scoring.gd (Node)
  ├── ghost_piece.gd (Node)
  ├── speed_progression.gd (Node)
  ├── visual_feedback.gd (Node)
  ├── audio_feedback.gd (Node)
  └── ui_layer (CanvasLayer)
        └── score_display.gd (Control node)
```

**Root creates one `Grid` instance:** `onready var grid: Grid = Grid.new()`

**Wiring pattern:** All children that need the grid receive it via `@export var grid: Grid` — set in the inspector by dragging the root node's `grid` property, or set programmatically in `_ready()`:

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

**Why not Autoload for wiring?** Because ADR-ARCH-001 forbids grid-as-autoload. The root node's `@onready var grid` is the explicit, testable equivalent.

**Why a flat hierarchy?** A flat list of children (no intermediate `Core/`, `Feature/`, `Presentation/` group nodes) avoids unnecessary path depth. All systems are at the same level under root, so `@export var` references use `$SystemName` or the inspector without path fragility. Grouping by layer can be added later if the scene becomes complex.

**UI in CanvasLayer:** `ui_layer` is a `CanvasLayer` child of root. CanvasLayer renders independently of the game world and is the standard Godot pattern for HUD/UI. The `score_display.gd` system lives here.

## Architecture Diagram

```
main.tscn (Node2D — class_name Main)
  │
  ├── Grid (RefCounted — class_name Grid, single shared instance)
  │     [injected into: collision, tetromino, piece_spawn, line_clear,
  │      ghost_piece, combo_scoring, speed_progression]
  │
  ├── input_handler.gd (foundation)
  │     emits: move_left, move_right, soft_drop, hard_drop, rotate_cw,
  │            rotate_ccw, pause
  │
  ├── game_state.gd (core — state machine)
  │     emits: new_game, game_over, pause_toggled
  │
  ├── collision.gd (core — receives Grid)
  │     exposes: can_move_to(tx, ty, shape)
  │
  ├── tetromino.gd (core — receives collision, grid)
  │     emits: piece_locked
  │
  ├── piece_spawn.gd (core — receives collision, tetromino)
  │     emits: piece_spawned, spawn_failed
  │
  ├── line_clear.gd (feature — receives grid, tetromino piece_locked)
  │     emits: lines_cleared(count) → fans to 4 consumers
  │
  ├── combo_scoring.gd (feature — receives lines_cleared signal)
  │     emits: nothing (writes score state read by score_display)
  │
  ├── ghost_piece.gd (feature — receives tetromino state, collision, grid)
  │     emits: nothing (writes ghost_position read by visual_feedback)
  │
  ├── speed_progression.gd (feature — receives lines_cleared signal)
  │     emits: level_up(new_level)
  │
  ├── visual_feedback.gd (presentation)
  │     consumes: lines_cleared, level_up, game_over signals
  │
  ├── audio_feedback.gd (presentation)
  │     consumes: all gameplay signals
  │
  └── ui_layer (CanvasLayer)
        └── score_display.gd (Control node — reads combo_scoring, speed_progression)
```

## Init Order

The init order is determined by the order nodes appear in the scene tree (top to bottom) and Godot's `_ready()` call order (same order):

1. **`Grid.new()`** — created on root (no engine dependencies)
2. **input_handler** — captures input, emits to anyone listening
3. **game_state** — boots to IDLE state
4. **collision** — pure query, no dependencies
5. **tetromino** — depends on collision, input_handler
6. **piece_spawn** — depends on collision, tetromino
7. **line_clear** — depends on grid, tetromino
8. **combo_scoring** — depends on line_clear signal
9. **ghost_piece** — depends on tetromino, collision, grid
10. **speed_progression** — depends on line_clear signal, game_state
11. **visual_feedback** — consumers of signals, no dependencies
12. **audio_feedback** — consumers of signals, no dependencies
13. **ui_layer / score_display** — reads state from combo_scoring and speed_progression

**Note:** Signal connections are established in `_ready()` — consumers connect to producers' signals. The producer does not need to know consumers exist. This means the init order above is valid: all producers are ready before consumers try to connect.

## Alternatives Considered

### Alternative 1: Grouped sub-nodes by layer

- **Description**: Wrap systems into `Core/`, `Feature/`, `Presentation/` folder nodes under root
- **Pros**: Logical grouping, easier to collapse in scene tree
- **Cons**: Adds path depth — `$Core/Tetromino` instead of `$Tetromino`; makes `@export` wiring slightly more verbose; no runtime benefit for a 13-node scene
- **Rejection Reason**: Over-engineering for a 13-node scene. A flat list is easier to navigate and the layer contract is already documented in architecture.md, not enforced by the scene tree.

### Alternative 2: Grid as a child Node of main

- **Description**: `Grid` as a `Node` child of main, not a RefCounted on the root
- **Pros**: Normal Godot pattern for node lifecycle
- **Cons**: Same problem as ADR-ARCH-001 alternative 2 — path coupling. If `Grid` node is ever moved in the scene tree, all `$Grid` path references break. RefCounted on root has no path.
- **Rejection Reason**: RefCounted on root avoids path coupling entirely. The grid has no need for node lifecycle (`_ready()`, `_process()`) — it's pure data.

### Alternative 3: Each system self-registers its grid reference

- **Description**: Systems call `Main.get_grid()` on their own `_ready()` to fetch the shared grid
- **Pros**: No explicit wiring in main's `_ready()`
- **Cons**: Creates a hidden dependency on the `Main` node's path or type name. Testing requires mocking `Main`. The explicit `@export var grid: Grid` wiring is already the established pattern (ADR-ARCH-001) — `Main.get_grid()` is just a less explicit version of the same coupling.
- **Rejection Reason**: Hidden `Main` reference is coupling by another name. Explicit `@export var grid` makes dependencies visible in the inspector.

## Consequences

### Positive

- All 13 systems are direct children of root — `$SystemName` is the path everywhere
- Single shared `Grid` instance with no path coupling
- No Autoloads anywhere — all dependencies are explicit
- UI in its own `CanvasLayer` renders above the game world without z-index tricks
- Init order is predictable and documentable (same as scene tree order)
- Testable: in GUT tests, a test script can create a `Main` scene, set `mock_grid` on children, and run

### Negative

- Root's `_ready()` has explicit wiring for grid injection (roughly 10 lines). This is one-time boilerplate — once written, all systems use `@export var grid: Grid` and it just works.
- If a new system is added, someone must remember to wire it in `Main._ready()`. An assert in each system's `_ready()` (`assert(grid != null)`) catches forgotten wiring early.

### Neutral

- Flat hierarchy means the scene tree shows all 13 systems at the same level. This is fine at 13 nodes — at 100+ nodes a grouped structure would be better, but that day is not coming for this project.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Forgotten grid wiring in `Main._ready()` | Medium | Runtime null-ref crash | Assert `assert(grid != null)` in each system's `_ready()` |
| Systems not yet ready when signal connect() is called | Low | Signal silently not received | Producers are higher in the scene tree than consumers; `_ready()` fires top-to-bottom |
| UI dual-focus conflict (4.6) | Medium | Mouse vs keyboard focus not tracked separately | Test all HUD interactions with both mouse and keyboard |

## Performance Implications

- **CPU**: Negligible — node tree structure has zero per-frame cost
- **Memory**: Negligible — 13 Node objects + 1 Grid RefCounted instance (~1KB total)
- **Load Time**: Negligible — scene instantiation is Godot's job
- **Network**: None

## Migration Plan

- Greenfield project — no existing scene to migrate
- `main.tscn` is created from scratch following this ADR's node hierarchy
- All `@export var grid: Grid` fields are set via inspector or programmatically in `_ready()`
- No `get_node(".")` or `get_parent()` calls for grid access anywhere

## Validation Criteria

- All 13 systems exist as direct children of `main.tscn` root (flat list, no intermediate folders)
- `main.gd` creates exactly one `Grid` instance via `Grid.new()` and wires it to all children
- No Autoload singletons are registered in `project.godot` (other than any Godot-required ones)
- UI lives in a `CanvasLayer` child of root
- In GUT tests, a minimal `Main` scene can be created with a mock grid injected

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| grid-system.md | Grid System | All systems access the grid via a shared instance | Single `Grid.new()` on root, injected to all children via `@export var grid: Grid` |
| All GDDs | All | Systems must be independently testable | No Autoloads; grid injectable via `@export`; signal connections observable |
| score-display-system.md | Score Display | UI must render above gameplay | `CanvasLayer` ensures HUD renders above game world |
| All GDDs | All | No hidden global state | Root node is the explicit owner of grid and wiring |

## Related

- ADR-ARCH-001 (Grid Resource Pattern) — Grid is a RefCounted, not a Node or Autoload
- ADR-ARCH-002 (Signal Bus) — All 15 signals use native Godot signal syntax, consumer connects via `connect()` in `_ready()`
- `docs/architecture/architecture.md` Phase 2 (Module Ownership) — defines which system owns which data
- `docs/architecture/architecture.md` Phase 3 (Data Flow) — defines the 15-signal communication map