# Epic: game-state-system

> **Epic ID**: game-state-system
> **Status**: Ready
> **Stage**: Pre-Production
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26

## Overview

The Game State System manages the high-level state machine of the game: IDLE, PLAYING, PAUSED, and GAME_OVER. It controls which subsystems are active, responds to pause input, detects game-over conditions, and orchestrates new game initialization. It is the top-level coordinator — other systems run only when this system permits them.

## Governing ADRs

| ADR | Topic | Impact |
|-----|-------|--------|
| ADR-001 | Grid Resource Pattern | New game init calls clear_grid on injected Grid ref |
| ADR-002 | Signal Bus | State change signals emitted via signal bus |
| ADR-003 | Scene Tree | Game state node wired to all child systems |

## GDD Source

`design/gdd/game-state-system.md`

## TR Registry

| ID | Requirement |
|----|-------------|
| TR-game-state-001 | 4 states: IDLE/PLAYING/PAUSED/GAME_OVER with defined transitions |
| TR-game-state-002 | Game over detection: spawn position (x=4, y=19) occupied |
| TR-game-state-003 | New game init: clear_grid, reset score/level/combo to 0, spawn first piece |

## Stories

| # | Story | Type | TR IDs | Status |
|---|-------|------|--------|--------|
| 001 | Game State Machine | Logic | TR-game-state-001, TR-game-state-002 | Ready |
| 002 | New Game Initialization | Logic | TR-game-state-003 | Ready |

## Dependencies

**Hard dependencies:**
- Grid System (clear_grid) — story 002 blocked until grid-system stories complete

**Soft dependencies:**
- Input System (pause signal) — game can run without pause if input is broken

**Downstream dependents:**
- All gameplay systems (state signals enable/disable based on game state)
- Score Display System (receives reset on new game)
- Speed Progression System (receives level reset on new game)
- Combo Scoring System (receives combo reset on new game)

## Layer

Core

## Risk

LOW — State machine with boolean conditions, no complex math or engine-specific APIs

## Notes

Game over detection (TR-game-state-002) is triggered externally by the Spawn System when it finds the spawn position occupied. The Game State System receives this information and transitions to GAME_OVER. The actual spawn position check is in the Piece Spawn System.