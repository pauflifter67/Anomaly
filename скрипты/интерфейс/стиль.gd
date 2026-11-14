extends RefCounted

const ACCENT = Color(0.88, 0.75, 0.52)
const TEXT = Color(0.93, 0.91, 0.87)
const DIM = Color(0.62, 0.60, 0.56)
const FAINT = Color(0.45, 0.44, 0.42)
const BAD = Color(0.92, 0.34, 0.28)
const GOOD = Color(0.56, 0.88, 0.62)
const BG = Color(0.035, 0.035, 0.04, 0.94)


static func label(text: String, size = 18, color = TEXT, fnt = "ui", align = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", Game.font(fnt))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 6)
	return l


static func wrap_text_lol(text: String, size = 16, color = DIM, width = 300.0) -> Label:
	var l = label(text, size, color, "ui")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	return l


static func panel_look(bg = BG, border = Color(1, 1, 1, 0.07), border_w = 1, pad = 28) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	s.set_corner_radius_all(2)
	return s


static func panel(pad = 28, bg = BG) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_look(bg, Color(1, 1, 1, 0.07), 1, pad))
	return p


static func line(width = 60.0, color = ACCENT, h = 2.0) -> ColorRect:
	var r = ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(width, h)
	r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func anchor(c: Control, ax: float, ay: float, left: float, top: float, right: float, bottom: float):
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = left
	c.offset_top = top
	c.offset_right = right
	c.offset_bottom = bottom


static func gap_thing(h: float) -> Control:
	var c = Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func button(text: String, size = 16, min_w = 170.0, primary = false) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 46)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", Game.font("wide"))
	b.add_theme_font_size_override("font_size", size)
	var base = ACCENT if primary else Color(1, 1, 1, 0.18)
	var normal = panel_look(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.14) if primary else Color(0, 0, 0, 0.25), base, 1, 10)
	var hover = panel_look(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.28), ACCENT, 1, 10)
	var pressed = panel_look(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.4), ACCENT, 1, 10)
	var disabled = panel_look(Color(0, 0, 0, 0.2), Color(1, 1, 1, 0.06), 1, 10)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", TEXT if primary else DIM)
	b.add_theme_color_override("font_hover_color", TEXT)
	b.add_theme_color_override("font_pressed_color", TEXT)
	b.add_theme_color_override("font_disabled_color", FAINT)
	b.mouse_entered.connect(func():
		if b.disabled:
			return
		Sfx.play("hover", -18.0)
		b.pivot_offset = b.size * 0.5
		var t = b.create_tween()
		t.tween_property(b, "scale", Vector2(1.035, 1.035), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	b.mouse_exited.connect(func():
		var t = b.create_tween()
		t.tween_property(b, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	b.pressed.connect(func(): Sfx.play("click", -9.0))
	return b


static func dark_corners(strength = 0.6) -> TextureRect:
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, strength * 0.25), Color(0, 0, 0, strength)])
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	gt.width = 256
	gt.height = 256
	var tr = TextureRect.new()
	tr.texture = gt
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


static func overlay(dim = 0.6) -> Control:
	var big_boss = Control.new()
	big_boss.set_anchors_preset(Control.PRESET_FULL_RECT)
	big_boss.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, dim)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_boss.add_child(bg)
	var cc = CenterContainer.new()
	cc.name = "Center"
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_boss.add_child(cc)
	big_boss.visible = false
	return big_boss


static func show_overlay_lol(o: Control):
	o.visible = true
	o.modulate.a = 0.0
	var t = o.create_tween()
	t.tween_property(o, "modulate:a", 1.0, 0.25)
