# ADR-ARCH-001: Grid System Resource Pattern

## Status
Accepted

## Date
2026-04-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Data Structure |
| **Knowledge Risk** | LOW — this decision is pure GDScript class pattern, no engine API surface area |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/physics.md` |
| **Post-Cutoff APIs Used** | None — plain GDScript class |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-ARCH-002 (signal bus), ADR-ARCH-003 (scene tree), all gameplay system ADRs |
| **Blocks** | All subsequent ADRs and all GDD implementation — nothing can be built without this |
| **Ordering Note** | Must be Accepted before any other ADR is created |

## Context

### Problem Statement
The Grid System is the foundation of the entire game. Every gameplay system depends on it: Tetromino reads it, Collision reads it, Line Clearing reads and writes it, Ghost Piece reads it, Score Display reads it. All 13 GDDs reference the grid. The question is: how does the grid exist in the Godot runtime?

### Constraints
- Must be accessible from every other module in the game
- Must not create tight coupling via Autoload singletons (makes testing harder)
- Must not require scene tree path coupling (`get_node("../../Grid")`)
- Must support the full GDD cell API: `get_cell`, `set_cell`, `is_empty`, `is_valid_position`, `clear_grid`
- Must be trivially mockable for unit testing (pure data, no Godot dependencies)

### Requirements
- All 13 GDDs must be able to use the grid's API
- The grid must be a singleton (one grid, one game)
- Grid state must be accessible to any system that needs it
- Grid must be replaceable with a mock in test environments

## Decision

The Grid System is implemented as a **`class_name Grid extends RefCounted`** — a lightweight, non-Node, reference-counted Godot class. It is not an autoload. It is not a child Node.

**Instantiation:** One instance lives as a property on the `main.tscn` root node (or passed via dependency injection to systems that need it). No Godot scene tree path references anywhere.

```gdscript
# grid.gd — placed in src/ or autoloaded as a script resource
class_name Grid
extends RefCounted

var cells: Array  # 10×20, cells[y][x], 0=EMPTY, 1-7=tetromino type

func _init() -> void:
    cells = []
    for i in range(20):
        cells.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

func get_cell(x: int, y: int) -> int:
    return cells[y][x]

func set_cell(x: int, y: int, value: int) -> void:
    cells[y][x] = value

func is_empty(x: int, y: int) -> bool:
    return cells[y][x] == 0

func is_valid_position(x: int, y: int) -> bool:
    return x >= 0 and x < 10 and y >= 0 and y < 20

func clear_grid() -> void:
    for y in range(20):
        for x in range(10):
            cells[y][x] = 0
```

**How systems access it:**
```gdscript
# main.tscn — creates one Grid instance
@onready var grid: Grid = Grid.new()

# Systems that need the grid receive it via exported var or _init parameter
@export var grid: Grid  # set by main.tscn scene composition

# In tests, inject a mock Grid
var mock_grid = Grid.new()  # trivially mockable
```

**Why RefCounted (not Node):**
- RefCounted has no scene tree overhead — it's a pure GDScript object
- No `queue_free()` concerns, no `_ready()` lifecycle, no scene tree coupling
- `class_name` registers it globally in the type system, so type hints work everywhere
- Easy to `duplicate()` for testing
- The grid has no need for `_process`, `_physics_process`, or any Node lifecycle — it's pure data

## Architecture Diagram

```
main.tscn
  ├── GameState (Node)
  ├── InputHandler (Node)
  ├── Grid (RefCounted instance — class_name Grid)  ← injected into children
  ├── Collision (Node, receives grid via @export)
  ├── Tetromino (Node, receives grid via @export)
  ├── PieceSpawn (Node, receives grid via @export)
  ├── LineClear (Node, receives grid via @export)
  ├── ComboScoring (Node)
  ├── GhostPiece (Node)
  ├── SpeedProgression (Node)
  ├── ScoreDisplay (Node)
  ├── VisualFeedback (Node)
  └── AudioFeedback (Node)
```

**Note:** `Grid` is injected into nodes that need it. Alternative (simpler): each node could instantiate its own `Grid` reference if they all share the same instance from main.tscn. See Open Questions.

## Alternatives Considered

### Alternative 1: Autoload singleton
- **Description**: Register `grid.gd` as an Autoload in project.godot, accessible globally as `Grid.`
- **Pros**: Convenient — no wiring needed, `Grid.get_cell()` from anywhere
- **Cons**: Hidden global state makes unit testing impossible without mocking the Autoload; creates tight coupling; violates "no autoload coupling" forbidden pattern; harder to reason about where state is mutated
- **Rejection Reason**: Forbids easy mocking and testability — contradicts the project's testing requirements (GUT, 80% coverage). The grid is accessed by 8 systems; autoloading it hides all those dependencies.

### Alternative 2: Node child of main
- **Description**: Grid as a `Node` child of main.tscn, systems use `$Grid` or `get_node("../Grid")`
- **Pros**: Normal Godot pattern, grid lifecycle tied to scene
- **Cons**: Scene path coupling — every system that uses the grid must know its path in the scene tree; refactoring the scene structure breaks all references; still can't mock without a complex test harness
- **Rejection Reason**: Path coupling is fragile; if the grid node is moved in the scene tree, all dependent code breaks.

### Alternative 3: Global constant/data resource
- **Description**: Grid as a `Resource` saved to disk and loaded as a singleton
- **Pros**: Persistent, shareable
- **Cons**: Overkill — grid is ephemeral game state that resets every game; persistence is not needed; adds file I/O complexity
- **Rejection Reason**: Not needed for an arcade game with no persistent state between sessions.

## Consequences

### Positive
- Grid is trivially mockable for unit tests — create a `MockGrid` with custom cell data
- No scene tree dependencies — refactoring the scene tree never breaks grid access
- No Autoload coupling — all dependencies are explicit (injected via `@export`)
- Pure data class — no `_ready()`, no lifecycle, no Godot overhead
- Type hints work everywhere via `class_name Grid`

### Negative
- One more initialization step: main.tscn must create and wire the Grid instance to child nodes
- Dependency injection via `@export var grid: Grid` must be set in the inspector or via `_ready()` — if forgotten, `grid` is null (runtime error)
- If two systems somehow get different Grid instances, grid state diverges (mitigation: one instance from main.tscn)

### Risks
- **Risk**: Null grid reference at runtime if wiring is forgotten
  - **Mitigation**: Use a `assert(grid != null, "Grid not wired")` in each system's `_ready()` to catch at editor time
- **Risk**: Multiple Grid instances causing state divergence
  - **Mitigation**: Grid is created once in main.tscn; all `@export` references point to the same instance

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| grid-system.md | 10×20 cell array, cell API (get/set/is_empty/is_valid) | Implements all 5 methods as class_name Grid with correct signatures |
| collision-system.md | Depends on Grid via is_empty/is_valid_position | Receives Grid via @export, no autoload coupling |
| tetromino-system.md | Writes locked cells to grid | Receives Grid via @export, calls set_cell() |
| piece-spawn-system.md | Checks spawn position via is_empty | Receives Grid via @export |
| line-clearing-system.md | Reads rows via get_cell, writes EMPTY via set_cell | Receives Grid via @export |
| ghost-piece-system.md | Queries is_empty for drop calculation | Receives Grid via @export |
| game-state-system.md | Resets grid via clear_grid() on new game | Receives Grid via @export, calls clear_grid() |

## Performance Implications
- **CPU**: Negligible — 200-element 2D array access, pure RAM lookup
- **Memory**: ~200 integers = <1KB
- **Load Time**: Negligible — no file I/O, just array allocation
- **Network**: None

## Migration Plan
- Move grid data from any existing Autoload or global variable to `Grid.new()` in main.tscn
- Add `@export var grid: Grid` to all systems that currently use a global reference
- Remove any `get_node("../Grid")` calls and replace with the `@export` reference
- This is a greenfield project — no existing code to migrate

## Validation Criteria
- `grid.get_cell(5, 10)` returns 0 for a fresh grid
- `grid.set_cell(5, 10, 3)` followed by `grid.get_cell(5, 10)` returns 3
- `grid.is_empty(5, 10)` returns false after set_cell with non-zero
- `grid.is_valid_position(10, 0)` returns false (out of bounds)
- `grid.clear_grid()` resets all 200 cells to 0
- Unit tests can create `Grid.new()` and inject it into systems under test