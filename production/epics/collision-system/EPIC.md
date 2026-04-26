# Epic: collision-system

> **Epic ID**: collision-system
> **Status**: Ready
> **Stage**: Pre-Production
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26

## Overview

The Collision System determines whether a tetromino can occupy a specific position on the grid. It checks if the target cells are within bounds and unoccupied. All movement requests (left, right, down, rotation) pass through collision detection before being confirmed. The system is a pure query: it reads the grid state and returns true/false, never modifying the grid.

## Governing ADRs

| ADR | Topic | Impact |
|-----|-------|--------|
| ADR-001 | Grid Resource Pattern | Collision queries grid via injected Grid ref |
| ADR-002 | Signal Bus | Lock event uses signal bus |
| ADR-003 | Scene Tree | Collision logic lives in a CollisionSystem node |

## GDD Source

`design/gdd/collision-system.md`

## TR Registry

| ID | Requirement |
|----|-------------|
| TR-collision-001 | `can_move_to(x, y, tetromino_shape) -> bool` queries grid for collision |
| TR-collision-002 | 3 collision types: Wall, Floor, Stack |
| TR-collision-003 | Wall kick offsets: 6 positions tested |
| TR-collision-004 | Lock delay: 500ms, resets on valid move, hard drop locks immediately |

## Stories

| # | Story | Type | TR IDs | Status |
|---|-------|------|--------|--------|
| 001 | Collision Detection API | Logic | TR-collision-001, TR-collision-002 | Ready |
| 002 | Wall Kick and Lock Delay | Logic | TR-collision-003, TR-collision-004 | Ready |

## Dependencies

**Hard dependencies:**
- Grid System (is_valid_position, is_empty) — story 001 blocked until grid-system stories complete

**Downstream dependents:**
- Tetromino System (uses can_move_to result to allow/deny moves)
- Game State System (receives lock event when piece lands)

## Layer

Core

## Risk

LOW — Pure query functions, no engine-specific APIs beyond basic GDScript

## Notes

Lock delay (TR-collision-004) is implemented by the Tetromino System but the lock condition (when can_move_to returns false) is defined by this system. Wall kick offsets (TR-collision-003) are applied by the Tetromino System's rotation logic; the collision system defines the offset list.