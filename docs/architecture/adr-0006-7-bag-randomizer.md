# ADR-ARCH-006: 7-Bag Randomizer

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

The 7-bag randomizer shuffles all 7 tetromino types into a bag, deals them one at a time, and refills the bag when empty. This guarantees each piece appears at least once per 7-piece cycle while maintaining randomness within the cycle. It prevents the extreme droughts (or floods) of specific pieces that true random suffers from.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Randomness |
| **Knowledge Risk** | LOW — shuffling algorithm is language-agnostic, no engine API |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-004 (Shape Storage) — piece types 1-7 are defined there |
| **Enables** | Tetromino System, Piece Spawn System |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before Piece Spawn System implementation |

## Context

### Problem Statement

Pure random piece selection (e.g., `randi() % 7 + 1`) produces unpredictable and often unfair distribution. A player can go 20+ pieces without an I-piece, or receive 4 S-pieces in a row. The 7-bag randomizer solves this by ensuring fairness within each 7-piece cycle while preserving the psychological feel of randomness.

### Constraints

- All 7 tetromino types must appear at least once per 7-piece cycle
- Within a cycle, order must be unpredictable
- Must be deterministic in tests (seedable) but unpredictable in play
- Must be fast — called once per piece spawn

### Requirements

- Shuffle all 7 types into a new random order when bag is first created or when it empties
- `get_next()` returns the first element and removes it from the bag
- When bag is empty, automatically refill and reshuffle

## Decision

**Pattern: Fisher-Yates shuffle on a 7-element array, managed by `PieceBag` class.**

```gdscript
# piece_bag.gd
class_name PieceBag
extends RefCounted

var _bag: Array = []
var _rng: RandomNumberGenerator

func _init(seed_value: int = 0) -> void:
    _rng = RandomNumberGenerator.new()
    if seed_value != 0:
        _rng.seed = seed_value
    _shuffle_bag()

func _shuffle_bag() -> void:
    # Fisher-Yates shuffle on [1,2,3,4,5,6,7]
    _bag = [1, 2, 3, 4, 5, 6, 7]
    for i in range(_bag.size() - 1, 0, -1):
        var j := _rng.randi() % (i + 1)
        var tmp := _bag[i]
        _bag[i] = _bag[j]
        _bag[j] = tmp

func get_next() -> int:
    if _bag.is_empty():
        _shuffle_bag()
    return _bag.pop_front()
```

**In `piece_spawn.gd`:**
```gdscript
@onready var _bag: PieceBag = PieceBag.new()
@onready var _next_piece_type: int = _bag.get_next()

func get_next_piece_type() -> int:
    var piece_type := _next_piece_type
    _next_piece_type = _bag.get_next()
    return piece_type
```

**Why Fisher-Yates over `shuffle()`?**
GDScript's built-in `Array.shuffle()` uses Godot's global `randi()` — it cannot accept a `RandomNumberGenerator` instance, making it non-deterministic in tests. Fisher-Yates with an explicit `_rng` instance is deterministic when seeded, which is required for reproducible GUT tests.

**Why `pop_front()` instead of index 0?**
`_bag` is an `Array` (not `ArrayQueue`). `pop_front()` is O(n) on Array. For n=7 this is trivially negligible (~7 comparisons). No need for a `Deque` data structure.

**Seeded constructor for testing:**
`PieceBag.new(seed)` accepts a seed for deterministic test sequences. Without a seed, `_rng` uses a random seed from the OS. Tests use `PieceBag.new(12345)` to get reproducible piece sequences.

**Shuffle on construction AND on empty:**
Bag is shuffled in `_init()` so the first piece is random. Subsequent `get_next()` calls return elements in shuffled order. When `pop_front()` empties the bag, the next call to `get_next()` triggers a fresh shuffle.

## Architecture Diagram

```
piece_spawn.gd
  ├── _bag: PieceBag (class_name PieceBag, refilled automatically)
  ├── _next_piece_type: int  (peek at next piece, for queue display)
  │
  └── spawn_piece():
        piece_type = _bag.get_next()     ← pops and refills bag if empty
        _next_piece_type = _bag.get_next() ← peek for queue display
        → emits piece_spawned(piece_type)
        → requests tetromino.gd to activate piece_type

PieceBag (class_name PieceBag extends RefCounted)
  ├── _bag: Array[1-7]  (7 tetromino types, shuffled)
  ├── _rng: RandomNumberGenerator
  ├── get_next() → int  (pops first element, reshuffles when empty)
  └── _shuffle_bag()    (Fisher-Yates on [1,2,3,4,5,6,7])
```

## Key Interfaces

```gdscript
class_name PieceBag
extends RefCounted

func _init(seed_value: int = 0) -> void:
    # seed_value=0 means use OS random seed (normal gameplay)
    # seed_value!=0 sets deterministic seed (tests)

func get_next() -> int:
    # Returns next piece type (1-7), refills bag if empty
    # O(1) amortized — pop_front() on Array is O(n) but bag has max 7 elements
```

## Alternatives Considered

### Alternative 1: True random with history buffer

- **Description**: `randi() % 7 + 1` with a "no-duplicate" rule: if the new piece matches the previous N pieces, re-roll.
- **Pros**: Simple
- **Cons**: Doesn't guarantee fairness over time — can still get long droughts; re-rolls are invisible to the player and feel like "stuck" pieces
- **Rejection Reason**: Doesn't prevent droughts, just reduces them. Complex history tracking adds state without solving the core problem.

### Alternative 2: Ghostly's "bag + history" system

- **Description**: 7-bag + a "history" of the last N pieces, with re-rolls if the next bag would produce a piece already in history.
- **Pros**: Even better fairness
- **Cons**: Over-engineering for a Tetris game. Standard 7-bag is accepted by the Tetris community as sufficient fairness.
- **Rejection Reason**: Unnecessary complexity. Standard 7-bag is industry-standard and sufficient.

### Alternative 3: Shuffle with `Array.shuffle()` (no explicit RNG)

- **Description**: `_bag.shuffle()` using Godot's global `randi()`.
- **Pros**: One line of code
- **Cons**: Non-deterministic in tests — cannot seed for reproducibility. GUT tests need deterministic piece sequences to verify spawn behavior.
- **Rejection Reason**: Tests must be deterministic. Explicit `RandomNumberGenerator` with a seeded constructor is required.

## Consequences

### Positive

- Fair piece distribution: each piece type appears at least once per 7-piece cycle
- Within a cycle, order is unpredictable
- Deterministic in tests: `PieceBag.new(12345)` produces the same sequence every time
- Industry-standard approach: 7-bag is the accepted Tetris randomizer
- Simple implementation: Fisher-Yates shuffle fits in 10 lines

### Negative

- Predictable within a cycle if player tracks bag contents (not a concern for casual play; known by competitive players but still fair)

### Neutral

- The "peek" (`_next_piece_type`) supports a next-piece preview in the queue without changing bag logic

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| `shuffle_bag()` creates unbalanced first bag after a specific sequence | Low | Player perception of unfairness | Fisher-Yates is unbiased; perception issues are psychological not statistical |
| Tests using non-seeded bag are non-deterministic | Medium | Flaky tests | GUT tests MUST use `PieceBag.new(seed)` for reproducibility |

## Performance Implications

- **CPU**: Negligible — shuffle on 7 elements (≤21 swap operations) once per 7 pieces
- **Memory**: 7 integers in `_bag` + 1 `RandomNumberGenerator` instance
- **Load Time**: Negligible
- **Network**: None

## Migration Plan

- Greenfield — no existing piece selection code
- `piece_bag.gd` created with Fisher-Yates shuffle
- `piece_spawn.gd` creates one `PieceBag` instance on `_ready()`
- Tests use `PieceBag.new(test_seed)` for deterministic sequences

## Validation Criteria

- `PieceBag.new(12345).get_next()` called 7 times returns all types 1-7 with no duplicates
- After 7 calls, bag is automatically refilled (8th call returns a piece, not error)
- `PieceBag.new()` (no seed) produces a different first sequence each run (use OS randomness)
- GUT tests: with `PieceBag.new(42)`, the 1st through 7th calls return predictable values, enabling deterministic spawn tests

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| piece-spawn-system.md | Piece Spawn | 7-bag randomizer for fair piece distribution | Fisher-Yates shuffle on [1,2,3,4,5,6,7] with automatic refill |
| tetromino-system.md | Tetromino | Piece spawns at x=4, y=19 | Spawn position defined in `piece_spawn.gd`, not in bag logic |

## Related

- ADR-ARCH-004 (Shape Storage) — piece types 1-7 are defined via `TetrominoShapes.SHAPES`
- ADR-ARCH-003 (Scene Tree) — `piece_spawn.gd` is a child of `main.tscn`