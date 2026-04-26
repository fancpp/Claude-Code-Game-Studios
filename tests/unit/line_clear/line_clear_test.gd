# Line Clear System Unit Tests
extends GutTest

var _line_clear: LineClear
var _grid: Grid

func before_each() -> void:
	_grid = Grid.new()
	_line_clear = LineClear.new()
	_line_clear.grid = _grid


func after_each() -> void:
	_line_clear.free()
	_grid.free()


func _populate_row(y: int, value: int) -> void:
	for x in range(Grid.GRID_WIDTH):
		_grid.set_cell(x, y, value)


## AC-1: Complete row at y=0 detected
func test_detects_complete_row() -> void:
	_populate_row(0, 1)
	var count := _line_clear.detect_and_clear_lines()
	assert_eq(count, 1, "Should detect 1 complete row")


## AC-4: Row with 1 EMPTY cell NOT cleared
func test_does_not_clear_incomplete_row() -> void:
	_populate_row(5, 1)
	_grid.set_cell(3, 5, Grid.EMPTY)  # one cell empty
	var count := _line_clear.detect_and_clear_lines()
	assert_eq(count, 0, "Should not clear incomplete row")


## AC-5: No complete rows returns 0
func test_no_complete_rows_returns_zero() -> void:
	_grid.set_cell(0, 0, 1)  # only one cell occupied
	var count := _line_clear.detect_and_clear_lines()
	assert_eq(count, 0, "Should return 0 when no rows complete")


## Test multiple complete rows detected
func test_detects_multiple_complete_rows() -> void:
	_populate_row(2, 1)
	_populate_row(5, 1)
	_populate_row(9, 1)
	var count := _line_clear.detect_and_clear_lines()
	assert_eq(count, 3, "Should detect 3 complete rows")


## Test clear_lines returns count of 4 (Tetris)
func test_detects_four_complete_rows() -> void:
	_populate_row(0, 1)
	_populate_row(1, 1)
	_populate_row(2, 1)
	_populate_row(3, 1)
	var count := _line_clear.detect_and_clear_lines()
	assert_eq(count, 4, "Should detect 4 complete rows (Tetris)")


## AC-2: Non-adjacent rows collapse correctly
func test_cleared_rows_removed_and_shifted() -> void:
	# Set up rows: y=3 complete, y=5 complete, y=10 has data
	_populate_row(3, 1)
	_populate_row(5, 1)
	_populate_row(10, 2)  # this row should shift to y=8

	var count := _line_clear.detect_and_clear_lines()
	assert_eq(count, 2, "Should clear 2 rows")

	# Row that was at y=10 should now be at y=8
	assert_false(_grid.is_empty(0, 8), "Row should have shifted to y=8")
	assert_eq(_grid.get_cell(0, 8), 2, "Shifted row should have value 2")

	# Cleared rows should be empty
	assert_true(_grid.is_empty(0, 3), "Cleared row y=3 should be empty")
	assert_true(_grid.is_empty(0, 5), "Cleared row y=5 should be empty")


## AC-6: Row at y=10 shifts down by 2 when rows y=3,y=4 cleared
func test_row_shifts_down_by_exact_count() -> void:
	_populate_row(3, 1)
	_populate_row(4, 1)
	_populate_row(10, 3)

	var count := _line_clear.detect_and_clear_lines()
	assert_eq(count, 2, "Should clear 2 rows")

	# Row at y=10 should shift to y=8 (2 cleared rows below it: y=3, y=4)
	assert_false(_grid.is_empty(0, 8), "Row should shift to y=8")
	assert_eq(_grid.get_cell(0, 8), 3, "Shifted row should preserve value")


## Test lines_cleared signal is emitted after collapse
func test_lines_cleared_signal_emitted() -> void:
	_populate_row(0, 1)
	_populate_row(1, 1)

	var emitted_count: int = -1
	_line_clear.lines_cleared.connect(func(count): emitted_count = count)

	var result := _line_clear.detect_and_clear_lines()
	assert_eq(result, 2, "Should return 2 cleared lines")
	assert_eq(emitted_count, 2, "Signal should emit count=2")


## Test no signal emitted when zero lines cleared
func test_no_signal_when_zero_lines_cleared() -> void:
	_grid.set_cell(0, 0, 1)  # only one cell

	var signal_emitted := false
	_line_clear.lines_cleared.connect(func(_count): signal_emitted = true)

	var result := _line_clear.detect_and_clear_lines()
	assert_eq(result, 0, "Should return 0")
	assert_false(signal_emitted, "Signal should not emit when 0 lines cleared")


## Test that collapse is atomic (no intermediate states)
func test_collapse_is_atomic() -> void:
	# Set up: y=0 and y=1 complete, y=2 has data
	_populate_row(0, 1)
	_populate_row(1, 1)
	_populate_row(2, 4)

	_line_clear.detect_and_clear_lines()

	# After atomic collapse:
	# y=0 was complete and should be empty
	# y=1 was complete and should be empty
	# y=2 had data, shifted from y=2 to y=0 (since 2 cleared rows were below it)
	# Actually: y=2 has 2 cleared rows below it (y=0, y=1) so shifts by 2 to y=0
	assert_false(_grid.is_empty(0, 0), "Row with data should be at y=0 after collapse")
	assert_eq(_grid.get_cell(0, 0), 4, "Data should be at y=0")
	assert_true(_grid.is_empty(0, 1), "y=1 should be empty (was complete)")
	assert_true(_grid.is_empty(0, 2), "y=2 should be empty (was complete)")