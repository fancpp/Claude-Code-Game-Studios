class_name GhostPiece
extends Node
## Ghost Piece System — calculates the drop destination Y position.
## Receives grid via @export. Provides ghost_y via signal or property.
## Does NOT handle rendering — rendering layer reads ghost_position_updated.

@export var grid: Grid
@export var tetromino: Node  ## Set by main.gd — used to read current piece state

signal ghost_position_updated(ghost_x: int, ghost_y: int, ghost_shape: Array)

## Current ghost position data
var _ghost_x: int = 0
var _ghost_y: int = 0
var _ghost_shape: Array = []

func _ready() -> void:
	assert(grid != null, "GhostPiece: grid not wired")

## Called by main.gd when tetromino moves/rotates.
## Reads current piece state from tetromino and recalculates ghost position.
func _on_piece_moved() -> void:
	if tetromino == null or tetromino.piece_type == 0:
		return
	update_ghost(tetromino.position.x, tetromino.position.y,
		TetrominoShapes.get_data(tetromino.piece_type).get_cells(tetromino.rotation_state))


## Calculate ghost Y position by ray-casting down from piece position.
## piece_shape is an array of [offset_x, offset_y] cell positions.
## Returns the Y coordinate where the ghost piece should be rendered.
func calculate_ghost_y(piece_x: int, piece_y: int, piece_shape: Array) -> int:
	var ghost_y := piece_y
	while _can_ghost_move_to(piece_x, ghost_y - 1, piece_shape):
		ghost_y -= 1
	return ghost_y


## Update ghost position and emit signal if changed.
## Call this whenever piece moves or rotates.
func update_ghost(piece_x: int, piece_y: int, shape: Array) -> void:
	var new_ghost_y := calculate_ghost_y(piece_x, piece_y, shape)

	if new_ghost_y != _ghost_y or piece_x != _ghost_x or _ghost_shape != shape:
		_ghost_x = piece_x
		_ghost_y = new_ghost_y
		_ghost_shape = shape.duplicate()
		ghost_position_updated.emit(_ghost_x, _ghost_y, _ghost_shape)


## Returns the current ghost Y position (last calculated).
func get_ghost_y() -> int:
	return _ghost_y


## Returns the current ghost X position (last calculated).
func get_ghost_x() -> int:
	return _ghost_x


## Returns the current ghost shape (last calculated).
func get_ghost_shape() -> Array:
	return _ghost_shape.duplicate()


## Internal helper — tests if all cells of the piece shape can occupy (x, y).
func _can_ghost_move_to(x: int, y: int, shape: Array) -> bool:
	for cell in shape:
		var cx: int = cell[0]
		var cy: int = cell[1]
		var grid_x := x + cx
		var grid_y := y + cy
		# Must be within grid bounds and not overlapping a locked cell
		if not grid.is_valid_position(grid_x, grid_y):
			return false  # out of bounds (floor/wall)
		if not grid.is_empty(grid_x, grid_y):
			return false  # occupied
	return true


## Get drop distance from piece_y to ghost_y.
func get_drop_distance(piece_y: int, ghost_y: int) -> int:
	return piece_y - ghost_y