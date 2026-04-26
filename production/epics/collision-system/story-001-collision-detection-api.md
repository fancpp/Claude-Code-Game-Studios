# Story 001: Collision Detection API

> **Epic**: collision-system
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/collision-system.md`
**Requirement**: `TR-collision-001` (`can_move_to` query), `TR-collision-002` (3 collision types: Wall, Floor, Stack)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**:
- ADR-001 (Grid Resource Pattern): `can_move_to` receives injected Grid ref, calls `is_valid_position` and `is_empty`
- ADR-002 (Signal Bus): Lock condition emitted via signal bus when piece cannot move down
- ADR-003 (Scene Tree): CollisionSystem node child of main scene tree

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript query functions. No post-cutoff APIs used.

**Control Manifest Rules (Core layer)**:
- Required: `can_move_to(x, y, tetromino_shape) -> bool`, 3 collision type checks
- Forbidden: No grid mutation in collision queries
- Guardrail: No engine state modified — pure read-only operation

---

## Acceptance Criteria

*From GDD collision-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN a tetromino at position (5, 10), WHEN `can_move_to(5, 9, shape)` is called with all cells empty below, THEN it returns true.
- [ ] **AC-2**: GIVEN a tetromino at position (0, 10), WHEN `can_move_to(-1, 10, shape)` is called, THEN it returns false (wall collision).
- [ ] **AC-3**: GIVEN a tetromino at position (5, 0), WHEN `can_move_to(5, -1, shape)` is called, THEN it returns false (floor collision).
- [ ] **AC-4**: GIVEN a tetromino with a shape containing only empty cells, WHEN `can_move_to(5, 10, shape)` is called, THEN it returns false.
- [ ] **AC-5**: GIVEN a tetromino at position (5, 10), WHEN `can_move_to` is called with a target position occupied by a locked piece, THEN it returns false (stack collision).

---

## Implementation Notes

*From GDD collision-system.md Detailed Design:*

```
can_move_to(tx, ty, shape) = AND(
  for all (cx, cy) in shape:
    is_valid_position(tx + cx, ty + cy) AND is_empty(tx + cx, ty + cy)
)
```

**Collision types:**
| Type | Condition | Behavior |
|------|-----------|----------|
| Wall collision | x < 0 or x >= GRID_WIDTH (10) | Return false |
| Floor collision | y < 0 | Return false |
| Stack collision | Grid cell is occupied (non-zero) | Return false |
| Valid move | All cells empty and in bounds | Return true |

**Grid API used:**
- `grid.is_valid_position(x, y)` — returns false for out-of-bounds
- `grid.is_empty(x, y)` — returns false for occupied cells

- Place `CollisionSystem` class in `src/collision/collision_system.gd`
- `can_move_to` is a pure function — no side effects, no state modification
- When `can_move_to(px, py - 1, shape)` returns false AND the piece is in PLAYING state, emit `piece_locked` signal via signal bus

---

## Out of Scope

*Handled by neighbouring stories:*
- Story 002: Wall kick offsets for rotation; lock delay timing

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: Valid downward move returns true
- Given: A Grid with all cells empty, a tetromino shape at (5, 10)
- When: `collision.can_move_to(5, 9, shape)` is called
- Then: Return value equals true
- Edge cases: Also test `can_move_to(5, 11, shape)` with all cells empty — should also be true

**AC-2**: Left wall collision returns false
- Given: A Grid with all cells empty, a tetromino shape at (0, 10)
- When: `collision.can_move_to(-1, 10, shape)` is called
- Then: Return value equals false
- Edge cases: Also test right wall at x=9, `can_move_to(10, 10, shape)` should return false

**AC-3**: Floor collision returns false
- Given: A Grid with all cells empty, a tetromino shape at (5, 0)
- When: `collision.can_move_to(5, -1, shape)` is called
- Then: Return value equals false
- Edge cases: Also test `can_move_to(5, -2, shape)` — should also return false

**AC-4**: Empty shape returns false
- Given: A Grid with all cells empty, a tetromino shape with all cells set to empty (e.g., [[]])
- When: `collision.can_move_to(5, 10, empty_shape)` is called
- Then: Return value equals false
- Edge cases: Shape with mixed empty and occupied cells — only non-empty cells are checked

**AC-5**: Stack collision returns false
- Given: A Grid with cell (5, 8) occupied by a locked tetromino piece
- When: `collision.can_move_to(5, 9, shape)` is called with shape covering cell (5, 8)
- Then: Return value equals false
- Edge cases: Partial overlap — if any cell of shape overlaps an occupied cell, entire move is rejected

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/collision/collision_detection_api_test.gd` — must exist and pass

**Status**: [ ] Not yet created