# Visual Feedback Unit Tests
# Test evidence for: tests/unit/visual_feedback/vfx_test.gd
# Story: production/epics/visual-feedback-system/story-001-flash-shake.md
# Story: production/epics/visual-feedback-system/story-002-combo-glow.md
# Story: production/epics/visual-feedback-system/story-003-game-over-dim.md
# ADR: ADR-011 (Visual Effects) — Accepted
extends GutTest

var _vfx: VisualFeedback

func before_each() -> void:
	_vfx = VisualFeedback.new()

func after_each() -> void:
	_vfx.free()

## AC-1: flash emits vfx_flash_started signal with color and duration
func test_flash_signal_emitted() -> void:
	var captured_color := Color.BLACK
	var captured_duration := -1
	_vfx.vfx_flash_started.connect(func(c, d): captured_color = c; captured_duration = d)
	_vfx.flash(Color.WHITE, 100)
	assert_eq(captured_color, Color.WHITE, "Flash color should be WHITE")
	assert_eq(captured_duration, 100, "Flash duration should be 100ms")

## AC-1: flash with different color
func test_flash_signal_emitted_with_red() -> void:
	var captured_color := Color.BLACK
	_vfx.vfx_flash_started.connect(func(c, _d): captured_color = c)
	_vfx.flash(Color.RED, 200)
	assert_eq(captured_color, Color.RED, "Flash color should be RED")

## AC-2: shake emits vfx_shake_started signal with magnitude
func test_shake_signal_emitted() -> void:
	var captured_magnitude := -1
	_vfx.vfx_shake_started.connect(func(m): captured_magnitude = m)
	_vfx.shake(8)
	assert_eq(captured_magnitude, 8, "Shake magnitude should be 8px")

## AC-2: shake with different magnitude
func test_shake_signal_emitted_small() -> void:
	var captured_magnitude := -1
	_vfx.vfx_shake_started.connect(func(m): captured_magnitude = m)
	_vfx.shake(2)
	assert_eq(captured_magnitude, 2, "Shake magnitude should be 2px")

## AC-3: combo_glow emits vfx_combo_glow_started signal with combo level
func test_combo_glow_signal_emitted() -> void:
	var captured_level := -1
	_vfx.vfx_combo_glow_started.connect(func(l): captured_level = l)
	_vfx.combo_glow(5)
	assert_eq(captured_level, 5, "Combo level should be 5")

## AC-3: combo_glow with level 2
func test_combo_glow_signal_level_2() -> void:
	var captured_level := -1
	_vfx.vfx_combo_glow_started.connect(func(l): captured_level = l)
	_vfx.combo_glow(2)
	assert_eq(captured_level, 2, "Combo level should be 2")

## AC-4: dim emits vfx_dim_started signal
func test_dim_signal_emitted() -> void:
	var dim_called := false
	_vfx.vfx_dim_started.connect(func(): dim_called = true)
	_vfx.dim()
	assert_true(dim_called, "vfx_dim_started should be emitted")

## AC-4: game_over_effect emits vfx_game_over signal
func test_game_over_effect_signal_emitted() -> void:
	var game_over_called := false
	_vfx.vfx_game_over.connect(func(): game_over_called = true)
	_vfx.game_over_effect()
	assert_true(game_over_called, "vfx_game_over should be emitted")