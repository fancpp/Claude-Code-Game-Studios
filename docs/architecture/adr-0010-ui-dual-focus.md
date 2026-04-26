# ADR-ARCH-010: UI Dual-Focus (Godot 4.6)

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

In Godot 4.6, mouse/touch focus and keyboard/gamepad focus are **separate** — both can be active simultaneously on different controls. This changes how interactive UI elements (menus, buttons) must be designed and tested. For Tetris Arcade Challenge, the MVP HUD is non-interactive (`Label` nodes, no focus needed), so this change has minimal immediate impact. However, any pause menu or interactive overlay added post-MVP must be tested with both input methods.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Presentation / UI |
| **Knowledge Risk** | MEDIUM — dual-focus system is post-LLM-cutoff (4.6, Jan 2026); tested behavior must be verified against Godot 4.6 docs |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | Dual-focus system — `focus_mode` properties are now per-input-method |
| **Verification Required** | Interactive UI elements (pause menu, game over menu) must be tested with both mouse and keyboard/gamepad in Godot 4.6 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Any interactive menu/overlay systems post-MVP |
| **Blocks** | Nothing (MVP HUD is non-interactive Labels) |
| **Ordering Note** | Advisory — must be verified if interactive UI is added |

## Context

### Problem Statement

The game's UI includes both a passive HUD (score, level, combo — `Label` nodes) and potentially interactive elements (pause menu, game over screen). In Godot 4.6, the focus system was split: **mouse/touch focus** and **keyboard/gamepad focus** are now separate input-method-specific focuses. A control can have mouse focus and keyboard focus simultaneously (or one without the other). This affects how interactive UI elements must be designed and tested.

### What changed in 4.6

| Before 4.6 | In 4.6 |
|------------|--------|
| One unified focus — `grab_focus()` affects all input methods | Two separate focuses: mouse/touch vs keyboard/gamepad |
| Mouse hover automatically gave focus to a control | Mouse hover and keyboard focus are independent |
| `focus_mode` controlled all input methods together | `focus_mode` is now per-input-method |

### Impact on this project

**MVP HUD (`Label` nodes):** No impact. `Label` nodes do not take focus. Score, level, and combo display are pure output — no interaction required.

**Pause menu / Game Over screen (post-MVP or Vertical Slice):** Must be designed with dual-focus in mind. If a "PAUSE" overlay has `Button` nodes:
- Mouse hover highlights the button (mouse focus)
- Arrow keys navigate between buttons (keyboard/gamepad focus)
- Both can be active simultaneously

If the pause menu has only a "RESUME" button and the player uses a mouse: mouse hover activates the button, but keyboard focus may be on a different invisible element. This can cause confusion.

### Constraints

- Primary input is keyboard (arrow keys for movement, Enter for confirm)
- Gamepad support is partial (arrow keys as alternative)
- No hover-only interactions (per technical preferences)
- Interactive UI elements must work with keyboard AND mouse/gamepad

### Requirements

- All interactive UI elements must be tested with both input methods (keyboard/gamepad AND mouse)
- `grab_focus()` only affects keyboard/gamepad focus — not mouse focus
- Focus navigation order must be defined for keyboard/gamepad (`focus_neighbor_*`)

## Decision

**Pattern: Test interactive UI with both input methods. Design non-interactive HUD for MVP.**

### For MVP (non-interactive HUD)

The MVP HUD uses `Label` nodes exclusively. `Label` nodes do not take focus. No dual-focus considerations apply to the score/level/combo display.

```gdscript
# score_display.gd — Label nodes only, no focus handling
# In Godot 4.6, Label nodes are immune to dual-focus because they don't take focus at all
score_label.text = "001250"   # pure output, no interaction
```

**No code changes required for the MVP HUD.** The dual-focus change is irrelevant to non-interactive `Label` nodes.

### For Interactive UI (pause menu, game over screen — post-MVP)

When interactive UI is added (pause menu with `Button` nodes), the following pattern must be followed:

```gdscript
# pause_menu.gd
func _ready() -> void:
    # In Godot 4.6:
    # - grab_focus() only affects KEYBOARD/GAMEPAD focus
    # - Mouse hover gives MOUSE focus (separate)
    # - Both can be active on different controls simultaneously

    # Set initial keyboard focus explicitly
    $resume_button.grab_focus()   # keyboard/gamepad focus — player can navigate with arrows

    # Mouse hover will independently give mouse focus when cursor is over a button
    # Both focus types coexist — no conflict
```

**Godot 4.6 focus API:**
```gdscript
# Keyboard/gamepad focus
button.grab_focus()            # set keyboard focus
button.has_focus()             # check keyboard focus

# Mouse/touch focus (new in 4.6 — was previously the same as keyboard focus)
button.mouse_filter = Control.MOUSE_FILTER_STOP   # accept mouse events
button.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ignore mouse events

# Both can be true at the same time:
# button.has_focus() == true (keyboard focus)
# button.is_mouse_hovering() == true (mouse focus)
```

### Testing Protocol for Interactive UI

For any pause menu or overlay with interactive controls, the following must be verified in Godot 4.6:

1. **Mouse path**: Move mouse over buttons → hover highlights appear → click activates
2. **Keyboard path**: Press Tab or arrow keys → focus indicator moves → Enter activates
3. **Simultaneous path**: Give button A keyboard focus, move mouse over button B → verify both focus states coexist without conflict
4. **Gamepad path**: Navigate with D-pad/left stick → focus moves correctly → A button activates

### Key Design Rule

**Do not rely on `focus_mode` alone to control interaction.** In 4.6, `focus_mode` on a `Button` controls keyboard/gamepad focus only. Mouse hover still works independently. If a button should not be interactable at all, use `mouse_filter = MOUSE_FILTER_IGNORE` in addition to `focus_mode = FOCUS_NONE`.

## Architecture Diagram

```
Dual Focus in Godot 4.6:

  Keyboard/Gamepad Focus          Mouse/Touch Focus
  (grab_focus(), arrows, Tab)     (hover, click, touch)

  [Resume Button]                 [Resume Button]
   - has_focus() = true            - is_mouse_hovering() = true
   - FOCUS_NONE blocks this        - MOUSE_FILTER_IGNORE blocks this

  Both can be true simultaneously on the SAME or DIFFERENT controls.
```

## Alternatives Considered

### Alternative 1: Disable mouse focus entirely on interactive UI

- **Description**: Set `mouse_filter = MOUSE_FILTER_IGNORE` on all interactive controls so only keyboard/gamepad focus works.
- **Cons**: Breaks mouse-based interaction entirely — player cannot click buttons with the mouse. Not acceptable since gamepad is "partial" support and mouse may be used.
- **Rejection Reason**: Primary input is keyboard but gamepad support is partial. Full mouse disable removes a valid input path.

### Alternative 2: Design all UI with single-focus assumption and defer testing

- **Description**: Write UI code as if 4.6 dual-focus doesn't exist, test later.
- **Cons**: Dual-focus bugs (keyboard focus on wrong element while mouse hover shows different element) are subtle and hard to catch late. Better to document the requirement now.
- **Rejection Reason**: The 4.6 dual-focus change is well-documented. Documenting the testing requirement now is low cost and prevents late-stage surprises.

## Consequences

### Positive

- MVP HUD (Labels) is completely unaffected by dual-focus — no code needed
- The testing protocol ensures interactive UI is verified with both input methods before shipping
- The pattern is simple: `grab_focus()` for keyboard, `mouse_filter` for mouse — both coexist

### Negative

- Interactive UI (pause menu, game over) requires dual-input testing in Godot 4.6 — more QA effort than a single-focus system
- `grab_focus()` behavior is different from pre-4.6 intuition for developers new to 4.6

### Neutral

- This ADR is primarily documentation/testing guidance, not a code architecture decision
- The MVP HUD implementation from ADR-ARCH-009 does not change at all

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Pause menu keyboard focus and mouse hover conflict | Medium | Player confused about which button is "selected" | Test with both input methods; explicitly call `grab_focus()` on the correct button |
| Mouse-only player can't interact with menu | Low | Player can't click buttons | Test mouse path in Godot 4.6; buttons must have `mouse_filter = MOUSE_FILTER_STOP` |
| Visual focus indicator not visible with gamepad | Low | Player doesn't know which button has keyboard focus | Custom focus rectangle style in theme; test with gamepad connected |

## Performance Implications

- **CPU**: Negligible — focus state is a boolean flag on each Control node
- **Memory**: Negligible
- **Load Time**: Negligible
- **Network**: None

## Migration Plan

- No code changes needed for MVP
- When interactive UI (pause menu) is added:
  - Use `grab_focus()` to set initial keyboard/gamepad focus
  - Test with both mouse and keyboard/gamepad in Godot 4.6
  - Set `mouse_filter = MOUSE_FILTER_STOP` on interactive controls
  - Set `focus_neighbor_*` on button containers for keyboard navigation

## Validation Criteria

- **GIVEN** MVP HUD (score_display.gd), **WHEN** game runs, **THEN** no focus-related errors or warnings appear (Labels don't take focus)
- **GIVEN** interactive pause menu with buttons, **WHEN** tested in Godot 4.6 with mouse, **THEN** hover highlighting works on buttons
- **GIVEN** interactive pause menu with buttons, **WHEN** tested with keyboard, **THEN** `grab_focus()` correctly sets initial focus and arrow keys navigate between buttons
- **GIVEN** a button has both keyboard focus and mouse hover simultaneously, **WHEN** Enter is pressed, **THEN** the correct button activates

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| score-display-system.md | Score Display | Non-interactive HUD display | MVP uses Label nodes only — no focus system involved |
| game-state-system.md | Game State | Pause behavior (pause key freezes loops) | Pause menu (when added) must be tested with dual-focus in 4.6 |
| All GDDs | All | Test with both mouse and keyboard | Dual-focus testing protocol documented for interactive UI |
| tech-preferences.md | Input | Primary input: keyboard; gamepad: partial; no hover-only | Mouse and keyboard focus are now separate in 4.6 — both work independently |

## Related

- ADR-ARCH-009 (Score Display) — MVP HUD uses Labels (no focus)
- ADR-ARCH-003 (Scene Tree) — `ui_layer` (CanvasLayer) contains all UI including any future interactive overlays
- `docs/engine-reference/godot/modules/ui.md` — dual-focus system details
- `docs/engine-reference/godot/breaking-changes.md` — 4.6 dual-focus breaking change