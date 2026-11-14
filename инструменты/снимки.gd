extends Node

const Catalog = preload("res://скрипты/карты/каталог_карт.gd")
const Manager = preload("res://скрипты/аномалии/менеджер_аномалий.gd")
const Difficulty = preload("res://скрипты/сложность/сложность.gd")

var out_dir = ""
var just_this_map = ""
var only = ""


func _ready():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--map="):
			just_this_map = arg.substr(6)
		elif arg.begins_with("--only="):
			only = arg.substr(7)
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("user://снимки")
	DirAccess.make_dir_recursive_absolute(out_dir)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ассеты/текстуры/превью"))
	Game.progress.path = "user://shots_progress.cfg"
	get_window().size = Vector2i(1600, 900)
	await Game.come_back_to_light(0.01)
	for m in Catalog.LIST:
		if just_this_map != "" and m["id"] != just_this_map:
			continue
		if not ResourceLoader.exists(m["script"]):
			continue
		if only == "" or only == "previews" or only == "maps":
			await _snap_map(m)
		if only == "" or only == "anomalies":
			await _snap_anomalies(m)
	if only == "" or only == "ui":
		await _snap_ui()
	print("Снимки готовы: ", out_dir)
	get_tree().quit()


func _wait_frames(n: int):
	for i in n:
		await get_tree().process_frame


func _save_it(name: String):
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))


func _snap_map(m: Dictionary):
	var map = load(m["script"]).new()
	add_child(map)
	map.build()
	var cam = Camera3D.new()
	cam.fov = 70.0
	add_child(cam)
	cam.current = true
	var snapshot_lol: Array = map.preview_pic()
	cam.look_at_from_position(snapshot_lol[0], snapshot_lol[1])
	await _wait_frames(30)
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	var prev = img.duplicate() as Image
	prev.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	prev.save_png(ProjectSettings.globalize_path(m["preview"]))
	img.save_png(out_dir.path_join(m["id"] + "_preview.png"))
	var photo_spots: Array = map.qa_pics() if map.has_method("qa_pics") else []
	for i in photo_spots.size():
		cam.look_at_from_position(photo_spots[i][0], photo_spots[i][1])
		await _wait_frames(8)
		await _save_it("%s_qa_%02d" % [m["id"], i])
	cam.queue_free()
	map.queue_free()
	await _wait_frames(2)


func _snap_anomalies(m: Dictionary):
	var map = load(m["script"]).new()
	add_child(map)
	map.build()
	var lib: Array = map.make_the_anomaly_list()
	var cam = Camera3D.new()
	cam.fov = 70.0
	add_child(cam)
	cam.current = true
	var seen = {}
	var which_one = 0
	for a in lib:
		if seen.has(a.kind):
			continue
		seen[a.kind] = true
		map.params = map.default_stuff()
		map.build()
		a.apply()
		if a.pre:
			map.build()
		var snapshot_lol: Array = map.preview_pic()
		if map.has_method("focus_pic"):
			snapshot_lol = map.focus_pic(a)
		cam.look_at_from_position(snapshot_lol[0], snapshot_lol[1])
		await _wait_frames(6)
		await _save_it("%s_an_%02d_%s" % [m["id"], which_one, a.kind])
		which_one += 1
	cam.queue_free()
	map.queue_free()
	await _wait_frames(2)


func _snap_ui():
	var menu: Node = load(Game.MENU_SCENE).instantiate()
	add_child(menu)
	await get_tree().create_timer(2.5).timeout
	await _save_it("ui_menu")
	menu._show_some_panel(menu._map_picker_panel())
	await get_tree().create_timer(0.8).timeout
	await _save_it("ui_map_select")
	menu._show_some_panel(menu._how_hard_panel())
	await get_tree().create_timer(0.8).timeout
	await _save_it("ui_difficulty")
	menu._open_settings_pls()
	await get_tree().create_timer(0.8).timeout
	await _save_it("ui_settings")
	menu.queue_free()
	await _wait_frames(3)

	Game.progress.picked_map = "hotel"
	var game: Node = load(Game.GAME_SCENE).instantiate()
	add_child(game)
	await get_tree().create_timer(3.0).timeout
	await _save_it("ui_game_reference")
	game._load_the_round(false)
	game._start_wandering()
	await get_tree().create_timer(1.0).timeout
	await _save_it("ui_game_round")
	game._on_exit_clicked()
	await get_tree().create_timer(0.6).timeout
	await _save_it("ui_submit")
	game.hud.submit_layer.visible = false
	game._judge_the_player(game.manager.how_many_really() + 1)
	await get_tree().create_timer(0.6).timeout
	await _save_it("ui_result_wrong")
	game.hud.result_layer.visible = false
	game.oopsies_left = 0
	game.vibe_check = game.State.SUBMIT
	game._judge_the_player(99)
	game.hud.result_layer.visible = false
	game._rip_game()
	await get_tree().create_timer(0.6).timeout
	await _save_it("ui_game_over")
	game.queue_free()
	await _wait_frames(3)
