extends Node

const Manager = preload("res://скрипты/аномалии/менеджер_аномалий.gd")
const Difficulty = preload("res://скрипты/сложность/сложность.gd")
const Catalog = preload("res://скрипты/карты/каталог_карт.gd")
const Progress = preload("res://скрипты/прогресс/прогресс.gd")

const REQUIRED = {"hotel": 20, "station": 15, "underground": 15}

var fails = 0
var checks = 0


func _ready():
	await get_tree().process_frame
	var only = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			only = arg.substr(6)
	for m in Catalog.LIST:
		if only != "" and m["id"] != only:
			continue
		if not ResourceLoader.exists(m["script"]):
			print("[skip] нет скрипта карты: ", m["id"])
			continue
		await _test_one_map(m)
	_test_progress_lol()
	if only == "" or only == "gameplay":
		await _test_gameplay_lol()
	print("")
	print("==== ИТОГ: %s  (проверок: %d, ошибок: %d)" % ["PASS" if fails == 0 else "FAIL", checks, fails])
	get_tree().quit(1 if fails > 0 else 0)


func check_stuff(cond: bool, msg: String):
	checks += 1
	if not cond:
		fails += 1
		printerr("  FAIL: " + msg)


func _test_one_map(m: Dictionary):
	print("")
	print("=== КАРТА: ", m["id"])
	var t0 = Time.get_ticks_msec()
	var script: GDScript = load(m["script"])
	check_stuff(script != null and script.can_instantiate(), "скрипт карты не загрузился")
	if script == null or not script.can_instantiate():
		return
	var map = script.new()
	add_child(map)
	map.build()
	print("  постройка: %d мс (с генерацией текстур), узлов: %d" % [Time.get_ticks_msec() - t0, _count_lol(map)])
	t0 = Time.get_ticks_msec()
	map.build()
	print("  перестройка: %d мс" % (Time.get_ticks_msec() - t0))
	check_stuff(map.exit_zone != null, "нет зоны выхода")
	var lib: Array = map.make_the_anomaly_list()
	var kinds = {}
	var cats = {}
	for a in lib:
		kinds[a.kind] = true
		cats[a.category] = int(cats.get(a.category, 0)) + 1
	print("  аномалий: %d вариантов, %d типов; по категориям: %s" % [lib.size(), kinds.size(), str(cats)])
	check_stuff(kinds.size() >= int(REQUIRED[m["id"]]), "мало типов аномалий: %d" % kinds.size())

	var id_list = {}
	for a in lib:
		check_stuff(not id_list.has(a.id), "дубликат id: " + a.id)
		id_list[a.id] = true
		map.params = map.default_stuff()
		map.build()
		var ok: bool = a.apply()
		if a.pre:
			map.build()
		check_stuff(ok, "аномалия не применилась: " + a.id)
	map.params = map.default_stuff()
	map.build()

	var bonus: int = m.get("bonus", 0)
	for d in Difficulty.ORDER:
		var diff = Difficulty.gimme_difficulty(d)
		var boss_manager = Manager.new()
		var hist = {}
		var max_allowed: int = (diff["count_weights"] as Array).size() - 1 + bonus
		var subt_sum = 0.0
		var subt_n = 0
		for r in 500:
			var the_plan: Array = boss_manager.cook_up_plan(lib, diff, bonus)
			var seen_kinds = {}
			var seen_tags = {}
			for a in the_plan:
				check_stuff(not seen_kinds.has(a.kind), "повтор типа %s в раунде" % a.kind)
				seen_kinds[a.kind] = true
				for t in a.tags:
					check_stuff(not seen_tags.has(t), "конфликт по объекту %s" % t)
					seen_tags[t] = true
				subt_sum += a.subtlety
				subt_n += 1
			check_stuff(the_plan.size() <= max_allowed, "слишком много аномалий: %d" % the_plan.size())
			boss_manager.lock_it_in(the_plan)
			check_stuff(boss_manager.is_answer_right(the_plan.size()), "верный ответ не принят")
			check_stuff(not boss_manager.is_answer_right(the_plan.size() + 1), "неверный ответ принят")
			hist[the_plan.size()] = int(hist.get(the_plan.size(), 0)) + 1
		check_stuff(hist.has(0), "нет раундов без аномалий (%s)" % d)
		var keys = hist.keys()
		keys.sort()
		var parts = []
		for k in keys:
			parts.append("%d:%d" % [k, hist[k]])
		print("  %-6s распределение количества: %s  средняя заметность: %.2f" % [d, " ".join(parts), subt_sum / maxf(subt_n, 1)])

	var m1 = Manager.new()
	var m2 = Manager.new()
	var diffn = Difficulty.gimme_difficulty("hard")
	var s1: String = m1.fingerprint(m1.cook_up_plan(lib, diffn, bonus, 4242))
	var s2: String = m2.fingerprint(m2.cook_up_plan(lib, diffn, bonus, 4242))
	check_stuff(s1 == s2, "генерация не детерминирована по зерну")

	var boss_manager_2 = Manager.new()
	for r in 40:
		map.params = map.default_stuff()
		map.build()
		var the_plan: Array = boss_manager_2.cook_up_plan(lib, Difficulty.gimme_difficulty("hard"), bonus)
		var applied: Array = []
		var rebuild = false
		for a in the_plan:
			if a.pre and a.apply():
				applied.append(a)
				rebuild = true
		if rebuild:
			map.build()
		for a in the_plan:
			if not a.pre and a.apply():
				applied.append(a)
		check_stuff(applied.size() == the_plan.size(), "в сцене применилось %d из %d" % [applied.size(), the_plan.size()])
		boss_manager_2.lock_it_in(applied)
		check_stuff(boss_manager_2.how_many_really() == applied.size(), "счётчик не совпадает со сценой")
	map.queue_free()
	await get_tree().process_frame


func _test_progress_lol():
	print("")
	print("=== ПРОГРЕСС")
	var p = Progress.new()
	p.path = "user://test_progress.cfg"
	p.nuke_progress()
	p.when_run_starts_lol("hotel")
	var opened = ""
	for i in Catalog.UNLOCK_ROUNDS:
		opened = p.when_we_win_round("hotel", "normal", i + 1)
	p.oopsie_happened()
	var q = Progress.new()
	q.path = p.path
	q.dig_up_save()
	check_stuff(q.best_score_for_this_map("hotel", "normal") == Catalog.UNLOCK_ROUNDS, "лучший результат не сохранился")
	check_stuff(q.oopsies_total_lol == 1, "ошибки не сохранились")
	check_stuff(q.is_it_open_yet("station"), "следующая карта не открылась")
	check_stuff(opened == "THE STATION", "не сообщили об открытии карты")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p.path))
	print("  ок")


func _wait_for_state(game: Node, st: int, timeout = 8.0) -> bool:
	var t = 0.0
	while game.vibe_check != st and t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time()
	return game.vibe_check == st


func _test_gameplay_lol():
	print("")
	print("=== ИГРОВОЙ ЦИКЛ")
	var where_i_saved: String = Game.progress.path
	Game.progress.path = "user://test_gameplay.cfg"
	Game.progress.nuke_progress()
	Game.progress.open_maps = ["hotel", "station", "underground"]
	for m in Catalog.LIST:
		Game.progress.picked_map = m["id"]
		Game.progress.picked_difficulty = "normal"
		var g: Node = load("res://сцены/игра/игра.tscn").instantiate()
		add_child(g)
		check_stuff(await _wait_for_state(g, g.State.EXPLORE), "%s: игра не началась" % m["id"])
		for i in 30:
			await get_tree().physics_frame
		var pl: CharacterBody3D = g.player
		check_stuff(pl.is_on_floor() and pl.global_position.y > -0.3, "%s: игрок не стоит на полу (y=%.2f)" % [m["id"], pl.global_position.y])
		var ex: Area3D = g.map_node.exit_zone
		var stand = ex.global_position + Vector3(0, -1.2, 1.6)
		pl.beam_me_up(Transform3D(Basis(), stand))
		for i in 6:
			await get_tree().physics_frame
		check_stuff(pl._prompt != "", "%s: луч игрока не видит дверь-выход" % m["id"])
		pl._poke_it()
		check_stuff(await _wait_for_state(g, g.State.EXPLORE), "%s: дверь не сработала" % m["id"])
		check_stuff(not g.reference, "%s: после двери не начался раунд" % m["id"])
		g.queue_free()
		await get_tree().process_frame
		print("  %s: пол, луч и дверь — ок" % m["id"])
	for d in Difficulty.ORDER:
		Game.progress.picked_map = "hotel"
		Game.progress.picked_difficulty = d
		var diff = Difficulty.gimme_difficulty(d)
		var game: Node = load("res://сцены/игра/игра.tscn").instantiate()
		add_child(game)
		var S = game.State
		check_stuff(await _wait_for_state(game, S.EXPLORE), "%s: игра не началась" % d)
		check_stuff(game.reference, "%s: первый коридор не эталон" % d)
		check_stuff(game.manager.how_many_really() == 0, "%s: в эталоне есть аномалии" % d)
		check_stuff(not game._is_it_timed(), "%s: таймер в эталоне" % d)
		game._on_exit_clicked()
		check_stuff(await _wait_for_state(game, S.EXPLORE), "%s: не перешли в раунд" % d)
		check_stuff(not game.reference and game.level == 1, "%s: не раунд 1" % d)
		check_stuff(game._is_it_timed() == (float(diff["time_limit"]) > 0.0), "%s: таймер не соответствует сложности" % d)
		game._on_exit_clicked()
		check_stuff(game.vibe_check == S.SUBMIT, "%s: окно отчёта не открылось" % d)
		game.hud.submit_layer.visible = false
		game._judge_the_player(game.manager.how_many_really())
		check_stuff(game.vibe_check == S.RESULT and game.cleared == 1, "%s: верный ответ не засчитан" % d)
		game.hud.result_layer.visible = false
		game._on_verdict_gone()
		check_stuff(await _wait_for_state(game, S.EXPLORE), "%s: не перешли в раунд 2" % d)
		check_stuff(game.level == 2 and not game.reference, "%s: не раунд 2" % d)
		var allowed: int = diff["mistakes"]
		for i in allowed + 1:
			game._on_exit_clicked()
			game.hud.submit_layer.visible = false
			game._judge_the_player(game.manager.how_many_really() + 1)
			check_stuff(game.vibe_check == S.RESULT, "%s: неверный ответ не обработан" % d)
			game.hud.result_layer.visible = false
			if i < allowed:
				check_stuff(game.oopsies_left == allowed - i - 1, "%s: неверный счёт ошибок" % d)
				game._on_verdict_gone()
				check_stuff(await _wait_for_state(game, S.EXPLORE), "%s: не вернулись после ошибки" % d)
				check_stuff(game.reference, "%s: после ошибки нет возврата к эталону" % d)
				game._on_exit_clicked()
				check_stuff(await _wait_for_state(game, S.EXPLORE), "%s: эталон → раунд после ошибки" % d)
				check_stuff(game.level == 2, "%s: номер раунда сбился после ошибки" % d)
			else:
				game._on_verdict_gone()
				check_stuff(game.vibe_check == S.OVER, "%s: забег не закончился" % d)
		check_stuff(Game.progress.best_score_for_this_map("hotel", d) == 1, "%s: лучший результат не сохранён" % d)
		game.queue_free()
		await get_tree().process_frame
		print("  %s: ок" % d)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.progress.path))
	Game.progress.path = where_i_saved
	Game.progress.dig_up_save()


func _count_lol(n: Node) -> int:
	var c = 1
	for ch in n.get_children():
		c += _count_lol(ch)
	return c
