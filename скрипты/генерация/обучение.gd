extends Node
# Интерактивное обучение: следит за действиями игрока и по очереди показывает задания.
# Работает поверх обычного игрового процесса (игровой_процесс.gd) в режиме Game.tutorial_mode.

const Loc = preload("res://скрипты/ядро/локализация.gd")
const TOTAL = 7

# [ключ, заголовок, текст] — тексты на английском, перевод берётся из Loc.
const STEPS = [
	["look", "MOUSE", "Move the mouse. Look around. 67."],
	["walk", "W A S D", "Press W A S D to walk. Skibidi steps."],
	["run", "SHIFT", "Hold SHIFT to run. Gotta go fast."],
	["torch", "F", "Press F: flashlight. Lowkey cool."],
	["ref", "REMEMBER", "This corridor is normal. Remember it. Then press E at the far door."],
	["find", "FIND IT", "ONE thing changed. Find it. Stuck? Press H. Then E at the door."],
	["report", "REPORT", "Pick the number with ← →, then CONFIRM. Mistakes are free. No cap."],
]

var g: Node
var _done = {"look": false, "walk": false, "run": false, "torch": false}
var _look_acc = 0.0
var _run_time = 0.0
var _start_pos = Vector3.ZERO
var _have_start = false
var _last_step = -99
var _skipped = false


func setup(game: Node):
	g = game


# Вызывается, когда HUD был пересобран (смена языка) — показать текущее задание заново.
func reset_display():
	_last_step = -99


func _input(e: InputEvent):
	if g == null:
		return
	# T = "нет, я сам научусь": выходим из обучения в обычную игру
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_T and g.vibe_check == g.State.EXPLORE and not _skipped:
		_skipped = true
		Game.tutorial_mode = false
		Sfx.play("click", -8.0)
		Sfx.play("riser", -6.0)
		Game.yeet_to_scene(Game.GAME_SCENE)
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and g.vibe_check == g.State.EXPLORE:
		_look_acc += (e as InputEventMouseMotion).relative.length()


func _process(delta: float):
	if g == null or g.player == null or g.hud == null:
		return
	var step = _current_step(delta)
	if step == _last_step:
		return
	if _last_step >= 0 and _last_step <= 3 and step > _last_step:
		g.hud.pop_toast(Loc.t("✓  Done"))
		Sfx.play("chime_ok", -12.0)
	_last_step = step
	if step < 0:
		g.hud.hide_tutorial()
	else:
		var s: Array = STEPS[step]
		g.hud.show_tutorial_step(step + 1, TOTAL, s[1], s[2])


func _current_step(delta: float) -> int:
	var st = g.vibe_check
	if st == g.State.SUBMIT:
		return 6
	if st != g.State.EXPLORE:
		return -1
	if not g.reference:
		return 5
	var p: CharacterBody3D = g.player
	if not _have_start:
		_start_pos = p.global_position
		_have_start = true
	if _look_acc > 400.0:
		_done["look"] = true
	if Vector2(p.global_position.x - _start_pos.x, p.global_position.z - _start_pos.z).length() > 2.5:
		_done["walk"] = true
	if Input.is_action_pressed("sprint") and p.velocity.length() > 3.5:
		_run_time += delta
		if _run_time > 0.6:
			_done["run"] = true
	if p.torch_thingy.visible:
		_done["torch"] = true
	for i in 4:
		if not _done[STEPS[i][0]]:
			return i
	return 4
