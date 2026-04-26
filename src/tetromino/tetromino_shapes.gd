class_name TetrominoData
extends RefCounted
## Pure data class holding precomputed 4×4 occupancy grids for 4 SRS rotation states.
## One instance per piece type (1-7), shared via TetrominoShapes.SHAPES.
## No engine dependencies — trivially mockable in tests.

var rotation_grids: Array  # Array[Array] — 4×4 bool grid per rotation state

func _init(p_grids: Array) -> void:
	rotation_grids = p_grids

## Returns occupied cells for a given rotation state as local Vector2i offsets.
## Row 0 = top, col 0 = left of the 4×4 bounding box.
func get_cells(rotation: int) -> Array:
	var cells: Array = []
	var grid = rotation_grids[rotation]
	for row in range(4):
		for col in range(4):
			if grid[row][col]:
				cells.append(Vector2i(col, row))
	return cells


class_name TetrominoShapes
extends RefCounted
## Static dictionary of all 7 tetromino shapes in SRS standard.
## O(1) lookup by piece type (1-7) and rotation state (0-3).
## No runtime rotation math — all 28 shape variants precomputed.

static var SHAPES: Dictionary = {
	1: TetrominoData.new([  # I
		[[false,false,false,false],[true,true,true,true],[false,false,false,false],[false,false,false,false]],
		[[false,false,true,false],[false,false,true,false],[false,false,true,false],[false,false,true,false]],
		[[false,false,false,false],[false,false,false,false],[true,true,true,true],[false,false,false,false]],
		[[false,true,false,false],[false,true,false,false],[false,true,false,false],[false,true,false,false]],
	]),
	2: TetrominoData.new([  # O (symmetric — all rotations identical)
		[[false,false,false,false],[false,true,true,false],[false,true,true,false],[false,false,false,false]],
		[[false,false,false,false],[false,true,true,false],[false,true,true,false],[false,false,false,false]],
		[[false,false,false,false],[false,true,true,false],[false,true,true,false],[false,false,false,false]],
		[[false,false,false,false],[false,true,true,false],[false,true,true,false],[false,false,false,false]],
	]),
	3: TetrominoData.new([  # T
		[[false,false,false,false],[false,true,false,false],[true,true,true,false],[false,false,false,false]],
		[[false,false,false,false],[false,true,false,false],[false,true,true,false],[false,true,false,false]],
		[[false,false,false,false],[false,false,false,false],[true,true,true,false],[false,true,false,false]],
		[[false,false,false,false],[true,true,false,false],[false,true,false,false],[false,true,false,false]],
	]),
	4: TetrominoData.new([  # S
		[[false,false,false,false],[false,true,true,false],[true,true,false,false],[false,false,false,false]],
		[[false,false,false,false],[false,true,false,false],[false,true,true,false],[false,true,false,false]],
		[[false,false,false,false],[false,false,false,false],[false,true,true,false],[true,true,false,false]],
		[[false,false,false,false],[true,false,false,false],[true,true,false,false],[false,true,false,false]],
	]),
	5: TetrominoData.new([  # Z
		[[false,false,false,false],[true,true,false,false],[false,true,true,false],[false,false,false,false]],
		[[false,false,false,false],[false,false,true,false],[false,true,true,false],[false,true,false,false]],
		[[false,false,false,false],[false,false,false,false],[true,true,false,false],[false,true,true,false]],
		[[false,false,false,false],[false,true,false,false],[true,true,false,false],[true,false,false,false]],
	]),
	6: TetrominoData.new([  # J
		[[false,false,false,false],[true,false,false,false],[true,true,true,false],[false,false,false,false]],
		[[false,false,false,false],[false,true,true,false],[false,true,false,false],[false,true,false,false]],
		[[false,false,false,false],[false,false,false,false],[true,true,true,false],[false,false,true,false]],
		[[false,false,false,false],[true,true,false,false],[false,true,false,false],[true,false,false,false]],
	]),
	7: TetrominoData.new([  # L
		[[false,false,false,false],[false,false,true,false],[true,true,true,false],[false,false,false,false]],
		[[false,false,false,false],[false,true,false,false],[false,true,false,false],[false,true,true,false]],
		[[false,false,false,false],[false,false,false,false],[true,true,true,false],[true,false,false,false]],
		[[false,false,false,false],[true,true,false,false],[false,true,false,false],[false,true,false,false]],
	]),
}

## O(1) lookup. Returns TetrominoData for piece type 1-7.
static func get_data(piece_type: int) -> TetrominoData:
	return SHAPES[piece_type]