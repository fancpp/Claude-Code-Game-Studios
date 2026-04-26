# Story 002: Combo Glow — gold glow around combo display at x5, 500ms fade

> **Epic**: visual-feedback-system
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/visual-feedback-system.md`
**Requirement**: `TR-visual-003` (combo x5 glow: gold ColorRect around combo display, 500ms fade out)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-007 (Visual Effects Architecture) — `ColorRect` overlay with `_process()` fade-out.

**Engine**: Godot 4.6 | **Risk**: MEDIUM — Godot 4.6 changed glow-before-tonemapping order; gold glow brightness needs playtest verification
**Control Manifest Rules (Presentation layer)**:
- Required: `combo_glow_overlay (ColorRect)`, gold color (RGB: 255, 215, 0), fades from full opacity to 0 over 500ms
- Forbidden: Glow visible when combo < 5
- Guardrail: `combo_x5` signal (one-shot per game) — only fires when combo first reaches 5

---

## Acceptance Criteria

*From GDD visual-feedback-system.md Acceptance Criteria:*

- [ ] **AC-3**: GIVEN combo multiplier reaches x5, **WHEN** the event is received, **THEN** gold glow appears around the combo display for 500ms.
- [ ] **AC-5**: GIVEN combo glow is active and combo breaks (resets to 0), **WHEN** `combo_changed(0)` is received, **THEN** glow cancels immediately (no fade out).

---

## Implementation Notes

*From ADR-ARCH-007:*

```gdscript
# visual_feedback.gd — combo glow
const COMBO_GLOW_DURATION := 0.5  # 500ms in seconds
const GOLD_COLOR := Color(1.0, 0.84, 0.0)  # RGB 255, 215, 0

var _glow_time: float = 0.0
var _glow_duration: float = 0.0
var _is_glowing: bool = false

@onready var combo_glow_overlay: ColorRect = $combo_glow_overlay

func _ready() -> void:
    combo_scoring.combo_x5.connect(_on_combo_x5)
    combo_scoring.combo_changed.connect(_on_combo_changed)

func _on_combo_x5() -> void:
    _glow_time = 0.0
    _glow_duration = COMBO_GLOW_DURATION
    _is_glowing = true
    combo_glow_overlay.modulate = GOLD_COLOR
    combo_glow_overlay.visible = true

# Immediate cancel on combo break
func _on_combo_changed(new_combo: int, _multiplier: int) -> void:
    if new_combo == 0 and _is_glowing:
        _is_glowing = false
        combo_glow_overlay.visible = false

func _process(delta: float) -> void:
    # ... flash/shake updates (from story 001)
    _update_combo_glow(delta)

func _update_combo_glow(delta: float) -> void:
    if not _is_glowing:
        return
    _glow_time += delta
    var progress := _glow_time / _glow_duration
    if progress >= 1.0:
        _is_glowing = false
        combo_glow_overlay.visible = false
    else:
        combo_glow_overlay.modulate.a = 1.0 - progress
```

**Combo glow overlay positioning**: The `combo_glow_overlay` ColorRect is a full-viewport overlay (same as flash_overlay) set to gold color. It shows a gold tint over the whole screen, creating the "glow around the combo display" effect.

**One-shot cancellation on combo break**: If the player breaks the combo (locks a piece with 0 lines) while the glow is active, the glow is cancelled immediately — no fade-out. Per GDD: "Glow cancels immediately — no fade out. The combo glow was for active combo only."

---

## Out of Scope

- Flash/shake (Story 001)
- Game over dim (Story 003)

---

## QA Test Cases

**AC-3**: Combo x5 triggers gold glow
- Given: Combo reaches 5 for first time this game
- When: `combo_x5` signal is received
- Then: `combo_glow_overlay` becomes visible with gold color at full opacity
- And: Over 500ms, opacity decays from 1.0 to 0.0 linearly
- And: After 500ms, `combo_glow_overlay.visible == false`
- Edge cases: Second x5 in same game (combo_x5 doesn't fire again), combo drops to 4 and returns to 5 (combo_x5 does NOT refire)

**AC-5**: Combo break cancels glow immediately
- Given: Combo x5 glow is active (e.g., at 50% opacity, 250ms elapsed)
- When: `combo_changed(0, 1)` is received (combo resets)
- Then: `_is_glowing = false` and `combo_glow_overlay.visible = false` immediately
- No fade-out; immediate cancellation

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: Screenshot + lead sign-off at `production/qa/evidence/visual-feedback-combo-glow-*.png`

**Status**: [ ] Not yet created

**Dependencies**: combo-scoring-system stories (001-003)