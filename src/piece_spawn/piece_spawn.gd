class_name PieceSpawn
extends Node
## Piece spawner — manages 7-bag randomizer and spawns pieces at grid center.
## Spawn position: x=4, y=19 (top-center of 10×20 grid).
## Emits piece_spawned(type) on success, spawn_failed on game-over trigger.

@export var grid: Grid
@export var tetromino: Node  # Tetromino system — set by main.gd wiring

signal piece_spawned(piece_type: int)
signal spawn_failed    # emitted when spawn cell is occupied → game over
signal next_piece_updated(next_type: int)  # for UI preview

var _bag: PieceBag
var _current_piece_type: int = 0
var _next_piece_type: int = 0

const SPAWN_X: int = 4
const SPAWN_Y: int = 19

func _ready() -> void:
	assert(grid != null, "PieceSpawn: grid not wired")
	_bag = PieceBag.new()
	_current_piece_type = _bag.get_next()
	_next_piece_type = _bag.get_next()

## Returns next piece type without spawning (peek for preview).
func peek_next() -> int:
	return _next_piece_type

## Spawns the current piece at spawn position.
## Returns true if spawned successfully, false if spawn cell occupied.
func spawn_piece() -> bool:
	# Check if spawn position is occupied
	if not grid.is_empty(SPAWN_X, SPAWN_Y):
		spawn_failed.emit()
		return false

	# Activate piece in Tetromino system
	tetromino.activate(_current_piece_type)
	piece_spawned.emit(_current_piece_type)

	# Advance bag for next piece
	_current_piece_type = _next_piece_type
	_next_piece_type = _bag.get_next()
	next_piece_updated.emit(_next_piece_type)
	return true

## Called by GameState on new game — resets bag and pre-fills.
func reset_bag() -> void:
	_bag = PieceBag.new()
	_current_piece_type = _bag.get_next()
	_next_piece_type = _bag.get_next()

## Called externally to get current piece type.
func get_current_piece_type() -> int:
	return _current_piece_type