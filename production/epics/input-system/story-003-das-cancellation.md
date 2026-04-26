# Story 003: DAS Cancellation + Key Release Reset — left+right cancel, key release reset

> **Epic**: input-system
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/input-system.md`
**Requirement**: `TR-input-003` (left+right simultaneous cancels both), `TR-input-004` (DAS pauses with game)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-012: DAS Timing
**ADR Decision Summary**: Left+right held simultaneously resets all DAS state for both actions. Key release resets all DAS state for that action. DAS auto-pauses with game via `_process()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: No post-cutoff APIs — `_unhandled_input()` and `_process()` are stable. DAS integer state is not affected by Godot's pause — it just stops incrementing when `_process()` stops.

**Control Manifest Rules (Foundation layer)**:
- Required: Left+right held simultaneously resets DAS state to 0 for both; key release resets all DAS state
- Forbidden: Using OS key repeat rate instead of fixed 170ms/50ms timing
- Guardrail: No explicit pause/unpause wiring needed for DAS

---

## Acceptance Criteria

*From GDD `design/gdd/input-system.md` Edge Cases and ADR-ARCH-012:*

- [ ] **AC-1**: GIVEN left key held for 200ms (initial fire already happened), WHEN right key is also pressed, THEN no `move_left` or `move_right` signals fire for the rest of the frame.
- [ ] **AC-2**: GIVEN left+right both held, WHEN `_process()` runs for multiple frames, THEN no `move_left` or `move_right` signals fire while both are held.
- [ ] **AC-3**: GIVEN left+right both held for some time, WHEN left is released while right stays held, THEN DAS for left remains cancelled; DAS for right continues accumulating from where it was.
- [ ] **AC-4**: GIVEN left key held for 200ms then released, WHEN left key is pressed again, THEN DAS for left starts fresh from 0ms (initial fire not yet happened).
- [ ] **AC-5**: GIVEN soft drop key held for 300ms (initial + multiple repeats fired), WHEN soft drop key is released, THEN all DAS state for soft drop resets to 0.
- [ ] **AC-6**: GIVEN any DAS action is cancelled mid-hold (left+right), WHEN the key that was held first is released, THEN the other action's DAS does NOT reset — it stays cancelled while both are held.

---

## Implementation Notes

*Derived from ADR-ARCH-012 Decision section — DAS cancellation and key release:*

```gdscript
# input_handler.gd — DAS cancellation in _process()
func _process(delta: float) -> void:
    var dt_ms := int(delta * 1000.0)

    # DAS cancellation: left + right simultaneously = no movement
    if _key_left_held and _key_right_held:
        _das_left_time_ms = 0
        _das_left_repeat_count = 0
        _das_left_initial_fired = false
        _das_right_time_ms = 0
        _das_right_repeat_count = 0
        _das_right_initial_fired = false
        return  # cancel both

    if _key_left_held:
        # ... DAS accumulation + fire logic
```

```gdscript
# input_handler.gd — Key release resets DAS state
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_released("move_left"):
        _key_left_held = false
        _das_left_time_ms = 0
        _das_left_repeat_count = 0
        _das_left_initial_fired = false

    if event.is_action_released("move_right"):
        _key_right_held = false
        _das_right_time_ms = 0
        _das_right_repeat_count = 0
        _das_right_initial_fired = false

    if event.is_action_released("soft_drop"):
        _key_soft_drop_held = false
        _das_soft_drop_time_ms = 0
        _das_soft_drop_repeat_count = 0
        _das_soft_drop_initial_fired = false
```

**Key release resets ALL DAS state** for that action — time, repeat_count, and initial_fired flag. A new press starts completely fresh from zero.

**DAS cancellation is per-frame** — checked at the top of `_process()` before any time accumulation or signal emission.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 001: Immediate-action signals (hard drop, rotate, pause)
- Story 002: DAS core mechanics (initial delay, repeat formula)

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: Left+right cancels both mid-frame
- Given: InputHandler with `_key_left_held = true`, `_das_left_time_ms = 200`, `_das_left_initial_fired = true`
- When: `_key_right_held` is set to `true` and `_process(0.016)` is called (one frame at ~60fps)
- Then: `move_left` does NOT fire on this frame
- And: `_das_left_time_ms`, `_das_left_repeat_count`, `_das_left_initial_fired` are all reset to 0
- And: `_das_right_time_ms`, `_das_right_repeat_count`, `_das_right_initial_fired` are all reset to 0

**AC-2**: No signals fire while both held across multiple frames
- Given: InputHandler with `_key_left_held = true` and `_key_right_held = true`
- When: `_process(0.016)` called for 10 consecutive frames (160ms total)
- Then: Neither `move_left` nor `move_right` fires in any of those frames

**AC-3**: After left+right cancel, releasing left lets right continue
- Given: InputHandler with `_key_left_held = true` and `_key_right_held = true` (cancelling state), then `_key_left_held = false`
- When: `_process(0.016)` is called
- Then: `move_right` does NOT fire immediately (right's DAS was cancelled, time reset to 0)
- And: `_process(0.170)` subsequent call
- Then: `move_right` fires (right resumes from fresh 0ms, initial fire happens at 170ms)

**AC-4**: Key release followed by re-press starts DAS fresh
- Given: InputHandler with `_key_left_held = true`, `_das_left_time_ms = 250`, `_das_left_initial_fired = true`, `_das_left_repeat_count = 2`
- When: `_key_left_held` is set to `false` (key released)
- Then: All DAS state for left resets: time=0, repeat_count=0, initial_fired=false
- And when: `_key_left_held` set to `true` again (re-pressed), `_process(0.170)` called
- Then: `move_left` fires exactly once (new initial fire from 0ms)

**AC-5**: Soft drop key release resets soft drop DAS
- Given: InputHandler with `_key_soft_drop_held = true`, `_das_soft_drop_time_ms = 300`
- When: `_key_soft_drop_held` set to `false`
- Then: `_das_soft_drop_time_ms = 0`, `_das_soft_drop_repeat_count = 0`, `_das_soft_drop_initial_fired = false`

**AC-6**: Right stays cancelled after left is released while both held
- Given: InputHandler with `_key_left_held = true` and `_key_right_held = true` (cancelled state)
- When: `_key_left_held` set to `false` (right still held), `_process(0.170)` called
- Then: `move_right` does NOT fire (right's DAS was cancelled and not re-triggered by releasing left alone)
- Note: This tests that cancellation is only cleared when the remaining held key is processed in a subsequent frame, not by release of the other key

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/das_cancellation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (DAS state variables must exist to be cancelled/reset)
- Unlocks: None — this is the final Input System story