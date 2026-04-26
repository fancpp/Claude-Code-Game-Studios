# Interaction Pattern Library

*Created: 2026-04-26*
*Status: Draft*
*Source: Extracted from GDDs and Technical Preferences*

---

## Platform: Web + PC

**Primary Input**: Keyboard
**No hover-only interactions** — all interactive elements work via keyboard focus

---

## Keyboard Patterns

### Direct Press (no hold)
- Hard Drop: `Space` or `W` — immediate, no DAS
- Rotate CW: `X` or `Up Arrow` — immediate, no hold behavior
- Rotate CCW: `Z` — immediate, no hold behavior
- Pause: `ESC` — toggle, immediate response

### DAS (Delayed Auto Shift)
Applied to: Move Left (`←` / `A`), Move Right (`→` / `D`), Soft Drop (`↓` / `S`)
- Initial delay: 170ms before first repeat
- Repeat rate: 50ms
- Release resets DAS state entirely
- Simultaneous left+right press cancels both DAS actions

### Focus Navigation
- Tab / Shift+Tab: move between focusable elements
- Enter / Space: activate focused element
- ESC: close current overlay/menu (returns focus to game)

---

## Menu Patterns

### Pause Overlay
- Triggered by `ESC` or pause button
- Darkens game background (dim overlay)
- Focus trapped within pause menu while open
- `ESC` again closes pause menu
- Game is automatically paused when overlay opens

### Game Over Screen
- Displays final score, level, lines cleared
- Single "New Game" button
- Focus starts on "New Game" button
- No back navigation — game over is terminal state for that session

### HUD (non-interactive)
- Labels only — no keyboard/mouse interaction required
- Updates via signal subscription (combo_scoring, speed_progression)
- CanvasLayer renders above game world (no z-index management needed)

---

## Visual Feedback Patterns

### Flash Overlay (per ADR-ARCH-007)
- White `ColorRect` at 30% opacity
- Appears instantly on hard drop
- Fades out over 200ms using tween

### Combo Glow (per ADR-ARCH-007)
- Scale + glow pulse on combo counter label
- Triggers on `combo_changed` signal
- Animation: scale 1.0 → 1.3 → 1.0 over 150ms

### Lock Flash (per ADR-ARCH-007)
- White flash overlay fires on piece lock
- 200ms fade-out after flash

### Dim Overlay (per ADR-ARCH-007)
- 50% black overlay on game over
- Triggers on `game_over` signal
- Gameplay scene dims, game over screen overlays above

---

## Audio-Visual Pairings (per ADR-ARCH-008)

| Audio Event | Visual Trigger | Note |
|-------------|----------------|------|
| Move tick | None (audio only) | Short tick on piece move |
| Rotate | None (audio only) | Click on rotation |
| Soft drop tick | None (audio only) | Accelerating tick while falling |
| Hard drop | White flash | Visual + audio simultaneously |
| Lock | Lock flash + audio | Lock flash + thud sound |
| Line clear | Screen flash | Visual + chime, scales with lines |
| Combo ×5 | Combo glow + special chime | Both audio and visual |
| Level up | Level label pulse + fanfare | Both audio and visual |
| Game over | Dim overlay + sting | Both audio and visual |

---

## Touch/Gamepad (Future — not in MVP)

These patterns are out of scope for MVP but documented here for future reference:

- Gamepad left stick: move left/right
- Gamepad A button: hard drop
- Gamepad B button: rotate CCW  
- Gamepad X button: rotate CW
- Gamepad start: pause
- Touch swipe down: soft drop
- Touch swipe up: hard drop
- Touch tap: rotate CW

---

## Input Action Map (MVP)

| Action | Primary Key | Alt Key | DAS |
|--------|-------------|---------|-----|
| Move Left | `←` | `A` | Yes |
| Move Right | `→` | `D` | Yes |
| Soft Drop | `↓` | `S` | Yes |
| Hard Drop | `Space` | `W` | No |
| Rotate CW | `X` | `Up Arrow` | No |
| Rotate CCW | `Z` | — | No |
| Pause | `ESC` | — | No |

---

## Patterns NOT Used (clarity for implementation)

- Hover-only tooltips — no hover interactions per platform requirements
- Double-click actions — no double-click in MVP
- Drag-and-drop — no drag interactions in MVP
- Touch gestures — out of scope for MVP web/desktop
- Mouse-look / pointer-lock — not applicable to 2D