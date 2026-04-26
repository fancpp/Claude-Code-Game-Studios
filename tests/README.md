# Test Suite — Tetris Arcade Challenge

## Framework

**GUT (Godot Unit Tester)** — GDScript unit testing framework for Godot 4.6.

- Plugin: `addons/gut/` (install via Godot AssetLib or clone from `bitbeans/gut`)
- Runner: `tests/gdunit4_runner.gd`

## Setup

```bash
# 1. Add GUT to your project
# Option A: Godot AssetLib → search "GUT" → install
# Option B: Clone directly
git clone https://github.com/bitbeans/gut.git addons/gut

# 2. Enable the addon in Project Settings → Plugins
# 3. Run tests from editor: Tools → GUT → Run All Tests
# 4. Or run headless from command line:
godot --headless --script tests/gdunit4_runner.gd
```

## Directory Structure

```
tests/
├── README.md              # This file
├── unit/                  # Unit tests — individual systems
│   ├── grid_test.gd       # Grid resource pattern
│   ├── tetromino_test.gd  # Tetromino shapes + rotation
│   ├── collision_test.gd  # Collision detection
│   ├── line_clear_test.gd # Line clearing logic
│   ├── combo_scoring_test.gd
│   └── das_timing_test.gd # DAS input timing
├── integration/           # Integration tests — multi-system
│   └── runner.gd          # Integration test runner
├── fixtures/              # Shared test fixtures
│   └── shapes.gd          # Tetromino shape constants for tests
└── gdunit4_runner.gd      # GUT runner (entry point for CI)
```

## Running Tests

### Local (editor)
```
Tools → GUT → Run All Tests
```

### Local (headless / CI)
```bash
godot --headless --script tests/gdunit4_runner.gd
```

### CI (GitHub Actions)
Tests run automatically on every push to `main` and on PRs via `.github/workflows/tests.yml`.

## Required Test Coverage (80% minimum)

Per `.claude/docs/coding-standards.md`:
- Tetromino rotation system
- Line clearing logic
- Combo scoring
- Collision detection
- DAS timing (input handler)

## Test Types

| Type | Location | Gate Level |
|------|----------|------------|
| Unit | `tests/unit/` | BLOCKING |
| Integration | `tests/integration/` | BLOCKING |

## CI/CD Rules

- No merge if tests fail — tests are a blocking gate in CI
- Never disable or skip failing tests to make CI pass — fix the underlying issue