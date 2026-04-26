# Game State Machine Unit Tests
extends GutTest

var _gs: GameState

func before_each() -> void:
	_gs = GameState.new()

func after_each() -> void:
	_gs.free()

## State enum values
func test_state_enum_values() -> void:
	assert_eq(_gs.State.IDLE, 0, "IDLE = 0")
	assert_eq(_gs.State.PLAYING, 1, "PLAYING = 1")
	assert_eq(_gs.State.PAUSED, 2, "PAUSED = 2")
	assert_eq(_gs.State.GAME_OVER, 3, "GAME_OVER = 3")

## Initial state is IDLE
func test_initial_state_is_idle() -> void:
	assert_eq(_gs.get_state(), _gs.State.IDLE, "Initial state should be IDLE")

## IDLE → PLAYING (valid)
func test_idle_to_playing_valid() -> void:
	assert_true(_gs.change_state(_gs.State.PLAYING), "IDLE→PLAYING should succeed")
	assert_eq(_gs.get_state(), _gs.State.PLAYING, "State should be PLAYING")

## IDLE → PAUSED (invalid)
func test_idle_to_paused_invalid() -> void:
	assert_false(_gs.change_state(_gs.State.PAUSED), "IDLE→PAUSED should fail")
	assert_eq(_gs.get_state(), _gs.State.IDLE, "State should still be IDLE")

## IDLE → GAME_OVER (invalid)
func test_idle_to_game_over_invalid() -> void:
	assert_false(_gs.change_state(_gs.State.GAME_OVER), "IDLE→GAME_OVER should fail")

## PLAYING → PAUSED (valid)
func test_playing_to_paused_valid() -> void:
	_gs.change_state(_gs.State.PLAYING)
	assert_true(_gs.change_state(_gs.State.PAUSED), "PLAYING→PAUSED should succeed")

## PLAYING → GAME_OVER (valid)
func test_playing_to_game_over_valid() -> void:
	_gs.change_state(_gs.State.PLAYING)
	assert_true(_gs.change_state(_gs.State.GAME_OVER), "PLAYING→GAME_OVER should succeed")

## PAUSED → PLAYING (valid)
func test_paused_to_playing_valid() -> void:
	_gs.change_state(_gs.State.PLAYING)
	_gs.change_state(_gs.State.PAUSED)
	assert_true(_gs.change_state(_gs.State.PLAYING), "PAUSED→PLAYING should succeed")

## GAME_OVER → IDLE (valid)
func test_game_over_to_idle_valid() -> void:
	_gs.change_state(_gs.State.PLAYING)
	_gs.change_state(_gs.State.GAME_OVER)
	assert_true(_gs.change_state(_gs.State.IDLE), "GAME_OVER→IDLE should succeed")

## state_changed signal emits on valid transition
func test_state_changed_signal_emits() -> void:
	var t: Array = []
	_gs.state_changed.connect(func(f, to): t.append([f, to]))
	_gs.change_state(_gs.State.PLAYING)
	assert_eq(t.size(), 1, "Should emit once")
	assert_eq(t[0][0], _gs.State.IDLE)
	assert_eq(t[0][1], _gs.State.PLAYING)

## state_changed does NOT emit on invalid transition
func test_no_signal_on_invalid_transition() -> void:
	var count := 0
	_gs.state_changed.connect(func(f, to): count += 1)
	_gs.change_state(_gs.State.PAUSED)
	assert_eq(count, 0, "Should not emit on invalid transition")

## game_over signal emits when entering GAME_OVER
func test_game_over_signal_emits() -> void:
	var count := 0
	_gs.game_over.connect(func(): count += 1)
	_gs.change_state(_gs.State.PLAYING)
	_gs.change_state(_gs.State.GAME_OVER)
	assert_eq(count, 1, "game_over should emit once")

## _on_pause_input toggles PLAYING ↔ PAUSED
func test_pause_toggles_playing_to_paused() -> void:
	_gs.change_state(_gs.State.PLAYING)
	_gs._on_pause_input()
	assert_eq(_gs.get_state(), _gs.State.PAUSED)

func test_pause_toggles_paused_to_playing() -> void:
	_gs.change_state(_gs.State.PLAYING)
	_gs._on_pause_input()
	_gs._on_pause_input()
	assert_eq(_gs.get_state(), _gs.State.PLAYING)

func test_pause_ignored_in_idle() -> void:
	_gs._on_pause_input()
	assert_eq(_gs.get_state(), _gs.State.IDLE)

func test_pause_ignored_in_game_over() -> void:
	_gs.change_state(_gs.State.PLAYING)
	_gs.change_state(_gs.State.GAME_OVER)
	_gs._on_pause_input()
	assert_eq(_gs.get_state(), _gs.State.GAME_OVER)

## start_new_game emits new_game_init and transitions to PLAYING
func test_start_new_game_emits_init() -> void:
	var count := 0
	_gs.new_game_init.connect(func(): count += 1)
	_gs.start_new_game()
	assert_eq(count, 1)
	assert_eq(_gs.get_state(), _gs.State.PLAYING)