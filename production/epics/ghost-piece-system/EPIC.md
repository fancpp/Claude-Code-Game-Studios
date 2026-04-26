# Epic: Ghost Piece System

> **Layer**: Feature
> **GDD**: design/gdd/ghost-piece-system.md
> **Architecture Module**: Feature / Ghost Piece
> **Status**: Ready
> **Stories**: 2 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Ghost Piece System calculates and renders a translucent preview showing where the current tetromino will land if dropped straight down. It ray-casts downward from the active piece's current position through the Grid System until it hits an occupied cell or the floor, then provides the ghost position for rendering. The ghost mirrors the active piece's shape and rotation but with a distinct visual style (30% opacity, outline/dotted).

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| (no dedicated ADR — ghost calculation is a pure query over the Grid API) | Ghost calculation via grid queries, rendering via Visual Feedback | LOW |

---

## GDD Requirements

| TR-ID | Requirement | Status |
|-------|-------------|--------|
| TR-ghost-001 | Ghost calculation: ray-cast down from current position until collision, returns ghost_y | Active |
| TR-ghost-002 | Ghost visual: 30% opacity, outline or dotted style, renders behind active piece | Active |

---

## Definition of Done

This epic is complete when:
- `ghost_piece.gd` implements `calculate_ghost_y(piece_x, piece_y, piece_shape) -> int` in `src/ghost_piece/`
- Ghost position updates in real-time with piece movement and rotation
- Rendering (30% opacity, outline style) is handled by the rendering layer — ghost_piece.gd provides ghost position data
- Unit tests in `tests/unit/ghost_piece/` cover all edge cases

---

## Stories

| # | Story | Type | Status | Dependencies |
|---|-------|------|--------|--------------|
| 001 | Ghost Calculation — ray-cast down to find drop destination | Logic | Ready | grid-system stories, tetromino-system stories (for piece state) |
| 002 | Ghost Rendering — 30% opacity, outline/dotted visual style | Visual/Feel | Ready | story 001, visual-feedback-system stories |

## Dependency Order

`ghost-piece-system` depends on:
- `grid-system` stories (all must be done)
- `tetromino-system` stories (for piece position and shape signals)
- Rendering depends on `visual-feedback-system` stories

Advance `grid-system` and `tetromino-system` before starting story 001.