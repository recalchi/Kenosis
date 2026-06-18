extends Node

const SAVE_PATH := "user://kenosis_save.cfg"
const MAP_ACCESS_ITEM_ID := "cartographer_lens"
const LEGACY_MAP_ACCESS_ITEM_ID := "arcane_lens"

var _data := {
	"version": 2,
	"test_field_complete": false,
	"best_points": 0,
	"checkpoint": Vector2.ZERO,
	"current_location": "awakening",
	"unlocked_locations": ["awakening"],
	"observed_lore": [],
	"collected_items": [],
}
var _persistence_suspended := false
var _test_snapshot: Dictionary = {}


func _ready() -> void:
	load_save()


func mark_test_field_complete(points: int) -> void:
	_data.test_field_complete = true
	_data.best_points = maxi(int(_data.best_points), points)
	save()


func record_checkpoint(position: Vector2, points: int) -> void:
	_data.checkpoint = position
	_data.best_points = maxi(int(_data.best_points), points)
	save()


func set_current_location(location_id: StringName) -> void:
	_data.current_location = String(location_id)
	unlock_location(location_id)
	save()


func get_current_location() -> StringName:
	return StringName(_data.current_location)


func unlock_location(location_id: StringName) -> void:
	var id := String(location_id)
	var unlocked: Array = _data.unlocked_locations
	if not unlocked.has(id):
		unlocked.append(id)
		_data.unlocked_locations = unlocked
		save()


func is_location_unlocked(location_id: StringName) -> bool:
	return String(location_id) in _data.unlocked_locations


func mark_lore_observed(lore_id: StringName) -> bool:
	var id := String(lore_id)
	var observed: Array = _data.observed_lore
	if observed.has(id):
		return false
	observed.append(id)
	_data.observed_lore = observed
	save()
	return true


func is_lore_observed(lore_id: StringName) -> bool:
	return String(lore_id) in _data.observed_lore


func collect_item(item_id: StringName) -> bool:
	var id := String(item_id)
	var collected: Array = _data.collected_items
	if collected.has(id):
		return false
	collected.append(id)
	_data.collected_items = collected
	save()
	return true


func has_map_access() -> bool:
	var collected: Array = _data.collected_items
	return collected.has(MAP_ACCESS_ITEM_ID) or collected.has(LEGACY_MAP_ACCESS_ITEM_ID)


func set_map_access(enabled: bool) -> void:
	var collected: Array = _data.collected_items
	if enabled:
		if not collected.has(MAP_ACCESS_ITEM_ID):
			collected.append(MAP_ACCESS_ITEM_ID)
	else:
		for id in [MAP_ACCESS_ITEM_ID, LEGACY_MAP_ACCESS_ITEM_ID]:
			if collected.has(id):
				collected.erase(id)
	_data.collected_items = collected
	save()


func get_data() -> Dictionary:
	return _data.duplicate(true)


func get_save_path() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)


func begin_test_session() -> void:
	if _persistence_suspended:
		return
	_test_snapshot = _data.duplicate(true)
	_persistence_suspended = true


func end_test_session() -> void:
	if not _persistence_suspended:
		return
	_data = _test_snapshot.duplicate(true)
	_test_snapshot.clear()
	_persistence_suspended = false


func save() -> void:
	if _persistence_suspended:
		return
	var config := ConfigFile.new()
	for key in _data:
		config.set_value("progress", key, _data[key])
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Nao foi possivel salvar o progresso: %s" % error_string(error))


func load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for key in _data:
		_data[key] = config.get_value("progress", key, _data[key])
	if int(_data.version) < 2:
		_data.version = 2
		if not _data.has("current_location"):
			_data.current_location = "awakening"
		if not _data.has("unlocked_locations"):
			_data.unlocked_locations = ["awakening"]
		if not _data.has("observed_lore"):
			_data.observed_lore = []
		if not _data.has("collected_items"):
			_data.collected_items = []
		save()
