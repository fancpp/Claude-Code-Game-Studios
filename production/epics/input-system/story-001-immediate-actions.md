# Story 001: Immediate-Action Signals — hard drop, rotate CW/CCW, pause

> **Epic**: input-system
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/input-system.md`
**Requirement**: `TR-input-001`, `TR-input-002` (hard drop, rotate CW/CCW, pause — no DAS)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-012: DAS Timing
**ADR Decision Summary**: DAS state tracked per action in `_process()`, 170ms initial / 50ms repeat. Hard Drop, Rotate CW/CCW, and Pause emit immediately with no hold behavior — no DAS applies to them.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript `_unhandled_input()` — stable Godot API from 2.x through 4.6. No post-cutoff APIs.

**Control Manifest Rules (Foundation layer)**:
- Required: Hard Drop, Rotate CW, Rotate CCW, Pause emit immediately on key press with no DAS
- Forbidden: No Autoload, no `get_node()` for grid access (input system doesn't use grid but follows layer rules)
- Guardrail: DAS applies to Move Left/Right/Soft Drop only

---

## Acceptance Criteria

*From GDD `design/gdd/input-system.md` Acceptance Criteria, scoped to non-DAS actions:*

- [ ] **AC-1**: GIVEN the game is running, WHEN Space is pressed, THEN `hard_drop` signal is emitted immediately (no DAS delay).
- [ ] **AC-2**: GIVEN the game is running, WHEN X is pressed, THEN `rotate_cw` signal is emitted immediately.
- [ ] **AC-3**: GIVEN the game is running, WHEN Z is pressed, THEN `rotate_ccw` signal is emitted immediately.
- [ ] **AC-4**: GIVEN the game is not paused, WHEN Escape is pressed, THEN `pause` signal is emitted.
- [ ] **AC-5**: GIVEN the game is paused, WHEN Escape is pressed, THEN `pause` signal is emitted (toggles).

---

## Implementation Notes

*Derived from ADR-ARCH-012 Decision section — non-DAS actions:*

```gdscript
# input_handler.gd — non-DAS actions only
class_name InputHandler
extends Node

signal move_left
signal move_right
signal soft_drop
signal hard_drop
signal rotate_cw
signal rotate_ccw
signal pause

func _unhandled_input(event: InputEvent) -> void:
    # Non-DAS actions: immediate, no hold
    if event.is_action_pressed("hard_drop"):
        emit_signal("hard_drop")
    if event.is_action_pressed("rotate_cw"):
        emit_signal("rotate_cw")
    if event.is_action_pressed("rotate_ccw"):
        emit_signal("rotate_ccw")
    if event.is_action_pressed("pause"):
        emit_signal("pause")
```

- Hard Drop, Rotate CW, Rotate CCW, Pause all emit immediately in `_unhandled_input()`
- No DAS state tracked for these actions
- No `_key_*_held` flags needed for these actions
- Key mappings (hard drop=Space, rotate CW=X, rotate CCW=Z, pause=Escape) must be configured in `project.godot` Input Map

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 002: DAS applies to Move Left/Right/Soft Drop — `_key_left_held`, `_das_left_time_ms`, initial delay logic
- Story 003: DAS cancellation (left+right simultaneously), key release resets DAS state

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: hard_drop emits immediately on Space press
- Given: InputHandler with project.godot configured (hard_drop action mapped to Space)
- When: `Input.parse_input_event()` fires a Space key press event through `_unhandled_input()`
- Then: `hard_drop` signal is emitted synchronously during the same `_unhandled_input()` call
- Edge cases: Holding Space should not re-trigger — hard_drop only fires on `is_action_pressed`, not repeated

**AC-2**: rotate_cw emits immediately on X press
- Given: InputHandler
- When: `Input.parse_input_event()` fires an X key press event through `_unhandled_input()`
- Then: `rotate_cw` signal is emitted synchronously
- Edge cases: X key repeat from OS key repeat does not trigger — `is_action_pressed` only fires on initial press

**AC-3**: rotate_ccw emits immediately on Z press
- Given: InputHandler
- When: `Input.parse_input_event()` fires a Z key press event through `_unhandled_input()`
- Then: `rotate_ccw` signal is emitted synchronously
- Edge cases: Same as AC-2 — OS repeat filtered by `is_action_pressed`

**AC-4 / AC-5**: pause emits on Escape regardless of game state
- Given: InputHandler
- When: `Input.parse_input_event()` fires Escape press through `_unhandled_input()`
- Then: `pause` signal is emitted (no game-state check in input_handler — game_state system decides what to do with the signal)
- Edge cases: Pause signal always emits — input_handler does not gate it based on pause state

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/immediate_actions_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (foundation layer, no dependencies)
- Unlocks: Story 002 (DAS for Move Left/Right/Soft Drop)