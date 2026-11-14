extends RefCounted

var kind = ""
var id = ""
var desc = ""
var category = "object"
var subtlety = 2
var zone = ""
var tags: Array = []
var pre = false
var apply_fn: Callable


func apply() -> bool:
	if not apply_fn.is_valid():
		return false
	return bool(apply_fn.call())
