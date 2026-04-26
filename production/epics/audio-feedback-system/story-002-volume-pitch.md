# Story 002: Volume + Pitch System — volume hierarchy, pitch variation, SOUND_ENABLED toggle

> **Epic**: audio-feedback-system
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/audio-feedback-system.md`
**Requirement**: `TR-audio-002` (volume hierarchy: master * sfx * type_scalar), `TR-audio-003` (pitch variation 0.98-1.02), `TR-audio-004` (audio continues during pause)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-008 (Audio Architecture) — volume hierarchy via `linear_to_db()`, pitch via `randf_range()`, audio does NOT pause with game.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Presentation layer)**:
- Required: `set_master_volume(vol: float)`, `set_sfx_enabled(enabled: bool)`, `effective_volume` formula
- Forbidden: Audio pause on game pause — deliberate GDD design choice
- Guardrail: `volume_db = linear_to_db(effective_volume)` for Godot audio bus

---

## Acceptance Criteria

*From GDD audio-feedback-system.md Acceptance Criteria:*

- [ ] **AC-8**: GIVEN master_volume = 0.8, sfx_volume = 1.0, LOCK_SOUND_VOLUME = 0.7, **WHEN** lock sound plays, **THEN** effective_volume = 0.8 * 1.0 * 0.7 = 0.56 and pitch varies within [0.98, 1.02].
- [ ] **AC-pause**: GIVEN audio is playing, **WHEN** game pauses, **THEN** audio continues playing (no pause).
- [ ] **AC-toggle**: GIVEN `set_sfx_enabled(false)` is called, **WHEN** any signal fires, **THEN** no `play()` call occurs (no-op, no error).

---

## Implementation Notes

*From ADR-ARCH-008:*

```gdscript
# audio_feedback.gd — volume hierarchy + pitch (extends story 001)

const MASTER_DEFAULT := 0.8
const SFX_DEFAULT := 1.0

# Volume scalars per sound type
const VOLUME_LOCK := 0.7
const VOLUME_CLEAR := 0.8
const VOLUME_TETRIS := 1.0
const VOLUME_HARD_DROP := 0.6
const VOLUME_LEVEL_UP := 0.9
const VOLUME_COMBO := 1.0
const VOLUME_GAME_OVER := 1.0

var master_volume: float = MASTER_DEFAULT
var sfx_volume: float = SFX_DEFAULT

func _play(player: AudioStreamPlayer, volume_scalar: float) -> void:
    if not sfx_enabled:
        return
    # Pitch variation
    player.pitch_scale = randf_range(1.0 - PITCH_VARIANCE, 1.0 + PITCH_VARIANCE)
    # Volume hierarchy
    var effective_vol := master_volume * sfx_volume * volume_scalar
    player.volume_db = linear_to_db(effective_vol)
    player.play()

func set_master_volume(vol: float) -> void:
    master_volume = clampf(vol, 0.0, 1.0)

func get_master_volume() -> float:
    return master_volume
```

**Volume formula**: `effective_volume = master_volume * sfx_volume * sound_type_scalar`
- `master_volume`: user-controllable overall volume (0.0-1.0)
- `sfx_volume`: relative sound effects volume (0.0-1.0)
- `sound_type_scalar`: per-sound-type weight (lock=0.7, clear=0.8, tetris=1.0, etc.)
- `linear_to_db()` converts linear 0.0-1.0 to Godot's decibel scale

**Audio does NOT pause with game**: No `get_tree().paused` check. No pause wiring. Audio continues during pause — per GDD explicit design choice.

**Pitch variation**: `randf_range(1.0 - PITCH_VARIANCE, 1.0 + PITCH_VARIANCE)` where `PITCH_VARIANCE = 0.02`. Range: [0.98, 1.02]. Each `_play()` call generates a new random value.

---

## Out of Scope

- Signal routing for 9 sound types (Story 001)

---

## QA Test Cases

**AC-8**: Volume hierarchy math
- Given: `master_volume = 0.8`, `sfx_volume = 1.0`, `volume_scalar = 0.7` (lock)
- When: `_play(sfx_lock, 0.7)` is called
- Then: `sfx_lock.volume_db == linear_to_db(0.8 * 1.0 * 0.7)` = `linear_to_db(0.56)`
- And: `sfx_lock.pitch_scale` is in range [0.98, 1.02]
- Edge cases: `master_volume = 0.0` (silent), `sfx_volume = 0.0` (silent)

**AC-pause**: Audio continues during pause
- Given: `sfx_lock` is currently playing a lock click
- When: Game pauses via `get_tree().paused = true`
- Then: `sfx_lock.is_playing()` remains true (audio not paused)
- Verification: This is the default Godot behavior when no explicit pause wiring exists

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/audio_feedback/volume_pitch_test.gd` — must exist and pass

**Status**: [ ] Not yet created

**Dependencies**: audio-feedback-system story-001