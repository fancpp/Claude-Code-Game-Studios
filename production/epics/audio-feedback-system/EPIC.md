# Epic: Audio Feedback System

> **Layer**: Presentation
> **GDD**: design/gdd/audio-feedback-system.md
> **Architecture Module**: Presentation / Audio
> **Status**: Ready
> **Stories**: 2 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Audio Feedback System provides satisfying sound effects for all gameplay events: lock click, line clears (single through Tetris), level up, combo x5 chime, game over, and hard drop. It uses 9 `AudioStreamPlayer` instances (one per sound type), signal-driven playback, hierarchical volume control, and subtle pitch variation to prevent audible repetition. Audio does NOT pause when the game pauses (explicit design decision per GDD).

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-ARCH-008: Audio Architecture | 9-instance `AudioStreamPlayer` pool, signal-driven, Godot audio bus, pitch variation, audio does NOT pause with game | LOW |

---

## GDD Requirements

| TR-ID | Requirement | Status |
|-------|-------------|--------|
| TR-audio-001 | 9 sound types with defined durations and behaviors | Active |
| TR-audio-002 | Volume hierarchy: effective_volume = master_volume * sfx_volume * sound_type_scalar | Active |
| TR-audio-003 | Pitch variation: base_pitch * uniform_random(0.98, 1.02) per playback | Active |
| TR-audio-004 | Audio continues during pause (explicit design choice — not affected by game pause) | Active |

---

## Definition of Done

This epic is complete when:
- `audio_feedback.gd` is implemented in `src/audio_feedback/` with all 9 `AudioStreamPlayer` instances
- All signal connections established in `_ready()`: `piece_locked`, `hard_drop`, `lines_cleared`, `level_up`, `combo_x5`, `game_over`
- `set_master_volume()`, `set_sfx_enabled()` public APIs implemented
- Tests in `tests/unit/audio_feedback/` verify signal routing and volume math

---

## Stories

| # | Story | Type | Status | Dependencies |
|---|-------|------|--------|--------------|
| 001 | SFX Playback — 9 sound signal handlers, pitch variation | Visual/Feel | Ready | tetromino-system stories, line-clear-system stories, combo-scoring-system stories, speed-progression-system stories |
| 002 | Volume + Pitch System — volume hierarchy, pitch variation, SOUND_ENABLED toggle | Logic | Ready | story 001 |

## Dependency Order

`audio-feedback-system` subscribes to signals from multiple Feature and Core layer systems. Implementation can proceed once those systems have defined their signal interfaces. Verification requires actual sound files (.ogg) imported into the project.

Advance the following systems before verification:
- `tetromino-system` (piece_locked, hard_drop signals)
- `line-clear-system` (lines_cleared signal)
- `combo-scoring-system` (combo_x5 signal)
- `speed-progression-system` (level_up signal)
- `game-state-system` (game_over signal)