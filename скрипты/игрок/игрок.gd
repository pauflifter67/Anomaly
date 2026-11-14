extends CharacterBody3D

signal prompt_flipped(text: String)

const SLOW_WALK = 2.7
const ZOOMIES = 4.6
const SPEEDUP = 11.0
const DOWNWARD_PULL = 18.0

var head: Node3D
var cam: Camera3D
var torch_thingy: SpotLight3D
var laser_stick: RayCast3D
var can_i_move_lol = true
var footstep_pitch = 1.0
var step_loudness = -13.0

var _wobble = 0.0
var _step_counter = 0.0
var _prompt = ""
var _target: Object = null


func _ready():
	var col_shape_thing = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.75
	col_shape_thing.shape = cap
	col_shape_thing.position.y = 0.875
	add_child(col_shape_thing)
	head = Node3D.new()
	head.position.y = 1.62
	add_child(head)
	cam = Camera3D.new()
	cam.near = 0.05
	cam.far = 150.0
	head.add_child(cam)
	cam.current = true
	torch_thingy = SpotLight3D.new()
	torch_thingy.spot_range = 18.0
	torch_thingy.spot_angle = 24.0
	torch_thingy.spot_attenuation = 0.8
	torch_thingy.light_energy = 3.2
	torch_thingy.light_color = Color(1.0, 0.95, 0.86)
	torch_thingy.position = Vector3(0.12, -0.12, 0.0)
	torch_thingy.visible = false
	cam.add_child(torch_thingy)
	laser_stick = RayCast3D.new()
	laser_stick.target_position = Vector3(0, 0, -2.6)
	laser_stick.collide_with_areas = true
	laser_stick.hit_from_inside = true
	laser_stick.add_exception(self)
	cam.add_child(laser_stick)
	floor_snap_length = 0.3
	Game.settings_got_changed.connect(_fix_settings_lol)
	_fix_settings_lol()


func _fix_settings_lol():
	cam.fov = float(Game.setting("fov"))
	torch_thingy.shadow_enabled = Game.quality() >= 2


func beam_me_up(xf: Transform3D):
	global_position = xf.origin
	rotation = Vector3(0, xf.basis.get_euler().y, 0)
	head.rotation = Vector3.ZERO
	velocity = Vector3.ZERO


func _unhandled_input(e: InputEvent):
	if not can_i_move_lol:
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s = float(Game.setting("sensitivity")) * 0.01
		rotate_y(-e.relative.x * s)
		head.rotate_x(-e.relative.y * s)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
	elif e.is_action_pressed("flashlight"):
		torch_thingy.visible = not torch_thingy.visible
		Sfx.play("click", -12.0, 1.4)
	elif e.is_action_pressed("interact"):
		_poke_it()
	elif e is InputEventMouseButton and e.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y -= DOWNWARD_PULL * delta
	var go_dir = Vector3.ZERO
	var sprint = false
	if can_i_move_lol:
		var wasd_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		go_dir = (transform.basis * Vector3(wasd_vec.x, 0, wasd_vec.y))
		if go_dir.length() > 1.0:
			go_dir = go_dir.normalized()
		sprint = Input.is_action_pressed("sprint")
	var victim = go_dir * (ZOOMIES if sprint else SLOW_WALK)
	var k = 1.0 - exp(-SPEEDUP * delta)
	velocity.x = lerpf(velocity.x, victim.x, k)
	velocity.z = lerpf(velocity.z, victim.z, k)
	move_and_slide()

	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_speed > 0.4:
		_wobble += delta * horiz_speed * 2.3
		_step_counter += horiz_speed * delta
		var stride_len = 0.95 if horiz_speed > 3.5 else 0.72
		if _step_counter >= stride_len:
			_step_counter = 0.0
			Sfx.play("step%d" % (randi() % 4), step_loudness + (2.0 if sprint else 0.0), footstep_pitch * randf_range(0.9, 1.1))
	var wiggle = 0.032 if Game.setting("head_bob") else 0.0
	var w = clampf(horiz_speed / 3.0, 0.0, 1.0)
	cam.position = cam.position.lerp(Vector3(cos(_wobble) * wiggle * 0.5 * w, absf(sin(_wobble)) * wiggle * w, 0), clampf(delta * 12.0, 0.0, 1.0))
	_whats_under_my_nose()


func _whats_under_my_nose():
	var t = ""
	var victim: Object = null
	if can_i_move_lol and laser_stick.is_colliding():
		var c = laser_stick.get_collider()
		if c and c.has_meta("prompt"):
			t = str(c.get_meta("prompt"))
			victim = c
	_target = victim
	if t != _prompt:
		_prompt = t
		prompt_flipped.emit(t)


func _poke_it():
	if _target and is_instance_valid(_target) and _target.has_meta("on_interact"):
		var cb: Callable = _target.get_meta("on_interact")
		if cb.is_valid():
			cb.call()
