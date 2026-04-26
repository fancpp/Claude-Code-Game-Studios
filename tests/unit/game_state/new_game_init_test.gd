# New Game Initialization Unit Tests — Story 004
# Tests: start_new_game, new_game_init signal emission, state transitions
extends GutTest

var _game_state: GameState
var _grid: Grid

func before_each() -> void:
	_game_state = GameState.new()
	_grid = Grid.new()

func after_each() -> void:
	_game_state.free()
	_grid.free()

## Test: start_new_game emits new_game_init signal
func test_start_new_game_emits_new_game_init() -> void:
	# Given: GameState in IDLE, new_game_init signal connected
	var signal_received := false
	_game_state.connect("new_game_init", Callable(self, "_on_new_game_init").bind(signal_received))

	# When: starting new game
	_game_state.start_new_game()

	# Then: new_game_init signal was emitted
	assert_true(signal_received, "new_game_init signal should be emitted")

func _on_new_game_init() -> void:
	pass

## Test: start_new_game transitions to PLAYING from IDLE
func test_start_new_game_transitions_to_playing_from_idle() -> void:
	# Given: GameState in IDLE
	# When: starting new game
	_game_state.start_new_game()
	# Then: state is PLAYING
	assert_eq(_game_state.current_state, GameState.State.PLAYING, "Should transition to PLAYING")

## Test: start_new_game transitions to PLAYING from GAME_OVER
func test_start_new_game_transitions_to_playing_from_game_over() -> void:
	# Given: GameState in GAME_OVER
	_game_state.current_state = GameState.State.GAME_OVER
	# When: starting new game
	_game_state.start_new_game()
	# Then: state is PLAYING
	assert_eq(_game_state.current_state, GameState.State.PLAYING, "Should transition to PLAYING from GAME_OVER")

## Test: start_new_game does nothing during PLAYING
func test_start_new_game_no_op_during_playing() -> void:
	# Given: GameState in PLAYING
	_game_state.current_state = GameState.State.PLAYING
	var previous_state := _game_state.current_state
	# When: starting new game during PLAYING
	_game_state.start_new_game()
	# Then: state unchanged
	assert_eq(_game_state.current_state, previous_state, "Should be no-op during PLAYING")

## Test: start_new_game does nothing during PAUSED
func test_start_new_game_no_op_during_paused() -> void:
	# Given: GameState in PAUSED
	_game_state.current_state = GameState.State.PAUSED
	var previous_state := _game_state.current_state
	# When: starting new game during PAUSED
	_game_state.start_new_game()
	# Then: state unchanged
	assert_eq(_game_state.current_state, previous_state, "Should be no-op during PAUSED")

## Test: state_changed signal is emitted after start_new_game
func test_start_new_game_emits_state_changed() -> void:
	# Given: GameState in IDLE, state_changed signal connected
	var signal_emitted := false
	var from := -1
	var to := -1
	_game_state.connect("state_changed", Callable(self, "_on_state_changed_collector").bind(signal_emitted, from, to))

	# When: starting new game
	_game_state.start_new_game()

	# Then: signal was emitted with correct states
	assert_true(signal_emitted, "state_changed should be emitted")
	assert_eq(from, GameState.State.IDLE, "from state should be IDLE")
	assert_eq(to, GameState.State.PLAYING, "to state should be PLAYING")

func _on_state_changed_collector(f, t, was_emit, from_ref, to_ref) -> void:
	was_emit.set(true)
	from_ref.set(f)
	to_ref.set(t)