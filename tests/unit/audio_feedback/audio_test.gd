# Audio Feedback Unit Tests
# Test evidence for: tests/unit/audio_feedback/audio_test.gd
# Story: production/epics/audio-feedback-system/story-001-sfx-playback.md
# Story: production/epics/audio-feedback-system/story-002-volume-pitch.md
# ADR: ADR-008 (Audio Architecture) — Accepted
extends GutTest

var _audio: AudioFeedback

func before_each() -> void:
	_audio = AudioFeedback.new()

func after_each() -> void:
	_audio.free()

## AC-1: play_sfx emits sfx_played signal
func test_play_sfx_emits_signal() -> void:
	var captured_sfx := ""
	_audio.sfx_played.connect(func(name): captured_sfx = name)
	_audio.play_sfx("line_clear")
	assert_eq(captured_sfx, "line_clear", "SFX name should be emitted")

## AC-1: play_sfx with different sound names
func test_play_sfx_move() -> void:
	var captured_sfx := ""
	_audio.sfx_played.connect(func(name): captured_sfx = name)
	_audio.play_sfx("move")
	assert_eq(captured_sfx, "move", "SFX name should be move")

func test_play_sfx_hard_drop() -> void:
	var captured_sfx := ""
	_audio.sfx_played.connect(func(name): captured_sfx = name)
	_audio.play_sfx("hard_drop")
	assert_eq(captured_sfx, "hard_drop", "SFX name should be hard_drop")

func test_play_sfx_game_over() -> void:
	var captured_sfx := ""
	_audio.sfx_played.connect(func(name): captured_sfx = name)
	_audio.play_sfx("game_over")
	assert_eq(captured_sfx, "game_over", "SFX name should be game_over")

## AC-7: set_sfx_enabled(false) prevents play_sfx from emitting
func test_play_sfx_disabled_no_signal() -> void:
	var signal_received := false
	_audio.sfx_played.connect(func(_name): signal_received = true)
	_audio.set_sfx_enabled(false)
	_audio.play_sfx("line_clear")
	assert_false(signal_received, "No signal should be emitted when disabled")

## AC-8: set_volume changes volume_db
func test_set_volume() -> void:
	var captured_vol := 0.0
	_audio.volume_changed.connect(func(v): captured_vol = v)
	_audio.set_volume(-6.0)
	assert_eq(captured_vol, -6.0, "Volume should be -6.0 dB")

## AC-8: set_volume with different values
func test_set_volume_zero() -> void:
	var captured_vol := 1.0
	_audio.volume_changed.connect(func(v): captured_vol = v)
	_audio.set_volume(0.0)
	assert_eq(captured_vol, 0.0, "Volume should be 0.0 dB")

## AC-8: set_pitch changes pitch
func test_set_pitch() -> void:
	var captured_pitch := 1.0
	_audio.pitch_changed.connect(func(p): captured_pitch = p)
	_audio.set_pitch(1.5)
	assert_eq(captured_pitch, 1.5, "Pitch should be 1.5")

## AC-8: set_pitch with different values
func test_set_pitch_variation() -> void:
	var captured_pitch := 1.0
	_audio.pitch_changed.connect(func(p): captured_pitch = p)
	_audio.set_pitch(0.98)
	assert_eq(captured_pitch, 0.98, "Pitch should be 0.98")

## Test valid SFX names
func test_sfx_names_valid() -> void:
	var valid_names := _audio.get_valid_sfx_names()
	assert_true(valid_names.has("move"), "move should be a valid SFX name")
	assert_true(valid_names.has("rotate"), "rotate should be a valid SFX name")
	assert_true(valid_names.has("soft_drop"), "soft_drop should be a valid SFX name")
	assert_true(valid_names.has("hard_drop"), "hard_drop should be a valid SFX name")
	assert_true(valid_names.has("line_clear"), "line_clear should be a valid SFX name")
	assert_true(valid_names.has("combo_x2"), "combo_x2 should be a valid SFX name")
	assert_true(valid_names.has("combo_x3"), "combo_x3 should be a valid SFX name")
	assert_true(valid_names.has("combo_x4"), "combo_x4 should be a valid SFX name")
	assert_true(valid_names.has("combo_x5"), "combo_x5 should be a valid SFX name")
	assert_true(valid_names.has("level_up"), "level_up should be a valid SFX name")
	assert_true(valid_names.has("game_over"), "game_over should be a valid SFX name")
	assert_eq(valid_names.size(), 11, "Should have exactly 11 SFX names")

## Test is_valid_sfx
func test_is_valid_sfx() -> void:
	assert_true(_audio.is_valid_sfx("move"), "move should be valid")
	assert_true(_audio.is_valid_sfx("line_clear"), "line_clear should be valid")
	assert_false(_audio.is_valid_sfx("invalid_sound"), "invalid_sound should not be valid")
	assert_false(_audio.is_valid_sfx(""), "empty string should not be valid")

## Test re-enabling SFX after disable
func test_sfx_re_enable() -> void:
	var signal_count := 0
	_audio.sfx_played.connect(func(_name): signal_count += 1)
	_audio.set_sfx_enabled(false)
	_audio.play_sfx("line_clear")
	assert_eq(signal_count, 0, "No signal when disabled")
	_audio.set_sfx_enabled(true)
	_audio.play_sfx("line_clear")
	assert_eq(signal_count, 1, "Signal should emit after re-enable")