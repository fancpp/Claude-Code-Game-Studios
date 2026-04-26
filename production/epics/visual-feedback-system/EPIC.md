# Epic: Visual Feedback System

> **Layer**: Presentation
> **GDD**: design/gdd/visual-feedback-system.md
> **Architecture Module**: Presentation / Visual Effects
> **Status**: Ready
> **Stories**: 3 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Visual Feedback System provides immediate visual responses to gameplay events: white screen flash on line clear (intensity scales with clear type), screen shake on Tetris, gold combo glow at x5, level-up flash, and instant screen dim on game over. Effects are additive and coexist — multiple effects can play simultaneously without cancellation. All effects are driven by signals from upstream systems and managed in `_process()` with delta-accumulation (same auto-pause pattern as the lock delay timer).

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-ARCH-007: Visual Effects Architecture | `ColorRect` overlays for flash/glow, `Node2D` offset for shake, `_process()` delta timing | MEDIUM — Godot 4.6 changed glow-before-tonemapping; flash brightness needs playtest verification |

---

## GDD Requirements

| TR-ID | Requirement | Status |
|-------|-------------|--------|
| TR-visual-001 | Flash overlays: white ColorRect at 30% opacity, durations 100-300ms by clear type, linear decay | Active |
| TR-visual-002 | Screen shake: random x/y offset, magnitude 2-8px by clear type, linear decay | Active |
| TR-visual-003 | Combo x5 glow: gold ColorRect around combo display, 500ms fade out | Active |
| TR-visual-004 | Game over: screen dims to 50% overlay, instant application | Active |

---

## Definition of Done

This epic is complete when:
- `visual_feedback.gd` is implemented in `src/visual_feedback/` with all 5 effect types
- `flash_overlay`, `combo_glow_overlay`, `dim_overlay` ColorRect nodes exist in scene tree
- `_process()` manages all timing with linear decay
- All acceptance criteria from `design/gdd/visual-feedback-system.md` verified by playtest screenshot

---

## Stories

| # | Story | Type | Status | Dependencies |
|---|-------|------|--------|--------------|
| 001 | Flash + Shake Effects — white flash and screen shake on line clear | Visual/Feel | Ready | line-clear-system stories, visual-feedback-system |
| 002 | Combo Glow — gold glow around combo display at x5, 500ms fade | Visual/Feel | Ready | combo-scoring-system stories (combo_x5 signal) |
| 003 | Game Over Dim — 50% dim overlay, instant, persists until new game | Visual/Feel | Ready | game-state-system stories (game_over signal) |

## Dependency Order

`visual-feedback-system` is a presentation layer system that subscribes to signals from Feature and Core layer systems. It can be implemented once the upstream systems it subscribes to have defined their signal interfaces (even if signals are not yet wired).

Advance the relevant upstream systems before verification:
- `line-clear-system` for flash/shake (Story 001)
- `combo-scoring-system` for combo glow (Story 002)
- `game-state-system` for game over dim (Story 003)