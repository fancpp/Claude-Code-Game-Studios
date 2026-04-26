# game_smoke.gd — Godot Headless Smoke Test
# Verifies the game scene loads and initializes without errors
extends GutTest

func test_main_scene_loads_without_error() -> void:
	var scene = load("res://main.tscn")
	assert_ne(scene, null, "main.tscn should load")
	var instance = scene.instantiate()
	assert_ne(instance, null, "main.tscn should instantiate")
	instance.free()

func test_project_godot_exists() -> void:
	var f = FileAccess.file_exists("res://project.godot")
	assert_eq(f, true, "project.godot should exist")

func test_all_core_systems_exist() -> void:
	var systems = [
		"res://src/grid/grid.gd",
		"res://src/input_handler/input_handler.gd",
		"res://src/collision/collision.gd",
		"res://src/game_state/game_state.gd",
		"res://src/tetromino/tetromino.gd",
		"res://src/piece_spawn/piece_spawn.gd",
		"res://src/line_clear/line_clear.gd",
		"res://src/combo_scoring/combo_scoring.gd",
		"res://src/ghost_piece/ghost_piece.gd",
		"res://src/speed_progression/speed_progression.gd",
		"res://src/visual_feedback/visual_feedback.gd",
		"res://src/audio_feedback/audio_feedback.gd",
		"res://src/score_display/score_display.gd",
	]
	for path in systems:
		var f = FileAccess.file_exists(path)
		assert_eq(f, true, path + " should exist")