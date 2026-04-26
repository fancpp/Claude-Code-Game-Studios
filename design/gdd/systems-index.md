# Systems Index: Tetris Arcade Challenge

> **Status**: Draft
> **Created**: 2026-04-26
> **Last Updated**: 2026-04-26
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Tetris Arcade Challenge is a classic falling-block puzzle game with combo-driven scoring. The mechanical scope is intentionally focused — it requires a precise grid system, seven distinct tetrominoes with rotation, collision detection, line clearing with combo rewards, and a linear speed progression. The entire game runs on a single 10×20 play field. No persistent world, no characters, no narrative — just pure mechanical mastery. All systems serve the core loop: place pieces, clear lines, build combos, survive the escalating speed.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Grid System | Core | MVP | Complete | design/gdd/grid-system.md | (none — foundation) |
| 2 | Input System | Core | MVP | Complete | design/gdd/input-system.md | (none — foundation) |
| 3 | Collision System | Core | MVP | Complete | design/gdd/collision-system.md | Grid System |
| 4 | Tetromino System | Gameplay | MVP | Complete | design/gdd/tetromino-system.md | Grid System, Collision System |
| 5 | Piece Spawn System | Gameplay | MVP | Complete | design/gdd/piece-spawn-system.md | Tetromino System |
| 6 | Game State System | Core | MVP | Complete | design/gdd/game-state-system.md | Grid System, Collision System |
| 7 | Line Clearing System | Gameplay | MVP | Complete | design/gdd/line-clearing-system.md | Tetromino System, Grid System, Collision System |
| 8 | Combo Scoring System | Gameplay | MVP | Complete | design/gdd/combo-scoring-system.md | Line Clearing System |
| 9 | Ghost Piece System | Gameplay | MVP | Complete | design/gdd/ghost-piece-system.md | Tetromino System, Grid System |
| 10 | Speed Progression System | Progression | MVP | Complete | design/gdd/speed-progression-system.md | Game State System |
| 11 | Score Display System | UI | MVP | Needs Revision | design/gdd/score-display-system.md | Combo Scoring System, Speed Progression System |
| 12 | Visual Feedback System | UI | Vertical Slice | Needs Revision | design/gdd/visual-feedback-system.md | Line Clearing System, Combo Scoring System |
| 13 | Audio Feedback System | Audio | Vertical Slice | Complete | design/gdd/audio-feedback-system.md | Line Clearing System, Game State System |

---

## Categories

| Category | Description | Systems in This Project |
|----------|-------------|------------------------|
| **Core** | Foundation systems everything depends on | Grid System, Input System, Collision System, Game State System |
| **Gameplay** | The systems that make the game fun | Tetromino System, Piece Spawn System, Line Clearing System, Combo Scoring System, Ghost Piece System, Speed Progression System |
| **UI** | Player-facing information displays | Score Display System, Visual Feedback System |
| **Audio** | Sound and music systems | Audio Feedback System |
| **Progression** | How the player grows over time | Speed Progression System |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Systems |
|------|------------|------------------|---------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | First playable prototype (4-6 weeks) | Grid, Input, Collision, Tetromino, Piece Spawn, Game State, Line Clearing, Combo Scoring, Ghost Piece, Speed Progression, Score Display |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Vertical slice (6-8 weeks) | Visual Feedback, Audio Feedback |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha (8-10 weeks) | (none — MVP + VS = Alpha scope) |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release (10-12 weeks) | (all systems complete) |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Grid System** — The 10×20 play field. All gameplay happens on the grid. No other system can exist without it.
2. **Input System** — Captures keyboard events. Without input, the player cannot interact with anything.

### Core Layer (depends on foundation)

1. **Collision System** — depends on: Grid System. Detects when tetrominoes hit walls, floor, or other pieces.
2. **Game State System** — depends on: Grid System, Collision System. Manages playing/paused/game-over transitions.

### Gameplay Layer (depends on core)

1. **Tetromino System** — depends on: Grid System, Collision System. Defines the 7 tetromino shapes and SRS rotation.
2. **Piece Spawn System** — depends on: Tetromino System. Uses 7-bag randomizer to spawn the next piece.
3. **Ghost Piece System** — depends on: Tetromino System, Grid System. Shows where the current piece will land.
4. **Line Clearing System** — depends on: Tetromino System, Grid System, Collision System. Detects and removes completed rows.
5. **Speed Progression System** — depends on: Game State System. Increases drop speed as level increases (linear curve).

### Feature Layer (depends on gameplay)

1. **Combo Scoring System** — depends on: Line Clearing System. Tracks consecutive clears, applies multiplier.

### Presentation Layer (depends on feature)

1. **Score Display System** — depends on: Combo Scoring System, Speed Progression System. Renders score, level, combo to screen.
2. **Visual Feedback System** — depends on: Line Clearing System, Combo Scoring System. Flashes, shakes, pulses on events.
3. **Audio Feedback System** — depends on: Line Clearing System, Game State System. Plays sounds on clear, game over, etc.

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort |
|-------|--------|----------|-------|-------------|
| 1 | Grid System | MVP | Foundation | S |
| 2 | Input System | MVP | Foundation | S |
| 3 | Collision System | MVP | Core | S |
| 4 | Game State System | MVP | Core | S |
| 5 | Tetromino System | MVP | Gameplay | M |
| 6 | Piece Spawn System | MVP | Gameplay | S |
| 7 | Ghost Piece System | MVP | Gameplay | S |
| 8 | Line Clearing System | MVP | Gameplay | M |
| 9 | Combo Scoring System | MVP | Feature | M |
| 10 | Speed Progression System | MVP | Gameplay | S |
| 11 | Score Display System | MVP | Presentation | S |
| 12 | Visual Feedback System | Vertical Slice | Presentation | M |
| 13 | Audio Feedback System | Vertical Slice | Presentation | S |

---

## Circular Dependencies

- **None found** — All dependencies flow in one direction from foundation to presentation.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Tetromino System (SRS rotation) | Technical | SRS has many edge cases (wall kicks). Implementing incorrectly causes pieces to clip through walls or behave unpredictably. | Use established reference implementation. Prototype rotation early. |
| Line Clearing System | Design | Multiple line clears at once (Tetris) need correct ordering and stack collapse. Buggy collapse breaks the game. | Unit test all line count scenarios (1-4 lines). |
| Collision System | Technical | Collision detection must be pixel-perfect with no tunneling at high speeds. | Test at max speed. Ensure no pieces pass through each other. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 13 |
| Design docs started | 13 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 11/11 |
| Vertical Slice systems designed | 2/2 |

---

## Next Steps

- [ ] Review and approve this systems index
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype the highest-risk system early (`/prototype [tetromino-system]`) — SRS rotation is the hardest technical piece