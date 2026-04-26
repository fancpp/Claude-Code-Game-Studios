# Story 001: Game State Machine

> **Epic**: game-state-system
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/game-state-system.md`
**Requirement**: `TR-game-state-001` (4 states with transitions), `TR-game-state-002` (Game over detection: spawn position occupied)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**:
- ADR-001 (Grid Resource Pattern): GameStateSystem holds injected Grid ref for spawn position check
- ADR-002 (Signal Bus): State change signals (`state_changed`, `game_over`) emitted via signal bus
- ADR-003 (Scene Tree): GameStateSystem node is parent of all gameplay subsystems

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Simple state machine with enum and match statement. No post-cutoff APIs.

**Control Manifest Rules (Core layer)**:
- Required: 4-state enum (IDLE/PLAYING/PAUSED/GAME_OVER), state change validation, game over detection
- Forbidden: No transitions from invalid states (e.g., pause during IDLE)
- Guardrail: Pause only triggers once per press — not continuously while held

---

## Acceptance Criteria

*From GDD game-state-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN game is in IDLE state, WHEN player presses start, THEN state becomes PLAYING and piece spawns.
- [ ] **AC-2**: GIVEN game is in PLAYING state, WHEN player presses pause, THEN state becomes PAUSED.
- [ ] **AC-3**: GIVEN game is in PAUSED state, WHEN player presses pause, THEN state becomes PLAYING.
- [ ] **AC-4**: GIVEN game is in PLAYING state, WHEN game over condition is met, THEN state becomes GAME_OVER.
- [ ] **AC-5**: GIVEN game is in GAME_OVER state, WHEN player presses restart, THEN state becomes PLAYING and grid is cleared.
- [ ] **AC-6**: GIVEN game is in PLAYING state, WHEN pause is pressed and held, THEN pause only triggers once (not toggling).

---

## Implementation Notes

*From GDD game-state-system.md Detailed Design:*

**State transitions:**
```
IDLE -> PLAYING: Start game
PLAYING -> PAUSED: Pause key
PLAYING -> GAME_OVER: Game over condition met
PAUSED -> PLAYING: Pause key
GAME_OVER -> PLAYING: Restart (new game)
```

**Game Over Detection:**
- Trigger: Spawn System finds spawn position (x=4, y=19) already occupied when attempting to spawn
- Spawn System emits `spawn_failed` signal
- GameStateSystem listens for `spawn_failed`, transitions to GAME_OVER, emits `game_over` signal

**State Machine Implementation:**
```gdscript
enum GameState { IDLE, PLAYING, PAUSED, GAME_OVER }
var _current_state: GameState = GameState.IDLE

func _on_start_input() -> void:
    if _current_state == GameState.IDLE:
        _transition_to(GameState.PLAYING)

func _on_pause_input() -> void:
    match _current_state:
        GameState.PLAYING: _transition_to(GameState.PAUSED)
        GameState.PAUSED: _transition_to(GameState.PLAYING)

func _on_spawn_failed() -> void:
    if _current_state == GameState.PLAYING:
        _transition_to(GameState.GAME_OVER)

func _on_restart_input() -> void:
    if _current_state == GameState.GAME_OVER:
        _transition_to(GameState.PLAYING)
```

**Edge case handling (no-ops per GDD):**
- Pause during IDLE: No-op
- Pause during GAME_OVER: No-op
- Start during PLAYING: No-op
- Restart during PLAYING: No-op
- Restart during IDLE: No-op

**Pause key debounce:**
- Detect key press (not hold): only trigger on `INPUT_ACTION_PRESSED`, not `INPUT_ACTION_HELD`
- No continuous toggling while key is held

- Place in `src/game_state/game_state_system.gd`
- Emit `state_changed(old_state, new_state)` via signal bus on every transition
- Emit `game_over` via signal bus when entering GAME_OVER state

---

## Out of Scope

*Handled by neighbouring stories:*
- Story 002: New game initialization (clear_grid, score/level/combo reset, first piece spawn)

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**AC-1**: IDLE -> PLAYING on start
- Given: GameStateSystem with `_current_state == IDLE`
- When: `_on_start_input()` is called
- Then: `_current_state` becomes `PLAYING`; `state_changed(IDLE, PLAYING)` is emitted; `piece_spawn_requested` signal is emitted
- Edge cases: Calling `_on_start_input()` again during PLAYING is a no-op

**AC-2 / AC-3**: PLAYING <-> PAUSED on pause
- Given: GameStateSystem with `_current_state == PLAYING` (AC-2) / `PAUSED` (AC-3)
- When: `_on_pause_input()` is called
- Then: AC-2: state becomes PAUSED; AC-3: state becomes PLAYING; `state_changed` is emitted in both cases
- Edge cases: Pressing pause twice rapidly — only first press triggers; second press during same frame is no-op

**AC-4**: PLAYING -> GAME_OVER on spawn failure
- Given: GameStateSystem with `_current_state == PLAYING`
- When: `_on_spawn_failed()` is called (SpawnSystem detected occupied spawn cell)
- Then: `_current_state` becomes `GAME_OVER`; `state_changed(PLAYING, GAME_OVER)` and `game_over` signals are emitted
- Edge cases: `_on_spawn_failed()` called during PAUSED — queued until unpaused per GDD edge case

**AC-5**: GAME_OVER -> PLAYING on restart
- Given: GameStateSystem with `_current_state == GAME_OVER`
- When: `_on_restart_input()` is called
- Then: `_current_state` becomes `PLAYING`; `state_changed(GAME_OVER, PLAYING)` is emitted; `new_game_init_requested` is emitted (handled by story 002)
- Edge cases: Calling during PLAYING is a no-op

**AC-6**: Pause not repeat while held
- Given: GameStateSystem with `_current_state == PLAYING`
- When: `_on_pause_input()` is called once
- Then: state becomes PAUSED; subsequent `_on_pause_input()` calls within the same press-hold are no-op
- Edge cases: Releasing and re-pressing pause key triggers again; test with 1-second hold — only one transition

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/game_state/game_state_machine_test.gd` — must exist and pass

**Status**: [ ] Not yet created