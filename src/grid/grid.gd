class_name Grid
extends RefCounted
## 10x20 game grid — pure data, no engine dependencies.
## Injected into systems via `@export var grid: Grid` on main.tscn root.

const GRID_WIDTH: int = 10
const GRID_HEIGHT: int = 20
const EMPTY: int = 0

var cells: Array  # 20×10, cells[y][x], 0=EMPTY, 1-7=tetromino type

func _init() -> void:
	cells = []
	for i in range(GRID_HEIGHT):
		cells.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

func get_cell(x: int, y: int) -> int:
	if not is_valid_position(x, y):
		return -1
	return cells[y][x]

func set_cell(x: int, y: int, value: int) -> void:
	if not is_valid_position(x, y):
		push_warning("Grid.set_cell: invalid position (%d, %d)" % [x, y])
		return
	cells[y][x] = value

func is_empty(x: int, y: int) -> bool:
	if not is_valid_position(x, y):
		return true  # Invalid position is treated as empty (not occupied)
	return cells[y][x] == EMPTY

func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT

func clear_grid() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			cells[y][x] = EMPTY