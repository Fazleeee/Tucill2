class_name SaveSystem
extends RefCounted

const SAVE_PATH: String = "user://save_data.json"

static func get_default_data() -> Dictionary:
	return {
		"high_score": 0,
		"best_wave": 1,
		"total_kills": 0,
		"bgm_volume": 0.7,
		"sfx_volume": 0.85
	}

static func load_data() -> Dictionary:
	var defaults: Dictionary = get_default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		save_data(defaults)
		return defaults
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return defaults
	var result: Dictionary = defaults.duplicate()
	for key in parsed.keys():
		result[key] = parsed[key]
	return result

static func save_data(data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

static func update_stats(score: int, wave: int, kills: int) -> Dictionary:
	var data: Dictionary = load_data()
	if score > int(data.get("high_score", 0)):
		data["high_score"] = score
	if wave > int(data.get("best_wave", 1)):
		data["best_wave"] = wave
	data["total_kills"] = int(data.get("total_kills", 0)) + kills
	save_data(data)
	return data

static func update_audio_settings(bgm_vol: float, sfx_vol: float) -> void:
	var data: Dictionary = load_data()
	data["bgm_volume"] = clampf(bgm_vol, 0.0, 1.0)
	data["sfx_volume"] = clampf(sfx_vol, 0.0, 1.0)
	save_data(data)

static func reset_data() -> Dictionary:
	var current: Dictionary = load_data()
	var fresh: Dictionary = get_default_data()
	fresh["bgm_volume"] = current.get("bgm_volume", 0.7)
	fresh["sfx_volume"] = current.get("sfx_volume", 0.85)
	save_data(fresh)
	return fresh
