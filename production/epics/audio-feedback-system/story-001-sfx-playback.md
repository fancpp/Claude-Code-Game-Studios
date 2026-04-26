# Story 001: SFX Playback — 9 sound signal handlers, pitch variation

> **Epic**: audio-feedback-system
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/audio-feedback-system.md`
**Requirement**: `TR-audio-001` (9 sound types with durations), `TR-audio-003` (pitch variation 0.98-1.02)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-008 (Audio Architecture) — 9 `AudioStreamPlayer` instances, pitch variation via `randf_range`, signal-driven.

**Engine**: Godot 4.6 | **Risk**: LOW — `AudioStreamPlayer` API stable
**Control Manifest Rules (Presentation layer)**:
- Required: 9 `AudioStreamPlayer` children: sfx_lock, sfx_single, sfx_double, sfx_triple, sfx_tetris, sfx_level_up, sfx_combo, sfx_game_over, sfx_hard_drop
- Forbidden: Queuing or cancellation of overlapping sounds — each sound plays independently
- Guardrail: `pitch_scale` set immediately before `play()`, not in a separate function

---

## Acceptance Criteria

*From GDD audio-feedback-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN a piece locks, **WHEN** `piece_locked` signal is received, **THEN** lock click sound plays at LOCK_SOUND_VOLUME.
- [ ] **AC-2**: GIVEN a Tetris (4 lines) clears, **WHEN** `lines_cleared(4)` is received, **THEN** Tetris layered sound plays at TETRIS_SOUND_VOLUME.
- [ ] **AC-3**: GIVEN level up occurs, **WHEN** `level_up` signal is received, **THEN** ascending arpeggio plays for 300ms.
- [ ] **AC-4**: GIVEN combo multiplier reaches x5, **WHEN** the event is received, **THEN** special combo chime plays distinct from normal clears.
- [ ] **AC-5**: GIVEN game over, **WHEN** `game_over` signal is received, **THEN** descending tone plays for 500ms.
- [ ] **AC-6**: GIVEN hard drop, **WHEN** `hard_drop` signal is received, **THEN** heavy thud plays immediately.
- [ ] **AC-7**: GIVEN SOUND_ENABLED is set to false, **WHEN** any sound event occurs, **THEN** no sound plays but no error occurs.

---

## Implementation Notes

*From ADR-ARCH-008:*

```gdscript
# audio_feedback.gd
class_name AudioFeedback
extends Node

const PITCH_VARIANCE := 0.02  # randf_range(0.98, 1.02) per playback

var sfx_enabled: bool = true

@onready var sfx_lock: AudioStreamPlayer = $sfx_lock
@onready var sfx_single: AudioStreamPlayer = $sfx_single
@onready var sfx_double: AudioStreamPlayer = $sfx_double
@onready var sfx_triple: AudioStreamPlayer = $sfx_triple
@onready var sfx_tetris: AudioStreamPlayer = $sfx_tetris
@onready var sfx_level_up: AudioStreamPlayer = $sfx_level_up
@onready var sfx_combo: AudioStreamPlayer = $sfx_combo
@onready var sfx_game_over: AudioStreamPlayer = $sfx_game_over
@onready var sfx_hard_drop: AudioStreamPlayer = $sfx_hard_drop

func _ready() -> void:
    tetromino.piece_locked.connect(_on_piece_locked)
    tetromino.hard_drop.connect(_on_hard_drop)
    line_clear.lines_cleared.connect(_on_lines_cleared)
    speed_progression.level_up.connect(_on_level_up)
    combo_scoring.combo_x5.connect(_on_combo_x5)
    game_state.game_over.connect(_on_game_over)

func _play(player: AudioStreamPlayer, volume_scalar: float) -> void:
    if not sfx_enabled:
        return
    player.pitch_scale = randf_range(1.0 - PITCH_VARIANCE, 1.0 + PITCH_VARIANCE)
    # volume set by caller (story 002)
    player.play()

func _on_piece_locked() -> void:
    _play(sfx_lock, 0.7)

func _on_hard_drop() -> void:
    _play(sfx_hard_drop, 0.6)

func _on_lines_cleared(count: int) -> void:
    match count:
        1: _play(sfx_single, 0.8)
        2: _play(sfx_double, 0.8)
        3: _play(sfx_triple, 0.8)
        4: _play(sfx_tetris, 1.0)

func _on_level_up(_new_level: int) -> void:
    _play(sfx_level_up, 0.9)

func _on_combo_x5() -> void:
    _play(sfx_combo, 1.0)

func _on_game_over() -> void:
    _play(sfx_game_over, 1.0)

func set_sfx_enabled(enabled: bool) -> void:
    sfx_enabled = enabled
```

**Signal connections**: Each signal handler is a separate method for clarity and testability. `_play()` is the shared playback helper.

**Pitch variation**: `randf_range(0.98, 1.02)` is called on every `_play()` call. For GUT tests, `seed()` can be set to make this deterministic.

**No sound cancellation**: Each `AudioStreamPlayer` plays independently. If `sfx_lock.play()` is called while lock sound is already playing, both instances play (the same player node can only play one at a time, but each signal handler fires independently).

---

## Out of Scope

- Volume hierarchy (story 002)
- SOUND_ENABLED toggle (story 002)

---

## QA Test Cases

**AC-2**: Tetris sound (lines_cleared 4)
- Given: `lines_cleared(4)` signal received
- When: `_on_lines_cleared(4)` runs
- Then: `sfx_tetris.play()` is called (not sfx_single, sfx_double, etc.)
- Edge cases: Rapid successive clears (both trigger independently)

**AC-7**: SOUND_ENABLED = false → no sound
- Given: `set_sfx_enabled(false)` called
- When: Any signal fires (piece_locked, lines_cleared, etc.)
- Then: No `play()` call is made on any AudioStreamPlayer
- No error thrown — `_play()` returns early

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: Screenshot + lead sign-off OR documented manual audio test at `production/qa/evidence/audio-feedback-*.md`

**Status**: [ ] Not yet created

**Dependencies**: tetromino-system stories, line-clear-system stories, combo-scoring-system stories, speed-progression-system stories, game-state-system stories