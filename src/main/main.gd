class_name Main
extends Node2D
## Root node of the game scene.
## Scene tree (flat, per ADR-003):
##   main.tscn (Main/Node2D)
##     ├── input_handler
##     ├── game_state
##     ├── collision         ← needs grid
##     ├── tetromino         ← needs grid + collision
##     ├── piece_spawn       ← needs grid + tetromino
##     ├── line_clear        ← needs grid
##     ├── combo_scoring     ← needs grid
##     ├── ghost_piece       ← needs grid + tetromino
##     ├── speed_progression ← needs grid
##     ├── visual_feedback
##     ├── audio_feedback
##     └── ui_layer (CanvasLayer)
##           └── score_display

@onready var grid: Grid = Grid.new()

func _ready() -> void:
	# Wire grid to systems that need it
	collision.grid = grid
	tetromino.grid = grid
	tetromino.collision = collision
	piece_spawn.grid = grid
	piece_spawn.tetromino = tetromino
	line_clear.grid = grid
	combo_scoring.grid = grid
	ghost_piece.grid = grid
	speed_progression.grid = grid

	# Speed progression: connect to line clear for level-up
	speed_progression.connect_to_line_clear(line_clear)

	_connect_signals()

func _connect_signals() -> void:
	# Input → Tetromino
	input_handler.move_left.connect(tetromino.move_left)
	input_handler.move_right.connect(tetromino.move_right)
	input_handler.soft_drop.connect(tetromino.soft_drop)
	input_handler.hard_drop.connect(tetromino.hard_drop)
	input_handler.rotate_cw.connect(tetromino.rotate_cw)
	input_handler.rotate_ccw.connect(tetromino.rotate_ccw)

	# Input → GameState (pause toggle)
	input_handler.pause.connect(game_state._on_pause_input)

	# Collision lock delay → Tetromino (piece locks after delay)
	collision.lock_delay_expired.connect(tetromino._lock_piece_to_grid)

	# Tetromino locked → Piece Spawn (spawn next piece)
	tetromino.piece_locked.connect(func(): piece_spawn.spawn_piece())

	# Tetromino locked → Line Clear
	tetromino.piece_locked.connect(line_clear._on_piece_locked)

	# Piece Spawn failure → Game Over
	piece_spawn.spawn_failed.connect(game_state._on_spawn_failed)

	# Line Clear → Combo Scoring
	line_clear.lines_cleared.connect(combo_scoring._on_lines_cleared)

	# Line Clear → Speed Progression (level up)
	line_clear.lines_cleared.connect(speed_progression._on_lines_cleared)

	# Speed Progression auto-drop timer → Tetromino
	speed_progression.drop_tick.connect(tetromino.move_down)

	# Combo Scoring → Score Display
	combo_scoring.score_changed.connect(score_display.update_score)
	combo_scoring.combo_x2.connect(func(): score_display.update_combo(2))
	combo_scoring.combo_x3.connect(func(): score_display.update_combo(3))
	combo_scoring.combo_x4.connect(func(): score_display.update_combo(4))
	combo_scoring.combo_x5.connect(func(): score_display.update_combo(5))

	# Speed Progression → Score Display
	speed_progression.level_up.connect(score_display.update_level)

	# Ghost Piece recalc on piece move
	tetromino.piece_moved.connect(ghost_piece._on_piece_moved)

	# Game State → Visual + Audio feedback
	game_state.game_over.connect(visual_feedback._on_game_over)
	game_state.game_over.connect(audio_feedback._on_game_over)
	game_state.game_over.connect(score_display._on_game_over)

	# Line Clear → Visual + Audio feedback (flash/shake/sfx)
	line_clear.lines_cleared.connect(visual_feedback._on_lines_cleared)
	line_clear.lines_cleared.connect(audio_feedback._on_line_clear)

	# Tetromino hard drop → Audio feedback
	tetromino.piece_hard_dropped.connect(audio_feedback._on_hard_drop)

	# Combo x5 → Visual + Audio
	combo_scoring.combo_x5.connect(visual_feedback._on_combo_x5)
	combo_scoring.combo_x5.connect(audio_feedback._on_combo_x5)

	# Level up → Audio
	speed_progression.level_up.connect(audio_feedback._on_level_up)

	# Game State new game init → all systems reset
	game_state.new_game_init.connect(grid.clear_grid)
	game_state.new_game_init.connect(score_display.reset)
	game_state.new_game_init.connect(combo_scoring.reset_combo)
	game_state.new_game_init.connect(piece_spawn.reset_bag)
	game_state.new_game_init.connect(speed_progression._on_new_game)