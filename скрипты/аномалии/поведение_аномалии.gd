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
