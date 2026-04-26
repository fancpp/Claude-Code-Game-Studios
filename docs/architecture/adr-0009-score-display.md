# ADR-ARCH-009: Score Display

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

The Score Display System renders score, level, and combo as `Label` nodes in a `CanvasLayer` child of `main.tscn`. Labels are updated via signal handlers from `combo_scoring.gd` (score, combo) and `speed_progression.gd` (level). Score formats as 6-digit zero-padded string (e.g., `001250`). Combo label is hidden when `combo_counter == 0` and shown as "×N" when `> 0`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Presentation / UI |
| **Knowledge Risk** | LOW — `Label` and `CanvasLayer` API are stable from Godot 3.x through 4.6 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-ARCH-002 (Signal Bus) — display updates are signal-driven |
| **Enables** | Score Display System implementation |
| **Blocks** | Nothing |
| **Ordering Note** | Must be Accepted before Score Display System implementation |

## Context

### Problem Statement

The HUD needs to display score, level, and combo from upstream systems. The question is: what node type (`Label` vs `RichTextLabel` vs custom draw), where in the scene tree does the HUD live, and how does the display get updated (signal-driven vs polling)?

### Constraints

- Score must display as 6-digit zero-padded integer (e.g., `001250`)
- Score overflow (>999999) displays as `999999+`
- Combo display visible only when `combo_counter > 0`, hidden when `== 0`
- HUD remains static during pause (values frozen)
- Level format: `LV {N}`
- Next piece preview is Vertical Slice (not MVP) — not included in MVP scope

### Requirements

- Score, level, and combo labels exist in a `CanvasLayer` above gameplay
- Display updates are signal-driven — `score_display.gd` never polls state
- HUD positions are fixed offsets from grid edges (per GDD pixel coordinates)
- All label updates are atomic (no rolling animations)

## Decision

**Pattern: Signal-driven `Label` nodes in `CanvasLayer`, `_ready()` signal connections.**

### Node Structure (in `main.tscn`)

```
ui_layer (CanvasLayer)
  └── score_display.gd (Control node)
        ├── score_label (Label)     # "001250"
        ├── level_label (Label)     # "LV 1"
        └── combo_label (Label)     # "×3" or hidden
```

**Scene tree position:** Per ADR-ARCH-003, `ui_layer` is a `CanvasLayer` child of `main.tscn` root, rendered above gameplay. `score_display.gd` is a `Control` child of `ui_layer`.

**Implementation:**

```gdscript
# score_display.gd
class_name ScoreDisplay
extends Control

const SCORE_PADDING := 6
const COMBO_VISIBLE_THRESHOLD := 1

var _displayed_score: int = 0
var _displayed_level: int = 1
var _displayed_combo: int = 0

@onready var score_label: Label = $score_label
@onready var level_label: Label = $level_label
@onready var combo_label: Label = $combo_label

func _ready() -> void:
    combo_scoring.score_changed.connect(_on_score_changed)
    combo_scoring.combo_changed.connect(_on_combo_changed)
    speed_progression.level_up.connect(_on_level_up)
    game_state.new_game.connect(_on_new_game)
    _refresh_all()

func _on_score_changed(new_score: int) -> void:
    _displayed_score = new_score
    if _displayed_score > 999999:
        score_label.text = "999999+"
    else:
        score_label.text = str(_displayed_score).pad_decimals(0).lpad(SCORE_PADDING, "0")
        # GDScript alternative: "%06d" % new_score

func _on_combo_changed(new_combo: int) -> void:
    _displayed_combo = new_combo
    if _displayed_combo >= COMBO_VISIBLE_THRESHOLD:
        combo_label.text = "×%d" % _displayed_combo
        combo_label.visible = true
    else:
        combo_label.visible = false

func _on_level_up(new_level: int) -> void:
    _displayed_level = new_level
    level_label.text = "LV %d" % _displayed_level

func _on_new_game() -> void:
    _displayed_score = 0
    _displayed_level = 1
    _displayed_combo = 0
    _refresh_all()

func _refresh_all() -> void:
    _on_score_changed(_displayed_score)
    _on_level_up(_displayed_level)
    _on_combo_changed(_displayed_combo)
```

**HUD positions:** Per GDD pixel coordinates, labels are positioned as fixed offsets from the grid right edge and top:

```gdscript
func _ready() -> void:
    # Position labels at fixed pixel offsets from grid
    # GRID_RIGHT_X = 320, GRID_TOP_Y = 0, HUD_MARGIN = 16
    const GRID_RIGHT_X := 320
    const HUD_MARGIN := 16

    var base_x := GRID_RIGHT_X + HUD_MARGIN  # = 336
    score_label.position = Vector2(base_x, 0)
    level_label.position = Vector2(base_x, 24)
    combo_label.position = Vector2(base_x, 48)

    combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
```

**Why `Label` (not `RichTextLabel` or custom `_draw()`)?**

| Approach | Pros | Cons |
|----------|------|------|
| `Label` | Simple, Godot-managed text rendering, `lpad()` formatting works | Limited styling |
| `RichTextLabel` | Fancy markup, inline colors | Overkill for simple numeric display |
| Custom `_draw()` | Full control over rendering | Must handle all text rendering manually, harder to debug |

`Label` is the correct choice — the HUD displays plain numeric text, no markup needed. Godot 4.6's `Label` supports `lpad()` and `rpad()` for zero-padding.

**Why signal-driven (not property polling)?**

The GDD says "The display updates immediately on every score event." A signal-driven approach means the display only updates when state changes — no polling, no wasted frames checking for changes. This is consistent with the signal-driven architecture established in ADR-ARCH-002.

**Why `LV %d` format in `_on_level_up` (not `Label.text = "LV " + str(level)`)?**

Using string formatting (`"LV %d" % level`) is more efficient than string concatenation and avoids an intermediate `str()` call.

## Architecture Diagram

```
ui_layer (CanvasLayer — from ARCH-003)
  └── score_display.gd (Control — class_name ScoreDisplay)
        ├── score_label (Label)    # "001250"
        ├── level_label (Label)    # "LV 1"
        └── combo_label (Label)    # "×3" or hidden

Signal connections in _ready():
  combo_scoring.score_changed   → _on_score_changed(score: int)
  combo_scoring.combo_changed   → _on_combo_changed(combo: int)
  speed_progression.level_up    → _on_level_up(level: int)
  game_state.new_game           → _on_new_game()

Data flow:
  combo_scoring emits score_changed(1250)
    → _on_score_changed(1250)
      → score_label.text = "001250"

  combo_scoring emits combo_changed(3)
    → _on_combo_changed(3)
      → combo_label.text = "×3"
      → combo_label.visible = true

  speed_progression emits level_up(6)
    → _on_level_up(6)
      → level_label.text = "LV 6"
```

## Key Interfaces

```gdscript
class_name ScoreDisplay
extends Control

# Signal subscriptions (inputs from upstream systems)
@export var combo_scoring: Node   # must emit score_changed(new_score: int), combo_changed(new_combo: int)
@export var speed_progression: Node  # must emit level_up(new_level: int)
@export var game_state: Node      # must emit new_game signal

func _ready() -> void:
    combo_scoring.score_changed.connect(_on_score_changed)
    combo_scoring.combo_changed.connect(_on_combo_changed)
    speed_progression.level_up.connect(_on_level_up)
    game_state.new_game.connect(_on_new_game)

# Note: score_display.gd does NOT need to be referenced by any other system.
# It is a terminal presentation system — it reads upstream state via signals
# and renders to Label nodes. No exports needed.
```

## Alternatives Considered

### Alternative 1: Poll `combo_scoring.score` property each frame

- **Description**: `_process()` reads `combo_scoring.score` and updates label if changed.
- **Pros**: Simple polling pattern
- **Cons**: Wastes CPU checking for changes every frame; creates hidden coupling to `combo_scoring` internals; score changes are event-driven, not frame-driven
- **Rejection Reason**: Signal-driven is more efficient and more consistent with the project's architecture. Signals are the contract, not property reads.

### Alternative 2: Next piece preview in MVP

- **Description**: Include next piece mini-grid rendering in MVP scope.
- **Cons**: GDD labels next-piece preview as Vertical Slice, not MVP. Extra mini-grid rendering logic adds scope before core HUD is validated.
- **Rejection Reason**: Defer to Vertical Slice. MVP HUD is score/level/combo only.

### Alternative 3: Use `set_text()` with ` `%06d`` format

- **Description**: `"%06d" % score` for zero-padding.
- **Cons**: String formatting with `%` is valid GDScript but less readable than `lpad()`.
- **Rejection Reason**: Both work. `lpad()` is more readable for the team. Use `lpad()`.

## Consequences

### Positive

- Signal-driven updates — HUD only changes when state changes, no polling
- `Label` nodes are the correct Godot node for simple numeric text display
- `CanvasLayer` ensures HUD always renders above gameplay (per ARCH-003)
- `LV %d` format and `×N` format are concise and readable
- New game resets all three labels atomically

### Negative

- Requires `combo_scoring` and `speed_progression` to emit named signals (`score_changed`, `combo_changed`, `level_up`) — not just update internal properties. These signals are the contract.
- If a new signal is not added when state changes, the HUD will not update. (This is a correctness requirement — not a flaw in the pattern.)

### Neutral

- Label positions are hardcoded pixel offsets — acceptable for a fixed-layout HUD; not responsive to window resizing (not required for MVP)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| `combo_scoring` doesn't emit `score_changed` on every score update | Low | HUD shows stale score | GUT test: change score, assert label text matches |
| Combo display flashes (briefly shows ×0) on reset | Low | Visual artifact | `combo_label.visible = false` set immediately when `combo == 0` before text update |

## Performance Implications

- **CPU**: Negligible — label `set_text()` is a string update, O(n) in digits
- **Memory**: 3 `Label` nodes (~3KB total)
- **Load Time**: Negligible
- **Network**: None

## Migration Plan

- Greenfield — no existing HUD code
- `ui_layer/CanvasLayer` already exists from ARCH-003
- `score_display.gd/Control` created as child of `ui_layer`
- 3 `Label` nodes created as children of `score_display.gd`
- Signal connections established in `_ready()`
- Combo Scoring and Speed Progression systems emit `score_changed`, `combo_changed`, `level_up` signals when their values change (this is the interface contract)

## Validation Criteria

- GIVEN `score_changed(1250)` signal, WHEN received, THEN `score_label.text == "001250"`
- GIVEN `score_changed(1000000)` signal, WHEN received, THEN `score_label.text == "999999+"`
- GIVEN `combo_changed(0)` signal, WHEN received, THEN `combo_label.visible == false`
- GIVEN `combo_changed(3)` signal, WHEN received, THEN `combo_label.visible == true` AND `combo_label.text == "×3"`
- GIVEN `level_up(6)` signal, WHEN received, THEN `level_label.text == "LV 6"`
- GIVEN `new_game` signal, WHEN received, THEN all three labels show reset values
- GUT test: emit `score_changed(1250)` and assert `score_label.text == "001250"`

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| score-display-system.md | Score Display | 6-digit zero-padded score | `str(score).lpad(6, "0")` format; overflow shows "999999+" |
| score-display-system.md | Score Display | Combo visible only when > 0, format "×N" | `combo_label.visible` toggled, text = "×%d" % combo |
| score-display-system.md | Score Display | Level format "LV {N}" | `"LV %d" % level` format |
| score-display-system.md | Score Display | HUD static during pause | Signal-driven — no `_process()` loop, values only change on signal |
| score-display-system.md | Score Display | Score updates atomic | Each signal handler sets label text atomically — no animation |
| score-display-system.md | Score Display | Next piece preview deferred to Vertical Slice | Not included in MVP scope |

## Related

- ADR-ARCH-002 (Signal Bus) — all display updates are signal-driven
- ADR-ARCH-003 (Scene Tree) — `score_display.gd` lives in `ui_layer` (CanvasLayer child of main.tscn)
- ADR-ARCH-008 (Audio) — shares the same signal-driven presentation pattern