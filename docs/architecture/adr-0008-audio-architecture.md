# ADR-ARCH-008: Audio Architecture

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

The Audio Feedback System uses a pool of 9 `AudioStreamPlayer` instances (one per sound type) connected to a Godot SFX audio bus. All playback is signal-driven — `audio_feedback.gd` subscribes to gameplay signals and plays sounds on receipt. Pitch varies subtly per playback (`randf_range(0.98, 1.02)`) to prevent audible repetition. Audio does NOT pause when the game pauses (per GDD edge case decision). Volume is hierarchical: `effective_volume = master_volume × sfx_volume × sound_type_scalar`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Presentation / Audio |
| **Knowledge Risk** | LOW — `AudioStreamPlayer` and Godot audio bus API are stable from 2.x through 4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-002 (Signal Bus) — all audio is triggered by signals |
| **Enables** | Audio Feedback System implementation |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before Audio Feedback System implementation |

## Context

### Problem Statement

The game has 9 distinct sound types (lock, single/double/triple clear, Tetris, level up, combo ×5, game over, hard drop) that must play in response to gameplay events. The question is: how are the audio players organized, how is volume controlled, and what happens when multiple sounds trigger simultaneously or when the game pauses?

### Constraints

- Audio does NOT pause when the game pauses (per GDD — this is an explicit design choice)
- Multiple sounds can play simultaneously (no exclusive locking — sounds that overlap simply mix)
- Sounds that trigger while a previous instance is already playing play alongside it (no queuing, no cancellation)
- If audio device is unavailable, sound calls are silent no-ops
- Volume must be user-controllable (master) with relative per-type control

### Requirements

- All sounds are triggered by signals from upstream systems (no polling)
- Each of the 9 sound types has its own `AudioStreamPlayer`
- Pitch varies subtly per playback to avoid audible repetition
- Volume hierarchy: `effective_volume = master × sfx_volume × type_scalar`
- Audio continues when game is paused

## Decision

**Pattern: 9-instance `AudioStreamPlayer` pool, signal-driven, Godot audio bus, `_process()` poll for pitch variation.**

### Audio Bus Structure

```
project.godot → Audio → Audio Buses:
  Bus 0: Master
    └── Bus 1: SFX
          └── (all 9 AudioStreamPlayer instances connect here)
```

`master_volume` and `sfx_volume` are scalars applied via `AudioServer` or per-player `volume_db`. `AudioServer.get_bus_volume_db(bus_index)` is used to read the current bus volume, but we store our own `master_volume` and `sfx_volume` scalars for the math.

### Node Structure (in `main.tscn`)

```
audio_feedback.gd (Node)
  ├── sfx_lock (AudioStreamPlayer)         # lock click
  ├── sfx_single (AudioStreamPlayer)       # single line clear
  ├── sfx_double (AudioStreamPlayer)       # double line clear
  ├── sfx_triple (AudioStreamPlayer)       # triple line clear
  ├── sfx_tetris (AudioStreamPlayer)       # tetris chord + rising tone
  ├── sfx_level_up (AudioStreamPlayer)     # ascending arpeggio
  ├── sfx_combo (AudioStreamPlayer)        # combo ×5 chime
  ├── sfx_game_over (AudioStreamPlayer)    # descending tone
  └── sfx_hard_drop (AudioStreamPlayer)    # heavy thud
```

Each `AudioStreamPlayer` has its `bus` property set to `SFX` (Bus 1). `stream` property set to the appropriate `.ogg` audio file.

### Implementation

```gdscript
# audio_feedback.gd
class_name AudioFeedback
extends Node

const MASTER_DEFAULT := 0.8
const SFX_DEFAULT := 1.0
const PITCH_VARIANCE := 0.02   # randf_range(0.98, 1.02) per playback

var master_volume: float = MASTER_DEFAULT
var sfx_enabled: bool = true

# Volume scalars per sound type
const VOLUME_LOCK := 0.7
const VOLUME_CLEAR := 0.8
const VOLUME_TETRIS := 1.0
const VOLUME_HARD_DROP := 0.6
const VOLUME_LEVEL_UP := 0.9
const VOLUME_COMBO := 1.0
const VOLUME_GAME_OVER := 1.0

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
    # Pitch variation for non-repetitive sound
    player.pitch_scale = randf_range(1.0 - PITCH_VARIANCE, 1.0 + PITCH_VARIANCE)
    player.volume_db = linear_to_db(master_volume * sfx_volume * volume_scalar)
    player.play()

func _on_piece_locked() -> void:
    _play(sfx_lock, VOLUME_LOCK)

func _on_hard_drop() -> void:
    _play(sfx_hard_drop, VOLUME_HARD_DROP)

func _on_lines_cleared(count: int) -> void:
    match count:
        1: _play(sfx_single, VOLUME_CLEAR)
        2: _play(sfx_double, VOLUME_CLEAR)
        3: _play(sfx_triple, VOLUME_CLEAR)
        4: _play(sfx_tetris, VOLUME_TETRIS)

func _on_level_up(_new_level: int) -> void:
    _play(sfx_level_up, VOLUME_LEVEL_UP)

func _on_combo_x5() -> void:
    _play(sfx_combo, VOLUME_COMBO)

func _on_game_over() -> void:
    _play(sfx_game_over, VOLUME_GAME_OVER)

func set_master_volume(vol: float) -> void:
    master_volume = clamp(vol, 0.0, 1.0)

func set_sfx_enabled(enabled: bool) -> void:
    sfx_enabled = enabled
```

**Why 9 separate `AudioStreamPlayer` instances?**

| Approach | Pros | Cons |
|----------|------|------|
| One `AudioStreamPlayer` + queue | Minimal nodes | Must manage a play queue; can't overlap same sound; adds complexity |
| 9 `AudioStreamPlayer` instances | Each sound is independent; overlapping same sound works; simple | 9 nodes in scene tree |

9 nodes is not excessive — each `AudioStreamPlayer` is a lightweight Godot node. The independence it provides (any sound can overlap any other, including itself) is worth the minor scene tree addition.

**Why audio does NOT pause with game:**

Per the GDD edge case: "If game is paused: Audio continues playing." This is an explicit design choice — piece-drop sounds continuing during pause help players maintain rhythm awareness for the next unpause. This means we deliberately do NOT hook `_process()` or any pause callback. Audio simply plays whenever signals fire.

**Pitch variation:**
`randf_range(0.98, 1.02)` per playback means the same lock click sounds slightly different each time — avoids the "robotic repetition" problem. `randf()` is seeded from OS randomness in normal play; GUT tests can control via `seed()`.

## Architecture Diagram

```
audio_feedback.gd
  ├── 9× AudioStreamPlayer (one per sound type, all on SFX bus)
  │
  ├── _ready():
  │     connects to: tetromino.piece_locked, tetromino.hard_drop,
  │                  line_clear.lines_cleared, speed_progression.level_up,
  │                  combo_scoring.combo_x5, game_state.game_over
  │
  └── _play(player, volume_scalar):
        sets pitch_scale = randf_range(0.98, 1.02)
        sets volume_db = linear_to_db(master × sfx × scalar)
        calls player.play()

Signal flow:
  piece_locked  → _on_piece_locked   → _play(sfx_lock, 0.7)
  hard_drop     → _on_hard_drop      → _play(sfx_hard_drop, 0.6)
  lines_cleared → _on_lines_cleared  → _play(sfx_X, 0.8) by count
  level_up      → _on_level_up       → _play(sfx_level_up, 0.9)
  combo_x5      → _on_combo_x5       → _play(sfx_combo, 1.0)
  game_over     → _on_game_over      → _play(sfx_game_over, 1.0)
```

## Key Interfaces

```gdscript
# audio_feedback.gd
class_name AudioFeedback
extends Node

@export var tetromino: Node
@export var line_clear: Node
@export var speed_progression: Node
@export var combo_scoring: Node
@export var game_state: Node

func _ready() -> void:
    # Signal connections only — no state polling

func set_master_volume(vol: float) -> void:
    # vol: 0.0 to 1.0

func set_sfx_enabled(enabled: bool) -> void:
    # Toggle all sound playback
```

## Alternatives Considered

### Alternative 1: Single `AudioStreamPlayer` with audio queue

- **Description**: One player, a queue of pending sounds, `play()` calls dequeue and play sequentially.
- **Pros**: Minimal node count (1)
- **Cons**: Cannot play overlapping sounds — a Tetris sound while a lock click is playing would cut off the lock click. Queue management adds complexity for no benefit given the 9-sound variety in this game.
- **Rejection Reason**: The GDD explicitly says sounds that overlap mix together. A queue approach contradicts this.

### Alternative 2: `AudioStreamPlayer` with `mix_target = MIX_TARGET_ENVELOPE` for pitch

- **Description**: Use Godot's envelope system to handle pitch variation and volume.
- **Cons**: Overcomplicating a simple pitch/volume adjustment. `_play()` with `pitch_scale` and `volume_db` is adequate.
- **Rejection Reason**: Simpler approach (`pitch_scale` property) already works perfectly.

### Alternative 3: Audio pauses when game pauses

- **Description**: Connect `get_tree().paused` changes to pause all `AudioStreamPlayer` instances.
- **Cons**: The GDD explicitly says "Audio does NOT pause when game is paused" — this is a player-experience choice (rhythm continuity).
- **Rejection Reason**: Explicit GDD requirement. Audio should continue during pause.

## Consequences

### Positive

- All 9 sound types have independent, signal-driven playback
- Sounds that overlap simply mix — no cancellation, no queuing logic needed
- Pitch variation makes repeated sounds feel less robotic
- Audio does NOT pause with game — per GDD requirement
- Volume hierarchy (master × sfx × type) matches real game audio patterns
- `set_master_volume()` and `set_sfx_enabled()` are clean public APIs for a future options menu

### Negative

- 9 `AudioStreamPlayer` nodes in the scene tree — minor visual clutter, but each is a single line in the scene file
- `pitch_scale` is per-player-instance — setting it before `play()` works, but some Godot versions reset pitch on `stop()`. Mitigation: set pitch_scale in `_play()` immediately before `play()`, not in a separate function.

### Neutral

- Audio files (.ogg) must be provided and imported into the Godot project — this ADR covers the playback architecture, not the sound files themselves

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Sound file missing or not imported | Low | `play()` silently does nothing | Assert in `_ready()` that `player.stream != null`; GUT test verifies playback is called |
| Pitch scale reset on `stop()` call | Low | Pitch variation applies to wrong playback on rapid re-trigger | Set `pitch_scale` immediately before `play()`, not on `stop()` |
| Audio device unavailable | Very Low | No sound, game continues silently | `AudioStreamPlayer` handles this gracefully — `play()` becomes no-op |

## Performance Implications

- **CPU**: Negligible — audio playback is handled by Godot's audio thread, not the main loop
- **Memory**: 9 `AudioStreamPlayer` instances (~9KB total)
- **Load Time**: Audio files load into memory on first `play()` call (streaming), or on scene load if `load_on_start` is set in import options
- **Network**: None

## Migration Plan

- Greenfield — no existing audio code
- 9 `AudioStreamPlayer` nodes created as children of `audio_feedback.gd` in the scene
- Each player's `stream` property set to the appropriate imported `.ogg` file
- Each player's `bus` property set to `SFX`
- Signal connections established in `_ready()`

## Validation Criteria

- GIVEN `piece_locked` signal, WHEN received, THEN `sfx_lock.play()` is called with `pitch_scale` in range [0.98, 1.02] and `volume_db` reflecting master × sfx × 0.7
- GIVEN `lines_cleared(4)` signal, WHEN received, THEN `sfx_tetris.play()` is called (not `sfx_single`)
- GIVEN `set_sfx_enabled(false)`, WHEN any signal fires, THEN no `play()` call is made (no-op)
- GIVEN `set_master_volume(0.5)`, WHEN any signal fires, THEN volume_db = `linear_to_db(0.5 × 1.0 × scalar)`
- GUT test: `audio_feedback._play(sfx_lock, 0.7)` and assert `sfx_lock.is_playing()` returns true

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| audio-feedback-system.md | Audio Feedback | All 9 sound triggers defined | Each has a dedicated `AudioStreamPlayer` |
| audio-feedback-system.md | Audio Feedback | Sounds can overlap simultaneously | 9 independent players, no cancellation or queuing |
| audio-feedback-system.md | Audio Feedback | Audio does NOT pause when game pauses | No pause wiring — audio plays on signal receipt |
| audio-feedback-system.md | Audio Feedback | Volume hierarchy: master × sfx × type | `_play()` computes `linear_to_db(master × sfx × scalar)` |
| audio-feedback-system.md | Audio Feedback | Pitch variation 0.98-1.02 | `randf_range(1.0 - PITCH_VARIANCE, 1.0 + PITCH_VARIANCE)` before each play |
| audio-feedback-system.md | Audio Feedback | SOUND_ENABLED toggle | `set_sfx_enabled()` controls all `_play()` calls |
| combo-scoring-system.md | Audio Feedback | `combo_x5` signal fires when combo reaches ×5 | Audio connects to `combo_x5` for special chime |

## Related

- ADR-ARCH-002 (Signal Bus) — all audio triggers are signal-driven
- ADR-ARCH-003 (Scene Tree) — `audio_feedback.gd` is a child of `main.tscn`
- ADR-ARCH-007 (Visual Effects) — shares signal-driven presentation pattern with visual effects