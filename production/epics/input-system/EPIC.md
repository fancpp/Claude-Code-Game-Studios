# Epic: Input System

> **Layer**: Foundation
> **GDD**: design/gdd/input-system.md
> **Architecture Module**: Input System (L1 Foundation)
> **Status**: Ready
> **Stories**: 3 created — see table below
> **Manifest Version**: 2026-04-26

---

## Overview

The Input System captures and translates keyboard events into game actions. It is the player's primary interface — every keypress is interpreted as a command (move left, rotate, soft drop, hard drop, pause). The system maps physical keys to abstract actions and emits signals that other systems subscribe to. It does not execute game logic; it only translates input into intent.

The system implements DAS (Delayed Auto Shift) for held movement keys: Move Left, Move Right, and Soft Drop each track independent DAS state with a 170ms initial delay and 50ms repeat rate. Hard Drop, Rotate CW/CCW, and Pause emit immediately with no hold behavior. DAS auto-pauses with the game via `_process()`.

---

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-ARCH-012: DAS Timing | Per-action DAS state in `_process()`, 170ms initial / 50ms repeat, left+right cancel | LOW |

---

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-input-001 | DAS 170ms initial / 50ms repeat | ADR-ARCH-012 ✅ |
| TR-input-002 | DAS applies to Move Left/Right/Soft Drop | ADR-ARCH-012 ✅ |
| TR-input-003 | Left+Right simultaneous cancels both | ADR-ARCH-012 ✅ |
| TR-input-004 | DAS pauses with game via `_process()` | ADR-ARCH-012 ✅ |

---

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Immediate-Action Signals (hard drop, rotate, pause) | Logic | Ready | ADR-ARCH-012 |
| 002 | DAS Core Mechanics (170ms/50ms, per-action state) | Logic | Ready | ADR-ARCH-012 |
| 003 | DAS Cancellation + Key Release Reset | Logic | Ready | ADR-ARCH-012 |

---

## Definition of Done

This epic is complete when:
- `input_handler.gd` is implemented with all 7 input actions (Move Left/Right, Soft/Hard Drop, Rotate CW/CCW, Pause)
- DAS state is tracked per-action independently (`_das_left_*`, `_das_right_*`, `_das_soft_drop_*`)
- Initial delay fires exactly once (170ms) before repeat begins
- Repeat fires at fixed interval (50ms) after initial delay
- Left+right held simultaneously resets all DAS state for both actions
- Key release resets all DAS state for that action
- `_process()` auto-pauses DAS when game pauses (no explicit pause wiring)
- `input_handler.gd` emits signals: `move_left`, `move_right`, `soft_drop`, `hard_drop`, `rotate_cw`, `rotate_ccw`, `pause`
- Unit tests in `tests/unit/das_timing_test.gd` cover DAS behavior with simulated `_process(delta)` calls

---

## Next Step

Run `/create-stories input-system` to break this epic into implementable stories.