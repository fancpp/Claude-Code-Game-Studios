# Piece Spawn System

> **Status**: In Design
> **Author**: Claude Code (with user collaboration)
> **Last Updated**: 2026-04-26
> **Implements Pillar**: Pillar 1 — Operation Precision

## Overview

The Piece Spawn System manages tetromino randomization using the 7-bag randomizer, maintains the next-piece preview queue, and orchestrates piece spawning at the beginning of each piece's life. It ensures fair piece distribution (each piece appears once per 7-piece bag before the bag reshuffles), determines spawn position, and detects spawn failure when the spawn cell is occupied (triggering game over). The system provides the randomness that creates variety within the otherwise deterministic gameplay.

## Player Fantasy

"The next piece is always a surprise — but a fair one." The player trusts the randomizer because they know every piece will come eventually. No piece feels "stolen" by bad luck; no piece feels "given" by over-generation. The preview shows what's coming, letting the player plan ahead while maintaining the tension of uncertainty. When the next piece appears, it feels like the natural progression of the game, not an interruption.

## Detailed Design

### Core Rules

**7-Bag Randomizer:**
The 7-bag randomizer shuffles all 7 tetromino types into a bag, then deals them out one at a time. When the bag is empty, it reshuffles. This guarantees fairness: no piece can appear more than twice in a row, and all pieces appear with equal probability over any 7-piece window.

**Bag Algorithm:**
```
bag = [1, 2, 3, 4, 5, 6, 7]  # shuffled at start
shuffle(bag)
while bag not empty:
  piece = bag.pop()
  emit piece
  if bag empty:
    bag = [1, 2, 3, 4, 5, 6, 7]
    shuffle(bag)
```

**Spawn Position:**
- X = 4 (horizontal center of 10-column grid)
- Y = 19 (top row, so piece appears at top of visible area)

**Spawn Process:**
1. Take next piece type from bag
2. Create Tetromino instance at spawn position, rotation 0
3. Check if spawn cell (4, 19) is occupied via Collision System
4. If occupied → emit `spawn_failed` signal → Game Over
5. If clear → emit `piece_spawned` signal → piece becomes active

**Next Piece Queue:**
- Queue holds N pieces ahead of current piece
- When a piece locks, the next piece from queue becomes active
- Queue is refilled from the bag as needed to maintain size

### States and Transitions

| State | Description | Entry Condition | Exit Condition |
|-------|-------------|-----------------|----------------|
| WAITING | No piece active, waiting for game to start | Game in IDLE state | Game starts → spawn first piece |
| SPAWNING | About to spawn a new piece | `request_spawn()` called | Spawn check passes → ACTIVE; spawn check fails → GAME_OVER |
| ACTIVE | Current piece is playing | Spawn check passes | Piece locks → SPAWNING |

**Internal State:**
- current_bag: array of remaining piece types in current bag
- next_queue: array of queued piece types for preview
- spawn_count: total pieces spawned this game (for statistics)

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Tetromino System | Output | Provides piece type, spawn position; receives `piece_locked` to trigger next spawn |
| Collision System | Input | `is_empty(x, y)` to check if spawn position is clear |
| Game State System | Input | Receives game state; emits `spawn_failed` when game over detected |
| Score Display System | Output | Provides next-piece preview data for queue display |

## Formulas

**7-Bag Shuffle (Fisher-Yates):**
```
for i from bag.length-1 down to 1:
  j = random(0, i)  # inclusive
  swap bag[i], bag[j]
```

**Queue Refill:**
```
while next_queue.length < PREVIEW_COUNT:
  if bag.empty:
    bag = [1,2,3,4,5,6,7]
    shuffle(bag)
  next_queue.append(bag.pop())
```

**Spawn Check:**
```
spawn_pos = (4, 19)
can_spawn = is_empty(spawn_pos.x, spawn_pos.y)
if not can_spawn:
  emit spawn_failed
  transition to GAME_OVER
else:
  emit piece_spawned(type)
```

## Edge Cases

- **If spawn position is occupied on first piece**: Game over immediately — grid was not properly cleared
- **If spawn position is occupied after pieces have been placed**: Game over — stack reached the top
- **If bag is empty when getting next piece**: Reshuffle immediately (guaranteed by algorithm, but defensive check)
- **If game restarts mid-piece**: Reset bag, clear queue, start fresh from first piece of new game
- **If piece locks and queue is empty**: This cannot happen if queue is maintained correctly (always pre-filled)
- **If random seed is manipulated**: 7-bag prevents extreme streak manipulation — at most 2 of same piece in sequence

## Dependencies

**Upstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Collision System | `is_empty(x, y)` | Checks if spawn cell is unoccupied |

**Downstream:**
| System | Interface | Expected Behavior |
|--------|-----------|-------------------|
| Tetromino System | `request_spawn()`, piece type | Creates piece with given type at spawn position |
| Game State System | `spawn_failed` signal | Triggers GAME_OVER state transition |
| Score Display System | Next piece queue data | Displays upcoming pieces to player |

**Hard vs. Soft:**
- **HARD** — Tetromino System, Collision System (cannot spawn without knowing spawn state and piece factory)
- **SOFT** — Score Display System (preview is nice-to-have but game is playable without it)

## Tuning Knobs

| Parameter | Default | Safe Range | Effect |
|-----------|---------|------------|--------|
| PREVIEW_COUNT | 1 | 1-5 | Number of pieces shown in preview queue |
| BAG_SIZE | 7 | 7 (fixed) | Pieces per bag — changing breaks fairness guarantee |

## Acceptance Criteria

- **GIVEN** a new game starts, **WHEN** the first piece is spawned, **THEN** the bag contains all 7 piece types shuffled.
- **GIVEN** bag contains 7 pieces, **WHEN** a piece is drawn, **THEN** the bag has 6 remaining pieces.
- **GIVEN** bag becomes empty, **WHEN** next piece is requested, **THEN** a new shuffled bag of 7 pieces is created.
- **GIVEN** spawn position (4, 19) is unoccupied, **WHEN** `request_spawn()` is called, **THEN** `piece_spawned` signal is emitted with next piece type.
- **GIVEN** spawn position (4, 19) is occupied, **WHEN** `request_spawn()` is called, **THEN** `spawn_failed` signal is emitted and game transitions to GAME_OVER.
- **GIVEN** the queue needs to be filled, **WHEN** pieces are drawn from the bag, **THEN** the preview queue maintains PREVIEW_COUNT pieces.
- **GIVEN** no same piece type has appeared in the last 6 pieces, **WHEN** the last piece of the bag is drawn, **THEN** the next piece must be from the new reshuffled bag (impossible to have 3 of same in a row).

## Open Questions

[To be designed]