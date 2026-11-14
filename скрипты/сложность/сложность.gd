extends RefCounted

const ORDER = ["easy", "normal", "hard"]

const LEVELS = {
	"easy": {
		"id": "easy",
		"title": "EASY",
		"tagline": "Learn to look.",
		"bullets": [
			"Obvious anomalies",
			"Up to 2 anomalies per round",
			"No time limit",
			"3 mistakes allowed",
			"Optional hints (press H)",
		],
		"count_weights": [22.0, 50.0, 28.0],
		"subtlety_weights": {1: 6.0, 2: 3.0, 3: 0.4},
		"time_limit": 0.0,
		"mistakes": 3,
		"hints": true,
	},
	"normal": {
		"id": "normal",
		"title": "NORMAL",
		"tagline": "Trust your memory.",
		"bullets": [
			"Mixed anomaly visibility",
			"Up to 3 anomalies per round",
			"3 minutes per round",
			"2 mistakes allowed",
			"No hints",
		],
		"count_weights": [18.0, 32.0, 30.0, 20.0],
		"subtlety_weights": {1: 3.0, 2: 4.0, 3: 2.0},
		"time_limit": 180.0,
		"mistakes": 2,
		"hints": false,
	},
	"hard": {
		"id": "hard",
		"title": "HARD",
		"tagline": "Doubt everything.",
		"bullets": [
			"Very subtle anomalies",
			"Up to 4 anomalies per round",
			"90 seconds per round",
			"1 mistake allowed",
			"No hints",
		],
		"count_weights": [14.0, 22.0, 26.0, 22.0, 16.0],
		"subtlety_weights": {1: 0.8, 2: 3.0, 3: 5.0},
		"time_limit": 90.0,
		"mistakes": 1,
		"hints": false,
	},
}


static func gimme_difficulty(id: String) -> Dictionary:
	if LEVELS.has(id):
		return LEVELS[id]
	return LEVELS["normal"]
