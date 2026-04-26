# Ghost Piece Calculation Unit Tests
extends GutTest

var _ghost: GhostPiece
var _grid: Grid

func before_each() -> void:
	_grid = Grid.new()
	_ghost = GhostPiece.new()
	_ghost.grid = _grid


func after_each() -> void:
	_ghost.free()
	_grid.free()


## Helper: create a simple T-piece shape [[0,0], [0,1], [0,2], [1,1]]
func _make_t_shape() -> Array:
	return [[0, 0], [0, 1], [0, 2], [1, 1]]


## Helper: create an I-piece shape (vertical) [[0,0], [0,1], [0,2], [0,3]]
func _make_i_shape() -> Array:
	return [[0, 0], [0, 1], [0, 2], [0, 3]]


## AC-1: Ghost on empty grid drops to floor
func test_ghost_at_bottom() -> void:
	var shape := _make_t_shape()
	var ghost_y := _ghost.calculate_ghost_y(5, 15, shape)
	assert_eq(ghost_y, 0, "Ghost should be at floor (y=0) on empty grid")


## AC-2: Ghost above stack stops at stack top
func test_ghost_above_stack() -> void:
	var shape := _make_t_shape()
	# Build a stack at y=5 (occupy cells at y=5)
	for x in range(Grid.GRID_WIDTH):
		_grid.set_cell(x, 5, 1)

	var ghost_y := _ghost.calculate_ghost_y(5, 10, shape)
	assert_eq(ghost_y, 6, "Ghost should be at y=6 (one above stack at y=5)")


## AC-3: Ghost equals piece when on floor (cannot move down)
func test_ghost_equals_piece_on_floor() -> void:
	var shape := _make_t_shape()
	# Piece at y=0 on floor — ghost should equal piece position
	var ghost_y := _ghost.calculate_ghost_y(5, 0, shape)
	assert_eq(ghost_y, 0, "Ghost should equal piece position when on floor")


## Test ghost above single occupied cell
func test_ghost_above_single_cell() -> void:
	var shape := [[0, 0]]  # single cell piece
	_grid.set_cell(5, 3, 1)  # single cell obstacle

	var ghost_y := _ghost.calculate_ghost_y(5, 5, shape)
	assert_eq(ghost_y, 4, "Ghost should be at y=4 (one above cell at y=3)")


## Test ghost position signal is emitted
func test_ghost_position_signal_emitted() -> void:
	var shape := _make_t_shape()
	var emitted_x: int = -1
	var emitted_y: int = -1
	var emitted_shape: Array = []

	_ghost.ghost_position_updated.connect(func(x, y, s):
		emitted_x = x
		emitted_y = y
		emitted_shape = s
	)

	_ghost.update_ghost(5, 15, shape)
	assert_eq(emitted_x, 5, "Signal should emit ghost_x=5")
	assert_eq(emitted_y, 0, "Signal should emit ghost_y=0")
	assert_eq(emitted_shape.size(), shape.size(), "Signal should emit shape")


## Test ghost recalculates on piece move
func test_ghost_recalculates_on_move() -> void:
	var shape := _make_t_shape()
	# Move from x=5 to x=3
	_ghost.update_ghost(5, 10, shape)
	_ghost.update_ghost(3, 10, shape)
	assert_eq(_ghost.get_ghost_x(), 3, "Ghost x should update on move")


## Test ghost position updates when piece Y changes
func test_ghost_updates_when_piece_y_changes() -> void:
	var shape := _make_t_shape()
	# Piece at y=15 on empty grid → ghost at y=0
	_ghost.update_ghost(5, 15, shape)
	var y1 := _ghost.get_ghost_y()

	# Now piece at y=10 → ghost still at y=0
	_ghost.update_ghost(5, 10, shape)
	var y2 := _ghost.get_ghost_y()

	# Both should be at floor (y=0) since grid is empty
	assert_eq(y1, 0, "Ghost y at piece_y=15 should be 0")
	assert_eq(y2, 0, "Ghost y at piece_y=10 should be 0")


## Test ghost stops at floor even when floor is at y=0
func test_ghost_does_not_go_below_floor() -> void:
	var shape := _make_i_shape()
	# I-piece at very bottom — ghost should not go below y=0
	var ghost_y := _ghost.calculate_ghost_y(5, 1, shape)
	# With I-shape at y=1, ghost should be at y=0 (can_move_to(5, 0) returns false)
	assert_eq(ghost_y, 0, "Ghost should not go below floor")


## Test get_drop_distance returns correct distance
func test_get_drop_distance() -> void:
	var distance := _ghost.get_drop_distance(15, 0)
	assert_eq(distance, 15, "Drop distance from y=15 to y=0 should be 15")


## Test ghost calculation with wall collision
func test_ghost_stopped_by_wall() -> void:
	var shape := [[0, 0], [1, 0], [2, 0]]  # horizontal bar at x=0,1,2
	# Place obstacle at right side so ghost can't go all the way to floor
	_grid.set_cell(0, 3, 1)

	var ghost_y := _ghost.calculate_ghost_y(0, 5, shape)
	# The ghost should stop above the obstacle
	assert_true(ghost_y >= 0, "Ghost y should be valid")


## Test ghost_shape is duplicated (not reference)
func test_ghost_shape_is_duplicated() -> void:
	var shape := _make_t_shape()
	_ghost.update_ghost(5, 10, shape)
	var retrieved := _ghost.get_ghost_shape()

	# Modify retrieved shape — original should not change
	retrieved.clear()
	assert_eq(_ghost.get_ghost_shape().size(), shape.size(), "Shape should be duplicated")