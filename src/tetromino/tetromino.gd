class_name Tetromino
extends Node
## Active tetromino piece — position, rotation, lock delay, movement.
## Reads shape data from TetrominoShapes (ADR-004).
## Validates moves via Collision.can_move_to before committing.
## Emits signals for piece_locked, piece_hard_dropped.

@export var collision: Node  # Collision system node — set by main.gd wiring
@export var grid: Grid        # Grid ref — set by main.gd wiring

## Public state
var piece_type: int = 0       # 1-7
var position: Vector2i = Vector2i.ZERO  # grid coords (x, y)
var rotation_state: int = 0   # 0-3 (SRS rotation state)

## Signals
signal piece_locked
signal piece_hard_dropped(drop_distance: int)
signal piece_moved  # used by ghost_piece to recalculate

## Lock delay state
var _lock_delay_ms: int = 0
var _lock_delay_active: bool = false
const LOCK_DELAY_MS: int = 500

## Wall kick offsets (SRS standard, per collision ADR-003)
const WALL_KICK_OFFSETS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-2, 0), Vector2i(2, 0)
]

## Spawn position
const SPAWN_X: int = 4
const SPAWN_Y: int = 19

func _ready() -> void:
	assert(collision != null, "Tetromino: collision not wired")
	assert(grid != null, "Tetromino: grid not wired")

## Activate a piece of the given type at spawn position.
func activate(type: int) -> void:
	piece_type = type
	position = Vector2i(SPAWN_X, SPAWN_Y)
	rotation_state = 0
	_lock_delay_ms = 0
	_lock_delay_active = false

## Returns world-space occupied cells for current piece.
func get_world_cells() -> Array:
	var local = TetrominoShapes.get_data(piece_type).get_cells(rotation_state)
	return local.map(func(c: Vector2i) -> Vector2i:
		return Vector2i(position.x + c.x, position.y + c.y))

## Returns current 4×4 occupancy grid.
func get_current_grid() -> Array:
	return TetrominoShapes.get_data(piece_type).rotation_grids[rotation_state]

## Movement — returns true if move was valid and committed.
func move_left() -> bool:
	return _try_move(Vector2i.LEFT)

func move_right() -> bool:
	return _try_move(Vector2i.RIGHT)

func move_down() -> bool:
	return _try_move(Vector2i.DOWN)

func _try_move(delta: Vector2i) -> bool:
	if collision.can_move_to(position + delta, get_current_grid()):
		position += delta
		_reset_lock_delay()
		piece_moved.emit()
		return true
	return false

## Rotation with SRS wall kicks. Returns true if rotation succeeded.
func rotate_cw() -> bool:
	return _try_rotation((rotation_state + 1) % 4)

func rotate_ccw() -> bool:
	return _try_rotation((rotation_state + 3) % 4)  # -1 mod 4

func _try_rotation(new_rotation: int) -> bool:
	var old_rotation = rotation_state
	var old_position = position
	rotation_state = new_rotation

	# Test each wall kick offset
	for kick in WALL_KICK_OFFSETS:
		var try_pos = position + kick
		if collision.can_move_to(try_pos, get_current_grid()):
			position = try_pos
			_reset_lock_delay()
			piece_moved.emit()
			return true

	# All kicks failed — revert
	rotation_state = old_rotation
	position = old_position
	return false

## Hard drop: drop to lowest valid position and lock immediately.
func hard_drop() -> void:
	var distance := 0
	while collision.can_move_to(position + Vector2i(0, -1), get_current_grid()):
		position += Vector2i(0, -1)
		distance += 1
	_lock_delay_ms = 0
	_lock_delay_active = false
	_lock_piece_to_grid()
	piece_hard_dropped.emit(distance)

## Soft drop: move down one row.
func soft_drop() -> bool:
	return move_down()

## Called by Collision when piece is blocked below — starts lock delay.
func start_lock_delay() -> void:
	_lock_delay_active = true

## Called by Collision on successful move — resets lock delay.
func _reset_lock_delay() -> void:
	_lock_delay_ms = 0
	_lock_delay_active = false

## Called each frame when lock delay is active.
func _process_lock_delay(dt_ms: int) -> void:
	if not _lock_delay_active:
		return
	_lock_delay_ms += dt_ms
	if _lock_delay_ms >= LOCK_DELAY_MS:
		_lock_delay_active = false
		_lock_piece_to_grid()

## Lock piece into grid and emit piece_locked.
func _lock_piece_to_grid() -> void:
	for cell in get_world_cells():
		grid.set_cell(cell.x, cell.y, piece_type)
	piece_locked.emit()

## Returns true if piece is in locking state (blocked below, timer running).
func is_locking() -> bool:
	return _lock_delay_active