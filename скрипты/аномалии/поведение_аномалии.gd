extends Node

var mode = "float"
var victim: Node3D
var speed = 1.0
var a = Vector3.ZERO
var b = Vector3.ZERO
var axis = Vector3.FORWARD
var lights: Array = []
var glow_pile: Array = []
var glow_on: Material
var glow_off: Material

var _t = 0.0
var _base_pos = Vector3.ZERO
var _base_rot = Vector3.ZERO


func _ready():
	if victim == null:
		victim = get_parent() as Node3D
	_base_pos = victim.position
	_base_rot = victim.rotation
	_t = randf() * 10.0 if mode == "sway" else 0.0


func _process(delta: float):
	if victim == null:
		return
	_t += delta * speed
	match mode:
		"float":
			victim.position = _base_pos + Vector3(0, 0.32 + sin(_t * 1.4) * 0.07, 0)
			victim.rotation = _base_rot + Vector3(sin(_t * 0.7) * 0.1, _t * 0.3, cos(_t * 0.9) * 0.08)
		"watch":
			var cam = get_viewport().get_camera_3d()
			if cam:
				var d = cam.global_position - victim.global_position
				var want = atan2(d.x, d.z)
				victim.global_rotation.y = lerp_angle(victim.global_rotation.y, want, clampf(delta * 1.2, 0.0, 1.0))
		"slide":
			victim.position = a.lerp(b, 0.5 - 0.5 * cos(_t))
		"flicker":
			var p = fposmod(_t, 4.3)
			var on = not (p < 0.12 or (p > 0.3 and p < 0.38) or (p > 2.1 and p < 2.17) or (p > 2.3 and p < 2.6))
			for l in lights:
				if is_instance_valid(l):
					l.visible = on
			for g in glow_pile:
				if is_instance_valid(g):
					g.material_override = glow_on if on else glow_off
		"spin":
			victim.rotate_object_local(axis, delta * speed)
		"sway":
			victim.rotation.z = _base_rot.z + sin(_t * 0.8) * 0.025
		"stalk":
			_creep_closer(delta)
		"blink":
			# глаза: моргают раз в несколько секунд
			var p = fposmod(_t, 3.7)
			victim.visible = not (p > 3.45 or (p > 1.2 and p < 1.32))
		"pulse":
			# свет бьётся, как сердце: тук-тук... пауза
			var p = fposmod(_t, 1.15)
			var beat = exp(-pow(p / 0.07, 2.0)) + 0.75 * exp(-pow((p - 0.27) / 0.07, 2.0))
			var k = 0.12 + 0.88 * clampf(beat, 0.0, 1.0)
			for i in lights.size():
				if is_instance_valid(lights[i]):
					lights[i].light_energy = float(_base_energy[i]) * (0.35 + 1.4 * k)
			for g in glow_pile:
				if is_instance_valid(g) and g.material_override is StandardMaterial3D:
					(g.material_override as StandardMaterial3D).emission_energy_multiplier = 0.4 + 4.0 * k
		"creak":
			# дверь сама тихо открывается и закрывается
			var hinge = victim.get_node_or_null("Hinge")
			if hinge:
				hinge.rotation.y = deg_to_rad(34.0) * pow(0.5 - 0.5 * cos(_t * 0.55), 2.0)


var _base_energy: Array = []


func remember_energy():
	_base_energy.clear()
	for l in lights:
		_base_energy.append(l.light_energy if is_instance_valid(l) else 1.0)


# «Не смотри назад»: фигура подходит ближе, только пока игрок на неё не смотрит.
func _creep_closer(delta: float):
	var cam = get_viewport().get_camera_3d()
	if cam == null or not victim.visible:
		return
	var to_cam = cam.global_position - victim.global_position
	to_cam.y = 0.0
	var dist = to_cam.length()
	if dist < 0.001:
		return
	victim.global_rotation.y = atan2(to_cam.x, to_cam.z)
	var fwd = -cam.global_transform.basis.z
	var to_fig = (victim.global_position + Vector3(0, 1.2, 0) - cam.global_position).normalized()
	var looking = fwd.dot(to_fig) > 0.5
	if not looking and dist > 2.4:
		victim.global_position += to_cam.normalized() * minf(speed * delta, dist - 2.4)
