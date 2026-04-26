# ADR-ARCH-011: Glow + Tonemapping (Godot 4.6)

## Status

Accepted

## Date

2026-04-26

## Last Verified

2026-04-26

## Decision Makers

Technical Director (self-review via /create-architecture)

## Summary

In Godot 4.6, glow (bloom) is applied **before** tonemapping instead of after. This changes how bright elements (including the flash overlay from visual feedback) appear. For this game's 2D CanvasLayer-based flash effect, the practical impact is that the white flash overlay's perceived brightness and color may differ from pre-4.6 behavior. No code changes are required — but flash overlay brightness must be verified with playtesting before ship.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Presentation / Rendering |
| **Knowledge Risk** | HIGH — glow-before-tonemapping is a post-LLM-cutoff change (4.6, Jan 2026); exact visual result must be verified in Godot 4.6 |
| **References Consulted** | `docs/engine-reference/godot/modules/rendering.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | Glow behavior changed in 4.6 — uses screen blending mode |
| **Verification Required** | Flash overlay brightness must be verified in Godot 4.6 playtesting before ship |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Any rendering/tone mapping decisions |
| **Blocks** | Nothing |
| **Ordering Note** | Advisory — must be verified before visual effects are signed off |

## Context

### What Changed in 4.6

**Before 4.6:**
```
Scene → Glow (additive bloom on bright pixels) → Tonemapping (compress HDR to LDR)
```
Glow was applied after tonemapping, so glow would bloom around bright areas that were already compressed to the display's LDR range.

**In 4.6:**
```
Scene → Glow (additive bloom) → Tonemapping (compress HDR to LDR)
```
Glow is now applied **before** tonemapping. Bright areas glow before being compressed, which changes the visual result — particularly for very bright elements like the flash overlay.

### Impact on This Game

The game's visual feedback system (ADR-ARCH-007) uses a white `ColorRect` overlay (`flash_overlay`) at 30% opacity for line-clear flashes. This creates a full-screen brightening effect.

With glow-before-tonemapping:
- The white overlay (30% opacity white) is now a source of bloom **before** tonemapping compresses it
- The perceived brightness of the flash may be higher than pre-4.6
- For a 30% white overlay on a dark background, the glow bloom contribution is small but measurable
- The effect is most visible on Tetris (strongest flash, 8px shake)

For a 2D game using `CanvasLayer` overlays, this is less dramatic than for 3D scenes with high-dynamic-range lighting. However, the change is real and must be verified.

### Constraints

- Flash overlay must be visible and readable (not washed out or too subtle)
- No custom shader work in MVP scope
- All effects use `ColorRect` overlays and `CanvasModulate` for ambient (no 3D lighting)
- Must target HTML5 web — rendering behavior should be consistent across D3D12/Vulkan

## Decision

**Pattern: No code changes. Verify flash overlay brightness in Godot 4.6 playtesting.**

### Current Implementation

```gdscript
# From ADR-ARCH-007
const FLASH_INITIAL_OPACITY := 0.3   # 30% white ColorRect overlay
```

This value was chosen based on pre-4.6 behavior where glow was applied after tonemapping. In 4.6, the same 30% opacity may produce a slightly brighter/different-looking flash.

### Verification Protocol

Before visual effects sign-off, the following must be verified:

1. **Flash brightness check**: Play Tetris (4-line clear), observe flash. Compare perceived brightness to pre-4.6 reference (or to expectation). Adjust `FLASH_INITIAL_OPACITY` down if flash appears too bright/white.

2. **If flash is too bright**: Reduce `FLASH_INITIAL_OPACITY` from 0.3 to 0.2 or 0.25. Re-verify.

3. **If flash appears tinted** (glow processing affects color): This is unlikely for a pure white flash, but if the flash takes on a color cast, a `ColorRect` with pre-adjusted RGB values may be needed.

### Why No Code Change Now

The change in glow order is a rendering pipeline change. Without running the game in Godot 4.6, it is impossible to determine exactly how much the flash brightness will change. The `FLASH_INITIAL_OPACITY = 0.3` constant is a tuning knob — the correct value is determined empirically by playtesting, not by calculation.

### WorldEnvironment Configuration

If the game later adds a `WorldEnvironment` (for ambient canvas darkening or similar), the glow settings are accessible via `Environment.glow_intensity` and `Environment.glow_blend_mode`:

```gdscript
# If WorldEnvironment is added in the future:
var env := Environment.new()
env.glow_intensity = 0.8          # default
env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE  # screen blending mode in 4.6
# Glow blend mode: ADDITIVE (screen) vs SOFTLIGHT vs REPLACE
# In 4.6, glow uses screen blending mode — this may differ from pre-4.6 behavior
```

For MVP, no `WorldEnvironment` is planned — the game uses raw `ColorRect` overlays. If glow behavior is problematic, the nuclear option is to add a `WorldEnvironment` with `glow_intensity = 0.0` to disable glow entirely for the 2D game.

## Architecture Diagram

```
Godot 4.6 Rendering Pipeline (relevant portion):

  [Scene render — 2D CanvasLayer]
         │
         ▼
  [Glow/Bloom pass]        ← ADDITIVE blend mode in 4.6
    └── White flash overlay (30% opacity) receives bloom here
         │
         ▼
  [Tonemapping]            ← compresses HDR to display LDR range
         │
         ▼
  [Display output]
```

Pre-4.6: Glow was after tonemapping, so flash overlay bloom was applied to already-compressed output.

In 4.6: Glow is before tonemapping, so flash overlay bloom is part of HDR scene before compression.

## Alternatives Considered

### Alternative 1: Disable glow entirely via WorldEnvironment

- **Description**: Add a `WorldEnvironment` with `glow_intensity = 0.0` to the scene.
- **Pros**: Eliminates glow entirely, flash overlay behaves as expected
- **Cons**: Removes any glow effects from the entire game (if any exist later); adds a node and configuration for a 2D game that shouldn't need it
- **Rejection Reason**: Overkill. A 2D game using `ColorRect` overlays has minimal HDR content. The glow change is marginal for this use case. Playtesting will determine if the flash needs adjustment, not a blanket glow disable.

### Alternative 2: Pre-adjust FLASH_INITIAL_OPACITY based on guess

- **Description**: Reduce `FLASH_INITIAL_OPACITY` from 0.3 to 0.2 preemptively.
- **Cons**: Arbitrary adjustment without verification. If the change is imperceptible at 0.3, reducing it to 0.2 makes the flash less visible for no reason.
- **Rejection Reason**: Adjustment should be based on Godot 4.6 playtesting, not guesswork.

### Alternative 3: Custom shader for flash that ignores glow

- **Description**: Use a custom fragment shader for the flash `ColorRect` that explicitly excludes it from the glow pass.
- **Pros**: Precise control
- **Cons**: MVP scope; custom shader adds complexity and testing surface; not warranted for a simple flash overlay
- **Rejection Reason**: Out of scope for MVP. Simpler than custom shader: just adjust `FLASH_INITIAL_OPACITY` after playtesting.

## Consequences

### Positive

- No code changes required for MVP
- `FLASH_INITIAL_OPACITY` is a simple tuning knob — the correct value is determined by playtesting
- The glow-before-tonemapping change affects 3D HDR scenes more than 2D flat `ColorRect` overlays

### Negative

- Flash overlay brightness is not guaranteed to match pre-4.6 behavior without verification
- Playtesting in Godot 4.6 is required before visual effects can be signed off as complete

### Neutral

- This ADR documents the rendering change for future reference and sets the verification requirement
- It does not make a binding architectural decision — it flags the issue for the visual effects validation step

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Flash appears too bright in Godot 4.6 | Medium | Visual feedback feels overwhelming | Reduce `FLASH_INITIAL_OPACITY` after playtesting |
| Flash has color cast in 4.6 | Very Low | White flash appears tinted | Verify with playtest; adjust ColorRect RGB if needed |

## Performance Implications

- **CPU**: None
- **Memory**: None
- **Load Time**: None
- **Network**: None

## Migration Plan

- No code changes now
- During visual effects validation (before ship):
  - Play Tetris line clears in Godot 4.6
  - Compare flash brightness to expected feel
  - Adjust `FLASH_INITIAL_OPACITY` from 0.3 to whatever value feels correct
  - Document the final value in the visual effects sign-off notes

## Validation Criteria

- **GIVEN** a Tetris (4-line clear) in Godot 4.6, **WHEN** the flash plays, **THEN** the flash is clearly visible and not uncomfortably bright
- **GIVEN** `FLASH_INITIAL_OPACITY` is adjusted, **WHEN** all line clear types are tested, **THEN** single/double/triple/Tetris flashes are proportionally correct (higher count = more intense)
- **GIVEN** the game runs in a web browser (D3D12 on Windows, Vulkan elsewhere), **WHEN** flash plays, **THEN** flash brightness is consistent across render backends

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| visual-feedback-system.md | Visual Feedback | Flash on line clear: 30% white, 100-300ms | Documents that 4.6 glow change may affect perceived brightness; sets verification protocol |
| All GDDs | All | Engine: Godot 4.6 | Documents the glow-before-tonemapping change from 4.6 |

## Related

- ADR-ARCH-007 (Visual Effects Architecture) — `FLASH_INITIAL_OPACITY = 0.3` is the tuning knob this ADR addresses
- `docs/engine-reference/godot/modules/rendering.md` — glow before tonemapping note
- `docs/engine-reference/godot/breaking-changes.md` — "Glow processes BEFORE tonemapping" entry