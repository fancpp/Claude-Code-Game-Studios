# Story 002: Ghost Rendering — 30% opacity, outline/dotted visual style

> **Epic**: ghost-piece-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/ghost-piece-system.md`
**Requirement**: `TR-ghost-002` (ghost visual: 30% opacity, outline or dotted style, renders behind active piece)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: No dedicated ADR — rendering approach follows Godot 2D rendering conventions.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: Ghost renders at 30% opacity (GHOST_OPACITY = 0.3), outline or dotted style
- Forbidden: Ghost does not fill cells (only outline/dotted — fill would obscure the grid)
- Guardrail: Ghost renders in a layer behind the active piece (z-order or draw order)

---

## Acceptance Criteria

*From GDD ghost-piece-system.md Acceptance Criteria:*

- [ ] **AC-5**: GIVEN piece at position (5, 15), **WHEN** player moves piece to (3, 15), **THEN** ghost recalculates and moves to the correct drop position.
- [ ] **AC-6**: GIVEN piece at position (5, 15) with rotation state 0, **WHEN** player rotates the piece, **THEN** ghost recalculates with the new shape.
- [ ] **AC-7**: GIVEN game is paused, **WHEN** the game resumes, **THEN** ghost appears at the same position as before the pause.
- [ ] **AC-8**: GIVEN game is in GAME_OVER state, **WHEN** rendering occurs, **THEN** no ghost is rendered.

---

## Implementation Notes

*Rendering approach (Godot 2D)*:

The ghost rendering is handled in the visual layer, NOT in `ghost_piece.gd`. `ghost_piece.gd` provides `ghost_position` data (via a signal or property) that the rendering system reads. The exact rendering node (a `Node2D` with custom `_draw()`, a `Sprite2D` with modulated alpha, or `ColorRect` outlines) is determined by the visual-feedback-system implementation.

**Ghost rendering data interface**:
```gdscript
# ghost_piece.gd — data provider
class_name GhostPiece
extends Node

signal ghost_position_updated(ghost_x: int, ghost_y: int, ghost_shape: Array)

# ghost_position_updated fires whenever:
# - Piece moves (left/right)
# - Piece rotates
# - Piece drops (soft drop advances position)
# - New piece spawns
# Rendering system (visual-feedback) subscribes and redraws ghost cells
```

**Visual style implementation (GDScript `_draw()` example)**:
```gdscript
# ghost_renderer.gd (in visual-feedback layer)
func _draw() -> void:
    if ghost_x < 0 or not is_instance_valid(current_piece):
        return

    var ghost_color := Color(piece_color.r, piece_color.g, piece_color.b, 0.3)
    var cell_size := CELL_SIZE

    for cell in ghost_shape:
        var draw_pos := Vector2(
            (ghost_x + cell[0]) * cell_size,
            (ghost_y + cell[1]) * cell_size
        )
        # Outline style: draw a rect outline at 30% opacity
        var rect := Rect2(draw_pos, Vector2(cell_size, cell_size))
        draw_rect(rect, ghost_color, false, 2.0)  # false = not filled (outline)
```

**Ghost and game pause**: Ghost position is updated via signal. When game pauses, no new signals fire and the ghost stays at its last position — no special pause handling needed.

**Ghost in GAME_OVER**: `ghost_position_updated` is not emitted after `game_over` signal. The rendering system hides the ghost when `game_over` is active.

---

## Out of Scope

- Ghost calculation algorithm (Story 001) — rendering uses the `ghost_position_updated` signal
- Specific rendering node choice (handled by visual-feedback-system)

---

## QA Test Cases

**AC-5**: Ghost recalculates on piece move
- Given: Piece moves from x=5 to x=3
- When: `ghost_position_updated(3, ghost_y, shape)` signal fires
- Then: Ghost renders at new x position corresponding to x=3
- Edge cases: Move blocked by wall (no new signal), move to valid position with different ghost outcome

**AC-6**: Ghost recalculates on rotation
- Given: Piece rotates from rotation state 0 to 1
- When: `ghost_position_updated(piece_x, new_ghost_y, new_shape)` fires
- Then: Ghost renders at new position using new_shape cells
- Edge cases: Rotation blocked by wall (no signal), rotation changes drop destination

**AC-7**: Ghost static during pause
- Given: Ghost at position (5, 6) before pause
- When: Game pauses, then resumes
- Then: Ghost is still at (5, 6) after resume — no new calculation needed since position was preserved

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: Screenshot + lead sign-off at `production/qa/evidence/ghost-piece-visual-*.png`
Or: Interaction test documenting ghost opacity and style

**Status**: [ ] Not yet created

**Dependencies**: ghost-piece-system story-001, visual-feedback-system stories