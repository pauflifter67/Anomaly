extends CanvasLayer
# Экранные эффекты поверх 3D: зерно, виньетка, хроматическая аберрация,
# «плывущее» пространство (warp), глитч и красная вспышка. HUD рисуется выше (layer 10).

const SHADER_CODE = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain = 0.045;
uniform float vignette = 0.35;
uniform float aberration = 0.0012;
uniform float warp = 0.0;
uniform float glitch = 0.0;
uniform float red = 0.0;
uniform float desat = 0.0;
uniform float seed = 0.0;

float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float t = TIME;
	// пространство «дышит» и плывёт
	if (warp > 0.001) {
		uv += warp * 0.011 * vec2(sin(uv.y * 17.0 + t * 2.1), cos(uv.x * 13.0 + t * 1.6));
		uv = 0.5 + (uv - 0.5) * (1.0 - warp * 0.035 * (0.5 + 0.5 * sin(t * 1.4)));
	}
	// глитч: горизонтальные полосы съезжают
	if (glitch > 0.001) {
		float band = floor(uv.y * 26.0);
		float tick = floor(t * 24.0);
		float r = rnd(vec2(band, tick + seed));
		if (r < glitch * 0.55) {
			uv.x += (rnd(vec2(tick, band)) - 0.5) * 0.09 * glitch;
		}
	}
	float ab = aberration + warp * 0.006 + glitch * 0.014;
	vec2 dir = uv - 0.5;
	vec3 col;
	col.r = texture(screen_tex, uv + dir * ab).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - dir * ab).b;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), clamp(desat + warp * 0.25, 0.0, 1.0));
	col = mix(col, col * vec3(1.35, 0.32, 0.28) + vec3(0.10, 0.0, 0.0), clamp(red, 0.0, 1.0));
	float v = smoothstep(0.9, 0.22, length(c * vec2(1.0, 0.82)));
	col *= mix(1.0, v, vignette);
	col += (rnd(SCREEN_UV * vec2(1931.0, 1087.0) + fract(t * 7.0) * 91.0) - 0.5) * grain;
	// тонкие строки развёртки при глитче
	col *= 1.0 - glitch * 0.12 * step(0.5, fract(SCREEN_UV.y * 240.0));
	COLOR = vec4(col, 1.0);
}
"""

var rect: ColorRect
var mat: ShaderMaterial
var warp_target = 0.0
var dread = 0.0
var red_hold = 0.0
var ambient_glitches = false

var _warp = 0.0
var _glitch = 0.0
var _red = 0.0
var _random_t = 5.0


func _ready():
	if layer == 1:
		layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sh = Shader.new()
	sh.code = SHADER_CODE
	mat = ShaderMaterial.new()
	mat.shader = sh
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	add_child(rect)


func set_warp(x: float):
	warp_target = clampf(x, 0.0, 1.0)


func kick_glitch(x: float):
	_glitch = maxf(_glitch, x)
	mat.set_shader_parameter("seed", randf() * 100.0)


func flash_red(x: float):
	_red = maxf(_red, x)


func _process(delta: float):
	rect.visible = bool(Game.setting("fx"))
	if not rect.visible:
		return
	_warp = lerpf(_warp, warp_target, clampf(delta * 2.5, 0.0, 1.0))
	_glitch = maxf(0.0, _glitch - delta * 1.5)
	_red = move_toward(_red, red_hold, delta * 0.9)
	if ambient_glitches:
		_random_t -= delta
		if _random_t <= 0.0:
			_random_t = randf_range(6.0, 13.0)
			kick_glitch(randf_range(0.25, 0.55))
	# редкие микроглитчи, когда страшно (мало времени или рядом искажение)
	var fear = maxf(dread, _warp)
	if fear > 0.3 and randf() < delta * fear * 0.6:
		kick_glitch(0.2 + fear * 0.3)
	mat.set_shader_parameter("warp", _warp)
	mat.set_shader_parameter("glitch", _glitch)
	mat.set_shader_parameter("red", _red)
	mat.set_shader_parameter("grain", 0.045 + dread * 0.05)
	mat.set_shader_parameter("aberration", 0.0012 + dread * 0.004)
	mat.set_shader_parameter("vignette", 0.35 + dread * 0.3)
	mat.set_shader_parameter("desat", dread * 0.3)
