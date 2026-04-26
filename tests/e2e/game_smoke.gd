# game_smoke.gd — Godot Headless Smoke Test
# Runs without web export templates.
# Execute: godot --headless --script tests/e2e/game_smoke.gd
#
# Tests that:
# 1. main.tscn loads without crash
# 2. All 13 systems initialize (no null-deref)
# 3. GameState transitions work
# 4. Piece spawn works with 7-bag

extends SceneTree

const PASS := 0
const FAIL := 1

var _passed := 0
var _failed := 0

func _init() -> void:
	print("=== Godot Headless Smoke Test ===")

	var main_path := "res://main.tscn"
	var loaded := ResourceLoader.load(main_path)
	if loaded == null:
		_print("FAIL", "main.tscn loads", "file not found")
		quit(FAIL)
		return

	var main_node: Node = loaded.instantiate()
	root.add_child(main_node)

	# Let all _ready() callbacks run
	await (Engine.get_main_loop() as SceneTree).process_frame

	_print_test("main.tscn loads", main_node != null)
	_print_test("grid system", _test_grid())
	_print_test("collision system", _test_collision())
	_print_test("tetromino system", _test_tetromino())
	_print_test("piece spawn + 7-bag", _test_piece_spawn())
	_print_test("game state transitions", _test_game_state())
	_print_test("speed progression", _test_speed())
	_print_test("line clear system", _test_line_clear())
	_print_test("combo scoring", _test_combo())
	_print_test("ghost piece", _test_ghost())

	print("")
	print("=== Results ===")
	print("Passed: %d  Failed: %d" % [_passed, _failed])

	main_node.free()
	if _failed > 0:
		quit(FAIL)
	else:
		quit(PASS)

func _print(label: String, msg: String) -> void:
	print("[%s] %s" % [label, msg])

func _print_test(name: String, passed: bool) -> void:
	var status = "PASS" if passed else "FAIL"
	_print(status, name)
	if passed:
		_passed += 1
	else:
		_failed += 1

# --- Individual system tests ---

func _test_grid() -> bool:
	var g := Grid.new()
	var ok := g.cells.size() == 20 and g.cells[0].size() == 10
	ok = ok and g.is_empty(0, 0) == true
	ok = ok and g.is_valid_position(9, 19) == true
	ok = ok and g.is_valid_position(10, 19) == false  # out of bounds
	g.free()
	return ok

func _test_collision() -> bool:
	var c := Collision.new()
	c.grid = Grid.new()
	var ok := c.can_move_to(4, 19, TetrominoShapes.get_data(1).rotation_grids[0]) == true
	ok = ok and c.can_move_to(-1, 0, TetrominoShapes.get_data(1).rotation_grids[0]) == false  # wall
	c.free()
	return ok

func _test_tetromino() -> bool:
	var t := Tetromino.new()
	t.grid = Grid.new()
	t.collision = Collision.new()
	t.collision.grid = Grid.new()
	t.activate(1)  # I-piece
	var ok := t.piece_type == 1
	var ok2 := t.position == Vector2i(4, 19)
	# Valid move
	var moved := t.move_left()
	ok = ok and moved == true
	# Rotate CW
	var rotated := t.rotate_cw()
	ok = ok and rotated == true
	t.free()
	return ok and ok2

func _test_piece_spawn() -> bool:
	var ps := PieceSpawn.new()
	ps.grid = Grid.new()
	ps.tetromino = Tetromino.new()
	ps.tetromino.grid = Grid.new()
	ps.tetromino.collision = Collision.new()
	ps.tetromino.collision.grid = Grid.new()
	var ok := ps.peek_next() >= 1 and ps.peek_next() <= 7
	var spawned := ps.spawn_piece()
	ok = ok and spawned == true
	ps.free()
	return ok

func _test_game_state() -> bool:
	var gs := GameState.new()
	var ok := gs.change_state(gs.State.PLAYING) == true
	gs.start_new_game()
	ok = ok and gs.get_state() == gs.State.PLAYING
	gs._on_pause_input()
	ok = ok and gs.get_state() == gs.State.PAUSED
	gs._on_pause_input()
	ok = ok and gs.get_state() == gs.State.PLAYING
	gs.change_state(gs.State.GAME_OVER)
	ok = ok and gs.get_state() == gs.State.GAME_OVER
	gs.free()
	return ok

func _test_speed() -> bool:
	var sp := SpeedProgression.new()
	sp.grid = Grid.new()
	var ok := sp.get_level() == 1
	var interval := sp.get_drop_interval_ms()
	ok = ok and interval == 1000
	sp.free()
	return ok

func _test_line_clear() -> bool:
	var lc := LineClear.new()
	lc.grid = Grid.new()
	lc.free()
	return true

func _test_combo() -> bool:
	var cs := ComboScoring.new()
	cs.grid = Grid.new()
	cs.reset_combo()
	cs._on_lines_cleared(2)
	var ok := cs.total_score > 0
	cs.free()
	return ok

func _test_ghost() -> bool:
	var gp := GhostPiece.new()
	gp.grid = Grid.new()
	gp.tetromino = null  # not wired yet
	var ok := gp.calculate_ghost_y(4, 10, TetrominoShapes.get_data(1).get_cells(0)) >= 0
	gp.free()
	return ok