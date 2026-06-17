extends Node
class_name GameSettingsManager

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"

var master_volume := 0.8
var music_volume := 0.7
var sfx_volume := 0.85
var fullscreen := false
var vsync_enabled := true
var tutorials_enabled := true
var text_speed := 36.0


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	master_volume = float(config.get_value("audio", "master_volume", master_volume))
	music_volume = float(config.get_value("audio", "music_volume", music_volume))
	sfx_volume = float(config.get_value("audio", "sfx_volume", sfx_volume))
	fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))
	vsync_enabled = bool(config.get_value("video", "vsync", vsync_enabled))
	tutorials_enabled = bool(config.get_value("gameplay", "tutorials", tutorials_enabled))
	text_speed = float(config.get_value("gameplay", "text_speed", text_speed))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync_enabled)
	config.set_value("gameplay", "tutorials", tutorials_enabled)
	config.set_value("gameplay", "text_speed", text_speed)
	config.save(SETTINGS_PATH)


func apply_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	settings_changed.emit()


func commit() -> void:
	apply_settings()
	save_settings()


func _set_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus_index, value <= 0.001)
