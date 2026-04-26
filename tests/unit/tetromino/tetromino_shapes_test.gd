# Tetromino Shapes Unit Tests — ADR-004 validation
# Tests that TetrominoShapes.SHAPES returns correct cells for all 7 pieces × 4 rotations.
extends GutTest

## Helper: verify a piece has exactly n cells at a given rotation.
func _verify_cell_count(piece_type: int, rotation: int, expected_count: int) -> void:
	var data = TetrominoShapes.get_data(piece_type)
	var cells = data.get_cells(rotation)
	assert_eq(cells.size(), expected_count,
		"Piece %d rot %d: expected %d cells, got %d" % [piece_type, rotation, expected_count, cells.size()])

## I-piece: 4 cells all rotations
func test_i_piece_has_4_cells_all_rotations() -> void:
	for r in range(4):
		_verify_cell_count(1, r, 4)

## O-piece: 4 cells all rotations (and all identical cells)
func test_o_piece_has_4_cells_all_rotations() -> void:
	for r in range(4):
		_verify_cell_count(2, r, 4)

func test_o_piece_same_cells_all_rotations() -> void:
	var data = TetrominoShapes.get_data(2)
	var rot0 = data.get_cells(0)
	var rot1 = data.get_cells(1)
	var rot2 = data.get_cells(2)
	var rot3 = data.get_cells(3)
	# O-piece is symmetric — all 4 rotations should have same cell set
	assert_eq(rot0, rot1, "O-piece rot0 == rot1")
	assert_eq(rot1, rot2, "O-piece rot1 == rot2")
	assert_eq(rot2, rot3, "O-piece rot2 == rot3")

## T-piece: 4 cells all rotations
func test_t_piece_has_4_cells_all_rotations() -> void:
	for r in range(4):
		_verify_cell_count(3, r, 4)

## S-piece: 4 cells all rotations
func test_s_piece_has_4_cells_all_rotations() -> void:
	for r in range(4):
		_verify_cell_count(4, r, 4)

## Z-piece: 4 cells all rotations
func test_z_piece_has_4_cells_all_rotations() -> void:
	for r in range(4):
		_verify_cell_count(5, r, 4)

## J-piece: 4 cells all rotations
func test_j_piece_has_4_cells_all_rotations() -> void:
	for r in range(4):
		_verify_cell_count(6, r, 4)

## L-piece: 4 cells all rotations
func test_l_piece_has_4_cells_all_rotations() -> void:
	for r in range(4):
		_verify_cell_count(7, r, 4)

## All pieces have exactly 4 cells at rotation 0
func test_all_pieces_have_4_cells_at_rotation_0() -> void:
	for piece_type in range(1, 8):
		_verify_cell_count(piece_type, 0, 4)

## I-piece at rot 0 spans 4 columns wide
func test_i_piece_rot0_horizontal() -> void:
	var cells = TetrominoShapes.get_data(1).get_cells(0)
	# Cells at y=1 (row 1 of 4×4), x = 0,1,2,3
	var row1 = cells.filter(func(c): return c.y == 1)
	assert_eq(row1.size(), 4, "I-piece rot0 has 4 cells in middle row")

## I-piece at rot 1 spans 4 rows tall
func test_i_piece_rot1_vertical() -> void:
	var cells = TetrominoShapes.get_data(1).get_cells(1)
	# Cells at x=2 (col 2 of 4×4), y = 0,1,2,3
	var col2 = cells.filter(func(c): return c.x == 2)
	assert_eq(col2.size(), 4, "I-piece rot1 has 4 cells in middle col")

## Cells are Vector2i within 4×4 bounding box
func test_all_cells_within_4x4_bounds() -> void:
	for piece_type in range(1, 8):
		for rotation in range(4):
			var cells = TetrominoShapes.get_data(piece_type).get_cells(rotation)
			for cell in cells:
				assert_true(cell.x >= 0 and cell.x < 4,
					"Piece %d rot %d: cell.x=%d out of bounds" % [piece_type, rotation, cell.x])
				assert_true(cell.y >= 0 and cell.y < 4,
					"Piece %d rot %d: cell.y=%d out of bounds" % [piece_type, rotation, cell.y])