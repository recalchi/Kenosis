extends Node
class_name DataRegistryManager

const DATA_PATHS := {
	"lore": "res://data/lore/lore_texts.json",
	"dialogue": "res://data/dialogue/dialogue.json",
	"items": "res://data/config/items.json",
	"levels": "res://data/config/levels.json",
	"layouts": "res://data/config/location_layouts.json",
	"input": "res://data/config/input_config.json",
	"balance": "res://data/config/balance.json",
	"collectibles": "res://data/collectibles/collectibles.json",
}

var data: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	data.clear()
	for data_key in DATA_PATHS:
		data[data_key] = _read_json(DATA_PATHS[data_key])


func get_section(data_key: StringName) -> Variant:
	return data.get(String(data_key), {})


func get_balance(path: Array[String], fallback: Variant = null) -> Variant:
	var value: Variant = data.get("balance", {})
	for segment in path:
		if not value is Dictionary or not value.has(segment):
			return fallback
		value = value[segment]
	return value


func get_destination(destination_id: StringName) -> Dictionary:
	var levels: Dictionary = data.get("levels", {})
	for destination in levels.get("map_destinations", []):
		if String(destination.get("id", "")) == String(destination_id):
			return destination
	return {}


func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataRegistry could not open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("DataRegistry found invalid JSON in %s" % path)
		return {}
	return parsed
