# Story 001: Score + Level Display — 6-digit zero-padded score, "LV N" level

> **Epic**: score-display-system
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/score-display-system.md`
**Requirement**: `TR-score-001` (6-digit zero-padded score, caps at 999999+), `TR-score-002` (level format "LV N")
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: ADR-ARCH-009 (Score Display) — `Label` nodes, signal-driven `_ready()` connections.

**Engine**: Godot 4.6 | **Risk**: LOW — `Label` and `CanvasLayer` API stable since Godot 3.x
**Control Manifest Rules (Presentation layer)**:
- Required: `score_label`, `level_label` as `Label` children of `ScoreDisplay` Control node
- Forbidden: No polling — display only updates on signal receipt
- Guardrail: Score format exactly "006500" not "6500", not "6,500"

---

## Acceptance Criteria

*From GDD score-display-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN score = 1250, **WHEN** score is rendered, **THEN** display shows "001250".
- [ ] **AC-2**: GIVEN score = 1000000, **WHEN** score is rendered, **THEN** display shows "999999+".
- [ ] **AC-5**: GIVEN level changes from 5 to 6, **WHEN** level is rendered, **THEN** display shows "LV 6".
- [ ] **AC-6**: GIVEN new game starts, **WHEN** HUD is rendered, **THEN** score shows "000000", level shows "LV 1", and combo is hidden.
- [ ] **AC-7**: GIVEN game is paused, **WHEN** HUD continues to be rendered, **THEN** values remain unchanged from before the pause.

---

## Implementation Notes

*From ADR-ARCH-009:*

```gdscript
# score_display.gd
class_name ScoreDisplay
extends Control

const SCORE_PADDING := 6

@onready var score_label: Label = $score_label
@onready var level_label: Label = $level_label
@onready var combo_label: Label = $combo_label

var _displayed_score: int = 0
var _displayed_level: int = 1

func _ready() -> void:
    combo_scoring.score_changed.connect(_on_score_changed)
    speed_progression.level_up.connect(_on_level_up)
    game_state.new_game.connect(_on_new_game)
    _refresh_all()

func _on_score_changed(new_score: int) -> void:
    _displayed_score = new_score
    if _displayed_score > 999999:
        score_label.text = "999999+"
    else:
        score_label.text = str(_displayed_score).lpad(SCORE_PADDING, "0")

func _on_level_up(new_level: int) -> void:
    _displayed_level = new_level
    level_label.text = "LV %d" % _displayed_level

func _on_new_game() -> void:
    _displayed_score = 0
    _displayed_level = 1
    _refresh_all()

func _refresh_all() -> void:
    _on_score_changed(_displayed_score)
    _on_level_up(_displayed_level)
```

**Score formatting**: GDScript `lpad()` pads a string on the left. `str(1250).lpad(6, "0")` → `"001250"`. Alternative: `"%06d" % score`.

**Score overflow**: `> 999999` triggers `"999999+"` display. The actual score continues to accumulate internally; only the display is capped.

**Pause behavior**: Signal-driven means no signals fire during pause. `score_label` text stays at the last-seen value — no explicit pause handling needed.

---

## Out of Scope

- Combo display (Story 002)
- Next piece preview (deferred to Vertical Slice per GDD)

---

## QA Test Cases

**AC-1**: 1250 → "001250"
- Given: `score_changed(1250)` signal received
- When: `_on_score_changed(1250)` runs
- Then: `score_label.text == "001250"`
- Edge cases: score = 0 ("000000"), score = 999999 ("999999")

**AC-2**: 1000000 → "999999+"
- Given: `score_changed(1000000)` signal received
- When: `_on_score_changed(1000000)` runs
- Then: `score_label.text == "999999+"`

**AC-5**: Level "LV N" format
- Given: `level_up(6)` signal received
- When: `_on_level_up(6)` runs
- Then: `level_label.text == "LV 6"`
- Edge cases: Level 15 ("LV 15"), Level 1 ("LV 1")

**AC-7**: Pause preserves values
- Given: Score display shows "001250"
- When: Game pauses (no `score_changed` signal fires during pause)
- Then: `score_label.text` remains "001250"

---

## Test Evidence

**Story Type**: UI
**Required evidence**: Manual walkthrough doc OR interaction test at `production/qa/evidence/score-display-*.md`

**Status**: [ ] Not yet created

**Dependencies**: combo-scoring-system stories (001-003), speed-progression-system stories (001-002)