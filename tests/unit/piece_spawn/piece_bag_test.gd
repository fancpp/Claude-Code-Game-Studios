# PieceBag Unit Tests — ADR-006 validation
# Tests Fisher-Yates shuffle, bag refill, and deterministic seeding.
extends GutTest

## Helper: count occurrences of each piece type in first n draws.
func _count_draws(bag: PieceBag, n: int) -> Dictionary:
	var counts = {}
	for i in range(1, 8):
		counts[i] = 0
	for i in range(n):
		var p = bag.get_next()
		counts[p] = counts.get(p, 0) + 1
	return counts

## Seeded bag with 12345: first 7 draws are all 7 pieces (no duplicates).
func test_seeded_bag_7_draws_all_unique() -> void:
	var bag = PieceBag.new(12345)
	var seen = {}
	var dups = 0
	for i in range(7):
		var p = bag.get_next()
		if seen.has(p):
			dups += 1
		seen[p] = true
	assert_eq(dups, 0, "No duplicates in first 7 draws with seed 12345")
	assert_eq(seen.size(), 7, "All 7 piece types appeared")

## Seeded bag: after 7 draws, bag auto-refills (8th draw succeeds).
func test_seeded_bag_refills_after_7() -> void:
	var bag = PieceBag.new(99999)
	# Draw 7
	for i in range(7):
		bag.get_next()
	# Bag should be empty now
	assert_true(bag.is_empty(), "Bag should be empty after 7 draws")
	# 8th draw should succeed (auto-refill)
	var piece = bag.get_next()
	assert_true(piece >= 1 and piece <= 7, "8th draw should return valid piece type, got %d" % piece)
	assert_false(bag.is_empty(), "Bag should not be empty after refill")

## Unseeded bag (seed=0): produces different first sequences each run.
func test_unseeded_bag_produces_sequence() -> void:
	var bag = PieceBag.new(0)  # explicit seed=0 means OS random
	var first7 = []
	for i in range(7):
		first7.append(bag.get_next())
	# All should be 1-7 with no duplicates
	var unique = first7.reduce(func(acc, p):
		if not acc.has(p): acc[p] = true
		return acc, {})
	assert_eq(unique.size(), 7, "Unseeded first 7 draws should all be unique")

## After refill, new bag has all 7 pieces again.
func test_second_bag_also_complete() -> void:
	var bag = PieceBag.new(42)
	# Drain and refill
	for i in range(7):
		bag.get_next()
	bag.get_next()  # triggers refill
	# New set of 7
	var seen = {}
	for i in range(7):
		var p = bag.get_next()
		seen[p] = true
	assert_eq(seen.size(), 7, "Second bag should also contain all 7 pieces")

## Each draw decrements bag size by 1.
func test_each_draw_decrements_size() -> void:
	var bag = PieceBag.new(1)
	# Initial bag has 7
	var draws = 0
	while not bag.is_empty():
		bag.get_next()
		draws += 1
	assert_eq(draws, 7, "Exactly 7 draws to empty a fresh bag")

## get_next() on empty bag triggers auto-refill without error.
func test_get_next_on_empty_refills() -> void:
	var bag = PieceBag.new(7)
	for i in range(7):
		bag.get_next()  # drain
	assert_true(bag.is_empty())
	var piece = bag.get_next()  # should not raise, should refill
	assert_true(piece >= 1 and piece <= 7, "Refill get_next should return valid piece")