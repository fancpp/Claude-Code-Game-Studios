# Story 001: Flash + Shake Effects — white flash and screen shake on line clear

> **Epic**: visual-feedback-system
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/visual-feedback-system.md`
**Requirement**: `TR-visual-001` (flash: 30% opacity, 100-300ms by clear type), `TR-visual-002` (shake: 2-8px magnitude by clear type, linear decay)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-007 (Visual Effects Architecture) — `ColorRect` overlay for flash, `Node2D` offset for shake, `_process()` delta timing.

**Engine**: Godot 4.6 | **Risk**: MEDIUM — Godot 4.6 changed glow-before-tonemapping order; flash brightness needs playtest verification
**Control Manifest Rules (Presentation layer)**:
- Required: `flash_overlay (ColorRect)`, `game_canvas` Node2D reference, `_process()` delta timing
- Forbidden: `Timer` nodes — use `_process()` delta accumulation per ADR-ARCH-007
- Guardrail: Flash opacity must reach exactly 0.0 at end of duration (no residual opacity)

---

## Acceptance Criteria

*From GDD visual-feedback-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN a Single line clear, **WHEN** `lines_cleared(1)` is received, **THEN** white flash plays for 100ms at 30% opacity.
- [ ] **AC-2**: GIVEN a Tetris (4 lines), **WHEN** `lines_cleared(4)` is received, **THEN** white flash plays for 300ms at 30% opacity AND screen shakes with 8px magnitude for 300ms.
- [ ] **AC-8**: GIVEN a Tetris triggers while a lock pulse is playing, **WHEN** both events fire, **THEN** both effects play simultaneously without cancellation.

---

## Implementation Notes

*From ADR-ARCH-007:_process() delta pattern:*

```gdscript
# visual_feedback.gd — flash and shake
class_name VisualFeedback
extends Node

const FLASH_INITIAL_OPACITY := 0.3
const SHAKE_MAGNITUDE_SINGLE := 2.0
const SHAKE_MAGNITUDE_DOUBLE := 2.0
const SHAKE_MAGNITUDE_TRIPLE := 4.0
const SHAKE_MAGNITUDE_TETRIS := 8.0
const FLASH_DURATION_SINGLE := 0.1
const FLASH_DURATION_DOUBLE := 0.15
const FLASH_DURATION_TRIPLE := 0.2
const FLASH_DURATION_TETRIS := 0.3
const SHAKE_DURATION_TETRIS := 0.3

var _flash_time: float = 0.0
var _flash_duration: float = 0.0
var _is_flashing: bool = false

var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_magnitude: float = 0.0
var _is_shaking: bool = false

@onready var flash_overlay: ColorRect = $flash_overlay
@onready var game_canvas: Node2D = $"../../game_canvas"

func _ready() -> void:
    line_clear.lines_cleared.connect(_on_lines_cleared)

func _process(delta: float) -> void:
    _update_flash(delta)
    _update_shake(delta)

func _on_lines_cleared(count: int) -> void:
    match count:
        1: trigger_flash(FLASH_DURATION_SINGLE); trigger_shake(FLASH_DURATION_SINGLE, SHAKE_MAGNITUDE_SINGLE)
        2: trigger_flash(FLASH_DURATION_DOUBLE); trigger_shake(FLASH_DURATION_DOUBLE, SHAKE_MAGNITUDE_DOUBLE)
        3: trigger_flash(FLASH_DURATION_TRIPLE); trigger_shake(FLASH_DURATION_TRIPLE, SHAKE_MAGNITUDE_TRIPLE)
        4: trigger_flash(FLASH_DURATION_TETRIS); trigger_shake(SHAKE_DURATION_TETRIS, SHAKE_MAGNITUDE_TETRIS)

func trigger_flash(duration: float) -> void:
    _flash_time = 0.0
    _flash_duration = duration
    _is_flashing = true
    flash_overlay.modulate.a = FLASH_INITIAL_OPACITY
    flash_overlay.visible = true

func trigger_shake(duration: float, magnitude: float) -> void:
    _shake_time = 0.0
    _shake_duration = duration
    _shake_magnitude = magnitude
    _is_shaking = true

func _update_flash(delta: float) -> void:
    if not _is_flashing:
        return
    _flash_time += delta
    var progress := _flash_time / _flash_duration
    if progress >= 1.0:
        _is_flashing = false
        flash_overlay.modulate.a = 0.0
    else:
        flash_overlay.modulate.a = FLASH_INITIAL_OPACITY * (1.0 - progress)

func _update_shake(delta: float) -> void:
    if not _is_shaking:
        return
    _shake_time += delta
    var progress := _shake_time / _shake_duration
    if progress >= 1.0:
        _is_shaking = false
        game_canvas.position = Vector2.ZERO
    else:
        var magnitude := _shake_magnitude * (1.0 - progress)  # linear decay
        game_canvas.position = Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
```

**Additive effects**: Each effect has its own state. `_on_lines_cleared(4)` calls both `trigger_flash()` and `trigger_shake()` — they run independently in `_process()`. No effect cancels another.

**Pause behavior**: `_process()` auto-pauses with `get_tree().paused = true`. All effect timers freeze and resume. No explicit pause wiring needed.

---

## Out of Scope

- Combo glow (Story 002)
- Game over dim (Story 003)
- Lock pulse effect (from tetromino piece_locked — deferred)

---

## QA Test Cases

**AC-1**: Single flash 100ms at 30%
- Given: Flash effect idle (no active flash)
- When: `_on_lines_cleared(1)` is called
- Then: `flash_overlay.modulate.a` starts at 0.3, decays linearly to 0.0 over 100ms
- Edge cases: Call again during active flash (additive — new flash starts from 0.3 over its own duration)

**AC-2**: Tetris flash + shake
- Given: No active effects
- When: `_on_lines_cleared(4)` is called
- Then: Flash starts at 0.3 opacity for 300ms AND shake starts at 8px magnitude for 300ms, both starting simultaneously
- Edge cases: Tetris while flash already playing from previous clear (both coexist)

**AC-8**: Effects coexist without cancellation
- Given: Lock pulse is currently animating (from tetromino piece_locked)
- When: `_on_lines_cleared(4)` is called (Tetris arrives same frame as lock pulse)
- Then: All effects (flash, shake, lock pulse) play simultaneously
- No effect is cancelled; no effect waits for another

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: Screenshot + lead sign-off at `production/qa/evidence/visual-feedback-flash-shake-*.png`

**Status**: [ ] Not yet created

**Dependencies**: line-clear-system stories (001-003)