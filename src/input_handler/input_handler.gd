class_name InputHandler
extends Node
## Input handler stub — receives no grid (Foundation layer, input only).
## Handles DAS for Move Left/Right/Soft Drop and immediate signals for others.
## Full implementation in Story 001/002/003 — stubs here for scene tree completeness.

signal move_left
signal move_right
signal soft_drop
signal hard_drop
signal rotate_cw
signal rotate_ccw
signal pause

const DAS_INITIAL_DELAY_MS := 170
const DAS_REPEAT_RATE_MS := 50

var _key_left_held: bool = false
var _key_right_held: bool = false
var _key_soft_drop_held: bool = false

var _das_left_time_ms: int = 0
var _das_left_repeat_count: int = 0
var _das_left_initial_fired: bool = false

var _das_right_time_ms: int = 0
var _das_right_repeat_count: int = 0
var _das_right_initial_fired: bool = false

var _das_soft_drop_time_ms: int = 0
var _das_soft_drop_repeat_count: int = 0
var _das_soft_drop_initial_fired: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	## DAS implementation — full logic in Story 002 and 003.
	var dt_ms := int(delta * 1000.0)

	if _key_left_held and _key_right_held:
		_das_left_time_ms = 0
		_das_left_repeat_count = 0
		_das_left_initial_fired = false
		_das_right_time_ms = 0
		_das_right_repeat_count = 0
		_das_right_initial_fired = false
		return

	if _key_left_held:
		_das_left_time_ms += dt_ms
		if not _das_left_initial_fired:
			if _das_left_time_ms >= DAS_INITIAL_DELAY_MS:
				emit_signal("move_left")
				_das_left_initial_fired = true
				_das_left_repeat_count = 1
		else:
			var elapsed := _das_left_time_ms - DAS_INITIAL_DELAY_MS
			var expected := elapsed / DAS_REPEAT_RATE_MS
			if _das_left_repeat_count <= expected:
				emit_signal("move_left")
				_das_left_repeat_count += 1

	if _key_right_held:
		_das_right_time_ms += dt_ms
		if not _das_right_initial_fired:
			if _das_right_time_ms >= DAS_INITIAL_DELAY_MS:
				emit_signal("move_right")
				_das_right_initial_fired = true
				_das_right_repeat_count = 1
		else:
			var elapsed := _das_right_time_ms - DAS_INITIAL_DELAY_MS
			var expected := elapsed / DAS_REPEAT_RATE_MS
			if _das_right_repeat_count <= expected:
				emit_signal("move_right")
				_das_right_repeat_count += 1

	if _key_soft_drop_held:
		_das_soft_drop_time_ms += dt_ms
		if not _das_soft_drop_initial_fired:
			if _das_soft_drop_time_ms >= DAS_INITIAL_DELAY_MS:
				emit_signal("soft_drop")
				_das_soft_drop_initial_fired = true
				_das_soft_drop_repeat_count = 1
		else:
			var elapsed := _das_soft_drop_time_ms - DAS_INITIAL_DELAY_MS
			var expected := elapsed / DAS_REPEAT_RATE_MS
			if _das_soft_drop_repeat_count <= expected:
				emit_signal("soft_drop")
				_das_soft_drop_repeat_count += 1

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		_key_left_held = true
	if event.is_action_released("move_left"):
		_key_left_held = false
		_das_left_time_ms = 0
		_das_left_repeat_count = 0
		_das_left_initial_fired = false
	if event.is_action_pressed("move_right"):
		_key_right_held = true
	if event.is_action_released("move_right"):
		_key_right_held = false
		_das_right_time_ms = 0
		_das_right_repeat_count = 0
		_das_right_initial_fired = false
	if event.is_action_pressed("soft_drop"):
		_key_soft_drop_held = true
	if event.is_action_released("soft_drop"):
		_key_soft_drop_held = false
		_das_soft_drop_time_ms = 0
		_das_soft_drop_repeat_count = 0
		_das_soft_drop_initial_fired = false
	if event.is_action_pressed("hard_drop"):
		emit_signal("hard_drop")
	if event.is_action_pressed("rotate_cw"):
		emit_signal("rotate_cw")
	if event.is_action_pressed("rotate_ccw"):
		emit_signal("rotate_ccw")
	if event.is_action_pressed("pause"):
		emit_signal("pause")