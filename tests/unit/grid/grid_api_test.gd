# Grid API Unit Tests — Story 001
# Test evidence for: tests/unit/grid/grid_api_test.gd
# Story: production/epics/grid-system/story-001-core-grid-api.md
# ADR: ADR-ARCH-001 (Grid Resource Pattern)
extends GutTest

var _grid: Grid

func before_each() -> void:
	_grid = Grid.new()

func after_each() -> void:
	_grid.free()

## AC-1: Fresh grid, get_cell(0,0) returns 0
func test_grid_get_cell_fresh_grid_returns_empty() -> void:
	assert_eq(_grid.get_cell(0, 0), Grid.EMPTY, "Fresh grid cell (0,0) should be EMPTY (0)")

func test_grid_get_cell_opposite_corner_returns_empty() -> void:
	assert_eq(_grid.get_cell(9, 19), Grid.EMPTY, "Fresh grid cell (9,19) should be EMPTY (0)")

## AC-2: Occupied cell returns tetromino type
func test_grid_get_cell_occupied_returns_value() -> void:
	_grid.set_cell(5, 5, 3)
	assert_eq(_grid.get_cell(5, 5), 3, "get_cell should return the tetromino type set via set_cell")

func test_grid_get_cell_values_1_to_7_all_returned_correctly() -> void:
	for value in range(1, 8):
		_grid.set_cell(3, 3, value)
		assert_eq(_grid.get_cell(3, 3), value, "Values 1-7 should be returned correctly")

func test_grid_get_cell_empty_distinguishable_from_unset() -> void:
	_grid.set_cell(2, 2, 0)
	assert_eq(_grid.get_cell(2, 2), 0, "Value 0 (EMPTY) should be distinguishable")

## AC-3: clear_grid() resets all 200 cells
func test_grid_clear_grid_resets_all_cells() -> void:
	_grid.set_cell(0, 0, 5)
	_grid.set_cell(9, 19, 7)
	_grid.set_cell(5, 5, 3)
	_grid.clear_grid()
	for y in range(Grid.GRID_HEIGHT):
		for x in range(Grid.GRID_WIDTH):
			assert_eq(_grid.get_cell(x, y), Grid.EMPTY, "All cells should be EMPTY after clear_grid")

func test_grid_clear_grid_idempotent() -> void:
	_grid.set_cell(1, 2, 3)
	_grid.clear_grid()
	_grid.clear_grid()
	assert_eq(_grid.get_cell(1, 2), Grid.EMPTY, "clear_grid called twice should be idempotent")

func test_grid_clear_grid_boundary_cells_cleared() -> void:
	_grid.set_cell(0, 0, 7)
	_grid.set_cell(9, 19, 7)
	_grid.clear_grid()
	assert_eq(_grid.get_cell(0, 0), Grid.EMPTY, "Boundary cell (0,0) should be cleared")
	assert_eq(_grid.get_cell(9, 19), Grid.EMPTY, "Boundary cell (9,19) should be cleared")

## AC-4 / AC-5: is_empty true/false
func test_grid_is_empty_fresh_grid_returns_true() -> void:
	assert_true(_grid.is_empty(3, 5), "is_empty should return true for fresh grid cell")

func test_grid_is_empty_fresh_grid_all_cells() -> void:
	assert_true(_grid.is_empty(0, 0), "is_empty(0,0) should be true on fresh grid")
	assert_true(_grid.is_empty(9, 19), "is_empty(9,19) should be true on fresh grid")

func test_grid_is_empty_occupied_returns_false() -> void:
	_grid.set_cell(3, 5, 3)
	assert_false(_grid.is_empty(3, 5), "is_empty should return false for occupied cell")

## AC-6: set_cell to 0 clears cell
func test_grid_set_cell_zero_clears_cell() -> void:
	_grid.set_cell(3, 5, 3)
	_grid.set_cell(3, 5, 0)
	assert_eq(_grid.get_cell(3, 5), Grid.EMPTY, "set_cell(x,y,0) should clear the cell")
	assert_true(_grid.is_empty(3, 5), "is_empty should return true after clearing cell")

func test_grid_set_cell_overwrite_non_zero_with_non_zero() -> void:
	_grid.set_cell(3, 5, 3)
	_grid.set_cell(3, 5, 5)
	assert_eq(_grid.get_cell(3, 5), 5, "Overwriting non-zero with another non-zero should work")

## AC-7: Column-major array access (cells[y][x])
func test_grid_column_major_access_via_api() -> void:
	_grid.set_cell(3, 5, 7)
	assert_eq(_grid.get_cell(3, 5), 7, "get_cell(x,y) should return value set via set_cell(x,y,value)")

func test_grid_cells_array_is_2d() -> void:
	assert_eq(_grid.cells.size(), Grid.GRID_HEIGHT, "cells should have GRID_HEIGHT (20) rows")
	assert_eq(_grid.cells[0].size(), Grid.GRID_WIDTH, "cells[0] should have GRID_WIDTH (10) columns")

func test_grid_column_major_internal_array_matches_api() -> void:
	_grid.set_cell(3, 5, 7)
	assert_eq(_grid.cells[5][3], 7, "cells[y][x] internal array access should match get_cell(x,y) API")