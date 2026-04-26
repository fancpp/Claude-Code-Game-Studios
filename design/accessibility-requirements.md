# Accessibility Requirements

*Created: 2026-04-26*
*Status: Draft*
*Committed Tier: Basic*

---

## Commitment

**Tier: Basic**

This project commits to **Basic** accessibility support. This is the minimum viable tier — it ensures the game is playable without requiring specialized hardware or additional accommodations.

---

## Basic Tier Requirements

### Input Remapping
- All game controls are rebindable via a keybinding menu
- Default bindings are standard and follow platform conventions
- No input action is mouse-only or touch-only

### Visual Accessibility
- High-contrast mode available (toggle in settings)
- No color-only information conveyance (shapes + colors for tetromino types)
- UI text is readable at default zoom levels

### Audio Accessibility
- Subtitles or captions for all audio cues
- Volume controls for music, SFX, and UI sounds independently
- No audio-only information (visual feedback accompanies all audio cues)

### Motor Accessibility
- All time-sensitive actions (DAS, lock delay) have configurable timing
- No rapid-tap requirements for any game-critical action
- Pause functionality is accessible without fine motor precision

### Cognitive Accessibility
- Game state is always visible — no hidden information
- Core loop is simple and learnable within 2 minutes
- UI uses plain language with no unexplained jargon

---

## Out of Scope (not committed in Basic tier)

- Screen reader support (not applicable — 2D arcade game)
- Colorblind-specific modes (not committed — colors are distinguishable by shape)
- Extended remapping for gamepad/accessibility devices (future Vertical Slice)
- Adjustable UI text scaling beyond default (future Vertical Slice)

---

## Verification

Test Basic tier compliance:
1. Play a full game using only keyboard (no mouse)
2. Verify all audio cues have corresponding visual indicators
3. Confirm pause/menu are accessible without precise mouse input
4. Test that default DAS timing (170ms/50ms) can be adjusted in settings (if timing menu is added)

---

## Future Tiers

If accessibility is expanded, the progression would be:

- **Standard**: Basic + colorblind modes + scalable UI + gamepad remapping
- **Comprehensive**: Standard + motor accessibility + full settings menu
- **Exemplary**: Comprehensive + external audit + full customization