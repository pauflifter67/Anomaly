extends Node3D

const Anomaly = preload("res://скрипты/аномалии/аномалия.gd")
const Behaviour = preload("res://скрипты/аномалии/поведение_аномалии.gd")
const Tex = preload("res://скрипты/ядро/текстуры.gd")

var params = {}
var obj = {}
var info = {}
var lib: Array = []
var M = {}
var env: Environment
var env_settings_pile = {}
var important_lights: Array = []
var spawn_spot = Transform3D.IDENTITY
var exit_zone: Area3D
var force_the_code = false
var warp_spots: Array = []


func _init():
	params = default_stuff()
	Game.settings_got_changed.connect(_apply_fancy_level)


func build():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	obj.clear()
	important_lights.clear()
	M.clear()
	warp_spots.clear()
	var path = the_prebaked_scene()
	if not force_the_code and path != "" and ResourceLoader.exists(path):
		_load_prebaked(path)
	else:
		_cook_the_map()
	_spawn_creepy_stuff()
	_apply_fancy_level()


func the_prebaked_scene() -> String:
	return ""


func _make_anomaly_stuff():
	pass


func _after_loading_lol():
	pass


func _load_prebaked(path: String):
	var big_boss: Node = (load(path) as PackedScene).instantiate()
	add_child(big_boss)
	for n in big_boss.find_children("*", "", true, false):
		if n.has_meta("reg"):
			sign_up_anomaly(n.get_meta("reg"), n, n.get_meta("label", ""), n.get_meta("zone", ""))
		if n is Light3D and n.has_meta("prio"):
			important_lights.append([n.get_meta("prio"), n])
		if n is WorldEnvironment:
			env = n.environment
			env_settings_pile = n.get_meta("cfg", {})
	exit_zone = big_boss.find_child("Exit", true, false) as Area3D
	var spawn = big_boss.find_child("Спавн", true, false) as Node3D
	if spawn:
		spawn_spot = spawn.transform
	_make_anomaly_stuff()
	_after_loading_lol()


func default_stuff() -> Dictionary:
	return {}


func _cook_the_map():
	pass


func make_the_anomaly_list() -> Array:
	return lib


func background_noise() -> String:
	return ""


func footstep_pitch() -> float:
	return 1.0


func arrival_noise() -> String:
	return "ding"


func preview_pic() -> Array:
	return [Vector3(0, 1.6, 4), Vector3(0, 1.4, -10)]


func menu_pic() -> Array:
	return [Vector3(0, 1.65, 2.0), Vector3(0, 1.65, -8.0)]


func mat(col: Color, rough = 0.8, metal = 0.0, tex = "", scale = 1.0, normal = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if tex != "":
		m.albedo_texture = Tex.gimme_tex(tex)
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * scale
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if normal > 0.0 and Game.quality() >= 2:
			m.normal_enabled = true
			m.normal_texture = Tex.gimme_normal_tex(tex)
			m.normal_scale = normal
	return m


func texture_mat_xd(tex: String, scale = Vector3.ONE, rough = 0.8, normal = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_texture = Tex.gimme_tex(tex)
	m.uv1_scale = scale
	m.roughness = rough
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if normal > 0.0 and Game.quality() >= 2:
		m.normal_enabled = true
		m.normal_texture = Tex.gimme_normal_tex(tex)
		m.normal_scale = normal
	return m


func glow(col: Color, energy = 2.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m


func see_through_mat(tex: String, col = Color.WHITE, unshaded = false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_texture = Tex.gimme_tex(tex)
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func node(parent: Node, nm: String, pos = Vector3.ZERO, rot_y = 0.0) -> Node3D:
	var n = Node3D.new()
	n.name = nm
	n.position = pos
	n.rotation.y = deg_to_rad(rot_y)
	parent.add_child(n)
	return n


func box(parent: Node, size: Vector3, pos: Vector3, m: Material, collide = false, rot_y = 0.0) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	parent.add_child(mi)
	if collide:
		_slap_on_body(mi, size)
	return mi


func cylinder_lol(parent: Node, top_r: float, bot_r: float, h: float, pos: Vector3, m: Material, collide = false, seg = 16) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	if collide:
		_slap_on_body(mi, Vector3(maxf(top_r, bot_r) * 2.0, h, maxf(top_r, bot_r) * 2.0))
	return mi


func ball_lol(parent: Node, r: float, pos: Vector3, m: Material, scl = Vector3.ONE) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi


func pill_lol(parent: Node, r: float, h: float, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cm = CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


func quad(parent: Node, size: Vector2, pos: Vector3, m: Material, rot_y = 0.0) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	parent.add_child(mi)
	return mi


func plane(parent: Node, size: Vector2, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var p = PlaneMesh.new()
	p.size = size
	mi.mesh = p
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


func text_in_3d_lol(parent: Node, txt: String, pos: Vector3, px = 0.004, col = Color.WHITE, size = 64, rot_y = 0.0, shaded = true, fnt = "bold") -> Label3D:
	var l = Label3D.new()
	l.text = txt
	l.position = pos
	l.rotation.y = deg_to_rad(rot_y)
	l.pixel_size = px
	l.font_size = size
	l.font = Game.font(fnt)
	l.modulate = col
	l.outline_size = 0
	l.shaded = shaded
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	parent.add_child(l)
	return l


func invisible_wall(parent: Node, size: Vector3, pos: Vector3):
	var sb = StaticBody3D.new()
	var col_shape_thing = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	col_shape_thing.shape = sh
	sb.add_child(col_shape_thing)
	sb.position = pos
	parent.add_child(sb)


func _slap_on_body(mi: Node3D, size: Vector3):
	var sb = StaticBody3D.new()
	var col_shape_thing = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	col_shape_thing.shape = sh
	sb.add_child(col_shape_thing)
	mi.add_child(sb)


func many_boxes(parent: Node, size: Vector3, positions: Array, m: Material) -> MultiMeshInstance3D:
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm = BoxMesh.new()
	bm.size = size
	mm.mesh = bm
	mm.instance_count = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(Basis(), positions[i]))
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	parent.add_child(mmi)
	return mmi


func clock(parent: Node, nm: String, pos: Vector3, rot_y: float, r: float, rim_mat: Material, h = 10.0, m = 10.0, double = false) -> Node3D:
	var c = node(parent, nm, pos, rot_y)
	var face_m = StandardMaterial3D.new()
	face_m.albedo_texture = Tex.gimme_tex("clock_face")
	face_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	face_m.roughness = 0.4
	var side_pile = [0.0, 180.0] if double else [0.0]
	var rim = cylinder_lol(c, r + 0.025, r + 0.025, 0.08 if double else 0.05, Vector3(0, 0, 0 if double else 0.025), rim_mat)
	rim.rotation.x = PI / 2.0
	for s in side_pile:
		var side = node(c, "Face%d" % int(s), Vector3.ZERO, s)
		var zf = 0.042 if double else 0.052
		quad(side, Vector2(r * 2.0, r * 2.0), Vector3(0, 0, zf), face_m)
		var black = mat(Color(0.04, 0.04, 0.04), 0.5)
		var hh = node(side, "Hour", Vector3(0, 0, zf + 0.008))
		box(hh, Vector3(r * 0.08, r * 0.55, 0.006), Vector3(0, r * 0.24, 0), black)
		var mh = node(side, "Minute", Vector3(0, 0, zf + 0.014))
		box(mh, Vector3(r * 0.05, r * 0.85, 0.006), Vector3(0, r * 0.38, 0), black)
	set_the_time(c, h, m)
	return c


func set_the_time(c: Node3D, h: float, m: float):
	for face in c.find_children("Face*", "Node3D", false, false):
		face.get_node("Minute").rotation.z = -TAU * (m / 60.0)
		face.get_node("Hour").rotation.z = -TAU * ((fmod(h, 12.0) + m / 60.0) / 12.0)


func spooky_guy(parent: Node, nm: String, pos: Vector3, m: Material, rot_y = 0.0) -> Node3D:
	var f = node(parent, nm, pos, rot_y)
	pill_lol(f, 0.2, 1.45, Vector3(0, 0.9, 0), m)
	box(f, Vector3(0.48, 0.16, 0.22), Vector3(0, 1.48, 0), m)
	ball_lol(f, 0.12, Vector3(0, 1.74, 0), m, Vector3(1, 1.12, 1))
	pill_lol(f, 0.06, 0.7, Vector3(-0.27, 1.12, 0), m)
	pill_lol(f, 0.06, 0.7, Vector3(0.27, 1.12, 0), m)
	return f


func omni_light_lol(parent: Node, pos: Vector3, col: Color, energy: float, rng_m: float, shadow_prio = -1) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.3
	l.light_specular = 0.35
	l.shadow_bias = 0.06
	parent.add_child(l)
	if shadow_prio >= 0:
		l.set_meta("prio", shadow_prio)
		important_lights.append([shadow_prio, l])
	return l


func _tag_the_lamp(n: Node3D, _lights: Array, glow_pile: Array, _off_mat: Material):
	n.set_meta("lamp", true)
	for g in glow_pile:
		if g.material_override == null:
			g.material_override = (g as MeshInstance3D).get_active_material(0).duplicate()
		g.set_meta("glow", true)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _lamp_lol(n: Node) -> Dictionary:
	var glow_pile: Array = []
	for c in n.find_children("*", "MeshInstance3D", true, false):
		if c.has_meta("glow"):
			glow_pile.append(c)
	return {"lights": n.find_children("*", "Light3D", true, false), "glows": glow_pile}


func _apply_fancy_level():
	if env:
		Game.make_env_less_fancy(env, env_settings_pile)
	important_lights.sort_custom(func(x, y): return int(x[0]) < int(y[0]))
	var budget = Game.shadow_pocket_money()
	for i in important_lights.size():
		var l: Light3D = important_lights[i][1]
		if is_instance_valid(l):
			l.shadow_enabled = i < budget
	for p in find_children("*", "GPUParticles3D", true, false):
		(p as GPUParticles3D).visible = Game.quality() >= 2


func make_the_env(cfg: Dictionary):
	env_settings_pile = cfg
	var we = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = cfg.get("bg", Color(0, 0, 0))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = cfg.get("ambient", Color(0.5, 0.5, 0.5))
	env.ambient_light_energy = cfg.get("ambient_energy", 0.3)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = cfg.get("exposure", 1.0)
	env.glow_enabled = false
	env.glow_intensity = 0.3
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.2
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = cfg.get("fog_color", Color(0.1, 0.1, 0.1))
	env.fog_density = cfg.get("fog_density", 0.01)
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = cfg.get("contrast", 1.08)
	env.adjustment_saturation = cfg.get("saturation", 0.9)
	we.environment = env
	we.set_meta("cfg", cfg)
	add_child(we)


func sprinkle_dust(center: Vector3, extents: Vector3, amount = 150, col = Color(1.0, 0.92, 0.8, 0.35)):
	var p = GPUParticles3D.new()
	p.name = "Пыль"
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.gravity = Vector3(0, -0.004, 0)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.005
	pm.initial_velocity_max = 0.04
	p.process_material = pm
	p.amount = amount
	p.lifetime = 14.0
	p.preprocess = 14.0
	var q = QuadMesh.new()
	q.size = Vector2(0.006, 0.006)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(col.r, col.g, col.b, col.a * 0.7)
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	m.distance_fade_min_distance = 0.4
	m.distance_fade_max_distance = 2.0
	q.material = m
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(-extents * 1.5, extents * 3.0)
	p.position = center
	add_child(p)


func make_the_exit_door(pos: Vector3, size: Vector3, parent: Node = null) -> Area3D:
	var a = Area3D.new()
	a.name = "Exit"
	var col_shape_thing = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	col_shape_thing.shape = sh
	a.add_child(col_shape_thing)
	a.position = pos
	a.monitoring = false
	a.set_meta("prompt", "[E]")
	(parent if parent else self).add_child(a)
	exit_zone = a
	return a


func sign_up_anomaly(nm: String, n: Node, label = "", zone = "") -> Node:
	obj[nm] = n
	if label != "" or not info.has(nm):
		info[nm] = {"label": label, "zone": zone}
	n.set_meta("reg", nm)
	if label != "":
		n.set_meta("label", label)
		n.set_meta("zone", zone)
	return n


func label_it(nm: String) -> String:
	if info.has(nm):
		return info[nm]["label"]
	return nm


func cap(s: String) -> String:
	if s.is_empty():
		return s
	return s[0].to_upper() + s.substr(1)


static func set_here_or_not(n: Node, v: bool):
	if n is Node3D:
		(n as Node3D).visible = v
	for c in n.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).disabled = not v


func add(kind: String, victim: String, desc: String, cat: String, subt: int, fn: Callable, tags = [], pre = false):
	var a = Anomaly.new()
	a.kind = kind
	a.id = kind + ":" + victim
	a.desc = desc
	a.category = cat
	a.subtlety = subt
	a.zone = info[victim]["zone"] if info.has(victim) else ""
	a.tags = tags if not tags.is_empty() else [victim]
	a.apply_fn = fn
	a.pre = pre
	lib.append(a)


func anomaly_hide_it(kind: String, nm: String, desc: String, subt = 2, cat = "object", tags = []):
	add(kind, nm, desc, cat, subt, _yeet_hide.bind(nm), tags)


func anomaly_show_it(kind: String, nm: String, desc: String, subt = 2, cat = "object", tags = []):
	add(kind, nm, desc, cat, subt, _yeet_show.bind(nm), tags)


func anomaly_lights_out(kind: String, nm: String, desc: String, subt = 2, tags = []):
	add(kind, nm, desc, "light", subt, _yeet_light_off.bind(nm), tags)


func anomaly_paint_light(kind: String, nm: String, col: Color, desc: String, subt = 1, tags = []):
	add(kind, nm, desc, "light", subt, _yeet_light_color.bind(nm, col), tags)


func anomaly_disco(kind: String, nm: String, desc: String, subt = 1, tags = []):
	add(kind, nm, desc, "light", subt, _yeet_flicker.bind(nm), tags)


func anomaly_scoot(kind: String, nm: String, offset: Vector3, rot_deg: float, desc: String, subt = 3, tags = []):
	add(kind, nm, desc, "object", subt, _yeet_move.bind(nm, offset, rot_deg), tags)


func anomaly_change_text(kind: String, nm: String, txt: String, desc: String, subt = 3, cat = "object", tags = []):
	add(kind, nm, desc, cat, subt, _yeet_text.bind(nm, txt), tags)


func anomaly_swap_mat(kind: String, nm: String, mat_key: String, desc: String, subt = 2, cat = "object", tags = []):
	add(kind, nm, desc, cat, subt, _yeet_material.bind(nm, mat_key), tags)


func anomaly_levitate(kind: String, nm: String, desc: String, subt = 1, tags = []):
	add(kind, nm, desc, "supernatural", subt, _yeet_behaviour.bind(nm, "float"), tags)


func anomaly_noise(kind: String, nm: String, sound: String, interval: float, vol: float, desc: String, subt = 2, tags = []):
	add(kind, nm, desc, "sound", subt, _yeet_sound.bind(nm, sound, interval, vol), tags)


func anomaly_spooky(kind: String, nm: String, desc: String, subt = 1, tags = []):
	add(kind, nm, desc, "supernatural", subt, _yeet_figure.bind(nm), tags)


func _find_node_lol(nm: String) -> Node3D:
	var n = obj.get(nm)
	if n == null or not is_instance_valid(n):
		return null
	return n as Node3D


func _yeet_hide(nm: String) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not n.visible:
		return false
	set_here_or_not(n, false)
	return true


func _yeet_show(nm: String) -> bool:
	var n = _find_node_lol(nm)
	if n == null or n.visible:
		return false
	set_here_or_not(n, true)
	return true


func _yeet_light_off(nm: String) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not n.has_meta("lamp"):
		return false
	var d = _lamp_lol(n)
	for l in d["lights"]:
		l.visible = false
	for g in d["glows"]:
		g.material_override = M["lamp_off"]
	return true


func _yeet_light_color(nm: String, col: Color) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not n.has_meta("lamp"):
		return false
	var d = _lamp_lol(n)
	for l in d["lights"]:
		l.light_color = col
	for g in d["glows"]:
		var m = (g.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = col
		m.emission = col
		g.material_override = m
	return true


func _yeet_flicker(nm: String) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not n.has_meta("lamp"):
		return false
	var d = _lamp_lol(n)
	var b = Behaviour.new()
	b.mode = "flicker"
	b.victim = n
	b.lights = d["lights"]
	b.glow_pile = d["glows"]
	b.glow_on = d["glows"][0].material_override if not d["glows"].is_empty() else null
	b.glow_off = M["lamp_off"]
	b.speed = 1.0
	n.add_child(b)
	return true


func _yeet_move(nm: String, offset: Vector3, rot_deg: float) -> bool:
	var n = _find_node_lol(nm)
	if n == null:
		return false
	n.position += offset
	n.rotation.y += deg_to_rad(rot_deg)
	return true


func _yeet_text(nm: String, txt: String) -> bool:
	var n = obj.get(nm)
	if n == null:
		return false
	if n is Label3D:
		(n as Label3D).text = txt
		return true
	for l in (n as Node).find_children("*", "Label3D", true, false):
		(l as Label3D).text = txt
	return true


func _yeet_material(nm: String, mat_key: String) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not M.has(mat_key):
		return false
	var targets: Array = []
	for c in n.find_children("*", "MeshInstance3D", true, false):
		if c.has_meta("swap"):
			targets.append(c)
	if targets.is_empty() and n is MeshInstance3D:
		targets.append(n)
	if targets.is_empty():
		return false
	for t in targets:
		t.material_override = M[mat_key]
	return true


func _yeet_behaviour(nm: String, mode: String) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not n.visible:
		return false
	var b = Behaviour.new()
	b.mode = mode
	b.victim = n
	n.add_child(b)
	return true


func _yeet_figure(nm: String) -> bool:
	if not _yeet_show(nm):
		return false
	var b = Behaviour.new()
	b.mode = "watch"
	b.victim = obj[nm]
	obj[nm].add_child(b)
	return true


# ============ ЖУТЬ: хоррор-аномалии (общие для всех карт) ============

# Карта переопределяет и строит спрятанные жуткие объекты (вызывается после постройки любым путём).
func _spawn_creepy_stuff():
	pass


func creepy_mat(col: Color, rough = 0.9) -> StandardMaterial3D:
	return mat(col, rough)


func blood_mat() -> StandardMaterial3D:
	var m = mat(Color(0.32, 0.01, 0.01), 0.12, 0.1)
	m.clearcoat_enabled = true
	m.clearcoat = 0.6
	return m


func void_mat() -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.0, 0.0, 0.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


# Надпись «кровью» на стене, с потёками. Спрятана, пока аномалия не включит.
func creepy_writing(nm: String, txt: String, pos: Vector3, rot_y: float, zone: String, size = 120, px = 0.006, shaded = true) -> Node3D:
	var holder = node(self, nm, pos, rot_y)
	var r = RandomNumberGenerator.new()
	r.seed = hash(nm)
	holder.rotation.z = deg_to_rad(r.randf_range(-4.0, 4.0))
	var col = Color(0.5, 0.02, 0.015) if shaded else Color(0.62, 0.03, 0.02)
	var l = text_in_3d_lol(holder, txt, Vector3.ZERO, px, col, size, 0.0, shaded, "bold")
	l.outline_size = 10
	l.outline_modulate = Color(0.25, 0.0, 0.0, 0.6)
	var lines = txt.split("\n")
	var widest = 0
	for s in lines:
		widest = maxi(widest, s.length())
	var h = size * px
	var w = widest * h * 0.58
	var bottom = -lines.size() * h * 0.5
	var bm = blood_mat()
	if not shaded:
		bm = StandardMaterial3D.new()
		bm.albedo_color = col
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 6 + widest / 2:
		var dx = r.randf_range(-w * 0.48, w * 0.48)
		var ln = r.randf_range(0.08, 0.55)
		var thick = r.randf_range(0.012, 0.03)
		box(holder, Vector3(thick, ln, 0.004), Vector3(dx, bottom - ln * 0.5 + h * 0.12, 0.002), bm)
		ball_lol(holder, thick * 0.9, Vector3(dx, bottom - ln + h * 0.12, 0.003), bm, Vector3(1, 1.4, 0.3))
	set_here_or_not(holder, false)
	sign_up_anomaly(nm, holder, "", zone)
	return holder


# Два красных глаза в темноте — и чёрная голова вокруг них.
func creepy_eyes(nm: String, pos: Vector3, rot_y: float, zone: String) -> Node3D:
	var e = node(self, nm, pos, rot_y)
	ball_lol(e, 0.2, Vector3(0, 0.02, -0.08), void_mat(), Vector3(1.0, 1.25, 0.7))
	var g = glow(Color(1.0, 0.04, 0.02), 9.0)
	g.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ball_lol(e, 0.04, Vector3(-0.08, 0.04, 0.05), g, Vector3(1.5, 0.7, 0.6))
	ball_lol(e, 0.04, Vector3(0.08, 0.04, 0.05), g, Vector3(1.5, 0.7, 0.6))
	var l = omni_light_lol(e, Vector3(0, 0, 0.3), Color(1.0, 0.08, 0.04), 0.35, 1.8)
	l.shadow_enabled = false
	set_here_or_not(e, false)
	sign_up_anomaly(nm, e, "", zone)
	return e


# Высокая худая фигура-силуэт: длинные руки, голова набок, белые точки глаз.
func creepy_figure(nm: String, pos: Vector3, rot_y: float, zone: String) -> Node3D:
	var f = node(self, nm, pos, rot_y)
	# очень тёмный, но освещаемый материал: в темноте — силуэт, фонариком — видно
	var v = creepy_mat(Color(0.018, 0.016, 0.02), 1.0)
	pill_lol(f, 0.17, 1.55, Vector3(0, 0.95, 0), v)
	box(f, Vector3(0.46, 0.12, 0.2), Vector3(0, 1.66, 0), v)
	var head = node(f, "Head", Vector3(0.05, 1.93, 0.02))
	head.rotation.z = deg_to_rad(-22.0)
	ball_lol(head, 0.12, Vector3.ZERO, v, Vector3(0.95, 1.3, 1.0))
	var eye = StandardMaterial3D.new()
	eye.albedo_color = Color(0.95, 0.95, 0.9)
	eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ball_lol(head, 0.017, Vector3(-0.045, 0.03, 0.105), eye)
	ball_lol(head, 0.017, Vector3(0.045, 0.03, 0.105), eye)
	for sx in [-1.0, 1.0]:
		var arm = pill_lol(f, 0.045, 1.25, Vector3(sx * 0.27, 1.05, 0.02), v)
		arm.rotation.z = sx * deg_to_rad(4.0)
		ball_lol(f, 0.05, Vector3(sx * 0.3, 0.42, 0.02), v, Vector3(0.8, 1.6, 0.8))
	set_here_or_not(f, false)
	sign_up_anomaly(nm, f, "", zone)
	return f


# Кровавые отпечатки ладоней, смазанные вниз по стене. Локальная ось +z — наружу из стены.
func creepy_handprints(nm: String, pos: Vector3, rot_y: float, zone: String, count = 4) -> Node3D:
	var holder = node(self, nm, pos, rot_y)
	var r = RandomNumberGenerator.new()
	r.seed = hash(nm)
	var bm = mat(Color(0.42, 0.02, 0.015), 0.35)
	for i in count:
		var h = node(holder, "Hand%d" % i, Vector3(i * 0.3 + r.randf_range(-0.05, 0.05), -i * 0.16 + r.randf_range(-0.05, 0.05), 0.004 + i * 0.001))
		h.rotation.z = deg_to_rad(r.randf_range(-28.0, 18.0))
		h.scale = Vector3(1.8, 1.8, 1.0)
		ball_lol(h, 0.5, Vector3.ZERO, bm, Vector3(0.085, 0.1, 0.006))
		for k in 4:
			var f = pill_lol(h, 0.0095, 0.075 + (0.012 if k in [1, 2] else 0.0), Vector3(-0.03 + k * 0.02, 0.078, 0), bm)
			f.scale = Vector3(1, 1, 0.25)
		var th = pill_lol(h, 0.01, 0.065, Vector3(-0.055, 0.0, 0), bm)
		th.scale = Vector3(1, 1, 0.25)
		th.rotation.z = 0.85
		# смазанный след вниз
		var sl = r.randf_range(0.05, 0.14)
		ball_lol(h, 0.5, Vector3(r.randf_range(-0.01, 0.01), -0.06 - sl * 0.4, -0.001), bm, Vector3(0.075, sl, 0.004))
	set_here_or_not(holder, false)
	sign_up_anomaly(nm, holder, "", zone)
	return holder


# Лужа неправильной формы из нескольких плоских капель.
func creepy_puddle(nm: String, pos: Vector3, size: Vector2, zone: String) -> Node3D:
	var p = node(self, nm, pos)
	var r = RandomNumberGenerator.new()
	r.seed = hash(nm)
	var bm = blood_mat()
	var small = minf(size.x, size.y)
	var blobs = 4 + int(maxf(size.x, size.y) / small * 2.5)
	for i in blobs:
		var d = small * r.randf_range(0.45, 0.85)
		var off = Vector3(r.randf_range(-0.5, 0.5) * (size.x - d * 0.6), 0.0, r.randf_range(-0.5, 0.5) * (size.y - d * 0.6))
		var b = ball_lol(p, 0.5, off + Vector3(0, i * 0.0006, 0), bm, Vector3(d, 0.012, d * r.randf_range(0.75, 1.3)))
		b.rotation.y = r.randf_range(0.0, TAU)
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 3 + blobs / 2:
		var d = small * r.randf_range(0.06, 0.14)
		var ang = r.randf_range(0.0, TAU)
		var off = Vector3(cos(ang) * size.x * 0.62, 0.0, sin(ang) * size.y * 0.62)
		ball_lol(p, 0.5, off, bm, Vector3(d, 0.01, d))
	set_here_or_not(p, false)
	sign_up_anomaly(nm, p, "", zone)
	return p


func creepy_spot(nm: String, pos: Vector3, zone: String) -> Node3D:
	return sign_up_anomaly(nm, node(self, nm, pos), "", zone) as Node3D


# Перевёрнутый предмет.
func anomaly_flip(kind: String, nm: String, lift: float, desc: String, subt = 2, tags = []):
	add(kind, nm, desc, "supernatural", subt, _yeet_flip.bind(nm, lift), tags)


# Лампа бьётся красным, как сердце.
func anomaly_heartbeat_light(kind: String, nm: String, desc: String, subt = 1, tags = []):
	add(kind, nm, desc, "light", subt, _yeet_pulse.bind(nm), tags)


# Фигура, которая подкрадывается, пока на неё не смотришь.
func anomaly_stalker(kind: String, nm: String, desc: String, subt = 1, tags = []):
	add(kind, nm, desc, "supernatural", subt, _yeet_stalker.bind(nm), tags)


func anomaly_eyes(kind: String, nm: String, desc: String, subt = 2, tags = []):
	add(kind, nm, desc, "supernatural", subt, _yeet_eyes.bind(nm), tags)


# Зона искажения: рядом с ней «плывёт» экран (эффект рисует игровой процесс).
func anomaly_warp(kind: String, nm: String, radius: float, desc: String, subt = 2, tags = []):
	add(kind, nm, desc, "supernatural", subt, _yeet_warp.bind(nm, radius), tags)


# Насколько сильно искажение в точке p (0..1).
func warp_amount(p: Vector3) -> float:
	var best = 0.0
	for s in warp_spots:
		var d = Vector2(p.x - s[0].x, p.z - s[0].z).length()
		best = maxf(best, 1.0 - smoothstep(float(s[1]) * 0.3, float(s[1]), d))
	return best


func _yeet_show_many(names: Array) -> bool:
	var ok = false
	for nm in names:
		ok = _yeet_show(nm) or ok
	return ok


func _yeet_flip(nm: String, lift: float) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not n.visible:
		return false
	n.rotation.z += PI
	n.position.y += lift
	return true


func _yeet_pulse(nm: String) -> bool:
	if not _yeet_light_color(nm, Color(0.9, 0.04, 0.02)):
		return false
	var n = _find_node_lol(nm)
	var d = _lamp_lol(n)
	var b = Behaviour.new()
	b.mode = "pulse"
	b.victim = n
	b.lights = d["lights"]
	b.glow_pile = d["glows"]
	b.remember_energy()
	n.add_child(b)
	return true


func _yeet_stalker(nm: String) -> bool:
	if not _yeet_show(nm):
		return false
	var b = Behaviour.new()
	b.mode = "stalk"
	b.speed = 1.1
	b.victim = obj[nm]
	obj[nm].add_child(b)
	return true


func _yeet_eyes(nm: String) -> bool:
	if not _yeet_show(nm):
		return false
	var b = Behaviour.new()
	b.mode = "blink"
	b.victim = obj[nm]
	obj[nm].add_child(b)
	return true


func _yeet_warp(nm: String, radius: float) -> bool:
	var n = _find_node_lol(nm)
	if n == null:
		return false
	warp_spots.append([n.global_position if n.is_inside_tree() else n.position, radius])
	return true


func _yeet_creak(nm: String) -> bool:
	var n = _find_node_lol(nm)
	if n == null or not n.visible or n.get_node_or_null("Hinge") == null:
		return false
	var b = Behaviour.new()
	b.mode = "creak"
	b.victim = n
	n.add_child(b)
	return true


func _anchor_pos(n: Node3D) -> Vector3:
	if n == null:
		return Vector3.ZERO
	return n.global_position if n.is_inside_tree() else n.position


func _yeet_sound(nm: String, sound: String, interval: float, vol: float) -> bool:
	var n = _find_node_lol(nm)
	if n == null:
		return false
	var p = AudioStreamPlayer3D.new()
	p.stream = Sfx.fetch_stream(sound)
	p.volume_db = vol
	p.unit_size = 5.0
	p.max_distance = 45.0
	n.add_child(p)
	var t = Timer.new()
	t.wait_time = interval
	t.autostart = true
	t.timeout.connect(p.play)
	n.add_child(t)
	return true
