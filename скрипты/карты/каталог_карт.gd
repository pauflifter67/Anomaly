extends RefCounted

const UNLOCK_ROUNDS = 3

const LIST = [
	{
		"id": "hotel",
		"title": "THE HOTEL",
		"subtitle": "Meridian Grand - 7th floor",
		"desc": "A silent luxury corridor. Doors, lamps, paintings - everything is exactly where it should be. Until it is not.",
		"recommend": "EASY - NORMAL",
		"unit": "CORRIDOR",
		"bonus": 0,
		"script": "res://скрипты/карты/отель.gd",
		"preview": "res://ассеты/текстуры/превью/отель.png",
		"requires": "",
	},
	{
		"id": "station",
		"title": "THE STATION",
		"subtitle": "Hollowmere Terminus - last departure",
		"desc": "A terminus where no train has left in years. Clocks, boards and platforms repeat forever - almost.",
		"recommend": "NORMAL",
		"unit": "PLATFORM",
		"bonus": 0,
		"script": "res://скрипты/карты/вокзал.gd",
		"preview": "res://ассеты/текстуры/превью/вокзал.png",
		"requires": "hotel",
	},
	{
		"id": "underground",
		"title": "THE UNDERGROUND",
		"subtitle": "Blackwater line - sealed 19 years ago",
		"desc": "A flooded-out metro platform in near darkness. More to watch, less to see. The hardest protocol.",
		"recommend": "HARD",
		"unit": "TUNNEL",
		"bonus": 1,
		"script": "res://скрипты/карты/метро.gd",
		"preview": "res://ассеты/текстуры/превью/метро.png",
		"requires": "station",
	},
]


static func gimme_map(id: String) -> Dictionary:
	for m in LIST:
		if m["id"] == id:
			return m
	return LIST[0]


static func whats_next(id: String) -> Dictionary:
	for m in LIST:
		if m["requires"] == id:
			return m
	return {}
