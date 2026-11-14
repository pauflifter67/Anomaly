extends Node

const UI = preload("res://скрипты/интерфейс/стиль.gd")
const Catalog = preload("res://скрипты/карты/каталог_карт.gd")
const Difficulty = preload("res://скрипты/сложность/сложность.gd")
const SettingsPanel = preload("res://скрипты/интерфейс/панель_настроек.gd")
const HotelMap = preload("res://скрипты/карты/отель.gd")
const DEVELOPERS = ["Марат", "Мишель", "Саид", "Тамир"]

var cam: Camera3D
var bg_map: Node3D
var ui: Control
var panel_holder: Control
var panel_right_now: Control
var footer_lbl: Label
var stats_lbl: Label
var title_box: Control
var _t = 0.0
var _cam_first = Vector3.ZERO
var _cam_second = Vector3.ZERO


class MenuItem extends Button:
	var style = StyleBoxFlat.new()
	var bar: ColorRect
	var _col = 0.0

	func _init(txt: String):
		text = txt
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(380, 50)
		style.bg_color = Color(0, 0, 0, 0)
		style.content_margin_left = 0.0
		for s in ["normal", "hover", "pressed", "disabled"]:
			add_theme_stylebox_override(s, style)
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		add_theme_font_override("font", Game.font("wide"))
		add_theme_font_size_override("font_size", 23)
		_paint_it(0.0)
		bar = ColorRect.new()
		bar.color = UI.ACCENT
		bar.size = Vector2(0, 2)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		mouse_entered.connect(_mouse_is_over_me.bind(true))
		mouse_exited.connect(_mouse_is_over_me.bind(false))
		pressed.connect(func(): Sfx.play("click", -8.0))
		resized.connect(func(): bar.position = Vector2(0, size.y * 0.5 - 1.0))

	func _mouse_is_over_me(on: bool):
		if on:
			Sfx.play("hover", -16.0)
		var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(style, "content_margin_left", 40.0 if on else 0.0, 0.28)
		t.tween_property(bar, "size:x", 26.0 if on else 0.0, 0.28)
		t.tween_method(_paint_it, _col, 1.0 if on else 0.0, 0.2)

	func _paint_it(x: float):
		_col = x
		var c = UI.DIM.lerp(UI.TEXT, x)
		add_theme_color_override("font_color", c)
		add_theme_color_override("font_hover_color", c)
		add_theme_color_override("font_pressed_color", UI.ACCENT)


func _ready():
	get_tree().paused = false
	bg_map = HotelMap.new()
	add_child(bg_map)
	bg_map.build()
	bg_map._yeet_flicker("lamp_R6")
	cam = Camera3D.new()
	cam.fov = 60.0
	add_child(cam)
	cam.current = true
	var snapshot_lol: Array = bg_map.menu_pic()
	_cam_first = snapshot_lol[0]
	_cam_second = snapshot_lol[1]
	_process(0.0)

	var layer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	_cook_ui()

	Sfx.set_bg_noise("amb_hotel", -16.0)
	Sfx.set_bg_music("music_menu", -9.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await Game.come_back_to_light(1.4)


func _process(delta: float):
	_t += delta
	var k = 0.5 - 0.5 * cos(_t * 0.045)
	var pos = _cam_first.lerp(_cam_second, k)
	pos += Vector3(sin(_t * 0.21) * 0.05, sin(_t * 0.33) * 0.025, 0)
	cam.position = pos
	cam.rotation = Vector3(-0.03 + sin(_t * 0.17) * 0.012, sin(_t * 0.11) * 0.04, sin(_t * 0.07) * 0.004)


func _cook_ui():
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.8])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.93), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0.0)])
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.width = 256
	gt.height = 4
	var shade = TextureRect.new()
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	ui.add_child(UI.dark_corners(0.7))

	var title = VBoxContainer.new()
	title.position = Vector2(104, 120)
	title.add_theme_constant_override("separation", 6)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(title)
	title.add_child(UI.label("SECOND WIND", 82, UI.TEXT, "hero"))
	title.add_child(UI.label("ANOMALY  PROTOCOL", 20, UI.ACCENT, "wide"))
	title.add_child(UI.gap_thing(10))
	title.add_child(UI.line(64))
	title.add_child(UI.gap_thing(6))
	title.add_child(UI.label("OBSERVE.  REMEMBER.  SURVIVE.", 14, UI.DIM, "wide"))
	title_box = title

	var menu = VBoxContainer.new()
	menu.position = Vector2(100, 410)
	menu.add_theme_constant_override("separation", 2)
	ui.add_child(menu)
	var stuff_list = [
		["PLAY", _on_play_clicked_yay],
		["MAP SELECT", func(): _show_some_panel(_map_picker_panel())],
		["DIFFICULTY", func(): _show_some_panel(_how_hard_panel())],
		["SETTINGS", _open_settings_pls],
		["CREDITS", func(): _show_some_panel(_who_made_this_panel())],
		["QUIT", func(): get_tree().quit()],
	]
	for it in stuff_list:
		var b = MenuItem.new(it[0])
		b.pressed.connect(it[1])
		menu.add_child(b)

	footer_lbl = UI.label("", 13, UI.DIM, "wide")
	UI.anchor(footer_lbl, 0.0, 1.0, 104, -70, 1000, -44)
	ui.add_child(footer_lbl)
	stats_lbl = UI.label("", 12, UI.FAINT, "wide", HORIZONTAL_ALIGNMENT_RIGHT)
	UI.anchor(stats_lbl, 1.0, 1.0, -800, -84, -60, -36)
	stats_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	ui.add_child(stats_lbl)
	_refresh_bottom_text()

	panel_holder = Control.new()
	panel_holder.anchor_left = 0.37
	panel_holder.anchor_right = 0.975
	panel_holder.anchor_top = 0.09
	panel_holder.anchor_bottom = 0.93
	panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel_holder)


func _refresh_bottom_text():
	var m = Catalog.gimme_map(Game.progress.picked_map)
	var d = Difficulty.gimme_difficulty(Game.progress.picked_difficulty)
	footer_lbl.text = "MAP   %s        DIFFICULTY   %s        BEST   %d" % [m["title"], d["title"], Game.progress.best_score_for_this_map(m["id"], d["id"])]
	var p = Game.progress
	stats_lbl.text = "CORRIDORS CLEARED  %d     MISTAKES  %d     RUNS  %d\nHACK CLUB HAVEN  ·  BOUNCE BACK  ·  v%s" % [p.cleared_total_lol, p.oopsies_total_lol, p.runs_total_lol, ProjectSettings.get_setting("application/config/version", "0.1")]


func _unhandled_input(e: InputEvent):
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE and panel_right_now:
		_close_some_panel()


func _on_play_clicked_yay():
	if not Game.progress.is_it_open_yet(Game.progress.picked_map):
		Game.progress.picked_map = "hotel"
	Game.progress.stuff_save_in_box()
	Sfx.play("riser", -6.0)
	Sfx.set_bg_music("")
	Game.yeet_to_scene(Game.GAME_SCENE)


func _show_some_panel(p: Control):
	_close_some_panel(false)
	panel_right_now = p
	panel_holder.add_child(p)
	_fade_the_title(0.0)
	p.modulate.a = 0.0
	p.position.x = 40.0
	var t = p.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(p, "modulate:a", 1.0, 0.35)
	t.tween_property(p, "position:x", 0.0, 0.45)


func _close_some_panel(animate = true):
	if panel_right_now == null:
		return
	var p = panel_right_now
	panel_right_now = null
	if not animate:
		p.queue_free()
		return
	_fade_the_title(1.0)
	var t = p.create_tween()
	t.tween_property(p, "modulate:a", 0.0, 0.2)
	t.tween_callback(p.queue_free)


func _fade_the_title(a: float):
	var t = title_box.create_tween()
	t.tween_property(title_box, "modulate:a", a, 0.3)


func _open_settings_pls():
	var c = CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sp = SettingsPanel.new()
	sp.closed.connect(func(): _close_some_panel())
	c.add_child(sp)
	_show_some_panel(c)


func _make_header(v: VBoxContainer, title: String, sub: String):
	v.add_child(UI.label(title, 34, UI.TEXT, "title"))
	v.add_child(UI.line())
	v.add_child(UI.wrap_text_lol(sub, 15, UI.DIM, 880))
	v.add_child(UI.gap_thing(6))


func _make_back_button_row(v: VBoxContainer):
	v.add_child(UI.gap_thing(8))
	var h = HBoxContainer.new()
	v.add_child(h)
	var b = UI.button("BACK", 15, 160)
	b.pressed.connect(func(): _close_some_panel())
	h.add_child(b)


func _map_picker_panel() -> Control:
	var v = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 10)
	_make_header(v, "MAP SELECT", "Every map is a place to learn by heart. Clear %d corridors in one run to unlock the next map. Completed maps can be replayed at any time." % Catalog.UNLOCK_ROUNDS)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	v.add_child(h)
	for m in Catalog.LIST:
		h.add_child(_map_card_thingy(m))
	_make_back_button_row(v)
	return v


func _map_card_thingy(m: Dictionary) -> Control:
	var open_maps: bool = Game.progress.is_it_open_yet(m["id"])
	var selected: bool = Game.progress.picked_map == m["id"]
	var p = PanelContainer.new()
	var st = UI.panel_look(Color(0.03, 0.03, 0.035, 0.9), UI.ACCENT if selected else Color(1, 1, 1, 0.08), 2 if selected else 1, 0)
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(292, 0)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var img = TextureRect.new()
	img.custom_minimum_size = Vector2(292, 164)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.clip_contents = true
	if ResourceLoader.exists(m["preview"]):
		img.texture = load(m["preview"])
	else:
		var gt = GradientTexture2D.new()
		var g = Gradient.new()
		g.colors = PackedColorArray([Color(0.2, 0.15, 0.1), Color(0.02, 0.02, 0.02)])
		gt.gradient = g
		gt.fill_to = Vector2(0, 1)
		img.texture = gt
	if not open_maps:
		img.modulate = Color(0.25, 0.25, 0.28)
	v.add_child(img)
	var mc = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 18)
	v.add_child(mc)
	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	mc.add_child(inner)
	inner.add_child(UI.label(m["title"], 21, UI.TEXT if open_maps else UI.DIM, "wide"))
	inner.add_child(UI.label(m["subtitle"], 12, UI.ACCENT, "ui"))
	var desc = UI.wrap_text_lol(m["desc"], 14, UI.DIM, 256)
	desc.custom_minimum_size.y = 84
	inner.add_child(desc)
	inner.add_child(UI.label("RECOMMENDED   " + m["recommend"], 11, UI.FAINT, "wide"))
	var best_pile = []
	for d in Difficulty.ORDER:
		best_pile.append("%s %d" % [Difficulty.gimme_difficulty(d)["title"].substr(0, 1), Game.progress.best_score_for_this_map(m["id"], d)])
	inner.add_child(UI.label("BEST   " + "  ·  ".join(best_pile), 11, UI.FAINT, "wide"))
	var status = "SELECTED" if selected else ("UNLOCKED" if open_maps else "LOCKED")
	var col = UI.ACCENT if selected else (UI.GOOD if open_maps else UI.BAD)
	if not open_maps:
		var req = Catalog.gimme_map(m["requires"])
		inner.add_child(UI.label("LOCKED", 12, col, "wide"))
		inner.add_child(UI.wrap_text_lol("Clear %d corridors in one run in %s." % [Catalog.UNLOCK_ROUNDS, req["title"]], 12, UI.DIM, 256))
	else:
		inner.add_child(UI.label(status, 12, col, "wide"))
	inner.add_child(UI.gap_thing(6))
	var b = UI.button("SELECTED" if selected else "SELECT", 14, 256, not selected and open_maps)
	b.disabled = not open_maps or selected
	b.pressed.connect(func():
		Game.progress.picked_map = m["id"]
		Game.progress.stuff_save_in_box()
		_refresh_bottom_text()
		_show_some_panel(_map_picker_panel()))
	inner.add_child(b)
	return p


func _how_hard_panel() -> Control:
	var v = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 10)
	_make_header(v, "DIFFICULTY", "Difficulty changes how subtle the anomalies are, how many can appear at once, how much time you have and how many mistakes you can afford.")
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	v.add_child(h)
	for id in Difficulty.ORDER:
		var d = Difficulty.gimme_difficulty(id)
		var selected: bool = Game.progress.picked_difficulty == id
		var p = PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.panel_look(Color(0.03, 0.03, 0.035, 0.9), UI.ACCENT if selected else Color(1, 1, 1, 0.08), 2 if selected else 1, 22))
		p.custom_minimum_size = Vector2(292, 0)
		h.add_child(p)
		var inner = VBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		p.add_child(inner)
		inner.add_child(UI.label(d["title"], 28, UI.TEXT, "title"))
		inner.add_child(UI.label(d["tagline"], 16, UI.ACCENT, "serif"))
		inner.add_child(UI.gap_thing(4))
		for bullet in d["bullets"]:
			inner.add_child(UI.label("—  " + bullet, 14, UI.DIM, "ui"))
		inner.add_child(UI.gap_thing(8))
		var m = Catalog.gimme_map(Game.progress.picked_map)
		inner.add_child(UI.label("BEST ON %s   %d" % [m["title"], Game.progress.best_score_for_this_map(m["id"], id)], 11, UI.FAINT, "wide"))
		var b = UI.button("SELECTED" if selected else "SELECT", 14, 248, not selected)
		b.disabled = selected
		b.pressed.connect(func():
			Game.progress.picked_difficulty = id
			Game.progress.stuff_save_in_box()
			_refresh_bottom_text()
			_show_some_panel(_how_hard_panel()))
		inner.add_child(b)
	_make_back_button_row(v)
	return v


func _who_made_this_panel() -> Control:
	var v = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 10)
	_make_header(v, "CREDITS", "DEVELOPERS")
	for dev in DEVELOPERS:
		v.add_child(UI.label(dev, 24, UI.TEXT, "light"))
	_make_back_button_row(v)
	return v
