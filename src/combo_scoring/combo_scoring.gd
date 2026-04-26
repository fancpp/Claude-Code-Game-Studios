class_name ComboScoring
extends Node
## Combo Scoring System — tracks combo counter, calculates score, emits signals.
## Subscribes to line_clear.lines_cleared and game_state.new_game signals.
## Emits score_changed, combo_changed, combo_x5 signals to downstream.

@export var grid: Grid

# Signals
signal combo_changed(counter: int, multiplier: int)
signal combo_x5()
signal score_changed(new_score: int)
signal lines_cleared_received(count: int)

# Constants
const MAX_COMBO_MULTIPLIER: int = 5
const SOFT_DROP_POINTS_PER_CELL: int = 1
const HARD_DROP_POINTS_PER_CELL: int = 2
const BASE_POINTS: Array[int] = [0, 100, 300, 500, 800]  # index = line count

# State
var combo_counter: int = 0
var total_score: int = 0
var _has_reached_x5_this_game: bool = false

# References for signal connections
var _line_clear: Node
var _game_state: Node

func _ready() -> void:
	assert(grid != null, "ComboScoring: grid not wired")


## Connect to line_clear.lines_cleared signal.
## Call this after both nodes are available in the scene tree.
func connect_to_line_clear(line_clear_node: Node) -> void:
	_line_clear = line_clear_node
	if _line_clear.has_signal("lines_cleared"):
		_line_clear.lines_cleared.connect(_on_lines_cleared)


## Connect to game_state.new_game_init signal.
## Call this after both nodes are available in the scene tree.
func connect_to_game_state(game_state_node: Node) -> void:
	_game_state = game_state_node
	if _game_state.has_signal("new_game_init"):
		_game_state.new_game_init.connect(_on_new_game)


## Handle lines_cleared signal — increment combo and calculate score.
func _on_lines_cleared(count: int) -> void:
	lines_cleared_received.emit(count)
	if count > 0:
		var old_multiplier := _get_combo_multiplier(combo_counter)
		var earned := _calculate_line_score(count, combo_counter)
		total_score += earned
		combo_counter += 1

		var new_multiplier := _get_combo_multiplier(combo_counter)

		score_changed.emit(total_score)
		combo_changed.emit(combo_counter, new_multiplier)

		# Fire combo_x5 only the first time multiplier reaches 5
		if new_multiplier == MAX_COMBO_MULTIPLIER and not _has_reached_x5_this_game:
			_has_reached_x5_this_game = true
			combo_x5.emit()
	else:
		# Zero-line lock — reset combo
		_reset_combo_internal()


## Reset combo counter (e.g., when piece locks with 0 lines).
func reset_combo() -> void:
	_reset_combo_internal()


## Internal combo reset without emitting signal.
func _reset_combo_internal() -> void:
	combo_counter = 0


## Reset all state on new game.
func _on_new_game() -> void:
	combo_counter = 0
	total_score = 0
	_has_reached_x5_this_game = false

func _on_game_over() -> void:
	## Stub: game over — scoring system freezes.
	pass


## Add soft drop score bonus.
func add_soft_drop_score(distance: int) -> void:
	if distance > 0:
		total_score += distance * SOFT_DROP_POINTS_PER_CELL
		score_changed.emit(total_score)


## Add hard drop score bonus.
func add_hard_drop_score(distance: int) -> void:
	if distance > 0:
		total_score += distance * HARD_DROP_POINTS_PER_CELL
		score_changed.emit(total_score)


## Returns the combo multiplier capped at MAX_COMBO_MULTIPLIER.
func _get_combo_multiplier(counter: int) -> int:
	return mini(counter, MAX_COMBO_MULTIPLIER)


## Calculate score for a line clear event.
## Uses combo counter BEFORE increment for this clear.
func _calculate_line_score(lines: int, combo_counter_value: int) -> int:
	var base := BASE_POINTS[lines] if lines < BASE_POINTS.size() else 0
	var multiplier := _get_combo_multiplier(combo_counter_value)
	return base * lines * multiplier