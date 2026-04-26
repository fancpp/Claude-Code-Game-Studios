# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-04-26
> **Manifest Version**: 2026-04-26
> **ADRs Covered**: ADR-ARCH-001 (Grid Resource Pattern), ADR-ARCH-002 (Signal Bus), ADR-ARCH-003 (Scene Tree)
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed this date when created. `/story-readiness` compares a story's embedded version to this field to detect stories written against stale rules. Always matches `Last Updated` — they are the same date, serving different consumers.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs, technical preferences, and engine reference docs. For the reasoning behind each rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, engine initialisation, Grid System, Input System*

### Required Patterns

- **Grid must be `class_name Grid extends RefCounted`** — pure data class, no Node lifecycle, no `_process`, no `_ready`. Source: ADR-ARCH-001
- **Grid API must provide**: `get_cell(x, y)`, `set_cell(x, y, value)`, `is_empty(x, y)`, `is_valid_position(x, y)`, `clear_grid()`. Source: ADR-ARCH-001
- **Grid instantiated once**: `Grid.new()` on `main.tscn` root node. Never instantiate multiple Grid instances — causes state divergence. Source: ADR-ARCH-001
- **Grid accessed via `@export var grid: Grid`** on every system that needs it. Set in inspector or programmatically in `_ready()`. Source: ADR-ARCH-001, ADR-ARCH-003
- **All 13 systems are direct children of `main.tscn` root** — flat hierarchy, no intermediate `Core/`, `Feature/`, `Presentation/` group nodes. Source: ADR-ARCH-003
- **`main.gd` wires grid to all children in `_ready()`** — explicit injection, no `get_node()` for grid access. Source: ADR-ARCH-003
- **UI renders in `CanvasLayer` child of root** — above game world, no z-index tricks needed. Source: ADR-ARCH-003
- **No Autoload singletons** registered in `project.godot` except Godot-required ones. Source: ADR-ARCH-001, ADR-ARCH-002, ADR-ARCH-003
- **Init order** (top-to-bottom in scene tree): Grid → input_handler → game_state → collision → tetromino → piece_spawn → line_clear → combo_scoring → ghost_piece → speed_progression → visual_feedback → audio_feedback → ui_layer/score_display. Source: ADR-ARCH-003

### Forbidden Approaches

- **Never use `Autoload` for grid or any shared state** — hidden global state makes GUT testing impossible. Source: ADR-ARCH-001
- **Never use `get_node("...")` for grid access** — path coupling breaks on scene refactoring. Source: ADR-ARCH-001
- **Never register grid or game state as Autoload** — testability requirement prohibits this. Source: ADR-ARCH-001
- **Never use `EventBus` or any central signal bus** — native Godot signals are observable in debugger. Source: ADR-ARCH-002
- **Never route signals through an intermediate singleton** — consumers connect directly to producer signals. Source: ADR-ARCH-002

### Performance Guardrails

- **Grid**: <1KB memory, 200-element array — negligible CPU. Source: ADR-ARCH-001

---

## Core Layer Rules

*Applies to: core gameplay loop, Collision System, Game State System, Tetromino System, Piece Spawn System*

### Required Patterns

- **Collision queries via `can_move_to(tx, ty, shape)`** on collision node — pure query, no state mutation. Source: GDD collision-system.md
- **Tetromino uses SRS rotation** — 4×4 occupancy grid, wall kick offsets per tetromino-system.md. Source: ADR-ARCH-004
- **Piece spawn uses 7-bag randomizer** with seeded `RandomNumberGenerator` for deterministic tests. Source: ADR-ARCH-006
- **Lock delay: 500ms timer per piece** — resets on valid move, pauses when DAS is active. Source: ADR-ARCH-005
- **Each system's `_ready()` asserts grid is wired**: `assert(grid != null, "Grid not wired")`. Source: ADR-ARCH-003
- **Consumers own signal `connect()` calls** in their `_ready()` — producer does not know its consumers. Source: ADR-ARCH-002

### Forbidden Approaches

- **Never use direct method calls for cross-system communication** — creates tight coupling. Source: ADR-ARCH-002
- **Never call `get_node()` on `../` paths for grid access** — use `@export var grid: Grid` injection instead. Source: ADR-ARCH-003

---

## Feature Layer Rules

*Applies to: Line Clearing, Combo Scoring, Ghost Piece, Speed Progression Systems*

### Required Patterns

- **`lines_cleared(count)` signal fans out to 4 consumers** — combo_scoring, speed_progression, visual_feedback, audio_feedback. Source: ADR-ARCH-002
- **Ghost piece queries `is_empty` for drop destination** — writes ghost position read by visual_feedback. Source: GDD ghost-piece-system.md
- **Combo scoring tracks counter + multiplier** — emits `combo_changed(counter, multiplier)` and `combo_x5` when counter first reaches 5. Source: GDD combo-scoring-system.md
- **Speed progression emits `level_up(new_level)`** on every N lines cleared. Source: GDD speed-progression-system.md

### Forbidden Approaches

- **Never** use `EventBus.emit("lines_cleared", count)` — emit from `line_clear.gd` directly. Source: ADR-ARCH-002

---

## Presentation Layer Rules

*Applies to: Score Display, Visual Feedback, Audio Feedback Systems*

### Required Patterns

- **Score display subscribes to signals** from combo_scoring and speed_progression — no polling. Source: ADR-ARCH-009
- **Visual feedback triggers `ColorRect` flash overlays** at 30% opacity, 200ms fade. Source: ADR-ARCH-007
- **Audio feedback plays cues on all gameplay signals** — move tick, lock thud, line clear chime, combo ×5 special chime, level-up fanfare, game-over sting. Source: ADR-ARCH-008

### Forbidden Approaches

- **Never use `yield()`** — use `await` for coroutines per Godot 4.0 GDScript 2.0 idiom. Source: deprecated-apis.md
- **Never use string-based `connect()`** — use `signal.connect(callable)` typed form. Source: deprecated-apis.md

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `PlayerController` |
| Variables/functions | snake_case | `move_speed` |
| Signals | snake_case past tense | `health_changed`, `lines_cleared` |
| Files | snake_case matching class | `player_controller.gd` |
| Scenes | PascalCase matching root node | `PlayerController.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH` |

### Performance Budgets

| Target | Value |
|--------|-------|
| Framerate | 60fps |
| Frame budget | 16.6ms |
| Draw calls | <100/frame for web performance |
| Memory ceiling | <100MB for web deployment |

### Testing Requirements

| Requirement | Value |
|-------------|-------|
| Framework | GUT (Godot Unit Tester) |
| Minimum coverage | 80% |
| Required test areas | Tetromino rotation, line clearing, combo scoring, collision detection, DAS timing |

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or behave differently in 4.6. Never use them:

| Deprecated | Use Instead | Why |
|------------|-------------|-----|
| `yield()` | `await signal` | GDScript 2.0 coroutine syntax |
| `connect("signal", obj, "method")` (string form) | `signal.connect(callable)` | Type-safe, refactor-friendly |
| `instance()` | `instantiate()` | Method renamed in 4.0 |
| `PackedScene.instance()` | `PackedScene.instantiate()` | Method renamed in 4.0 |
| `get_world()` | `get_world_3d()` | Explicit 2D/3D split |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | Time singleton preferred |
| `TileMap` | `TileMapLayer` | One node per layer (4.3+) |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` | Renamed for clarity |
| `YSort` node | `Node2D.y_sort_enabled` | Property on Node2D, not separate node |

### Cross-Cutting Constraints

- **No `get_node()` for grid access** — always `@export var grid: Grid`. Source: ADR-ARCH-001
- **No Autoloads for game state** — all state via dependency injection. Source: ADR-ARCH-001
- **Never use `assert()` to suppress errors** — `assert()` is debug-only in Godot
- **All `@export` fields must have type hints** — no untyped exports
- **DAS applies to**: Move Left, Move Right, Soft Drop — 170ms initial, 50ms repeat. Source: ADR-ARCH-012
- **DAS does NOT apply to**: Hard Drop, Rotate CW, Rotate CCW, Pause — immediate signal emit. Source: ADR-ARCH-012
- **Left+right simultaneous cancels both DAS** — state resets to 0 for both actions. Source: ADR-ARCH-012
- **DAS auto-pauses with game** — via `_process()` pause mechanism, no explicit pause wiring needed. Source: ADR-ARCH-012