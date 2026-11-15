extends "res://скрипты/карты/база_карты.gd"

const SEC = 5.0
const XB = -3.0
const XE = 2.0
const XF = 7.0
const TX = 4.5
const TY = -1.1
const WH = 2.8
const SICK = Color(0.95, 0.86, 0.58)
const COOL = Color(0.80, 0.92, 1.0)


func default_stuff() -> Dictionary:
	return {"sections": 7}


func background_noise() -> String:
	return "amb_metro"


func footstep_pitch() -> float:
	return 1.0


func arrival_noise() -> String:
	return "drip"


func preview_pic() -> Array:
	return [Vector3(-1.6, 1.7, 2.6), Vector3(1.5, 1.0, -20.0)]


func menu_pic() -> Array:
	return [Vector3(-0.5, 1.7, 2.5), Vector3(-0.5, 1.7, -10.0)]


func qa_pics() -> Array:
	var L: float = params["sections"] * SEC
	return [
		[Vector3(-0.5, 1.6, 2.5), Vector3(-0.5, 1.4, -15)],
		[Vector3(0.5, 1.6, -8), Vector3(-3, 1.4, -14)],
		[Vector3(-2.0, 1.6, -12), Vector3(7, 0.6, -18)],
		[Vector3(-0.5, 1.6, -L + 4), Vector3(-0.5, 1.2, -L)],
		[Vector3(-0.5, 1.6, -L + 3), Vector3(TX, 0.0, -L - 5)],
		[Vector3(-0.5, 1.6, -20), Vector3(0, 1.6, 5)],
	]


func focus_pic(a) -> Array:
	var t: String = a.id.split(":")[1]
	var n = obj.get(t)
	if n is Node3D and (n as Node3D).is_inside_tree():
		var p: Vector3 = (n as Node3D).global_position
		return [Vector3(0.6, 1.7, p.z + 4.5), p + Vector3(0, 0.3, 0)]
	return preview_pic()


static func zone_center_lol(i: int) -> float:
	return -(i + 0.5) * SEC


static func which_zone_is_this(i: int) -> String:
	if i <= 1:
		return "the start of the platform"
	if i <= 4:
		return "the middle of the platform"
	return "the far end of the platform"


func _cook_the_map():
	_material_pile()
	make_the_env({
		"ambient": Color(0.42, 0.45, 0.40), "ambient_energy": 0.22,
		"fog_color": Color(0.03, 0.035, 0.03), "fog_density": 0.03,
		"exposure": 1.25, "saturation": 0.75, "contrast": 1.15, "vol": 0.03,
	})
	var n: int = params["sections"]
	var L = n * SEC
	_the_shell(L)
	for i in n:
		_chunk(i)
	_both_ends(L)
	_secret_stuff(L)
	spawn_spot = Transform3D(Basis(), Vector3(-0.5, 0.05, 2.6))
	sprinkle_dust(Vector3(1.0, 2.0, -L * 0.5), Vector3(4.5, 1.8, L * 0.5), 260, Color(0.9, 0.95, 0.85, 0.28))


func _material_pile():
	M["tiles"] = mat(Color.WHITE, 0.35, 0.0, "tiles_metro", 1.1, 0.4)
	M["floor"] = mat(Color.WHITE, 0.85, 0.0, "concrete_dark", 0.4, 0.5)
	M["concrete"] = mat(Color.WHITE, 0.9, 0.0, "concrete", 0.35, 0.4)
	M["gravel"] = mat(Color.WHITE, 1.0, 0.0, "gravel", 0.8, 0.8)
	M["rail"] = mat(Color(0.45, 0.42, 0.40), 0.4, 0.4, "rust", 2.0)
	M["sleeper"] = mat(Color(0.14, 0.11, 0.08), 0.95)
	M["pipe"] = mat(Color(0.75, 0.75, 0.75), 0.6, 0.3, "rust", 1.5)
	M["pipe_g"] = mat(Color(0.18, 0.26, 0.2), 0.6, 0.2)
	M["pipe_d"] = mat(Color(0.2, 0.2, 0.22), 0.5, 0.35)
	M["valve"] = mat(Color(0.7, 0.07, 0.05), 0.45)
	M["valve_blue"] = mat(Color(0.08, 0.2, 0.7), 0.45)
	M["steel"] = mat(Color(0.42, 0.44, 0.45), 0.4, 0.4, "metal", 2.0)
	M["door"] = mat(Color(0.35, 0.38, 0.36), 0.6, 0.2, "rust", 1.0)
	M["dark"] = mat(Color(0.012, 0.012, 0.012), 1.0)
	M["black"] = mat(Color(0.01, 0.01, 0.01), 1.0)
	M["red"] = mat(Color(0.62, 0.06, 0.05), 0.4)
	M["white"] = mat(Color(0.85, 0.85, 0.82), 0.5)
	M["sign"] = mat(Color(0.05, 0.05, 0.06), 0.4)
	M["yellow"] = mat(Color(0.8, 0.65, 0.08), 0.6)
	M["lamp_off"] = mat(Color(0.2, 0.2, 0.19), 0.5)
	M["cage"] = mat(Color(0.12, 0.12, 0.12), 0.5, 0.3)
	M["barrel"] = mat(Color(0.12, 0.25, 0.4), 0.5, 0.3)
	M["figure"] = mat(Color(0.004, 0.004, 0.005), 0.95)
	M["puddle"] = see_through_mat("puddle")
	(M["puddle"] as StandardMaterial3D).roughness = 0.05
	(M["puddle"] as StandardMaterial3D).metallic = 0.6


func _the_shell(L: float):
	var s = node(self, "Shell")
	var zmid = (4.0 - L) * 0.5
	var zlen = L + 4.0
	box(s, Vector3(XE - XB, 0.2, zlen), Vector3((XB + XE) * 0.5, -0.1, zmid), M["floor"], true)
	box(s, Vector3(0.2, -TY, zlen), Vector3(XE - 0.1, TY * 0.5, zmid), M["concrete"])
	box(s, Vector3(0.3, 0.012, zlen), Vector3(XE - 0.3, 0.006, zmid), M["white"])
	invisible_wall(s, Vector3(0.1, 3.0, zlen), Vector3(XE + 0.05, 1.5, zmid))
	box(s, Vector3(0.3, WH, zlen), Vector3(XB - 0.15, WH * 0.5, zmid), M["tiles"], true)
	box(s, Vector3(0.3, WH - TY, zlen), Vector3(XF + 0.15, (WH + TY) * 0.5, zmid), M["tiles"])
	box(s, Vector3(XF - XE, 0.2, zlen), Vector3((XE + XF) * 0.5, TY - 0.1, zmid), M["gravel"])
	for r: int in [-1, 1]:
		box(s, Vector3(0.08, 0.16, zlen), Vector3(TX + r * 0.72, TY + 0.14, zmid), M["rail"])
	box(s, Vector3(0.12, 0.12, zlen), Vector3(TX + 1.35, TY + 0.15, zmid), M["steel"])
	var pos: Array = []
	var z = 3.8
	while z > -L:
		pos.append(Vector3(TX, TY + 0.03, z))
		z -= 0.7
	many_boxes(s, Vector3(2.4, 0.1, 0.22), pos, M["sleeper"])
	var center = Vector2(2.0, WH - 4.9)
	var R = 7.0
	var a0 = atan2(4.9, XB - 2.0)
	var a1 = atan2(4.9, XF - 2.0)
	var seg_pile = 9
	for k in seg_pile:
		var t0 = a0 + (a1 - a0) * k / seg_pile
		var t1 = a0 + (a1 - a0) * (k + 1) / seg_pile
		var p0 = center + Vector2(cos(t0), sin(t0)) * R
		var p1 = center + Vector2(cos(t1), sin(t1)) * R
		var mid = (p0 + p1) * 0.5
		var nrm = (mid - center).normalized()
		var seg = box(s, Vector3(p0.distance_to(p1) + 0.06, 0.3, zlen), Vector3(mid.x + nrm.x * 0.15, mid.y + nrm.y * 0.15, zmid), M["tiles"])
		seg.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x)
	var n: int = params["sections"]
	for i in n + 1:
		var zz = -i * SEC
		box(s, Vector3(0.25, WH, 0.3), Vector3(XB + 0.12, WH * 0.5, zz), M["concrete"])
		box(s, Vector3(0.25, WH - TY, 0.3), Vector3(XF - 0.12, (WH + TY) * 0.5, zz), M["concrete"])


func _chunk(i: int):
	var c = zone_center_lol(i)
	var zone = which_zone_is_this(i)
	var s = node(self, "Sec%d" % i)
	var face = XB + 0.01
	var pmats = ["pipe", "pipe_g", "pipe_d"]
	for k in 3:
		var p = cylinder_lol(s, 0.07 - k * 0.012, 0.07 - k * 0.012, SEC - 0.06, Vector3(face + 0.12 + k * 0.03, 2.38 + k * 0.16, c), M[pmats[k]], false, 10)
		p.rotation.x = PI / 2.0
		sign_up_anomaly("pipe_%d_%d" % [i, k], p, "a pipe segment on the wall in %s" % zone, zone)
		var fl = cylinder_lol(s, 0.1 - k * 0.012, 0.1 - k * 0.012, 0.06, Vector3(face + 0.12 + k * 0.03, 2.38 + k * 0.16, c + SEC * 0.5 - 0.03), M["pipe_d"], false, 10)
		fl.rotation.x = PI / 2.0
	if i in [1, 4]:
		var v = node(s, "valve_%d" % i, Vector3(face + 0.32, 2.38, c + 0.6), 90.0)
		var tm = TorusMesh.new()
		tm.inner_radius = 0.1
		tm.outer_radius = 0.14
		var wheel = MeshInstance3D.new()
		wheel.mesh = tm
		wheel.material_override = M["valve"]
		wheel.rotation.x = PI / 2.0
		wheel.set_meta("swap", true)
		v.add_child(wheel)
		box(v, Vector3(0.03, 0.03, 0.2), Vector3(0, 0, -0.1), M["pipe_d"])
		sign_up_anomaly("valve_%d" % i, v, "the red valve wheel on the pipe in %s" % zone, zone)
	var ln = "lamp_%d" % i
	sign_up_anomaly(ln, bulkhead_lol(s, ln, Vector3(face, 1.95, c), 90.0, SICK, 1.15, 6.5, i * 2), "the caged wall lamp in %s" % zone, zone)
	if i % 2 == 0:
		var tn = "tube_%d" % i
		sign_up_anomaly(tn, tube_lol(s, tn, Vector3(-0.5, 3.4, c - 1.2)), "the fluorescent tube above %s" % zone, zone)
	else:
		var fn = "lamp_f%d" % i
		sign_up_anomaly(fn, bulkhead_lol(s, fn, Vector3(XF - 0.01, 1.6, c), -90.0, Color(1.0, 0.6, 0.3), 0.8, 5.5, 20 + i), "the orange lamp on the far wall across the tracks in %s" % zone, zone)
	if i % 2 == 0:
		sign_up_anomaly("bench_%d" % i, sit_here(s, "Bench%d" % i, Vector3(XB + 0.35, 0, c + 1.4), 90.0), "the metal bench in %s" % zone, zone)
	elif i in [1, 5]:
		sign_up_anomaly("door_%d" % i, door(s, "door_%d" % i, Vector3(XB, 0, c + 1.4), true), "the STAFF ONLY door in %s" % zone, zone)
	if i in [1, 4]:
		sign_up_anomaly("name_%d" % i, name_plate(s, "name_%d" % i, Vector3(face, 1.55, c - 1.4), 90.0, 3.0), "the BLACKWATER sign on the platform wall in %s" % zone, zone)
	if i in [2, 5]:
		sign_up_anomaly("name_f%d" % i, name_plate(s, "name_f%d" % i, Vector3(XF - 0.01, 1.2, c - 1.0), -90.0, 4.0), "the big BLACKWATER sign across the tracks in %s" % zone, zone)
	if i == 2:
		var mp = node(s, "map_2", Vector3(face, 1.6, c + 1.4), 90.0)
		box(mp, Vector3(1.5, 1.0, 0.04), Vector3(0, 0, 0.02), M["sign"])
		var canvas = quad(mp, Vector2(1.4, 0.9), Vector3(0, 0, 0.042), texture_mat_xd("art_metro_map", Vector3.ONE, 0.6))
		mp.set_meta("canvas", canvas)
		sign_up_anomaly("map_2", mp, "the line map above the bench", zone)
		sign_up_anomaly("ext", fire_thing(s, "Ext", Vector3(XB, 0, c - 1.5), 90.0), "the fire extinguisher", zone)
	if i == 3:
		var em = node(s, "emerg", Vector3(face, 1.25, c - 1.5), 90.0)
		box(em, Vector3(0.5, 0.6, 0.18), Vector3(0, 0, 0.09), M["red"])
		box(em, Vector3(0.22, 0.06, 0.01), Vector3(0, 0.05, 0.185), M["white"])
		box(em, Vector3(0.06, 0.22, 0.01), Vector3(0, 0.05, 0.185), M["white"])
		text_in_3d_lol(em, "EMERGENCY", Vector3(0, -0.18, 0.185), 0.0016, Color(0.95, 0.95, 0.95), 40, 0.0, true, "bold")
		sign_up_anomaly("emerg", em, "the red emergency cabinet", zone)
	if i == 6:
		var ph = node(s, "phone", Vector3(face, 1.35, c - 1.5), 90.0)
		box(ph, Vector3(0.28, 0.4, 0.12), Vector3(0, 0, 0.06), M["yellow"])
		var rec = node(ph, "Receiver", Vector3(-0.08, 0.02, 0.15))
		box(rec, Vector3(0.06, 0.26, 0.06), Vector3.ZERO, M["black"])
		ph.set_meta("receiver", rec)
		text_in_3d_lol(ph, "SOS", Vector3(0.06, 0.12, 0.125), 0.0018, Color(0.05, 0.05, 0.05), 40, 0.0, true, "bold")
		sign_up_anomaly("phone", ph, "the emergency phone", zone)


func _both_ends(L: float):
	for e in 2:
		var z = 4.0 if e == 0 else -L
		var nd = node(self, "End%d" % e, Vector3(0, 0, z), 180.0 if e == 0 else 0.0)
		var sx = -1.0 if e == 0 else 1.0
		var xb = XB * sx
		var xe = XE * sx
		var xf = XF * sx
		box(nd, Vector3(absf(xe - xb), 5.0, 0.4), Vector3((xb + xe) * 0.5, 2.5, -0.2), M["tiles"], true)
		box(nd, Vector3(absf(xf - xe), 2.6, 0.4), Vector3((xe + xf) * 0.5, 3.1 + 0.2, -0.2), M["tiles"])
		box(nd, Vector3(0.4, 3.6, 0.4), Vector3(xe + sx * 0.2, 0.7, -0.2), M["tiles"])
		box(nd, Vector3(0.4, 3.6, 0.4), Vector3(xf - sx * 0.2, 0.7, -0.2), M["tiles"])
		var tcx = TX * sx
		var tl = 18.0
		var tz = -tl * 0.5 - 0.4
		box(nd, Vector3(4.2, 0.2, tl), Vector3(tcx, TY - 0.1, tz), M["gravel"])
		box(nd, Vector3(0.3, 4.0, tl), Vector3(tcx - 2.25, TY + 2.0, tz), M["dark"])
		box(nd, Vector3(0.3, 4.0, tl), Vector3(tcx + 2.25, TY + 2.0, tz), M["dark"])
		box(nd, Vector3(4.8, 0.3, tl), Vector3(tcx, TY + 4.0, tz), M["dark"])
		box(nd, Vector3(4.2, 4.0, 0.3), Vector3(tcx, TY + 2.0, -tl - 0.4), M["black"])
		for r: int in [-1, 1]:
			box(nd, Vector3(0.08, 0.16, tl), Vector3(tcx + r * 0.72, TY + 0.14, tz), M["rail"])
		var sig = node(nd, "Signal", Vector3(tcx + sx * 1.6, 0, -1.2))
		box(sig, Vector3(0.08, 2.6, 0.08), Vector3(0, TY + 1.3, 0), M["cage"])
		box(sig, Vector3(0.25, 0.4, 0.15), Vector3(0, TY + 2.5, 0.05), M["black"])
		var bulb = ball_lol(sig, 0.06, Vector3(0, TY + 2.55, 0.14), glow(Color(1.0, 0.08, 0.05), 4.0))
		var sl = omni_light_lol(sig, Vector3(0, TY + 2.55, 0.5), Color(1.0, 0.1, 0.05), 0.6, 4.0)
		_tag_the_lamp(sig, [sl], [bulb], M["lamp_off"])
		sign_up_anomaly("signal_%s" % ("near" if e == 0 else "far"), sig, "the red signal light at the %s tunnel" % ("near" if e == 0 else "far"), which_zone_is_this(0 if e == 0 else 6))
		var fan = node(nd, "fan_%d" % e, Vector3(-0.5 * sx, 3.6, 0.05))
		box(fan, Vector3(0.9, 0.9, 0.05), Vector3.ZERO, M["cage"])
		var blade_pile = node(fan, "Blades", Vector3(0, 0, 0.06))
		for b in 4:
			var bl = box(blade_pile, Vector3(0.12, 0.38, 0.02), Vector3(0, 0.2, 0), M["steel"])
			var pivot = node(blade_pile, "B%d" % b)
			blade_pile.remove_child(bl)
			pivot.add_child(bl)
			pivot.rotation.z = b * PI * 0.5
		var spinner = Behaviour.new()
		spinner.mode = "spin"
		spinner.victim = blade_pile
		spinner.axis = Vector3(0, 0, 1)
		spinner.speed = 4.0
		blade_pile.add_child(spinner)
		fan.set_meta("spinner", spinner)
		sign_up_anomaly("fan_%d" % e, fan, "the ventilation fan above the %s door" % ("entrance" if e == 0 else "exit"), which_zone_is_this(0 if e == 0 else 6))
		var dx = -0.5 * sx
		box(nd, Vector3(1.4, 2.4, 0.08), Vector3(dx, 1.2, 0.04), M["cage"])
		box(nd, Vector3(1.2, 2.2, 0.06), Vector3(dx, 1.1, 0.09), M["door"], true)
		box(nd, Vector3(0.5, 0.05, 0.05), Vector3(dx + 0.3 * sx, 1.05, 0.14), M["steel"])
		if e == 0:
			text_in_3d_lol(nd, "TO STREET", Vector3(dx, 2.6, 0.06), 0.003, Color(0.8, 0.8, 0.78), 48, 0.0, true, "wide")
		else:
			var sign = node(nd, "ExitSign", Vector3(dx, 2.62, 0.08))
			box(sign, Vector3(1.0, 0.26, 0.06), Vector3.ZERO, M["black"])
			var face = box(sign, Vector3(0.94, 0.2, 0.01), Vector3(0, 0, 0.035), glow(Color(0.1, 0.8, 0.3), 0.8))
			text_in_3d_lol(sign, "WAY OUT", Vector3(0, 0, 0.042), 0.0028, Color(0.92, 1, 0.92), 48, 0.0, false, "wide")
			var gl = omni_light_lol(sign, Vector3(0, -0.2, 0.4), Color(0.3, 1.0, 0.5), 0.7, 4.0)
			_tag_the_lamp(sign, [gl], [face], M["lamp_off"])
			sign_up_anomaly("exit_sign", sign, "the WAY OUT sign", which_zone_is_this(6))
			make_the_exit_door(Vector3(dx, 1.2, -L + 0.4), Vector3(1.4, 2.4, 0.5))


func _secret_stuff(L: float):
	var dx = door(self, "door_x", Vector3(XB + 0.04, 0, zone_center_lol(3) + 1.4), false)
	set_here_or_not(dx, false)
	sign_up_anomaly("door_x", dx, "a new door", which_zone_is_this(3))
	var ft = spooky_guy(self, "fig_tunnel", Vector3(TX, TY, -L - 2.5), M["figure"])
	set_here_or_not(ft, false)
	sign_up_anomaly("fig_tunnel", ft, "a figure", which_zone_is_this(6))
	var fp = spooky_guy(self, "fig_platform", Vector3(-1.2, 0, zone_center_lol(5) - 1.0), M["figure"])
	set_here_or_not(fp, false)
	sign_up_anomaly("fig_platform", fp, "a figure", which_zone_is_this(5))
	var gr = text_in_3d_lol(self, "IT SEES YOU", Vector3(XF - 0.02, 0.6, zone_center_lol(3) + 0.8), 0.009, Color(0.75, 0.05, 0.04), 96, -90.0, true, "bold")
	gr.visible = false
	sign_up_anomaly("graffiti", gr, "graffiti", which_zone_is_this(3))
	var pd = plane(self, Vector2(1.6, 1.3), Vector3(-1.0, 0.012, zone_center_lol(5) + 0.8), M["puddle"])
	pd.visible = false
	sign_up_anomaly("puddle", pd, "a puddle", which_zone_is_this(5))
	var br = node(self, "barrel", Vector3(XB + 0.45, 0, zone_center_lol(6) - 0.1))
	cylinder_lol(br, 0.3, 0.3, 0.9, Vector3(0, 0.45, 0), M["barrel"], true)
	cylinder_lol(br, 0.31, 0.31, 0.04, Vector3(0, 0.3, 0), M["pipe_d"])
	cylinder_lol(br, 0.31, 0.31, 0.04, Vector3(0, 0.65, 0), M["pipe_d"])
	set_here_or_not(br, false)
	sign_up_anomaly("barrel", br, "a barrel", which_zone_is_this(6))
	var cb = node(self, "cable", Vector3(0.6, 4.3, zone_center_lol(2) - 0.4))
	var wire = box(cb, Vector3(0.025, 2.4, 0.025), Vector3(0, -1.2, 0), M["black"])
	wire.rotation.z = 0.12
	cb.visible = false
	sign_up_anomaly("cable", cb, "a cable", which_zone_is_this(2))
	var hc = node(self, "handcar", Vector3(TX, TY, zone_center_lol(3) - 1.0))
	box(hc, Vector3(1.8, 0.25, 2.2), Vector3(0, 0.55, 0), M["pipe_g"])
	box(hc, Vector3(0.1, 0.9, 0.1), Vector3(0, 1.1, 0), M["cage"])
	box(hc, Vector3(1.4, 0.06, 0.08), Vector3(0, 1.55, 0), M["cage"])
	for wx: float in [-0.72, 0.72]:
		for wz: float in [-0.7, 0.7]:
			var wh = cylinder_lol(hc, 0.25, 0.25, 0.08, Vector3(wx, 0.3, wz), M["cage"])
			wh.rotation.z = PI / 2.0
	set_here_or_not(hc, false)
	sign_up_anomaly("handcar", hc, "a handcar", which_zone_is_this(3))
	sign_up_anomaly("snd_knock", node(self, "SndKnock", Vector3(TX, 0.5, -L - 3.0)), "", which_zone_is_this(6))
	sign_up_anomaly("snd_whisper", node(self, "SndWhisper", Vector3(XB - 0.8, 1.4, zone_center_lol(5) + 1.4)), "", which_zone_is_this(5))
	sign_up_anomaly("snd_train", node(self, "SndTrain", Vector3(TX, 0.5, 5.5)), "", which_zone_is_this(0))


func bulkhead_lol(parent: Node, nm: String, pos: Vector3, rot: float, col: Color, energy: float, rng_m: float, prio: int) -> Node3D:
	var l = node(parent, nm, pos, rot)
	box(l, Vector3(0.3, 0.2, 0.06), Vector3(0, 0, 0.03), M["cage"])
	var g = ball_lol(l, 0.09, Vector3(0, 0, 0.1), glow(col, 2.6), Vector3(1.4, 0.8, 0.7))
	for k in 3:
		box(l, Vector3(0.02, 0.2, 0.02), Vector3(-0.1 + k * 0.1, 0, 0.17), M["cage"])
	var lt = omni_light_lol(l, Vector3(0, 0, 0.35), col, energy, rng_m, prio)
	_tag_the_lamp(l, [lt], [g], M["lamp_off"])
	return l


func tube_lol(parent: Node, nm: String, pos: Vector3) -> Node3D:
	var t = node(parent, nm, pos)
	for cx: float in [-0.5, 0.5]:
		box(t, Vector3(0.015, 0.9, 0.015), Vector3(0, 0.45, cx), M["cage"])
	box(t, Vector3(0.16, 0.06, 1.3), Vector3(0, 0.03, 0), M["cage"])
	var g = box(t, Vector3(0.07, 0.05, 1.2), Vector3(0, -0.02, 0), glow(COOL, 2.4))
	var lt = omni_light_lol(t, Vector3(0, -0.3, 0), COOL, 1.1, 7.0, 5)
	_tag_the_lamp(t, [lt], [g], M["lamp_off"])
	return t


func sit_here(parent: Node, nm: String, pos: Vector3, rot: float) -> Node3D:
	var b = node(parent, nm, pos, rot)
	box(b, Vector3(1.8, 0.05, 0.4), Vector3(0, 0.45, 0), M["steel"])
	box(b, Vector3(1.8, 0.4, 0.04), Vector3(0, 0.72, -0.18), M["steel"])
	for lx: float in [-0.8, 0.8]:
		box(b, Vector3(0.05, 0.45, 0.38), Vector3(lx, 0.225, 0), M["cage"])
	invisible_wall(b, Vector3(1.8, 0.9, 0.45), Vector3(0, 0.45, 0))
	return b


func door(parent: Node, nm: String, pos: Vector3, real: bool) -> Node3D:
	var d = node(parent, nm, pos, 90.0)
	box(d, Vector3(1.2, 2.3, 0.04), Vector3(0, 1.15, 0.02), M["cage"])
	if real:
		box(d, Vector3(1.0, 2.15, 0.01), Vector3(0, 1.08, 0.045), M["black"])
	var hinge = node(d, "Hinge", Vector3(-0.5, 0, 0.08))
	box(hinge, Vector3(1.0, 2.15, 0.05), Vector3(0.5, 1.08, 0), M["door"], true)
	box(hinge, Vector3(0.08, 0.04, 0.05), Vector3(0.88, 1.05, 0.05), M["steel"])
	text_in_3d_lol(hinge, "STAFF ONLY", Vector3(0.5, 1.6, 0.03), 0.0022, Color(0.85, 0.82, 0.7), 40, 0.0, true, "wide")
	d.set_meta("hinge", hinge)
	return d


func name_plate(parent: Node, nm: String, pos: Vector3, rot: float, w: float) -> Node3D:
	var s = node(parent, nm, pos, rot)
	box(s, Vector3(w, 0.5, 0.04), Vector3(0, 0, 0.02), M["sign"])
	box(s, Vector3(w + 0.08, 0.06, 0.05), Vector3(0, 0.27, 0.02), M["red"])
	text_in_3d_lol(s, "BLACKWATER", Vector3(0, -0.02, 0.045), 0.0042 * w / 3.0, Color(0.92, 0.92, 0.9), 64, 0.0, true, "wide")
	return s


func fire_thing(parent: Node, nm: String, pos: Vector3, rot: float) -> Node3D:
	var e = node(parent, nm, pos, rot)
	box(e, Vector3(0.14, 0.05, 0.05), Vector3(0, 1.3, 0.025), M["cage"])
	cylinder_lol(e, 0.085, 0.085, 0.52, Vector3(0, 1.02, 0.11), M["red"])
	cylinder_lol(e, 0.03, 0.05, 0.08, Vector3(0, 1.32, 0.11), M["black"])
	return e


func make_the_anomaly_list() -> Array:
	if not lib.is_empty():
		return lib
	var n = 7
	var lamp_pile: Array = []
	for i in n:
		lamp_pile.append("lamp_%d" % i)
		lamp_pile.append("tube_%d" % i if i % 2 == 0 else "lamp_f%d" % i)
	for ln in lamp_pile:
		anomaly_lights_out("lamp_off", ln, cap(label_it(ln)) + " was off.", 2, [ln])
		anomaly_paint_light("lamp_color", ln, Color(0.35, 1.0, 0.35), cap(label_it(ln)) + " glowed green.", 1, [ln])
		anomaly_disco("lamp_flicker", ln, cap(label_it(ln)) + " was flickering.", 1, [ln])
	anomaly_paint_light("signal_green", "signal_near", Color(0.1, 1.0, 0.3), "The signal at the near tunnel was green instead of red.", 2)
	anomaly_paint_light("signal_green", "signal_far", Color(0.1, 1.0, 0.3), "The signal at the far tunnel was green instead of red.", 2)
	anomaly_lights_out("exit_light_off", "exit_sign", "The WAY OUT sign was not lit.", 2)
	for i in range(1, 6):
		anomaly_hide_it("pipe_gone", "pipe_%d_1" % i, "A segment of the middle pipe was missing in %s." % which_zone_is_this(i), 3)
	for i in [1, 4]:
		anomaly_swap_mat("valve_color", "valve_%d" % i, "valve_blue", "The valve wheel in %s was blue instead of red." % which_zone_is_this(i), 3)
	anomaly_change_text("name_sign", "name_1", "BLACKWATEP", "The station sign near the entrance read BLACKWATEP.", 3)
	anomaly_change_text("name_sign", "name_4", "BLACKVVATER", "The station sign in the middle of the platform read BLACKVVATER.", 3)
	anomaly_change_text("name_sign", "name_f2", "BLAKCWATER", "The big sign across the tracks read BLAKCWATER.", 3)
	anomaly_change_text("name_sign", "name_f5", "BLACKWATER 19", "The far sign across the tracks had an extra \"19\" on it.", 3)
	anomaly_hide_it("emerg_gone", "emerg", "The red emergency cabinet was missing.", 2)
	anomaly_hide_it("ext_gone", "ext", "The fire extinguisher was missing.", 2)
	anomaly_scoot("ext_moved", "ext", Vector3(0, 0, 0.9), 0.0, "The fire extinguisher had moved along the wall.", 3)
	for b in ["bench_0", "bench_2", "bench_4", "bench_6"]:
		anomaly_hide_it("bench_gone", b, cap(label_it(b)) + " was missing.", 2, "object", [b])
	for d in ["door_1", "door_5"]:
		add("door_open", d, cap(label_it(d)) + " was open.", "object", 2, _yeet_door_open.bind(d), [d])
	anomaly_show_it("door_extra", "door_x", "A third STAFF ONLY door appeared in the middle of the platform.", 2, "structure")
	anomaly_spooky("figure", "fig_tunnel", "A figure stood in the far tunnel, on the tracks.", 1, ["figure"])
	anomaly_spooky("figure", "fig_platform", "A figure stood near the end of the platform.", 1, ["figure"])
	anomaly_show_it("graffiti", "graffiti", "Red graffiti \"IT SEES YOU\" appeared on the wall across the tracks.", 2)
	anomaly_show_it("puddle", "puddle", "A dark puddle appeared on the platform floor.", 3)
	anomaly_show_it("barrel", "barrel", "A blue barrel stood against the wall near the exit.", 2)
	anomaly_show_it("cable", "cable", "A loose cable hung from the ceiling.", 3)
	anomaly_show_it("handcar", "handcar", "A handcar stood on the tracks.", 1)
	add("phone_off_hook", "phone", "The receiver of the emergency phone was hanging off the hook.", "object", 3, _yeet_phone.bind("phone"))
	add("map_swap", "map_2", "The line map had an extra black line on it.", "object", 3, _yeet_map.bind("map_2"))
	for f in ["fan_0", "fan_1"]:
		add("fan_stopped", f, cap(label_it(f)) + " had stopped spinning.", "object", 3, _yeet_fan_stop.bind(f))
	anomaly_noise("knocking", "snd_knock", "knock", 6.0, 6.0, "Knocking echoed from inside the far tunnel.", 2)
	anomaly_noise("whisper", "snd_whisper", "whisper", 6.0, 4.0, "Whispering came from behind the STAFF ONLY door at the far end.", 2)
	anomaly_noise("distant_train", "snd_train", "train_far", 12.0, 6.0, "A train could be heard in the tunnel behind you — on a line closed for 19 years.", 2)
	add("longer", "platform", "The platform was longer — an extra section appeared before the exit.", "structure", 2, _prep_lol_longer, ["length"], true)

	# ---- жуть ----
	anomaly_show_it("blood_writing", "blood_never_left", "Red letters \"THEY NEVER LEFT\" were smeared on the far wall across the tracks.", 1, "supernatural")
	anomaly_eyes("red_eyes", "eyes_tunnel", "Two red eyes glowed deep inside the far tunnel.", 2)
	anomaly_stalker("stalker", "fig_stalker", "A dark figure crept closer every time you looked away.", 1, ["figure"])
	anomaly_show_it("blood_pool", "blood_pool", "A pool of dark red liquid spread across the platform.", 2, "supernatural")
	anomaly_warp("warp", "warp_a", 4.0, "The air in %s was warping — the walls seemed to breathe." % which_zone_is_this(2), 2)
	anomaly_warp("warp", "warp_b", 4.0, "The air at %s was warping — the walls seemed to breathe." % which_zone_is_this(5), 2)
	for b in ["bench_2", "bench_4"]:
		anomaly_flip("bench_flipped", b, 0.85, cap(label_it(b)) + " was upside down.", 2, [b])
	for ln in ["lamp_1", "lamp_4"]:
		anomaly_heartbeat_light("lamp_heartbeat", ln, cap(label_it(ln)) + " pulsed red like a heartbeat.", 1, [ln])
	anomaly_noise("heartbeat", "snd_heart", "heartbeat", 1.25, 5.0, "A heartbeat came from behind the STAFF ONLY door at the start of the platform.", 2)
	anomaly_noise("scratching", "snd_scratch", "scratch", 4.5, 4.0, "Something was scratching under the edge of the platform.", 2)
	return lib


func _spawn_creepy_stuff():
	var L: float = params["sections"] * SEC
	creepy_writing("blood_never_left", "THEY NEVER\nLEFT", Vector3(XF - 0.03, 2.3, zone_center_lol(2)), -90.0, which_zone_is_this(2), 100, 0.006, false)
	creepy_eyes("eyes_tunnel", Vector3(TX, TY + 1.4, -L - 4.0), 0.0, which_zone_is_this(6))
	creepy_figure("fig_stalker", Vector3(0.0, 0, zone_center_lol(6)), 0.0, which_zone_is_this(6))
	creepy_puddle("blood_pool", Vector3(0.5, 0.014, zone_center_lol(4)), Vector2(1.4, 1.1), which_zone_is_this(4))
	creepy_spot("warp_a", Vector3(0, 1.6, zone_center_lol(2)), which_zone_is_this(2))
	creepy_spot("warp_b", Vector3(0, 1.6, zone_center_lol(5)), which_zone_is_this(5))
	var d1 = _find_node_lol("door_1")
	creepy_spot("snd_heart", _anchor_pos(d1) + Vector3(-0.6, 1.2, 0), which_zone_is_this(1))
	creepy_spot("snd_scratch", Vector3(XE + 0.3, -0.4, zone_center_lol(3)), which_zone_is_this(3))


func _yeet_door_open(nm: String) -> bool:
	var d = _find_node_lol(nm)
	if d == null:
		return false
	(d.get_meta("hinge") as Node3D).rotation.y = deg_to_rad(-70.0)
	return true


func _yeet_phone(nm: String) -> bool:
	var p = _find_node_lol(nm)
	if p == null:
		return false
	var r: Node3D = p.get_meta("receiver")
	r.position += Vector3(0.0, -0.55, 0.06)
	r.rotation.z = 0.5
	return true


func _yeet_map(nm: String) -> bool:
	var p = _find_node_lol(nm)
	if p == null:
		return false
	(p.get_meta("canvas") as MeshInstance3D).material_override = texture_mat_xd("art_metro_map_alt", Vector3.ONE, 0.6)
	return true


func _yeet_fan_stop(nm: String) -> bool:
	var f = _find_node_lol(nm)
	if f == null:
		return false
	var sp: Node = f.get_meta("spinner")
	if is_instance_valid(sp):
		sp.queue_free()
		return true
	return false


func _prep_lol_longer() -> bool:
	params["sections"] = 8
	return true
