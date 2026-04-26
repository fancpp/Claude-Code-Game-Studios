# Grid Unit Tests — Redirect
# Real tests moved to: tests/unit/grid/grid_api_test.gd
# This file is kept for backwards compatibility with existing test references.
# Tests: grid cell access (Story 001), boundary checks (Story 002), line clear collapse (future)
extends GutTest

func test_placeholder() -> void:
	# See tests/unit/grid/grid_api_test.gd for actual Grid API tests (Story 001)
	assert_true(true, "Grid placeholder — see tests/unit/grid/grid_api_test.gd")