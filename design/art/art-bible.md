# Art Bible: Tetris Arcade Challenge

*Created: 2026-04-26*
*Status: Draft*
*Art Director Sign-Off (AD-ART-BIBLE): PENDING*

---

## 1. Visual Identity Statement

### One-Line Visual Rule
**"Clarity above all — every pixel earns its place. The game disappears; only the challenge remains."**

### Supporting Visual Principles

1. **Crisp Geometry** — Blocks are perfect rectangles with clean edges. No gradients, no blur, no anti-aliasing artifacts. *Design test: When debating anti-aliased vs. hard-edged blocks, choose hard edges.*

2. **Dark Canvas, Bright Focus** — Deep black/dark gray play area makes colored pieces pop. UI is minimal and recedes. *Design test: When UI competes with gameplay for attention, reduce UI opacity or move it off the play field.*

3. **Instant Feedback** — Every action produces immediate visual response. Line clears flash, combos pulse, game over shakes. No delayed animations. *Design test: When an animation could be removed without losing information, remove it.*

---

## 2. Mood & Atmosphere

### Game States

| State | Primary Emotion | Lighting Character | Atmospheric Descriptors | Energy Level |
|-------|----------------|-------------------|------------------------|--------------|
| **Playing (Normal)** | Focused calm | Even, mid-contrast, no shadows | Clean, precise, controlled | Measured |
| **Playing (Speed Up)** | Controlled tension | Slightly higher contrast, subtle pulse | Accelerating, building, intense | Escalating |
| **Line Clear** | Triumphant satisfaction | Bright flash, white-out fade | Explosive, rewarding, electric | Peak burst |
| **Combo Active** | Momentum joy | Subtle glow around combo counter | Chain-reaction, unstoppable, flowing | Sustained high |
| **Game Over** | Respectful finality | Brief shake, fade to dark | Decisive, clean, no regret | Rapid descent |
| **Paused** | Neutral intermission | Dimmed play field | Suspended, waiting | Zero |

### Visual Pacing
The game starts calm and clean, building visual intensity with speed and combo chains. The visual language should feel like breathing — calm baseline, occasional sharp peaks, always returning to center.

---

## 3. Shape Language

### Block Design
- **Silhouette**: Perfect squares composing tetrominoes. At any distance, the grid reads clearly.
- **Internal detail**: Each tetromino type is identified by color only — no internal pattern or texture.
- **Grid alignment**: All blocks snap to integer grid positions. No sub-pixel rendering.

### Environment Geometry
- **Play field**: 10×20 grid of uniform cells. Clean rectangular boundary.
- **Background**: Solid dark color, no decoration. The play field is the entire world.
- **UI containers**: Minimal rounded rectangles for score/level/combo display.

### UI Shape Grammar
- **Primary shapes**: Rectangles with sharp or slightly rounded corners (2-4px radius)
- **Icon style**: Outlined, single-weight strokes. No filled icons.
- **Typography hierarchy**: Large bold numbers for score, medium for labels, small for secondary info

### Hero vs. Supporting Shapes
- **Hero**: The active falling tetromino — brightest, most saturated color
- **Supporting**: Ghost piece preview — same color at 30% opacity
- **Receding**: Locked pieces on the stack — slightly desaturated compared to falling piece
- **UI**: Score/combo displays — white on semi-transparent dark panels

---

## 4. Color System

### Primary Palette

| Color | Hex | Role | Semantic Meaning |
|-------|-----|------|------------------|
| **Background** | `#0D0D0D` | Dark canvas | Focus, no distraction |
| **Play Field** | `#1A1A2E` | Play area background | Defined workspace |
| **Grid Lines** | `#2D2D44` | Subtle grid | Positioning guide (very subtle) |
| **I-Piece** | `#00F5FF` | Cyan | Standard Tetris convention |
| **O-Piece** | `#FFE500` | Yellow | Standard Tetris convention |
| **T-Piece** | `#9B59B6` | Purple | Standard Tetris convention |
| **S-Piece** | `#2ECC71` | Green | Standard Tetris convention |
| **Z-Piece** | `#E74C3C` | Red | Standard Tetris convention |
| **J-Piece** | `#3498DB` | Blue | Standard Tetris convention |
| **L-Piece** | `#E67E22` | Orange | Standard Tetris convention |
| **Ghost Piece** | Same as piece | 30% opacity | Landing prediction |
| **UI Panel** | `#FFFFFF` at 10% | Score/combo background | Information overlay |
| **UI Text** | `#FFFFFF` | Primary text | All numbers and labels |

### Semantic Color Usage

| Color | When Used | Meaning |
|-------|-----------|---------|
| **White flash** | Line clear | Reward, achievement |
| **Red pulse** | Combo broken | Warning, reset |
| **Gold/yellow** | High combo (5+) | Special recognition, momentum |
| **Cyan glow** | Active I-piece | Attention, danger (board state) |

### UI Palette (Separation from World)
The UI (score, level, combo) uses a distinct language:
- Semi-transparent dark panels (`#FFFFFF` 10%)
- White text (`#FFFFFF`)
- No piece colors in UI — purely typographic

### Colorblind Safety
- **Shape backup**: All pieces have distinct shapes (not just colors). I, O, T, S, Z, J, L are all geometrically unique.
- **Combo counter**: Always shows numeric value + visual pulse — never color-dependent.
- **No red/green only signals**: Line clear and combo break use position + animation + optional sound, not just color.

---

## 5. Character Design Direction

*Not applicable — no characters in this game.*

---

## 6. Environment Design Language

### Overall Philosophy
The play field IS the environment. No separate world-building — the grid is abstract, timeless, and universal.

### Play Field Design
- **Boundary**: Clear rectangular border, 1-2px, slightly brighter than background
- **Grid cells**: Faint grid lines visible for placement guidance (`#2D2D44`)
- **No decorative elements**: No particles, no background patterns, no thematic decoration

### Texture Philosophy
- **No textures** — Pure flat color blocks
- **No shadows** — Flat 2D, no depth illusion within blocks
- **No highlights** — Blocks are solid color, no gradient or bevel

### Prop Density Rules
- **Zero props** — The game contains only: play field, falling pieces, locked pieces, UI
- **No obstacles** — Pure puzzle, no environmental hazards or interactive objects

### Environmental Storytelling
- **None required** — This is an abstract arcade experience
- **Visual storytelling via game state** — The stack of locked pieces tells the story of the current run

---

## 7. UI/HUD Visual Direction

### Style Classification
**Screen-space HUD** — UI overlays the play field, not diegetic. Clean separation between world and interface.

### Layout
```
+----------------------------------+
|  [SCORE]        [LEVEL]          |
|   12500           7              |
|                                  |
|  +----------------------------+  |
|  |                            |  |
|  |       PLAY FIELD           |  |
|  |        10 x 20             |  |
|  |                            |  |
|  |                            |  |
|  |                            |  |
|  +----------------------------+  |
|                                  |
|  [COMBO]        [NEXT]           |
|   x3           [preview]         |
+----------------------------------+
```

### Typography
- **Primary font**: System monospace or pixel-style font (e.g., "Press Start 2P" or system monospace)
- **Score**: Large (24-32px), bold, white
- **Level**: Medium (18-24px), bold, white
- **Combo**: Large when active, pulsing
- **Labels**: Small (12-14px), uppercase, letter-spaced

### Iconography Style
- **Outlined icons only** — Single stroke weight, no fills
- **Line thickness**: 1-2px
- **Size**: 16x16 or 24x24 base

### UI Animation Feel
- **Score changes**: Number rolls up, no pop
- **Combo updates**: Subtle pulse/scale on increment
- **Line clear**: Bright flash (100ms), then fade
- **Game over**: Brief screen shake, then fade to game over overlay

### Interaction Patterns
- **Keyboard only for MVP** — Arrow keys for movement, up for rotation, space for hard drop
- **No hover states** — Pure keyboard interaction
- **Immediate response** — All inputs produce instant visual feedback

---

## 8. Asset Standards

### File Formats
| Asset Type | Format | Notes |
|------------|--------|-------|
| **Block sprites** | PNG with alpha | 32x32 base size, exported at 1x, 2x, 4x for scaling |
| **UI elements** | SVG or PNG | Vector preferred for UI, PNG for game elements |
| **Background** | Solid color (no image) | Set via code |
| **Icons** | SVG | Outlined, single stroke weight |

### Naming Conventions
```
blocks/
  block_i.png      (I-piece, cyan)
  block_o.png      (O-piece, yellow)
  block_t.png      (T-piece, purple)
  block_s.png      (S-piece, green)
  block_z.png      (Z-piece, red)
  block_j.png      (J-piece, blue)
  block_l.png      (L-piece, orange)

ui/
  panel_score.png   (score display background)
  panel_combo.png   (combo display background)
  icon_rotation.png (rotation hint)
  icon_pause.png    (pause button)

fonts/
  (use system monospace or embed pixel font)
```

### Resolution Tiers
- **Base resolution**: 384 x 640 (play field scaled to fit)
- **Internal grid**: 10 columns x 20 rows
- **Cell size**: 32x32 pixels at 1x scale
- **Scale options**: 1x (mobile), 2x (tablet), 4x (desktop retina)

### Performance Constraints
- **Draw calls target**: <50 for entire scene
- **Texture memory**: <10MB total
- **No dynamic textures**: All sprites are static

### Engine-Specific Notes (Godot 4.6)
- Use `Sprite2D` or `TextureRect` for blocks
- No shader-based blocks in MVP — simple sprite rendering
- UI uses Godot's built-in `Label`, `TextureRect`, and `Panel` nodes

---

## 9. Style Prohibitions

### Explicitly NOT Allowed

| Prohibition | Reason |
|-------------|--------|
| **No gradients on blocks** | Breaks the crisp, clean aesthetic. Blocks are solid color only. |
| **No drop shadows** | Flat 2D design — no depth illusions |
| **No particle effects in MVP** | Visual noise distracts from core gameplay. Add only if proven necessary for feedback. |
| **No animated backgrounds** | The play field is static and focused. Movement comes from the pieces. |
| **No3D perspective** | Pure 2D — no fake 3D rotation or isometric views |
| **No custom piece colors** | Standard Tetris colors are immediately recognizable — do not deviate |
| **No textures on blocks** | Solid fills only — no brick, marble, or other material textures |
| **No animated blocks** | Static blocks — animation is only for feedback (flash, shake) |
| **No diegetic UI** | UI is HUD overlay, not part of the game world |
| **No watermark/branding on play field** | Clean, uncluttered gameplay area |

---

## Reference Direction

| Reference | Take From It | Avoid | Purpose |
|-----------|-------------|-------|---------|
| **Original Tetris (1984)** | Crisp block rendering, dark background, clear grid | Any modern "improvements" (power-ups, 3D) | Validates pure arcade approach |
| **Jstris** | Clean UI layout, ghost piece implementation | Competitive UI clutter | UI clarity and usability |
| **Arcade cabinet aesthetic** | High contrast, simple shapes, readable at a glance | Complexity, detail | Overall visual approach |

---

## Next Steps

- [x] Art bible created
- [ ] Run `/map-systems` to decompose concept into systems
- [ ] Run `/design-system` to author per-system GDDs
- [ ] Run `/create-architecture` to produce master architecture document