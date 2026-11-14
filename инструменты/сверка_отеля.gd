extends Node


const Script_ = "res://скрипты/карты/отель.gd"


func _ready():
	var a = _cook_it(true)
	var b = _cook_it(false)
	var ka = _get_the_keys(a)
	var kb = _get_the_keys(b)
	var bad = 0
	for cat in ka:
		var d = _what_changed(ka[cat], kb[cat])
		print("%-10s код=%d сцена=%d  только_в_коде=%d только_в_сцене=%d" % [cat, ka[cat].size(), kb[cat].size(), d[0].size(), d[1].size()])
		for s in d[0].slice(0, 8):
			print("   - код:   ", s)
		for s in d[1].slice(0, 8):
			print("   - сцена: ", s)
		bad += d[0].size() + d[1].size()

	var ra: Array = a.obj.keys()
	var rb: Array = b.obj.keys()
	ra.sort()
	rb.sort()
	var missing_in_scene_lol = ra.filter(func(k): return not b.obj.has(k))
	var missing_in_code_lol = rb.filter(func(k): return not a.obj.has(k))
	print("reg: код=%d сцена=%d  нет_в_сцене=%s  нет_в_коде=%s" % [ra.size(), rb.size(), missing_in_scene_lol, missing_in_code_lol])

	var moved = 0
	for k in ra:
		if b.obj.has(k) and a.obj[k] is Node3D and b.obj[k] is Node3D:
			var pa: Vector3 = (a.obj[k] as Node3D).global_position
			var pb: Vector3 = (b.obj[k] as Node3D).global_position
			if pa.distance_to(pb) > 0.001:
				moved += 1
				print("   позиция отличается: ", k, " ", pa, " ", pb)
	print("spawn: ", a.spawn_spot.origin, " ", b.spawn_spot.origin, " выход: ", a.exit_zone != null, " ", b.exit_zone != null)
	print("ИТОГ: расхождений=%d, reg-расхождений=%d, сдвинутых=%d" % [bad, missing_in_scene_lol.size() + missing_in_code_lol.size(), moved])
	get_tree().quit(0 if bad + missing_in_scene_lol.size() + missing_in_code_lol.size() + moved == 0 else 1)


func _cook_it(code: bool):
	await_nothing_lol()
	var m = load(Script_).new()
	m.force_the_code = code
	if code:
		m.params["bake"] = true
	add_child(m)
	m.build()
	return m


func await_nothing_lol():
	pass


func _r(v: Vector3) -> String:
	return "(%.3f,%.3f,%.3f)" % [v.x, v.y, v.z]


func _get_the_keys(map: Node) -> Dictionary:
	var output_pile = {"mesh": [], "light": [], "collision": [], "label": [], "particles": []}
	for n in map.find_children("*", "", true, false):
		if not n is Node3D:
			continue
		var n3 = n as Node3D
		var vis = n3.is_visible_in_tree()
		var tf = n3.global_transform
		var base = "%s|%s|%s|%s" % [n.get_class(), _r(tf.origin), _r(tf.basis.get_euler()), _r(tf.basis.get_scale())]
		if n is MeshInstance3D:
			var mi = n as MeshInstance3D
			var sz = mi.mesh.get_aabb().size if mi.mesh else Vector3.ZERO
			var mat = mi.material_override
			var col = ""
			if mat is StandardMaterial3D:
				col = str((mat as StandardMaterial3D).albedo_color) + str((mat as StandardMaterial3D).emission_energy_multiplier)
			output_pile["mesh"].append("%s|%s|%s|vis=%s" % [base, _r(sz), col, vis])
		elif n is Light3D:
			var l = n as Light3D
			output_pile["light"].append("%s|e=%.2f|%s|vis=%s" % [base, l.light_energy, str(l.light_color), vis])
		elif n is CollisionShape3D:
			var sh = (n as CollisionShape3D).shape
			output_pile["collision"].append("%s|%s|dis=%s" % [base, _r(sh.size) if sh is BoxShape3D else str(sh), (n as CollisionShape3D).disabled])
		elif n is Label3D:
			output_pile["label"].append("%s|%s|vis=%s" % [base, (n as Label3D).text.replace("\n", "/"), vis])
		elif n is GPUParticles3D:
			output_pile["particles"].append("%s|%d" % [base, (n as GPUParticles3D).amount])
	for k in output_pile:
		output_pile[k].sort()
	return output_pile


func _what_changed(x: Array, y: Array) -> Array:
	var cy = {}
	for s in y:
		cy[s] = cy.get(s, 0) + 1
	var only_x: Array = []
	for s in x:
		if cy.get(s, 0) > 0:
			cy[s] -= 1
		else:
			only_x.append(s)
	var only_y: Array = []
	for s in cy:
		for i in cy[s]:
			only_y.append(s)
	return [only_x, only_y]
