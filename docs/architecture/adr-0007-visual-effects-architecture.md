# ADR-ARCH-007: Visual Effects Architecture

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

The Visual Feedback System uses a `ColorRect` overlay for flash and combo glow, and a `Node2D` container offset for screen shake. Multiple effects coexist — they are additive, not exclusive. Each effect is driven by a signal and managed in `_process()` with the same delta-accumulation pattern as the lock delay timer (auto-pause with game, no explicit wiring). Effects track their own elapsed time; no Godot `Timer` nodes.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Presentation / Rendering |
| **Knowledge Risk** | MEDIUM — 4.6 changed glow processing order (glow before tonemapping). Flash overlay brightness may render differently than in prior versions. |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None — uses stable `ColorRect`, `Node2D` APIs |
| **Verification Required** | Flash overlay brightness must be verified against Godot 4.6 (playtest) due to glow-before-tonemapping change |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-002 (Signal Bus) — all effects are signal-driven |
| **Enables** | All GDD implementation for visual feedback |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before Visual Feedback System implementation |

## Context

### Problem Statement

The Visual Feedback System needs to produce 5 types of effects (flash, shake, combo glow, level-up flash, game over dim) that can overlap and must all pause/resume correctly with the game. The question is: what nodes implement each effect, how are they driven, and how do they coexist without interference?

### Constraints

- Flash and combo glow require an overlay covering the entire screen (full-viewport `ColorRect`)
- Screen shake moves the entire game canvas (all gameplay nodes as a unit)
- Effects can play simultaneously (Tetris + lock pulse can coexist)
- Effects must pause and resume with the game (same `_process()` pattern as lock delay)
- Godot 4.6 changed glow processing before tonemapping — flash brightness may be affected

### Requirements

- All effects triggered by signals from upstream systems (no polling)
- Flash: 30% white opacity, decays to 0 over 100-300ms depending on line count
- Shake: random x/y offset within 2-8px magnitude, decays linearly
- Combo glow: gold `ColorRect` overlay, fades out over 500ms
- Game over dim: 50% brightness `ColorRect`, instant, persists until new game

## Decision

**Pattern: Signal-driven `_process()` delta effects, `ColorRect` overlays, `Node2D` container shake.**

### Node Structure (in `main.tscn`)

```
main.tscn
  ├── game_canvas (Node2D)          ← all gameplay nodes live here, shake moves this
  │     ├── grid.gd
  │     ├── tetromino.gd
  │     ├── line_clear.gd
  │     └── ... (all gameplay nodes)
  │
  └── visual_feedback.gd (Node)
        ├── flash_overlay (ColorRect)      ← full-screen white flash
        ├── combo_glow_overlay (ColorRect) ← full-screen gold glow
        ├── dim_overlay (ColorRect)        ← full-screen dim (game over)
        └── game_overlay (ColorRect)       ← 50% dim for game over state
```

All `ColorRect` overlays are children of `visual_feedback.gd`, sized to the full viewport (`anchors_preset = Control.PRESET_FULL_RECT`), and layered above gameplay via their z-order within the scene tree. `game_canvas` is the node that receives shake offset.

**Shake implementation — `game_canvas` offset approach:**

Instead of offsetting individual nodes, the entire `game_canvas` Node2D applies a random `x/y` offset each frame within the current shake magnitude:

```gdscript
# visual_feedback.gd — shake effect
class_name VisualFeedback
extends Node

var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_magnitude: float = 0.0
var _is_shaking: bool = false

@onready var game_canvas: Node2D = $"../../game_canvas"

func _process(delta: float) -> void:
    if _is_shaking:
        _shake_time += delta
        var progress := _shake_time / _shake_duration
        if progress >= 1.0:
            _is_shaking = false
            game_canvas.position = Vector2.ZERO
        else:
            var magnitude := _shake_magnitude * (1.0 - progress)  # linear decay
            game_canvas.position = Vector2(
                randf_range(-magnitude, magnitude),
                randf_range(-magnitude, magnitude)
            )

func trigger_shake(duration: float, magnitude: float) -> void:
    _shake_time = 0.0
    _shake_duration = duration
    _shake_magnitude = magnitude
    _is_shaking = true
```

**Flash implementation — `ColorRect` with modulated opacity:**

```gdscript
# visual_feedback.gd — flash effect
var _flash_time: float = 0.0
var _flash_duration: float = 0.0
var _is_flashing: bool = false
const FLASH_INITIAL_OPACITY: float = 0.3

@onready var flash_overlay: ColorRect = $flash_overlay

func _process(delta: float) -> void:
    if _is_flashing:
        _flash_time += delta
        var progress := _flash_time / _flash_duration
        if progress >= 1.0:
            _is_flashing = false
            flash_overlay.modulate.a = 0.0
        else:
            flash_overlay.modulate.a = FLASH_INITIAL_OPACITY * (1.0 - progress)

func trigger_flash(duration: float) -> void:
    _flash_time = 0.0
    _flash_duration = duration
    _is_flashing = true
    flash_overlay.modulate.a = FLASH_INITIAL_OPACITY
    flash_overlay.visible = true
```

**Combo glow — gold `ColorRect` with fade:**

```gdscript
func trigger_combo_glow(duration: float) -> void:
    _glow_time = 0.0
    _glow_duration = duration
    _is_glowing = true
    combo_glow_overlay.modulate = Color(1.0, 0.84, 0.0, 1.0)  # gold
    combo_glow_overlay.visible = true

func _process(delta: float) -> void:
    if _is_glowing:
        _glow_time += delta
        var progress := _glow_time / _glow_duration
        if progress >= 1.0:
            _is_glowing = false
            combo_glow_overlay.visible = false
        else:
            combo_glow_overlay.modulate.a = 1.0 - progress
```

**Game over dim — instant, persistent:**

```gdscript
func _on_game_state_game_over() -> void:
    dim_overlay.visible = true
    dim_overlay.modulate.a = 0.5  # 50% brightness

func _on_game_state_new_game() -> void:
    dim_overlay.visible = false
    dim_overlay.modulate.a = 0.0
```

**Effect signal handlers (connected in `_ready()`):**

```gdscript
func _ready() -> void:
    line_clear.lines_cleared.connect(_on_lines_cleared)
    tetromino.piece_locked.connect(_on_piece_locked)
    speed_progression.level_up.connect(_on_level_up)
    combo_scoring.combo_x5.connect(_on_combo_x5)   # combo reaches ×5
    game_state.game_over.connect(_on_game_over)
    game_state.new_game.connect(_on_new_game)

func _on_lines_cleared(count: int) -> void:
    match count:
        1: trigger_flash(0.1);  trigger_shake(0.1, 2.0)
        2: trigger_flash(0.15); trigger_shake(0.15, 2.0)
        3: trigger_flash(0.2);  trigger_shake(0.2, 4.0)
        4: trigger_flash(0.3);  trigger_shake(0.3, 8.0)
```

**Pause behavior:** Same as lock delay — `_process()` auto-pauses with `get_tree().paused = true`. All effect timers freeze and resume. No explicit pause wiring needed.

**Why `ColorRect` overlays (not `CanvasModulate`)?**
`CanvasModulate` applies a uniform color to the entire viewport and is designed for ambient lighting (day/night). A `ColorRect` overlay with animated `modulate.a` is the standard Godot approach for flash and glow overlays — it's additive (overlays existing colors), full-viewport, and supports per-effect control.

**Why `game_canvas` shake (not individual node shake)?**
Shaking individual nodes (e.g., camera + pieces separately) creates visual inconsistency — elements drift apart. Shaking the entire `game_canvas` as a unit keeps the relative positions of all gameplay elements intact while producing the screen-shake feeling.

## Architecture Diagram

```
visual_feedback.gd
  ├── flash_overlay (ColorRect)          ← white, fades over 100-300ms
  ├── combo_glow_overlay (ColorRect)     ← gold, fades over 500ms
  ├── dim_overlay (ColorRect)            ← 50% dim, instant, persistent
  │
  ├── game_canvas (Node2D) reference     ← receives shake position offset
  │
  ├── _ready():
  │     connects to: line_clear.lines_cleared, tetromino.piece_locked,
  │                  speed_progression.level_up, combo_scoring.combo_x5,
  │                  game_state.game_over, game_state.new_game
  │
  └── _process(delta):
        updates: flash opacity, shake offset, glow opacity
        each effect tracks its own elapsed time independently

Signal flow:
  lines_cleared(count) → _on_lines_cleared → trigger_flash() + trigger_shake()
  combo_x5            → _on_combo_x5       → trigger_combo_glow()
  game_over           → _on_game_over      → dim_overlay.visible = true
  new_game            → _on_new_game       → dim_overlay.visible = false
```

## Key Interfaces

```gdscript
# visual_feedback.gd — public signal connections (all driven by upstream signals)
class_name VisualFeedback
extends Node

@export var line_clear: Node
@export var tetromino: Node
@export var speed_progression: Node
@export var combo_scoring: Node
@export var game_state: Node

func _ready() -> void:
    line_clear.lines_cleared.connect(_on_lines_cleared)
    # ... all signal connections

# Tuning knobs (const, changeable per GDD tuning section)
const FLASH_INITIAL_OPACITY := 0.3
const SHAKE_MAGNITUDE_TETRIS := 8.0
const SHAKE_DURATION_TETRIS := 0.3
const COMBO_GLOW_DURATION := 0.5
```

## Alternatives Considered

### Alternative 1: One `Timer` per effect with `process_mode = PROCESS_MODE_ALWAYS`

- **Description**: Each effect has a `Timer` child node. Timers auto-pause with tree.
- **Pros**: Inspector-visible, Godot-managed duration
- **Cons**: 5+ Timer nodes in `visual_feedback.gd` for what is just `_process(delta)` accumulation. More complex scene structure for no benefit.
- **Rejection Reason**: `_process()` delta accumulation achieves the same result with zero extra nodes and simpler code.

### Alternative 2: `CanvasModulate` for flash

- **Description**: Use `CanvasModulate` node to apply full-screen flash color.
- **Cons**: `CanvasModulate` is designed for ambient lighting shifts (day/night), not momentary flash overlays. It multiplies colors rather than adding white. For a 30% white flash, the result would be tinted而非 brightened — wrong visual effect.
- **Rejection Reason**: `CanvasModulate` produces a tinting effect, not a flash. `ColorRect` overlay with modulated alpha is the correct approach.

### Alternative 3: Individual node shake (shake each piece/node separately)

- **Description**: Each gameplay node applies its own random shake offset.
- **Cons**: Nodes shake independently — grid lines appear to flex, pieces appear to flex individually. Visually jarring in the wrong way. Relative positions drift.
- **Rejection Reason**: Shaking `game_canvas` as a unit preserves internal geometry while producing the correct "camera shake" feel.

## Consequences

### Positive

- All 5 effect types covered: flash, shake, combo glow, level-up flash, game over dim
- Multiple effects coexist — additive rendering with no cancellation logic needed
- `_process()` auto-pause means effects pause/resume with the game without explicit wiring
- `game_canvas` shake preserves internal geometry of the game scene
- Signal-driven: `visual_feedback.gd` never queries game state — it reacts to signals
- No `Timer` nodes — clean node structure

### Negative

- If a new signal-triggered effect is added, it must be manually connected in `_ready()` (same as all other signals — not novel boilerplate)

### Neutral

- The `ColorRect` overlays (flash, combo glow, dim) render above gameplay as siblings in the scene tree — correct layering depends on their order in the tree. `visual_feedback.gd` should be ordered after `game_canvas` to render above it.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Flash brightness different in Godot 4.6 (glow before tonemapping) | Medium | Flash appears too bright or wrong color | Verify with playtest; may need opacity tuning |
| Shake offset causes pieces to leave viewport | Low | Visual clipping on edges | Shake magnitude is small (≤8px); grid has margin |
| Combo glow fires at wrong time | Low | GUT test verifies `combo_x5` signal fires at correct threshold |

## Performance Implications

- **CPU**: Negligible — a few float comparisons and one `randf_range()` call per frame per active effect
- **Memory**: 5 `ColorRect` nodes (~5KB total), a few float state variables
- **Load Time**: Negligible
- **Network**: None

## Migration Plan

- Greenfield — no existing visual effect code
- `visual_feedback.gd` created as child of `main.tscn`
- `ColorRect` overlay nodes created as children of `visual_feedback.gd`
- All signal connections established in `_ready()`
- `game_canvas` reference acquired via `$"../../game_canvas"` path (one-time path coupling, acceptable for this one reference)

## Validation Criteria

- GIVEN `lines_cleared(4)` signal, WHEN received, THEN white flash at 30% opacity plays for 300ms AND screen shakes at 8px magnitude for 300ms, both starting simultaneously
- GIVEN `game_over` signal, WHEN received, THEN `dim_overlay` becomes visible at 50% opacity
- GIVEN `game_over` dim is active, WHEN `new_game` signal is received, THEN `dim_overlay` becomes invisible
- GIVEN a Tetris (4 lines) and combo ×5 fire simultaneously, WHEN both are received, THEN all 3 effects (flash, shake, combo glow) play simultaneously
- GIVEN a flash is playing at 50% opacity, WHEN game pauses, THEN flash freezes and resumes on unpause
- GUT test: emit `lines_cleared(1)` signal and assert `flash_overlay.modulate.a > 0` within the same frame

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| visual-feedback-system.md | Visual Feedback | Flash on line clear: 30% white, 100-300ms | `flash_overlay` ColorRect with `_process()` opacity decay |
| visual-feedback-system.md | Visual Feedback | Screen shake: 2-8px magnitude, linear decay | `game_canvas` position offset in `_process()` with `randf_range` |
| visual-feedback-system.md | Visual Feedback | Combo ×5 glow: gold, 500ms | `combo_glow_overlay` ColorRect with fade-out in `_process()` |
| visual-feedback-system.md | Visual Feedback | Game over dim: 50% brightness | `dim_overlay` ColorRect, instant set, persistent |
| visual-feedback-system.md | Visual Feedback | Effects pause with game | `_process()` auto-pauses with game (same mechanism as lock delay) |
| visual-feedback-system.md | Visual Feedback | Effects coexist (no cancellation) | Each effect has independent state; no exclusive-lock logic |

## Related

- ADR-ARCH-002 (Signal Bus) — all effects are driven by native Godot signals
- ADR-ARCH-003 (Scene Tree) — `visual_feedback.gd` is a child of `main.tscn`; `game_canvas` is its sibling for shake reference
- ADR-ARCH-005 (Lock Delay) — shares the same `_process()` delta-accumulation pattern for timing