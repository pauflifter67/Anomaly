extends PanelContainer

signal closed

const UI = preload("res://скрипты/интерфейс/стиль.gd")
const Loc = preload("res://скрипты/ядро/локализация.gd")

var _quality_btns: Array = []
var _lang_btns = {}
var _reset_btn: Button
var _reset_armed = false


func _ready():
	add_theme_stylebox_override("panel", UI.panel_look(UI.BG, Color(1, 1, 1, 0.07), 1, 34))
	custom_minimum_size = Vector2(640, 0)
	_build()


func _build():
	_quality_btns.clear()
	_lang_btns.clear()
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	v.add_child(UI.label(Loc.t("SETTINGS"), 30, UI.TEXT, "title"))
	v.add_child(UI.line())
	v.add_child(UI.gap_thing(4))

	var lrow = _make_a_row(v, "LANGUAGE / ЯЗЫК")
	for lang in [["en", "ENGLISH"], ["ru", "РУССКИЙ"]]:
		var lb = UI.button(lang[1], 14, 130)
		lb.toggle_mode = true
		lb.pressed.connect(_pick_language.bind(lang[0]))
		lrow.add_child(lb)
		_lang_btns[lang[0]] = lb
	_sync_language()

	var qrow = _make_a_row(v, Loc.t("GRAPHICS"))
	for i in 3:
		var b = UI.button(Loc.t(["LOW", "MEDIUM", "HIGH"][i]), 14, 110)
		b.toggle_mode = true
		b.pressed.connect(_pick_fanciness.bind(i))
		qrow.add_child(b)
		_quality_btns.append(b)
	_sync_fanciness()

	_tickbox_thing(v, Loc.t("FULLSCREEN"), "fullscreen")
	_tickbox_thing(v, Loc.t("VSYNC"), "vsync")
	_tickbox_thing(v, Loc.t("HEAD BOB"), "head_bob")
	_tickbox_thing(v, Loc.t("SCREEN EFFECTS"), "fx")
	_slidey_boi(v, Loc.t("MOUSE SENSITIVITY"), "sensitivity", 0.05, 0.6, 0.01)
	_slidey_boi(v, Loc.t("FIELD OF VIEW"), "fov", 60.0, 100.0, 1.0)
	_slidey_boi(v, Loc.t("VOLUME"), "volume", 0.0, 1.0, 0.01)

	v.add_child(UI.gap_thing(6))
	var brow = HBoxContainer.new()
	brow.add_theme_constant_override("separation", 12)
	v.add_child(brow)
	_reset_btn = UI.button(Loc.t("RESET PROGRESS"), 13, 200)
	_reset_btn.pressed.connect(_on_big_red_button)
	brow.add_child(_reset_btn)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(sp)
	var back = UI.button(Loc.t("BACK"), 15, 150, true)
	back.pressed.connect(func(): closed.emit())
	brow.add_child(back)


func _make_a_row(parent: Node, title: String) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l = UI.label(title, 14, UI.DIM, "wide")
	l.custom_minimum_size.x = 230
	h.add_child(l)
	parent.add_child(h)
	return h


func _tickbox_thing(parent: Node, title: String, key: String):
	var h = _make_a_row(parent, title)
	var c = CheckButton.new()
	c.button_pressed = bool(Game.setting(key))
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(func(on: bool): Game.shove_setting(key, on))
	h.add_child(c)


func _slidey_boi(parent: Node, title: String, key: String, lo: float, hi: float, step: float):
	var h = _make_a_row(parent, title)
	var s = HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Game.setting(key))
	s.custom_minimum_size = Vector2(250, 24)
	s.focus_mode = Control.FOCUS_NONE
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var val = UI.label(_prettify_number(key, s.value), 14, UI.TEXT, "ui")
	val.custom_minimum_size.x = 60
	s.value_changed.connect(func(x: float):
		val.text = _prettify_number(key, x)
		Game.shove_setting(key, x))
	h.add_child(s)
	h.add_child(val)


func _prettify_number(key: String, x: float) -> String:
	match key:
		"fov":
			return "%d°" % int(x)
		"volume":
			return "%d%%" % int(x * 100.0)
	return "%.2f" % x


func _pick_fanciness(i: int):
	Game.shove_setting("quality", i)
	_sync_fanciness()


func _sync_fanciness():
	for i in _quality_btns.size():
		_quality_btns[i].set_pressed_no_signal(i == Game.quality())
		_quality_btns[i].add_theme_color_override("font_color", UI.TEXT if i == Game.quality() else UI.DIM)


func _pick_language(lang: String):
	if str(Game.setting("language")) == lang:
		_sync_language()
		return
	Game.shove_setting("language", lang)
	_rebuild.call_deferred()


# Перерисовываем панель на новом языке (отложенно: кнопку, которая нас вызвала, нельзя удалять на месте).
func _rebuild():
	for c in get_children():
		c.queue_free()
	_reset_armed = false
	_build()


func _sync_language():
	var cur = str(Game.setting("language"))
	for k in _lang_btns:
		_lang_btns[k].set_pressed_no_signal(k == cur)
		_lang_btns[k].add_theme_color_override("font_color", UI.TEXT if k == cur else UI.DIM)


func _on_big_red_button():
	if not _reset_armed:
		_reset_armed = true
		_reset_btn.text = Loc.t("CLICK AGAIN TO CONFIRM")
		return
	_reset_armed = false
	Game.progress.nuke_progress()
	_reset_btn.text = Loc.t("PROGRESS RESET")
	_reset_btn.disabled = true
