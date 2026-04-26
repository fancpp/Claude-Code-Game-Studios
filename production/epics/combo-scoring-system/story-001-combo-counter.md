# Story 001: Combo Counter — increment/reset logic

> **Epic**: combo-scoring-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/combo-scoring-system.md`
**Requirement**: `TR-combo-001` (combo counter: +1 on non-zero line clear, resets to 0 when piece locks with 0 lines)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: No dedicated ADR — pure calculation logic per GDD. Uses signal bus (ADR-ARCH-002) for `lines_cleared(count)` input.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `combo_counter: int` private field, starts at 0, `combo_counter_changed.emit(counter)` signal
- Forbidden: No manual combo override (only signal-driven reset)
- Guardrail: Counter resets atomically — no intermediate states visible

---

## Acceptance Criteria

*From GDD combo-scoring-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN new game starts, **WHEN** first piece is placed, **THEN** combo_counter = 0 and total_score = 0.
- [ ] **AC-4**: GIVEN combo_counter = 3, **WHEN** a piece locks with 0 lines cleared, **THEN** combo_counter resets to 0.
- [ ] **AC-6**: GIVEN new game signal received, **WHEN** game resets, **THEN** total_score = 0 and combo_counter = 0.

*Note: AC-4 is the reset case; AC-1 and AC-6 are initialization.*

---

## Implementation Notes

*From GDD Core Rules:*

```gdscript
# combo_scoring.gd
class_name ComboScoring
extends Node

var combo_counter: int = 0
var total_score: int = 0

# Base points per lines cleared (indexed by lines count)
const BASE_POINTS: Array[int] = [0, 100, 300, 500, 800]  # index 0 unused, 1-4 valid

signal combo_counter_changed(new_counter: int)

func _ready() -> void:
    line_clear.lines_cleared.connect(_on_lines_cleared)
    game_state.new_game.connect(_on_new_game)

func _on_lines_cleared(count: int) -> void:
    if count > 0:
        combo_counter += 1
        combo_counter_changed.emit(combo_counter)
    # Note: reset to 0 happens when piece locks with 0 lines (handled elsewhere)

func _on_new_game() -> void:
    combo_counter = 0
    total_score = 0
```

**Combo reset on zero-line lock**: The GDD says the combo resets when a piece locks with 0 lines cleared. This means the `piece_locked` signal (or equivalent) with lines_cleared=0 must trigger a combo reset. This requires wiring from the game state / tetromino system.

**Combo counter boundary**: Counter can grow indefinitely (no cap), but multiplier is capped at 5 (handled in Story 002).

---

## Out of Scope

- Score calculation (Story 002)
- Signal emission to downstream (Story 003)
- Drop bonuses

---

## QA Test Cases

**AC-1**: New game starts with combo_counter = 0
- Given: A newly instantiated `ComboScoring` node (or `_on_new_game()` called)
- When: Game begins, first piece is about to lock
- Then: `combo_counter == 0` and `total_score == 0`
- Edge cases: Called twice in a row (idempotent reset)

**AC-4**: Zero-line lock resets combo to 0
- Given: `combo_counter = 3`
- When: `piece_locked` fires with lines_cleared = 0 (zero-line lock)
- Then: `combo_counter == 0`
- Edge cases: Counter already 0 (no change), very high counter (100+)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combo_scoring/combo_counter_test.gd` — must exist and pass

**Status**: [ ] Not yet created

**Dependencies**: line-clear-system stories (001-003)