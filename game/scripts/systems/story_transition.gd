extends Node

var pending_spawn: StringName = &"default"
var _transitioning := false
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade()


func travel_to_location(location_id: StringName, spawn_id: StringName = &"default") -> void:
	if _transitioning:
		return
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		return
	var levels: Dictionary = registry.get_section(&"levels")
	var locations: Dictionary = levels.get("story_locations", {})
	var profile: Dictionary = locations.get(String(location_id), {})
	if profile.is_empty():
		push_warning("Unknown story location: %s" % location_id)
		return
	var scene_path := String(profile.get("scene", ""))
	if not ResourceLoader.exists(scene_path):
		push_warning("Story location scene not found: %s" % scene_path)
		return

	pending_spawn = spawn_id
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.set_current_location(location_id)
	get_tree().paused = false
	await _fade_to(1.0, 0.22)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _fade_to(0.0, 0.28)
	_transitioning = false


func return_to_hub() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	await _fade_to(1.0, 0.22)
	get_tree().change_scene_to_file("res://scenes/ui/MenuHub.tscn")
	await get_tree().process_frame
	await _fade_to(0.0, 0.28)
	_transitioning = false


func consume_pending_spawn() -> StringName:
	var spawn := pending_spawn
	pending_spawn = &"default"
	return spawn


func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "StoryFadeLayer"
	_fade_layer.layer = 200
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "StoryFade"
	_fade_rect.color = Color(0.005, 0.008, 0.012, 1.0)
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_layer.add_child(_fade_rect)


func _fade_to(alpha: float, duration: float) -> void:
	_transitioning = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "modulate:a", alpha, duration)
	await tween.finished
