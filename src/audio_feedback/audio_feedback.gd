class_name AudioFeedback
extends Node

## Audio feedback presentation layer per ADR-008.
## Manages SFX playback with volume and pitch control.
## Stubs: prints playback and emits signal for observation.

signal sfx_played(sfx_name: String)
signal volume_changed(vol_db: float)
signal pitch_changed(pitch: float)

## Volume constants
const MASTER_DEFAULT := 0.8
const SFX_DEFAULT := 1.0
const PITCH_VARIANCE := 0.02

## Internal state
var _volume_db: float = 0.0
var _pitch: float = 1.0
var _sfx_enabled: bool = true

## SFX map: sound name -> description
## These are stub descriptions for the SFX types.
const SFX_MAP := {
	"move": "move feedback",
	"rotate": "rotation feedback",
	"soft_drop": "soft drop",
	"hard_drop": "hard drop impact",
	"line_clear": "line clear sound",
	"combo_x2": "combo milestone x2",
	"combo_x3": "combo milestone x3",
	"combo_x4": "combo milestone x4",
	"combo_x5": "combo milestone x5",
	"level_up": "level up jingle",
	"game_over": "game over tune"
}

func _ready() -> void:
	# Signal connections made by consumers in their _ready() per ADR-002
	pass

## Play an SFX by name.
## [param sfx_name] The name of the sound effect to play.
func play_sfx(sfx_name: String) -> void:
	if not _sfx_enabled:
		return
	print("Audio.play(%s)" % sfx_name)
	emit_signal("sfx_played", sfx_name)

## Set the volume in decibels.
## [param vol_db] Volume level in decibels.
func set_volume(vol_db: float) -> void:
	_volume_db = vol_db
	emit_signal("volume_changed", _volume_db)

## Set the pitch multiplier.
## [param pitch] Pitch multiplier (1.0 = normal).
func set_pitch(pitch: float) -> void:
	_pitch = pitch
	emit_signal("pitch_changed", _pitch)

## Check if an SFX name is valid.
## [param sfx_name] The sound effect name to check.
## Returns true if the SFX name exists in the map.
func is_valid_sfx(sfx_name: String) -> bool:
	return SFX_MAP.has(sfx_name)

## Get all valid SFX names.
## Returns an array of all valid sound effect names.
func get_valid_sfx_names() -> Array:
	return SFX_MAP.keys()

## Enable or disable SFX playback.
## [param enabled] Whether SFX should play.
func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled

## Signal handlers (called by main.gd wiring) ##

func _on_hard_drop(drop_distance: int) -> void:
	play_sfx("hard_drop")

func _on_rotate() -> void:
	play_sfx("rotate")

func _on_move() -> void:
	play_sfx("move")

func _on_line_clear(count: int) -> void:
	match count:
		1: play_sfx("line_clear")
		2: play_sfx("line_clear")
		3: play_sfx("line_clear")
		4: play_sfx("line_clear")
		_: play_sfx("line_clear")

func _on_combo_x5() -> void:
	play_sfx("combo_x5")

func _on_level_up(new_level: int) -> void:
	play_sfx("level_up")

func _on_game_over() -> void:
	play_sfx("game_over")