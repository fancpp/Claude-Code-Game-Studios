# Collision Detection Unit Tests
# Tests can_move_to() for all 3 collision types: Wall, Floor, Stack.
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

## Helper: get a 4x4 grid for a 2x2 piece at (tx, ty) with given shape.
func _shape_at(tx: int, ty: int, shape: Array) -> Array:
	return shape  # 4×4 bool grid

## 2×2 shape (all cells occupied) — O-piece-like
var _2x2_shape: Array = [
	[false,false,false,false],
	[false,true,true,false],
	[false,true,true,false],
	[false,false,false,false]
]

## Helper: standard 1×4 I-piece horizontal (rot 0)
var _i_horiz: Array = [
	[false,false,false,false],
	[true,true,true,true],
	[false,false,false,false],
	[false,false,false,false]
]

## AC-1: Empty grid — can move anywhere in bounds
func test_can_move_empty_grid() -> void:
	assert_true(_collision.can_move_to(0, 0, _2x2_shape), "Should move to 0,0")
	assert_true(_collision.can_move_to(5, 10, _2x2_shape), "Should move to 5,10")
	assert_true(_collision.can_move_to(8, 17, _2x2_shape), "Should move to 8,17")

## AC-2: Wall collision — x < 0
func test_cannot_move_wall_left() -> void:
	assert_false(_collision.can_move_to(-1, 0, _2x2_shape), "x=-1 blocked")

## AC-2: Wall collision — x + shape exceeds grid width
func test_cannot_move_wall_right() -> void:
	# O-piece rightmost cell at col 1, so x=9 means col 10 = out of bounds
	assert_false(_collision.can_move_to(9, 0, _2x2_shape), "x=9 blocked (col overflow)")
	# I-piece at x=7, horizontal spans 0-3 → col 10 = out of bounds
	assert_false(_collision.can_move_to(7, 0, _i_horiz), "x=7 blocked for I horiz")

## AC-3: Floor collision — y < 0
func test_cannot_move_floor() -> void:
	assert_false(_collision.can_move_to(4, -1, _2x2_shape), "y=-1 blocked")

## AC-3: Floor collision — y + shape exceeds grid height
func test_cannot_move_floor_top() -> void:
	assert_false(_collision.can_move_to(0, 18, _2x2_shape), "y=18 blocked (row overflow)")

## AC-4: Stack collision — occupied cell
func test_cannot_move_into_occupied_cell() -> void:
	_grid.set_cell(5, 5, 3)  # place T-piece (type 3)
	assert_false(_collision.can_move_to(4, 5, _2x2_shape), "Blocked by stack at 5,5")

## AC-5: Valid position returns true
func test_can_move_valid_position() -> void:
	assert_true(_collision.can_move_to(4, 10, _2x2_shape), "4,10 is valid")

## AC-6: is_occupied
func test_is_occupied_true() -> void:
	_grid.set_cell(3, 7, 1)
	assert_true(_collision.is_occupied(3, 7), "Cell at 3,7 is occupied")

func test_is_occupied_false_empty() -> void:
	assert_false(_collision.is_occupied(3, 7), "Cell at 3,7 is empty")

func test_is_occupied_out_of_bounds() -> void:
	assert_false(_collision.is_occupied(-1, 0), "Out of bounds returns false")
	assert_false(_collision.is_occupied(10, 0), "Out of bounds returns false")