# Story 002: New Game Initialization

> **Epic**: game-state-system
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/game-state-system.md`
**Requirement**: `TR-game-state-003` (New game init: clear_grid, reset score/level/combo to 0, spawn first piece)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**:
- ADR-001 (Grid Resource Pattern): GameStateSystem holds injected Grid ref, calls `grid.clear_grid()`
- ADR-002 (Signal Bus): `new_game_init` signal emitted to all subsystems; each subsystem resets its own state on receipt
- ADR-003 (Scene Tree): GameStateSystem coordinates the init sequence via signal bus

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Simple sequential initialization — clear_grid, signal emission. No complex timing or engine APIs.

**Control Manifest Rules (Core layer)**:
- Required: clear_grid(), score/level/combo reset to 0, piece spawn request
- Forbidden: No hardcoded values (use named constants), no subsystem-specific logic in GameStateSystem
- Guardrail: New game init must complete within 0ms (instant)

**Dependencies**:
- Blocked until: grid-system stories (grid API must be available for clear_grid)

---

## Acceptance Criteria

*From GDD game-state-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN game is in GAME_OVER state and player presses restart, WHEN new game init runs, THEN grid is cleared (all 200 cells = 0).
- [ ] **AC-2**: GIVEN new game init is triggered, WHEN init runs, THEN score, level, and combo counter are reset to 0.
- [ ] **AC-3**: GIVEN new game init is triggered, WHEN init runs, THEN first tetromino piece spawns at x=4, y=19.
- [ ] **AC-4**: GIVEN new game init is triggered, WHEN init runs, THEN game state transitions to PLAYING.

---

## Implementation Notes

*From GDD game-state-system.md Detailed Design:*

**New Game Initialization sequence:**
1. `grid.clear_grid()` — resets all 200 cells to 0
2. `score_display_system.reset()` — score to 0, level to 1
3. `combo_scoring_system.reset()` — combo counter to 0
4. `speed_progression_system.reset()` — level to 1
5. `piece_spawn_system.request_spawn()` — spawn first piece at x=4, y=19
6. Transition to PLAYING state

**Signal-driven reset pattern:**
- GameStateSystem emits `new_game_init` via signal bus
- Each subsystem (ScoreDisplay, ComboScoring, SpeedProgression) listens and resets itself
- GameStateSystem itself only calls `grid.clear_grid()` and `piece_spawn_system.request_spawn()`
- This avoids circular dependencies — GameStateSystem does not hold direct references to ScoreDisplay, ComboScoring, SpeedProgression

**Implementation:**
```gdscript
func _init_new_game() -> void:
    # Clear grid (direct call on injected grid ref)
    grid.clear_grid()

    # Emit new game signal — subsystems reset themselves
    signal_bus.new_game_init.emit()

    # Request first piece spawn
    piece_spawn_system.request_spawn()

    # Transition to PLAYING
    _transition_to(GameState.PLAYING)
```

- Place in `src/game_state/game_state_system.gd`
- Called from `_on_restart_input()` when current state is GAME_OVER
- `_transition_to(GameState.PLAYING)` is called last to ensure subsystems are ready before gameplay begins

---

## Out of Scope

*Handled by neighbouring stories:*
- Story 001: State machine transitions, GAME_OVER state, restart input handling
- Score Display System: Score display reset implementation
- Combo Scoring System: Combo counter reset implementation
- Speed Progression System: Level reset implementation
- Piece Spawn System: `request_spawn` implementation

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: Grid cleared on new game
- Given: A game in progress with locked pieces on the grid (cells set to non-zero values)
- When: `_init_new_game()` is called
- Then: `grid.clear_grid()` is called; all 200 cells `grid.get_cell(x, y)` for x in 0-9, y in 0-19 return 0
- Edge cases: Multiple pieces locked across multiple rows — all cleared; calling clear_grid twice is idempotent

**AC-2**: Score/level/combo reset to 0
- Given: A game in progress with score=1250, level=5, combo=3
- When: `signal_bus.new_game_init.emit()` is called
- Then: ScoreDisplay, ComboScoring, and SpeedProgression systems reset their internal state; subsequent score display shows 0, level shows 1, combo shows 0
- Edge cases: Each subsystem resets independently — GameStateSystem does not track their state

**AC-3**: First piece spawns at correct position
- Given: New game initialization is running
- When: `_init_new_game()` reaches the spawn step
- Then: `piece_spawn_system.request_spawn()` is called with spawn position x=4, y=19
- Edge cases: The piece spawn system handles the actual piece creation — GameStateSystem only requests the spawn

**AC-4**: State transitions to PLAYING
- Given: A game in GAME_OVER state
- When: `_init_new_game()` completes
- Then: `_current_state` is `PLAYING`; `state_changed(GAME_OVER, PLAYING)` is emitted; all gameplay loops can now run
- Edge cases: If `_init_new_game()` is called during PLAYING (should not happen — guarded by story 001), it still transitions to PLAYING (no-op on state machine)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/game_state/new_game_init_test.gd` — must exist and pass

**Status**: [ ] Not yet created