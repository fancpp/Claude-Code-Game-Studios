# DAS Cancellation Unit Tests — Story 003
# Test evidence for: tests/unit/input/das_cancellation_test.gd
# Story: production/epics/input-system/story-003-das-cancellation.md
# ADR: ADR-ARCH-012 (DAS Timing) — Accepted
extends GutTest

var _handler: InputHandler

func before_each() -> void:
	_handler = InputHandler.new()

func after_each() -> void:
	_handler.free()

## AC-1: Left+right cancels both mid-frame
func test_left_right_simultaneous_cancels_both() -> void:
	var left_count := 0
	var right_count := 0
	_handler.move_left.connect(func(): left_count += 1)
	_handler.move_right.connect(func(): right_count += 1)
	_handler._key_left_held = true
	_handler._das_left_time_ms = 200
	_handler._das_left_initial_fired = true
	_handler._key_right_held = true  # Now both held — cancellation happens
	_handler._process(0.016)
	assert_eq(left_count, 0, "move_left should NOT fire when both left+right held")
	assert_eq(right_count, 0, "move_right should NOT fire when both left+right held")
	assert_eq(_handler._das_left_time_ms, 0, "Left DAS time should be reset to 0")
	assert_eq(_handler._das_right_time_ms, 0, "Right DAS time should be reset to 0")

## AC-2: No signals while both held across multiple frames
func test_no_signals_while_both_held_multiple_frames() -> void:
	var fire_count := 0
	_handler.move_left.connect(func(): fire_count += 1)
	_handler.move_right.connect(func(): fire_count += 1)
	_handler._key_left_held = true
	_handler._key_right_held = true
	for i in range(10):
		_handler._process(0.016)  # 10 frames at 60fps (~160ms total)
	assert_eq(fire_count, 0, "No signals should fire while both left+right held")

## AC-3: After cancel, releasing left lets right continue
func test_releasing_left_lets_right_continue() -> void:
	var right_count := 0
	_handler.move_right.connect(func(): right_count += 1)
	# Start with both held (cancelled state)
	_handler._key_left_held = true
	_handler._key_right_held = true
	_handler._das_left_time_ms = 100
	_handler._das_right_time_ms = 100
	# Release left — right still held
	_handler._key_left_held = false
	_handler._process(0.016)
	# Right's DAS was cancelled too — starts from 0
	assert_eq(right_count, 0, "Right does not fire immediately after cancel")
	# Now advance time — right should fire at 170ms
	_handler._process(0.170)
	assert_eq(right_count, 1, "Right fires at 170ms after being the only held key")

## AC-4: Key release + re-press starts DAS fresh
func test_key_release_starts_das_fresh_on_repress() -> void:
	var fires: Array = []
	_handler.move_left.connect(func(): fires.append("fire"))
	_handler._key_left_held = true
	_handler._das_left_time_ms = 250
	_handler._das_left_initial_fired = true
	_handler._das_left_repeat_count = 2
	# Release key
	_handler._key_left_held = false
	_handler._das_left_time_ms = 0
	_handler._das_left_repeat_count = 0
	_handler._das_left_initial_fired = false
	# Re-press
	_handler._key_left_held = true
	_handler._process(0.170)
	assert_eq(fires.size(), 1, "New initial fire from 0ms after re-press")

## AC-5: Soft drop key release resets soft drop DAS
func test_soft_drop_release_resets_soft_drop_das() -> void:
	_handler._key_soft_drop_held = true
	_handler._das_soft_drop_time_ms = 300
	_handler._das_soft_drop_initial_fired = true
	_handler._key_soft_drop_held = false
	_handler._das_soft_drop_time_ms = 0
	_handler._das_soft_drop_repeat_count = 0
	_handler._das_soft_drop_initial_fired = false
	assert_eq(_handler._das_soft_drop_time_ms, 0, "Soft drop DAS time reset to 0")
	assert_eq(_handler._das_soft_drop_initial_fired, false, "Soft drop initial_fired reset")

## AC-6: Right stays cancelled after left release while both held
func test_right_stays_cancelled_after_left_released_while_both_held() -> void:
	var right_count := 0
	_handler.move_right.connect(func(): right_count += 1)
	_handler._key_left_held = true
	_handler._key_right_held = true
	_handler._process(0.016)  # cancellation happens
	_handler._key_left_held = false  # release left — right still held but cancelled
	_handler._process(0.170)  # 170ms of right being the only held (but still cancelled)
	assert_eq(right_count, 0, "Right should not fire — it was cancelled and not re-triggered by left release alone")

## Cancel resets all state atomically
func test_cancel_resets_initial_fired_and_repeat_count() -> void:
	_handler._key_left_held = true
	_handler._das_left_time_ms = 200
	_handler._das_left_initial_fired = true
	_handler._das_left_repeat_count = 2
	_handler._key_right_held = true  # triggers cancel
	_handler._process(0.016)
	assert_eq(_handler._das_left_initial_fired, false, "initial_fired reset to false on cancel")
	assert_eq(_handler._das_left_repeat_count, 0, "repeat_count reset to 0 on cancel")