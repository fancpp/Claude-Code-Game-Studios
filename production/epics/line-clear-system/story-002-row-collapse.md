# Story 002: Row Collapse — atomic removal and downward shift

> **Epic**: line-clear-system
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/line-clearing-system.md`
**Requirement**: `TR-line-clear-003` (row collapse: atomic, rows above cleared rows shift down by cleared count)
*Requirement text lives in `docs/architecture/tr-registry.yaml`*

**ADR Governing Implementation**: No dedicated ADR — uses grid API from ADR-ARCH-001. Row collapse is a direct application of the Grid API (`get_cell`, `set_cell`).

**Engine**: Godot 4.6 | **Risk**: LOW
**Control Manifest Rules (Feature layer)**:
- Required: `collapse_rows(cleared_rows: Array[int])` private method in `line_clear.gd`
- Forbidden: No intermediate visual state — collapse must be atomic from perspective of other systems
- Guardrail: `clear_row(y)` sets all 10 cells to EMPTY atomically

---

## Acceptance Criteria

*From GDD line-clearing-system.md Acceptance Criteria:*

- [ ] **AC-2**: GIVEN rows y=3 and y=5 are complete, **WHEN** collapse happens, **THEN** all rows above y=5 shift down by 2 and rows y=3 and y=5 are removed.
- [ ] **AC-3**: GIVEN 4 non-adjacent rows are complete, **WHEN** collapse happens, **THEN** all 4 rows are removed and remaining rows shift down by 4.
- [ ] **AC-6**: GIVEN a row at y=10 has occupied cells, **WHEN** 2 rows below it (y=3, y=4) are cleared, **THEN** the row at y=10 shifts to y=8 (moves down by exactly 2).

---

## Implementation Notes

*From GDD Formulas section:*

```gdscript
# Row collapse algorithm (in line_clear.gd)
func _collapse_rows(cleared_rows: Array[int]) -> void:
    # Sort cleared rows ascending so we process from bottom to top
    cleared_rows.sort()

    # For each remaining row (not cleared), count how many cleared rows are below it
    # and shift down by that count
    for y in range(20):
        if y in cleared_rows:
            continue  # skip cleared rows
        # Count cleared rows below this row
        var shift_amount := 0
        for cleared_y in cleared_rows:
            if cleared_y < y:
                shift_amount += 1
        if shift_amount > 0:
            # Copy row y to row y + shift_amount
            for x in range(10):
                var cell_value := grid.get_cell(x, y)
                grid.set_cell(x, y + shift_amount, cell_value)
                grid.set_cell(x, y, 0)  # clear source
```

**Critical**: The collapse must be atomic. All cleared rows disappear simultaneously before any remaining rows shift. From the perspective of any signal observer, the grid transitions from pre-collapse state to post-collapse state with no intermediate states.

**Collapse algorithm key properties**:
- Rows shift by the count of cleared rows BELOW them (not including themselves)
- A row at y=10 with cleared rows at y=3 and y=4 below it shifts by 2 to y=8
- The operation must handle non-adjacent cleared rows correctly

---

## Out of Scope

- Line detection (Story 001)
- Signal emission to downstream (Story 003)
- Lock delay or piece spawning

---

## QA Test Cases

**AC-2**: Non-adjacent rows — y=3 and y=5 cleared, rows above shift by 2
- Given: Grid with complete rows at y=3 and y=5, and a row at y=10 with occupied cells
- When: `_collapse_rows([3, 5])` is called
- Then: Row that was at y=10 is now at y=8 (shifted by 2)
- And: Rows at y=3 and y=5 are now EMPTY
- Edge cases: Row at y=4 (between cleared rows) also clears

**AC-6**: Shift amount calculation
- Given: Grid with rows at y=3 and y=4 cleared, row at y=10 occupied
- When: `_collapse_rows([3, 4])` is called
- Then: Row at y=10 moves to y=8 (shifted by 2)
- Edge cases: Row at y=3 exactly (already cleared), row at y=5 (just above cleared rows — shifts by 2)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/line_clear/row_collapse_test.gd` — must exist and pass

**Status**: [ ] Not yet created