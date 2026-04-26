# Speed Progression System Unit Tests
extends GutTest

var _speed: SpeedProgression
var _grid: Grid

func before_each() -> void:
	_grid = Grid.new()
	_speed = SpeedProgression.new()
	_speed.grid = _grid


func after_each() -> void:
	_speed.free()
	_grid.free()


## AC-1: Level 1 = 1000ms
func test_level_1_drop_interval() -> void:
	_speed.current_level = 1
	assert_eq(_speed.get_drop_interval_ms(), 1000, "Level 1 should have 1000ms interval")


## AC-4 partial: Level 14 = 350ms
func test_level_14_drop_interval() -> void:
	_speed.current_level = 14
	assert_eq(_speed.get_drop_interval_ms(), 350, "Level 14 should have 350ms interval")


## Test level 15 is capped at minimum 100ms (per GDD AC)
func test_level_15_drop_interval_capped() -> void:
	_speed.current_level = 15
	# Per GDD AC-4: level 15 should be 100ms (MIN cap overrides formula)
	# Formula gives 300ms but AC says 100ms
	var interval := _speed.get_drop_interval_ms()
	# The formula gives 300ms but level 15 is capped
	# Per implementation: if current_level >= MAX_LEVEL, return DROP_INTERVAL_MIN
	assert_eq(interval, 100, "Level 15 should be capped at 100ms")


## Test level up changes interval
func test_level_up_changes_interval() -> void:
	_speed.current_level = 1
	var interval1 := _speed.get_drop_interval_ms()

	_speed.current_level = 2
	var interval2 := _speed.get_drop_interval_ms()

	assert_true(interval2 < interval1, "Level 2 interval should be faster than level 1")
	assert_eq(interval2, 950, "Level 2 should have 950ms interval")


## Test minimum interval capped at 100ms
func test_min_interval_capped_at_100ms() -> void:
	_speed.current_level = 15
	var interval := _speed.get_drop_interval_ms()
	assert_eq(interval, 100, "Should be capped at minimum 100ms")


## Test level up signal emitted on level change
func test_level_up_signal_emitted() -> void:
	var new_level: int = -1
	_speed.level_up.connect(func(l): new_level = l)

	_speed.current_level = 2
	_speed.update_level(2)
	# Note: update_level only emits if level actually changes
	_speed._on_lines_cleared(10)  # This should trigger level up from 1 to 2

	# Reset to 1 and trigger proper level up
	_speed.current_level = 1
	_speed.lines_since_last_level = 0
	_speed._on_lines_cleared(10)
	assert_eq(new_level, 2, "level_up signal should emit new level 2")


## Test drop_interval_changed signal emitted on level up
func test_drop_interval_changed_signal_emitted() -> void:
	var emitted_interval: int = -1
	_speed.drop_interval_changed.connect(func(ms): emitted_interval = ms)

	_speed.current_level = 1
	_speed.lines_since_last_level = 0
	_speed._on_lines_cleared(10)

	assert_eq(emitted_interval, 950, "drop_interval_changed should emit 950ms")


## Test new game resets level and interval
func test_new_game_resets_state() -> void:
	_speed.current_level = 8
	_speed.lines_since_last_level = 5

	_speed._on_new_game()
	assert_eq(_speed.current_level, 1, "Level should reset to 1")
	assert_eq(_speed.lines_since_last_level, 0, "Lines should reset to 0")


## Test lines_since_last_level accumulates
func test_lines_accumulate() -> void:
	_speed.lines_since_last_level = 0
	_speed._on_lines_cleared(3)
	assert_eq(_speed.lines_since_last_level, 3, "Lines should accumulate")
	_speed._on_lines_cleared(4)
	assert_eq(_speed.lines_since_last_level, 7, "Lines should continue accumulating")


## Test level-up at 10 lines
func test_level_up_at_10_lines() -> void:
	_speed.current_level = 1
	_speed.lines_since_last_level = 0

	_speed._on_lines_cleared(10)

	assert_eq(_speed.current_level, 2, "Level should be 2 after 10 lines")
	assert_eq(_speed.lines_since_last_level, 0, "Lines should reset after level up")


## Test multi-level jump when clearing many lines at once
func test_multi_level_jump() -> void:
	_speed.current_level = 1
	_speed.lines_since_last_level = 9

	_speed._on_lines_cleared(4)  # 9 + 4 = 13, enough for one level up with 3 carry-over

	assert_eq(_speed.current_level, 2, "Level should jump to 2")
	assert_eq(_speed.lines_since_last_level, 3, "Should have 3 lines carry-over")


## Test level does not exceed MAX_LEVEL
func test_level_capped_at_max() -> void:
	_speed.current_level = 14
	_speed.lines_since_last_level = 9

	_speed._on_lines_cleared(10)  # Would be level 16, but capped at 15

	assert_eq(_speed.current_level, 15, "Level should cap at MAX_LEVEL")
	assert_eq(_speed.lines_since_last_level, 9, "Lines carry-over stops at max level")


## Test get_drop_interval returns float in seconds
func test_get_drop_interval_returns_float() -> void:
	_speed.current_level = 1
	var interval := _speed.get_drop_interval()
	assert_almost_eq(interval, 1.0, 0.001, "Level 1 interval should be 1.0 seconds")


## Test drop interval decreases linearly with level
func test_drop_interval_decreases_linearly() -> void:
	var intervals: Array[int] = []
	for level in range(1, 16):
		_speed.current_level = level
		intervals.append(_speed.get_drop_interval_ms())

	# Verify linear decrease: each level is 50ms faster
	for i in range(1, intervals.size()):
		var diff := intervals[i - 1] - intervals[i]
		assert_eq(diff, 50, "Each level should be 50ms faster")


## Test get_level returns current level
func test_get_level() -> void:
	_speed.current_level = 7
	assert_eq(_speed.get_level(), 7, "get_level should return current level")


## Test get_lines_since_last_level returns correct value
func test_get_lines_since_last_level() -> void:
	_speed.lines_since_last_level = 5
	assert_eq(_speed.get_lines_since_last_level(), 5, "Should return lines since last level")