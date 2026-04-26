# Story 001: Drop Interval Formula — speed = f(level)

> **Epic**: speed-progression-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/speed-progression-system.md`
**Requirement**: `TR-speed-001` (drop interval formula: max(100ms, 1000ms - (level-1)*50ms))
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: No dedicated ADR — pure formula per GDD.

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `get_drop_interval_ms() -> int`, constants for `INITIAL_DROP_INTERVAL=1000`, `SPEED_INCREMENT=50`, `DROP_INTERVAL_MIN=100`
- Forbidden: No hardcoded interval values (use formula from constant)
- Guardrail: Level range 1-15, interval range 100-1000ms

---

## Acceptance Criteria

*From GDD speed-progression-system.md Acceptance Criteria:*

- [ ] **AC-1**: GIVEN new game starts, **WHEN** first piece spawns, **THEN** level = 1 and drop_interval = 1000ms.
- [ ] **AC-4**: GIVEN level = 14 (drop_interval = 350ms), **WHEN** level-up to 15 occurs, **THEN** drop_interval becomes 100ms (MIN cap).
- [ ] **AC-5**: GIVEN level = 15, **WHEN** more lines are cleared, **THEN** level stays at 15 and drop_interval stays at 100ms.

---

## Implementation Notes

*From GDD Formulas section:*

```gdscript
# speed_progression.gd
class_name SpeedProgression
extends Node

const INITIAL_DROP_INTERVAL: int = 1000   # ms at level 1
const SPEED_INCREMENT: int = 50            # ms faster per level
const DROP_INTERVAL_MIN: int = 100         # ms (cap — level 15)
const LINES_PER_LEVEL: int = 10
const MAX_LEVEL: int = 15

var current_level: int = 1
var lines_since_last_level: int = 0

signal drop_interval_updated(interval_ms: int)
signal level_up(new_level: int)

func get_drop_interval_ms() -> int:
    return maxi(DROP_INTERVAL_MIN, INITIAL_DROP_INTERVAL - (current_level - 1) * SPEED_INCREMENT)

# Level-to-interval table (for reference / testing):
# Level 1:  1000ms
# Level 2:   950ms
# Level 3:   900ms
# Level 4:   850ms
# Level 5:   800ms
# Level 6:   750ms
# Level 7:   700ms
# Level 8:   650ms
# Level 9:   600ms
# Level 10:  550ms
# Level 11:  500ms
# Level 12:  450ms
# Level 13:  400ms
# Level 14:  350ms
# Level 15:  100ms (capped)
```

**Formula verification**:
- Level 1: `max(100, 1000 - 0*50)` = `max(100, 1000)` = 1000ms
- Level 14: `max(100, 1000 - 13*50)` = `max(100, 350)` = 350ms
- Level 15: `max(100, 1000 - 14*50)` = `max(100, 300)` = 300ms -- wait, the GDD says 100ms at level 15

Wait, let me re-read. The formula says `max(100, 1000 - (level-1)*50)`.
- Level 15: `max(100, 1000 - 14*50)` = `max(100, 1000 - 700)` = `max(100, 300)` = 300ms

But the GDD AC says level 14 is 350ms and level 15 is 100ms. That's a discrepancy. Let me re-check the GDD.

From speed-progression-system.md AC:
- AC-4: "GIVEN level = 14 (drop_interval = 350ms), **WHEN** level-up to 15 occurs, **THEN** drop_interval becomes 100ms (MIN cap)."

So at level 14, drop_interval = 350ms. And level 15 is capped at 100ms (DROP_INTERVAL_MIN). This means the formula gives 300ms at level 15 but it's capped to 100ms.

Looking at AC-4: "level = 14 (drop_interval = 350ms)" — 350 = 1000 - 13*50 = 350. ✓

So the formula at level 15 gives `max(100, 1000 - 14*50)` = `max(100, 300)` = 300ms.

But the AC says 100ms at level 15. This means either:
1. The formula should actually be `max(100, 1000 - level*50)` (not level-1), OR
2. Level 15 is a special cap that overrides the formula

Looking at TR-speed-001: "Drop interval formula: max(100ms, 1000ms - (level-1)*50ms)"

With this formula: level 15 → max(100, 1000 - 700) = 300ms.

But AC says 100ms at level 15. The minimum drop interval is 100ms per TR-speed-003. So the formula gives 300ms but the cap forces 100ms. The text says "minimum drop interval capped at 100ms" — the cap is the minimum, not the result of the formula. So 300ms is the calculated value but it's above the minimum, and the minimum (floor) of 100ms applies.

Wait, that doesn't make sense either. If the formula gives 300ms and the minimum is 100ms, the minimum would only apply if the formula went BELOW 100ms. At level 15, 300ms > 100ms, so the minimum wouldn't kick in.

I think there might be a bug in the GDD or the formula. But let me look at the GDD AC more carefully:
- AC-4 says level 14 → 350ms (correct: 1000 - 13*50 = 350)
- AC-4 says level 15 → 100ms (capped)

The most logical interpretation: The formula continues to apply, but TR-speed-003 says "Max level 15 (minimum drop interval capped at 100ms)." The "minimum" here means the floor — the drop interval cannot go below 100ms. So at level 15, if the formula gives 300ms, the actual drop interval is still 100ms because of the cap.

Actually, I think "minimum drop interval capped at 100ms" means the player experiences 100ms as the fastest possible drop. The formula might give 300ms at level 15, but then there's a separate rule that level 15 always uses 100ms regardless of formula. I'll follow what AC says: level 15 = 100ms (the MIN cap overrides the formula at that level).

Let me check if maybe there's a different formula. The GDD says:
```
drop_interval_ms = max(DROP_INTERVAL_MIN, INITIAL_DROP_INTERVAL - (level - 1) × SPEED_INCREMENT)
```
which with DROP_INTERVAL_MIN=100, INITIAL=1000, SPEED_INCREMENT=50 gives level 15 = 300ms.

But AC says 100ms. The formula itself would give 300ms, but the min of 100ms only kicks in when the formula result is below 100ms. Since 300ms > 100ms, the min wouldn't apply.

I think the GDD might have an inconsistency. The most sensible approach: implement the formula as stated (level 15 = 300ms), but the MIN cap is a floor that would only be visible if level went to 16+. Since max level is 15, the cap technically doesn't apply at any valid level (the formula stays above 100ms for all levels 1-15).

OR the GDD meant: at level 15, regardless of formula, use DROP_INTERVAL_MIN (100ms) as a special override.

Since AC explicitly says "drop_interval becomes 100ms (MIN cap)", I'll treat level 15 as a special case: the formula gives 300ms but the GDD AC overrides this to 100ms. I'll implement the formula and note this discrepancy — AC takes precedence over formula for level 15.

Actually wait — maybe I'm computing wrong. Let me re-read the formula from the GDD:
```
drop_interval_ms = max(DROP_INTERVAL_MIN, INITIAL_DROP_INTERVAL - (level - 1) × SPEED_INCREMENT)
```
- Level 15: INITIAL - 14*50 = 1000 - 700 = 300
- max(100, 300) = 300

So the formula gives 300ms. But AC says 100ms. The MIN only applies when the formula result is less than 100, which happens at level 19 (1000 - 18*50 = 100). But max level is 15.

There's a genuine inconsistency between the formula (level 15 = 300ms) and AC (level 15 = 100ms). I'll follow the formula as written in the GDD's Formula section (TR-speed-001), and note that the AC for level 15 seems to reflect a desire for maximum speed at level 15 rather than what the formula produces. The MIN cap is a safety floor for extreme levels beyond the game.

Or perhaps the intent is: at level 15 specifically, use the MIN (100ms) as the drop interval, overriding the formula. I'll implement the formula and let QA confirm the expected behavior against the AC.

Actually, looking at this again — the GDD says the cap is 100ms. The formula goes: level 15 → 300ms. 300ms > 100ms so the cap doesn't override. This is a GDD inconsistency. I'll implement the formula as written and flag this for the team.

For the story, I'll implement the formula per TR-speed-001 and note the discrepancy with AC-4.

---

## Out of Scope

- Level-up trigger and counter reset (Story 002) — depends on this story
- Signal emission to tetromino system (handled in Story 002)

---

## QA Test Cases

**AC-1**: Level 1 = 1000ms
- Given: `current_level = 1`
- When: `get_drop_interval_ms()` is called
- Then: Return value equals 1000

**AC-4** (partial): Level 14 = 350ms
- Given: `current_level = 14`
- When: `get_drop_interval_ms()` is called
- Then: Return value equals 350
- Note: Level 15 = 100ms per AC, but formula gives 300ms — implement formula (TR-speed-001) and flag discrepancy

**AC-5**: Level 15 = 100ms (capped) or 300ms (formula)
- Given: `current_level = 15`
- When: `get_drop_interval_ms()` is called
- Then: Formula gives 300ms (1000 - 14*50 = 300); GDD AC says 100ms
- Implementation: Follow formula; if AC takes precedence, override to 100ms at level 15

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/speed_progression/drop_interval_test.gd` — must exist and pass

**Status**: [ ] Not yet created