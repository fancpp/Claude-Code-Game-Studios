# Grid Boundary Validation Unit Tests — Story 002
# Test evidence for: tests/unit/grid/boundary_test.gd
# Story: production/epics/grid-system/story-002-boundary-validation.md
# ADR: ADR-ARCH-001 (Grid Resource Pattern)
extends GutTest

var _grid: Grid

func before_each() -> void:
	_grid = Grid.new()

func after_each() -> void:
	_grid.free()

## AC-1 / AC-2: is_valid_position rejects out-of-bounds X
func test_grid_is_valid_position_rejects_negative_x() -> void:
	assert_false(_grid.is_valid_position(-1, 5), "is_valid_position(-1, 5) should return false")

func test_grid_is_valid_position_rejects_x_at_width() -> void:
	assert_false(_grid.is_valid_position(10, 5), "is_valid_position(10, 5) should return false")

func test_grid_is_valid_position_rejects_x_beyond_width() -> void:
	assert_false(_grid.is_valid_position(11, 5), "is_valid_position(11, 5) should return false")
	assert_false(_grid.is_valid_position(100, 5), "is_valid_position(100, 5) should return false")

func test_grid_is_valid_position_accepts_valid_x() -> void:
	assert_true(_grid.is_valid_position(0, 5), "is_valid_position(0, 5) should return true")
	assert_true(_grid.is_valid_position(9, 5), "is_valid_position(9, 5) should return true")

## AC-3: is_valid_position accepts all valid coordinates
func test_grid_is_valid_position_all_valid_coordinates() -> void:
	for y in range(Grid.GRID_HEIGHT):
		for x in range(Grid.GRID_WIDTH):
			var result = _grid.is_valid_position(x, y)
			assert_true(result, "is_valid_position(%d, %d) should return true" % [x, y])

func test_grid_is_valid_position_four_corners() -> void:
	assert_true(_grid.is_valid_position(0, 0), "(0,0) should be valid")
	assert_true(_grid.is_valid_position(9, 0), "(9,0) should be valid")
	assert_true(_grid.is_valid_position(0, 19), "(0,19) should be valid")
	assert_true(_grid.is_valid_position(9, 19), "(9,19) should be valid")

## AC-4: Boundary edge cases at exact limits
func test_grid_is_valid_position_last_valid_cell() -> void:
	assert_true(_grid.is_valid_position(9, 19), "(9,19) should be valid — last valid cell")

func test_grid_is_valid_position_x_at_limit() -> void:
	assert_false(_grid.is_valid_position(10, 19), "(10, 19) should be invalid — x at limit")

func test_grid_is_valid_position_y_at_limit() -> void:
	assert_false(_grid.is_valid_position(9, 20), "(9, 20) should be invalid — y at limit")

func test_grid_is_valid_position_both_at_limit() -> void:
	assert_false(_grid.is_valid_position(10, 20), "(10, 20) should be invalid — both at limit")

func test_grid_is_valid_position_negative_both() -> void:
	assert_false(_grid.is_valid_position(-1, -1), "(-1, -1) should be invalid — negative on both axes")

## get_cell returns -1 for invalid coordinates
func test_grid_get_cell_negative_x_returns_minus_one() -> void:
	assert_eq(_grid.get_cell(-1, 5), -1, "get_cell(-1, 5) should return -1")

func test_grid_get_cell_x_at_width_returns_minus_one() -> void:
	assert_eq(_grid.get_cell(10, 5), -1, "get_cell(10, 5) should return -1")

func test_grid_get_cell_negative_y_returns_minus_one() -> void:
	assert_eq(_grid.get_cell(3, -1), -1, "get_cell(3, -1) should return -1")

func test_grid_get_cell_y_at_height_returns_minus_one() -> void:
	assert_eq(_grid.get_cell(3, 20), -1, "get_cell(3, 20) should return -1")

func test_grid_get_cell_completely_out_of_bounds() -> void:
	assert_eq(_grid.get_cell(-1, -1), -1, "get_cell(-1, -1) should return -1")
	assert_eq(_grid.get_cell(10, 20), -1, "get_cell(10, 20) should return -1")

## set_cell no-ops for invalid coordinates
func test_grid_set_cell_negative_x_no_op() -> void:
	_grid.set_cell(-1, 5, 3)
	# No crash, and cell (0,0) should still be empty (not modified)
	assert_eq(_grid.get_cell(0, 0), Grid.EMPTY, "set_cell(-1, 5, 3) should be no-op")

func test_grid_set_cell_x_at_width_no_op() -> void:
	_grid.set_cell(10, 5, 3)
	assert_eq(_grid.get_cell(0, 0), Grid.EMPTY, "set_cell(10, 5, 3) should be no-op")

func test_grid_set_cell_negative_y_no_op() -> void:
	_grid.set_cell(3, -1, 3)
	assert_eq(_grid.get_cell(0, 0), Grid.EMPTY, "set_cell(3, -1, 3) should be no-op")

func test_grid_set_cell_y_at_height_no_op() -> void:
	_grid.set_cell(3, 20, 3)
	assert_eq(_grid.get_cell(0, 0), Grid.EMPTY, "set_cell(3, 20, 3) should be no-op")

func test_grid_set_cell_completely_out_of_bounds_no_op() -> void:
	_grid.set_cell(-1, -1, 3)
	_grid.set_cell(10, 20, 3)
	assert_eq(_grid.get_cell(0, 0), Grid.EMPTY, "set_cell with completely invalid coords should be no-op")

func test_grid_set_cell_valid_after_invalid_no_op() -> void:
	# First try invalid, then valid — the valid one should still work
	_grid.set_cell(-1, 5, 3)
	_grid.set_cell(3, 5, 7)
	assert_eq(_grid.get_cell(3, 5), 7, "Valid set_cell should work after invalid set_cell no-ops")