extends Node3D

const Manager = preload("res://скрипты/аномалии/менеджер_аномалий.gd")
const Difficulty = preload("res://скрипты/сложность/сложность.gd")
const Catalog = preload("res://скрипты/карты/каталог_карт.gd")
const Player = preload("res://скрипты/игрок/игрок.gd")
const HUD = preload("res://скрипты/интерфейс/интерфейс_игры.gd")
const Loc = preload("res://скрипты/ядро/локализация.gd")
const Tutorial = preload("res://скрипты/генерация/обучение.gd")
const Chase = preload("res://скрипты/генерация/погоня.gd")
const ScreenFx = preload("res://скрипты/эффекты/экран.gd")

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

var chase_thing: Node
var chase_loaded = false
var chase_happened = false

var _last_ok = false
var _over = false
var _synth_tick = 0
var _best_before = 0
var _ui_lang = ""
var tutorial: Node
var fx: CanvasLayer
var _heart_t = 0.0


func _ready():
	map_deets = Catalog.gimme_map(Game.progress.picked_map)
	if not Game.progress.is_it_open_yet(map_deets["id"]) or Game.tutorial_mode:
		map_deets = Catalog.LIST[0]
	diff = Difficulty.gimme_difficulty("easy" if Game.tutorial_mode else Game.progress.picked_difficulty)
	oopsies_left = 99 if Game.tutorial_mode else int(diff["mistakes"])
	if Game.chase_mode:
		oopsies_left = 0
	_best_before = Game.progress.best_score_for_this_map(_score_map(), _score_id())

	player = Player.new()
	player.name = "Player"
	add_child(player)
	fx = ScreenFx.new()
	fx.name = "ScreenFx"
	add_child(fx)
	hud = HUD.new()
	add_child(hud)
	_setup_hud()
	_ui_lang = str(Game.setting("language"))
	Game.settings_got_changed.connect(_on_settings_changed)
	hud.answer_sent.connect(_judge_the_player)
	hud.answer_nvm.connect(_on_submit_nvm)
	hud.result_closed.connect(_on_verdict_gone)
	hud.wants_back.connect(_pause_pls.bind(false))
	hud.wants_again.connect(func(): Game.yeet_to_scene(Game.GAME_SCENE))
	hud.wants_out.connect(func(): Game.yeet_to_scene(Game.MENU_SCENE))
	player.prompt_flipped.connect(hud.show_prompt_text)

	if Game.tutorial_mode:
		tutorial = Tutorial.new()
		tutorial.name = "Tutorial"
		add_child(tutorial)
		tutorial.setup(self)
	else:
		Game.progress.when_run_starts_lol(map_deets["id"])
	Sfx.set_bg_music("")
	_load_the_round(not Game.chase_mode)  # в режиме погони эталонный коридор не нужен
	Sfx.set_bg_noise(map_node.background_noise(), -8.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await Game.come_back_to_light(1.0)
	_start_wandering()


# Под каким именем хранится рекорд: в режиме погони свой, не сложность
func _score_id() -> String:
	return "chase" if Game.chase_mode else str(diff["id"])


# В режиме погони рекорд общий на все карты (забег = карта, карты идут по кругу)
func _score_map() -> String:
	return "all" if Game.chase_mode else str(map_deets["id"])


func _exit_prompt() -> String:
	if Game.chase_mode:
		return Loc.t("[E]  ESCAPE")
	return Loc.t("[E]  ENTER THE CORRIDOR") if reference else Loc.t("[E]  REPORT ANOMALIES")


func _setup_hud():
	if Game.chase_mode:
		hud.setup(Loc.t("CHASE MODE") + "   ·   " + Loc.t(map_deets["title"]), 0, false)
	elif Game.tutorial_mode:
		hud.setup(Loc.t("TRAINING") + "   ·   " + Loc.t(map_deets["title"]), 0, true)
	else:
		hud.setup(Loc.t(map_deets["title"]) + "   ·   " + Loc.t(diff["title"]), int(diff["mistakes"]), bool(diff["hints"]))


# Для обучения: всегда одна заметная аномалия — красная лампа в начале коридора.
func _tutorial_plan(lib: Array) -> Array:
	var pick = null
	for a in lib:
		if a.id == "lamp_red:lamp_L1":
			pick = a
			break
		if pick == null and a.kind == "lamp_red":
			pick = a
	return [pick] if pick != null else []


# Смена языка из настроек на паузе: пересобираем интерфейс и возвращаем паузу с настройками.
func _on_settings_changed():
	var lang = str(Game.setting("language"))
	if lang == _ui_lang:
		return
	_ui_lang = lang
	_relang.call_deferred()


func _relang():
	hud.rebuild()
	_setup_hud()
	_poke_hud()
	if tutorial:
		tutorial.reset_display()
	map_node.exit_zone.set_meta("prompt", _exit_prompt())
	if vibe_check == State.PAUSED:
		hud.show_pause_screen_lol(true)
		hud.open_settings()


func _load_the_round(is_ref: bool):
	reference = is_ref
	_kill_chase()
	if Game.chase_mode:
		chase_loaded = true  # в режиме погони монстр приходит в каждом забеге
	else:
		chase_loaded = (not is_ref) and (not Game.tutorial_mode) and (not chase_happened) and level >= 2 and randf() < 0.5
	if map_node:
		remove_child(map_node)
		map_node.queue_free()
	var script: GDScript = load(map_deets["script"])
	map_node = script.new()
	map_node.name = "Map"
	add_child(map_node)
	map_node.build()
	if Game.chase_mode:  # карта могла смениться: обновляем заголовок и звук
		_setup_hud()
		Sfx.set_bg_noise(map_node.background_noise(), -8.0)
	var lib: Array = map_node.make_the_anomaly_list()
	var applied: Array = []
	if not is_ref:
		var the_plan: Array = []
		if Game.tutorial_mode:
			the_plan = _tutorial_plan(lib)
		elif not Game.chase_mode:  # в режиме погони аномалий нет
			the_plan = manager.cook_up_plan(lib, diff, int(map_deets.get("bonus", 0)))
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
	map_node.exit_zone.set_meta("prompt", _exit_prompt())
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
	return not reference and not Game.chase_mode and float(diff["time_limit"]) > 0.0


func _poke_hud():
	if Game.chase_mode:
		var best_run = maxi(Game.progress.best_score_for_this_map(_score_map(), "chase"), cleared)
		hud.show_round_num("%s  %02d" % [Loc.t("RUN"), level], Loc.t("Escaped: %d     Best: %d") % [cleared, best_run])
	elif reference:
		hud.show_round_num(Loc.t("REFERENCE"), Loc.t("This corridor is normal. Memorize it, then use the door at the end."))
	elif Game.tutorial_mode:
		hud.show_round_num(Loc.t("TRAINING"), Loc.t("One thing is different here. Find it, then report at the exit."))
	else:
		var best = maxi(Game.progress.best_score_for_this_map(map_deets["id"], diff["id"]), cleared)
		hud.show_round_num("%s  %02d" % [Loc.t(map_deets["unit"]), level], Loc.t("Cleared: %d     Best: %d") % [cleared, best])
	hud.show_oopsies(oopsies_left)
	hud.show_clock_ticking(time_remaining_lol, _is_it_timed())


func _start_wandering():
	vibe_check = State.EXPLORE
	player.can_i_move_lol = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Sfx.play(map_node.arrival_noise(), -12.0)
	if Game.chase_mode:
		var run_sub = Loc.t("Something is coming. Get to the exit.")
		if map_deets["id"] == "underground":
			run_sub += Loc.t("  Press F for your flashlight.")
		hud.yell_banner("%s  %02d" % [Loc.t("RUN"), level], run_sub, 2.2)
		hud.toggle_help_text(false)
	elif reference:
		var sub = Loc.t("Everything here is exactly as it should be. Remember it.")
		if map_deets["id"] == "underground":
			sub += Loc.t("  Press F for your flashlight.")
		hud.yell_banner(Loc.t("REFERENCE CORRIDOR"), sub, 3.5)
		hud.toggle_help_text(true)
	else:
		hud.yell_banner("%s  %02d" % [Loc.t(map_deets["unit"]), level], Loc.t("Count every difference. Report at the exit."), 2.2)
		hud.toggle_help_text(false)


# Жуть: искажение рядом с аномалией-«warp», страх при малом времени, сердцебиение.
func _spooky_tick(delta: float):
	if fx == null:
		return
	var exploring = vibe_check == State.EXPLORE
	var w = 0.0
	if exploring and map_node and player:
		w = map_node.warp_amount(player.global_position)
	fx.set_warp(w)
	var d = 0.0
	if exploring and _is_it_timed() and time_remaining_lol < 20.0:
		d = 1.0 - clampf(time_remaining_lol / 20.0, 0.0, 1.0)
	fx.dread = lerpf(fx.dread, d, clampf(delta * 2.0, 0.0, 1.0))
	var fear = maxf(w, d)
	if exploring and fear > 0.3:
		_heart_t -= delta
		if _heart_t <= 0.0:
			Sfx.play("heartbeat", -16.0 + fear * 12.0)
			_heart_t = 1.3 - fear * 0.5
	else:
		_heart_t = 0.0


func _kill_chase():
	if is_instance_valid(chase_thing):
		chase_thing.go_away()
	chase_thing = null
	if player:
		player.speed_mult = 1.0


# Погоня бывает один раз за забег, когда игрок уже немного прошёл по коридору
func _should_monster_pop():
	if not chase_loaded or chase_thing != null or Game.tutorial_mode or reference:
		return
	var sp: Vector3 = map_node.spawn_spot.origin
	var ex: Vector3 = map_node.exit_zone.global_position
	var total = sp.z - ex.z
	var walked = sp.z - player.global_position.z
	var start_at = clampf(total * 0.3, 12.0, 20.0)
	if Game.chase_mode:
		start_at = 3.0  # в режиме погони монстр приходит почти сразу
	elif total < 30.0:
		return
	if walked >= start_at:
		chase_loaded = false
		chase_happened = true
		chase_thing = Chase.new()
		chase_thing.name = "Chase"
		if Game.chase_mode:
			chase_thing.head_start = 9.0
			chase_thing.rage = minf((level - 1) * 0.25, 0.9)  # каждый забег дядя быстрее
		add_child(chase_thing)
		chase_thing.summon(player, ex)
		chase_thing.got_eaten.connect(_on_eaten)
		hud.yell_banner(Loc.t("IT SEES YOU"), Loc.t("Run to the exit. Avoid the rifts."), 2.5)


func _on_eaten():
	if vibe_check != State.EXPLORE:
		return
	vibe_check = State.TRANSITION
	await Game.go_dark(0.4)
	_kill_chase()
	_rip_game()
	await Game.come_back_to_light(0.6)


func _process(delta: float):
	_spooky_tick(delta)
	if vibe_check == State.EXPLORE:
		_should_monster_pop()
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
	if Game.chase_mode or not bool(diff["hints"]):
		return
	if reference:
		hud.whisper_hint(Loc.t("This is the reference corridor. Nothing here is wrong — yet."))
		return
	if cheated_with_hint:
		hud.whisper_hint(Loc.t("You have already used the hint for this corridor."))
		return
	cheated_with_hint = true
	fx.kick_glitch(0.35)
	Sfx.play("glitch", -16.0)
	hud.whisper_hint(manager.hint())


func _on_exit_clicked():
	if vibe_check != State.EXPLORE:
		return
	_kill_chase()
	if Game.chase_mode:
		_outran_the_monster()
	elif reference:
		_lets_gooo(_load_the_round.bind(false))
	else:
		vibe_check = State.SUBMIT
		player.can_i_move_lol = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.open_answer_box()


# Режим погони: добежал до двери - следующий забег, монстр быстрее
func _outran_the_monster():
	cleared += 1
	Game.progress.when_we_outrun_monster(_score_map(), cleared)
	Sfx.play("chime_ok", -4.0)
	level += 1
	# 1 забег = 1 карта: следующий забег на следующей карте, после последней снова с первой
	var idx = 0
	for i in Catalog.LIST.size():
		if Catalog.LIST[i]["id"] == map_deets["id"]:
			idx = i
	map_deets = Catalog.LIST[(idx + 1) % Catalog.LIST.size()]
	hud.pop_toast(Loc.t("Escaped. The next run will be faster."))
	_lets_gooo(_load_the_round.bind(false))


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
	if Game.tutorial_mode:
		# Обучение: статистика и открытие карт не трогаются, ошибки ничего не стоят.
		Sfx.play("chime_ok" if ok else "wrong", -4.0)
		if ok:
			footer = Loc.t("Well done! You found the anomaly and filed the report. That is the whole game: remember, compare, report. Training complete.")
		else:
			footer = Loc.t("Not quite. The training corridor has exactly one anomaly. Back to the reference corridor, look once more.")
	elif ok:
		cleared += 1
		var opened: String = Game.progress.when_we_win_round(map_deets["id"], diff["id"], cleared)
		Sfx.play("chime_ok", -4.0)
		footer = Loc.t("Corridor cleared. The next one will be different.")
		if opened != "":
			hud.pop_toast(Loc.t("NEW MAP UNLOCKED:  ") + Loc.t(opened))
			footer += Loc.t("  New map unlocked: ") + Loc.t(opened) + "."
	else:
		Game.progress.oopsie_happened()
		Sfx.play("wrong", -2.0)
		if oopsies_left <= 0:
			_over = true
			footer = Loc.t("No mistakes left. The protocol ends here.")
		else:
			oopsies_left -= 1
			footer = Loc.t("You will be sent back to the original corridor. Study it again — then try once more.")
	if ok:
		fx.kick_glitch(0.2)
	else:
		fx.kick_glitch(1.0)
		fx.flash_red(0.85)
		Sfx.play("sting", -4.0)
	_last_ok = ok
	vibe_check = State.RESULT
	hud.show_oopsies(oopsies_left)
	var kind = "correct" if ok else ("timeout" if timeout else "wrong")
	hud.show_the_verdict(kind, answer, manager.how_many_really(), manager.gimme_descriptions(), footer, _over)


func _on_verdict_gone():
	if vibe_check != State.RESULT:
		return
	if Game.tutorial_mode and _last_ok:
		Game.tutorial_mode = false
		Game.yeet_to_scene(Game.MENU_SCENE)
	elif _over:
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
	fx.kick_glitch(0.6)
	Sfx.play("glitch", -14.0)
	await Game.go_dark(0.7)
	build.call()
	Sfx.play("door_close", -10.0)
	await get_tree().create_timer(0.3).timeout
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await Game.come_back_to_light(0.9)
	_start_wandering()


func _rip_game():
	vibe_check = State.OVER
	var best: int = Game.progress.best_score_for_this_map(_score_map(), _score_id())
	var mode_title = Loc.t("CHASE MODE") if Game.chase_mode else Loc.t(diff["title"])
	hud.show_rip_screen(Loc.t(map_deets["title"]), mode_title, cleared, best, cleared > _best_before)
	Sfx.play("boom", -4.0)
	fx.red_hold = 0.35
	fx.kick_glitch(1.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
