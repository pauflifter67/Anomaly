extends RefCounted

const Catalog = preload("res://скрипты/карты/каталог_карт.gd")

const FACTORY_SETTINGS = {
	"quality": 1,
	"fullscreen": false,
	"vsync": true,
	"sensitivity": 0.22,
	"fov": 75.0,
	"volume": 0.8,
	"head_bob": true,
	"language": "en",
	"fx": true,
}

var path = "user://second_wind.cfg"
var settings = {}
var picked_map = "hotel"
var picked_difficulty = "normal"
var open_maps: Array = ["hotel"]
var best = {}
var cleared_total_lol = 0
var oopsies_total_lol = 0
var runs_total_lol = 0
var records = {}


func _init():
	settings = FACTORY_SETTINGS.duplicate()


func dig_up_save():
	var cf = ConfigFile.new()
	if cf.load(path) != OK:
		return
	for k in FACTORY_SETTINGS:
		settings[k] = cf.get_value("settings", k, FACTORY_SETTINGS[k])
	picked_map = cf.get_value("progress", "selected_map", "hotel")
	picked_difficulty = cf.get_value("progress", "selected_difficulty", "normal")
	open_maps = cf.get_value("progress", "unlocked", ["hotel"])
	best = cf.get_value("progress", "best", {})
	cleared_total_lol = cf.get_value("progress", "total_cleared", 0)
	oopsies_total_lol = cf.get_value("progress", "total_mistakes", 0)
	runs_total_lol = cf.get_value("progress", "total_runs", 0)
	records = cf.get_value("progress", "records", {})
	if not open_maps.has("hotel"):
		open_maps.append("hotel")


func stuff_save_in_box():
	var cf = ConfigFile.new()
	for k in settings:
		cf.set_value("settings", k, settings[k])
	cf.set_value("progress", "selected_map", picked_map)
	cf.set_value("progress", "selected_difficulty", picked_difficulty)
	cf.set_value("progress", "unlocked", open_maps)
	cf.set_value("progress", "best", best)
	cf.set_value("progress", "total_cleared", cleared_total_lol)
	cf.set_value("progress", "total_mistakes", oopsies_total_lol)
	cf.set_value("progress", "total_runs", runs_total_lol)
	cf.set_value("progress", "records", records)
	cf.save(path)


func nuke_progress():
	picked_map = "hotel"
	open_maps = ["hotel"]
	best = {}
	cleared_total_lol = 0
	oopsies_total_lol = 0
	runs_total_lol = 0
	records = {}
	stuff_save_in_box()


func best_score_for_this_map(map_id: String, diff_id: String) -> int:
	return int(best.get(map_id + "/" + diff_id, 0))


func is_it_open_yet(map_id: String) -> bool:
	return open_maps.has(map_id)


func record(map_id: String) -> Dictionary:
	if not records.has(map_id):
		records[map_id] = {"runs": 0, "cleared": 0, "best": 0}
	return records[map_id]


func when_run_starts_lol(map_id: String):
	runs_total_lol += 1
	record(map_id)["runs"] += 1
	stuff_save_in_box()


func when_we_win_round(map_id: String, diff_id: String, cleared_in_run: int) -> String:
	cleared_total_lol += 1
	var r = record(map_id)
	r["cleared"] += 1
	r["best"] = maxi(int(r["best"]), cleared_in_run)
	var key = map_id + "/" + diff_id
	best[key] = maxi(int(best.get(key, 0)), cleared_in_run)
	var opened = ""
	if cleared_in_run >= Catalog.UNLOCK_ROUNDS:
		var nxt = Catalog.whats_next(map_id)
		if not nxt.is_empty() and not open_maps.has(nxt["id"]):
			open_maps.append(nxt["id"])
			opened = nxt["title"]
	stuff_save_in_box()
	return opened


# Убежал от монстра в режиме погони: рекорд хранится под ключом "карта/chase"
func when_we_outrun_monster(map_id: String, escaped_in_run: int):
	cleared_total_lol += 1
	var key = map_id + "/chase"
	best[key] = maxi(int(best.get(key, 0)), escaped_in_run)
	stuff_save_in_box()


func oopsie_happened():
	oopsies_total_lol += 1
	stuff_save_in_box()
