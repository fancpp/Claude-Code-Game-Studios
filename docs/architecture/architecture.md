# Tetris Arcade Challenge — Master Architecture

## Document Status
- Version: 1
- Last Updated: 2026-04-26
- Engine: Godot 4.6
- GDDs Covered: all 13 (grid, input, collision, tetromino, piece-spawn, game-state, line-clearing, combo-scoring, ghost-piece, speed-progression, score-display, visual-feedback, audio-feedback)
- ADRs Referenced: 0 (see Required ADRs — 11 must be created before coding)
- Technical Director Sign-Off: 2026-04-26 — APPROVED (TD-ARCHITECTURE self-review)
- Lead Programmer Feasibility: SKIPPED (Lean mode — no blocking concerns identified)

---

## Engine Knowledge Gap Summary

**Engine: Godot 4.6 | LLM Training Cutoff: ~4.3 | Post-Cutoff Risk: HIGH**

- ⚠️ **UI (HIGH)**: Dual-focus system (4.6) — mouse/touch focus SEPARATE from keyboard/gamepad focus. Score display HUD focus behavior changed.
- ⚠️ **Rendering (HIGH)**: Glow processes before tonemapping (4.6) — 2D flash effects using CanvasModulate may be affected.
- ⚠️ **Input (HIGH)**: SDL3 gamepad driver (4.5) — API stable, backend changed.
- ✅ **Physics (LOW)**: CharacterBody2D/Area2D 2D physics unchanged.
- ✅ **Audio (LOW)**: AudioStreamPlayer API stable.

---

## System Layer Map

### Layer Definitions

| Layer | Role | Systems |
|-------|------|---------|
| **Platform (L0)** | Godot 4.6 engine surface — CharacterBody2D, Area2D, CanvasLayer, AudioStreamPlayer | (engine) |
| **Foundation (L1)** | Pure engine integration. No game logic. All other systems depend on them. | Grid System, Input System |
| **Core (L2)** | Core game mechanics other systems build on. State machines, collision queries, piece lifecycle. | Collision System, Game State System, Tetromino System, Piece Spawn System |
| **Feature (L3)** | Specific gameplay mechanics. Depend on Core systems. Produce data consumed by Presentation. | Line Clearing System, Combo Scoring System, Ghost Piece System, Speed Progression System |
| **Presentation (L4)** | Render gameplay results. Output-only from gameplay perspective. | Score Display System, Visual Feedback System, Audio Feedback System |

### ASCII Dependency Diagram

```
PLATFORM     ┌─────────────────────────────────────────────┐
(Layer 0)    │  Godot 4.6 Engine (CharacterBody2D, Canvas)  │
             └─────────────────────────────────────────────┘
                        ▲            ▲            ▲
FOUNDATION    ┌─────────┴────────────┴────────────┴─────────┐
(Layer 1)    │   Grid System      Input System              │
             │  (10×20 array)   (DAS, key capture)          │
             └─────────┬────────────┬───────────────────────┘
                        │            │
CORE           ┌────────┴─────┐     │      ┌──────────────────┐
(Layer 2)     │ Collision     │     │      │  Game State      │
              │ System        │◄────┘      │  System          │
              │ (can_move_to) │            │ (state machine)  │
              └───────┬───────┘            └────────┬─────────┘
                      │                    ▲         │
                      │  ┌─────────────────│─────────┘
              ┌───────┴──┴──────┐         │
              │  Tetromino      │◄────────┘
              │  System         │
              │  (7 shapes,SRS) │
              └───────┬─────────┘
                      │
              ┌───────┴───────────────────────────────────┐
              │           Piece Spawn System               │
              │       (7-bag, next queue, spawn pos)       │
FEATURE       └───────┬───────────────────────────────────┘
(Layer 3)             │
          ┌───────────┼───────────────────┬───────────────┐
          │           │                   │               │
    ┌─────┴─────┐ ┌───┴──────┐  ┌────────┴────┐  ┌───────┴───────┐
    │ Line Clear│ │  Combo   │  │   Ghost    │  │ Speed Prog.   │
    │  System   │ │ Scoring  │  │   Piece    │  │   System      │
    │(row scan) │ │ (score)  │  │ (drop calc)│  │(level/speed)  │
    └───────────┘ └──────────┘  └────────────┘  └───────────────┘
                        │               │               │
PRESENTATION ◄──────────┴───────────────┴───────────────┘
(Layer 4)     ┌────────────────┬─────────────────┬───────────────┐
              │ Score Display  │ Visual Feedback │ Audio Feedback│
              │   (HUD)        │ (flash/shake)   │  (sounds)     │
              └────────────────┴─────────────────┴───────────────┘
```

### Layer Assignments by System

| System | Layer | Owns | Depends On |
|--------|-------|------|------------|
| Grid System | Foundation (L1) | 10×20 grid array, cell API | (none) |
| Input System | Foundation (L1) | Key capture, DAS timing, 7 actions | (none) |
| Collision System | Core (L2) | can_move_to(), wall kick logic | Grid System |
| Game State System | Core (L2) | State machine (IDLE/PLAYING/PAUSED/GAME_OVER) | Grid System, Input System |
| Tetromino System | Core (L2) | 7 shapes, SRS rotation, lock timer, piece state | Collision System |
| Piece Spawn System | Core (L2) | 7-bag randomizer, next queue, spawn check | Collision System, Tetromino System |
| Line Clearing System | Feature (L3) | Row scan, atomic collapse | Tetromino System, Grid System |
| Combo Scoring System | Feature (L3) | Combo counter, score calculation | Line Clearing System |
| Ghost Piece System | Feature (L3) | Ghost drop calculation | Tetromino System, Grid System, Collision System |
| Speed Progression System | Feature (L3) | Level tracking, drop interval | Game State System |
| Score Display System | Presentation (L4) | HUD rendering | Combo Scoring System, Speed Progression System |
| Visual Feedback System | Presentation (L4) | Flash, shake, glow effects | Line Clearing System, Combo Scoring System |
| Audio Feedback System | Presentation (L4) | Sound trigger and mixing | Line Clearing System, Game State System |

## Module Ownership

### Foundation Layer (L1)

**Grid System** (`grid.gd`)
- **Owns**: 10×20 cell array, cell state (EMPTY=0, OCCUPIED=1-7)
- **Exposes**: `get_cell(x,y)`, `set_cell(x,y,val)`, `is_empty(x,y)`, `is_valid_position(x,y)`, `clear_grid()`
- **Consumes**: (none)
- **Engine APIs**: Plain GDScript class — no engine nodes for pure data storage ✅

**Input System** (`input_handler.gd`)
- **Owns**: Input event capture, DAS state per action (170ms initial, 50ms repeat), soft drop accumulator
- **Exposes**: Action signals: `move_left`, `move_right`, `soft_drop`, `hard_drop`, `rotate_cw`, `rotate_ccw`, `pause`
- **Consumes**: (none — reads Godot Input system directly)
- **Engine APIs**: `Input.is_action_just_pressed()`, `Input.is_action_just_released()`, `_unhandled_input(event)` — all stable ✅

---

### Core Layer (L2)

**Collision System** (`collision.gd`)
- **Owns**: `can_move_to(tx, ty, shape)` — pure query, zero internal state
- **Exposes**: `can_move_to(tx, ty, shape) -> bool`
- **Consumes**: Grid System (`is_empty`, `is_valid_position`)
- **Engine APIs**: None — pure GDScript logic ✅

**Game State System** (`game_state.gd`)
- **Owns**: State enum (IDLE/PLAYING/PAUSED/GAME_OVER), score/level/combo for reset
- **Exposes**: `game_over` signal, `new_game` signal, `paused` boolean property
- **Consumes**: Input System (pause key), Grid System (`clear_grid()` on new game)
- **Engine APIs**: None — pure state machine ✅

**Tetromino System** (`tetromino.gd`)
- **Owns**: 7 shape definitions, SRS rotation state tables (4 states each), active piece (position, rotation, type), lock_timer
- **Exposes**: `piece_locked` signal; `request_spawn()` call; current piece state (read by Ghost and Spawn)
- **Consumes**: Collision System (`can_move_to()`), Input System (action signals), Grid System (`set_cell()` on lock)
- **Engine APIs**: `Timer` node or `_process()` for lock delay — stable ✅

**Piece Spawn System** (`piece_spawn.gd`)
- **Owns**: 7-bag array, next_queue (size=1), spawn_count
- **Exposes**: `piece_spawned(type)` signal, `spawn_failed` signal
- **Consumes**: Collision System (`is_empty(spawn_pos)`), Tetromino System (spawn position constant x=4, y=19)
- **Engine APIs**: None — pure data logic ✅

---

### Feature Layer (L3)

**Line Clearing System** (`line_clear.gd`)
- **Owns**: cleared_rows list, atomic row collapse operation
- **Exposes**: `lines_cleared(count)` signal (fan-out to Combo, Speed, Visual, Audio)
- **Consumes**: Grid System (row scan via `get_cell`), Tetromino System (`piece_locked` trigger)
- **Engine APIs**: None — pure data logic ✅

**Combo Scoring System** (`combo_scoring.gd`)
- **Owns**: combo_counter, total_score, current_combo_multiplier
- **Exposes**: `score`, `combo_counter`, `combo_multiplier` properties; `new_game` reset handler
- **Consumes**: Line Clearing System (`lines_cleared(count)` signal), Input System (drop signals for bonus scoring)
- **Engine APIs**: None — pure data logic ✅

**Ghost Piece System** (`ghost_piece.gd`)
- **Owns**: ghost_position (x, y), ghost_shape (mirrors active piece)
- **Exposes**: `ghost_position`, `ghost_shape` properties (read by rendering)
- **Consumes**: Tetromino System (active piece state), Collision System (`can_move_to()` for ray-cast)
- **Engine APIs**: None — calculation only ✅

**Speed Progression System** (`speed_progression.gd`)
- **Owns**: current_level (1-15), lines_since_last_level, current_drop_interval
- **Exposes**: `drop_interval_ms`, `level` property; `level_up(new_level)` signal
- **Consumes**: Line Clearing System (`lines_cleared(count)` signal), Game State System (new game reset)
- **Engine APIs**: None — pure data logic ✅

---

### Presentation Layer (L4)

**Score Display System** (`score_display.gd`)
- **Owns**: HUD node references (score Label, level Label, combo Label)
- **Exposes**: (writes to UI nodes only — no exports)
- **Consumes**: Combo Scoring System (`score`, `combo_counter`), Speed Progression System (`level`)
- **Engine APIs**: `Label` node for text — stable ✅
  - ⚠️ **4.6 DUAL-FOCUS**: keyboard/gamepad focus SEPARATE from mouse focus. Test HUD focus with both input methods.

**Visual Feedback System** (`visual_feedback.gd`)
- **Owns**: FlashOverlay (CanvasModulate or ColorRect), Camera2D shake offset, combo glow ColorRect, effect timers
- **Exposes**: (writes to rendering nodes only — no exports)
- **Consumes**: Line Clearing System (`lines_cleared(count)`), Combo Scoring System (`combo_multiplier`), Speed Progression System (`level_up`), Game State System (`game_over`)
- **Engine APIs**: `ColorRect` for flash/glow overlay, `Node2D` position offset for shake, `Timer` for effect durations — stable ✅
  - ⚠️ **4.6 GLOW**: glow now processes before tonemapping. Flash overlay brightness may render differently — verify with playtest.

**Audio Feedback System** (`audio_feedback.gd`)
- **Owns**: 9× `AudioStreamPlayer` instances (one per sound type), master/sfx volume scalars
- **Exposes**: (plays audio only — no exports)
- **Consumes**: All gameplay systems (line_cleared, combo, level_up, game_over, piece_locked, hard_drop signals)
- **Engine APIs**: `AudioStreamPlayer` (multiple instances), `AudioServer` for volume control — stable ✅

---

### Module Dependency Diagram

```
grid.gd ──────────────────► collision.gd ──────────────────► tetromino.gd
                           │                                  │
input.gd ─────────────────► game_state.gd                    │
                           │                                  │
                           └─────────────────────────────────► piece_spawn.gd
                                                                        │
                                                                        ▼
tetromino.gd ─────────────► line_clear.gd ◄───────────────── ghost_piece.gd
                           │    │         │
                           ▼    ▼        ▼
                     combo_scoring.gd  speed_progression.gd
                           │                    │
                           └────┬────┬─────────┘
                                ▼    ▼         ▼
                    score_display.gd  visual_feedback.gd  audio_feedback.gd
```

### Engine API Risk Summary

| Module | Engine APIs Used | Risk Level |
|--------|-----------------|------------|
| grid.gd | None (plain GDScript class) | ✅ LOW |
| input_handler.gd | Input.* (stable) | ✅ LOW |
| collision.gd | None | ✅ LOW |
| game_state.gd | None | ✅ LOW |
| tetromino.gd | Timer / _process() | ✅ LOW |
| piece_spawn.gd | None | ✅ LOW |
| line_clear.gd | None | ✅ LOW |
| combo_scoring.gd | None | ✅ LOW |
| ghost_piece.gd | None | ✅ LOW |
| speed_progression.gd | None | ✅ LOW |
| score_display.gd | Label (stable) | ⚠️ MEDIUM — dual-focus 4.6 |
| visual_feedback.gd | ColorRect, Node2D, Timer | ⚠️ MEDIUM — glow 4.6 |
| audio_feedback.gd | AudioStreamPlayer × 9 | ✅ LOW |

## Data Flow

### 1. Frame Update Path (60fps game loop)

```
_tick (every frame, delta = 16.6ms target)
  │
  ├── input_handler.gd: _unhandled_input(event)
  │     └── emit signals: move_left, move_right, soft_drop, hard_drop, rotate_cw, rotate_ccw
  │
  ├── tetromino.gd: _process(delta)
  │     ├── on move_left/right → apply movement if can_move_to() → reset lock_timer
  │     ├── on rotate_cw/ccw → apply rotation if can_move_to() with wall kicks → reset lock_timer
  │     ├── on soft_drop → apply down movement (20× gravity speed)
  │     ├── on hard_drop → lock immediately: set_cell(), emit piece_locked
  │     ├── gravity tick (current_drop_interval) → attempt move down
  │     │     └── if can_move_to() false → start/continue lock_timer
  │     │          └── if lock_timer >= 500ms → lock_piece(), set_cell(), emit piece_locked
  │     └── on piece_locked → piece_spawn.gd: request_spawn()
  │
  ├── piece_spawn.gd:
  │     ├── pop next piece from queue → tetromino.gd: activate_piece(type)
  │     └── check is_empty(4,19) → if occupied: emit spawn_failed → game_state.gd: GAME_OVER
  │
  ├── line_clear.gd: on piece_locked
  │     ├── scan rows y=0→19, collect rows where all 10 cells occupied
  │     ├── if cleared_rows: atomic collapse (remove cleared, shift remaining down)
  │     └── emit lines_cleared(count) → fan-out to 4 downstream
  │
  ├── combo_scoring.gd: on lines_cleared(count)
  │     ├── if count > 0: combo_counter += 1 else combo_counter = 0
  │     ├── score_earned = BASE_POINTS[count] × count × min(combo_counter, 5)
  │     └── emit score_changed, combo_changed
  │
  ├── speed_progression.gd: on lines_cleared(count)
  │     ├── lines_since_last_level += count
  │     ├── if lines_since_last_level >= 10: level += 1, emit level_up, reset counter
  │     └── emit drop_interval_ms = max(100, 1000 - (level-1) × 50)
  │
  ├── ghost_piece.gd: recalculate on any tetromino state change (move/rotate/spawn)
  │     └── ghost_y = piece_y; while can_move_to(piece_x, ghost_y-1, shape): ghost_y -= 1
  │
  ├── score_display.gd: on score_changed, level_up, combo_changed
  │     └── update Label text: "000000", "LV {n}", "×{n}" (combo hidden at 0)
  │
  ├── visual_feedback.gd: on lines_cleared, level_up, game_over
  │     ├── flash: ColorRect opacity 0.3 → 0 (linear decay, 100-300ms)
  │     ├── shake: Node2D offset random(-mag, mag) decaying (100-300ms)
  │     ├── combo_glow: ColorRect gold (255,215,0) 500ms fade-out
  │     └── game_over: CanvasModulate color dim to 50%
  │
  └── audio_feedback.gd: on any gameplay signal
        └── play sound: effective_volume = master_vol × sfx_vol × type_scalar; pitch ±2%
```

### 2. Signal Communication Map (fan-out pattern)

| Signal | Emitter | Receivers |
|--------|---------|-----------|
| `move_left` | input_handler.gd | tetromino.gd |
| `move_right` | input_handler.gd | tetromino.gd |
| `soft_drop` | input_handler.gd | tetromino.gd, combo_scoring.gd |
| `hard_drop` | input_handler.gd | tetromino.gd, combo_scoring.gd |
| `rotate_cw` | input_handler.gd | tetromino.gd |
| `rotate_ccw` | input_handler.gd | tetromino.gd |
| `pause` | input_handler.gd | game_state.gd |
| `piece_locked` | tetromino.gd | line_clear.gd, piece_spawn.gd |
| `spawn_failed` | piece_spawn.gd | game_state.gd → GAME_OVER |
| `lines_cleared(count)` | line_clear.gd | combo_scoring.gd, speed_progression.gd, visual_feedback.gd, audio_feedback.gd |
| `level_up(new_level)` | speed_progression.gd | visual_feedback.gd, audio_feedback.gd, score_display.gd |
| `game_over` | game_state.gd | visual_feedback.gd, audio_feedback.gd |
| `new_game` | game_state.gd | combo_scoring.gd, speed_progression.gd |
| `score_changed` | combo_scoring.gd | score_display.gd |
| `combo_changed` | combo_scoring.gd | score_display.gd, visual_feedback.gd |

**Architecture pattern — Signal-based fan-out:** The `lines_cleared` signal is the distribution hub. One `piece_locked` event fans out to 4 independent downstream systems. Producers and consumers are fully decoupled — no direct imports between them.

### 3. Save/Load Path

**Persisted state (user settings only):**

| Module | Persisted State | Storage |
|--------|----------------|---------|
| input_handler.gd | Keybindings | `ConfigFile` → `user://settings.cfg` |
| score_display.gd | Master volume, SFX volume | `ConfigFile` → `user://settings.cfg` |
| audio_feedback.gd | Master volume, SFX volume | `ConfigFile` → `user://settings.cfg` |

**Not persisted (arcade purity):**
- Grid, tetromino, combo, speed, line-clear state — all reset every game
- High score persistence deferred to Vertical Slice (post-MVP)

### 4. Initialization Order

```
1. main.tscn: _ready()
     │
2. game_state.gd: _ready() → state = IDLE
     │
3. grid.gd: _ready() → grid = 200×[0] (10×20, all EMPTY)
     │
4. input_handler.gd: _ready() → init DAS state, load keybindings from ConfigFile
     │
5. combo_scoring.gd: _ready() → reset(): combo_counter=0, total_score=0
     │
6. speed_progression.gd: _ready() → reset(): level=1, lines_since_last_level=0, drop_interval=1000
     │
7. piece_spawn.gd: _ready() → shuffle bag, fill next_queue
     │
8. score_display.gd: _ready() → init labels: "000000", "LV 1", combo hidden
     │
9. visual_feedback.gd: _ready() → init flash/shake/glow nodes, state=IDLE
     │
10. audio_feedback.gd: _ready() → init 9× AudioStreamPlayer, load volumes from ConfigFile
     │
11. tetromino.gd: _ready() → no active piece yet
     │
12. Player presses Start → game_state: IDLE → PLAYING
     │
13. tetromino.gd: request_spawn() → piece_spawn.gd: spawn first piece
```

## API Boundaries

### Core Module Contracts (GDScript pseudocode)

**Grid System (`grid.gd`)**
```gdscript
class_name Grid
extends RefCounted

var cells: Array        # 10×20, cells[y][x], 0=EMPTY, 1-7=tetromino type

func get_cell(x: int, y: int) -> int: ...
func set_cell(x: int, y: int, value: int) -> void: ...
func is_empty(x: int, y: int) -> bool: ...
func is_valid_position(x: int, y: int) -> bool: ...  # x∈[0,9], y∈[0,19]
func clear_grid() -> void: ...  # reset all 200 cells to EMPTY
```

**Collision System (`collision.gd`)**
```gdscript
class_name Collision
extends RefCounted

# Pure function — no internal state, no side effects
func can_move_to(tx: int, ty: int, shape: Array) -> bool:
    # shape = Array of (cx, cy) Vector2i cell offsets
    # Returns true iff ALL cells in bounds AND is_empty for every cell
    pass

func get_wall_kick_offsets() -> Array:
    return [(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]
```

**Tetromino System (`tetromino.gd`)**
```gdscript
class_name Tetromino
extends Node  # needs _process for gravity timer

var position: Vector2i   # grid (x, y) of reference cell
var rotation: int        # SRS state 0-3
var piece_type: int      # 1-7 (I,O,T,S,Z,J,L)

signal piece_locked

func activate(type: int, x: int, y: int) -> void: ...
func request_spawn() -> void: ...  # called after lock — emits piece_locked
```

**Game State System (`game_state.gd`)**
```gdscript
class_name GameState
extends Node

enum State { IDLE, PLAYING, PAUSED, GAME_OVER }
var state: State

signal game_over
signal new_game
signal paused_changed(is_paused: bool)

func toggle_pause() -> void: ...   # PLAYING↔PAUSED
func start_game() -> void: ...     # IDLE→PLAYING
func restart_game() -> void: ...   # GAME_OVER→PLAYING (instant, no IDLE stop)
func trigger_game_over() -> void: ...  # spawn_failed→GAME_OVER
```

**Piece Spawn System (`piece_spawn.gd`)**
```gdscript
class_name PieceSpawn
extends Node

signal piece_spawned(type: int)  # emits piece type 1-7
signal spawn_failed               # triggers game over

func request_spawn() -> void:
    # 1. Pop next piece from queue
    # 2. Check is_empty(4, 19) via Collision System
    # 3a. Clear → emit piece_spawned(type), refill queue
    # 3b. Occupied → emit spawn_failed
```

**Line Clearing System (`line_clear.gd`)**
```gdscript
class_name LineClear
extends Node

signal lines_cleared(count: int)  # fan-out to 4 downstream systems

func on_piece_locked() -> void:
    # 1. Scan rows y=0→19, collect full rows
    # 2. Atomic collapse: remove cleared rows, shift remaining down
    # 3. emit lines_cleared(count)
```

**Combo Scoring System (`combo_scoring.gd`)**
```gdscript
class_name ComboScoring
extends Node

var score: int
var combo_counter: int
var combo_multiplier: int  # min(combo_counter, 5)

signal score_changed(new_score: int)
signal combo_changed(counter: int, multiplier: int)

func on_lines_cleared(count: int) -> void: ...
func on_new_game() -> void: ...           # reset
func on_soft_drop(distance: int) -> void: ...  # +1pt/cell
func on_hard_drop(distance: int) -> void: ...  # +2pt/cell
```

**Speed Progression System (`speed_progression.gd`)**
```gdscript
class_name SpeedProgression
extends Node

var level: int           # 1-15
var drop_interval_ms: int  # = max(100, 1000 - (level-1) × 50)

signal level_up(new_level: int)
signal drop_interval_changed(ms: int)

func on_lines_cleared(count: int) -> void:
    # lines_since_last_level += count; if >=10: level++, emit level_up
    emit_signal("drop_interval_changed", drop_interval_ms)
```

**Ghost Piece System (`ghost_piece.gd`)**
```gdscript
class_name GhostPiece
extends Node

var ghost_position: Vector2i  # (x, y) — read by rendering
var ghost_shape: Array        # mirrors active piece shape

func recalculate(current_pos: Vector2i, current_shape: Array, collision: Collision) -> void:
    ghost_y = current_pos.y
    while collision.can_move_to(current_pos.x, ghost_y - 1, current_shape):
        ghost_y -= 1
    ghost_position = Vector2i(current_pos.x, ghost_y)
    ghost_shape = current_shape
```

**Score Display System (`score_display.gd`)**
```gdscript
class_name ScoreDisplay
extends Node

@onready var score_label: Label
@onready var level_label: Label
@onready var combo_label: Label

func _ready() -> void:
    combo_label.visible = false

func on_score_changed(new_score: int) -> void:
    score_label.text = "%06d" % new_score if new_score <= 999999 else "999999+"

func on_level_up(new_level: int) -> void:
    level_label.text = "LV %d" % new_level

func on_combo_changed(counter: int, multiplier: int) -> void:
    combo_label.visible = counter > 0
    combo_label.text = "×%d" % multiplier if counter > 0 else ""
```

**Visual Feedback System (`visual_feedback.gd`)**
```gdscript
class_name VisualFeedback
extends Node

@onready var flash_overlay: ColorRect
@onready var camera: Node2D  # for shake offset
@onready var combo_glow: ColorRect
@onready var game_dimmer: CanvasModulate

func on_lines_cleared(count: int) -> void: ...
func on_level_up() -> void: ...
func on_combo_glow() -> void: ...  # combo ×5 trigger
func on_game_over() -> void: ...
func on_pause_changed(is_paused: bool) -> void: ...  # freeze all timers
```

**Audio Feedback System (`audio_feedback.gd`)**
```gdscript
class_name AudioFeedback
extends Node

@onready var players: Array[AudioStreamPlayer]  # 9 instances, indexed by sound type

func on_piece_locked() -> void:     # 50ms click
func on_lines_cleared(count: int) -> void:  # 100-400ms beep, varies by count
func on_level_up() -> void:         # 300ms ascending arpeggio
func on_combo_chime() -> void:      # 200ms at combo ×5
func on_game_over() -> void:        # 500ms descending tone
func on_hard_drop() -> void:        # 30ms thud

func set_master_volume(v: float) -> void: ...  # 0.0-1.0
func set_sfx_volume(v: float) -> void: ...     # 0.0-1.0
```

### Cross-Module Invariants

1. `can_move_to()` always called with shape from active tetromino — never with stale shape
2. `line_clear.gd` must finish collapse BEFORE `tetromino.gd` emits next `request_spawn()` — collapse is atomic within a single frame
3. Ghost piece recalculates AFTER tetromino state change is confirmed — not before
4. All 9 `AudioStreamPlayer` instances in `audio_feedback.gd` play simultaneously — no shared bus that could cause clipping
5. Score display format never shows more than "999999+" even if internal score exceeds 999,999

## ADR Audit

**Existing ADRs found: 0.** No architecture decisions have been recorded yet.

### Traceability Coverage Check

All 43 Technical Requirements (TR-*) from the baseline are currently **uncovered** — no ADR addresses any GDD requirement yet. This is expected at this stage: the architecture document establishes the context for ADRs to be created.

| Req ID | Requirement | ADR Coverage | Status |
|--------|-------------|--------------|--------|
| TR-grid-001 | 10×20 grid, bottom-left origin | — | ❌ GAP |
| TR-grid-002 | Cell API get/set/is_empty/is_valid | — | ❌ GAP |
| TR-collision-001 | can_move_to() pure query | — | ❌ GAP |
| TR-tetromino-001 | 7 shapes, SRS rotation | — | ❌ GAP |
| TR-spawn-001 | 7-bag randomizer | — | ❌ GAP |
| TR-gamestate-001 | 4-state machine | — | ❌ GAP |
| TR-lineclear-001 | Row scan bottom-to-top | — | ❌ GAP |
| TR-combo-002 | Combo multiplier cap 5 | — | ❌ GAP |
| TR-ghost-001 | Ray-cast ghost drop | — | ❌ GAP |
| TR-speed-001 | Drop interval formula | — | ❌ GAP |
| TR-score-001 | 6-digit zero-padded score | — | ❌ GAP |
| TR-visual-001 | 30% opacity flash | — | ❌ GAP |
| TR-audio-001 | 9 distinct sounds | — | ❌ GAP |
| *(all 43 TRs)* | *(all uncovered)* | — | ❌ ALL GAPS |

**Verdict:** All TRs uncovered — no existing ADR addresses any requirement. All 11 required ADRs below must be created before coding begins.

---

## Required ADRs

### Must Have Before Coding Starts (Foundation + Core)

| # | Title | Covers | Priority |
|---|-------|--------|----------|
| ADR-ARCH-001 | Grid system resource pattern | TR-grid-002 (cell API) | CRITICAL |
| ADR-ARCH-002 | Signal bus architecture | All signal-based fan-out (lines_cleared, etc.) | CRITICAL |
| ADR-ARCH-003 | Scene tree structure | All modules | CRITICAL |
| ADR-ARCH-004 | Tetromino shape storage + SRS | TR-tetromino-001, TR-tetromino-004 | CRITICAL |
| ADR-ARCH-005 | Lock delay timer implementation | TR-tetromino-003, TR-collision-003 | HIGH |
| ADR-ARCH-006 | 7-bag randomizer implementation | TR-spawn-001 | HIGH |

### Should Have Before Presentation Layer

| # | Title | Covers | Priority |
|---|-------|--------|----------|
| ADR-ARCH-007 | Visual effect node architecture | TR-visual-001, TR-visual-002, TR-ghost-002 | HIGH |
| ADR-ARCH-008 | Audio stream player architecture | TR-audio-001 through TR-audio-004 | HIGH |
| ADR-ARCH-009 | Score display component | TR-score-001, TR-score-002, TR-score-003 | MEDIUM |

### Verify Before 4.6 Implementation

| # | Title | Covers | Priority |
|---|-------|--------|----------|
| ADR-ARCH-010 | Godot 4.6 UI dual-focus compatibility | score-display-system.md HUD | MEDIUM |
| ADR-ARCH-011 | Godot 4.6 glow tonemapping order | visual-feedback-system.md flash | MEDIUM |

---

## Architecture Principles

Five principles derived from the game concept, GDDs, and technical preferences:

1. **Pillar-First Design** — Every architectural decision must serve at least one of the four pillars: Operation Precision, Rhythm of Growth, Combo Reward, Instant Retry. A decision that serves none must be rejected.

2. **Pure Functions for Core Logic** — Collision, combo scoring, speed progression, line clearing are all pure functions: same inputs → same outputs, no hidden state, no side effects. This makes them trivially unit-testable and is non-negotiable for the core game loop.

3. **Signal-Based Fan-Out, Not Direct Imports** — Systems communicate through Godot signals, not by importing each other. The `line_cleared` event fans out to 4 downstream consumers without them knowing about each other. This prevents circular dependency and makes testing at boundaries trivial.

4. **Engine API Calls at Boundaries Only** — All game logic (scoring, collision, spawning, state) is engine-agnostic GDScript. Engine APIs (Input, Timer, AudioStreamPlayer, Label) are used only at the presentation edge. Core systems are portable and testable without a running Godot scene.

5. **60fps / 16.6ms Frame Budget for Web** — All frame-update code must complete within 16.6ms. The game loop is simple enough (no physics simulation, no pathfinding) that this should not be challenging, but the constraint must be verified during implementation with profiling.

---

## Open Questions

The following decisions are intentionally deferred — they do not block MVP implementation but must be resolved before the relevant layer is built:

| # | Question | Affects | Deferred Until |
|---|----------|---------|----------------|
| OQ-001 | Hard drop distance used for scoring — should it use actual cells fallen or theoretical drop to landing position? | combo_scoring.gd | ADR-ARCH-006 |
| OQ-002 | Does hard drop score bonus apply BEFORE or AFTER combo multiplier? (Both are additive; this is a UI question) | combo_scoring.gd | Implementation |
| OQ-003 | Should DAS be configurable by the player (key repeat rate)? | input_handler.gd | MVP deferred |
| OQ-004 | Ghost piece style — outline only vs. dotted fill vs. semi-transparent fill? | visual_feedback.gd | Art decision |
| OQ-005 | Sound on/off persistence — stored in ConfigFile, same as volume? | audio_feedback.gd | ConfigFile ADR |

---

## Document Status

| Field | Value |
|-------|-------|
| Version | 1 |
| Last Updated | 2026-04-26 |
| Engine | Godot 4.6 |
| GDDs Covered | 13 (all MVP + Vertical Slice systems) |
| ADRs Referenced | 0 (none yet — see Required ADRs above) |
| Technical Director Sign-Off | PENDING |
| Lead Programmer Feasibility | PENDING |