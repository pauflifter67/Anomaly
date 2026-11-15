extends Node

const RATE = 22050
const AMB_RATE = 11025

var ambient: AudioStreamPlayer
var music: AudioStreamPlayer
var _player_pool: Array[AudioStreamPlayer] = []
var _cache = {}
var _music_tweeny: Tween


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p = AudioStreamPlayer.new()
		add_child(p)
		_player_pool.append(p)
	ambient = AudioStreamPlayer.new()
	add_child(ambient)
	music = AudioStreamPlayer.new()
	add_child(music)


func fetch_stream(id: String) -> AudioStreamWAV:
	if not _cache.has(id):
		_cache[id] = _synthesize_everything(id)
	return _cache[id]


func play(id: String, vol = 0.0, pitch = 1.0):
	var p: AudioStreamPlayer = null
	for q in _player_pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = _player_pool[0]
	p.stream = fetch_stream(id)
	p.volume_db = vol
	p.pitch_scale = pitch
	p.play()


func play_3d_lol(id: String, parent: Node, pos: Vector3, vol = 0.0, pitch = 1.0):
	var p = AudioStreamPlayer3D.new()
	p.stream = fetch_stream(id)
	p.volume_db = vol
	p.pitch_scale = pitch
	p.unit_size = 4.0
	p.max_distance = 45.0
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


func set_bg_noise(id: String, vol = -10.0):
	if id == "":
		ambient.stop()
		ambient.stream = null
		return
	var s = fetch_stream(id)
	ambient.volume_db = vol
	if ambient.stream == s and ambient.playing:
		return
	ambient.stream = s
	ambient.play()


func set_bg_music(id: String, vol = -12.0):
	if _music_tweeny:
		_music_tweeny.kill()
	if id == "":
		if music.playing:
			_music_tweeny = create_tween()
			_music_tweeny.tween_property(music, "volume_db", -60.0, 1.2)
			_music_tweeny.tween_callback(music.stop)
		return
	var s = fetch_stream(id)
	if music.stream == s and music.playing:
		music.volume_db = vol
		return
	music.stream = s
	music.volume_db = -40.0
	music.play()
	_music_tweeny = create_tween()
	_music_tweeny.tween_property(music, "volume_db", vol, 2.5)


func _synthesize_everything(id: String) -> AudioStreamWAV:
	var r = RandomNumberGenerator.new()
	r.seed = hash(id)
	match id:
		"step0", "step1", "step2", "step3":
			return _stuff_into_wav(_synth_step(r, 0.18 + 0.04 * int(id[4]), 1.0), RATE)
		"door_open":
			return _stuff_into_wav(_synth_door_open(r), RATE)
		"door_close":
			return _stuff_into_wav(_synth_door_close(r), RATE)
		"ding":
			return _stuff_into_wav(_synth_beeps([[1318.5, 0.0], [1046.5, 0.38]], 1.8, 2.6, 0.32), RATE)
		"bell":
			return _stuff_into_wav(_synth_bell(r), RATE)
		"chime_ok":
			return _stuff_into_wav(_synth_beeps([[523.25, 0.0], [659.25, 0.09], [783.99, 0.18], [1046.5, 0.27]], 1.9, 2.4, 0.22), RATE)
		"wrong":
			return _stuff_into_wav(_synth_wrong(), RATE)
		"hover":
			return _stuff_into_wav(_synth_blip(2600.0, 0.035, 140.0, 0.12), RATE)
		"click":
			return _stuff_into_wav(_synth_click(r), RATE)
		"tick":
			return _stuff_into_wav(_synth_tick(r), RATE)
		"knock":
			return _stuff_into_wav(_synth_knock(r), RATE)
		"far_steps":
			return _stuff_into_wav(_synth_far_steps(r), RATE)
		"whisper":
			return _stuff_into_wav(_synth_whisper(r), RATE)
		"pa_chime":
			return _stuff_into_wav(_synth_beeps([[659.25, 0.0], [523.25, 0.45], [392.0, 0.9]], 2.6, 1.8, 0.3), RATE)
		"train_far":
			return _stuff_into_wav(_synth_train(r), AMB_RATE)
		"drip":
			return _stuff_into_wav(_synth_drip(), RATE)
		"riser":
			return _stuff_into_wav(_synth_riser(r), RATE)
		"boom":
			return _stuff_into_wav(_synth_boom(r), RATE)
		"heartbeat":
			return _stuff_into_wav(_synth_heartbeat(), RATE)
		"scratch":
			return _stuff_into_wav(_synth_scratch(r), RATE)
		"breath":
			return _stuff_into_wav(_synth_breath(r), RATE)
		"sting":
			return _stuff_into_wav(_synth_sting(r), RATE)
		"glitch":
			return _stuff_into_wav(_synth_glitch(r), RATE)
		"amb_hotel":
			return _stuff_into_wav(_vibes_hotel(r), AMB_RATE, true)
		"amb_station":
			return _stuff_into_wav(_vibes_station(r), AMB_RATE, true)
		"amb_metro":
			return _stuff_into_wav(_vibes_metro(r), AMB_RATE, true)
		"music_menu":
			return _stuff_into_wav(_synth_pad(r), AMB_RATE, true)
	push_warning("Неизвестный звук: " + id)
	return _stuff_into_wav(PackedFloat32Array([0.0, 0.0]), RATE)


func _stuff_into_wav(data: PackedFloat32Array, rate: int, loop = false) -> AudioStreamWAV:
	var bytes = PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = data.size()
	return s


func _buffer_thing(seconds: float, rate = RATE) -> PackedFloat32Array:
	var a = PackedFloat32Array()
	a.resize(int(seconds * rate))
	return a


func _make_it_loop(a: PackedFloat32Array, fade: int) -> PackedFloat32Array:
	var n = a.size() - fade
	var output_pile = PackedFloat32Array()
	output_pile.resize(n)
	for i in n:
		output_pile[i] = a[i]
	for i in fade:
		var k = float(i) / fade
		output_pile[i] = a[n + i] * (1.0 - k) + a[i] * k
	return output_pile


func _synth_step(r: RandomNumberGenerator, cutoff: float, wiggle: float) -> PackedFloat32Array:
	var a = _buffer_thing(0.2)
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		lp += cutoff * (r.randf_range(-1, 1) - lp)
		var env = exp(-t * 32.0) * (1.0 - exp(-t * 900.0))
		a[i] = (lp * 1.6 + sin(TAU * 72.0 * t) * 0.5 * exp(-t * 45.0)) * env * wiggle
	return a


func _synth_door_open(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(1.2)
	var ph = 0.0
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		var f = 170.0 + 70.0 * sin(t * 2.6) + r.randf_range(-12, 12)
		ph += TAU * f / RATE
		var stick = pow(absf(sin(t * 21.0 + sin(t * 5.0))), 4.0)
		var env = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.75, 1.15, t))
		lp += 0.18 * ((1.0 if sin(ph) > 0.0 else -1.0) * stick - lp)
		var latch = r.randf_range(-1, 1) * exp(-t * 90.0)
		a[i] = lp * env * 0.35 + latch * 0.5
	return a


func _synth_door_close(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(0.7)
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		lp += 0.08 * (r.randf_range(-1, 1) - lp)
		var click = r.randf_range(-1, 1) * exp(-maxf(t - 0.12, 0.0) * 120.0) * (1.0 if t > 0.12 else 0.0)
		a[i] = sin(TAU * 52.0 * t) * exp(-t * 8.0) * 0.7 + lp * exp(-t * 18.0) * 1.5 + click * 0.25
	return a


func _synth_beeps(notes: Array, length: float, decay: float, wiggle: float) -> PackedFloat32Array:
	var a = _buffer_thing(length)
	for i in a.size():
		var t = float(i) / RATE
		var v = 0.0
		for n in notes:
			var dt: float = t - float(n[1])
			if dt < 0.0:
				continue
			var f: float = n[0]
			var env = exp(-dt * decay) * (1.0 - exp(-dt * 300.0))
			v += (sin(TAU * f * dt) + 0.25 * sin(TAU * f * 2.0 * dt) + 0.08 * sin(TAU * f * 3.0 * dt)) * env
		a[i] = v * wiggle
	return a


func _synth_bell(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(2.0)
	var ratios = [1.0, 2.76, 5.4, 8.93]
	var amps = [1.0, 0.45, 0.25, 0.1]
	var decays = [2.2, 3.5, 6.0, 9.0]
	for i in a.size():
		var t = float(i) / RATE
		var v = r.randf_range(-1, 1) * exp(-t * 200.0) * 0.4
		for k in 4:
			v += sin(TAU * 2350.0 * float(ratios[k]) * t) * float(amps[k]) * exp(-t * float(decays[k]))
		a[i] = v * 0.22
	return a


func _synth_wrong() -> PackedFloat32Array:
	var a = _buffer_thing(1.1)
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		var saw = fposmod(t * 98.0, 1.0) * 2.0 - 1.0 + fposmod(t * 103.8, 1.0) * 2.0 - 1.0
		lp += 0.06 * (saw - lp)
		var env = (1.0 - exp(-t * 60.0)) * exp(-t * 2.8)
		a[i] = (lp * 0.8 + sin(TAU * 49.0 * t) * 0.5) * env * 0.5
	return a


func _synth_blip(freq: float, length: float, decay: float, wiggle: float) -> PackedFloat32Array:
	var a = _buffer_thing(length)
	for i in a.size():
		var t = float(i) / RATE
		a[i] = sin(TAU * freq * t) * exp(-t * decay) * wiggle
	return a


func _synth_click(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(0.09)
	for i in a.size():
		var t = float(i) / RATE
		a[i] = (sin(TAU * (900.0 - t * 4000.0) * t) * 0.5 + r.randf_range(-1, 1) * 0.3) * exp(-t * 70.0) * 0.4
	return a


func _synth_tick(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(0.06)
	var prev = 0.0
	for i in a.size():
		var t = float(i) / RATE
		var n = r.randf_range(-1, 1)
		a[i] = (n - prev) * exp(-t * 180.0) * 0.5
		prev = n
	return a


func _synth_knock(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(1.4)
	var hits = [0.0, 0.26, 0.52]
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		lp += 0.15 * (r.randf_range(-1, 1) - lp)
		var v = 0.0
		for h in hits:
			var dt: float = t - float(h)
			if dt >= 0.0:
				v += (sin(TAU * 135.0 * dt) * exp(-dt * 32.0) + lp * exp(-dt * 70.0) * 1.2)
		a[i] = v * 0.6
	return a


func _synth_far_steps(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(4.2)
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		lp += 0.05 * (r.randf_range(-1, 1) - lp)
		var v = 0.0
		for k in 6:
			var dt = t - k * 0.62
			if dt >= 0.0 and dt < 0.3:
				v += (lp * 3.0 + sin(TAU * 60.0 * dt) * 0.6) * exp(-dt * 26.0)
		a[i] = v * 0.7
	return a


func _synth_whisper(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(2.6)
	var low = 0.0
	var band = 0.0
	for i in a.size():
		var t = float(i) / RATE
		var fc = 900.0 + 700.0 * sin(t * 3.1) + 500.0 * sin(t * 7.3)
		var f = 2.0 * sin(PI * fc / RATE)
		var x = r.randf_range(-1, 1)
		low += f * band
		var high = x - low - 0.5 * band
		band += f * high
		var syll = pow(absf(sin(t * 6.5 + sin(t * 2.0))), 2.0)
		var env = smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(2.1, 2.6, t))
		a[i] = band * syll * env * 0.5
	return a


func _synth_train(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(7.0, AMB_RATE)
	var lp = 0.0
	for i in a.size():
		var t = float(i) / AMB_RATE
		lp += 0.03 * (r.randf_range(-1, 1) - lp)
		var env = sin(PI * t / 7.0)
		var clack = 0.0
		var ph = fposmod(t * 1.8, 1.0)
		if ph < 0.04:
			clack = r.randf_range(-1, 1) * 0.3
		a[i] = (lp * 3.0 + sin(TAU * 38.0 * t) * 0.3 + sin(TAU * 57.0 * t) * 0.15 + clack) * env * env * 0.5
	return a


func _synth_drip() -> PackedFloat32Array:
	var a = _buffer_thing(0.3)
	for i in a.size():
		var t = float(i) / RATE
		a[i] = sin(TAU * (1100.0 + 2400.0 * t) * t) * exp(-t * 28.0) * 0.35
	return a


func _synth_riser(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(1.5)
	var low = 0.0
	var band = 0.0
	for i in a.size():
		var t = float(i) / RATE
		var fc = 200.0 + 2600.0 * pow(t / 1.5, 2.0)
		var f = 2.0 * sin(PI * minf(fc, 5000.0) / RATE)
		low += f * band
		band += f * (r.randf_range(-1, 1) - low - 0.4 * band)
		a[i] = band * pow(t / 1.5, 1.5) * 0.4 + sin(TAU * 55.0 * t) * 0.2 * (t / 1.5)
	return a


func _synth_boom(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(2.5)
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		lp += 0.02 * (r.randf_range(-1, 1) - lp)
		a[i] = (sin(TAU * (48.0 - t * 6.0) * t) * 0.8 + lp * 4.0) * exp(-t * 1.8) * 0.6
	return a


# ---- жуткие звуки ----

# Тук-тук: два глухих удара сердца.
func _synth_heartbeat() -> PackedFloat32Array:
	var a = _buffer_thing(0.9)
	for i in a.size():
		var t = float(i) / RATE
		var v = 0.0
		for hit in [[0.0, 1.0], [0.24, 0.72]]:
			var dt: float = t - float(hit[0])
			if dt >= 0.0:
				var env = exp(-dt * 18.0) * (1.0 - exp(-dt * 350.0))
				v += sin(TAU * (58.0 - dt * 70.0) * dt) * env * float(hit[1])
		a[i] = v * 0.95
	return a


# Ногти по дереву: несколько резких шершавых проходов.
func _synth_scratch(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(1.6)
	var prev = 0.0
	var low = 0.0
	for i in a.size():
		var t = float(i) / RATE
		var x = r.randf_range(-1, 1)
		var hp = x - prev
		prev = x
		low += 0.35 * (hp - low)
		var v = 0.0
		for k in 4:
			var dt = t - k * 0.34 - r.randf() * 0.002
			var ln = 0.22 + 0.04 * k
			if dt >= 0.0 and dt < ln:
				var grit = 0.55 + 0.45 * sin(TAU * (34.0 + k * 9.0) * dt)
				v += low * sin(PI * dt / ln) * grit
		a[i] = v * 0.9
	return a


# Тяжёлое медленное дыхание: вдох — пауза — выдох.
func _synth_breath(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(3.4)
	var low = 0.0
	var band = 0.0
	for i in a.size():
		var t = float(i) / RATE
		var inhale = smoothstep(0.0, 0.5, t) * (1.0 - smoothstep(0.9, 1.3, t))
		var exhale = smoothstep(1.5, 1.8, t) * (1.0 - smoothstep(2.4, 3.3, t))
		var fc = 700.0 + 500.0 * inhale - 250.0 * exhale
		var f = 2.0 * sin(PI * fc / RATE)
		low += f * band
		band += f * (r.randf_range(-1, 1) - low - 0.6 * band)
		a[i] = (band * (inhale * 0.7 + exhale)) * 0.8 + low * exhale * 0.25
	return a


# Резкий хоррор-удар при ошибке: диссонанс + шум + провал вниз.
func _synth_sting(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(2.0)
	var lp = 0.0
	for i in a.size():
		var t = float(i) / RATE
		lp += 0.25 * (r.randf_range(-1, 1) - lp)
		var drop = 1.0 - 0.35 * minf(t / 1.6, 1.0)
		var v = 0.0
		for f in [98.0, 103.8, 146.8, 207.6, 311.1]:
			v += sin(TAU * f * drop * t + sin(t * 9.0) * 0.4)
		var env = (1.0 - exp(-t * 90.0)) * exp(-t * 1.6)
		a[i] = (v * 0.16 + lp * exp(-t * 7.0) * 0.9) * env
	return a


# Цифровой треск глитча.
func _synth_glitch(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(0.35)
	var hold = 0.0
	for i in a.size():
		if i % (40 + (i / 300) % 7 * 30) == 0:
			hold = r.randf_range(-1, 1)
		var t = float(i) / RATE
		a[i] = hold * exp(-t * 6.0) * 0.35 * (1.0 if fposmod(t * 37.0, 1.0) > 0.3 else 0.2)
	return a


func _vibes_hotel(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(8.5, AMB_RATE)
	var lp = 0.0
	var lp2 = 0.0
	for i in a.size():
		var t = float(i) / AMB_RATE
		lp += 0.04 * (r.randf_range(-1, 1) - lp)
		lp2 += 0.3 * (lp - lp2)
		var hum = sin(TAU * 60.0 * t) * 0.05 + sin(TAU * 120.0 * t) * 0.025 + sin(TAU * 180.0 * t) * 0.01
		a[i] = lp2 * 1.4 * (0.85 + 0.15 * sin(TAU * t / 8.0)) + hum
	return _make_it_loop(a, AMB_RATE / 2)


func _vibes_station(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(10.5, AMB_RATE)
	var lp = 0.0
	var buzz = 0.0
	for i in a.size():
		var t = float(i) / AMB_RATE
		var cut = 0.02 + 0.015 * sin(TAU * t / 10.0)
		lp += cut * (r.randf_range(-1, 1) - lp)
		var sq = 1.0 if sin(TAU * 100.0 * t) > 0.0 else -1.0
		buzz += 0.05 * (sq - buzz)
		a[i] = lp * 2.4 * (0.6 + 0.4 * sin(TAU * t / 10.0 + 1.0)) + buzz * 0.02
	return _make_it_loop(a, AMB_RATE / 2)


func _vibes_metro(r: RandomNumberGenerator) -> PackedFloat32Array:
	var a = _buffer_thing(10.5, AMB_RATE)
	var lp = 0.0
	var drip_pile = [1.3, 4.7, 6.2, 8.9]
	for i in a.size():
		var t = float(i) / AMB_RATE
		lp += 0.012 * (r.randf_range(-1, 1) - lp)
		var v = lp * 3.5 + sin(TAU * 41.2 * t) * 0.08 + sin(TAU * 61.8 * t) * 0.03 * (0.5 + 0.5 * sin(TAU * t / 10.0))
		for d in drip_pile:
			var dt: float = t - float(d)
			if dt >= 0.0 and dt < 0.25:
				v += sin(TAU * (900.0 + 1800.0 * dt) * dt) * exp(-dt * 30.0) * 0.12
		a[i] = v
	return _make_it_loop(a, AMB_RATE / 2)


func _synth_pad(r: RandomNumberGenerator) -> PackedFloat32Array:
	var length = 16.0
	var a = _buffer_thing(length, AMB_RATE)
	var notes = [55.0, 110.0, 164.8125, 220.0, 246.9375, 329.625]
	var amps = [0.35, 0.28, 0.2, 0.14, 0.1, 0.07]
	var lp = 0.0
	for i in a.size():
		var t = float(i) / AMB_RATE
		var v = 0.0
		for k in notes.size():
			var f: float = notes[k]
			var lfo = 0.6 + 0.4 * sin(TAU * t * float(k + 1) / length + k)
			v += (sin(TAU * f * t) + 0.5 * sin(TAU * (f + 0.125) * t)) * float(amps[k]) * lfo
		lp += 0.02 * (r.randf_range(-1, 1) - lp)
		a[i] = v * 0.22 + lp * 0.6
	return a
