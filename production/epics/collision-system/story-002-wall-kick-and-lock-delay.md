# Story 002: Wall Kick and Lock Delay

> **Epic**: collision-system
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/collision-system.md`
**Requirement**: `TR-collision-003` (Wall kick offsets), `TR-collision-004` (Lock delay: 500ms, resets on valid move, hard drop locks immediately)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**:
- ADR-001 (Grid Resource Pattern): Grid injected into CollisionSystem for offset position checks
- ADR-002 (Signal Bus): `lock_delay_expired` signal emitted via signal bus when piece should lock
- ADR-003 (Scene Tree): CollisionSystem node wired to TetrominoSystem for move validation

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Uses `_process(delta)` for lock delay timing per GDD specification.

**Control Manifest Rules (Core layer)**:
- Required: Wall kick offset list, lock delay timer with 500ms threshold
- Forbidden: No grid mutation in offset checks; lock delay pauses with game
- Guardrail: Lock delay resets on any successful `can_move_to` call

---

## Acceptance Criteria

*From GDD collision-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN wall kick is enabled, WHEN rotation is blocked at x=0, THEN system tests offset positions (-1, 0), (1, 0), (0, -1), (-2, 0), (2, 0).
- [ ] **AC-2**: GIVEN a piece has locked (can_move_to returns false for down), WHEN lock delay of 500ms elapses with no successful move, THEN piece locks and cells are written to grid.
- [ ] **AC-3**: GIVEN a piece is in lock delay, WHEN a successful move is made (can_move_to returns true), THEN lock delay resets to 0.
- [ ] **AC-4**: GIVEN a hard drop is performed, WHEN hard drop completes, THEN piece locks immediately with no lock delay.

---

## Implementation Notes

*From GDD collision-system.md Detailed Design and Formulas:*

**Wall Kick Offsets:**
```
offsets = [(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]
for each (dx, dy) in offsets:
  if can_move_to(tx + dx, ty + dy, shape): return true
return false
```

**Lock Delay Behavior:**
- Timer starts when `can_move_to(current_x, current_y - 1, shape)` first returns false (piece cannot move down)
- 500ms threshold via `_process(delta)` delta accumulation
- Timer resets to 0 on any successful move (any `can_move_to` returning true)
- Hard drop bypass: `hard_drop_requested` signal sets lock timer to 0 and immediately locks piece
- Lock delay pauses when game state is PAUSED (timer does not accumulate)

**Grid API used:**
- `grid.is_valid_position(x, y)`
- `grid.is_empty(x, y)`

- Place in `src/collision/collision_system.gd`
- `get_wall_kick_offsets() -> Array` returns the 6 offset pairs
- `test_wall_kick_offsets(x, y, shape) -> bool` iterates offsets and calls `can_move_to` for each
- Lock delay state: `_lock_delay_timer: float = 0.0`, `_lock_timer_active: bool = false`
- `_process(delta)` accumulates `_lock_delay_timer` when `_lock_timer_active` and game is PLAYING

---

## Out of Scope

*Handled by neighbouring stories:*
- Story 001: Core `can_move_to` collision detection (wall/floor/stack types)
- Tetromino System: Rotation implementation applies wall kick offsets

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: Wall kick offsets tested in order
- Given: A wall kick is triggered (basic collision check failed) with offsets [(0,0), (-1,0), (1,0), (0,-1), (-2,0), (2,0)]
- When: `collision.test_wall_kick_offsets(tx, ty, shape)` is called
- Then: Each offset is tested in order; first passing offset returns true; if all fail, returns false
- Edge cases: First offset (0,0) always tested even when basic check failed — ensures position is truly invalid

**AC-2**: Lock delay expires at 500ms
- Given: A piece is in lock delay state (`_lock_timer_active = true`, `_lock_delay_timer = 0`)
- When: 500ms of real time elapses with game in PLAYING state
- Then: `lock_delay_expired` signal is emitted via signal bus
- Edge cases: Test at exactly 499ms (no emission), exactly 500ms (emission fires), 501ms (emission fires once)

**AC-3**: Lock delay resets on successful move
- Given: A piece is in lock delay state (`_lock_delay_timer = 400ms`)
- When: `can_move_to` is called and returns true (valid move possible)
- Then: `_lock_delay_timer` is reset to 0 and `_lock_timer_active` becomes false
- Edge cases: Move that is not a translation but still returns true (e.g., rotation with wall kick) also resets

**AC-4**: Hard drop bypasses lock delay
- Given: A piece is in lock delay state (`_lock_delay_timer = 300ms`)
- When: `hard_drop_requested` signal is received
- Then: Piece locks immediately — no wait for 500ms; `lock_delay_expired` is emitted instantly
- Edge cases: Hard drop while lock delay not yet active still locks immediately; lock delay timer is abandoned

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/collision/wall_kick_lock_delay_test.gd` — must exist and pass

**Status**: [ ] Not yet created