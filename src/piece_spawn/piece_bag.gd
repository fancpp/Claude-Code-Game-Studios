class_name PieceBag
extends RefCounted
## 7-bag randomizer: Fisher-Yates shuffle of [1,2,3,4,5,6,7].
## Seedable for deterministic tests. Auto-refills when empty.

var _bag: Array = []
var _rng: RandomNumberGenerator

func _init(seed_value: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	if seed_value != 0:
		_rng.seed = seed_value
	_shuffle_bag()

func _shuffle_bag() -> void:
	_bag = [1, 2, 3, 4, 5, 6, 7]
	# Fisher-Yates shuffle (backward)
	for i in range(_bag.size() - 1, 0, -1):
		var j := _rng.randi() % (i + 1)
		var tmp = _bag[i]
		_bag[i] = _bag[j]
		_bag[j] = tmp

## Returns next piece type (1-7). Refills and reshuffles bag when empty.
func get_next() -> int:
	if _bag.is_empty():
		_shuffle_bag()
	return _bag.pop_front()

## Returns true if bag is empty (all 7 pieces already drawn this cycle).
func is_empty() -> bool:
	return _bag.is_empty()