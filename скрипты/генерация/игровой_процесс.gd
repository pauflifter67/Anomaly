extends Node3D

const Manager = preload("res://скрипты/аномалии/менеджер_аномалий.gd")
const Difficulty = preload("res://скрипты/сложность/сложность.gd")
const Catalog = preload("res://скрипты/карты/каталог_карт.gd")
const Player = preload("res://скрипты/игрок/игрок.gd")
const HUD = preload("res://скрипты/интерфейс/интерфейс_игры.gd")

enum State { EXPLORE, SUBMIT, RESULT, TRANSITION, OVER, PAUSED }

var vibe_check = State.TRANSITION
var map_deets: Dictionary
var diff: Dictionary
var map_node: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var manager = Manager.new()
var level = 1
var reference = true
var oopsies_left = 0
var cleared = 0
var time_remaining_lol = 0.0
var cheated_with_hint = false

var _last_ok = false
var _over = false
var _synth_tick = 0
var _best_before = 0


func _ready():
	map_deets = Catalog.gimme_map(Game.progress.picked_map)
	if not Game.progress.is_it_open_yet(map_deets["id"]):
		map_deets = Catalog.LIST[0]
	diff = Difficulty.gimme_difficulty(Game.progress.picked_difficulty)
	oopsies_left = int(diff["mistakes"])
	_best_before = Game.progress.best_score_for_this_map(map_deets["id"], diff["id"])

	player = Player.new()
	player.name = "Player"
	add_child(player)
	hud = HUD.new()
	add_child(hud)
	hud.setup(map_deets["title"] + "   ·   " + diff["title"], int(diff["mistakes"]), bool(diff["hints"]))
	hud.answer_sent.connect(_judge_the_player)
	hud.answer_nvm.connect(_on_submit_nvm)
	hud.result_closed.connect(_on_verdict_gone)
	hud.wants_back.connect(_pause_pls.bind(false))
	hud.wants_again.connect(func(): Game.yeet_to_scene(Game.GAME_SCENE))
	hud.wants_out.connect(func(): Game.yeet_to_scene(Game.MENU_SCENE))
	player.prompt_flipped.connect(hud.show_prompt_text)

	Game.progress.when_run_starts_lol(map_deets["id"])
	Sfx.set_bg_music("")
	_load_the_round(true)
	Sfx.set_bg_noise(map_node.background_noise(), -8.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await Game.come_back_to_light(1.0)
	_start_wandering()


func _load_the_round(is_ref: bool):
	reference = is_ref
	if map_node:
		remove_child(map_node)
		map_node.queue_free()
	var script: GDScript = load(map_deets["script"])
	map_node = script.new()
	map_node.name = "Map"
	add_child(map_node)
	map_node.build()
	var lib: Array = map_node.make_the_anomaly_list()
	var applied: Array = []
	if not is_ref:
		var the_plan: Array = manager.cook_up_plan(lib, diff, int(map_deets.get("bonus", 0)))
		var rebuild = false
		for a in the_plan:
			if a.pre and a.apply():
				applied.append(a)
				rebuild = true
		if rebuild:
			map_node.build()
		for a in the_plan:
			if not a.pre and a.apply():
				applied.append(a)
	manager.lock_it_in(applied, is_ref)
	map_node.exit_zone.set_meta("prompt", "[E]  ENTER THE CORRIDOR" if is_ref else "[E]  REPORT ANOMALIES")
	map_node.exit_zone.set_meta("on_interact", _on_exit_clicked)
	player.footstep_pitch = map_node.footstep_pitch()
	player.beam_me_up(map_node.spawn_spot)
	time_remaining_lol = float(diff["time_limit"])
	cheated_with_hint = false
	_synth_tick = 0
	_poke_hud()
	var nerd_label = "DEBUG (F10) seed %d — %d anomalies:\n" % [manager.dice_seed, manager.how_many_really()]
	for d in manager.gimme_descriptions():
		nerd_label += "• " + str(d) + "\n"
	hud.set_nerd_stuff(nerd_label)
	if OS.is_debug_build():
		print("[раунд] ", "эталон" if is_ref else "раунд %d" % level, ": ", manager.how_many_really(), " аномалий ", manager.fingerprint(manager.active))


func _is_it_timed() -> bool:
	return not reference and float(diff["time_limit"]) > 0.0


func _poke_hud():
	if reference:
		hud.show_round_num("REFERENCE", "This corridor is normal. Memorize it, then use the door at the end.")
	else:
		var best = maxi(Game.progress.best_score_for_this_map(map_deets["id"], diff["id"]), cleared)
		hud.show_round_num("%s  %02d" % [map_deets["unit"], level], "Cleared: %d     Best: %d" % [cleared, best])
	hud.show_oopsies(oopsies_left)
	hud.show_clock_ticking(time_remaining_lol, _is_it_timed())


func _start_wandering():
	vibe_check = State.EXPLORE
	player.can_i_move_lol = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Sfx.play(map_node.arrival_noise(), -12.0)
	if reference:
		var sub = "Everything here is exactly as it should be. Remember it."
		if map_deets["id"] == "underground":
			sub += "  Press F for your flashlight."
		hud.yell_banner("REFERENCE CORRIDOR", sub, 3.5)
		hud.toggle_help_text(true)
	else:
		hud.yell_banner("%s  %02d" % [map_deets["unit"], level], "Count every difference. Report at the exit.", 2.2)
		hud.toggle_help_text(false)


func _process(delta: float):
	if vibe_check != State.EXPLORE or not _is_it_timed():
		return
	time_remaining_lol -= delta
	hud.show_clock_ticking(time_remaining_lol, true)
	var sec = int(ceilf(time_remaining_lol))
	if time_remaining_lol <= 10.0 and sec != _synth_tick and sec > 0:
		_synth_tick = sec
		Sfx.play("tick", -2.0, 0.8)
	if time_remaining_lol <= 0.0:
		_judge_the_player(-1)


func _unhandled_input(e: InputEvent):
	if e.is_action_pressed("pause") and vibe_check == State.EXPLORE:
		_pause_pls(true)
	elif e.is_action_pressed("hint") and vibe_check == State.EXPLORE:
		_hint_pls()
	elif e.is_action_pressed("debug") and Game.nerd_mode:
		hud.flip_nerd_stuff()


func _pause_pls(on: bool):
	if on:
		vibe_check = State.PAUSED
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.show_pause_screen_lol(true)
	elif vibe_check == State.PAUSED:
		get_tree().paused = false
		hud.show_pause_screen_lol(false)
		vibe_check = State.EXPLORE
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _hint_pls():
	if not bool(diff["hints"]):
		return
	if reference:
		hud.whisper_hint("This is the reference corridor. Nothing here is wrong — yet.")
		return
	if cheated_with_hint:
		hud.whisper_hint("You have already used the hint for this corridor.")
		return
	cheated_with_hint = true
	hud.whisper_hint(manager.hint())


func _on_exit_clicked():
	if vibe_check != State.EXPLORE:
		return
	if reference:
		_lets_gooo(_load_the_round.bind(false))
	else:
		vibe_check = State.SUBMIT
		player.can_i_move_lol = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.open_answer_box()


func _on_submit_nvm():
	if vibe_check != State.SUBMIT:
		return
	vibe_check = State.EXPLORE
	player.can_i_move_lol = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _judge_the_player(answer: int):
	if vibe_check != State.SUBMIT and vibe_check != State.EXPLORE:
		return
	var timeout = answer < 0
	var ok = (not timeout) and manager.is_answer_right(answer)
	player.can_i_move_lol = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var footer = ""
	_over = false
	if ok:
		cleared += 1
		var opened: String = Game.progress.when_we_win_round(map_deets["id"], diff["id"], cleared)
		Sfx.play("chime_ok", -4.0)
		footer = "Corridor cleared. The next one will be different."
		if opened != "":
			hud.pop_toast("NEW MAP UNLOCKED:  " + opened)
			footer += "  New map unlocked: " + opened + "."
	else:
		Game.progress.oopsie_happened()
		Sfx.play("wrong", -2.0)
		if oopsies_left <= 0:
			_over = true
			footer = "No mistakes left. The protocol ends here."
		else:
			oopsies_left -= 1
			footer = "You will be sent back to the original corridor. Study it again — then try once more."
	_last_ok = ok
	vibe_check = State.RESULT
	hud.show_oopsies(oopsies_left)
	var kind = "correct" if ok else ("timeout" if timeout else "wrong")
	hud.show_the_verdict(kind, answer, manager.how_many_really(), manager.gimme_descriptions(), footer, _over)


func _on_verdict_gone():
	if vibe_check != State.RESULT:
		return
	if _over:
		_rip_game()
	elif _last_ok:
		level += 1
		_lets_gooo(_load_the_round.bind(false))
	else:
		_lets_gooo(_load_the_round.bind(true))


func _lets_gooo(build: Callable):
	vibe_check = State.TRANSITION
	player.can_i_move_lol = false
	hud.show_prompt_text("")
	Sfx.play("door_open", -8.0)
	await Game.go_dark(0.7)
	build.call()
	Sfx.play("door_close", -10.0)
	await get_tree().create_timer(0.3).timeout
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await Game.come_back_to_light(0.9)
	_start_wandering()


func _rip_game():
	vibe_check = State.OVER
	var best: int = Game.progress.best_score_for_this_map(map_deets["id"], diff["id"])
	hud.show_rip_screen(map_deets["title"], diff["title"], cleared, best, cleared > _best_before)
	Sfx.play("boom", -4.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
