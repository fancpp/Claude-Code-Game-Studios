# Epics Index

**Last Updated**: 2026-04-26
**Engine**: Godot 4.6
**Manifest Version**: 2026-04-26

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| grid-system | Foundation | Grid System | design/gdd/grid-system.md | 3 created (001-003 Ready) | Ready |
| input-system | Foundation | Input System | design/gdd/input-system.md | 3 created (001-003 Ready) | Ready |
| collision-system | Core | Collision System | design/gdd/collision-system.md | 2 created (001-002 Ready) | Ready |
| game-state-system | Core | Game State System | design/gdd/game-state-system.md | 2 created (001-002 Ready) | Ready |
| line-clear-system | Feature | Line Clear System | design/gdd/line-clearing-system.md | 3 created (001-003 Ready) | Ready |
| combo-scoring-system | Feature | Combo Scoring System | design/gdd/combo-scoring-system.md | 3 created (001-003 Ready) | Ready |
| ghost-piece-system | Feature | Ghost Piece System | design/gdd/ghost-piece-system.md | 2 created (001-002 Ready) | Ready |
| speed-progression-system | Feature | Speed Progression System | design/gdd/speed-progression-system.md | 2 created (001-002 Ready) | Ready |
| score-display-system | Presentation | Score Display System | design/gdd/score-display-system.md | 2 created (001-002 Ready) | Ready |
| visual-feedback-system | Presentation | Visual Feedback System | design/gdd/visual-feedback-system.md | 3 created (001-003 Ready) | Ready |
| audio-feedback-system | Presentation | Audio Feedback System | design/gdd/audio-feedback-system.md | 2 created (001-002 Ready) | Ready |

---

## Layer Progress

| Layer | Epics | Status |
|-------|-------|--------|
| Foundation | 2 (Grid System, Input System) | Epic files written — ready for story creation |
| Core | 2 (Collision, Game State) | Epic files written — ready for story creation |
| Feature | 4 (Line Clear, Combo Scoring, Ghost Piece, Speed Progression) | Epic files written — ready for story creation |
| Presentation | 3 (Score Display, Visual Feedback, Audio Feedback) | Epic files written — ready for story creation |

---

## Story Count by Layer

| Layer | Stories | Types |
|-------|---------|-------|
| Foundation | 6 | Logic/Integration |
| Core | 4 | Logic |
| Feature | 10 | Logic/Integration/Visual/Feel |
| Presentation | 7 | UI/Visual/Feel |
| **Total** | **27** | |

---

## Next Steps

- Core layer: tetromino-system and piece-spawn-system epics + stories still needed
- Feature/Presentation epics are unblocked — implementation order:
  1. line-clear-system (Feature) — depends on grid-system + tetromino-system
  2. combo-scoring-system (Feature) — depends on line-clear-system
  3. ghost-piece-system (Feature) — depends on grid + tetromino + collision
  4. speed-progression-system (Feature) — depends on line-clear-system
  5. score-display-system (Presentation) — depends on combo-scoring + speed-progression
  6. visual-feedback-system (Presentation) — subscribes to line-clear + combo + game-state
  7. audio-feedback-system (Presentation) — subscribes to tetromino + line-clear + combo + speed + game-state