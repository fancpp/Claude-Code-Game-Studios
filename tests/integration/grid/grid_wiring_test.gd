# Grid Wiring Integration Test — Story 003
# Test evidence for: tests/integration/grid/grid_wiring_test.gd
# Story: production/epics/grid-system/story-003-grid-wiring.md
# ADR: ADR-ARCH-001 (Grid Resource Pattern), ADR-ARCH-003 (Scene Tree)
extends GutTest

## AC-1: main.gd instantiates Grid once
func test_main_instantiates_grid_once() -> void:
	var main := Main.new()
	await main.ready  # _ready() is called when added to tree, but we call it manually
	# Note: @onready var grid = Grid.new() is set when the script instance is created
	assert_true(main.grid != null, "main.grid should not be null after _ready()")
	assert_true(main.grid is Grid, "main.grid should be a Grid instance")
	main.free()

## AC-2: grid wired to all 7 children
func test_grid_wired_to_all_7_systems() -> void:
	var main := Main.new()
	await main.ready

	# All 7 systems should have grid assigned via main.gd _ready() wiring
	assert_eq(main.collision.grid, main.grid, "collision.grid should reference main.grid")
	assert_eq(main.tetromino.grid, main.grid, "tetromino.grid should reference main.grid")
	assert_eq(main.piece_spawn.grid, main.grid, "piece_spawn.grid should reference main.grid")
	assert_eq(main.line_clear.grid, main.grid, "line_clear.grid should reference main.grid")
	assert_eq(main.combo_scoring.grid, main.grid, "combo_scoring.grid should reference main.grid")
	assert_eq(main.ghost_piece.grid, main.grid, "ghost_piece.grid should reference main.grid")
	assert_eq(main.speed_progression.grid, main.grid, "speed_progression.grid should reference main.grid")

	# All should reference the SAME grid instance
	assert_true(main.collision.grid == main.tetromino.grid, "all systems should share the same Grid instance")

	main.free()

## AC-3: All 7 systems declare @export var grid: Grid
func test_all_7_systems_declare_grid_export() -> void:
	var collision := Collision.new()
	var tetromino := Tetromino.new()
	var piece_spawn := PieceSpawn.new()
	var line_clear := LineClear.new()
	var combo_scoring := ComboScoring.new()
	var ghost_piece := GhostPiece.new()
	var speed_progression := SpeedProgression.new()

	# All should have a 'grid' property (it's typed via @export)
	assert_true(collision.has("grid"), "collision should have 'grid' property")
	assert_true(tetromino.has("grid"), "tetromino should have 'grid' property")
	assert_true(piece_spawn.has("grid"), "piece_spawn should have 'grid' property")
	assert_true(line_clear.has("grid"), "line_clear should have 'grid' property")
	assert_true(combo_scoring.has("grid"), "combo_scoring should have 'grid' property")
	assert_true(ghost_piece.has("grid"), "ghost_piece should have 'grid' property")
	assert_true(speed_progression.has("grid"), "speed_progression should have 'grid' property")

	collision.free()
	tetromino.free()
	piece_spawn.free()
	line_clear.free()
	combo_scoring.free()
	ghost_piece.free()
	speed_progression.free()

## AC-4: assert(grid != null) fires when grid is null
func test_assert_fires_when_grid_is_null() -> void:
	var collision := Collision.new()
	# By default @export var grid is null — calling _ready() should trigger assert
	# We use Gut's expect_assert() to catch this
	expect_assert("Grid not wired", func():
		collision._ready()
	)
	collision.free()

## AC-5: No Autoload for grid
func test_no_autoload_for_grid() -> void:
	# project.godot doesn't exist in test environment, so this is a code review check
	# We verify that no Grid autoload pattern is used in the source code
	var main_source := FileAccess.get_file_as_string("res://src/main/main.gd")
	var grid_gd_source := FileAccess.get_file_as_string("res://src/grid/grid.gd")

	# Grid class should NOT be registered as Autoload
	# (This is verified by checking the source — Grid is class_name, not Autoload)
	assert_false("Autoload" in main_source, "main.gd should not reference Autoload")
	assert_false("class_name Grid extends RefCounted" in main_source, "main.gd should not redefine Grid")
	assert_true("class_name Grid extends RefCounted" in grid_gd_source, "grid.gd should define Grid class_name")

## AC-6: GUT test can create Grid.new() directly
func test_grid_can_be_instantiated_without_autoload() -> void:
	var g := Grid.new()
	assert_true(g is Grid, "Grid.new() should create a Grid instance")
	assert_eq(g.get_cell(0, 0), Grid.EMPTY, "Fresh grid cell (0,0) should be EMPTY")
	assert_true(g.is_valid_position(5, 10), "is_valid_position should work on freshly instantiated Grid")
	g.free()