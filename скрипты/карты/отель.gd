extends "res://скрипты/карты/база_карты.gd"

const SEC = 5.0
const HW = 1.8
const LH = 3.6
const WARM = Color(1.0, 0.72, 0.45)
const DECO = ["vase", "plant", "books"]
const SCENE = "res://сцены/отель/отель.tscn"
const PROC_NAMES = {
	"marble": "мрамора", "metal": "металла", "fabric": "ткани",
	"stain": "пятна", "shadow": "тени", "clock_face": "циферблата",
}
const DOOR_SCENE = preload("res://ассеты/модели/отель/модель двери номера.glb")
const SCONCE_SCENE = preload("res://ассеты/модели/отель/модель настенного бра.glb")
const TEX = "res://ассеты/текстуры/отель/текстура %s - %s.png"
const DOOR_HALF = 0.54
const SLAB_HALF = 0.45


func pbr(tex_name: String, scale: float, tint = Color.WHITE, uv = false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_texture = load(TEX % [tex_name, "цвет"])
	m.albedo_color = tint
	var rp = TEX % [tex_name, "шероховатость"]
	if ResourceLoader.exists(rp):
		m.roughness_texture = load(rp)
	m.roughness = 1.0
	if not uv:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


func the_prebaked_scene() -> String:
	return SCENE


func default_stuff() -> Dictionary:
	return {"sections": 7, "ceiling": 3.0}


func background_noise() -> String:
	return "amb_hotel"


func footstep_pitch() -> float:
	return 0.8


func preview_pic() -> Array:
	return [Vector3(0.35, 1.65, 3.2), Vector3(-0.2, 1.35, -14.0)]


func menu_pic() -> Array:
	return [Vector3(0.0, 1.62, 2.0), Vector3(0.0, 1.62, -12.0)]


func qa_pics() -> Array:
	return [
		[Vector3(0, 1.6, 7.5), Vector3(0, 1.4, -10)],
		[Vector3(0.4, 1.6, 1.5), Vector3(-4.5, 1.6, 5.5)],
		[Vector3(-0.5, 1.6, 2.5), Vector3(4.5, 1.3, 5.0)],
		[Vector3(0, 1.6, -11), Vector3(0, 1.4, -30)],
		[Vector3(0, 1.6, -31), Vector3(0, 1.4, -36)],
		[Vector3(0, 1.6, -22), Vector3(0, 1.5, 4)],
	]


func focus_pic(a) -> Array:
	var t: String = a.id.split(":")[1]
	var n = obj.get(t)
	if t.begins_with("sec"):
		var k = int(t.substr(3))
		return [Vector3(0, 1.6, zone_center_lol(k) + 5.0), Vector3(0, 1.4, zone_center_lol(k) - 2.0)]
	if n is Node3D and (n as Node3D).is_inside_tree():
		var p: Vector3 = (n as Node3D).global_position
		if p.z > 0.0:
			return [Vector3(0, 1.6, clampf(p.z - 3.5, 0.5, 8.0)), p + Vector3(0, 0.6, 0)]
		return [Vector3(-signf(p.x) * 0.6, 1.6, p.z + 3.2), p + Vector3(0, 0.6, 0)]
	return preview_pic()


static func zone_center_lol(i: int) -> float:
	return -(i + 0.5) * SEC


static func room(side: int, i: int) -> int:
	return 701 + 2 * i if side < 0 else 702 + 2 * i


static func side_rotation_lol(side: int) -> float:
	return 90.0 if side < 0 else -90.0


static func side_name_lol(side: int) -> String:
	return "L" if side < 0 else "R"


static func which_zone_is_this(i: int) -> String:
	if i <= 1:
		return "the first part of the corridor"
	if i <= 4:
		return "the middle of the corridor"
	return "the far end of the corridor"


func world_pos_lol(side: int, z: float, off: float, y = 0.0) -> Vector3:
	return Vector3(side * (HW - off), y, z)


func _cook_the_map():
	_material_pile()
	make_the_env({
		"ambient": Color(0.62, 0.48, 0.36), "ambient_energy": 0.42,
		"fog_color": Color(0.14, 0.10, 0.07), "fog_density": 0.012,
		"exposure": 1.1, "saturation": 0.9, "contrast": 1.1, "vol": 0.012,
	})
	var n: int = params["sections"]
	var grand_total = n + (1 if params.get("bake", false) else 0)
	var end = node(self, "Конец")
	_fancy_lobby()
	for i in grand_total:
		_chunk(i)
		if i >= n:
			set_here_or_not(obj["sec%d" % i], false)
	for k in n + 1:
		_lamps_over_here(k, end if k == n else self)
	_the_end(end)
	_secret_extras(end)
	spawn_spot = Transform3D(Basis(), Vector3(0, 0.05, 6.8))
	sprinkle_dust(Vector3(0, 1.5, -n * SEC * 0.5), Vector3(HW - 0.1, 1.3, n * SEC * 0.5), 130)
	sprinkle_dust(Vector3(0, 1.8, 4.5), Vector3(4.5, 1.6, 4.0), 60)


func _make_anomaly_stuff():
	M["wall_alt"] = pbr("обоев", 0.8, Color(0.95, 0.62, 0.62))
	M["leaf_dead"] = mat(Color(0.34, 0.23, 0.09), 0.9)
	M["vase_alt"] = mat(Color(0.60, 0.07, 0.07), 0.15)
	M["lamp_off"] = mat(Color(0.30, 0.27, 0.23), 0.5)


func _after_loading_lol():
	if int(params["sections"]) > 7:
		var sec7 = _find_node_lol("sec7")
		set_here_or_not(sec7, true)
		for side in ["L", "R"]:
			var patch = _find_node_lol("door_%s7_patch" % side)
			if patch:
				set_here_or_not(patch, false)
		find_child("Конец", true, false).position.z -= SEC
		for extra in ["lamp_L7b", "lamp_R7b"]:
			set_here_or_not(find_child(extra, true, false), true)
	if float(params["ceiling"]) < 3.0:
		var drop = 3.0 - float(params["ceiling"])
		for n in find_children("*", "Node3D", true, false):
			if n.has_meta("ceiling"):
				n.position.y -= drop
		set_here_or_not(find_child("Перемычка", true, false), true)
		_find_node_lol("exit_sign").position.y = float(params["ceiling"]) - 0.17


func _material_pile():
	_mesh_cache.clear()
	_make_anomaly_stuff()
	M["door_wood"] = pbr("тёмного дерева", 1.0, Color.WHITE, true)
	M["door_brass"] = pbr("латуни", 1.0, Color.WHITE, true)
	M["door_brass"].metallic = 0.5
	M["door_led"] = glow(Color(0.2, 1.0, 0.4), 2.0)
	M["door_lens"] = mat(Color(0.02, 0.03, 0.05), 0.1, 0.4)
	M["sconce_bulb"] = glow(Color(1.0, 0.85, 0.6), 2.0)
	var shade = pbr("абажура", 1.0, Color.WHITE, true)
	shade.emission_enabled = true
	shade.emission_texture = load(TEX % ["абажура", "свечение"])
	shade.emission_energy_multiplier = 1.4
	M["sconce_shade"] = shade
	M["wall"] = pbr("обоев", 0.8)
	M["wains"] = pbr("тёмного дерева", 0.9)
	M["trim"] = pbr("тёмного дерева", 1.2, Color(1.25, 1.15, 1.1))
	M["base"] = pbr("тёмного дерева", 1.2, Color(0.7, 0.7, 0.7))
	M["floor"] = pbr("тёмного дерева", 0.6, Color(0.8, 0.8, 0.8))
	M["carpet"] = pbr("ковра", 0.45)
	M["rug"] = pbr("ковра", 0.6)
	M["plaster"] = pbr("потолка", 0.5)
	M["door"] = pbr("тёмного дерева", 0.9)
	M["wood"] = pbr("тёмного дерева", 1.0)
	M["brass"] = pbr("латуни", 2.0)
	M["gilt"] = pbr("латуни", 1.5, Color(0.95, 0.85, 0.7))
	M["steel"] = mat(Color(0.55, 0.56, 0.58), 0.3, 0.4, "metal", 2.0)
	M["marble"] = mat(Color.WHITE, 0.2, 0.0, "marble", 0.35, 0.1)
	var dark = mat(Color(0.03, 0.022, 0.018), 1.0)
	dark.cull_mode = BaseMaterial3D.CULL_DISABLED
	M["dark"] = dark
	M["black"] = mat(Color(0.02, 0.02, 0.02), 0.4)
	M["white"] = mat(Color(0.9, 0.9, 0.88), 0.6)
	M["fabric"] = mat(Color(0.50, 0.11, 0.12), 0.95, 0.0, "fabric", 3.0)
	M["fabric2"] = mat(Color(0.18, 0.30, 0.32), 0.95, 0.0, "fabric", 3.0)
	M["leaf"] = mat(Color(0.13, 0.30, 0.10), 0.65)
	M["trunk"] = mat(Color(0.25, 0.17, 0.1), 0.9)
	M["pot"] = mat(Color(0.22, 0.20, 0.18), 0.45)
	M["soil"] = mat(Color(0.08, 0.06, 0.04), 1.0)
	M["vase"] = mat(Color(0.12, 0.22, 0.48), 0.15)
	M["red"] = mat(Color(0.72, 0.05, 0.04), 0.3, 0.1)
	M["leather"] = mat(Color(0.30, 0.16, 0.08), 0.55)
	M["paper"] = mat(Color(0.88, 0.84, 0.74), 0.9)
	M["book1"] = mat(Color(0.35, 0.08, 0.08), 0.7)
	M["book2"] = mat(Color(0.10, 0.18, 0.12), 0.7)
	M["figure"] = mat(Color(0.006, 0.006, 0.008), 0.95)
	M["glass"] = mat(Color(0.05, 0.06, 0.07), 0.05, 0.3)
	M["stain"] = see_through_mat("stain")
	M["shadow"] = see_through_mat("shadow", Color(1, 1, 1, 0.8), true)


func long_wall(parent: Node, a: Vector2, b: Vector2, n: Vector2, top: float, bottom = 0.0, wains = true, crown = true):
	var length = a.distance_to(b)
	if length < 0.01:
		return
	var mid = (a + b) * 0.5
	var along_z = absf(a.x - b.x) < 0.001
	var w = _big_slab(parent, mid - n * 0.06, length, 0.12, bottom, top, M["wall"], along_z, true)
	w.set_meta("swap", true)
	if wains:
		_big_slab(parent, mid + n * 0.015, length, 0.03, 0.0, 0.95, M["wains"], along_z)
		_big_slab(parent, mid + n * 0.03, length, 0.05, 0.93, 1.0, M["trim"], along_z)
		_big_slab(parent, mid + n * 0.035, length, 0.03, 0.0, 0.14, M["base"], along_z)
	if crown:
		_big_slab(parent, mid + n * 0.035, length, 0.07, top - 0.13, top, M["trim"], along_z)


func _big_slab(parent: Node, c: Vector2, length: float, thick: float, y0: float, y1: float, m: Material, along_z: bool, collide = false) -> MeshInstance3D:
	var size = Vector3(thick, y1 - y0, length) if along_z else Vector3(length, y1 - y0, thick)
	return box(parent, size, Vector3(c.x, (y0 + y1) * 0.5, c.y), m, collide)


func _fancy_lobby():
	var H: float = params["ceiling"]
	var lobby = node(self, "Lobby")
	sign_up_anomaly("lobby", lobby, "the lobby", "the lobby")
	box(lobby, Vector3(10, 0.2, 9), Vector3(0, -0.1, 4.5), M["marble"], true)
	box(lobby, Vector3(10, 0.1, 9), Vector3(0, LH + 0.05, 4.5), M["plaster"])
	for zz: float in [1.5, 4.5, 7.5]:
		box(lobby, Vector3(10, 0.18, 0.25), Vector3(0, LH - 0.09, zz), M["trim"])
	for xx: float in [-2.5, 2.5]:
		box(lobby, Vector3(0.25, 0.18, 9), Vector3(xx, LH - 0.09, 4.5), M["trim"])
	long_wall(lobby, Vector2(-5, 9), Vector2(-5, 0), Vector2(1, 0), LH)
	long_wall(lobby, Vector2(5, 0), Vector2(5, 9), Vector2(-1, 0), LH)
	long_wall(lobby, Vector2(5, 9), Vector2(-5, 9), Vector2(0, -1), LH)
	long_wall(lobby, Vector2(-5, 0), Vector2(-HW, 0), Vector2(0, 1), LH)
	long_wall(lobby, Vector2(HW, 0), Vector2(5, 0), Vector2(0, 1), LH)
	long_wall(lobby, Vector2(-HW, 0), Vector2(HW, 0), Vector2(0, 1), LH, H, false, true)
	var filler_stuff = box(lobby, Vector3(HW * 2, 0.38, 0.12), Vector3(0, 2.81, -0.06), M["wall"])
	filler_stuff.name = "Перемычка"
	set_here_or_not(filler_stuff, false)
	for sx: int in [-1, 1]:
		box(lobby, Vector3(0.26, H, 0.2), Vector3(sx * (HW + 0.05), H * 0.5, 0.06), M["trim"])
	text_in_3d_lol(lobby, "ROOMS  701 — 714", Vector3(0, (H + LH) * 0.5, 0.012), 0.0035, Color(0.16, 0.09, 0.04), 48, 0.0, true)
	plane(lobby, Vector2(2.6, 3.6), Vector3(2.9, 0.006, 4.5), M["rug"])

	for e: int in [-1, 1]:
		var el = node(lobby, "Elevator" + side_name_lol(e), Vector3(e * 2.2, 0, 9.0), 180.0)
		box(el, Vector3(1.7, 2.65, 0.08), Vector3(0, 1.325, 0.04), M["brass"])
		box(el, Vector3(0.68, 2.36, 0.04), Vector3(-0.345, 1.18, 0.1), M["steel"])
		box(el, Vector3(0.68, 2.36, 0.04), Vector3(0.345, 1.18, 0.1), M["steel"])
		box(el, Vector3(0.5, 0.24, 0.05), Vector3(0, 2.92, 0.04), M["black"])
		var ind = text_in_3d_lol(el, "7", Vector3(0, 2.92, 0.07), 0.0035, Color(2.4, 1.3, 0.35), 56, 0.0, false)
		var ename = "elev_" + side_name_lol(e)
		sign_up_anomaly(ename, ind, "the floor indicator above the %s elevator" % ("left" if e < 0 else "right"), "the lobby")
	box(lobby, Vector3(0.14, 0.3, 0.03), Vector3(0, 1.2, 8.985), M["brass"])
	ball_lol(lobby, 0.025, Vector3(0, 1.25, 8.96), glow(Color(1.0, 0.6, 0.2), 3.0))
	ball_lol(lobby, 0.025, Vector3(0, 1.15, 8.96), glow(Color(1.0, 0.6, 0.2), 0.6))

	var desk = node(lobby, "Desk", Vector3(-3.8, 0, 4.5), 90.0)
	box(desk, Vector3(3.6, 1.1, 0.7), Vector3(0, 0.55, 0), M["wood"], true)
	box(desk, Vector3(3.75, 0.06, 0.86), Vector3(0, 1.13, 0.05), M["marble"])
	for k in 3:
		box(desk, Vector3(1.0, 0.72, 0.02), Vector3(-1.2 + k * 1.2, 0.5, 0.36), M["wains"])
	text_in_3d_lol(desk, "RECEPTION", Vector3(0, 0.96, 0.372), 0.0032, Color(0.85, 0.68, 0.38), 56, 0.0, true)
	var bell = node(desk, "Bell", Vector3(-1.1, 1.16, 0.18))
	cylinder_lol(bell, 0.055, 0.055, 0.015, Vector3(0, 0.008, 0), M["black"])
	ball_lol(bell, 0.045, Vector3(0, 0.03, 0), M["brass"], Vector3(1, 0.75, 1))
	sign_up_anomaly("bell", bell, "the reception bell", "the lobby")
	var book = box(desk, Vector3(0.34, 0.04, 0.24), Vector3(0.2, 1.18, 0.12), M["book1"])
	book.rotation.y = 0.2
	var dl = node(desk, "DeskLamp", Vector3(1.2, 1.16, -0.05))
	cylinder_lol(dl, 0.07, 0.08, 0.02, Vector3(0, 0.01, 0), M["brass"])
	cylinder_lol(dl, 0.01, 0.01, 0.3, Vector3(0, 0.16, 0), M["brass"])
	var dshade = box(dl, Vector3(0.3, 0.07, 0.12), Vector3(0, 0.33, 0.06), glow(Color(0.25, 0.75, 0.4), 1.6))
	var dlt = omni_light_lol(dl, Vector3(0, 0.25, 0.15), Color(1.0, 0.92, 0.7), 0.6, 2.8)
	_tag_the_lamp(dl, [dlt], [dshade], M["lamp_off"])
	sign_up_anomaly("desk_lamp", dl, "the green lamp on the reception desk", "the lobby")

	var kb = node(lobby, "KeyBoard", Vector3(-4.97, 0, 4.5), 90.0)
	box(kb, Vector3(1.45, 0.92, 0.04), Vector3(0, 1.75, 0.02), M["wood"])
	for r in 3:
		for c in 4:
			var key = node(kb, "Key%d" % (r * 4 + c), Vector3(-0.5 + c * 0.333, 2.05 - r * 0.28, 0.05))
			box(key, Vector3(0.02, 0.02, 0.03), Vector3(0, 0, -0.01), M["brass"])
			box(key, Vector3(0.025, 0.07, 0.008), Vector3(0, -0.05, 0.0), M["brass"])
			box(key, Vector3(0.05, 0.09, 0.01), Vector3(0, -0.12, 0.0), M["book1"])
			sign_up_anomaly("key_%d" % (r * 4 + c), key, "a room key behind the reception desk", "the lobby")
	sign_up_anomaly("clock_lobby", clock(lobby, "LobbyClock", Vector3(-4.96, 2.85, 4.5), 90.0, 0.24, M["brass"], 10.0, 10.0), "the lobby clock", "the lobby")

	sign_up_anomaly("chair_lobby_0", comfy_chair(lobby, "ChairLobby0", Vector3(3.9, 0, 3.6), -90.0, M["fabric2"]), "the armchair in the lobby", "the lobby")
	sign_up_anomaly("chair_lobby_1", comfy_chair(lobby, "ChairLobby1", Vector3(3.9, 0, 5.4), -90.0, M["fabric2"]), "the second armchair in the lobby", "the lobby")
	var ct = node(lobby, "CoffeeTable", Vector3(2.9, 0, 4.5))
	box(ct, Vector3(0.7, 0.05, 1.1), Vector3(0, 0.42, 0), M["wood"])
	box(ct, Vector3(0.5, 0.38, 0.9), Vector3(0, 0.2, 0), M["wood"], true)
	bling(ct, "LobbyBooks", Vector3(0, 0.45, 0.2), "books")
	sign_up_anomaly("plant_lobby", leafy_boi(lobby, "PlantLobby", Vector3(4.3, 0, 1.0), 1.25), "the tall plant in the lobby corner", "the lobby")
	leafy_boi(lobby, "PlantLobby2", Vector3(-4.3, 0, 1.0), 1.25)

	var ch = node(lobby, "Chandelier", Vector3(0, LH - 0.55, 4.5))
	cylinder_lol(ch, 0.01, 0.01, 0.5, Vector3(0, 0.3, 0), M["brass"])
	cylinder_lol(ch, 0.35, 0.35, 0.03, Vector3(0, 0, 0), M["gilt"], false, 24)
	var bulb_pile: Array = []
	for k in 8:
		var ang = k * TAU / 8.0
		var bm = glow(WARM, 3.5)
		bulb_pile.append(ball_lol(ch, 0.045, Vector3(cos(ang) * 0.35, 0.06, sin(ang) * 0.35), bm))
	bulb_pile.append(ball_lol(ch, 0.09, Vector3(0, -0.1, 0), glow(WARM, 2.5)))
	var chl = omni_light_lol(ch, Vector3(0, -0.2, 0), WARM, 2.0, 10.0, 0)
	_tag_the_lamp(ch, [chl], bulb_pile, M["lamp_off"])
	sign_up_anomaly("chandelier", ch, "the lobby chandelier", "the lobby")
	var li = 0
	for sx: int in [-1, 1]:
		for zz: float in [1.4, 7.6]:
			var nm = "lamp_lobby_%d" % li
			sign_up_anomaly(nm, wall_candle(lobby, nm, Vector3(sx * 4.98, 2.1, zz), side_rotation_lol(sx), 20 + li), "a wall lamp in the lobby", "the lobby")
			li += 1


func _chunk(i: int):
	var H: float = params["ceiling"]
	var z0 = -i * SEC
	var z1 = z0 - SEC
	var c = zone_center_lol(i)
	var zone = which_zone_is_this(i)
	var sec = node(self, "Sec%d" % i)
	sign_up_anomaly("sec%d" % i, sec, "the section with rooms %d and %d" % [room(-1, i), room(1, i)], zone)
	box(sec, Vector3(HW * 2 + 0.4, 0.2, SEC), Vector3(0, -0.1, c), M["floor"], true)
	plane(sec, Vector2(HW * 2, SEC), Vector3(0, 0.006, c), M["carpet"])
	var ceil_parts = [
		box(sec, Vector3(HW * 2, 0.1, SEC), Vector3(0, H + 0.05, c), M["plaster"]),
		box(sec, Vector3(HW * 2, 0.16, 0.26), Vector3(0, H - 0.08, z1), M["trim"]),
		cylinder_lol(sec, 0.06, 0.06, 0.03, Vector3(0, H - 0.015, c + 1.2), M["white"]),
		box(sec, Vector3(0.5, 0.02, 0.3), Vector3(0, H - 0.01, c - 1.4), M["steel"]),
	]
	for part in ceil_parts:
		part.set_meta("ceiling", true)

	for side: int in [-1, 1]:
		var s = side_name_lol(side)
		var x = side * HW
		var nrm = Vector2(-side, 0)
		var gname = "walls_%s%d" % [s, i]
		var grp = node(sec, gname)
		sign_up_anomaly(gname, grp, "the %s wall near room %d" % ["left" if side < 0 else "right", room(side, i)], zone)
		long_wall(grp, Vector2(x, z0), Vector2(x, c + DOOR_HALF), nrm, H)
		long_wall(grp, Vector2(x, c - DOOR_HALF), Vector2(x, z1), nrm, H)
		long_wall(grp, Vector2(x, c + DOOR_HALF), Vector2(x, c - DOOR_HALF), nrm, H, 2.15, false, true)
		var dn = "door_%s%d" % [s, i]
		sign_up_anomaly(dn, door(sec, dn, Vector3(x, 0, c), side_rotation_lol(side), str(room(side, i)), true), "the door of room %d" % room(side, i), zone)
		var patch = node(sec, dn + "_patch")
		long_wall(patch, Vector2(x, c + DOOR_HALF), Vector2(x, c - DOOR_HALF), nrm, 2.15, 0.0, true, false)
		set_here_or_not(patch, false)
		sign_up_anomaly(dn + "_patch", patch, "", zone)

	var tside = 1 if i % 2 == 0 else -1
	var tn = "table_%d" % i
	sign_up_anomaly(tn, little_table(sec, tn, world_pos_lol(tside, c - 1.5, 0.24), side_rotation_lol(tside)), "the side table near room %d" % room(tside, i), zone)
	var dkind: String = DECO[i % 3]
	var dn2 = "deco_%d" % i
	var dlabel = {"vase": "the blue vase", "plant": "the small plant", "books": "the stack of books"}
	sign_up_anomaly(dn2, bling(sec, dn2, world_pos_lol(tside, c - 1.5, 0.24, 0.8), dkind), "%s on the side table near room %d" % [dlabel[dkind], room(tside, i)], zone)

	if i % 2 == 0:
		var pl = "plant_%d" % i
		sign_up_anomaly(pl, leafy_boi(sec, pl, world_pos_lol(1, c + 1.5, 0.32), 1.0), "the potted palm near room %d" % room(1, i), zone)
	else:
		var cn = "chair_%d" % i
		sign_up_anomaly(cn, comfy_chair(sec, cn, world_pos_lol(-1, c + 1.5, 0.48), side_rotation_lol(-1), M["fabric"]), "the armchair near room %d" % room(-1, i), zone)
	if i == 2:
		sign_up_anomaly("ext", fire_thing(sec, "Ext", world_pos_lol(-1, c + 1.5, 0.0), side_rotation_lol(-1)), "the fire extinguisher", zone)
		var sg = node(sec, "ExtSign", world_pos_lol(-1, c + 1.5, 0.006, 1.78), side_rotation_lol(-1))
		box(sg, Vector3(0.24, 0.24, 0.01), Vector3.ZERO, M["red"])
		text_in_3d_lol(sg, "FIRE", Vector3(0, 0, 0.007), 0.0022, Color(1, 1, 1), 40, 0.0, true)


func _lamps_over_here(k: int, parent: Node):
	var n: int = params["sections"]
	var z = -k * SEC
	if k == 0:
		z = -0.3
	elif k == n:
		z = -n * SEC + 0.4
	for side: int in [-1, 1]:
		var nm = "lamp_%s%d" % [side_name_lol(side), k]
		var prio = 1 + k * 2 + (0 if (k % 2 == 0) == (side < 0) else 1)
		sign_up_anomaly(nm, wall_candle(parent, nm, Vector3(side * HW, 2.05, z), side_rotation_lol(side), prio), _lamp_name_tag(side, k, n), which_zone_is_this(clampi(k, 0, n - 1)))


func _lamp_name_tag(side: int, k: int, n: int) -> String:
	var s = "left" if side < 0 else "right"
	if k == 0:
		return "the %s wall lamp at the start of the corridor" % s
	if k >= n:
		return "the %s wall lamp by the exit" % s
	return "the %s wall lamp between rooms %d and %d" % [s, room(side, k - 1), room(side, k)]


func _the_end(end: Node):
	var n: int = params["sections"]
	var H: float = params["ceiling"]
	var ze = -n * SEC
	long_wall(end, Vector2(HW, ze), Vector2(-HW, ze), Vector2(0, 1), H)
	var d = node(end, "ExitDoor", Vector3(0, 0, ze))
	box(d, Vector3(0.1, 2.45, 0.07), Vector3(-0.9, 1.225, 0.035), M["trim"])
	box(d, Vector3(0.1, 2.45, 0.07), Vector3(0.9, 1.225, 0.035), M["trim"])
	box(d, Vector3(1.9, 0.1, 0.07), Vector3(0, 2.4, 0.035), M["trim"])
	for sx: int in [-1, 1]:
		box(d, Vector3(0.83, 2.33, 0.05), Vector3(sx * 0.42, 1.165, 0.03), M["door"], true)
		box(d, Vector3(0.28, 0.42, 0.01), Vector3(sx * 0.42, 1.75, 0.06), M["glass"])
		box(d, Vector3(0.6, 0.05, 0.05), Vector3(sx * 0.42, 1.05, 0.08), M["brass"])
	var sy = minf(2.72, H - 0.17)
	var sign = node(end, "ExitSign", Vector3(0, sy, ze + 0.05))
	box(sign, Vector3(0.6, 0.22, 0.08), Vector3.ZERO, M["black"])
	var face = box(sign, Vector3(0.54, 0.16, 0.01), Vector3(0, 0, 0.045), glow(Color(0.1, 0.75, 0.3), 0.7))
	text_in_3d_lol(sign, "EXIT", Vector3(0, 0, 0.052), 0.003, Color(0.92, 1, 0.92), 48, 0.0, false)
	var gl = omni_light_lol(sign, Vector3(0, -0.15, 0.3), Color(0.3, 1.0, 0.5), 0.5, 3.0)
	_tag_the_lamp(sign, [gl], [face], M["lamp_off"])
	sign_up_anomaly("exit_sign", sign, "the EXIT sign", which_zone_is_this(n - 1))
	text_in_3d_lol(end, "STAIRWELL\nFLOOR 7", Vector3(1.37, 1.55, ze + 0.012), 0.0018, Color(0.85, 0.68, 0.38), 40, 0.0, true)
	make_the_exit_door(Vector3(0, 1.2, ze + 0.35), Vector3(1.8, 2.4, 0.5), end)


func _secret_extras(end: Node):
	var n: int = params["sections"]
	for side: int in [-1, 1]:
		var extra = wall_candle(self, "lamp_%s7b" % side_name_lol(side), Vector3(side * HW, 2.05, -n * SEC), side_rotation_lol(side), -1)
		set_here_or_not(extra, false)
	var e0 = door(self, "door_extra_0", Vector3(-HW + 0.058, 0, zone_center_lol(0) + 1.5), 90.0, "", false)
	set_here_or_not(e0, false)
	sign_up_anomaly("door_extra_0", e0, "a new door", which_zone_is_this(0))
	var e4 = door(self, "door_extra_4", Vector3(-HW + 0.058, 0, zone_center_lol(4) + 1.5), 90.0, "", false)
	set_here_or_not(e4, false)
	sign_up_anomaly("door_extra_4", e4, "a new door", which_zone_is_this(4))

	var sc = node(self, "Suitcase", world_pos_lol(1, zone_center_lol(1) + 0.95, 0.32), -70.0)
	box(sc, Vector3(0.48, 0.64, 0.22), Vector3(0, 0.38, 0), M["leather"], true)
	box(sc, Vector3(0.2, 0.04, 0.04), Vector3(0, 0.72, 0), M["black"])
	box(sc, Vector3(0.5, 0.03, 0.24), Vector3(0, 0.52, 0), M["brass"])
	cylinder_lol(sc, 0.03, 0.03, 0.03, Vector3(-0.18, 0.03, 0), M["black"])
	cylinder_lol(sc, 0.03, 0.03, 0.03, Vector3(0.18, 0.03, 0), M["black"])
	set_here_or_not(sc, false)
	sign_up_anomaly("suitcase", sc, "a suitcase", which_zone_is_this(1))

	var te = little_table(self, "TableExtra", world_pos_lol(-1, zone_center_lol(6) + 1.5, 0.24), side_rotation_lol(-1))
	bling(te, "ExtraVase", Vector3(0, 0.8, 0), "vase")
	set_here_or_not(te, false)
	sign_up_anomaly("table_extra", te, "an extra side table", which_zone_is_this(6))

	var sa = plane(self, Vector2(0.9, 0.7), Vector3(0.35, 0.013, zone_center_lol(2) + 0.3), M["stain"])
	sa.visible = false
	sign_up_anomaly("stain_a", sa, "a stain on the carpet", which_zone_is_this(2))
	var sb = plane(self, Vector2(0.8, 0.9), Vector3(-0.3, 0.013, zone_center_lol(5) - 0.9), M["stain"])
	sb.visible = false
	sign_up_anomaly("stain_b", sb, "a stain on the carpet", which_zone_is_this(5))

	for pair in [["shadow_a", 3], ["shadow_b", 5]]:
		var which_one: int = pair[1]
		var sh = quad(self, Vector2(0.75, 1.75), Vector3(HW - 0.012, 1.05, zone_center_lol(which_one) + 0.8), M["shadow"], -90.0)
		sh.set_meta("a", Vector3(HW - 0.012, 1.05, zone_center_lol(which_one) + 0.8))
		sh.set_meta("b", Vector3(HW - 0.012, 1.05, zone_center_lol(which_one) + 2.2))
		sh.visible = false
		sign_up_anomaly(pair[0], sh, "a shadow", which_zone_is_this(which_one))

	var fe = spooky_guy(end, "fig_end", Vector3(-0.9, 0, -n * SEC + 1.6), M["figure"])
	set_here_or_not(fe, false)
	sign_up_anomaly("fig_end", fe, "a figure", which_zone_is_this(n - 1))
	var fl = spooky_guy(self, "fig_lobby", Vector3(3.9, 0, 8.3), M["figure"], 180.0)
	set_here_or_not(fl, false)
	sign_up_anomaly("fig_lobby", fl, "a figure", "the lobby")

	sign_up_anomaly("snd_steps", node(self, "SndSteps", Vector3(HW + 1.0, 1.2, zone_center_lol(4))), "", which_zone_is_this(4))
	sign_up_anomaly("snd_knock", node(self, "SndKnock", Vector3(-HW - 0.6, 1.2, zone_center_lol(2))), "", which_zone_is_this(2))
	sign_up_anomaly("snd_whisper", node(self, "SndWhisper", Vector3(HW + 0.6, 1.4, zone_center_lol(5))), "", which_zone_is_this(5))


func door(parent: Node, nm: String, pos: Vector3, rot: float, number: String, real = true) -> Node3D:
	var d = node(parent, nm, pos, rot)
	var model: Node3D = DOOR_SCENE.instantiate()
	var inner: Node = model.get_child(0)
	var hinge = node(d, "Hinge", Vector3(-SLAB_HALF, 0, 0))
	var table = {
		"M_Hotel_DarkWood": M["door_wood"], "M_Hotel_Brass": M["door_brass"],
		"M_Hotel_DoorNumber": M["door_brass"], "M_Hotel_BlackPlastic": M["black"],
		"M_Hotel_LED_Green": M["door_led"], "M_Hotel_Peephole": M["door_lens"],
	}
	for c in inner.get_children():
		if not c is MeshInstance3D:
			continue
		inner.remove_child(c)
		c.owner = null
		_inlinez(c, table)
		if String(c.name).begins_with("Casing"):
			d.add_child(c)
		else:
			hinge.add_child(c)
			(c as Node3D).position = Vector3(SLAB_HALF, 0, 0)
	model.free()
	invisible_wall(hinge, Vector3(0.9, 2.1, 0.04), Vector3(SLAB_HALF, 1.05, 0.02))
	if number != "":
		var num = text_in_3d_lol(hinge, number, Vector3(SLAB_HALF, 1.72, 0.043), 0.0019, Color(0.1, 0.06, 0.02), 40, 0.0, true, "serif")
		sign_up_anomaly(nm + "_num", num)
	if real:
		box(d, Vector3(1.08, 2.19, 1.6), Vector3(0, 1.095, -0.82), M["dark"])
		invisible_wall(d, Vector3(1.08, 2.2, 0.1), Vector3(0, 1.1, -1.6))
		var dnd = node(hinge, "DND", Vector3(SLAB_HALF + 0.3, 0.78, 0.035))
		box(dnd, Vector3(0.1, 0.2, 0.005), Vector3.ZERO, M["red"])
		text_in_3d_lol(dnd, "DO NOT\nDISTURB", Vector3(0, 0, 0.004), 0.0009, Color(1, 1, 1), 32, 0.0, true)
		set_here_or_not(dnd, false)
		sign_up_anomaly(nm + "_dnd", dnd)
	return d


var _mesh_cache = {}


func _inlinez(mi: MeshInstance3D, table: Dictionary):
	var src = mi.mesh as ArrayMesh
	if _mesh_cache.has(src):
		mi.mesh = _mesh_cache[src]
		return
	var copy = src.duplicate() as ArrayMesh
	for s in copy.get_surface_count():
		var old = src.surface_get_material(s)
		copy.surface_set_material(s, table.get(old.resource_name if old else "", M["black"]))
	_mesh_cache[src] = copy
	mi.mesh = copy


func wall_candle(parent: Node, nm: String, pos: Vector3, rot: float, prio: int) -> Node3D:
	var l = node(parent, nm, pos, rot)
	var model: Node3D = SCONCE_SCENE.instantiate()
	var table = {
		"M_Hotel_Brass": M["door_brass"], "M_Hotel_Bulb": M["sconce_bulb"], "M_Hotel_Shade": M["sconce_shade"],
	}
	var glow_pile: Array = []
	for c in model.get_child(0).get_children():
		if not c is MeshInstance3D:
			continue
		model.get_child(0).remove_child(c)
		c.owner = null
		_inlinez(c, table)
		l.add_child(c)
		(c as Node3D).position = Vector3(0, -0.12, 0)
		if c.name == "Shade" or c.name == "Bulb":
			glow_pile.append(c)
	model.free()
	var lt = omni_light_lol(l, Vector3(0, 0.08, 0.3), WARM, 1.3, 5.2, prio)
	_tag_the_lamp(l, [lt], glow_pile, M["lamp_off"])
	return l


func little_table(parent: Node, nm: String, pos: Vector3, rot: float) -> Node3D:
	var t = node(parent, nm, pos, rot)
	box(t, Vector3(0.9, 0.04, 0.42), Vector3(0, 0.78, 0), M["wood"])
	box(t, Vector3(0.84, 0.1, 0.36), Vector3(0, 0.71, 0), M["wood"])
	for lx in [-0.4, 0.4]:
		for lz in [-0.17, 0.17]:
			box(t, Vector3(0.04, 0.68, 0.04), Vector3(lx, 0.34, lz), M["wood"])
	invisible_wall(t, Vector3(0.9, 0.8, 0.42), Vector3(0, 0.4, 0))
	return t


func bling(parent: Node, nm: String, pos: Vector3, kind: String) -> Node3D:
	var d = node(parent, nm, pos)
	match kind:
		"vase":
			cylinder_lol(d, 0.05, 0.085, 0.26, Vector3(0, 0.13, 0), M["vase"]).set_meta("swap", true)
			cylinder_lol(d, 0.035, 0.03, 0.09, Vector3(0, 0.3, 0), M["vase"]).set_meta("swap", true)
			for k in 3:
				var ang = k * TAU / 3.0
				cylinder_lol(d, 0.004, 0.004, 0.22, Vector3(cos(ang) * 0.02, 0.42, sin(ang) * 0.02), M["leaf"])
				ball_lol(d, 0.035, Vector3(cos(ang) * 0.05, 0.54, sin(ang) * 0.05), M["red"])
		"plant":
			cylinder_lol(d, 0.08, 0.06, 0.13, Vector3(0, 0.065, 0), M["pot"])
			_leafy_bits(d, Vector3(0, 0.2, 0), 7, 0.08, 0.09)
		"books":
			box(d, Vector3(0.24, 0.05, 0.17), Vector3(0, 0.025, 0), M["book1"])
			box(d, Vector3(0.22, 0.045, 0.16), Vector3(0.01, 0.073, 0), M["book2"], false, 9.0)
			box(d, Vector3(0.23, 0.04, 0.17), Vector3(-0.01, 0.115, 0), M["paper"], false, -6.0)
			ball_lol(d, 0.04, Vector3(0.02, 0.175, 0), M["brass"])
	return d


func _leafy_bits(parent: Node, center: Vector3, count: int, radius: float, size: float):
	for k in count:
		var ang = k * TAU / count + 0.3 * (k % 2)
		var lf = ball_lol(parent, size, center + Vector3(cos(ang) * radius, (k % 3) * 0.04, sin(ang) * radius), M["leaf"], Vector3(1.6, 0.3, 0.6))
		lf.rotation = Vector3(0, -ang, 0.35)
		lf.set_meta("swap", true)


func leafy_boi(parent: Node, nm: String, pos: Vector3, s = 1.0) -> Node3D:
	var p = node(parent, nm, pos)
	cylinder_lol(p, 0.21 * s, 0.16 * s, 0.48 * s, Vector3(0, 0.24 * s, 0), M["pot"], true)
	cylinder_lol(p, 0.19 * s, 0.19 * s, 0.02, Vector3(0, 0.47 * s, 0), M["soil"])
	cylinder_lol(p, 0.025, 0.035, 0.7 * s, Vector3(0, 0.8 * s, 0), M["trunk"])
	for k in 9:
		var ang = k * TAU / 9.0
		var lf = ball_lol(p, 0.22 * s, Vector3(cos(ang) * 0.24 * s, (1.12 + (k % 3) * 0.08) * s, sin(ang) * 0.24 * s), M["leaf"], Vector3(1.7, 0.12, 0.42))
		lf.rotation = Vector3(0, -ang, -0.45 - (k % 2) * 0.25)
		lf.set_meta("swap", true)
	_leafy_bits(p, Vector3(0, 0.62 * s, 0), 5, 0.12 * s, 0.13 * s)
	return p


func comfy_chair(parent: Node, nm: String, pos: Vector3, rot: float, fabric: Material) -> Node3D:
	var c = node(parent, nm, pos, rot)
	box(c, Vector3(0.82, 0.24, 0.78), Vector3(0, 0.3, 0), fabric)
	box(c, Vector3(0.6, 0.12, 0.64), Vector3(0, 0.48, 0.05), fabric)
	box(c, Vector3(0.82, 0.62, 0.16), Vector3(0, 0.74, -0.31), fabric)
	box(c, Vector3(0.12, 0.3, 0.74), Vector3(-0.35, 0.55, 0.0), fabric)
	box(c, Vector3(0.12, 0.3, 0.74), Vector3(0.35, 0.55, 0.0), fabric)
	for lx in [-0.34, 0.34]:
		for lz in [-0.32, 0.32]:
			box(c, Vector3(0.05, 0.18, 0.05), Vector3(lx, 0.09, lz), M["wood"])
	invisible_wall(c, Vector3(0.82, 1.0, 0.8), Vector3(0, 0.5, 0))
	return c


func fire_thing(parent: Node, nm: String, pos: Vector3, rot: float) -> Node3D:
	var e = node(parent, nm, pos, rot)
	box(e, Vector3(0.14, 0.05, 0.05), Vector3(0, 1.3, 0.025), M["black"])
	cylinder_lol(e, 0.085, 0.085, 0.52, Vector3(0, 1.02, 0.11), M["red"])
	cylinder_lol(e, 0.03, 0.05, 0.08, Vector3(0, 1.32, 0.11), M["black"])
	box(e, Vector3(0.14, 0.025, 0.03), Vector3(0.04, 1.38, 0.11), M["black"])
	box(e, Vector3(0.025, 0.3, 0.025), Vector3(0.1, 1.12, 0.14), M["black"])
	return e


func make_the_anomaly_list() -> Array:
	if not lib.is_empty():
		return lib
	var n = 7
	var red = Color(1.0, 0.1, 0.06)

	for k in n + 1:
		for s in ["L", "R"]:
			var nm: String = "lamp_%s%d" % [s, k]
			anomaly_lights_out("lamp_off", nm, cap(label_it(nm)) + " was switched off.", 2, [nm])
			anomaly_paint_light("lamp_red", nm, red, cap(label_it(nm)) + " was glowing red.", 1, [nm])
			anomaly_disco("lamp_flicker", nm, cap(label_it(nm)) + " was flickering.", 1, [nm])
	for k in range(1, n - 1):
		var tags = ["lamp_L%d" % k, "lamp_R%d" % k, "lamp_L%d" % (k + 1), "lamp_R%d" % (k + 1)]
		add("dark_section", "sec%d" % k, "The section with rooms %d and %d was dark — four wall lamps were off." % [room(-1, k), room(1, k)], "light", 1, _yeet_lights_off.bind(tags), tags)
	anomaly_lights_out("chandelier_off", "chandelier", "The lobby chandelier was switched off.", 1)
	anomaly_paint_light("exit_sign_red", "exit_sign", Color(1.0, 0.08, 0.05), "The EXIT sign above the stairwell door was red instead of green.", 2)
	anomaly_lights_out("desk_lamp_off", "desk_lamp", "The green lamp on the reception desk was off.", 2)

	for i in n:
		for side: int in [-1, 1]:
			var dn = "door_%s%d" % [side_name_lol(side), i]
			var num = str(room(side, i))
			var wrong = num[0] + num[2] + num[1]
			if wrong == num:
				wrong = "8" + num.substr(1)
			add("door_ajar", dn, "The door of room %s was ajar." % num, "object", 2, _yeet_door_open.bind(dn), [dn])
			add("door_number", dn, "Room %s had the wrong number on its door: %s." % [num, wrong], "object", 3, _yeet_text.bind(dn + "_num", wrong), [dn])
			add("door_gone", dn, "The door of room %s had vanished — only wall remained." % num, "structure", 2, _yeet_door_gone.bind(dn), [dn])
			if (i % 2 == 0) == (side > 0):
				add("dnd_sign", dn, "A DO NOT DISTURB sign hung on the door of room %s." % num, "object", 3, _yeet_show.bind(dn + "_dnd"), [dn])
	anomaly_show_it("door_extra", "door_extra_0", "A new door with no number appeared near room 701.", 2, "structure")
	anomaly_show_it("door_extra", "door_extra_4", "A new door with no number appeared near room 709.", 2, "structure")

	for i in n:
		var dn = "deco_%d" % i
		var kind: String = DECO[i % 3]
		anomaly_hide_it("deco_gone", dn, cap(label_it(dn)) + " was gone.", 2)
		if kind == "vase":
			anomaly_swap_mat("vase_color", dn, "vase_alt", cap(label_it(dn)) + " had turned red.", 3)
		elif kind == "plant":
			anomaly_swap_mat("plant_dead", dn, "leaf_dead", cap(label_it(dn)) + " had withered.", 2)
		var tn = "table_%d" % i
		add("table_gone", tn, cap(label_it(tn)) + " had disappeared together with everything on it.", "object", 2, _yeet_hide_many.bind([tn, dn]), [tn, dn])
		if i % 2 == 0:
			var pl = "plant_%d" % i
			anomaly_hide_it("plant_gone", pl, cap(label_it(pl)) + " had disappeared.", 2)
			anomaly_swap_mat("plant_dead", pl, "leaf_dead", cap(label_it(pl)) + " had withered and turned brown.", 2)
		else:
			var cn = "chair_%d" % i
			anomaly_scoot("chair_moved", cn, Vector3(0.3, 0, 0.45), 38.0, cap(label_it(cn)) + " had been moved and turned.", 3, [cn])
			anomaly_hide_it("chair_gone", cn, cap(label_it(cn)) + " was missing.", 2, "object", [cn])
			anomaly_flip("chair_flipped", cn, 1.0, cap(label_it(cn)) + " was upside down.", 2, [cn])
	anomaly_hide_it("ext_gone", "ext", "The fire extinguisher was missing — only its sign remained.", 2)
	anomaly_scoot("ext_moved", "ext", Vector3(0, 0, 0.7), 0.0, "The fire extinguisher hung in a different place on the wall.", 3)
	anomaly_show_it("suitcase", "suitcase", "An abandoned suitcase stood by the door of room 704.", 1)
	anomaly_show_it("table_extra", "table_extra", "An extra side table with a vase stood near room 713.", 2)
	anomaly_show_it("stain", "stain_a", "A dark stain had appeared on the carpet near room 705.", 2)
	anomaly_show_it("stain", "stain_b", "A dark stain had appeared on the carpet near room 711.", 2)
	anomaly_hide_it("plant_gone", "plant_lobby", "The tall plant in the lobby corner had disappeared.", 2)
	anomaly_scoot("chair_moved", "chair_lobby_0", Vector3(-0.5, 0, -0.4), -50.0, "An armchair in the lobby had been moved and turned.", 3)
	anomaly_change_text("elevator_floor", "elev_L", "13", "The left elevator indicator showed floor 13 instead of 7.", 3)
	anomaly_change_text("elevator_floor", "elev_R", "B", "The right elevator indicator showed B instead of 7.", 3)
	anomaly_hide_it("bell_gone", "bell", "The bell on the reception desk was missing.", 3)
	add("clock_time", "clock_lobby", "The lobby clock showed 3:33 instead of 10:10.", "object", 3, _yeet_clock.bind("clock_lobby", 3.0, 33.0))
	for kk in [2, 5, 9]:
		anomaly_hide_it("key_gone", "key_%d" % kk, "One of the room keys behind the reception desk was missing.", 3, "object", ["keys"])

	add("longer", "corridor", "The corridor was longer — an extra section with rooms 715 and 716 appeared.", "structure", 2, _prep_lol_longer, ["length"], true)
	add("ceiling_low", "ceiling", "The corridor ceiling was noticeably lower.", "structure", 2, _prep_lol_ceiling, ["ceiling"], true)
	for i in range(1, n - 1):
		for side: int in [-1, 1]:
			var wn = "walls_%s%d" % [side_name_lol(side), i]
			anomaly_swap_mat("wallpaper", wn, "wall_alt", "The wallpaper on %s had a different colour." % label_it(wn), 2, "structure")

	anomaly_spooky("figure", "fig_end", "A dark figure stood at the far end of the corridor, watching you.", 1, ["figure"])
	anomaly_spooky("figure", "fig_lobby", "A dark figure stood in the corner of the lobby by the elevators.", 1, ["figure"])
	anomaly_levitate("floating", "deco_0", "The vase near room 702 was floating in the air.", 1)
	anomaly_levitate("floating", "chair_3", "The armchair near room 707 was floating in the air.", 1)
	add("shadow", "shadow_a", "A shadow moved along the wall near room 708 with no one to cast it.", "supernatural", 2, _yeet_shadow.bind("shadow_a"))
	add("shadow", "shadow_b", "A shadow moved along the wall near room 712 with no one to cast it.", "supernatural", 2, _yeet_shadow.bind("shadow_b"))

	anomaly_noise("footsteps", "snd_steps", "far_steps", 6.5, 2.0, "Footsteps could be heard inside room 710.", 2)
	anomaly_noise("knocking", "snd_knock", "knock", 5.0, 2.0, "Someone was knocking from inside room 705.", 2)
	anomaly_noise("whisper", "snd_whisper", "whisper", 5.5, 4.0, "Whispering came from behind the door of room 712.", 2)
	anomaly_noise("bell_ring", "bell", "bell", 7.0, -4.0, "The reception bell kept ringing by itself.", 2, ["bell"])

	# ---- жуть ----
	anomaly_show_it("blood_writing", "blood_get_out", "Red letters \"GET OUT\" were smeared on the wall near room %d." % room(-1, 3), 1, "supernatural")
	anomaly_show_it("blood_writing", "blood_look_back", "Red letters \"DON'T LOOK BACK\" were smeared on the wall near room %d." % room(1, 5), 1, "supernatural")
	anomaly_eyes("red_eyes", "eyes_exit", "Two red eyes watched you from the corner above the exit door.", 2)
	anomaly_stalker("stalker", "fig_stalker", "A dark figure crept closer every time you looked away.", 1, ["figure"])
	add("blood_door", "blood_door", "Bloody handprints were smeared on the wall next to the door of room %d." % room(-1, 4), "supernatural", 1, _yeet_show_many.bind(["blood_door", "blood_door_hands"]), ["door_L4"])
	anomaly_warp("warp", "warp_a", 4.0, "The air in %s was warping — the walls seemed to breathe." % which_zone_is_this(2), 2)
	anomaly_warp("warp", "warp_b", 4.0, "The air at %s was warping — the walls seemed to breathe." % which_zone_is_this(5), 2)
	for ln in ["lamp_L3", "lamp_R5"]:
		anomaly_heartbeat_light("lamp_heartbeat", ln, cap(label_it(ln)) + " pulsed red like a heartbeat.", 1, [ln])
	add("door_creak", "door_R6", "The door of room %d kept slowly opening and closing by itself." % room(1, 6), "supernatural", 2, _yeet_creak.bind("door_R6"), ["door_R6"])
	anomaly_noise("heartbeat", "snd_heart", "heartbeat", 1.25, 4.0, "A heartbeat could be heard through the wall of room %d." % room(1, 3), 2)
	anomaly_noise("scratching", "snd_scratch", "scratch", 4.5, 3.0, "Something was scratching at the door of room %d from the inside." % room(-1, 1), 2)
	anomaly_noise("breathing", "snd_breath", "breath", 5.0, 2.0, "Heavy breathing came from the empty lobby.", 2)
	return lib


func _spawn_creepy_stuff():
	creepy_writing("blood_get_out", "GET OUT", Vector3(-HW + 0.015, 1.75, zone_center_lol(3) + 1.5), 90.0, which_zone_is_this(3), 80, 0.005)
	creepy_writing("blood_look_back", "DON'T\nLOOK BACK", Vector3(HW - 0.015, 1.8, zone_center_lol(5) + 1.5), -90.0, which_zone_is_this(5), 64, 0.005)
	var ex = _anchor_pos(exit_zone)
	creepy_eyes("eyes_exit", Vector3(1.4, 2.45, ex.z + 0.35), 0.0, which_zone_is_this(6))
	creepy_figure("fig_stalker", Vector3(0.7, 0, zone_center_lol(5) - 1.0), 0.0, which_zone_is_this(5))
	creepy_puddle("blood_door", Vector3(-HW + 0.42, 0.035, zone_center_lol(4)), Vector2(0.75, 1.0), which_zone_is_this(4))
	creepy_handprints("blood_door_hands", Vector3(-HW + 0.012, 1.45, zone_center_lol(4) + 1.9), 90.0, which_zone_is_this(4))
	creepy_spot("warp_a", Vector3(0, 1.6, zone_center_lol(2)), which_zone_is_this(2))
	creepy_spot("warp_b", Vector3(0, 1.6, zone_center_lol(5)), which_zone_is_this(5))
	creepy_spot("snd_heart", Vector3(HW + 0.8, 1.2, zone_center_lol(3)), which_zone_is_this(3))
	creepy_spot("snd_scratch", Vector3(-HW - 0.25, 0.9, zone_center_lol(1)), which_zone_is_this(1))
	creepy_spot("snd_breath", Vector3(2.5, 1.5, 6.0), "the lobby")


func _yeet_lights_off(names: Array) -> bool:
	var ok = false
	for nm in names:
		ok = _yeet_light_off(nm) or ok
	return ok


func _yeet_hide_many(names: Array) -> bool:
	var ok = false
	for nm in names:
		ok = _yeet_hide(nm) or ok
	return ok


func _yeet_door_open(dn: String) -> bool:
	var d = _find_node_lol(dn)
	if d == null or not d.visible:
		return false
	d.get_node("Hinge").rotation.y = deg_to_rad(52.0)
	return true


func _yeet_door_gone(dn: String) -> bool:
	var d = _find_node_lol(dn)
	var p = _find_node_lol(dn + "_patch")
	if d == null or p == null:
		return false
	set_here_or_not(d, false)
	set_here_or_not(p, true)
	return true


func _yeet_clock(nm: String, h: float, m: float) -> bool:
	var c = _find_node_lol(nm)
	if c == null:
		return false
	set_the_time(c, h, m)
	return true


func _yeet_shadow(nm: String) -> bool:
	var s = _find_node_lol(nm)
	if s == null:
		return false
	s.visible = true
	var b = Behaviour.new()
	b.mode = "slide"
	b.victim = s
	b.a = s.get_meta("a")
	b.b = s.get_meta("b")
	b.speed = 0.45
	s.add_child(b)
	return true


func _prep_lol_longer() -> bool:
	params["sections"] = 8
	return true


func _prep_lol_ceiling() -> bool:
	params["ceiling"] = 2.62
	return true
