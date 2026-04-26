class_name GameState
extends Node
## Game state machine — 4 states, valid transitions, game over detection.
## Connects to: input_handler.pause, piece_spawn.spawn_failed.
## Emits: state_changed, game_over, new_game_init.

enum State { IDLE = 0, PLAYING = 1, PAUSED = 2, GAME_OVER = 3 }

signal state_changed(from: State, to: State)
signal game_over
signal new_game_init  ## Emitted on new game start — consumed by Grid, ScoreDisplay, etc.

var current_state: State = State.IDLE

## Connect to input_handler.pause signal. Called by main.gd wiring.
func _on_pause_input() -> void:
	match current_state:
		State.PLAYING:
			change_state(State.PAUSED)
		State.PAUSED:
			change_state(State.PLAYING)

## Connect to piece_spawn.spawn_failed. Called by main.gd wiring.
func _on_spawn_failed() -> void:
	change_state(State.GAME_OVER)

## Change to IDLE state and emit new_game_init. Called externally on new game.
func start_idle() -> void:
	change_state(State.IDLE)

## Start a new game: transition to PLAYING and emit new_game_init.
func start_new_game() -> void:
	_change_to_unsafe(State.PLAYING)
	new_game_init.emit()

## Change state with validation. Returns true if transition was valid.
func change_state(to: State) -> bool:
	var from = current_state
	if not _is_valid_transition(from, to):
		return false
	_change_to_unsafe(to)
	state_changed.emit(from, to)
	return true

## Internal: change state without transition validation (used for forced transitions).
func _change_to_unsafe(to: State) -> void:
	current_state = to
	if to == State.GAME_OVER:
		game_over.emit()

## Returns true if transition from -> to is allowed.
func _is_valid_transition(from: State, to: State) -> bool:
	match from:
		State.IDLE:
			return to == State.PLAYING
		State.PLAYING:
			return to == State.PAUSED or to == State.GAME_OVER
		State.PAUSED:
			return to == State.PLAYING or to == State.GAME_OVER
		State.GAME_OVER:
			return to == State.IDLE
	return false

## Returns current state.
func get_state() -> State:
	return current_state

## Returns human-readable state name.
func get_state_name() -> String:
	match current_state:
		State.IDLE: return "IDLE"
		State.PLAYING: return "PLAYING"
		State.PAUSED: return "PAUSED"
		State.GAME_OVER: return "GAME_OVER"
	return "UNKNOWN"