# ADR-ARCH-002: Signal Bus Architecture

## Status
Accepted

## Date
2026-04-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Communication Pattern |
| **Knowledge Risk** | LOW — Godot signals are stable from 2.0 through 4.6; this decision is about architecture, not engine API |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-001 (Grid System Resource Pattern) |
| **Enables** | All gameplay system ADRs (ARCH-003 through ARCH-011) |
| **Blocks** | Nothing (enables everything but doesn't block) |
| **Ordering Note** | Must be Accepted before gameplay system implementation begins |

## Context

### Problem Statement
The game has 13 systems that must communicate without importing each other. Specifically:
- `line_clear.gd` emits one signal (`lines_cleared`) that fans out to 4 consumers: `combo_scoring.gd`, `speed_progression.gd`, `visual_feedback.gd`, `audio_feedback.gd`
- `tetromino.gd` emits `piece_locked` → `line_clear.gd` and `piece_spawn.gd`
- `game_state.gd` emits `new_game` → `combo_scoring.gd`, `speed_progression.gd`

**The question is:** should each producer emit Godot signals directly from its nodes, with consumers using `connect()` to bind callbacks? Or should all signals route through a central `EventBus` autoload singleton that decouples producers from consumers entirely?

### Constraints
- Must support the full signal map (15 signals identified in architecture.md Phase 3)
- Must not create circular imports between systems
- Must be traceable: for any signal, must be able to answer "who emits this, who listens"
- Must work with the GUT testing framework (signals should be mockable/connectable in tests)

### Requirements
- All 15 signals from the signal map must be implementable
- Signal routing must be observable (debuggable)
- Systems must be independently testable
- No tight coupling via direct imports

## Decision

**Pattern: Native Godot signals (producer emits from itself) — NO central EventBus.**

Each producer node defines its own signals as `signal` declarations. Consumers connect via `connect()` in their `_ready()` methods. The signal map in `architecture.md Phase 3` is the authoritative source of truth for "who emits what."

```gdscript
# line_clear.gd — producer defines and emits its own signal
class_name LineClear
extends Node

signal lines_cleared(count: int)  # native Godot signal

func on_piece_locked() -> void:
    var count = check_and_collapse()
    if count > 0:
        emit_signal("lines_cleared", count)  # emitted from self
```

```gdscript
# combo_scoring.gd — consumer connects in _ready
class_name ComboScoring
extends Node

@export var line_clear: LineClear

func _ready() -> void:
    line_clear.lines_cleared.connect(_on_lines_cleared)

func _on_lines_cleared(count: int) -> void:
    # process combo
    pass
```

**Why not a central EventBus autoload?**
- An EventBus autoload is a global singleton — same problem as grid-as-autoload (ADR-ARCH-001 rejection reason)
- It hides the actual signal routing: you see `EventBus.emit("lines_cleared", count)` but can't trace which node actually emitted it
- It makes testing harder: you'd need to mock the EventBus singleton
- Native Godot signals are fully observable in the Godot debugger's nsights panel
- The fan-out pattern (`lines_cleared` → 4 consumers) works perfectly with native signals — no intermediate bus needed

**The signal map IS the contract:**

| Signal | Producer | Consumers | Pattern |
|--------|----------|-----------|---------|
| `piece_locked` | tetromino.gd | line_clear, piece_spawn | direct |
| `lines_cleared(count)` | line_clear.gd | combo, speed, visual, audio | fan-out |
| `level_up(new_level)` | speed_progression.gd | visual, audio, score_display | fan-out |
| `game_over` | game_state.gd | visual, audio | fan-out |
| `new_game` | game_state.gd | combo, speed | direct |
| `pause` | input_handler.gd | game_state | direct |

**Connection ownership:** The consumer owns the `connect()` call in `_ready()`. The producer does not know who is listening — it simply emits. This is the standard Godot pattern and it works.

**Disconnect on free:** Consumers should not manually disconnect in `_exit_tree()` — Godot handles signal disconnection when nodes are freed. If a system is disabled rather than freed, it should disconnect explicitly.

## Architecture Diagram

```
tetromino.gd
  └── signal piece_locked
        ├──► line_clear.gd.lines_cleared.connect(...)
        └──► piece_spawn.gd.on_piece_locked(...)

line_clear.gd
  └── signal lines_cleared(count)
        ├──► combo_scoring.gd._on_lines_cleared(count)
        ├──► speed_progression.gd._on_lines_cleared(count)
        ├──► visual_feedback.gd._on_lines_cleared(count)
        └──► audio_feedback.gd._on_lines_cleared(count)

game_state.gd
  ├── signal game_over
  │     ├──► visual_feedback.gd.on_game_over()
  │     └──► audio_feedback.gd.on_game_over()
  └── signal new_game
        ├──► combo_scoring.gd.on_new_game()
        └──► speed_progression.gd.on_new_game()

speed_progression.gd
  └── signal level_up(new_level)
        ├──► visual_feedback.gd.on_level_up()
        ├──► audio_feedback.gd.on_level_up()
        └──► score_display.gd.on_level_up()
```

## Alternatives Considered

### Alternative 1: Central EventBus autoload
- **Description**: Create an `EventBus.gd` autoload. All producers call `EventBus.emit("signal_name", args)`. All consumers connect to `EventBus.signal_name`.
- **Pros**: All routing in one place; producers don't need references to consumers
- **Cons**: Hides signal authorship — `EventBus.lines_cleared.emit(count)` doesn't tell you `line_clear.gd` was the source; makes debugging harder; autoload coupling; harder to test
- **Rejection Reason**: Same reason we rejected grid-as-autoload (ADR-ARCH-001) — hidden global state makes testing harder. The signal map already gives us the routing table without needing a central bus.

### Alternative 2: Central EventBus using a topic/string-based emit
- **Description**: `EventBus.emit("lines_cleared", count)` with string-based topic names
- **Pros**: Decouples completely; consumers don't need producer type reference
- **Cons**: No compile-time checking; string typos cause runtime errors; completely unobservable at compile time; worse debuggability than native signals
- **Rejection Reason**: Completely loses Godot's type safety. A typo in `"lines_clleared"` silently does nothing at runtime.

### Alternative 3: Direct method calls (no signals)
- **Description**: `line_clear.on_piece_locked()` called directly from `tetromino.gd`; no signals at all
- **Pros**: Simple call stack, compile-time type checking
- **Cons**: Creates circular import risk: tetromino→line_clear, but line_clear→combo→speed→etc. would need to call back; direct coupling between producer and all consumers; hard to add new consumers
- **Rejection Reason**: Tight coupling. If we need to add a 5th consumer to `lines_cleared`, we'd need to modify `tetromino.gd` to make a second call.

## Consequences

### Positive
- Signals are observable in Godot debugger — connection graph visible in remote nsights
- Producer doesn't need references to consumers — only consumer needs producer reference (via `@export`)
- Adding a new consumer only requires adding a `connect()` call in the new consumer's `_ready()` — producer doesn't change
- Fan-out to 4 consumers from `lines_cleared` works naturally with no intermediate
- Type-safe: compiler catches signal name typos
- Testable: in GUT tests, create a `LineClear` mock that manually calls the connected callable

### Negative
- Consumer must hold a reference to the producer (`@export var line_clear: LineClear`) — some boilerplate
- If producer is freed before consumer, dangling reference (but `_ready()` re-connection handles this via Godot's normal lifecycle)
- Connection debugging requires looking at individual nodes — not one central place

### Risks
- **Risk**: Forgotten `connect()` call — consumer never receives signal
  - **Mitigation**: GUT integration tests verify that signals are connected; assert in `_ready()` if expected signal is not connected
- **Risk**: Connecting to wrong node (typo in `@export`)
  - **Mitigation**: Type hints catch most typos; null-check in `_ready()`

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| line-clearing-system.md | Emit `lines_cleared(count)` to 4 downstream systems | Native signal fan-out pattern |
| combo-scoring-system.md | Receive `lines_cleared(count)` from Line Clearing System | Consumer connects signal in `_ready()` |
| speed-progression-system.md | Receive `lines_cleared(count)` | Same pattern |
| visual-feedback-system.md | Receive `lines_cleared(count)`, `level_up`, `game_over` | Same pattern, multiple signals |
| audio-feedback-system.md | Receive all gameplay signals | Same pattern |
| tetromino-system.md | Emit `piece_locked` | Native signal |
| game-state-system.md | Emit `game_over`, `new_game` | Native signal |
| all GDDs | Signal-based communication (cross-system data flow) | Defines native signal pattern as project standard |

## Performance Implications
- **CPU**: Negligible — Godot signal dispatch is a function pointer call
- **Memory**: One signal connection = ~16 bytes; 15 signals × average 2 connections = <500 bytes total
- **Load Time**: Negligible
- **Network**: None

## Migration Plan
- Greenfield project — no existing signal code to migrate
- Establish signal naming convention: `snake_case` with `_changed`, `_updated` suffixes per GDScript idiom
- Document the signal map from architecture.md Phase 3 as the authoritative reference

## Validation Criteria
- In Godot debugger nsights, signal connections are visible as edges in the node graph
- Adding a new consumer to `lines_cleared` requires only adding one `connect()` call in the new consumer — no changes to `line_clear.gd`
- GUT tests can create a mock `LineClear` node and verify `combo_scoring.gd` behavior by calling `mock.emit_signal("lines_cleared", 2)`