# DAS Mechanics Unit Tests — Story 002
# Test evidence for: tests/unit/input/das_mechanics_test.gd
# Story: production/epics/input-system/story-002-das-mechanics.md
# ADR: ADR-ARCH-012 (DAS Timing) — Accepted
extends GutTest

var _handler: InputHandler

func before_each() -> void:
	_handler = InputHandler.new()

func after_each() -> void:
	_handler.free()

## Simulate key press for a DAS action
func _press_key(key_var: String) -> void:
	# Use set to simulate key press via the internal flag
	_handler.set(key_var, true)

func _release_key(key_var: String) -> void:
	_handler.set(key_var, false)
	# Also trigger the release handling
	match key_var:
		"_key_left_held":
			_handler._das_left_time_ms = 0
			_handler._das_left_repeat_count = 0
			_handler._das_left_initial_fired = false
		"_key_right_held":
			_handler._das_right_time_ms = 0
			_handler._das_right_repeat_count = 0
			_handler._das_right_initial_fired = false
		"_key_soft_drop_held":
			_handler._das_soft_drop_time_ms = 0
			_handler._das_soft_drop_repeat_count = 0
			_handler._das_soft_drop_initial_fired = false

## AC-1: Initial fire at exactly 170ms
func test_das_initial_fire_at_170ms() -> void:
	var fire_count := 0
	_handler.move_left.connect(func(): fire_count += 1)
	_handler._key_left_held = true
	_handler._process(0.170)  # 170ms — exactly at threshold
	assert_eq(fire_count, 1, "move_left should fire exactly once at 170ms (initial fire)")

## AC-1b: No fire at 169ms
func test_das_no_fire_before_170ms() -> void:
	var fire_count := 0
	_handler.move_left.connect(func(): fire_count += 1)
	_handler._key_left_held = true
	_handler._process(0.169)  # 169ms — just before threshold
	assert_eq(fire_count, 0, "move_left should NOT fire before 170ms")

## AC-2: Initial + first repeat at 220ms
func test_das_initial_plus_first_repeat_at_220ms() -> void:
	var fires: Array = []
	_handler.move_left.connect(func(): fires.append("fire"))
	_handler._key_left_held = true
	_handler._process(0.170)  # initial fire
	assert_eq(fires.size(), 1, "First fire at 170ms")
	_handler._process(0.050)  # total 220ms — first repeat
	assert_eq(fires.size(), 2, "Second fire (first repeat) at 220ms")

## AC-3: Three fires at 320ms (initial + 2 repeats)
func test_das_three_fires_at_320ms() -> void:
	var fires: Array = []
	_handler.move_left.connect(func(): fires.append("fire"))
	_handler._key_left_held = true
	_handler._process(0.170)  # initial fire
	_handler._process(0.050)  # repeat 1 at 220ms
	_handler._process(0.100)  # repeat 2 at 320ms
	assert_eq(fires.size(), 3, "Should fire 3 times (initial + 2 repeats) at 320ms total")

## AC-4: No fire before 170ms (accumulated)
func test_das_no_fire_below_threshold_accumulated() -> void:
	var fire_count := 0
	_handler.move_left.connect(func(): fire_count += 1)
	_handler._key_left_held = true
	_handler._process(0.050)
	_handler._process(0.050)
	_handler._process(0.050)  # 150ms total — still below 170ms
	assert_eq(fire_count, 0, "No fire before threshold even with accumulated small deltas")

## AC-5: Soft drop fires soft_drop signal (not move_left/move_right)
func test_das_soft_drop_fires_soft_drop_not_move() -> void:
	var soft_drop_count := 0
	var move_count := 0
	_handler.soft_drop.connect(func(): soft_drop_count += 1)
	_handler.move_left.connect(func(): move_count += 1)
	_handler._key_soft_drop_held = true
	_handler._process(0.170)
	assert_eq(soft_drop_count, 1, "soft_drop signal should fire (not move_left)")
	assert_eq(move_count, 0, "move_left should NOT fire when soft_drop is held")

## AC-6: Independent DAS state per action (all 3 held)
func test_das_independent_per_action_all_three_held() -> void:
	var left_count := 0
	var right_count := 0
	var soft_count := 0
	_handler.move_left.connect(func(): left_count += 1)
	_handler.move_right.connect(func(): right_count += 1)
	_handler.soft_drop.connect(func(): soft_count += 1)
	_handler._key_left_held = true
	_handler._key_right_held = true
	_handler._key_soft_drop_held = true
	_handler._process(0.200)  # all 3 accumulate 200ms
	assert_eq(left_count, 1, "move_left fires once at 200ms")
	assert_eq(right_count, 1, "move_right fires once at 200ms")
	assert_eq(soft_count, 1, "soft_drop fires once at 200ms")

## AC-7: DAS resumes from correct elapsed after unpause
func test_das_resume_after_pause_at_correct_time() -> void:
	var fires: Array = []
	_handler.move_left.connect(func(): fires.append("fire"))
	_handler._key_left_held = true
	_handler._das_left_time_ms = 200  # simulate 200ms already accumulated
	_handler._das_left_initial_fired = true
	_handler._das_left_repeat_count = 1
	# Now unpause — next repeat at 250ms (50ms after 200ms)
	_handler._process(0.050)
	assert_eq(fires.size(), 1, "One repeat fire at 250ms (50ms after unpause from 200ms)")

## Repeat rate: 50ms interval
func test_das_repeat_at_50ms_intervals() -> void:
	var fires: Array = []
	_handler.move_left.connect(func(): fires.append("fire"))
	_handler._key_left_held = true
	_handler._process(0.170)  # initial at 170ms
	_handler._process(0.050)  # repeat 1 at 220ms
	_handler._process(0.050)  # repeat 2 at 270ms
	_handler._process(0.050)  # repeat 3 at 320ms
	# No fire at 270ms+50ms=320ms since repeat_count=3 and expected=3 (3<=3 true fires)
	# At 320ms: expected = (320-170)/50 = 3, repeat_count=3, 3<=3 true → fire
	assert_eq(fires.size(), 4, "Should fire 4 times: initial + 3 repeats at 50ms intervals")