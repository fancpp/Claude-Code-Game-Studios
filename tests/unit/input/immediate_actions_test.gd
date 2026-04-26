# Immediate Actions Unit Tests — Story 001
# Test evidence for: tests/unit/input/immediate_actions_test.gd
# Story: production/epics/input-system/story-001-immediate-actions.md
# ADR: ADR-ARCH-012 (DAS Timing) — Accepted
extends GutTest

var _handler: InputHandler

func before_each() -> void:
	_handler = InputHandler.new()

func after_each() -> void:
	_handler.free()

## AC-1: hard_drop emits immediately on Space press
func test_immediate_hard_drop_on_space_press() -> void:
	var emitted := false
	_handler.hard_drop.connect(func(): emitted = true)
	# Simulate Space press
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	_handler._unhandled_input(event)
	assert_true(emitted, "hard_drop signal should emit immediately on Space press")

## AC-2: rotate_cw emits immediately on X press
func test_immediate_rotate_cw_on_x_press() -> void:
	var emitted := false
	_handler.rotate_cw.connect(func(): emitted = true)
	var event := InputEventKey.new()
	event.keycode = KEY_X
	event.pressed = true
	_handler._unhandled_input(event)
	assert_true(emitted, "rotate_cw signal should emit immediately on X press")

## AC-3: rotate_ccw emits immediately on Z press
func test_immediate_rotate_ccw_on_z_press() -> void:
	var emitted := false
	_handler.rotate_ccw.connect(func(): emitted = true)
	var event := InputEventKey.new()
	event.keycode = KEY_Z
	event.pressed = true
	_handler._unhandled_input(event)
	assert_true(emitted, "rotate_ccw signal should emit immediately on Z press")

## AC-4/AC-5: pause emits on Escape regardless of game state
func test_pause_emits_on_escape_press() -> void:
	var emit_count := 0
	_handler.pause.connect(func(): emit_count += 1)
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	_handler._unhandled_input(event)
	assert_eq(emit_count, 1, "pause should emit once on Escape press")

func test_pause_emits_twice_on_two_escapes() -> void:
	var emit_count := 0
	_handler.pause.connect(func(): emit_count += 1)
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	_handler._unhandled_input(event)
	_handler._unhandled_input(event)  # second press
	assert_eq(emit_count, 2, "pause should emit on each Escape press (toggle behavior)")

## Edge case: OS key repeat does NOT trigger immediate actions
func test_key_repeat_does_not_emit_hard_drop() -> void:
	var emit_count := 0
	_handler.hard_drop.connect(func(): emit_count += 1)
	# is_action_pressed only fires on initial press — OS repeat does not set pressed=true
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = false  # Simulate key repeat (pressed=false)
	_handler._unhandled_input(event)
	assert_eq(emit_count, 0, "key repeat (pressed=false) should not emit hard_drop")