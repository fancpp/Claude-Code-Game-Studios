# Combo Scoring System Unit Tests
extends GutTest

var _combo: ComboScoring
var _grid: Grid

func before_each() -> void:
	_grid = Grid.new()
	_combo = ComboScoring.new()
	_combo.grid = _grid


func after_each() -> void:
	_combo.free()
	_grid.free()


## AC-2: Single at combo 0 = 100 points
func test_single_line_score() -> void:
	var score_earned := 0
	_combo.score_changed.connect(func(s): score_earned = s)

	_combo._on_lines_cleared(1)
	assert_eq(score_earned, 100, "Single at combo 0 should earn 100 points")


## AC-3: Double at combo 2 = 1200 points
func test_double_line_score() -> void:
	_combo.combo_counter = 2
	var score_earned := 0
	_combo.score_changed.connect(func(s): score_earned = s)

	_combo._on_lines_cleared(2)
	assert_eq(score_earned, 1200, "Double at combo 2 should earn 1200 points")


## AC-4 partial: Tetris at combo 4 = 12800
func test_tetris_at_combo_4() -> void:
	_combo.combo_counter = 4
	var score_earned := 0
	_combo.score_changed.connect(func(s): score_earned = s)

	_combo._on_lines_cleared(4)
	assert_eq(score_earned, 12800, "Tetris at combo 4 should earn 12800 points")


## AC-5: Combo 100+ uses multiplier 5x
func test_combo_multiplier_capped_at_5() -> void:
	_combo.combo_counter = 100
	var multiplier := _combo._get_combo_multiplier(100)
	assert_eq(multiplier, 5, "Multiplier should be capped at 5")


## Test combo counter increments after line clear
func test_combo_counter_increments() -> void:
	assert_eq(_combo.combo_counter, 0, "Initial combo should be 0")
	_combo._on_lines_cleared(1)
	assert_eq(_combo.combo_counter, 1, "Combo should increment to 1")


## Test combo x2 signal at 2 lines cleared (combo reaches 2)
func test_combo_x2_signal_at_2_lines() -> void:
	_combo.combo_counter = 1
	var combo_reached: int = 0
	_combo.combo_changed.connect(func(c, m): combo_reached = c)

	_combo._on_lines_cleared(1)
	assert_eq(combo_reached, 2, "Combo should reach 2")


## Test combo x3 signal at 3 lines cleared (combo reaches 3)
func test_combo_x3_signal_at_3_lines() -> void:
	_combo.combo_counter = 2
	var combo_reached: int = 0
	_combo.combo_changed.connect(func(c, m): combo_reached = c)

	_combo._on_lines_cleared(1)
	assert_eq(combo_reached, 3, "Combo should reach 3")


## Test combo x5 signal fires at combo 5
func test_combo_x5_signal_at_5_lines() -> void:
	_combo.combo_counter = 4
	var x5_fired := false
	_combo.combo_x5.connect(func(): x5_fired = true)

	_combo._on_lines_cleared(1)
	assert_true(x5_fired, "combo_x5 signal should fire when combo reaches 5")


## Test combo_x5 only fires once per game
func test_combo_x5_fires_once() -> void:
	_combo.combo_counter = 4
	_combo._has_reached_x5_this_game = true  # already reached x5

	var x5_fired := false
	_combo.combo_x5.connect(func(): x5_fired = true)

	_combo._on_lines_cleared(1)
	assert_false(x5_fired, "combo_x5 should not fire again after first reach")


## Test reset_combo sets counter to 0
func test_reset_combo() -> void:
	_combo.combo_counter = 5
	_combo.reset_combo()
	assert_eq(_combo.combo_counter, 0, "Combo should reset to 0")


## Test new game resets combo and score
func test_new_game_resets_state() -> void:
	_combo.combo_counter = 5
	_combo.total_score = 5000

	_combo._on_new_game()
	assert_eq(_combo.combo_counter, 0, "Combo should reset to 0 on new game")
	assert_eq(_combo.total_score, 0, "Score should reset to 0 on new game")
	assert_false(_combo._has_reached_x5_this_game, "_has_reached_x5_this_game should reset")


## Test hard drop score bonus
func test_hard_drop_score_bonus() -> void:
	var score := 0
	_combo.score_changed.connect(func(s): score = s)

	_combo.add_hard_drop_score(10)
	assert_eq(score, 20, "Hard drop 10 cells = 20 points")


## Test soft drop score bonus
func test_soft_drop_score_bonus() -> void:
	var score := 0
	_combo.score_changed.connect(func(s): score = s)

	_combo.add_soft_drop_score(15)
	assert_eq(score, 15, "Soft drop 15 cells = 15 points")


## Test zero-line lock resets combo
func test_zero_line_lock_resets_combo() -> void:
	_combo.combo_counter = 3
	_combo._on_lines_cleared(0)  # zero lines
	assert_eq(_combo.combo_counter, 0, "Combo should reset on zero-line lock")


## Test score with level formula
func test_score_includes_level_multiplier() -> void:
	# Score = base * lines * combo_multiplier
	# Double at combo 0: 300 * 2 * 1 = 600
	_combo.combo_counter = 0
	var score := 0
	_combo.score_changed.connect(func(s): score = s)

	_combo._on_lines_cleared(2)
	assert_eq(score, 600, "Double at combo 0 should be 600")


## Test combo_changed emits correct counter and multiplier
func test_combo_changed_emits_counter_and_multiplier() -> void:
	_combo.combo_counter = 2
	var emitted_counter: int = 0
	var emitted_multiplier: int = 0
	_combo.combo_changed.connect(func(c, m):
		emitted_counter = c
		emitted_multiplier = m
	)

	_combo._on_lines_cleared(1)
	assert_eq(emitted_counter, 3, "Counter should be 3 after clear")
	assert_eq(emitted_multiplier, 3, "Multiplier should be 3")