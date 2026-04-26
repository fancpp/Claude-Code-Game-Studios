# Story 003: Game Over Dim — 50% dim overlay, instant, persists until new game

> **Epic**: visual-feedback-system
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/visual-feedback-system.md`
**Requirement**: `TR-visual-004` (game over: screen dims to 50% overlay, instant application)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-007 (Visual Effects Architecture) — `ColorRect` dim overlay with instant opacity set, persistent.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Presentation layer)**:
- Required: `dim_overlay (ColorRect)` at 50% opacity (modulate.a = 0.5), instant set
- Forbidden: No animation on game over dim (immediate)
- Guardrail: Dim persists until `new_game` signal clears it

---

## Acceptance Criteria

*From GDD visual-feedback-system.md Acceptance Criteria:*

- [ ] **AC-4**: GIVEN game over signal, **WHEN** received, **THEN** screen dims to 50% brightness.
- [ ] **AC-6**: GIVEN screen dim is active (game over state), **WHEN** `new_game` signal is received, **THEN** dim overlay becomes invisible.

---

## Implementation Notes

*From ADR-ARCH-007:*

```gdscript
# visual_feedback.gd — game over dim
@onready var dim_overlay: ColorRect = $dim_overlay

func _ready() -> void:
    game_state.game_over.connect(_on_game_over)
    game_state.new_game.connect(_on_new_game)

func _on_game_over() -> void:
    dim_overlay.visible = true
    dim_overlay.modulate.a = 0.5  # 50% dim — instant, no animation

func _on_new_game() -> void:
    dim_overlay.visible = false
    dim_overlay.modulate.a = 0.0
```

**Instant application**: Unlike flash/shake/glow which are time-animated, the game over dim is instant. `modulate.a = 0.5` is set directly with no `_process()` animation.

**Persistent**: The dim stays active (visible, 50%) until `new_game` signal clears it. No timer, no auto-clear.

**Effect coexistence**: The dim overlay is a sibling `ColorRect` in the same `visual_feedback.gd` node. If other effects (e.g., flash from a late Tetris) are active when game over fires, the dim overlay becomes visible on top — dim does not cancel other effects.

---

## Out of Scope

- Flash/shake (Story 001)
- Combo glow (Story 002)

---

## QA Test Cases

**AC-4**: Game over dims instantly to 50%
- Given: Game over state reached, dim overlay hidden
- When: `game_over` signal is received
- Then: `dim_overlay.visible == true` and `dim_overlay.modulate.a == 0.5` immediately (no animation)
- Edge cases: Game over while flash is playing (both visible simultaneously)

**AC-6**: New game clears dim
- Given: Game over dim is visible (50%)
- When: `new_game` signal is received
- Then: `dim_overlay.visible == false` and `dim_overlay.modulate.a == 0.0`
- Dim does not fade out — immediately hidden

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: Screenshot + lead sign-off at `production/qa/evidence/visual-feedback-game-over-dim-*.png`

**Status**: [ ] Not yet created

**Dependencies**: game-state-system stories (001-003)