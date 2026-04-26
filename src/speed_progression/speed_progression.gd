class_name SpeedProgression
extends Node
## Speed Progression System — manages level and drop interval.
## Receives grid via @export. Connects to line_clear.lines_cleared signal.
## Emits level_up and drop_interval_changed signals to downstream.

@export var grid: Grid

## Emitted each time a drop should occur (at get_drop_interval() seconds).
## Consumed by main.gd: connected to tetromino.move_down for auto-drop.
signal drop_tick
signal level_up(new_level: int)
signal drop_interval_changed(interval_ms: int)

# Constants
const INITIAL_DROP_INTERVAL: int = 1000   # ms at level 1
const SPEED_INCREMENT: int = 50            # ms faster per level
const DROP_INTERVAL_MIN: int = 100         # ms (cap — level 15)
const LINES_PER_LEVEL: int = 10
const MAX_LEVEL: int = 15

# State
var current_level: int = 1
var lines_since_last_level: int = 0

# References for signal connections
var _line_clear: Node
var _drop_timer: Timer

func _ready() -> void:
	assert(grid != null, "SpeedProgression: grid not wired")
	_drop_timer = Timer.new()
	_drop_timer.timeout.connect(_on_drop_timer)
	add_child(_drop_timer)
	_drop_timer.wait_time = get_drop_interval()
	_drop_timer.one_shot = false


## Connect to line_clear.lines_cleared signal.
## Call this after both nodes are available in the scene tree.
func connect_to_line_clear(line_clear_node: Node) -> void:
	_line_clear = line_clear_node
	if _line_clear.has_signal("lines_cleared"):
		_line_clear.lines_cleared.connect(_on_lines_cleared)


## Handle lines_cleared signal — check for level-up.
func _on_lines_cleared(count: int) -> void:
	if count <= 0:
		return
	lines_since_last_level += count

	# Handle possible multi-level jump (e.g., clearing many lines at once near threshold)
	while lines_since_last_level >= LINES_PER_LEVEL and current_level < MAX_LEVEL:
		lines_since_last_level -= LINES_PER_LEVEL
		current_level += 1
		level_up.emit(current_level)
		drop_interval_changed.emit(get_drop_interval_ms())
		_drop_timer.wait_time = get_drop_interval()


func _on_drop_timer() -> void:
	drop_tick.emit()


## Reset to new game state (level=1, lines=0).
func _on_new_game() -> void:
	current_level = 1
	lines_since_last_level = 0
	drop_interval_changed.emit(get_drop_interval_ms())


## Update level directly (e.g., from game state reset).
## Recalculates drop interval and emits signals.
func update_level(new_level: int) -> void:
	current_level = mini(new_level, MAX_LEVEL)
	drop_interval_changed.emit(get_drop_interval_ms())
	_drop_timer.wait_time = get_drop_interval()


## Get current drop interval in milliseconds.
func get_drop_interval_ms() -> int:
	if current_level >= MAX_LEVEL:
		return DROP_INTERVAL_MIN
	return maxi(DROP_INTERVAL_MIN, INITIAL_DROP_INTERVAL - (current_level - 1) * SPEED_INCREMENT)


## Get current drop interval in seconds (for timer.wait_time).
func get_drop_interval() -> float:
	return get_drop_interval_ms() / 1000.0


## Get current level.
func get_level() -> int:
	return current_level


## Get lines since last level-up.
func get_lines_since_last_level() -> int:
	return lines_since_last_level