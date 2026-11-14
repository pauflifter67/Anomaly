extends CanvasLayer

signal answer_sent(count: int)
signal answer_nvm
signal result_closed
signal wants_back
signal wants_again
signal wants_out

const UI = preload("res://скрипты/интерфейс/стиль.gd")
const SettingsPanel = preload("res://скрипты/интерфейс/панель_настроек.gd")
const MAX_ANSWER = 9

var big_boss: Control
var map_lbl: Label
var round_label_lol: Label
var sub_lbl: Label
var clock_label_lol: Label
var pips: HBoxContainer
var oopsies_label_lol: Label
var prompt_label_lol: Label
var cross: ColorRect
var banner_thing: VBoxContainer
var banner_title: Label
var banner_sub: Label
var hint_label_lol: Label
var help_lbl: Label
var toast_label_lol: Label
var debug_lbl: Label

var submit_layer: Control
var submit_num: Label
var submit_value = 0
var result_layer: Control
var result_box: VBoxContainer
var pause_layer: Control
var over_layer: Control
var over_box: VBoxContainer
var settings_layer: Control

var _banner_tweeny: Tween
var _hint_tweeny: Tween
var _toast_tweeny: Tween
var _timer_warn = false


func _ready():
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	big_boss = Control.new()
	big_boss.set_anchors_preset(Control.PRESET_FULL_RECT)
	big_boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(big_boss)
	big_boss.add_child(UI.dark_corners(0.55))
	_cook_hud()
	_cook_submit()
	_cook_verdict()
	_cook_pause()
	_cook_game_over()
	_cook_settings()


func _cook_hud():
	var tl = VBoxContainer.new()
	tl.position = Vector2(48, 36)
	tl.add_theme_constant_override("separation", 2)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_boss.add_child(tl)
	map_lbl = UI.label("", 13, UI.ACCENT, "wide")
	tl.add_child(map_lbl)
	round_label_lol = UI.label("", 30, UI.TEXT, "light")
	tl.add_child(round_label_lol)
	sub_lbl = UI.label("", 13, UI.DIM, "ui")
	tl.add_child(sub_lbl)

	var tr = VBoxContainer.new()
	UI.anchor(tr, 1.0, 0.0, -348, 36, -48, 136)
	tr.alignment = BoxContainer.ALIGNMENT_BEGIN
	tr.add_theme_constant_override("separation", 6)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_boss.add_child(tr)
	clock_label_lol = UI.label("", 30, UI.TEXT, "light", HORIZONTAL_ALIGNMENT_RIGHT)
	tr.add_child(clock_label_lol)
	oopsies_label_lol = UI.label("MISTAKES ALLOWED", 11, UI.DIM, "wide", HORIZONTAL_ALIGNMENT_RIGHT)
	tr.add_child(oopsies_label_lol)
	pips = HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_END
	pips.add_theme_constant_override("separation", 6)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.add_child(pips)

	cross = ColorRect.new()
	cross.color = Color(1, 1, 1, 0.55)
	UI.anchor(cross, 0.5, 0.5, -2, -2, 2, 2)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_boss.add_child(cross)

	prompt_label_lol = UI.label("", 16, UI.TEXT, "wide", HORIZONTAL_ALIGNMENT_CENTER)
	UI.anchor(prompt_label_lol, 0.5, 0.5, -400, 36, 400, 66)
	big_boss.add_child(prompt_label_lol)

	banner_thing = VBoxContainer.new()
	UI.anchor(banner_thing, 0.5, 0.0, -520, 160, 520, 300)
	banner_thing.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_thing.add_theme_constant_override("separation", 8)
	banner_thing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_boss.add_child(banner_thing)
	banner_title = UI.label("", 44, UI.TEXT, "title", HORIZONTAL_ALIGNMENT_CENTER)
	banner_thing.add_child(banner_title)
	banner_sub = UI.label("", 16, UI.DIM, "wide", HORIZONTAL_ALIGNMENT_CENTER)
	banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_thing.add_child(banner_sub)
	banner_thing.modulate.a = 0.0

	hint_label_lol = UI.label("", 17, UI.ACCENT, "serif", HORIZONTAL_ALIGNMENT_CENTER)
	UI.anchor(hint_label_lol, 0.5, 1.0, -600, -130, 600, -96)
	hint_label_lol.visible = false
	hint_label_lol.modulate.a = 0.0
	big_boss.add_child(hint_label_lol)

	toast_label_lol = UI.label("", 15, UI.GOOD, "wide", HORIZONTAL_ALIGNMENT_CENTER)
	UI.anchor(toast_label_lol, 0.5, 0.0, -600, 40, 600, 70)
	toast_label_lol.modulate.a = 0.0
	big_boss.add_child(toast_label_lol)

	help_lbl = UI.label("", 12, UI.FAINT, "wide")
	UI.anchor(help_lbl, 0.0, 1.0, 48, -56, 1400, -30)
	help_lbl.visible = false
	big_boss.add_child(help_lbl)

	debug_lbl = UI.label("", 13, Color(1, 0.5, 0.4), "ui")
	debug_lbl.position = Vector2(48, 150)
	debug_lbl.visible = false
	big_boss.add_child(debug_lbl)


func setup(map_title: String, oopsies_total_lol: int, hints: bool):
	map_lbl.text = map_title
	for c in pips.get_children():
		c.queue_free()
	for i in oopsies_total_lol:
		var p = ColorRect.new()
		p.custom_minimum_size = Vector2(14, 14)
		p.color = UI.ACCENT
		pips.add_child(p)
	var h = "WASD  MOVE     SHIFT  RUN     F  FLASHLIGHT     E  INTERACT     ESC  PAUSE"
	if hints:
		h += "     H  HINT"
	help_lbl.text = h


func show_round_num(text: String, sub: String):
	round_label_lol.text = text
	sub_lbl.text = sub


func show_oopsies(left: int):
	var little_ones = pips.get_children()
	for i in little_ones.size():
		(little_ones[i] as ColorRect).color = UI.ACCENT if i < left else Color(1, 1, 1, 0.12)
	oopsies_label_lol.visible = little_ones.size() > 0


func show_clock_ticking(seconds: float, active: bool):
	if not active:
		clock_label_lol.text = ""
		return
	var s = int(ceilf(maxf(seconds, 0.0)))
	clock_label_lol.text = "%02d:%02d" % [s / 60, s % 60]
	var warn = seconds <= 15.0
	clock_label_lol.add_theme_color_override("font_color", UI.BAD if warn else UI.TEXT)


func show_prompt_text(text: String):
	prompt_label_lol.text = text
	cross.color = Color(UI.ACCENT.r, UI.ACCENT.g, UI.ACCENT.b, 0.9) if text != "" else Color(1, 1, 1, 0.55)


func yell_banner(title: String, sub = "", duration = 3.5):
	banner_title.text = title
	banner_sub.text = sub
	if _banner_tweeny:
		_banner_tweeny.kill()
	_banner_tweeny = create_tween()
	_banner_tweeny.tween_property(banner_thing, "modulate:a", 1.0, 0.6)
	_banner_tweeny.tween_interval(duration)
	_banner_tweeny.tween_property(banner_thing, "modulate:a", 0.0, 1.2)


func whisper_hint(text: String):
	hint_label_lol.text = text
	if _hint_tweeny:
		_hint_tweeny.kill()
	_hint_tweeny = create_tween()
	_hint_tweeny.tween_property(hint_label_lol, "modulate:a", 1.0, 0.5)
	_hint_tweeny.tween_interval(5.0)
	_hint_tweeny.tween_property(hint_label_lol, "modulate:a", 0.0, 1.5)


func pop_toast(text: String):
	toast_label_lol.text = text
	if _toast_tweeny:
		_toast_tweeny.kill()
	_toast_tweeny = create_tween()
	_toast_tweeny.tween_property(toast_label_lol, "modulate:a", 1.0, 0.4)
	_toast_tweeny.tween_interval(4.5)
	_toast_tweeny.tween_property(toast_label_lol, "modulate:a", 0.0, 1.0)


func toggle_help_text(v: bool):
	var t = create_tween()
	t.tween_property(help_lbl, "modulate:a", 1.0 if v else 0.0, 0.8)


func set_nerd_stuff(text: String):
	debug_lbl.text = text


func flip_nerd_stuff():
	debug_lbl.visible = not debug_lbl.visible


func _cook_submit():
	submit_layer = UI.overlay(0.55)
	big_boss.add_child(submit_layer)
	var p = UI.panel(40)
	p.custom_minimum_size = Vector2(620, 0)
	submit_layer.get_node("Center").add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	v.add_child(UI.label("OBSERVATION REPORT", 13, UI.ACCENT, "wide", HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label("How many anomalies did you notice?", 24, UI.TEXT, "light", HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.gap_thing(8))
	var h = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 34)
	v.add_child(h)
	var minus = UI.button("−", 30, 70)
	minus.custom_minimum_size = Vector2(70, 70)
	minus.pressed.connect(_bump_number.bind(-1))
	h.add_child(minus)
	submit_num = UI.label("0", 96, UI.TEXT, "light", HORIZONTAL_ALIGNMENT_CENTER)
	submit_num.custom_minimum_size = Vector2(140, 0)
	h.add_child(submit_num)
	var plus = UI.button("+", 30, 70)
	plus.custom_minimum_size = Vector2(70, 70)
	plus.pressed.connect(_bump_number.bind(1))
	h.add_child(plus)
	v.add_child(UI.label("← →  or  mouse wheel  ·  keys 0–9  ·  ENTER to confirm", 12, UI.FAINT, "wide", HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.gap_thing(10))
	var b = HBoxContainer.new()
	b.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_theme_constant_override("separation", 16)
	v.add_child(b)
	var cancel = UI.button("KEEP LOOKING", 14, 200)
	cancel.pressed.connect(_nope)
	b.add_child(cancel)
	var ok = UI.button("CONFIRM", 16, 200, true)
	ok.pressed.connect(_yep_thats_it)
	b.add_child(ok)


func open_answer_box():
	submit_value = 0
	submit_num.text = "0"
	prompt_label_lol.text = ""
	UI.show_overlay_lol(submit_layer)


func _bump_number(d: int):
	_force_number(clampi(submit_value + d, 0, MAX_ANSWER))


func _force_number(x: int):
	if x != submit_value:
		Sfx.play("tick", -6.0)
	submit_value = x
	submit_num.text = str(x)
	submit_num.pivot_offset = submit_num.size * 0.5
	submit_num.scale = Vector2(1.12, 1.12)
	var t = create_tween()
	t.tween_property(submit_num, "scale", Vector2.ONE, 0.18)


func _yep_thats_it():
	if not submit_layer.visible:
		return
	submit_layer.visible = false
	answer_sent.emit(submit_value)


func _nope():
	submit_layer.visible = false
	answer_nvm.emit()


func _cook_verdict():
	result_layer = UI.overlay(0.6)
	big_boss.add_child(result_layer)
	var p = UI.panel(40)
	p.custom_minimum_size = Vector2(720, 0)
	result_layer.get_node("Center").add_child(p)
	result_box = VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 10)
	p.add_child(result_box)


func show_the_verdict(kind: String, reported: int, actual: int, changes: Array, footer: String, over: bool):
	for c in result_box.get_children():
		c.queue_free()
	var title = "CORRECT"
	var col = UI.GOOD
	if kind == "wrong":
		title = "INCORRECT OBSERVATION"
		col = UI.BAD
	elif kind == "timeout":
		title = "TIME EXPIRED"
		col = UI.BAD
	result_box.add_child(UI.label("OBSERVATION REPORT", 13, UI.ACCENT, "wide"))
	result_box.add_child(UI.label(title, 40, col, "title"))
	var line = "Anomalies present:  %d" % actual
	if kind != "timeout":
		line += "        You reported:  %d" % reported
	result_box.add_child(UI.label(line, 18, UI.TEXT, "light"))
	result_box.add_child(UI.gap_thing(4))
	result_box.add_child(UI.line(720 - 80, Color(1, 1, 1, 0.08), 1))
	result_box.add_child(UI.label("WHAT WAS DIFFERENT", 12, UI.DIM, "wide"))
	if changes.is_empty():
		result_box.add_child(UI.wrap_text_lol("Nothing. This corridor was exactly as it should be.", 16, UI.TEXT, 640))
	for ch in changes:
		result_box.add_child(UI.wrap_text_lol("•  " + str(ch), 16, UI.TEXT, 640))
	result_box.add_child(UI.gap_thing(6))
	result_box.add_child(UI.wrap_text_lol(footer, 14, UI.DIM, 640))
	result_box.add_child(UI.gap_thing(6))
	var h = HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	result_box.add_child(h)
	var b = UI.button("CONTINUE" if not over else "VIEW RESULTS", 15, 220, true)
	b.pressed.connect(_close_verdict)
	h.add_child(b)
	UI.show_overlay_lol(result_layer)


func _close_verdict():
	if not result_layer.visible:
		return
	result_layer.visible = false
	result_closed.emit()


func _cook_pause():
	pause_layer = UI.overlay(0.65)
	big_boss.add_child(pause_layer)
	var p = UI.panel(40)
	p.custom_minimum_size = Vector2(420, 0)
	pause_layer.get_node("Center").add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UI.label("PAUSED", 34, UI.TEXT, "title"))
	v.add_child(UI.line())
	v.add_child(UI.gap_thing(6))
	var resume = UI.button("RESUME", 15, 340, true)
	resume.pressed.connect(func(): wants_back.emit())
	v.add_child(resume)
	var settings = UI.button("SETTINGS", 15, 340)
	settings.pressed.connect(_open_settings_pls)
	v.add_child(settings)
	var restart = UI.button("RESTART RUN", 15, 340)
	restart.pressed.connect(func(): wants_again.emit())
	v.add_child(restart)
	var leave = UI.button("LEAVE TO MENU", 15, 340)
	leave.pressed.connect(func(): wants_out.emit())
	v.add_child(leave)


func show_pause_screen_lol(v: bool):
	if v:
		UI.show_overlay_lol(pause_layer)
	else:
		pause_layer.visible = false
		settings_layer.visible = false


func _cook_settings():
	settings_layer = UI.overlay(0.5)
	big_boss.add_child(settings_layer)
	var sp = SettingsPanel.new()
	sp.closed.connect(func(): settings_layer.visible = false)
	settings_layer.get_node("Center").add_child(sp)


func _open_settings_pls():
	UI.show_overlay_lol(settings_layer)


func _cook_game_over():
	over_layer = UI.overlay(0.8)
	big_boss.add_child(over_layer)
	var p = UI.panel(46)
	p.custom_minimum_size = Vector2(640, 0)
	over_layer.get_node("Center").add_child(p)
	over_box = VBoxContainer.new()
	over_box.add_theme_constant_override("separation", 10)
	p.add_child(over_box)


func show_rip_screen(map_title: String, diff_title: String, cleared: int, best: int, new_best: bool):
	for c in over_box.get_children():
		c.queue_free()
	over_box.add_child(UI.label(map_title + "   ·   " + diff_title, 13, UI.ACCENT, "wide"))
	over_box.add_child(UI.label("PROTOCOL TERMINATED", 40, UI.BAD, "title"))
	over_box.add_child(UI.line())
	over_box.add_child(UI.gap_thing(6))
	over_box.add_child(UI.label("Corridors cleared:  %d" % cleared, 22, UI.TEXT, "light"))
	over_box.add_child(UI.label(("NEW BEST:  %d" % best) if new_best else ("Best:  %d" % best), 16, UI.GOOD if new_best else UI.DIM, "wide"))
	over_box.add_child(UI.gap_thing(10))
	over_box.add_child(UI.wrap_text_lol("Every mistake teaches the eye. Breathe. Look again. Bounce back.", 18, UI.ACCENT, 560))
	over_box.add_child(UI.gap_thing(14))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	over_box.add_child(h)
	var again = UI.button("TRY AGAIN", 15, 260, true)
	again.pressed.connect(func(): wants_again.emit())
	h.add_child(again)
	var menu = UI.button("MAIN MENU", 15, 260)
	menu.pressed.connect(func(): wants_out.emit())
	h.add_child(menu)
	UI.show_overlay_lol(over_layer)


func _input(e: InputEvent):
	if submit_layer.visible:
		if e is InputEventKey and e.pressed and not e.echo:
			var k: int = e.physical_keycode
			if k in [KEY_LEFT, KEY_A, KEY_DOWN, KEY_S, KEY_MINUS, KEY_KP_SUBTRACT]:
				_bump_number(-1)
			elif k in [KEY_RIGHT, KEY_D, KEY_UP, KEY_W, KEY_EQUAL, KEY_KP_ADD]:
				_bump_number(1)
			elif k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				_yep_thats_it()
			elif k == KEY_ESCAPE:
				_nope()
			elif k >= KEY_0 and k <= KEY_9:
				_force_number(k - KEY_0)
			elif k >= KEY_KP_0 and k <= KEY_KP_9:
				_force_number(k - KEY_KP_0)
			get_viewport().set_input_as_handled()
		elif e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_WHEEL_UP:
				_bump_number(1)
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_bump_number(-1)
	elif result_layer.visible:
		if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			_close_verdict()
			get_viewport().set_input_as_handled()
	elif settings_layer.visible:
		if e is InputEventKey and e.pressed and e.physical_keycode == KEY_ESCAPE:
			settings_layer.visible = false
			get_viewport().set_input_as_handled()
	elif pause_layer.visible:
		if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
			wants_back.emit()
			get_viewport().set_input_as_handled()
