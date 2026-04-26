class_name LineClear
extends Node
## Line Clearing System — detects complete rows and collapses the grid.
## Receives grid via @export. Connects to tetromino piece_locked signal.
## Emits lines_cleared(count) to downstream systems after atomic collapse.

@export var grid: Grid

signal lines_cleared(count: int)

## Maps tetromino node for piece_locked connection.
## Set this via editor or programatically before _ready runs.
@export var tetromino: Node

func _ready() -> void:
	assert(grid != null, "LineClear: grid not wired")
	if tetromino and tetromino.has_signal("piece_locked"):
		tetromino.piece_locked.connect(_on_piece_locked)


## Called when a piece locks. Detects complete rows and collapses them.
## Returns the number of lines cleared (0-4). Emits lines_cleared signal after collapse.
func detect_and_clear_lines() -> int:
	var cleared_rows: Array[int] = []

	# Scan all rows bottom-to-top, collect complete rows
	for y in range(Grid.GRID_HEIGHT):
		var is_complete := true
		for x in range(Grid.GRID_WIDTH):
			if grid.is_empty(x, y):
				is_complete = false
				break
		if is_complete:
			cleared_rows.append(y)

	var count := cleared_rows.size()
	if count == 0:
		return 0

	# Atomic row collapse
	_collapse_rows(cleared_rows)

	# Emit after collapse is complete
	lines_cleared.emit(count)
	return count


## Internal: performs atomic row collapse.
## cleared_rows must be sorted ascending.
func _collapse_rows(cleared_rows: Array[int]) -> void:
	cleared_rows.sort()

	# Build a new grid by copying non-cleared rows down
	var new_cells: Array = []
	for i in range(Grid.GRID_HEIGHT):
		new_cells.append([Grid.EMPTY] * Grid.GRID_WIDTH)

	# Track destination row in new_cells
	var dest_y := 0

	# Iterate source rows bottom-to-top
	for y in range(Grid.GRID_HEIGHT):
		if y in cleared_rows:
			continue  # skip cleared rows
		# Count how many cleared rows are below this source row
		var shift_amount := 0
		for cleared_y in cleared_rows:
			if cleared_y < y:
				shift_amount += 1
		# Copy source row to destination
		var dest_row := y - shift_amount
		for x in range(Grid.GRID_WIDTH):
			new_cells[dest_row][x] = grid.cells[y][x]

	# Apply new cells back to grid
	grid.cells = new_cells


## Handle piece_locked signal from tetromino.
func _on_piece_locked() -> void:
	detect_and_clear_lines()