# Score Display Unit Tests
# Test evidence for: tests/unit/score_display/score_display_test.gd
# Story: production/epics/score-display-system/story-001-score-level-display.md
# Story: production/epics/score-display-system/story-002-combo-display.md
# ADR: ADR-009 (Score Display) — Accepted
extends GutTest

var _score_display: ScoreDisplay

func before_each() -> void:
	_score_display = ScoreDisplay.new()

func after_each() -> void:
	_score_display.free()

## AC-1: score 1250 displays as "001250"
func test_update_score() -> void:
	var captured_score := -1
	var captured_level := -1
	_score_display.score_updated.connect(func(s, l): captured_score = s; captured_level = l)
	_score_display.update_score(1250, 1)
	assert_eq(captured_score, 1250, "Score should be 1250")
	assert_eq(_score_display.get_formatted_score(), "001250", "Score should be formatted as 001250")

## AC-1: score 0 displays as "000000"
func test_update_score_zero() -> void:
	_score_display.update_score(0, 1)
	assert_eq(_score_display.get_formatted_score(), "000000", "Zero score should be 000000")

## AC-2: score 1000000 displays as "999999+"
func test_update_score_overflow() -> void:
	_score_display.update_score(1000000, 1)
	assert_eq(_score_display.get_formatted_score(), "999999+", "Overflow score should be 999999+")

## AC-3: combo counter 0 is hidden
func test_update_combo_counter_zero_hidden() -> void:
	var captured_combo := -1
	_score_display.combo_display_updated.connect(func(c): captured_combo = c)
	_score_display.update_combo(0)
	assert_eq(captured_combo, 0, "Combo should be 0")
	assert_false(_score_display.is_combo_visible(), "Combo should be hidden when 0")

## AC-4: combo counter 3 displays as "x3"
func test_update_combo_counter_three() -> void:
	var captured_combo := -1
	_score_display.combo_display_updated.connect(func(c): captured_combo = c)
	_score_display.update_combo(3)
	assert_eq(captured_combo, 3, "Combo should be 3")
	assert_true(_score_display.is_combo_visible(), "Combo should be visible when > 0")
	assert_eq(_score_display.get_formatted_combo(), "x3", "Combo should be formatted as x3")

## AC-5: level displays as "LV N"
func test_update_level() -> void:
	var captured_level := -1
	_score_display.level_display_updated.connect(func(l): captured_level = l)
	_score_display.update_level(6)
	assert_eq(captured_level, 6, "Level should be 6")
	assert_eq(_score_display.get_formatted_level(), "LV 6", "Level should be formatted as LV 6")

## AC-5: level 1 displays as "LV 1"
func test_update_level_one() -> void:
	_score_display.update_level(1)
	assert_eq(_score_display.get_formatted_level(), "LV 1", "Level 1 should be LV 1")

## AC-6: reset clears all values
func test_reset_clears_all() -> void:
	_score_display.update_score(12500, 5)
	_score_display.update_combo(3)
	_score_display.update_level(5)
	_score_display.reset()
	assert_eq(_score_display.get_formatted_score(), "000000", "Score should be reset to 000000")
	assert_eq(_score_display.get_formatted_level(), "LV 1", "Level should be reset to LV 1")
	assert_eq(_score_display.get_formatted_combo(), "", "Combo should be reset to empty")
	assert_false(_score_display.is_combo_visible(), "Combo should be hidden after reset")