# Game Concept: Tetris Arcade Challenge

*Created: 2026-04-26*
*Status: Draft*

---

## Elevator Pitch

> It's a classic falling-block puzzle game where you strategically rotate and place tetrominoes to clear lines, chasing high scores through a precision-driven combo system that rewards sustained focus over lucky placements.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Puzzle / Arcade / Classic |
| **Platform** | Web (HTML5 — browser-based, no installation) |
| **Target Audience** | Arcade enthusiasts, high-score chasers, casual gamers seeking flow states |
| **Player Count** | Single-player |
| **Session Length** | 5-30 minutes per session |
| **Monetization** | None (free to play) |
| **Estimated Scope** | Small (1-3 months, solo developer) |
| **Comparable Titles** | Original Tetris (1984), Tetris Effect, Jstris |

---

## Core Fantasy

**You are a master of precision.** Every placement is intentional, every rotation deliberate. As the pace increases, your mind enters a flow state where the blocks become an extension of your thought. The satisfaction comes not from luck, but from the beautiful alignment of skill and focus — the feeling when a perfect combo lands and the score multiplier climbs.

---

## Unique Hook

Unlike modern Tetris variants that add complex power-ups or story modes, **Tetris Arcade Challenge** returns to pure arcade purity: precision controls, escalating speed, and a combo system that makes every consecutive clear feel like a small victory. The hook is the **combo multiplier** — the longer you maintain your streak, the higher your score climbs. One perfect game can feel like conducting an orchestra.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 3 | Clean visual feedback on line clears, screen flash, satisfying sound cues |
| **Fantasy** (make-believe) | N/A | Not applicable — pure mechanical challenge |
| **Narrative** (drama) | N/A | Not applicable — no story elements |
| **Challenge** (obstacle course, mastery) | **1** | Linear speed curve, combo system, high score pursuit |
| **Fellowship** (social connection) | N/A | Leaderboard only (optional) |
| **Discovery** (exploration) | N/A | Not applicable — fully known systems |
| **Expression** (self-expression) | 2 | Personal style in piece placement, efficiency optimization |
| **Submission** (relaxation) | 4 | Meditative quality of focused play once mastered |

### Key Dynamics (Emergent player behaviors)

- Players will naturally develop personal piece-placement patterns they refine over time
- Players will analyze their mistakes ("I shouldn't have placed that there") and adjust
- "One more run" psychology: after a game ends, immediate desire to improve the score

### Core Mechanics (Systems we build)

1. **Falling Tetromino System** — 7 standard tetrominoes (I, O, T, S, Z, J, L) with SRS rotation system
2. **Line Clearing System** — Complete horizontal lines disappear, triggering score calculation
3. **Combo Scoring System** — Consecutive line clears multiply points; broken combos reset multiplier
4. **Linear Speed Curve** — Drop speed increases with each level (1 point per level-up)
5. **Ghost Piece Preview** — Shows where the current piece will land

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Player chooses every piece's exact position and rotation | Core |
| **Competence** | Clear numeric feedback: score increases with skill; players see measurable improvement over time | Core |
| **Relatedness** | Optional leaderboard connection (deferred to post-MVP) | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — How: chasing high scores, achieving personal bests
- [ ] **Explorers** (discovery, understanding systems) — How: not applicable
- [ ] **Socializers** (relationships, cooperation) — How: not applicable
- [x] **Killers/Competitors** — How: leaderboard rankings, beating personal records

### Flow State Design

- **Onboarding curve**: First 2 minutes teach basic movement, 5 minutes understand combo system
- **Difficulty scaling**: Linear speed increase creates natural challenge growth
- **Feedback clarity**: Score, level, and combo counter update instantly on every action
- **Recovery from failure**: Game over is immediate; "Play Again" available in under 2 seconds

---

## Core Loop

### Moment-to-Moment (30 seconds)

1. Piece spawns at top center
2. Player rotates/moves piece left-right/down
3. Piece locks when it lands
4. Line clear check → score update → combo counter update
5. Next piece spawns
6. Repeat until game over

### Short-Term (5-15 minutes)

- One game session: place pieces, clear lines, grow combo, survive increasing speed
- Natural stopping point: game over
- "One more run" hook: immediately try again to beat personal best

### Session-Level (30-120 minutes)

- Multiple games with improving personal scores
- Each game is self-contained; no meta-progression
- Player naturally stops when satisfied with performance or time-constrained

### Long-Term Progression

- No permanent progression (arcade purity)
- Growth is measured in skill: faster reactions, better piece placement efficiency
- Players track personal best scores over time

### Retention Hooks

- **Curiosity**: Can I beat my high score?
- **Investment**: Time already invested in learning the game
- **Social**: (Optional) Leaderboard visibility
- **Mastery**: Infinite skill ceiling — no one achieves perfect play

---

## Game Pillars

### Pillar 1: Operation Precision

Every tetromino placement must be directly controllable and predictable. No random drops, no pieces sliding unexpectedly.

*Design test*: When discussing wall kicks or rotation systems, we choose the most predictable, player-controlled option.

### Pillar 2: Rhythm of Growth

The linear speed curve creates a sense of progression. The player feels themselves "growing" as speed increases and they keep up.

*Design test*: When debating speed curve shape, we choose linear progression over erratic or step-based curves.

### Pillar 3: Combo Reward

Consecutive line clears are worth more than isolated clears. Maintaining a combo requires sustained focus.

*Design test*: When discussing score calculations, combo multiplier is the primary reward mechanism.

### Pillar 4: Instant Retry

Game over leads directly to "Play Again" in under 2 seconds. No loading screens, no menus, no friction.

*Design test*: When discussing game over flow, we minimize any element that delays the next game.

---

## Anti-Pillars (What This Game Is NOT)

- **NOT a story-driven game**: Pure mechanical challenge, no narrative elements
- **NOT a power-up variant**: No special blocks, no abilities, no modifiers — classic rules only
- **NOT a multiplayer game**: Single-player experience only (leaderboard deferred to post-MVP)
- **NOT a mobile-first game**: Designed for keyboard input; touch controls are secondary consideration

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Original Tetris (1984) | Core mechanics, 7-bag randomizer, level-based speed | Enhanced combo system, cleaner visual feedback | Validates core concept |
| Tetris Effect | Visual/audio atmosphere, flow state design | Web-based, simpler scope | Validates the "zen" appeal |
| Jstris | Speed-running tools, clean interface | We are not building for competition; more accessible | Validates web-based approach |

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 15-45 |
| **Gaming experience** | Mid-core (has played games before, not necessarily puzzle specialist) |
| **Time availability** | 5-30 minute sessions; can be interrupted |
| **Platform preference** | Desktop browser (primary), mobile browser (secondary) |
| **Current games they play** | Casual mobile games, classic arcade games, browser games |
| **What they're looking for** | Quick, satisfying puzzle sessions without commitment |
| **What would turn them away** | Complex tutorials, required accounts, pay-to-win elements |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.x with HTML5 export — 2D-native, lightweight, excellent web export |
| **Key Technical Challenges** | SRS rotation system implementation, collision detection accuracy, web performance |
| **Art Style** | Clean 2D pixel art — 16x16 grid cells, minimal but polished |
| **Art Pipeline Complexity** | Low — simple geometric shapes, no complex sprites |
| **Audio Needs** | Minimal — satisfying clear sound, game over sound, optional background music |
| **Networking** | None for MVP (leaderboard optional post-MVP) |
| **Content Volume** | Single game mode, no levels, no items — infinite replayability |
| **Procedural Systems** | Random piece generation using 7-bag randomizer |

---

## Risks and Open Questions

### Design Risks

- Core loop may feel repetitive without variety (mitigation: focus on juice/feedback)
- Score ceiling may feel unmotivating without meta-progression (mitigation: personal best tracking)

### Technical Risks

- Web export performance must be verified (mitigation: prototype early)
- SRS rotation system has many edge cases (mitigation: use established reference implementation)

### Market Risks

- Tetris is a saturated genre; differentiation must be clear (mitigation: combo system focus)
- Browser games have low perceived value (mitigation: polish and instant play appeal)

### Scope Risks

- Feature creep from "nice to have" additions (mitigation: strict pillar enforcement)

### Open Questions

- Should we add keyboard shortcut customization? (Decision: yes, in settings)
- Should we persist high scores locally? (Decision: yes, localStorage)

---

## MVP Definition

**Core hypothesis**: Players find the classic Tetris loop engaging when combined with a satisfying combo multiplier system.

**Required for MVP**:
1. Full Tetris mechanics (7 tetrominoes, SRS rotation, line clearing)
2. Combo scoring system with visual feedback
3. Linear speed progression
4. Ghost piece preview
5. Game over and instant retry
6. Score and level display

**Explicitly NOT in MVP**:
- Leaderboard system
- Multiple game modes
- Piece preview (next piece showing)
- Touch controls
- Custom themes/skins

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | Core game only | Tetris mechanics + combo + speed curve | 4-6 weeks |
| **Vertical Slice** | Complete playable | Next piece preview + high score persistence | 6-8 weeks |
| **Alpha** | Feature complete | Keyboard settings + sound on/off | 8-10 weeks |
| **Full Vision** | Polished release | Multiple speed modes + visual polish + sound | 10-12 weeks |

---

## Visual Identity Anchor

*(To be finalized in `/art-bible` — this section captures initial direction)*

- **Initial direction**: Clean, minimalist arcade aesthetic
- **Color philosophy**: Dark background for focus, bright piece colors for clarity
- **Key visual principles**: Crisp edges, no blur, instant visual feedback on actions

---

## Next Steps

- [ ] Run `/setup-engine` to configure Godot 4.x and populate version-aware reference docs
- [ ] Run `/art-bible` to create the visual identity specification
- [ ] Use `/map-systems` to decompose the concept into individual systems
- [ ] Use `/design-system` to author per-system GDDs
- [ ] Create architecture decision records with `/architecture-decision`
- [ ] Prototype the core loop with `/prototype`
- [ ] Validate core loop with `/playtest-report`
- [ ] Plan first sprint with `/sprint-plan new`