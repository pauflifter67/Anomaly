extends Node3D
# Погоня! Страшный дядя бежит за игроком, на полу дырки в пространстве.
# Наступил в дырку - тормозишь. Дядя догнал - всё, game over.

signal got_eaten
signal phew_escaped

const HEAD_START_GAP = 14.0
const NOM_DIST = 1.0
const RIFT_MIN_AHEAD = 10.0
const RIFT_MAX_AHEAD = 20.0
const MAX_RIFTS = 5
const SAFE_NEAR_EXIT = 2.6
const HIP_Y = 1.08  # на какой высоте у дяди таз

# шейдер для дырки на полу (крутилка)
const FLOOR_SWIRL = """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform vec4 c1 : source_color = vec4(0.62, 0.25, 1.0, 1.0);
uniform vec4 c2 : source_color = vec4(0.1, 0.9, 1.0, 1.0);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float s1 = sin(a * 4.0 + r * 14.0 - TIME * 4.0);
	float s2 = sin(a * -3.0 + r * 9.0 + TIME * 2.5);
	float pulse = 0.75 + 0.25 * sin(TIME * 6.0);
	float rim = smoothstep(0.5, 0.68, r) * (1.0 - smoothstep(0.68, 0.9, r));
	float core = 1.0 - smoothstep(0.45, 0.62, r);
	float halo = (1.0 - smoothstep(0.6, 1.0, r)) * 0.35;
	vec3 glow = mix(c1.rgb, c2.rgb, 0.5 + 0.5 * s1) * (0.5 + 1.8 * rim) * pulse;
	vec3 swirl = c1.rgb * (0.5 + 0.5 * s2) * (1.0 - smoothstep(0.05, 0.6, r)) * 0.8;
	vec3 col = glow * (rim + halo) + swirl * core;
	ALBEDO = col;
	ALPHA = clamp(core * 0.95 + rim + halo, 0.0, 1.0) * (1.0 - smoothstep(0.9, 1.0, r));
}
"""

# шейдер-линза: картинка за дыркой кривится
const WOBBLY_LENS = """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform sampler2D scr : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float strength = 0.14;
void vertex() {
	float sc = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sc, INV_VIEW_MATRIX[1] * sc, INV_VIEW_MATRIX[2] * sc, MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float k = 1.0 - r;
	float ang = k * k * 3.0 * sin(TIME * 1.7);
	mat2 rot = mat2(vec2(cos(ang), sin(ang)), vec2(-sin(ang), cos(ang)));
	vec2 off = ((rot * p) - p) * strength - normalize(p + vec2(0.0001)) * k * k * strength * 0.8;
	off.x *= VIEWPORT_SIZE.y / VIEWPORT_SIZE.x;
	vec3 col;
	col.r = textureLod(scr, SCREEN_UV + off * 1.25, 0.0).r;
	col.g = textureLod(scr, SCREEN_UV + off, 0.0).g;
	col.b = textureLod(scr, SCREEN_UV + off * 0.75, 0.0).b;
	float edge = smoothstep(0.55, 0.92, r) * (1.0 - smoothstep(0.92, 1.0, r));
	col = col * (0.55 + 0.45 * smoothstep(0.0, 0.7, r)) + vec3(0.45, 0.18, 1.0) * edge * 0.7;
	ALBEDO = col;
	ALPHA = 1.0 - smoothstep(0.82, 1.0, r);
}
"""

# шейдер для кожи дяди: серая мокрая кожа с пятнами и венами, красноватая подсветка по краям
const SPOOKY_SKIN = """
shader_type spatial;
uniform vec4 skin : source_color = vec4(0.2, 0.18, 0.17, 1.0);
uniform vec4 rim_col : source_color = vec4(0.9, 0.08, 0.1, 1.0);
varying vec3 lpos;
float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}
float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), f.x), mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), f.x), mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}
void vertex() {
	lpos = VERTEX;
}
void fragment() {
	float n = vnoise(lpos * 9.0) * 0.6 + vnoise(lpos * 31.0) * 0.4;
	float veins = smoothstep(0.62, 0.7, vnoise(lpos * 14.0 + 3.0));
	vec3 base = skin.rgb * (0.6 + 0.8 * n);
	base = mix(base, vec3(0.08, 0.02, 0.03), veins * 0.5);
	ALBEDO = base;
	ROUGHNESS = 0.4 + 0.4 * n;
	SPECULAR = 0.5;
	float f = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.0);
	EMISSION = rim_col.rgb * f * (0.5 + 0.2 * sin(TIME * 7.0)) + base * 0.12;
}
"""

# шейдер на весь экран: глюки возле дырок и красные края
const SCREEN_GLITCH = """
shader_type canvas_item;
uniform sampler2D scr : hint_screen_texture, filter_linear_mipmap;
uniform float warp = 0.0;
uniform float danger = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	uv += c * warp * 0.07 * sin(TIME * 18.0 + length(c) * 28.0);
	uv.x += sin(uv.y * 40.0 + TIME * 30.0) * 0.004 * warp;
	float ab = 0.007 * warp + 0.002 * danger;
	vec3 col;
	col.r = texture(scr, uv + vec2(ab, 0.0)).r;
	col.g = texture(scr, uv).g;
	col.b = texture(scr, uv - vec2(ab, 0.0)).b;
	float v = smoothstep(0.3, 0.9, length(c) * 1.45);
	col = mix(col, col * vec3(1.0, 0.35, 0.35), v * danger);
	col += vec3(0.5, 0.05, 0.1) * v * danger * 0.3;
	col = mix(col, col * vec3(0.8, 0.5, 1.3), warp * 0.35);
	COLOR = vec4(col, 1.0);
}
"""

var rage = 0.0  # прибавка к скорости дяди (в режиме погони растёт с каждым забегом)
var head_start = HEAD_START_GAP
var poor_player: CharacterBody3D
var exit_spot = Vector3.ZERO
var scary_guy: Node3D
var rifts: Array = []
var its_on = false

var _fx_layer: CanvasLayer
var _fx_mat: ShaderMaterial
var _warp = 0.0
var _guy_speed = 3.6
var _timer = 0.0
var _heartbeat = 0.0
var _growl_timer = 3.0
var _ouch_cooldown = 0.0
var _floor_y = 0.0
var _next_rift_z = 0.0
var _spine: Node3D
var _head: Node3D
var _arm_up: Array = []
var _arm_low: Array = []
var _leg_up: Array = []
var _leg_low: Array = []
var _walk_phase = 0.0
var _skin: ShaderMaterial
var _its_over = false
var _dice = RandomNumberGenerator.new()


# будим дядю
func summon(p: CharacterBody3D, exit_p: Vector3):
	poor_player = p
	exit_spot = exit_p
	_dice.randomize()
	_floor_y = p.global_position.y
	_cook_screen_fx()
	_cook_scary_guy(Vector3(p.global_position.x, _floor_y, p.global_position.z + head_start))
	_next_rift_z = p.global_position.z - RIFT_MIN_AHEAD
	its_on = true
	Sfx.play("riser", -4.0, 0.8)
	Sfx.play_3d_lol("whisper", self, scary_guy.global_position, 4.0, 0.55)


func _cook_screen_fx():
	_fx_layer = CanvasLayer.new()
	_fx_layer.layer = 4
	add_child(_fx_layer)
	var rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_mat = _shader_pls(SCREEN_GLITCH)
	rect.material = _fx_mat
	_fx_layer.add_child(rect)


func _shader_pls(code: String) -> ShaderMaterial:
	var sh = Shader.new()
	sh.code = code
	var m = ShaderMaterial.new()
	m.shader = sh
	return m


# кусочек тела: цилиндр, который висит вниз от точки (как кость)
func _bone(parent: Node3D, pos: Vector3, top_r: float, bot_r: float, length: float) -> Node3D:
	var pivot = Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	var mi = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.top_radius = top_r
	shape.bottom_radius = bot_r
	shape.height = length
	shape.radial_segments = 10
	mi.mesh = shape
	mi.material_override = _skin
	mi.position.y = -length / 2.0
	pivot.add_child(mi)
	return pivot


# шарик (сустав, грудь, голова), можно сплющить через scl
func _blob(parent: Node3D, pos: Vector3, radius: float, scl: Vector3, mat: Material = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var shape = SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 16
	shape.rings = 8
	mi.mesh = shape
	mi.material_override = mat if mat else _skin
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi


# лепим дядю из кусочков: худой, сутулый, длинные руки, голова с пастью
func _cook_scary_guy(pos: Vector3):
	scary_guy = Node3D.new()
	scary_guy.name = "Monster"
	add_child(scary_guy)
	scary_guy.global_position = pos
	_skin = _shader_pls(SPOOKY_SKIN)

	var black_mat = StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.0, 0.0, 0.0)
	black_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var eye_mat = StandardMaterial3D.new()
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_mat.albedo_color = Color(1.0, 0.2, 0.12)
	var teeth_mat = StandardMaterial3D.new()
	teeth_mat.albedo_color = Color(0.8, 0.77, 0.68)
	teeth_mat.roughness = 0.6

	# таз и сутулая спина
	_blob(scary_guy, Vector3(0, HIP_Y, 0), 0.2, Vector3(1.2, 0.8, 0.9))
	_spine = Node3D.new()
	_spine.position.y = HIP_Y
	_spine.rotation.x = -0.28
	scary_guy.add_child(_spine)
	_blob(_spine, Vector3(0, 0.5, 0), 0.24, Vector3(1.15, 2.3, 0.75))  # грудная клетка
	_bone(_spine, Vector3(0, 1.12, 0), 0.07, 0.06, 0.25)  # шея

	# голова: вытянутая, глазницы с красными глазами, рот с зубами
	_head = Node3D.new()
	_head.position = Vector3(0, 1.34, -0.04)
	_spine.add_child(_head)
	_blob(_head, Vector3.ZERO, 0.17, Vector3(0.85, 1.3, 1.0))
	for side in [-0.065, 0.065]:
		_blob(_head, Vector3(side, 0.05, -0.14), 0.045, Vector3(1.0, 0.8, 0.6), black_mat)
		_blob(_head, Vector3(side, 0.05, -0.165), 0.018, Vector3.ONE, eye_mat)
	_blob(_head, Vector3(0, -0.1, -0.13), 0.05, Vector3(1.2, 1.8, 0.5), black_mat)
	for i in 5:
		var tooth = MeshInstance3D.new()
		var tooth_shape = CylinderMesh.new()
		tooth_shape.top_radius = 0.012
		tooth_shape.bottom_radius = 0.0
		tooth_shape.height = 0.05
		tooth_shape.radial_segments = 6
		tooth.mesh = tooth_shape
		tooth.material_override = teeth_mat
		tooth.position = Vector3((i - 2) * 0.02, -0.09, -0.165)
		_head.add_child(tooth)

	# длинные руки: плечо, локоть, предплечье, пальцы
	for side in [-1.0, 1.0]:
		_blob(_spine, Vector3(side * 0.3, 0.98, 0), 0.07, Vector3.ONE)
		var upper = _bone(_spine, Vector3(side * 0.3, 0.98, 0), 0.065, 0.05, 0.75)
		_blob(upper, Vector3(0, -0.75, 0), 0.055, Vector3.ONE)
		var fore = _bone(upper, Vector3(0, -0.75, 0), 0.05, 0.035, 0.8)
		for f in 3:
			var finger = _bone(fore, Vector3((f - 1) * 0.025, -0.8, 0), 0.015, 0.008, 0.3)
			finger.rotation = Vector3(0.25, 0, (f - 1) * 0.12)
		_arm_up.append(upper)
		_arm_low.append(fore)

	# ноги: бедро, колено, голень, ступня
	for side in [-1.0, 1.0]:
		var thigh = _bone(scary_guy, Vector3(side * 0.14, HIP_Y, 0), 0.1, 0.07, 0.52)
		_blob(thigh, Vector3(0, -0.52, 0), 0.07, Vector3.ONE)
		var shin = _bone(thigh, Vector3(0, -0.52, 0), 0.065, 0.04, 0.55)
		_blob(shin, Vector3(0, -0.56, -0.07), 0.05, Vector3(0.8, 0.5, 2.0))
		_leg_up.append(thigh)
		_leg_low.append(shin)

	var red_light = OmniLight3D.new()
	red_light.light_color = Color(1.0, 0.1, 0.08)
	red_light.light_energy = 1.6
	red_light.omni_range = 7.0
	red_light.position = Vector3(0, 2.6, -0.6)
	scary_guy.add_child(red_light)

	var smoke = CPUParticles3D.new()
	smoke.amount = 40
	smoke.lifetime = 1.4
	smoke.local_coords = false
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 0.35
	smoke.direction = Vector3(0, 1, 0.6)
	smoke.spread = 40.0
	smoke.initial_velocity_min = 0.3
	smoke.initial_velocity_max = 0.9
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.4
	var smoke_quad = QuadMesh.new()
	smoke_quad.size = Vector2(0.5, 0.5)
	var smoke_mat = StandardMaterial3D.new()
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_mat.albedo_color = Color(0.25, 0.02, 0.08, 0.35)
	smoke_quad.material = smoke_mat
	smoke.mesh = smoke_quad
	smoke.position.y = 1.6
	scary_guy.add_child(smoke)


# Шагает ногами, машет руками, а вблизи тянет руки вперёд
func _animate_guy(gap: float, step_len: float):
	_walk_phase += step_len * 2.2
	var reach = clampf(1.0 - (gap - 1.5) / 6.0, 0.0, 1.0)
	for i in 2:
		var leg_p = _walk_phase + i * PI
		_leg_up[i].rotation.x = sin(leg_p) * 0.6
		_leg_low[i].rotation.x = -(0.55 + 0.55 * sin(leg_p + 1.3))
		var arm_p = leg_p + PI
		_arm_up[i].rotation.x = lerpf(sin(arm_p) * 0.45, 1.35, reach)
		_arm_low[i].rotation.x = lerpf(0.25 + 0.2 * sin(arm_p), 0.15, reach)
	_spine.rotation.z = sin(_walk_phase) * 0.06
	_spine.rotation.x = -0.28 - reach * 0.12
	_head.rotation.z = sin(_timer * 2.3) * 0.1
	_head.rotation.x = 0.1 + 0.1 * sin(_timer * 3.1)


func _process(delta: float):
	if not its_on or _its_over:
		return
	_timer += delta
	var pp = poor_player.global_position
	var mp = scary_guy.global_position
	var to_player = Vector3(pp.x - mp.x, 0, pp.z - mp.z)
	var gap = to_player.length()

	# если игрок убежал далеко - дядя злится и бежит быстрее
	var want_speed = 3.7 + clampf((gap - 9.0) * 0.12, 0.0, 1.6) + clampf(_timer * 0.03, 0.0, 0.6) + rage
	_guy_speed = move_toward(_guy_speed, want_speed, delta * 1.5)
	var step_len = 0.0
	if gap > 0.01:
		step_len = minf(_guy_speed * delta, gap)
		scary_guy.global_position += to_player / gap * step_len
		scary_guy.rotation.y = atan2(-to_player.x, -to_player.z)
	scary_guy.global_position.y = _floor_y + 0.03 * absf(sin(_walk_phase))
	_animate_guy(gap, step_len)

	if Vector2(pp.x - exit_spot.x, pp.z - exit_spot.z).length() < SAFE_NEAR_EXIT:
		_phew()
		return
	if gap < NOM_DIST:
		_gotcha()
		return

	_rifts_tick(delta, pp)
	_scary_sounds(delta, gap)
	var danger = clampf(1.0 - (gap - 2.0) / 14.0, 0.0, 1.0)
	_fx_mat.set_shader_parameter("danger", danger)


func _rifts_tick(delta: float, pp: Vector3):
	# делаем новые дырки впереди игрока
	while rifts.size() < MAX_RIFTS and _next_rift_z > exit_spot.z + 6.0 and _next_rift_z > pp.z - RIFT_MAX_AHEAD:
		_maybe_make_rift(pp, _next_rift_z)
		_next_rift_z -= _dice.randf_range(6.0, 9.0)
	var warp = 0.0
	var standing_in_one = false
	_ouch_cooldown = maxf(0.0, _ouch_cooldown - delta)
	for r in rifts.duplicate():
		var rift_node: Node3D = r["node"]
		# дырка осталась далеко позади - выкидываем
		if rift_node.global_position.z > pp.z + 12.0:
			rifts.erase(r)
			rift_node.queue_free()
			continue
		var c: Vector3 = rift_node.global_position
		var d = Vector2(pp.x - c.x, pp.z - c.z).length()
		var radius: float = r["r"]
		warp = maxf(warp, 1.0 - smoothstep(radius * 0.5, radius * 3.0, d))
		r["light"].light_energy = 1.4 + 0.8 * sin(_timer * 6.0 + c.z)
		if d < radius * 0.85 and absf(pp.y - c.y) < 1.2:
			standing_in_one = true
			# засасывает в центр
			var suck = Vector3(c.x - pp.x, 0, c.z - pp.z) * 0.9 * delta
			poor_player.global_position += suck
			if _ouch_cooldown <= 0.0:
				_ouch_cooldown = 1.2
				_ouch_rift()
	var target_speed = 0.28 if standing_in_one else 1.0
	poor_player.speed_mult = move_toward(poor_player.speed_mult, target_speed, delta * (8.0 if standing_in_one else 1.6))
	_warp = lerpf(_warp, clampf(warp + (0.6 if standing_in_one else 0.0), 0.0, 1.0), clampf(delta * 8.0, 0.0, 1.0))
	_fx_mat.set_shader_parameter("warp", _warp)


# игрок наступил - звук и тряска камеры
func _ouch_rift():
	Sfx.play("wrong", -6.0, 0.6)
	Sfx.play("whisper", -6.0, 0.7)
	if poor_player.cam:
		var tw = create_tween()
		tw.tween_property(poor_player.cam, "rotation:z", 0.12, 0.08)
		tw.tween_property(poor_player.cam, "rotation:z", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC)


func _maybe_make_rift(pp: Vector3, z: float):
	var space = get_world_3d().direct_space_state
	var y = pp.y + 1.0
	var origin = Vector3(pp.x, y, z)
	var left = _how_far_is_wall(space, origin, Vector3.LEFT)
	var right = _how_far_is_wall(space, origin, Vector3.RIGHT)
	# слишком близко к стене или мебели - не ставим
	if left < 0.6 or right < 0.6:
		return
	var width = left + right
	if width < 1.9:
		return
	var radius = _dice.randf_range(0.7, 0.95)
	# оставляем игроку щель, чтобы можно было проскочить
	if width - 2.0 * radius < 1.1:
		radius = maxf(0.45, (width - 1.1) / 2.0)
	var margin = radius + 0.3
	if left - margin + right - margin < 0.0:
		return
	var x = pp.x + _dice.randf_range(-(left - margin), right - margin)
	_cook_rift(Vector3(x, _floor_y, z), radius)


func _how_far_is_wall(space: PhysicsDirectSpaceState3D, from: Vector3, dir: Vector3) -> float:
	var ray = PhysicsRayQueryParameters3D.create(from, from + dir * 6.0)
	ray.exclude = [poor_player.get_rid()]
	var hit = space.intersect_ray(ray)
	if hit.is_empty():
		return 3.0
	return from.distance_to(hit["position"])


# делаем красивую дырку
func _cook_rift(pos: Vector3, radius: float):
	var root = Node3D.new()
	root.name = "Rift"
	add_child(root)
	root.global_position = pos

	var floor_swirl = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2.ONE * radius * 2.7
	floor_swirl.mesh = plane
	floor_swirl.material_override = _shader_pls(FLOOR_SWIRL)
	floor_swirl.position.y = 0.03
	root.add_child(floor_swirl)

	var lens = MeshInstance3D.new()
	var lens_quad = QuadMesh.new()
	lens_quad.size = Vector2(radius * 1.5, radius * 2.5)
	lens.mesh = lens_quad
	lens.material_override = _shader_pls(WOBBLY_LENS)
	lens.position.y = radius * 1.15
	root.add_child(lens)

	var purple_light = OmniLight3D.new()
	purple_light.light_color = Color(0.6, 0.3, 1.0)
	purple_light.light_energy = 1.6
	purple_light.omni_range = radius * 5.0
	purple_light.position.y = 0.6
	root.add_child(purple_light)

	# искорки летят в дырку
	var sparks = CPUParticles3D.new()
	sparks.amount = 28
	sparks.lifetime = 1.3
	sparks.local_coords = true
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = radius * 1.3
	sparks.gravity = Vector3.ZERO
	sparks.radial_accel_min = -4.0
	sparks.radial_accel_max = -2.5
	sparks.initial_velocity_min = 0.0
	sparks.initial_velocity_max = 0.4
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 1.2
	var spark_quad = QuadMesh.new()
	spark_quad.size = Vector2(0.07, 0.07)
	var spark_mat = StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	spark_mat.albedo_color = Color(0.75, 0.55, 1.0)
	spark_quad.material = spark_mat
	sparks.mesh = spark_quad
	sparks.position.y = radius * 0.8
	root.add_child(sparks)

	# дырка плавно раскрывается
	root.scale = Vector3.ONE * 0.01
	var tw = create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rifts.append({"node": root, "r": radius, "light": purple_light})
	Sfx.play_3d_lol("riser", root, pos, -12.0, 1.6)


func _scary_sounds(delta: float, gap: float):
	_heartbeat -= delta
	if _heartbeat <= 0.0:
		_heartbeat = lerpf(0.35, 1.0, clampf(gap / 15.0, 0.0, 1.0))
		Sfx.play("boom", -22.0 + clampf(1.0 - gap / 15.0, 0.0, 1.0) * 8.0, 0.45)
	_growl_timer -= delta
	if _growl_timer <= 0.0:
		_growl_timer = _dice.randf_range(2.0, 4.0)
		Sfx.play_3d_lol("whisper", self, scary_guy.global_position, 2.0, _dice.randf_range(0.45, 0.7))


# ура, убежали
func _phew():
	if _its_over:
		return
	_its_over = true
	poor_player.speed_mult = 1.0
	phew_escaped.emit()
	_poof(0.8)


# догнал :(
func _gotcha():
	if _its_over:
		return
	_its_over = true
	poor_player.can_i_move_lol = false
	poor_player.speed_mult = 1.0
	Sfx.play("boom", -2.0, 0.7)
	_fx_mat.set_shader_parameter("warp", 1.0)
	_fx_mat.set_shader_parameter("danger", 1.0)
	# игрок оборачивается и видит дядю в упор
	var to_guy = scary_guy.global_position - poor_player.global_position
	var tw = create_tween()
	tw.tween_property(poor_player, "rotation:y", atan2(-to_guy.x, -to_guy.z) + PI, 0.25)
	tw.parallel().tween_property(poor_player.head, "rotation:x", deg_to_rad(15.0), 0.25)
	tw.tween_property(scary_guy, "global_position", poor_player.global_position + to_guy.normalized() * 0.7, 0.2)
	tw.tween_interval(0.9)
	tw.tween_callback(func(): got_eaten.emit())


# дядя и дырки исчезают
func _poof(delay: float):
	its_on = false
	_fx_mat.set_shader_parameter("warp", 0.0)
	_fx_mat.set_shader_parameter("danger", 0.0)
	var tw = create_tween()
	for r in rifts:
		tw.parallel().tween_property(r["node"], "scale", Vector3.ONE * 0.01, delay)
	tw.parallel().tween_property(scary_guy, "scale", Vector3(0.01, 0.01, 0.01), delay)
	tw.tween_callback(queue_free)


func go_away():
	if its_on:
		its_on = false
		poor_player.speed_mult = 1.0
	queue_free()
