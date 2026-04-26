class_name VisualFeedback
extends Node

## Visual feedback presentation layer per ADR-011.
## Receives gameplay signals and triggers VFX effects.
## Stubs: prints effect name and emits corresponding signal.

signal vfx_flash_started(color: Color, duration_ms: int)
signal vfx_shake_started(screen_shake_pixels: int)
signal vfx_dim_started
signal vfx_combo_glow_started(combo_level: int)
signal vfx_game_over

func _ready() -> void:
	# Signal connections made by consumers in their _ready() per ADR-002
	pass

## Trigger flash effect.
## [param color] The color of the flash.
## [param duration_ms] Duration of the flash in milliseconds.
func flash(color: Color, duration_ms: int) -> void:
	print("VFX.flash %s %dms" % [color, duration_ms])
	emit_signal("vfx_flash_started", color, duration_ms)

## Trigger screen shake effect.
## [param screen_shake_pixels] Magnitude of shake in pixels.
func shake(screen_shake_pixels: int) -> void:
	print("VFX.shake %dpx" % screen_shake_pixels)
	emit_signal("vfx_shake_started", screen_shake_pixels)

## Trigger dim effect (game over).
func dim() -> void:
	print("VFX.dim")
	emit_signal("vfx_dim_started")

## Trigger combo glow effect.
## [param combo_level] The combo level that triggered the glow.
func combo_glow(combo_level: int) -> void:
	print("VFX.combo_glow(%d)" % combo_level)
	emit_signal("vfx_combo_glow_started", combo_level)

## Trigger game over effect.
func game_over_effect() -> void:
	print("VFX.game_over")
	emit_signal("vfx_game_over")

## Signal handlers (called by main.gd wiring) ##

func _on_lines_cleared(count: int) -> void:
	## Trigger flash + shake based on line count.
	match count:
		1: flash(Color.WHITE, 100); shake(2)
		2: flash(Color.WHITE, 150); shake(2)
		3: flash(Color.WHITE, 200); shake(4)
		4: flash(Color.GOLD, 300); shake(8)  # Tetris — gold flash, big shake
		_: pass

func _on_combo_x5() -> void:
	combo_glow(5)

func _on_game_over() -> void:
	dim()
	game_over_effect()