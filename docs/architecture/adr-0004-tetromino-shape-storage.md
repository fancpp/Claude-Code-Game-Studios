# ADR-ARCH-004: Tetromino Shape Storage

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

All 7 tetromino shapes (I, O, T, S, Z, J, L) are stored as a `class_name TetrominoData extends RefCounted` — a pure data, non-Node class. Each instance holds a precomputed 4×4 boolean occupancy grid for each of the 4 SRS rotation states. A static dictionary on a `TetrominoShapes` static class provides O(1) lookup by piece type. No shape computation at runtime.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Data Structure |
| **Knowledge Risk** | LOW — pure GDScript data structure, no engine API surface area |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-001 (Grid Resource Pattern) — shapes validated against grid bounds |
| **Enables** | ADR-ARCH-005 (Lock Delay), ADR-ARCH-006 (7-Bag Randomizer) |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before Tetromino System implementation |

## Context

### Problem Statement

The Tetromino System needs to store 7 tetromino shapes × 4 rotation states each = 28 shape variants. Each shape variant is a set of 4 occupied cells relative to a pivot point. The question is the data structure: array-of-coordinates, bitmask, or 4×4 occupancy grid? And should shapes be static constants or computed at runtime?

### Constraints

- Must support all 7 standard SRS shapes (I, O, T, S, Z, J, L)
- Must support all 4 SRS rotation states per shape
- Must be fast: accessed every frame during piece movement and rotation
- Must be trivially mockable for unit tests (pure data, no Godot engine dependencies)
- Shapes must be consistent with the SRS wall kick offsets defined in the GDD

### Requirements

- O(1) lookup by piece type (1-7) and rotation state (0-3)
- Rotation transformation: CW `(x, y) → (y, -x)`, CCW `(x, y) → (-y, x)`
- Spawn position: x=4, y=19 (centered at top of 10×20 grid)
- Lock delay: 500ms (per GDD tuning knobs)

## Decision

**Pattern: `TetrominoData` (RefCounted) + `TetrominoShapes` static dictionary.**

Shapes are precomputed as 4×4 boolean occupancy grids, stored in a static dictionary, and accessed without any runtime math.

```gdscript
# tetromino_data.gd
class_name TetrominoData
extends RefCounted

# 4×4 occupancy grid for each rotation state.
# grid[rotation][row][col] = true if occupied.
# row 0 = top, col 0 = left.
# Using Array-of-Arrays (not PackedByteArray) for simplicity — 16 bools per state × 4 states = 64 values.
var rotation_grids: Array = []

func _init(p_grids: Array) -> void:
    rotation_grids = p_grids

# Returns the occupied cells for a given rotation state as local offsets.
func get_cells(rotation: int) -> Array:
    var cells: Array = []
    var grid = rotation_grids[rotation]
    for row in range(4):
        for col in range(4):
            if grid[row][col]:
                cells.append(Vector2i(col, row))
    return cells
```

```gdscript
# tetromino_shapes.gd
class_name TetrominoShapes
extends RefCounted

# Static dictionary: type (1-7) → TetrominoData instance
static var SHAPES: Dictionary = {
    1: TetrominoData.new([  # I
        [[0,0,0,0], [1,1,1,1], [0,0,0,0], [0,0,0,0]],  # rot 0
        [[0,0,1,0], [0,0,1,0], [0,0,1,0], [0,0,1,0]],  # rot 1
        [[0,0,0,0], [0,0,0,0], [1,1,1,1], [0,0,0,0]],  # rot 2
        [[0,1,0,0], [0,1,0,0], [0,1,0,0], [0,1,0,0]],  # rot 3
    ]),
    2: TetrominoData.new([  # O
        [[0,0,0,0], [0,1,1,0], [0,1,1,0], [0,0,0,0]],  # all rotations same
        [[0,0,0,0], [0,1,1,0], [0,1,1,0], [0,0,0,0]],
        [[0,0,0,0], [0,1,1,0], [0,1,1,0], [0,0,0,0]],
        [[0,0,0,0], [0,1,1,0], [0,1,1,0], [0,0,0,0]],
    ]),
    3: TetrominoData.new([  # T
        [[0,0,0,0], [0,1,0,0], [1,1,1,0], [0,0,0,0]],
        [[0,0,0,0], [0,1,0,0], [0,1,1,0], [0,1,0,0]],
        [[0,0,0,0], [0,0,0,0], [1,1,1,0], [0,1,0,0]],
        [[0,0,0,0], [0,1,0,0], [1,1,0,0], [0,1,0,0]],
    ]),
    4: TetrominoData.new([  # S
        [[0,0,0,0], [0,1,1,0], [1,1,0,0], [0,0,0,0]],
        [[0,0,0,0], [0,1,0,0], [0,1,1,0], [0,1,0,0]],
        [[0,0,0,0], [0,0,0,0], [0,1,1,0], [1,1,0,0]],
        [[0,0,0,0], [0,1,0,0], [1,1,0,0], [0,1,0,0]],
    ]),
    5: TetrominoData.new([  # Z
        [[0,0,0,0], [1,1,0,0], [0,1,1,0], [0,0,0,0]],
        [[0,0,0,0], [0,0,1,0], [0,1,1,0], [0,1,0,0]],
        [[0,0,0,0], [0,0,0,0], [1,1,0,0], [0,1,1,0]],
        [[0,0,0,0], [0,1,0,0], [1,1,0,0], [1,0,0,0]],
    ]),
    6: TetrominoData.new([  # J
        [[0,0,0,0], [1,0,0,0], [1,1,1,0], [0,0,0,0]],
        [[0,0,0,0], [0,1,1,0], [0,1,0,0], [0,1,0,0]],
        [[0,0,0,0], [0,0,0,0], [1,1,1,0], [0,0,1,0]],
        [[0,0,0,0], [0,1,0,0], [0,1,0,0], [1,1,0,0]],
    ]),
    7: TetrominoData.new([  # L
        [[0,0,0,0], [0,0,1,0], [1,1,1,0], [0,0,0,0]],
        [[0,0,0,0], [0,1,0,0], [0,1,0,0], [0,1,1,0]],
        [[0,0,0,0], [0,0,0,0], [1,1,1,0], [1,0,0,0]],
        [[0,0,0,0], [1,1,0,0], [0,1,0,0], [0,1,0,0]],
    ]),
}

static func get_data(piece_type: int) -> TetrominoData:
    return SHAPES[piece_type]
```

**Why 4×4 grid instead of cell-offset arrays?**

| Approach | Pros | Cons |
|----------|------|------|
| Cell offsets `Array[Vector2i]` | Compact | Requires rotation math per access |
| 4×4 bool grid | O(1) rotation access via lookup; easy to render | 16 booleans per rotation state |
| Bitmask (packed int) | Most compact | Harder to read/write in GDScript; compiler tricks needed |

The 4×4 grid is the pragmatic choice: O(1) rotation access, trivially readable in the source, and only 64 booleans per piece (256 bytes at runtime for all 7 shapes).

**Why `RefCounted` for `TetrominoData`?**

`RefCounted` allows `SHAPES` dictionary values to be shared by reference without being Nodes. It has no scene tree overhead. The static `SHAPES` dictionary owns one `TetrominoData` instance per piece type — created once at class load time.

**No runtime rotation math.** The rotation grids are precomputed and stored in the static dictionary. Rotation right/left does not compute `(x,y) → (y,-x)` — it just changes the `rotation` index and looks up the new grid. This is faster and avoids floating-point drift.

## Architecture Diagram

```
tetromino.gd (active piece)
  ├── type: int (1-7)
  ├── rotation: int (0-3)
  ├── position: Vector2i (x, y — top-left of 4×4 bounding box)
  │
  └── accesses TetrominoShapes.SHAPES[type].rotation_grids[rotation]
        → returns 4×4 bool grid
        → CollisionSystem.can_move_to(tx, ty, shape_grid) checks occupancy

TetrominoShapes (static class — class_name TetrominoShapes extends RefCounted)
  └── SHAPES: Dictionary { type → TetrominoData }
        └── TetrominoData.rotation_grids[4]: Array[Array] (4×4 bool grid per rotation)

piece_spawn.gd → calls TetrominoShapes.SHAPES[type].get_cells(0) for spawn check
ghost_piece.gd → calls TetrominoShapes.SHAPES[type].get_cells(rotation) for display
```

## Key Interfaces

```gdscript
# tetromino.gd — active piece, accesses shape data
class_name Tetromino
extends Node

var type: int       # 1-7
var rotation: int   # 0-3
var position: Vector2i  # grid coords (x, y)

func get_current_grid() -> Array:
    return TetrominoShapes.SHAPES[type].rotation_grids[rotation]

func rotate_cw() -> bool:
    var new_rotation = (rotation + 1) % 4
    # Test wall kicks...
    rotation = new_rotation
    return true

# Returns world-space occupied cells for current piece
func get_world_cells() -> Array[Vector2i]:
    var local = TetrominoShapes.SHAPES[type].get_cells(rotation)
    return local.map(func(c): return Vector2i(position.x + c.x, position.y + c.y))
```

## Alternatives Considered

### Alternative 1: Cell-offset arrays with runtime rotation math

- **Description**: Store shapes as `Array[Vector2i]` per rotation. Rotate by applying `(x, y) → (y, -x)` formula at runtime.
- **Pros**: Compact memory representation
- **Cons**: Runtime math per rotation (even if cheap, it's unnecessary); floating-point edge cases in `(y, -x)` transformation with integers; more complex to test
- **Rejection Reason**: Precomputing is free (shapes are static data) and eliminates all runtime rotation math. Simpler, no accuracy concerns.

### Alternative 2: Hardcoded shape arrays in `tetromino.gd`

- **Description**: Define shapes as static `const` arrays inside `tetromino.gd` with no separate data class.
- **Pros**: No extra file needed
- **Cons**: `tetromino.gd` becomes both data-holder and piece-controller — violates single responsibility. Harder to share shape data with `ghost_piece.gd` and `piece_spawn.gd` without coupling.
- **Rejection Reason**: Shape data needs to be read by `ghost_piece.gd` (for ghost display), `piece_spawn.gd` (for spawn check), and `tetromino.gd` (for active piece). A shared `TetrominoShapes` class is cleaner than coupling all three to the same const arrays.

## Consequences

### Positive

- O(1) shape lookup by type — no computation, just dictionary access
- All 28 shape variants are precomputed and verified at class-load time
- `TetrominoShapes` is a pure data class — no Godot engine dependencies, trivially mockable in GUT tests
- Rotation state change is index change only — no `(x,y)` transformation math at runtime
- `get_world_cells()` encapsulates the local-to-world transform in one place

### Negative

- Static `SHAPES` dictionary is initialized at class load time — if shape data has an error, it's a runtime crash at first piece spawn (mitigation: precomputed, not derived)
- 4×4 grid uses 16 booleans per state × 4 states × 7 shapes = 448 booleans (~560 bytes) — trivial but not minimal

### Neutral

- Shape data lives in `tetromino_shapes.gd` — separate from `tetromino.gd` (active piece controller). This is intentional separation of data vs. behavior.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Wrong shape data (typo in grid) causes piece to clip or not rotate | Low | Gameplay-breaking | GUT tests verify every rotation state returns the correct cell count and positions for all 7 pieces |
| Class initialization order issue with static dictionary | Low | Crash on first access | Static dictionary initialization is synchronous and deterministic in GDScript |

## Performance Implications

- **CPU**: Near-zero — shape lookup is dictionary access + array index; no computation
- **Memory**: ~560 bytes for all 28 shape variants (negligible)
- **Load Time**: Negligible — static dictionary initialized at class load
- **Network**: None

## Migration Plan

- Greenfield project — no existing shape data to migrate
- `tetromino_shapes.gd` is created with the static dictionary
- `tetromino.gd`, `ghost_piece.gd`, `piece_spawn.gd` all import `TetrominoShapes` via `class_name`
- Unit tests create a `MockTetrominoShapes` with controlled shape data for collision testing

## Validation Criteria

- `TetrominoShapes.SHAPES[1].get_cells(0)` returns 4 cells for the I-piece at rotation 0
- `TetrominoShapes.SHAPES[2].get_cells(0)` equals `get_cells(1)` equals `get_cells(2)` equals `get_cells(3)` (O-piece is symmetric)
- `TetrominoShapes.SHAPES[3].get_cells(1)` returns the T-piece at 90° clockwise
- `tetromino.gd` can create a piece with type=1, rotation=0, position=(4,19) and `get_world_cells()` returns valid grid coordinates
- GUT tests can mock `TetrominoShapes` to return arbitrary shapes for collision testing

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| tetromino-system.md | Tetromino | All 7 SRS shapes stored with 4 rotation states each | 4×4 grid per rotation in `TetrominoShapes.SHAPES` dictionary |
| tetromino-system.md | Tetromino | Rotation matrix CW `(x,y) → (y,-x)`, CCW `(x,y) → (-y,x)` | Precomputed rotation grids — no runtime rotation math needed |
| tetromino-system.md | Tetromino | Spawn position x=4, y=19 | `position: Vector2i(4, 19)` stored in active tetromino.gd |
| collision-system.md | Collision | Wall kick offsets `[(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]` | Defined in `tetromino.gd`'s wall kick logic, not in shape data |

## Related

- ADR-ARCH-001 (Grid Resource Pattern) — Grid is the coordinate space shapes are validated against
- ADR-ARCH-003 (Scene Tree) — `tetromino.gd` lives as a child of `main.tscn`
- `design/gdd/tetromino-system.md` — authoritative source for shape definitions and rotation rules