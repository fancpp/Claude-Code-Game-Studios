# Collision Detection API Unit Tests — Story 001
# Tests: can_move_to with empty grid, wall/floor/stack collision, is_occupied
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

## Test: can_move_to with empty grid returns true
func test_can_move_to_empty_grid_returns_true() -> void:
	# Given: empty 10x20 grid, I-piece shape at position (5, 10)
	var shape := [[0, 0], [0, -1], [0, -2], [0, -3]]  # I-piece vertical
	# When: can_move_to is called for a valid position
	var result := _collision.can_move_to(5, 10, shape)
	# Then: returns true
	assert_true(result, "can_move_to should return true on empty grid")

## Test: can_move_to with wall collision returns false
func test_can_move_to_wall_collision_returns_false() -> void:
	# Given: empty grid, T-piece shape
	var shape := [[0, 0], [-1, 0], [1, 0], [0, -1]]  # T-piece
	# When: attempting to move left wall at x=-1
	var result := _collision.can_move_to(-1, 10, shape)
	# Then: returns false
	assert_false(result, "can_move_to should return false for wall collision")

## Test: can_move_to with floor collision returns false
func test_can_move_to_floor_collision_returns_false() -> void:
	# Given: empty grid, T-piece shape
	var shape := [[0, 0], [-1, 0], [1, 0], [0, -1]]
	# When: attempting to move below floor at y=-1
	var result := _collision.can_move_to(5, -1, shape)
	# Then: returns false
	assert_false(result, "can_move_to should return false for floor collision")

## Test: can_move_to with stack collision returns false
func test_can_move_to_stack_collision_returns_false() -> void:
	# Given: grid with a locked piece at y=8
	_grid.set_cell(5, 8, 1)
	_grid.set_cell(6, 8, 1)
	var shape := [[0, 0], [1, 0]]  # Small horizontal shape
	# When: attempting to move onto the locked piece
	var result := _collision.can_move_to(5, 9, shape)
	# Then: returns false
	assert_false(result, "can_move_to should return false for stack collision")

## Test: can_move_to with valid position returns true
func test_can_move_to_valid_position_returns_true() -> void:
	# Given: empty grid
	var shape := [[0, 0]]
	# When: moving to a valid empty position
	var result := _collision.can_move_to(5, 10, shape)
	# Then: returns true
	assert_true(result, "can_move_to should return true for valid empty position")

## Test: is_occupied returns true for occupied cell
func test_is_occupied_returns_true_for_occupied_cell() -> void:
	# Given: grid with cell (5, 10) occupied
	_grid.set_cell(5, 10, 1)
	# When: checking if cell is occupied
	var result := _collision.is_occupied(5, 10)
	# Then: returns true
	assert_true(result, "is_occupied should return true for occupied cell")

## Test: is_occupied returns false for empty cell
func test_is_occupied_returns_false_for_empty_cell() -> void:
	# Given: empty grid
	# When: checking if cell (5, 10) is occupied
	var result := _collision.is_occupied(5, 10)
	# Then: returns false
	assert_false(result, "is_occupied should return false for empty cell")

## Test: is_occupied returns false for out-of-bounds
func test_is_occupied_returns_false_for_out_of_bounds() -> void:
	# Given: empty grid
	# When: checking out-of-bounds position
	var result := _collision.is_occupied(-1, 5)
	# Then: returns false
	assert_false(result, "is_occupied should return false for out-of-bounds")

## Test: Right wall collision returns false
func test_can_move_to_right_wall_collision_returns_false() -> void:
	# Given: empty grid, T-piece shape
	var shape := [[0, 0], [1, 0]]  # 2-cell horizontal
	# When: attempting to move past right wall at x=9
	var result := _collision.can_move_to(9, 10, shape)
	# Then: returns false (x=10 is out of bounds)
	assert_false(result, "can_move_to should return false for right wall collision")