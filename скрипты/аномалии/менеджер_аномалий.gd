extends RefCounted

const Loc = preload("res://скрипты/ядро/локализация.gd")
const MEMORY_LENGTH = 8

var rng = RandomNumberGenerator.new()
var dice_seed = 0
var active: Array = []
var history: Array = []
var last_time_kinds: Array = []
var boring_streak = 0


func cook_up_plan(library: Array, diff: Dictionary, bonus = 0, forced_seed = -1) -> Array:
	dice_seed = forced_seed if forced_seed >= 0 else int(randi())
	rng.seed = dice_seed
	var weightz: Array = (diff["count_weights"] as Array).duplicate()
	for i in bonus:
		weightz[0] = float(weightz[0]) * 0.75
		weightz.append(float(weightz[weightz.size() - 1]) * 0.85)
	if boring_streak >= 2:
		weightz[0] = 0.0
	var the_result: Array = []
	for attempt in 10:
		var count = _roll_weighted(weightz)
		the_result = _pick_some(library, count, diff, bonus)
		if the_result.is_empty() or not history.has(fingerprint(the_result)):
			break
	return the_result


func lock_it_in(applied: Array, reference = false):
	active = applied
	if reference:
		return
	history.append(fingerprint(applied))
	while history.size() > MEMORY_LENGTH:
		history.pop_front()
	last_time_kinds = []
	for a in applied:
		last_time_kinds.append(a.kind)
	boring_streak = boring_streak + 1 if applied.is_empty() else 0


func how_many_really() -> int:
	return active.size()


func is_answer_right(answer: int) -> bool:
	return answer == active.size()


func gimme_descriptions() -> Array:
	var output_pile: Array = []
	for a in active:
		output_pile.append(Loc.desc(a.desc))
	return output_pile


func hint() -> String:
	if active.is_empty():
		return Loc.t("You sense nothing out of place here.")
	var a = active[rng.randi_range(0, active.size() - 1)]
	var where: String = Loc.zone(a.zone if a.zone != "" else "this place")
	match a.category:
		"light":
			return Loc.t("Pay attention to the lighting in %s.") % where
		"structure":
			return Loc.t("Pay attention to the walls, doors and ceiling in %s.") % where
		"supernatural":
			return Loc.t("Something that should not exist is in %s.") % where
		"sound":
			return Loc.t("Stop walking and listen.")
	return Loc.t("Pay attention to the objects in %s.") % where


func fingerprint(list: Array) -> String:
	var id_list: Array = []
	for a in list:
		id_list.append(a.id)
	id_list.sort()
	return "|".join(id_list)


func _pick_some(library: Array, count: int, diff: Dictionary, bonus: int) -> Array:
	var kind_buckets = {}
	for a in library:
		if not kind_buckets.has(a.kind):
			kind_buckets[a.kind] = []
		kind_buckets[a.kind].append(a)
	var kinds: Array = kind_buckets.keys()
	var sw: Dictionary = diff["subtlety_weights"]
	var w: Array = []
	for k in kinds:
		var subt: int = kind_buckets[k][0].subtlety
		var x = float(sw.get(subt, 1.0))
		if bonus > 0:
			if subt == 1:
				x *= 0.6
			elif subt == 3:
				x *= 1.4
		if last_time_kinds.has(k):
			x *= 0.25
		w.append(x)
	var taken_tags = {}
	var output_pile: Array = []
	while output_pile.size() < count:
		var which_one = _roll_weighted(w)
		if which_one < 0:
			break
		w[which_one] = 0.0
		var options_lol: Array = (kind_buckets[kinds[which_one]] as Array).duplicate()
		for i in range(options_lol.size() - 1, 0, -1):
			var j = rng.randi_range(0, i)
			var swappy = options_lol[i]
			options_lol[i] = options_lol[j]
			options_lol[j] = swappy
		for a in options_lol:
			if not _clashes(a, taken_tags):
				output_pile.append(a)
				for t in a.tags:
					taken_tags[t] = true
				break
	return output_pile


func _clashes(a, taken_tags: Dictionary) -> bool:
	for t in a.tags:
		if taken_tags.has(t):
			return true
	return false


func _roll_weighted(weightz: Array) -> int:
	var grand_total = 0.0
	for x in weightz:
		grand_total += float(x)
	if grand_total <= 0.0:
		return -1
	var r = rng.randf() * grand_total
	for i in weightz.size():
		r -= float(weightz[i])
		if r < 0.0:
			return i
	return weightz.size() - 1
