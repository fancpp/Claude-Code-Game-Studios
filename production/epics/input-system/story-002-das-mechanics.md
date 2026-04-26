# Story 002: DAS Core Mechanics — initial delay 170ms, repeat rate 50ms, per-action state

> **Epic**: input-system
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/input-system.md`
**Requirement**: `TR-input-001` (DAS 170ms initial / 50ms repeat), `TR-input-002` (DAS applies to Move Left/Right/Soft Drop)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-012: DAS Timing
**ADR Decision Summary**: DAS state tracked per action in `_process()`, 170ms initial / 50ms repeat. Left+right cancel both. DAS auto-pauses with game via `_process()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `_process()` delta accumulation and `Input.is_action_pressed()` are stable from Godot 2.x through 4.6. No post-cutoff APIs.

**Control Manifest Rules (Foundation layer)**:
- Required: DAS state per action, 170ms initial delay, 50ms repeat rate
- Forbidden: Godot `Timer` nodes — use `_process()` delta accumulation
- Guardrail: 9 integers (~36 bytes) for DAS state — negligible memory

---

## Acceptance Criteria

*From GDD `design/gdd/input-system.md` and ADR-ARCH-012:*

- [ ] **AC-1**: GIVEN key is held for exactly 170ms, WHEN `_process()` accumulates time past 170ms, THEN `move_left` signal fires exactly once (initial fire).
- [ ] **AC-2**: GIVEN key is held for 220ms total, WHEN `_process()` fires at 170ms and again at 220ms, THEN `move_left` fires twice (initial fire + first repeat at 220ms).
- [ ] **AC-3**: GIVEN key is held for 320ms total, WHEN `_process()` fires at 170ms (initial), 220ms (repeat 1), and 320ms (repeat 2), THEN `move_left` fires three times.
- [ ] **AC-4**: GIVEN key is held but released before 170ms, WHEN `_process()` does not reach 170ms, THEN no `move_left` signal fires (DAS initial delay not reached).
- [ ] **AC-5**: GIVEN soft drop key held for 200ms, WHEN initial delay fires, THEN `soft_drop` signal fires (not `move_left`/`move_right`).
- [ ] **AC-6**: GIVEN three independent DAS actions (left, right, soft drop) held simultaneously, WHEN each accumulates 200ms, THEN each action fires independently — `move_left`, `move_right`, and `soft_drop` each fire once.
- [ ] **AC-7**: GIVEN game is paused with DAS running at 200ms elapsed, WHEN game is unpaused, THEN DAS resumes from 200ms (initial fire already happened at 170ms — next repeat fires at 250ms).

---

## Implementation Notes

*Derived from ADR-ARCH-012 Decision section — DAS per-action state and formula:*

```gdscript
# input_handler.gd — DAS state and _process logic
const DAS_INITIAL_DELAY_MS := 170
const DAS_REPEAT_RATE_MS := 50

var _key_left_held: bool = false
var _key_right_held: bool = false
var _key_soft_drop_held: bool = false

var _das_left_time_ms: int = 0
var _das_left_repeat_count: int = 0
var _das_left_initial_fired: bool = false

var _das_right_time_ms: int = 0
var _das_right_repeat_count: int = 0
var _das_right_initial_fired: bool = false

var _das_soft_drop_time_ms: int = 0
var _das_soft_drop_repeat_count: int = 0
var _das_soft_drop_initial_fired: bool = false

func _process(delta: float) -> void:
    var dt_ms := int(delta * 1000.0)

    if _key_left_held:
        _das_left_time_ms += dt_ms
        if not _das_left_initial_fired:
            if _das_left_time_ms >= DAS_INITIAL_DELAY_MS:
                emit_signal("move_left")
                _das_left_initial_fired = true
                _das_left_repeat_count = 1
        else:
            var elapsed_since_first := _das_left_time_ms - DAS_INITIAL_DELAY_MS
            var expected_repeats := elapsed_since_first / DAS_REPEAT_RATE_MS
            if _das_left_repeat_count <= expected_repeats:
                emit_signal("move_left")
                _das_left_repeat_count += 1

    # Same pattern for _key_right_held and _key_soft_drop_held...
```

**DAS Formula (per action):**
```
if not initial_fired:
    if elapsed_time_ms >= 170:
        emit signal (first fire)
        initial_fired = true
        repeat_count = 1
else:
    expected_repeats = (elapsed_time_ms - 170) / 50
    if repeat_count <= expected_repeats:
        emit signal
        repeat_count += 1
```

**Pause behavior:** `_process()` auto-pauses when `get_tree().paused = true`. DAS state (`_das_*_time_ms`) is simple integers — they stop incrementing when `_process()` stops, preserving exact elapsed time.

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 001: Immediate-action signals (hard drop, rotate, pause)
- Story 003: Left+right simultaneous cancellation, key release resets DAS state

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: Initial fire at exactly 170ms
- Given: InputHandler with `_key_left_held = true`, `_das_left_time_ms = 0`
- When: `_process(0.170)` is called (170ms of delta accumulated)
- Then: `move_left` signal fires exactly once
- Edge cases: 169ms should NOT fire; 171ms fires once (initial), not twice

**AC-2**: Initial fire + first repeat at 220ms
- Given: InputHandler after 170ms initial fire, `_das_left_time_ms = 170`
- When: `_process(0.050)` is called (total 220ms)
- Then: `move_left` fires once (first repeat)
- And when: `_process(0.050)` called again (total 270ms)
- Then: No additional fire (repeat count matches expected = 2, repeat count <= 2 is false)

**AC-3**: Three fires at 320ms (initial + 2 repeats)
- Given: InputHandler after two `_process()` calls at 170ms and 220ms
- When: `_process(0.100)` is called (total 320ms)
- Then: `move_left` fires once (second repeat)
- Edge cases: At 320ms total, expected_repeats = (320-170)/50 = 3, repeat_count=2, 2<=3 true → fires

**AC-4**: No fire before 170ms
- Given: InputHandler with `_key_left_held = true`, `_das_left_time_ms = 0`
- When: `_process(0.100)` is called (only 100ms elapsed)
- Then: `move_left` does NOT fire
- Edge cases: Multiple small deltas that sum to less than 170ms should not fire

**AC-5**: Soft drop fires soft_drop signal (not move_left/move_right)
- Given: InputHandler with `_key_soft_drop_held = true`
- When: `_process(0.170)` is called
- Then: `soft_drop` signal fires (not `move_left` or `move_right`)
- Edge cases: Each DAS action is independent — left+right+soft drop all held means all 3 fire

**AC-6**: Independent DAS state per action
- Given: InputHandler with all three `_key_*_held = true`, all DAS state at 0
- When: `_process(0.200)` is called (all 3 actions accumulate 200ms)
- Then: `move_left`, `move_right`, and `soft_drop` each fire exactly once
- Edge cases: Each action's repeat_count is independent — they don't share counters

**AC-7**: DAS resumes from correct elapsed time after unpause
- Given: InputHandler with `_key_left_held = true`, `_das_left_time_ms = 200`, `_das_left_initial_fired = true`, `_das_left_repeat_count = 1`
- When: `_process(0.050)` is called (simulating 50ms after unpause, total 250ms)
- Then: `move_left` fires once (expected_repeats = (250-170)/50 = 1, repeat_count=1, 1<=1 true)
- Edge cases: At total 249ms, expected_repeats = 1, 1<=1 true — fires at 249ms; At total 220ms after unpause (total 420ms), expected_repeats = 5, repeat_count=1 → 4 repeats fire

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/input/das_mechanics_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (signals must exist before testing DAS signal emissions)
- Unlocks: Story 003 (DAS cancellation and key release reset)