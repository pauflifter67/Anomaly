extends "res://скрипты/карты/база_карты.gd"

const SEC = 6.0
const N = 7
const HX = 9.0
const PW = 4.0
const TX = 5.7
const RH = 7.0
const TY = -1.2
const COOL = Color(0.80, 0.90, 1.0)
const WARM = Color(1.0, 0.78, 0.5)
const BOARD = [
	["23:05", "HARBOUR CITY", "1", "ON TIME"],
	["23:18", "NORTHGATE", "2", "DELAYED"],
	["23:32", "ASHFORD VALE", "1", "ON TIME"],
	["23:47", "SALT MARSH", "2", "ON TIME"],
	["00:10", "GREYWATER", "1", "BOARDING"],
]
const ADVERTS = {"advert_L1": "travel", "advert_L3": "timetable", "advert_L5": "notice", "advert_R0": "timetable", "advert_R5": "travel", "advert_R6": "notice"}


func background_noise() -> String:
	return "amb_station"


func footstep_pitch() -> float:
	return 1.15


func arrival_noise() -> String:
	return "pa_chime"


func preview_pic() -> Array:
	return [Vector3(-2.2, 1.7, -2.0), Vector3(1.5, 1.0, -24.0)]


func menu_pic() -> Array:
	return [Vector3(0, 1.7, 6.0), Vector3(0, 1.7, -8.0)]


func qa_pics() -> Array:
	return [
		[Vector3(0, 1.6, 8.5), Vector3(0, 2.5, 0)],
		[Vector3(0, 1.6, 8.5), Vector3(-8, 1.2, 4)],
		[Vector3(0, 1.6, -3), Vector3(0, 1.4, -25)],
		[Vector3(-2.5, 1.6, -15), Vector3(7, 1.0, -20)],
		[Vector3(0, 1.6, -36), Vector3(0, 1.5, -42)],
		[Vector3(0, 1.6, -30), Vector3(0, 2.0, 5)],
	]


func focus_pic(a) -> Array:
	var t: String = a.id.split(":")[1]
	var n = obj.get(t)
	if n is Node3D and (n as Node3D).is_inside_tree():
		var p: Vector3 = (n as Node3D).global_position
		if p.z > 0.0:
			return [Vector3(0, 1.7, 9.0), p + Vector3(0, 0.5, 0)]
		return [Vector3(clampf(p.x, -2.5, 2.5) * 0.3, 1.7, p.z + 5.0), p + Vector3(0, 0.5, 0)]
	return preview_pic()


static func zone_center_lol(i: int) -> float:
	return -(i + 0.5) * SEC


static func which_zone_is_this(i: int) -> String:
	if i <= 1:
		return "the near end of the platform"
	if i <= 4:
		return "the middle of the platform"
	return "the far end of the platform"


func _cook_the_map():
	_material_pile()
	make_the_env({
		"ambient": Color(0.5, 0.56, 0.66), "ambient_energy": 0.85,
		"fog_color": Color(0.06, 0.08, 0.11), "fog_density": 0.012,
		"exposure": 1.25, "saturation": 0.85, "contrast": 1.12, "vol": 0.02,
	})
	_big_hall()
	_big_concourse()
	for i in N:
		_chunk(i)
	_rail_bits()
	_the_end()
	_secret_stuff()
	spawn_spot = Transform3D(Basis(), Vector3(0, 0.05, 8.0))
	sprinkle_dust(Vector3(0, 3.0, -N * SEC * 0.5), Vector3(HX - 1.0, 2.5, N * SEC * 0.5), 300, Color(0.85, 0.9, 1.0, 0.3))
	sprinkle_dust(Vector3(0, 2.0, 5.0), Vector3(7.0, 1.8, 4.5), 120, Color(1.0, 0.92, 0.8, 0.3))


func _material_pile():
	M["tiles"] = mat(Color.WHITE, 0.55, 0.0, "tiles_station", 0.5, 0.3)
	M["brick"] = mat(Color(0.95, 0.9, 0.88), 0.9, 0.0, "brick", 0.45, 0.6)
	M["concrete"] = mat(Color.WHITE, 0.9, 0.0, "concrete", 0.35, 0.4)
	M["gravel"] = mat(Color.WHITE, 1.0, 0.0, "gravel", 0.8, 0.8)
	M["rail"] = mat(Color(0.5, 0.5, 0.52), 0.3, 0.5)
	M["sleeper"] = mat(Color(0.2, 0.14, 0.09), 0.9)
	M["iron"] = mat(Color(0.15, 0.28, 0.23), 0.5, 0.3)
	M["iron_red"] = mat(Color(0.45, 0.09, 0.07), 0.5, 0.3)
	M["dark_iron"] = mat(Color(0.08, 0.09, 0.09), 0.6, 0.3)
	M["roof"] = mat(Color(0.10, 0.11, 0.12), 0.8, 0.2)
	M["sky"] = glow(Color(0.10, 0.14, 0.26), 0.5)
	M["edge"] = mat(Color(0.85, 0.68, 0.08), 0.6)
	M["edge_red"] = mat(Color(0.75, 0.07, 0.05), 0.6)
	M["bench"] = mat(Color.WHITE, 0.6, 0.0, "wood_light", 1.2)
	M["board"] = mat(Color(0.02, 0.02, 0.025), 0.4)
	M["steel"] = mat(Color(0.5, 0.52, 0.55), 0.35, 0.4, "metal", 2.0)
	M["paint"] = mat(Color(0.34, 0.06, 0.07), 0.45, 0.2)
	M["cream"] = mat(Color(0.85, 0.80, 0.66), 0.5)
	M["window"] = mat(Color(0.03, 0.04, 0.05), 0.1, 0.3)
	M["window_lit"] = glow(Color(1.0, 0.78, 0.45), 1.6)
	M["black"] = mat(Color(0.015, 0.015, 0.015), 0.9)
	M["enamel"] = mat(Color(0.07, 0.12, 0.32), 0.3)
	M["shade"] = mat(Color(0.14, 0.22, 0.18), 0.4, 0.3)
	M["lamp_off"] = mat(Color(0.25, 0.27, 0.28), 0.5)
	M["leather"] = mat(Color(0.32, 0.17, 0.08), 0.55)
	M["fabric"] = mat(Color(0.18, 0.22, 0.35), 0.9, 0.0, "fabric", 3.0)
	M["yellow"] = mat(Color(0.95, 0.75, 0.05), 0.5)
	M["red"] = mat(Color(0.65, 0.06, 0.05), 0.4)
	M["white"] = mat(Color(0.88, 0.88, 0.86), 0.5)
	M["figure"] = mat(Color(0.006, 0.006, 0.008), 0.95)


func _big_hall():
	var L = N * SEC
	var h = node(self, "Hall")
	for sx: int in [-1, 1]:
		box(h, Vector3(0.4, RH - TY, L + 10.4), Vector3(sx * (HX + 0.2), (RH + TY) * 0.5, 5.0 - L * 0.5), M["brick"], true)
	box(h, Vector3(HX * 2, RH - TY, 0.4), Vector3(0, (RH + TY) * 0.5, 10.2), M["brick"], true)
	box(h, Vector3(HX * 2 + 0.8, 0.3, L + 10.8), Vector3(0, RH + 0.15, 5.0 - L * 0.5), M["roof"])
	box(h, Vector3(3.6, 0.05, L + 8.0), Vector3(0, RH - 0.02, 5.0 - L * 0.5), M["sky"])
	for k in range(-1, N + 1):
		var z = -k * SEC
		box(h, Vector3(HX * 2, 0.32, 0.26), Vector3(0, RH - 0.5, z), M["dark_iron"])
		for sx: int in [-1, 1]:
			var br = box(h, Vector3(5.6, 0.14, 0.14), Vector3(sx * 5.6, RH - 1.25, z), M["dark_iron"])
			br.rotation.z = sx * deg_to_rad(16.0)
		if k >= 0 and k < N:
			for sx: int in [-1, 1]:
				var wz = z - SEC * 0.5
				quad(h, Vector2(2.2, 3.0), Vector3(sx * (HX - 0.01), 4.6, wz), M["sky"], -90.0 * sx)
				box(h, Vector3(0.06, 3.2, 0.1), Vector3(sx * (HX - 0.03), 4.6, wz), M["dark_iron"])
				box(h, Vector3(0.06, 0.1, 2.4), Vector3(sx * (HX - 0.03), 4.6, wz), M["dark_iron"])


func _big_concourse():
	var c = node(self, "Concourse")
	box(c, Vector3(HX * 2, 0.2, 10), Vector3(0, -0.1, 5), M["tiles"], true)
	for sx: int in [-1, 1]:
		var cx = sx * (PW + (HX - PW) * 0.5)
		box(c, Vector3(HX - PW, 1.3, 0.3), Vector3(cx, -0.65, 0.15), M["concrete"])
		box(c, Vector3(HX - PW, 0.06, 0.06), Vector3(cx, 1.0, 0.1), M["dark_iron"])
		box(c, Vector3(HX - PW, 0.04, 0.04), Vector3(cx, 0.55, 0.1), M["dark_iron"])
		for k in 6:
			box(c, Vector3(0.05, 1.0, 0.05), Vector3(sx * (PW + 0.2 + k * 0.95), 0.5, 0.1), M["dark_iron"])
		invisible_wall(c, Vector3(HX - PW, 3.0, 0.2), Vector3(cx, 1.5, 0.1))
	var board = node(c, "Board", Vector3(0, 4.3, 0.4))
	box(board, Vector3(6.6, 2.3, 0.25), Vector3.ZERO, M["board"])
	box(board, Vector3(6.8, 2.5, 0.2), Vector3(0, 0, -0.04), M["steel"])
	box(board, Vector3(0.1, 2.4, 0.1), Vector3(-2.8, 2.3, -0.05), M["dark_iron"])
	box(board, Vector3(0.1, 2.4, 0.1), Vector3(2.8, 2.3, -0.05), M["dark_iron"])
	var amber = Color(1.7, 1.05, 0.3)
	var hdr = text_in_3d_lol(board, "DEPARTURES", Vector3(-3.0, 0.9, 0.13), 0.004, Color(1.4, 1.4, 1.4), 64, 0.0, false, "cond")
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for r in BOARD.size():
		var y = 0.42 - r * 0.33
		var one_row: Array = BOARD[r]
		var col_pile = [[-3.0, "t"], [-1.9, "d"], [1.55, "p"], [2.05, "s"]]
		for ci in 4:
			var lb = text_in_3d_lol(board, one_row[ci], Vector3(col_pile[ci][0], y, 0.13), 0.0034, amber, 64, 0.0, false, "cond")
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			sign_up_anomaly("board_%s%d" % [col_pile[ci][1], r], lb, "the departure board", "the concourse")
	sign_up_anomaly("clock_main", clock(c, "MainClock", Vector3(0, 6.1, 0.42), 0.0, 0.5, M["dark_iron"], 11.0, 52.0), "the big clock above the departure board", "the concourse")
	var tk = node(c, "Tickets", Vector3(0, 0, 9.98), 180.0)
	var tglows: Array = []
	for k in 3:
		var x = -4.0 + k * 4.0
		box(tk, Vector3(2.2, 2.6, 0.1), Vector3(x, 1.6, 0.05), M["dark_iron"])
		tglows.append(box(tk, Vector3(1.9, 1.2, 0.04), Vector3(x, 1.9, 0.11), glow(Color(1.0, 0.82, 0.55), 0.55)))
		box(tk, Vector3(2.0, 0.08, 0.35), Vector3(x, 1.2, 0.2), M["bench"])
	box(tk, Vector3(3.2, 0.5, 0.08), Vector3(0, 3.4, 0.1), M["enamel"])
	text_in_3d_lol(tk, "TICKETS", Vector3(0, 3.4, 0.15), 0.004, Color(0.95, 0.95, 0.95), 64, 0.0, true, "wide")
	var tl = omni_light_lol(tk, Vector3(0, 1.9, 0.8), Color(1.0, 0.82, 0.55), 0.8, 5.0)
	_tag_the_lamp(tk, [tl], tglows, M["lamp_off"])
	sign_up_anomaly("tickets", tk, "the ticket office windows", "the concourse")
	var vm = node(c, "Vending", Vector3(-8.5, 0, 6.0), 90.0)
	box(vm, Vector3(0.9, 1.9, 0.75), Vector3(0, 0.95, 0), M["red"], true)
	var vglow = box(vm, Vector3(0.6, 1.1, 0.02), Vector3(-0.08, 1.2, 0.38), glow(Color(0.75, 0.9, 1.0), 1.4))
	box(vm, Vector3(0.14, 0.5, 0.02), Vector3(0.33, 1.1, 0.38), M["dark_iron"])
	var vl = omni_light_lol(vm, Vector3(0, 1.2, 0.8), Color(0.7, 0.85, 1.0), 0.6, 3.5)
	_tag_the_lamp(vm, [vl], [vglow], M["lamp_off"])
	sign_up_anomaly("vending", vm, "the vending machine", "the concourse")
	sign_up_anomaly("bench_c0", sit_here(c, "BenchC0", Vector3(-3.2, 0, 5.2), 180.0), "the left bench in the waiting area", "the concourse")
	sign_up_anomaly("bench_c1", sit_here(c, "BenchC1", Vector3(3.2, 0, 5.2), 180.0), "the right bench in the waiting area", "the concourse")
	sign_up_anomaly("luggage_c", luggage(c, "LuggageC", Vector3(4.55, 0, 5.4), 20.0), "the suitcase by the right bench", "the concourse")
	sign_up_anomaly("bin_c", trash_can(c, "BinC", Vector3(-5.0, 0, 4.4)), "the bin in the waiting area", "the concourse")
	for sx: int in [-1, 1]:
		var nn = "name_" + ("L" if sx < 0 else "R")
		var ns = node(c, nn, Vector3(sx * (HX - 0.03), 4.2, 5.0), -90.0 * sx)
		box(ns, Vector3(5.0, 0.9, 0.05), Vector3.ZERO, M["enamel"])
		box(ns, Vector3(5.1, 1.0, 0.03), Vector3(0, 0, -0.02), M["white"])
		text_in_3d_lol(ns, "HOLLOWMERE", Vector3(0, 0, 0.03), 0.006, Color(0.95, 0.95, 0.95), 96, 0.0, true, "wide")
		sign_up_anomaly(nn, ns, "the HOLLOWMERE station sign on the %s wall" % ("left" if sx < 0 else "right"), "the concourse")
	sign_up_anomaly("poster_c", poster(c, "PosterC", Vector3(-HX + 0.02, 1.8, 1.8), 90.0, "travel", 1.0, 1.4), "the travel poster in the waiting area", "the concourse")
	poster(c, "PosterC2", Vector3(HX - 0.02, 1.8, 1.8), -90.0, "timetable", 1.0, 1.4)
	var li = 0
	for sx: int in [-1, 1]:
		for zz: float in [2.5, 7.5]:
			var nm = "lamp_c%d" % li
			sign_up_anomaly(nm, dangly_lamp(c, nm, Vector3(sx * 4.5, 4.6, zz), WARM, 1.8, 9.0, 10 + li), "a hanging lamp in the waiting area", "the concourse")
			li += 1


func _chunk(i: int):
	var z0 = -i * SEC
	var c = zone_center_lol(i)
	var zone = which_zone_is_this(i)
	var s = node(self, "Sec%d" % i)
	box(s, Vector3(PW * 2, 0.2, SEC), Vector3(0, -0.1, c), M["tiles"], true)
	box(s, Vector3(PW * 2, 1.1, SEC), Vector3(0, -0.75, c), M["concrete"])
	for sx: int in [-1, 1]:
		box(s, Vector3(0.35, 0.03, SEC), Vector3(sx * (PW - 0.2), 0.0, c), M["concrete"])
		invisible_wall(s, Vector3(0.1, 3.0, SEC), Vector3(sx * (PW + 0.05), 1.5, c))
	var p = node(s, "pillar_%d" % i, Vector3(0, 0, c))
	var col = cylinder_lol(p, 0.17, 0.17, RH - 0.5, Vector3(0, (RH - 0.5) * 0.5, 0), M["iron"], true)
	col.set_meta("swap", true)
	var base = box(p, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), M["iron"])
	base.set_meta("swap", true)
	var capital = box(p, Vector3(0.6, 0.25, 0.6), Vector3(0, RH - 0.62, 0), M["iron"])
	capital.set_meta("swap", true)
	sign_up_anomaly("pillar_%d" % i, p, "the iron pillar in %s" % zone, zone)
	sign_up_anomaly("bench_%da" % i, sit_here(s, "Bench%da" % i, Vector3(-0.75, 0, c + 1.7), -90.0), "the bench facing the left track in %s" % zone, zone)
	sign_up_anomaly("bench_%db" % i, sit_here(s, "Bench%db" % i, Vector3(0.75, 0, c + 1.7), 90.0), "the bench facing the right track in %s" % zone, zone)
	var ln = "lamp_%d" % i
	sign_up_anomaly(ln, dangly_lamp(s, ln, Vector3(0, 4.6, c - 2.2), COOL, 2.4, 11.0, i), "the hanging lamp above %s" % zone, zone)
	if i % 2 == 0:
		sign_up_anomaly("bin_%d" % i, trash_can(s, "Bin%d" % i, Vector3(0, 0, c - 0.75)), "the bin by the pillar in %s" % zone, zone)
	if i in [1, 3, 5]:
		sign_up_anomaly("sign_%d" % i, platform_sign_lol(s, "Sign%d" % i, Vector3(0, 3.7, c + 0.9)), "the platform sign in %s" % zone, zone)
	if i in [2, 4]:
		var ch = node(s, "ClockMount%d" % i, Vector3(0, 0, c + 0.9))
		box(ch, Vector3(0.04, RH - 4.0, 0.04), Vector3(0, (RH + 4.0) * 0.5, 0), M["dark_iron"])
		sign_up_anomaly("clock_%d" % i, clock(s, "clock_%d" % i, Vector3(0, 3.9, c + 0.9), 0.0, 0.35, M["dark_iron"], 11.0, 52.0, true), "the hanging clock in %s" % zone, zone)
	for side in ["L", "R"]:
		var an = "advert_%s%d" % [side, i]
		if ADVERTS.has(an):
			var sx = -1 if side == "L" else 1
			sign_up_anomaly(an, poster(s, an, Vector3(sx * (HX - 0.02), 1.9, c), -90.0 * sx, ADVERTS[an], 3.2, 2.2), "the large poster on the %s wall across the tracks" % ("left" if sx < 0 else "right"), zone)
	for sx: int in [-1, 1]:
		var wn = "wlamp_%s%d" % ["L" if sx < 0 else "R", i]
		sign_up_anomaly(wn, wall_light(s, wn, Vector3(sx * HX, 3.6, c - 1.8), -90.0 * sx, 30 + i), "the wall lamp above the %s track in %s" % ["left" if sx < 0 else "right", zone], zone)
	if i == 3:
		sign_up_anomaly("snd_pa", node(s, "Speaker", Vector3(0.2, 3.2, c)), "", zone)
	if i == 1:
		sign_up_anomaly("luggage_1", luggage(s, "Luggage1", Vector3(-0.65, 0.48, c + 2.3), 90.0), "the suitcase on the bench in %s" % zone, zone)
	if i == 4:
		sign_up_anomaly("luggage_4", sack(s, "Luggage4", Vector3(1.6, 0, c + 1.7)), "the travel bag on the platform in %s" % zone, zone)


func _rail_bits():
	var L = N * SEC
	var t = node(self, "Tracks")
	for sx: int in [-1, 1]:
		var cx = sx * (PW + (HX - PW) * 0.5)
		box(t, Vector3(HX - PW, 0.2, L), Vector3(cx, TY - 0.1, -L * 0.5), M["gravel"], true)
		for r: int in [-1, 1]:
			box(t, Vector3(0.08, 0.16, L), Vector3(sx * TX + r * 0.72, TY + 0.14, -L * 0.5), M["rail"])
		var pos: Array = []
		var z = -0.4
		while z > -L:
			pos.append(Vector3(sx * TX, TY + 0.03, z))
			z -= 0.7
		many_boxes(t, Vector3(2.5, 0.1, 0.24), pos, M["sleeper"])
		box(t, Vector3(2.0, 0.9, 0.4), Vector3(sx * TX, TY + 0.6, -0.6), M["red"])
		box(t, Vector3(2.02, 0.15, 0.42), Vector3(sx * TX, TY + 0.9, -0.6), M["white"])
	sign_up_anomaly("train_right", train_car(self, "TrainRight", Vector3(TX + 0.1, TY, -21.0), -1), "the carriage on the right track", which_zone_is_this(3))
	sign_up_anomaly("snd_train", node(self, "SndTrain", Vector3(-TX, 0.5, -L + 2.0)), "", which_zone_is_this(6))


func _the_end():
	var L = N * SEC
	var e = node(self, "End", Vector3(0, 0, -L))
	box(e, Vector3(HX * 2, RH - TY, 0.4), Vector3(0, (RH + TY) * 0.5, -0.2), M["brick"], true)
	for sx: int in [-1, 1]:
		box(e, Vector3(4.2, 4.6, 0.1), Vector3(sx * TX, TY + 2.3, 0.02), M["black"])
		box(e, Vector3(4.6, 0.4, 0.3), Vector3(sx * TX, TY + 4.8, 0.1), M["concrete"])
	box(e, Vector3(2.4, 2.6, 0.1), Vector3(0, 1.3, 0.05), M["dark_iron"])
	for sx: int in [-1, 1]:
		box(e, Vector3(1.05, 2.4, 0.06), Vector3(sx * 0.54, 1.2, 0.12), M["steel"], true)
		box(e, Vector3(0.6, 0.05, 0.05), Vector3(sx * 0.54, 1.05, 0.17), M["dark_iron"])
	var sign = node(e, "ExitSign", Vector3(0, 3.0, 0.12))
	box(sign, Vector3(1.6, 0.42, 0.08), Vector3.ZERO, M["black"])
	var face = box(sign, Vector3(1.5, 0.34, 0.01), Vector3(0, 0, 0.045), glow(Color(0.95, 0.75, 0.05), 0.7))
	text_in_3d_lol(sign, "WAY OUT", Vector3(0, 0, 0.052), 0.004, Color(0.05, 0.05, 0.05), 64, 0.0, false, "wide")
	var gl = omni_light_lol(sign, Vector3(0, -0.3, 0.4), Color(1.0, 0.8, 0.3), 0.6, 4.0)
	_tag_the_lamp(sign, [gl], [face], M["lamp_off"])
	sign_up_anomaly("exit_sign", sign, "the WAY OUT sign", which_zone_is_this(N - 1))
	make_the_exit_door(Vector3(0, 1.2, -L + 0.4), Vector3(2.2, 2.4, 0.5))


func _secret_stuff():
	var L = N * SEC
	var tl = train_car(self, "TrainLeft", Vector3(-TX - 0.1, TY, -18.0), 1)
	set_here_or_not(tl, false)
	sign_up_anomaly("train_left", tl, "a train", which_zone_is_this(3))
	var fp = spooky_guy(self, "fig_platform", Vector3(2.9, 0, zone_center_lol(5)), M["figure"], 90.0)
	set_here_or_not(fp, false)
	sign_up_anomaly("fig_platform", fp, "a passenger", which_zone_is_this(5))
	var ff = spooky_guy(self, "fig_far", Vector3(-TX, TY, -L + 3.0), M["figure"])
	set_here_or_not(ff, false)
	sign_up_anomaly("fig_far", ff, "a figure on the tracks", which_zone_is_this(6))
	var lx = luggage(self, "LuggageX", Vector3(-2.2, 0, zone_center_lol(3) + 0.4), -30.0)
	set_here_or_not(lx, false)
	sign_up_anomaly("luggage_x", lx, "a suitcase", which_zone_is_this(3))
	var ws = node(self, "WetSign", Vector3(-1.8, 0, zone_center_lol(2) - 1.6), 30.0)
	var p1 = box(ws, Vector3(0.4, 0.62, 0.02), Vector3(0, 0.3, 0.1), M["yellow"])
	p1.rotation.x = deg_to_rad(-12.0)
	var p2 = box(ws, Vector3(0.4, 0.62, 0.02), Vector3(0, 0.3, -0.1), M["yellow"])
	p2.rotation.x = deg_to_rad(12.0)
	text_in_3d_lol(ws, "CAUTION\nWET FLOOR", Vector3(0, 0.35, 0.18), 0.0018, Color(0.05, 0.05, 0.05), 48, 0.0, true, "bold")
	set_here_or_not(ws, false)
	sign_up_anomaly("wet_sign", ws, "a wet floor sign", which_zone_is_this(2))
	for sx: int in [-1, 1]:
		var en = "edge_" + ("L" if sx < 0 else "R")
		var ed = box(self, Vector3(0.22, 0.012, L), Vector3(sx * (PW - 0.55), 0.006, -L * 0.5), M["edge"])
		sign_up_anomaly(en, ed, "the yellow safety line along the %s edge of the platform" % ("left" if sx < 0 else "right"), "the platform")


func sit_here(parent: Node, nm: String, pos: Vector3, rot: float) -> Node3D:
	var b = node(parent, nm, pos, rot)
	box(b, Vector3(1.8, 0.06, 0.42), Vector3(0, 0.45, 0.02), M["bench"])
	var back = box(b, Vector3(1.8, 0.42, 0.05), Vector3(0, 0.75, -0.2), M["bench"])
	back.rotation.x = deg_to_rad(-8.0)
	for lx: float in [-0.78, 0.78]:
		box(b, Vector3(0.06, 0.45, 0.42), Vector3(lx, 0.225, 0.0), M["dark_iron"])
		box(b, Vector3(0.05, 0.05, 0.4), Vector3(lx, 0.62, 0.02), M["dark_iron"])
	invisible_wall(b, Vector3(1.8, 0.9, 0.5), Vector3(0, 0.45, 0))
	return b


func dangly_lamp(parent: Node, nm: String, pos: Vector3, col: Color, energy: float, rng_m: float, prio: int) -> Node3D:
	var l = node(parent, nm, pos)
	var cable = RH - pos.y
	box(l, Vector3(0.025, cable, 0.025), Vector3(0, cable * 0.5, 0), M["dark_iron"])
	cylinder_lol(l, 0.08, 0.42, 0.3, Vector3(0, 0.12, 0), M["shade"])
	var g = cylinder_lol(l, 0.36, 0.36, 0.02, Vector3(0, -0.04, 0), glow(col, 1.1))
	var lt = omni_light_lol(l, Vector3(0, -0.45, 0), col, energy, rng_m, prio)
	_tag_the_lamp(l, [lt], [g], M["lamp_off"])
	return l


func wall_light(parent: Node, nm: String, pos: Vector3, rot: float, prio: int) -> Node3D:
	var l = node(parent, nm, pos, rot)
	box(l, Vector3(0.18, 0.3, 0.05), Vector3(0, 0, 0.025), M["dark_iron"])
	box(l, Vector3(0.04, 0.04, 0.5), Vector3(0, 0.1, 0.27), M["dark_iron"])
	cylinder_lol(l, 0.05, 0.22, 0.18, Vector3(0, 0.05, 0.55), M["shade"])
	var g = cylinder_lol(l, 0.19, 0.19, 0.02, Vector3(0, -0.04, 0.55), glow(WARM, 1.2))
	var lt = omni_light_lol(l, Vector3(0, -0.4, 0.7), WARM, 1.6, 9.0, prio)
	_tag_the_lamp(l, [lt], [g], M["lamp_off"])
	return l


func trash_can(parent: Node, nm: String, pos: Vector3) -> Node3D:
	var b = node(parent, nm, pos)
	cylinder_lol(b, 0.24, 0.22, 0.8, Vector3(0, 0.4, 0), M["iron"], true)
	cylinder_lol(b, 0.26, 0.26, 0.05, Vector3(0, 0.82, 0), M["dark_iron"])
	return b


func luggage(parent: Node, nm: String, pos: Vector3, rot: float) -> Node3D:
	var sc = node(parent, nm, pos, rot)
	box(sc, Vector3(0.5, 0.66, 0.22), Vector3(0, 0.36, 0), M["leather"], true)
	box(sc, Vector3(0.2, 0.04, 0.04), Vector3(0, 0.71, 0), M["black"])
	box(sc, Vector3(0.52, 0.03, 0.24), Vector3(0, 0.5, 0), M["steel"])
	return sc


func sack(parent: Node, nm: String, pos: Vector3) -> Node3D:
	var b = node(parent, nm, pos, 25.0)
	var body = pill_lol(b, 0.17, 0.62, Vector3(0, 0.17, 0), M["fabric"])
	body.rotation.z = PI / 2.0
	box(b, Vector3(0.3, 0.02, 0.04), Vector3(0, 0.38, 0), M["black"])
	return b


func poster(parent: Node, nm: String, pos: Vector3, rot: float, art: String, w: float, h: float) -> Node3D:
	var p = node(parent, nm, pos, rot)
	box(p, Vector3(w + 0.1, h + 0.1, 0.04), Vector3(0, 0, 0.02), M["dark_iron"])
	var canvas = quad(p, Vector2(w, h), Vector3(0, 0, 0.042), texture_mat_xd("art_" + art, Vector3.ONE, 0.7))
	p.set_meta("canvas", canvas)
	p.set_meta("art", art)
	return p


func platform_sign_lol(parent: Node, nm: String, pos: Vector3) -> Node3D:
	var s = node(parent, nm, pos)
	box(s, Vector3(0.03, RH - pos.y, 0.03), Vector3(-1.1, (RH - pos.y) * 0.5, 0), M["dark_iron"])
	box(s, Vector3(0.03, RH - pos.y, 0.03), Vector3(1.1, (RH - pos.y) * 0.5, 0), M["dark_iron"])
	box(s, Vector3(2.6, 0.5, 0.06), Vector3.ZERO, M["enamel"])
	var f = text_in_3d_lol(s, "←  1          2  →", Vector3(0, 0, 0.035), 0.004, Color(0.95, 0.95, 0.95), 64, 0.0, true, "wide")
	var b = text_in_3d_lol(s, "←  2          1  →", Vector3(0, 0, -0.035), 0.004, Color(0.95, 0.95, 0.95), 64, 180.0, true, "wide")
	s.set_meta("front", f)
	s.set_meta("back", b)
	return s


func train_car(parent: Node, nm: String, pos: Vector3, door_side: int) -> Node3D:
	var c = node(parent, nm, pos)
	box(c, Vector3(2.9, 3.5, 20), Vector3(0, 2.45, 0), M["paint"], true)
	box(c, Vector3(2.92, 0.22, 20.02), Vector3(0, 1.8, 0), M["cream"])
	box(c, Vector3(2.6, 0.3, 19.6), Vector3(0, 4.3, 0), M["roof"])
	box(c, Vector3(2.3, 0.6, 18), Vector3(0, 0.45, 0), M["black"])
	for bz: float in [-7.0, 7.0]:
		box(c, Vector3(2.0, 0.4, 2.4), Vector3(0, 0.4, bz), M["dark_iron"])
		for wz: float in [-0.8, 0.8]:
			for wx: float in [-0.72, 0.72]:
				var wh = cylinder_lol(c, 0.38, 0.38, 0.1, Vector3(wx, 0.4, bz + wz), M["dark_iron"])
				wh.rotation.z = PI / 2.0
	for side: int in [-1, 1]:
		for wz: float in [-8.0, -5.5, -3.0, 3.0, 5.5, 8.0]:
			var w = box(c, Vector3(0.04, 0.9, 1.7), Vector3(side * 1.46, 2.9, wz), M["window"])
			w.set_meta("swap", true)
	var door = node(c, "Door", Vector3(door_side * 1.47, 0, 0))
	box(door, Vector3(0.05, 2.3, 1.15), Vector3(0, 2.25, 0), M["cream"])
	box(door, Vector3(0.06, 0.6, 0.5), Vector3(0, 2.9, 0), M["window"])
	var opening = box(c, Vector3(0.03, 2.3, 1.15), Vector3(door_side * 1.455, 2.25, 0), M["black"])
	opening.visible = false
	c.set_meta("door_panel", door)
	c.set_meta("door_open", opening)
	text_in_3d_lol(c, "HOLLOWMERE  LINE", Vector3(door_side * 1.47, 3.75, -6.0), 0.004, Color(0.85, 0.8, 0.65), 48, 90.0 * door_side, true, "wide")
	return c


func make_the_anomaly_list() -> Array:
	if not lib.is_empty():
		return lib
	var red = Color(1.0, 0.12, 0.08)
	var lamp_pile: Array = []
	for i in N:
		lamp_pile.append("lamp_%d" % i)
		lamp_pile.append("wlamp_L%d" % i)
		lamp_pile.append("wlamp_R%d" % i)
	for k in 4:
		lamp_pile.append("lamp_c%d" % k)
	for ln in lamp_pile:
		anomaly_lights_out("lamp_off", ln, cap(label_it(ln)) + " was switched off.", 2, [ln])
		anomaly_paint_light("lamp_red", ln, red, cap(label_it(ln)) + " glowed red.", 1, [ln])
		anomaly_disco("lamp_flicker", ln, cap(label_it(ln)) + " was flickering.", 1, [ln])
	anomaly_lights_out("vending_off", "vending", "The vending machine was switched off.", 2)
	anomaly_lights_out("tickets_dark", "tickets", "The ticket office windows were dark.", 2)
	anomaly_paint_light("exit_sign_red", "exit_sign", Color(1.0, 0.1, 0.05), "The WAY OUT sign glowed red instead of yellow.", 2)

	add("clock_time", "clock_main", "The big clock showed 4:44 instead of 11:52.", "object", 3, _yeet_clock.bind("clock_main", 4.0, 44.0))
	add("clock_time", "clock_2", "The hanging clock in the middle of the platform showed 7:05 instead of 11:52.", "object", 3, _yeet_clock.bind("clock_2", 7.0, 5.0))
	add("clock_time", "clock_4", "The hanging clock further down the platform showed 12:00 instead of 11:52.", "object", 3, _yeet_clock.bind("clock_4", 12.0, 0.0))

	anomaly_show_it("train_left", "train_left", "A train was standing on the left track.", 1, "structure", ["train_left"])
	anomaly_swap_mat("carriage_lights", "train_right", "window_lit", "The windows of the carriage on the right track were lit.", 2, "light", ["train_right"])
	add("carriage_door", "train_right", "The door of the carriage on the right track was open.", "object", 2, _yeet_carriage_door.bind("train_right"), ["train_right"])

	var bench_pile = ["bench_c0", "bench_c1"]
	for i in N:
		bench_pile.append("bench_%da" % i)
		bench_pile.append("bench_%db" % i)
	for b in bench_pile:
		var tags = [b, "luggage_1"] if b == "bench_1a" else [b]
		add("bench_gone", b, cap(label_it(b)) + " had disappeared.", "object", 2, _yeet_hide_many.bind(tags), tags)

	for r in BOARD.size():
		var one_row: Array = BOARD[r]
		add("board_dest", "board_d%d" % r, "On the departure board, the %s train was now going to HOLLOWMERE — this very station." % one_row[0], "object", 3, _yeet_text.bind("board_d%d" % r, "HOLLOWMERE"), ["board_d%d" % r])
		if one_row[3] == "ON TIME":
			add("board_status", "board_s%d" % r, "The %s to %s was suddenly CANCELLED on the board." % [one_row[0], one_row[1]], "object", 2, _yeet_text.bind("board_s%d" % r, "CANCELLED"), ["board_s%d" % r])
		var t: String = one_row[0]
		var swapped = t.substr(0, 3) + t[4] + t[3]
		if swapped != t and int(t[4]) < 6:
			add("board_time", "board_t%d" % r, "The departure time of the %s train had changed to %s." % [one_row[1], swapped], "object", 3, _yeet_text.bind("board_t%d" % r, swapped), ["board_t%d" % r])

	anomaly_spooky("passenger", "fig_platform", "A motionless passenger stood at the platform edge, watching you.", 1, ["figure"])
	anomaly_spooky("passenger", "fig_far", "A figure stood on the tracks at the far end of the station.", 1, ["figure"])

	for i in [1, 3, 5]:
		add("sign_number", "sign_%d" % i, "The platform sign in %s pointed to platform 3 instead of 2." % which_zone_is_this(i), "object", 3, _yeet_sign.bind("sign_%d" % i))

	for ln in ["luggage_1", "luggage_4", "luggage_c"]:
		anomaly_hide_it("luggage_gone", ln, cap(label_it(ln)) + " was gone.", 2)
	anomaly_show_it("luggage_extra", "luggage_x", "An unattended suitcase stood in the middle of the platform.", 2)
	anomaly_levitate("floating", "luggage_1", "The suitcase on the bench was floating in the air.", 1)
	anomaly_levitate("floating", "luggage_c", "The suitcase in the waiting area was floating in the air.", 1)

	for bn in ["bin_c", "bin_0", "bin_2", "bin_4", "bin_6"]:
		anomaly_hide_it("bin_gone", bn, cap(label_it(bn)) + " was missing.", 2)
	anomaly_show_it("wet_sign", "wet_sign", "A CAUTION WET FLOOR sign appeared on the platform.", 2)
	anomaly_noise("pa_chime", "snd_pa", "pa_chime", 9.0, 2.0, "The station announcement chime kept sounding — but no announcement followed.", 2)
	anomaly_noise("distant_train", "snd_train", "train_far", 11.0, 6.0, "A train could be heard approaching from the tunnel. None arrived.", 2)
	for en in ["edge_L", "edge_R"]:
		anomaly_swap_mat("edge_red", en, "edge_red", cap(label_it(en)) + " was red instead of yellow.", 2)
	for an in ADVERTS:
		var art: String = ADVERTS[an]
		add("advert_swap", an, cap(label_it(an)) + " had changed.", "object", 3, _yeet_poster.bind(an, art + "_alt"), [an])
	add("advert_swap", "poster_c", "The travel poster in the waiting area had changed: the red sun had turned black.", "object", 3, _yeet_poster.bind("poster_c", "travel_alt"), ["poster_c"])
	anomaly_change_text("name_sign", "name_L", "HOLLOWMIRE", "The station sign on the left wall read HOLLOWMIRE instead of HOLLOWMERE.", 3)
	anomaly_change_text("name_sign", "name_R", "HOLLOWMERF", "The station sign on the right wall read HOLLOWMERF instead of HOLLOWMERE.", 3)
	for i in N:
		anomaly_swap_mat("pillar_color", "pillar_%d" % i, "iron_red", cap(label_it("pillar_%d" % i)) + " was painted red instead of green.", 3)

	# ---- жуть ----
	anomaly_show_it("blood_writing", "blood_no_way_out", "Huge red letters \"NO WAY OUT\" were smeared on the wall across the left track.", 1, "supernatural")
	anomaly_show_it("blood_writing", "blood_behind_you", "Huge red letters \"LOOK BEHIND YOU\" were smeared on the wall across the right track.", 1, "supernatural")
	anomaly_eyes("red_eyes", "eyes_track", "Two red eyes glowed on the right track at the far end of the station.", 2)
	anomaly_stalker("stalker", "fig_stalker", "A dark figure crept closer every time you looked away.", 1, ["figure"])
	anomaly_show_it("blood_trail", "blood_trail", "A trail of dark red liquid led to the edge of the platform.", 2, "supernatural")
	anomaly_warp("warp", "warp_a", 4.5, "The air at %s was warping — the walls seemed to breathe." % which_zone_is_this(1), 2)
	anomaly_warp("warp", "warp_b", 4.5, "The air in %s was warping — the walls seemed to breathe." % which_zone_is_this(4), 2)
	for b in ["bench_2a", "bench_5b"]:
		anomaly_flip("bench_flipped", b, 0.85, cap(label_it(b)) + " was upside down.", 2, [b])
	for ln in ["lamp_1", "lamp_4"]:
		anomaly_heartbeat_light("lamp_heartbeat", ln, cap(label_it(ln)) + " pulsed red like a heartbeat.", 1, [ln])
	anomaly_noise("heartbeat", "snd_heart", "heartbeat", 1.25, 6.0, "A heartbeat came from beneath the platform.", 2)
	anomaly_noise("scratching", "snd_scratch", "scratch", 4.5, 3.0, "Something was scratching on the inside of the ticket office windows.", 2)
	anomaly_noise("breathing", "snd_breath", "breath", 5.0, 6.0, "Slow, heavy breathing came out of the far tunnel.", 2)
	return lib


func _spawn_creepy_stuff():
	var L = N * SEC
	creepy_writing("blood_no_way_out", "NO WAY\nOUT", Vector3(-HX + 0.03, 2.05, zone_center_lol(4)), 90.0, which_zone_is_this(4), 120, 0.006, false)
	creepy_writing("blood_behind_you", "LOOK BEHIND YOU", Vector3(HX - 0.03, 2.2, -8.0), -90.0, which_zone_is_this(1), 120, 0.006, false)
	creepy_eyes("eyes_track", Vector3(TX, TY + 1.5, -L + 1.0), 0.0, which_zone_is_this(6))
	creepy_figure("fig_stalker", Vector3(1.3, 0, zone_center_lol(6)), 0.0, which_zone_is_this(6))
	creepy_puddle("blood_trail", Vector3(-2.7, 0.014, zone_center_lol(3) + 0.6), Vector2(0.45, 3.2), which_zone_is_this(3))
	creepy_spot("warp_a", Vector3(0, 1.6, zone_center_lol(1)), which_zone_is_this(1))
	creepy_spot("warp_b", Vector3(0, 1.6, zone_center_lol(4)), which_zone_is_this(4))
	creepy_spot("snd_heart", Vector3(0, -0.6, zone_center_lol(3)), which_zone_is_this(3))
	var tk = _find_node_lol("tickets")
	creepy_spot("snd_scratch", _anchor_pos(tk) + Vector3(0, 1.3, 0), "the concourse")
	creepy_spot("snd_breath", Vector3(-TX, 0.5, -L - 1.0), which_zone_is_this(6))


func _yeet_hide_many(names: Array) -> bool:
	var ok = false
	for nm in names:
		ok = _yeet_hide(nm) or ok
	return ok


func _yeet_clock(nm: String, h: float, m: float) -> bool:
	var c = _find_node_lol(nm)
	if c == null:
		return false
	set_the_time(c, h, m)
	return true


func _yeet_carriage_door(nm: String) -> bool:
	var c = _find_node_lol(nm)
	if c == null:
		return false
	var door: Node3D = c.get_meta("door_panel")
	door.position.z += 1.2
	(c.get_meta("door_open") as Node3D).visible = true
	return true


func _yeet_sign(nm: String) -> bool:
	var s = _find_node_lol(nm)
	if s == null:
		return false
	(s.get_meta("front") as Label3D).text = "←  1          3  →"
	(s.get_meta("back") as Label3D).text = "←  3          1  →"
	return true


func _yeet_poster(nm: String, art: String) -> bool:
	var p = _find_node_lol(nm)
	if p == null:
		return false
	(p.get_meta("canvas") as MeshInstance3D).material_override = texture_mat_xd("art_" + art, Vector3.ONE, 0.7)
	return true
