# E2E Tests

## Types

### 1. Headless Smoke Test (`game_smoke.gd`)
**Framework**: Godot GDScript (no browser required)
**Run**: `godot --headless --script tests/e2e/game_smoke.gd`
**CI**: `.github/workflows/tests.yml` → `smoke-test` job

Tests all 13 systems instantiate and basic functions work:
- Grid, Collision, Tetromino, PieceSpawn, GameState
- SpeedProgression, LineClear, ComboScoring, GhostPiece

### 2. Web E2E Tests (`game.spec.ts`)
**Framework**: Playwright + TypeScript
**Run**: `npm install && npx playwright test`
**CI**: Only runs when Godot web export templates are available

Critical user flows (web browser):
- Game loads without crash
- New game starts (Enter)
- Piece movement (←/→/↓)
- Rotation (X/Z)
- Hard drop (Space)
- Pause toggle (Escape)
- No console errors during 30s gameplay

## Setup (local)

### Headless smoke test
```bash
godot --headless --script tests/e2e/game_smoke.gd
```

### Web E2E tests
```bash
npm install
npx playwright install --with-deps chromium

# Export Godot to HTML5 (requires export templates)
godot --headless --export-release html export_temp

# Serve and run tests
cd export_temp && python3 -m http.server 8000 &
npx playwright test --config=../playwright.config.ts
```

## CI

| Job | Trigger | Runs |
|-----|---------|------|
| `gut-tests` | every push/PR | Unit tests (GUT) |
| `smoke-test` | after gut-tests pass | Headless smoke test (Godot script) |