extends RefCounted

static var _tex = {}
static var _imgs = {}


static func gimme_tex(id: String) -> Texture2D:
	if _tex.has(id):
		return _tex[id]
	var img: Image = _gimme_img(id).duplicate()
	img.generate_mipmaps()
	var t = ImageTexture.create_from_image(img)
	_tex[id] = t
	return t


static func gimme_normal_tex(id: String, strength = 3.0) -> Texture2D:
	var key = id + "#n"
	if _tex.has(key):
		return _tex[key]
	var img: Image = _gimme_img(id).duplicate()
	img.convert(Image.FORMAT_RGBA8)
	img.bump_map_to_normal_map(strength)
	img.generate_mipmaps()
	var t = ImageTexture.create_from_image(img)
	_tex[key] = t
	return t


static func _gimme_img(id: String) -> Image:
	if _imgs.has(id):
		return _imgs[id]
	var img = _cook_it(id)
	if img == null:
		push_warning("Неизвестная текстура: " + id)
		img = Image.create_empty(4, 4, false, Image.FORMAT_RGB8)
		img.fill(Color.MAGENTA)
	_imgs[id] = img
	return img


static func _cook_it(id: String) -> Image:
	if id.begins_with("art_"):
		return _fake_painting(id.substr(4))
	match id:
		"wallpaper":
			return _ugly_wallpaper(Color(0.47, 0.49, 0.40), Color(0.38, 0.41, 0.33), Color(0.70, 0.60, 0.38))
		"wallpaper_alt":
			return _ugly_wallpaper(Color(0.55, 0.42, 0.40), Color(0.44, 0.31, 0.31), Color(0.70, 0.60, 0.38))
		"carpet":
			return _fluffy_carpet()
		"wood":
			return _wooden_stuff(Color(0.16, 0.085, 0.045), Color(0.31, 0.17, 0.09), 1)
		"wood_mid":
			return _wooden_stuff(Color(0.27, 0.13, 0.07), Color(0.46, 0.25, 0.13), 3)
		"wood_light":
			return _wooden_stuff(Color(0.36, 0.24, 0.13), Color(0.55, 0.39, 0.22), 2)
		"marble":
			return _fancy_marble()
		"plaster":
			return _boring_flat(Color(0.84, 0.81, 0.74), 0.03, 128, 7, 0.15)
		"fabric":
			return _boring_flat(Color(1, 1, 1), 0.2, 128, 8, 0.45)
		"concrete":
			return _grey_concrete(Color(0.46, 0.45, 0.43), 31)
		"concrete_dark":
			return _grey_concrete(Color(0.30, 0.29, 0.28), 32)
		"gravel":
			return _crunchy_gravel()
		"tiles_station":
			return _bathroom_tiles(256, 4, Color(0.56, 0.54, 0.50), Color(0.24, 0.23, 0.21), 0.07, 21)
		"tiles_metro":
			return _subway_tiles()
		"metal":
			return _shiny_metal(Color(0.62, 0.63, 0.65), 51)
		"rust":
			return _rusty_stuff()
		"brick":
			return _brick_wall_lol()
		"stain":
			return _random_blob(128, Color(0.10, 0.03, 0.02, 0.92), 0.25, 0.95, 41)
		"puddle":
			return _random_blob(128, Color(0.03, 0.035, 0.04, 0.85), 0.45, 0.98, 42)
		"shadow":
			return _shadow()
		"clock_face":
			return _clock_face_lol()
	return null


static func _noisy_noise(w: int, h: int, freq: float, seed: int, octaves = 4) -> Image:
	var n = FastNoiseLite.new()
	n.seed = seed
	n.frequency = freq
	n.fractal_octaves = octaves
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return n.get_seamless_image(w, h, false, false, 0.1, true)


static func _h(x: float, y: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


static func _boring_flat(col: Color, amount: float, size: int, seed: int, freq: float) -> Image:
	var img = Image.create_empty(size, size, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(size, size, freq, seed, 3)
	for y in size:
		for x in size:
			var n = nz.get_pixel(x, y).r
			img.set_pixel(x, y, col * (1.0 - amount + 2.0 * amount * n))
	return img


static func _ugly_wallpaper(c1: Color, c2: Color, gold: Color) -> Image:
	var w = 128
	var h = 128
	var img = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(w, h, 0.15, 3, 2)
	for y in h:
		var v = float(y) / h
		for x in w:
			var u = float(x) / w
			var dam = sin(u * TAU * 2.0) * sin(v * TAU * 2.0)
			var dam2 = sin((u + 0.25) * TAU * 2.0 + sin(v * TAU * 4.0) * 0.6) * cos(v * TAU * 2.0)
			var k = smoothstep(0.35, 0.6, absf(dam * 0.7 + dam2 * 0.5))
			var c = c1.lerp(c2, k)
			if fposmod(u * 4.0, 1.0) < 0.035:
				c = c.lerp(gold, 0.45)
			c = c * (0.93 + nz.get_pixel(x, y).r * 0.12)
			img.set_pixel(x, y, c)
	return img


static func _fluffy_carpet() -> Image:
	var w = 128
	var h = 256
	var img = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(w, h, 0.35, 9, 2)
	var crimson = Color(0.42, 0.06, 0.07)
	var dark = Color(0.20, 0.03, 0.04)
	var gold = Color(0.70, 0.50, 0.24)
	for y in h:
		var v = float(y) / h
		for x in w:
			var u = float(x) / w
			var c = crimson
			if u < 0.07 or u > 0.93:
				c = dark
			elif absf(u - 0.10) < 0.012 or absf(u - 0.90) < 0.012:
				c = gold
			else:
				var cu = (u - 0.5) * 1.25
				var cv = fposmod(v * 2.0, 1.0) - 0.5
				var d = absf(cu) + absf(cv)
				if absf(d - 0.40) < 0.022:
					c = gold
				elif d < 0.40 and d > 0.31:
					c = dark
				elif d < 0.12:
					c = gold.lerp(crimson, 0.45)
				elif absf(d - 0.2) < 0.018:
					c = gold.lerp(dark, 0.35)
				var cv2 = fposmod(v * 2.0 + 0.5, 1.0) - 0.5
				if absf(cu) + absf(cv2) < 0.05:
					c = gold * 0.8
			c = c * (0.78 + nz.get_pixel(x, y).r * 0.38)
			img.set_pixel(x, y, c)
	return img


static func _wooden_stuff(dark: Color, light: Color, seed: int) -> Image:
	var s = 256
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(s, s, 0.012, seed, 3)
	var fine = _noisy_noise(s, s, 0.25, seed + 10, 1)
	for y in s:
		var v = float(y) / s
		for x in s:
			var g = nz.get_pixel(x, y).r
			var ring = 0.5 + 0.5 * sin(v * TAU * 24.0 + g * 5.0)
			var f = fine.get_pixel(x, y).r
			img.set_pixel(x, y, dark.lerp(light, 0.3 + ring * 0.35 + f * 0.35))
	return img


static func _fancy_marble() -> Image:
	var s = 256
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(s, s, 0.01, 13, 5)
	for y in s:
		var v = float(y) / s
		for x in s:
			var u = float(x) / s
			var dark = (int(u * 2.0) + int(v * 2.0)) % 2 == 1
			var g = nz.get_pixel(x, y).r
			var vein = 1.0 - smoothstep(0.0, 0.09, absf(sin((u * 2.0 + v * 3.0) * TAU + g * 7.0)))
			var base = Color(0.12, 0.16, 0.14) if dark else Color(0.86, 0.83, 0.77)
			var vc = Color(0.55, 0.50, 0.38) if dark else Color(0.52, 0.50, 0.48)
			var c = base.lerp(vc, vein * 0.6) * (0.95 + g * 0.1)
			if fposmod(u * 2.0, 1.0) < 0.008 or fposmod(v * 2.0, 1.0) < 0.008:
				c = Color(0.30, 0.28, 0.25)
			img.set_pixel(x, y, c)
	return img


static func _grey_concrete(base: Color, seed: int) -> Image:
	var s = 256
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var n1 = _noisy_noise(s, s, 0.015, seed, 5)
	var n2 = _noisy_noise(s, s, 0.2, seed + 1, 2)
	var n3 = _noisy_noise(s, s, 0.04, seed + 2, 3)
	for y in s:
		for x in s:
			var a = n1.get_pixel(x, y).r
			var b = n2.get_pixel(x, y).r
			var st = n3.get_pixel(x, y).r
			var c = base * (0.72 + 0.42 * a + 0.1 * b)
			if st > 0.68:
				c = c * (1.0 - (st - 0.68) * 1.4)
			if b > 0.86:
				c = c * 0.75
			img.set_pixel(x, y, c)
	return img


static func _crunchy_gravel() -> Image:
	var s = 128
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var n = _noisy_noise(s, s, 0.3, 61, 2)
	var n2 = _noisy_noise(s, s, 0.05, 62, 3)
	for y in s:
		for x in s:
			var a = n.get_pixel(x, y).r
			var b = n2.get_pixel(x, y).r
			var c = Color(0.27, 0.25, 0.23) * (0.6 + a * 0.8)
			c = c.lerp(Color(0.2, 0.13, 0.08), b * 0.35)
			img.set_pixel(x, y, c)
	return img


static func _bathroom_tiles(size: int, count: int, base: Color, grout: Color, vary: float, seed: int) -> Image:
	var img = Image.create_empty(size, size, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(size, size, 0.05, seed, 3)
	var sp = _noisy_noise(size, size, 0.5, seed + 1, 1)
	var cell_thingy = size / count
	for y in size:
		for x in size:
			var cx = x / cell_thingy
			var cy = y / cell_thingy
			var horiz_speed = _h(float(cx) + seed, float(cy))
			var c = base * (1.0 - vary + 2.0 * vary * horiz_speed)
			var s = sp.get_pixel(x, y).r
			if s > 0.78:
				c = c * 0.72
			elif s < 0.18:
				c = c * 1.12
			if x % cell_thingy < 2 or y % cell_thingy < 2:
				c = grout
			c = c * (0.9 + nz.get_pixel(x, y).r * 0.2)
			img.set_pixel(x, y, c)
	return img


static func _subway_tiles() -> Image:
	var s = 256
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var dirt = _noisy_noise(s, s, 0.012, 71, 4)
	var fine = _noisy_noise(s, s, 0.3, 72, 1)
	var tweeny = 64
	var th = 32
	for y in s:
		var one_row = y / th
		var ly = y % th
		for x in s:
			var xo = (x + (32 if one_row % 2 == 1 else 0)) % s
			var col = xo / tweeny
			var lx = xo % tweeny
			var c = Color(0.80, 0.79, 0.72) * (0.95 + 0.1 * _h(float(col), float(one_row) + 3.0))
			var edgy = mini(mini(lx, tweeny - 1 - lx), mini(ly, th - 1 - ly))
			if edgy < 4:
				c = c * (0.86 + 0.035 * edgy)
			if lx < 2 or ly < 2:
				c = Color(0.27, 0.26, 0.23)
			var g = dirt.get_pixel(x, y).r
			if g > 0.5:
				c = c.lerp(Color(0.30, 0.27, 0.20), (g - 0.5) * 1.5)
			c = c * (0.94 + fine.get_pixel(x, y).r * 0.1)
			img.set_pixel(x, y, c)
	return img


static func _brick_wall_lol() -> Image:
	var s = 256
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(s, s, 0.08, 81, 3)
	var bw = 64
	var bh = 24
	for y in s:
		var one_row = y / bh
		for x in s:
			var xo = (x + (32 if one_row % 2 == 1 else 0)) % s
			var col = xo / bw
			var c = Color(0.36, 0.17, 0.12) * (0.8 + 0.35 * _h(float(col), float(one_row) + 9.0))
			if xo % bw < 3 or y % bh < 3:
				c = Color(0.32, 0.30, 0.27)
			c = c * (0.85 + nz.get_pixel(x, y).r * 0.3)
			img.set_pixel(x, y, c)
	return img


static func _shiny_metal(base: Color, seed: int) -> Image:
	var s = 128
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var fine = _noisy_noise(s, s, 0.3, seed, 1)
	var r = RandomNumberGenerator.new()
	r.seed = seed
	var row_pile = PackedFloat32Array()
	for y in s:
		row_pile.append(r.randf())
	for y in s:
		for x in s:
			img.set_pixel(x, y, base * (0.88 + 0.08 * row_pile[y] + 0.06 * fine.get_pixel(x, y).r))
	return img


static func _rusty_stuff() -> Image:
	var s = 128
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGB8)
	var n = _noisy_noise(s, s, 0.04, 91, 4)
	var f = _noisy_noise(s, s, 0.4, 92, 1)
	for y in s:
		for x in s:
			var a = n.get_pixel(x, y).r
			var c = Color(0.30, 0.30, 0.31) * (0.85 + f.get_pixel(x, y).r * 0.25)
			if a > 0.5:
				c = c.lerp(Color(0.38, 0.17, 0.07), (a - 0.5) * 1.8)
			img.set_pixel(x, y, c)
	return img


static func _random_blob(size: int, col: Color, inner: float, outer: float, seed: int) -> Image:
	var img = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var nz = _noisy_noise(size, size, 0.05, seed, 3)
	for y in size:
		for x in size:
			var d = Vector2(float(x) / size - 0.5, float(y) / size - 0.5).length() * 2.0
			var n = nz.get_pixel(x, y).r
			var a = 1.0 - smoothstep(inner, outer, d + (n - 0.5) * 0.45)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * col.a))
	return img


static func _shadow() -> Image:
	var w = 64
	var h = 128
	var img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u = float(x) / w
			var v = float(y) / h
			var head = 1.0 - smoothstep(0.06, 0.14, Vector2((u - 0.5), (v - 0.13) * 0.5).length())
			var body = 1.0 - smoothstep(0.75, 1.15, Vector2((u - 0.5) / 0.24, (v - 0.56) / 0.40).length())
			var a = maxf(head, body) * (1.0 - smoothstep(0.85, 1.0, v))
			img.set_pixel(x, y, Color(0, 0, 0, a * 0.85))
	return img


static func _clock_face_lol() -> Image:
	var s = 128
	var img = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var p = Vector2(float(x) / s - 0.5, float(y) / s - 0.5)
			var r = p.length()
			var c = Color(0.92, 0.89, 0.80, 1.0)
			if r > 0.5:
				c = Color(0, 0, 0, 0)
			elif r > 0.46:
				c = Color(0.08, 0.07, 0.06, 1)
			else:
				var ang = fposmod(atan2(p.x, -p.y), TAU)
				var step = TAU / 12.0
				var dif = absf(fposmod(ang + step * 0.5, step) - step * 0.5)
				var big = dif * r < 0.012 and r > 0.33 and r < 0.43
				var minute = absf(fposmod(ang + TAU / 120.0, TAU / 60.0) - TAU / 120.0) * r < 0.004 and r > 0.40 and r < 0.43
				if big or minute:
					c = Color(0.08, 0.07, 0.06, 1)
			img.set_pixel(x, y, c)
	return img


static func _fake_painting(name: String) -> Image:
	var w = 160
	var h = 120
	if name.begins_with("timetable") or name.begins_with("notice"):
		w = 96
		h = 128
	var img = Image.create_empty(w, h, false, Image.FORMAT_RGB8)
	var nz = _noisy_noise(w, h, 0.25, 77, 2)
	var poster = name.begins_with("timetable") or name.begins_with("notice") or name.begins_with("metro") or name.begins_with("travel")
	for y in h:
		var v = float(y) / h
		for x in w:
			var u = float(x) / w
			var c = _painting_pixel(name, u, v)
			var n = nz.get_pixel(x, y).r
			var vig = 1.0
			if not poster:
				vig = 1.0 - 0.35 * pow(Vector2(u - 0.5, v - 0.5).length() * 1.4, 2.0)
			c = c * (0.91 + n * 0.15) * vig
			img.set_pixel(x, y, c)
	return img


static func _hill_thing(u: float, base: float, a1: float, f1: float, p1: float, a2: float, f2: float) -> float:
	return base + a1 * sin(u * f1 + p1) + a2 * sin(u * f2)


static func _painting_pixel(name: String, u: float, v: float) -> Color:
	var black = Color(0.02, 0.02, 0.02)
	match name:
		"landscape", "landscape_fig":
			var c = Color(0.92, 0.62, 0.34).lerp(Color(0.32, 0.30, 0.48), clampf(1.0 - v / 0.55, 0.0, 1.0))
			if Vector2((u - 0.68) * 1.33, v - 0.36).length() < 0.07:
				c = Color(1.0, 0.86, 0.6)
			var far = _hill_thing(u, 0.50, 0.05, 9.0, 1.0, 0.03, 23.0)
			if v > far:
				c = Color(0.36, 0.33, 0.42).lerp(Color(0.25, 0.27, 0.3), (v - far) * 3.0)
			var near = _hill_thing(u, 0.62, 0.07, 5.0, 2.0, 0.02, 17.0)
			if v > near:
				c = Color(0.16, 0.22, 0.12).lerp(Color(0.08, 0.1, 0.06), (v - near) * 2.5)
			if name == "landscape_fig":
				var fy = _hill_thing(0.3, 0.62, 0.07, 5.0, 2.0, 0.02, 17.0)
				if absf(u - 0.3) < 0.009 and v < fy and v > fy - 0.08:
					c = black
				if Vector2((u - 0.3) * 1.33, v - (fy - 0.09)).length() < 0.014:
					c = black
			return c
		"portrait", "portrait_blank":
			var c = Color(0.22, 0.14, 0.08).lerp(Color(0.08, 0.05, 0.03), v)
			if Vector2((u - 0.5) * 1.33 / 0.5, (v - 1.05) / 0.38).length() < 1.0:
				c = Color(0.1, 0.1, 0.13)
			if absf(u - 0.5) < 0.05 and v > 0.5 and v < 0.75:
				c = Color(0.62, 0.46, 0.36)
			var fd = Vector2((u - 0.5) * 1.33 / 0.15, (v - 0.40) / 0.21).length()
			if fd < 1.0:
				c = Color(0.80, 0.62, 0.48).lerp(Color(0.55, 0.38, 0.28), fd * 0.6)
			if Vector2((u - 0.5) * 1.33 / 0.17, (v - 0.34) / 0.22).length() < 1.0 and v < 0.29:
				c = Color(0.12, 0.08, 0.05)
			if name == "portrait":
				for ex in [0.445, 0.555]:
					if Vector2((u - float(ex)) * 1.33, v - 0.39).length() < 0.018:
						c = Color(0.1, 0.07, 0.05)
				if absf(u - 0.5) < 0.035 and absf(v - 0.5) < 0.007:
					c = Color(0.45, 0.22, 0.2)
			return c
		"sea", "sea_storm":
			var storm = name == "sea_storm"
			var c = Color(0.62, 0.72, 0.80).lerp(Color(0.85, 0.82, 0.74), v / 0.5)
			if storm:
				c = Color(0.22, 0.24, 0.27).lerp(Color(0.38, 0.38, 0.40), v / 0.5)
			if v > 0.5:
				c = Color(0.12, 0.27, 0.38).lerp(Color(0.05, 0.13, 0.2), (v - 0.5) * 2.0)
				if sin(u * 60.0 + v * 90.0 + sin(u * 7.0) * 2.0) > (0.55 if storm else 0.88):
					c = c.lerp(Color(0.8, 0.85, 0.9), 0.5)
			if Vector2((u - 0.78) * 1.33 / 0.12, (v - 0.56) / 0.07).length() < 1.0:
				c = Color(0.12, 0.11, 0.1)
			if absf(u - 0.78) < 0.022 and v > 0.25 and v < 0.52:
				c = Color(0.92, 0.9, 0.86) if fposmod(v * 20.0, 1.0) < 0.6 else Color(0.7, 0.15, 0.12)
			if storm and Vector2((u - 0.78) * 1.33, v - 0.235).length() < 0.03:
				c = Color(1.0, 0.9, 0.5)
			return c
		"flowers", "flowers_dead":
			var dead = name == "flowers_dead"
			var c = Color(0.12, 0.2, 0.2).lerp(Color(0.05, 0.1, 0.1), v)
			if v > 0.82:
				c = Color(0.28, 0.17, 0.09)
			if absf(u - 0.5) < 0.09 - (v - 0.6) * 0.12 and v > 0.58 and v < 0.82:
				c = Color(0.75, 0.78, 0.82)
			var pts = [[0.42, 0.33], [0.5, 0.27], [0.58, 0.34], [0.36, 0.44], [0.64, 0.45], [0.47, 0.42], [0.55, 0.43], [0.44, 0.2], [0.6, 0.22]]
			var col_pile = [Color(0.75, 0.12, 0.12), Color(0.9, 0.78, 0.3), Color(0.9, 0.88, 0.85)]
			for k in pts.size():
				var py: float = pts[k][1]
				if dead:
					py += 0.12
				if Vector2((u - float(pts[k][0])) * 1.33, v - py).length() < 0.045:
					c = Color(0.25, 0.2, 0.15) if dead else col_pile[k % 3]
			return c
		"forest", "forest_fig":
			var c = Color(0.62, 0.66, 0.6).lerp(Color(0.3, 0.36, 0.3), v)
			var trees = [[0.08, 0.025, 0.5], [0.2, 0.04, 0.1], [0.33, 0.02, 0.6], [0.45, 0.03, 0.3], [0.62, 0.035, 0.15], [0.74, 0.02, 0.55], [0.86, 0.045, 0.05], [0.95, 0.02, 0.4]]
			for t in trees:
				if absf(u - float(t[0])) < float(t[1]):
					c = Color(0.08, 0.1, 0.08).lerp(c, float(t[2]))
			if v > 0.86:
				c = Color(0.12, 0.14, 0.1)
			if name == "forest_fig":
				if absf(u - 0.54) < 0.012 and v > 0.62 and v < 0.86:
					c = black
				if Vector2((u - 0.54) * 1.33, v - 0.6).length() < 0.018:
					c = black
			return c
		"night", "night_dark":
			var c = Color(0.05, 0.07, 0.16).lerp(Color(0.12, 0.14, 0.25), v)
			if _h(floorf(u * 160.0), floorf(v * 120.0)) > 0.985 and v < 0.6:
				c = Color(0.8, 0.8, 0.9)
			if Vector2((u - 0.2) * 1.33, v - 0.25).length() < 0.06:
				c = Color(0.9, 0.88, 0.75)
			if v > _hill_thing(u, 0.72, 0.03, 6.0, 0.5, 0.01, 19.0):
				c = Color(0.02, 0.025, 0.04)
			if u > 0.55 and u < 0.75 and v > 0.52 and v < 0.74:
				c = Color(0.03, 0.03, 0.04)
			if v > 0.40 and v <= 0.52 and absf(u - 0.65) < (v - 0.40) * 0.9:
				c = Color(0.03, 0.03, 0.04)
			if u > 0.62 and u < 0.67 and v > 0.58 and v < 0.64:
				c = Color(0.03, 0.03, 0.04) if name == "night_dark" else Color(1.0, 0.8, 0.4)
			return c
		"abstract", "abstract_alt":
			var pal = [Color(0.78, 0.6, 0.2), Color(0.15, 0.4, 0.42), Color(0.6, 0.2, 0.14), Color(0.86, 0.82, 0.72)]
			if name == "abstract_alt":
				pal = [Color(0.78, 0.6, 0.2), Color(0.6, 0.2, 0.14), Color(0.15, 0.4, 0.42), Color(0.86, 0.82, 0.72)]
			var t = u * 0.7 + v * 0.5
			var c: Color = pal[int(t * 6.0) % 4]
			if Vector2((u - 0.65) * 1.33, v - 0.4).length() < 0.15:
				c = Color(0.06, 0.06, 0.07)
			return c
		"timetable", "timetable_alt":
			var c = Color(0.9, 0.88, 0.82)
			if v < 0.14:
				c = Color(0.6, 0.1, 0.1) if name == "timetable_alt" else Color(0.1, 0.15, 0.3)
			elif v > 0.2 and v < 0.92 and u > 0.08 and u < 0.92:
				if fposmod(v, 0.07) < 0.025 and _h(floorf(u * 14.0), floorf(v / 0.07)) > 0.25:
					c = Color(0.3, 0.3, 0.32)
			return c
		"notice", "notice_alt":
			var c = Color(0.92, 0.86, 0.45)
			if v < 0.1:
				c = black if fposmod(u * 6.0 + v * 6.0, 1.0) < 0.5 else Color(0.95, 0.8, 0.1)
			elif v > 0.2 and v < 0.85 and u > 0.1 and u < 0.9:
				if fposmod(v, 0.08) < 0.03 and _h(floorf(u * 10.0), floorf(v / 0.08)) > 0.2:
					c = Color(0.6, 0.05, 0.05) if name == "notice_alt" else Color(0.2, 0.2, 0.2)
			return c
		"travel", "travel_alt":
			var c = Color(0.95, 0.78, 0.4).lerp(Color(0.9, 0.5, 0.3), v / 0.55)
			if Vector2((u - 0.5) * 1.33, v - 0.42).length() < 0.16:
				c = black if name == "travel_alt" else Color(0.85, 0.2, 0.12)
			if v > 0.55:
				c = Color(0.1, 0.32, 0.45).lerp(Color(0.05, 0.18, 0.3), (v - 0.55) * 2.2)
			if v > 0.40 and v < 0.62 and absf(u - 0.3) < (v - 0.40) * 0.5:
				c = Color(0.95, 0.92, 0.85)
			if u < 0.04 or u > 0.96 or v < 0.05 or v > 0.95:
				c = Color(0.92, 0.88, 0.78)
			return c
		"metro_map", "metro_map_alt":
			var c = Color(0.9, 0.88, 0.82)
			if absf(v - 0.5) < 0.025 and u > 0.08 and u < 0.92:
				c = Color(0.8, 0.12, 0.12)
			if absf(u - 0.35) < 0.02 and v > 0.1 and v < 0.9:
				c = Color(0.12, 0.55, 0.25)
			if absf((v - 0.15) - (u - 0.1) * 0.8) < 0.025 and u > 0.1 and u < 0.95 and v < 0.9:
				c = Color(0.12, 0.3, 0.7)
			if name == "metro_map_alt" and absf((v - 0.85) + (u - 0.15) * 0.8) < 0.02 and u > 0.15 and u < 0.9:
				c = black
			for p in [Vector2(0.35, 0.5), Vector2(0.55, 0.5), Vector2(0.8, 0.5), Vector2(0.35, 0.2), Vector2(0.35, 0.8)]:
				var d = Vector2((u - p.x) * 1.33, v - p.y).length()
				if d < 0.03:
					c = Color(1, 1, 1) if d < 0.018 else black
			return c
	return Color(0.5, 0.5, 0.5)
