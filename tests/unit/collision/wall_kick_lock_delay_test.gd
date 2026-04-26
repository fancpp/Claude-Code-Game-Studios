# Wall Kick + Lock Delay Unit Tests
extends GutTest

var _grid: Grid
var _collision: Collision

func before_each() -> void:
	_grid = Grid.new()
	_collision = Collision.new()
	_collision.grid = _grid

func after_each() -> void:
	_collision.free()
	_grid.free()

## Helper: I-piece horizontal shape
var _i_horiz: Array = [
	[false,false,false,false],
	[true,true,true,true],
	[false,false,false,false],
	[false,false,false,false]
]

## AC-1: Wall kick offsets
func test_wall_kick_offsets_count() -> void:
	var offsets = _collision.get_wall_kick_offsets()
	assert_eq(offsets.size(), 6, "Should have 6 wall kick offsets")

func test_wall_kick_offsets_start_with_zero() -> void:
	var offsets = _collision.get_wall_kick_offsets()
	assert_eq(offsets[0], Vector2i(0, 0), "First offset should be (0,0)")

## AC-2: Lock delay starts inactive
func test_lock_delay_starts_inactive() -> void:
	assert_false(_collision.is_lock_delay_active(), "Lock delay should start inactive")

## AC-3: Start lock delay activates it
func test_start_lock_delay_activates() -> void:
	_collision.start_lock_delay()
	assert_true(_collision.is_lock_delay_active(), "Lock delay should be active after start")

## AC-4: Cancel lock delay deactivates
func test_cancel_lock_delay_deactivates() -> void:
	_collision.start_lock_delay()
	_collision.cancel_lock_delay()
	assert_false(_collision.is_lock_delay_active(), "Lock delay should be inactive after cancel")

## AC-5: Lock delay fires after 500ms
func test_lock_delay_fires_at_500ms() -> void:
	var expired := false
	_collision.lock_delay_expired.connect(func(): expired = true)
	_collision.start_lock_delay()
	_collision._process(0.500)  # exactly 500ms
	assert_true(expired, "lock_delay_expired should fire at 500ms")
	assert_false(_collision.is_lock_delay_active(), "Should be inactive after expiry")

## AC-6: No fire before 500ms
func test_no_fire_before_500ms() -> void:
	var expired := false
	_collision.lock_delay_expired.connect(func(): expired = true)
	_collision.start_lock_delay()
	_collision._process(0.499)
	assert_false(expired, "Should not fire before 500ms")
	assert_true(_collision.is_lock_delay_active(), "Should still be active")

## AC-7: Reset clears all state
func test_reset_lock_delay() -> void:
	_collision.start_lock_delay()
	_collision._process(0.100)
	_collision.reset_lock_delay()
	assert_false(_collision.is_lock_delay_active(), "Should be inactive after reset")

## AC-8: Lock delay pauses with game (not blocked by pause — just inactive via signal)
func test_lock_delay_accumulates_across_frames() -> void:
	_collision.start_lock_delay()
	_collision._process(0.200)
	_collision._process(0.200)
	_collision._process(0.100)
	assert_false(_collision.is_lock_delay_active(), "Should expire after 500ms accumulated")
	var expired_count := 0
	_collision.lock_delay_expired.connect(func(): expired_count += 1)
	_collision.start_lock_delay()
	_collision._process(0.200)
	_collision._process(0.200)
	_collision._process(0.150)
	assert_eq(expired_count, 1, "Should fire exactly once")