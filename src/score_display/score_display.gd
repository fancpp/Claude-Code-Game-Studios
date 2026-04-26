class_name ScoreDisplay
extends Node

## Score display UI presentation layer.
## Subscribes to combo_scoring and speed_progression signals per ADR-009.
## Tracks score/level/combo values and emits signals for observation.

signal score_updated(new_score: int, new_level: int)
signal combo_display_updated(new_combo: int)
signal level_display_updated(new_level: int)

## Constants
const SCORE_PADDING := 6
const COMBO_VISIBLE_THRESHOLD := 1
const SCORE_OVERFLOW_DISPLAY := "999999+"

## Internal state
var _score: int = 0
var _level: int = 1
var _combo: int = 0

func _ready() -> void:
	# Signal connections will be made by consumers in their _ready() per ADR-002
	# (this node doesn't know its signal sources at implementation time)
	pass

## Update score display.
## [param score] The new score value.
## [param level] The current level for display purposes.
func update_score(score: int, level: int) -> void:
	_score = score
	_level = level
	emit_signal("score_updated", _score, _level)

## Update combo display.
## [param combo] The new combo counter value.
func update_combo(combo: int) -> void:
	_combo = combo
	emit_signal("combo_display_updated", _combo)

## Update level display.
## [param level] The new level value.
func update_level(level: int) -> void:
	_level = level
	emit_signal("level_display_updated", _level)

## Reset all displays to initial values.
func _on_game_over() -> void:
	## Stub: game over state — display frozen.
	## Actual visual effect handled by visual_feedback._on_game_over().
	pass

func reset() -> void:
	_score = 0
	_level = 1
	_combo = 0
	emit_signal("score_updated", _score, _level)
	emit_signal("combo_display_updated", _combo)
	emit_signal("level_display_updated", _level)

## Get formatted score string (6-digit zero-padded).
func get_formatted_score() -> String:
	if _score > 999999:
		return SCORE_OVERFLOW_DISPLAY
	return str(_score).lpad(SCORE_PADDING, "0")

## Get formatted level string ("LV N").
func get_formatted_level() -> String:
	return "LV %d" % _level

## Get formatted combo string ("xN") or empty if hidden.
func get_formatted_combo() -> String:
	if _combo < COMBO_VISIBLE_THRESHOLD:
		return ""
	return "x%d" % _combo

## Check if combo should be visible.
func is_combo_visible() -> bool:
	return _combo >= COMBO_VISIBLE_THRESHOLD