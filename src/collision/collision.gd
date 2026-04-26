class_name Collision
extends Node
## Collision detection + lock delay timer.
## Receives grid via @export var grid: Grid (injected by main.gd).
## Provides can_move_to() for movement validation and manages lock delay.

@export var grid: Grid

## Lock delay
signal lock_delay_expired  ## Fired when 500ms lock delay timer expires

var _lock_delay_ms: int = 0
var _lock_delay_active: bool = false
const LOCK_DELAY_MS: int = 500

## Wall kick offsets (SRS standard, per TR-collision-003)
const WALL_KICK_OFFSETS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-2, 0), Vector2i(2, 0)
]

func _ready() -> void:
	assert(grid != null, "Collision: grid not wired")

## Returns true if the tetromino shape can occupy (tx, ty) in the grid.
## shape: 4×4 bool grid from TetrominoShapes (local coords).
## Checks each occupied cell against grid bounds + occupancy.
func can_move_to(tx: int, ty: int, shape: Array) -> bool:
	for row in range(4):
		for col in range(4):
			if not shape[row][col]:
				continue
			var cx := tx + col
			var cy := ty + row
			if not grid.is_valid_position(cx, cy):
				return false
			if not grid.is_empty(cx, cy):
				return false
	return true

## Returns true if grid cell (x, y) is occupied (not empty and in bounds).
func is_occupied(x: int, y: int) -> bool:
	if not grid.is_valid_position(x, y):
		return false
	return not grid.is_empty(x, y)

## Start lock delay timer — called when piece is blocked below.
func start_lock_delay() -> void:
	_lock_delay_ms = 0
	_lock_delay_active = true

## Cancel lock delay — called on successful piece movement.
func cancel_lock_delay() -> void:
	_lock_delay_ms = 0
	_lock_delay_active = false

## Reset lock delay state (e.g., on piece hard drop).
func reset_lock_delay() -> void:
	_lock_delay_ms = 0
	_lock_delay_active = false

## Returns wall kick offsets to try in order.
func get_wall_kick_offsets() -> Array:
	return WALL_KICK_OFFSETS

## Process lock delay each frame. dt is delta time in seconds.
func _process(delta: float) -> void:
	if not _lock_delay_active:
		return
	_lock_delay_ms += int(delta * 1000.0)
	if _lock_delay_ms >= LOCK_DELAY_MS:
		_lock_delay_active = false
		lock_delay_expired.emit()

## Returns current lock delay state.
func is_lock_delay_active() -> bool:
	return _lock_delay_active

## Returns true if piece at (x, y) with given shape is blocked immediately below.
func is_blocked_below(x: int, y: int, shape: Array) -> bool:
	return not can_move_to(x, y - 1, shape)