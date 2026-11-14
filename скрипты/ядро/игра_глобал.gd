extends Node

signal settings_got_changed

const Progress = preload("res://скрипты/прогресс/прогресс.gd")
const MENU_SCENE = "res://сцены/главное_меню/главное_меню.tscn"
const GAME_SCENE = "res://сцены/игра/игра.tscn"

var progress = Progress.new()
var nerd_mode = false

var _font_stash = {}
var _black_rect: ColorRect
var _im_busy = false


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	nerd_mode = OS.is_debug_build()
	_bind_the_buttons()
	progress.dig_up_save()
	_cook_fonts()
	_cook_fade()
	fix_the_screen()


func setting(key: String) -> Variant:
	return progress.settings.get(key, Progress.FACTORY_SETTINGS.get(key))


func shove_setting(key: String, value: Variant):
	progress.settings[key] = value
	progress.stuff_save_in_box()
	fix_the_screen()
	settings_got_changed.emit()


func quality() -> int:
	return clampi(int(setting("quality")), 0, 2)


func shadow_pocket_money() -> int:
	return [0, 1, 4][quality()]


func fix_the_screen():
	if DisplayServer.get_name() != "headless":
		var fs: bool = setting("fullscreen")
		var mode = DisplayServer.window_get_mode()
		if fs and mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not fs and mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if setting("vsync") else DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(setting("volume")), 0.0001)))
	var vp = get_viewport()
	var q = quality()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if q == 0 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = [0.7, 0.9, 1.0][q]
	vp.msaa_3d = Viewport.MSAA_2X if q >= 2 else Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED if q >= 1 else Viewport.SCREEN_SPACE_AA_FXAA
	vp.positional_shadow_atlas_size = [1024, 512, 2048][q]


func make_env_less_fancy(env: Environment, _cfg: Dictionary):
	env.glow_enabled = quality() >= 2
	env.ssao_enabled = false
	env.volumetric_fog_enabled = false


func font(kind = "ui") -> Font:
	return _font_stash.get(kind, _font_stash["ui"])


func _cook_fonts():

	var plain = SystemFont.new()
	plain.font_names = PackedStringArray(["Segoe UI", "Arial"])
	var bold = SystemFont.new()
	bold.font_names = PackedStringArray(["Segoe UI", "Arial"])
	bold.font_weight = 700
	for kind in ["ui", "light", "hero", "title", "wide", "cond", "serif"]:
		_font_stash[kind] = plain
	_font_stash["bold"] = bold


func _cook_fade():
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_black_rect = ColorRect.new()
	_black_rect.color = Color(0, 0, 0, 1)
	_black_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_black_rect)


func go_dark(t = 0.6):
	_black_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tweeny = create_tween()
	tweeny.tween_property(_black_rect, "color:a", 1.0, t)
	await tweeny.finished


func come_back_to_light(t = 0.8):
	var tweeny = create_tween()
	tweeny.tween_property(_black_rect, "color:a", 0.0, t)
	await tweeny.finished
	_black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func yeet_to_scene(path: String):
	if _im_busy:
		return
	_im_busy = true
	await go_dark(0.6)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	_im_busy = false


func _bind_the_buttons():
	var map = {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E],
		"flashlight": [KEY_F],
		"hint": [KEY_H],
		"pause": [KEY_ESCAPE],
		"debug": [KEY_F10],
	}
	for action in map:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in map[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
