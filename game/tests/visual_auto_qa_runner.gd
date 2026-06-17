extends SceneTree

const OUTPUT_DIR := "res://../builds/qa/visualbot"
const TEST_ROOM_PATH := "res://scenes/levels/TestRoom.tscn"
const MAP_ROOM_PATH := "res://scenes/levels/MapTestRoom.tscn"
const STORY_ROOM_PATH := "res://scenes/levels/locations/Awakening.tscn"

var _captures: Array[Dictionary] = []
var _issues: Array[String] = []


func _init() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.begin_test_session()

	await _capture_test_room()
	await _capture_map_room()
	await _capture_story_room()

	if save_system != null:
		save_system.end_test_session()

	var report := {
		"generated_at": Time.get_datetime_string_from_system(),
		"passed": _issues.is_empty(),
		"capture_count": _captures.size(),
		"captures": _captures,
		"issues": _issues,
	}
	_write_report(report)
	print("KENOSIS_VISUAL_AUTO_QA_OK %s" % JSON.stringify(report))
	quit(0 if _issues.is_empty() else 1)


func _capture_test_room() -> void:
	var room := _instantiate_scene(TEST_ROOM_PATH)
	if room == null:
		return
	await _settle_frames(24)
	await _capture("test_room_start", "Campo de teste: estado inicial")

	var hud := room.find_child("PrototypeHUD", true, false) as PrototypeHUD
	if hud != null:
		hud.apply_tutorial_preference(false)
	var player := room.find_child("Player", true, false) as PlayerController
	var receiver := room.find_child("ResonanceReceiver", true, false)
	var resonance_system := room.find_child("ResonanceSystem", true, false) as ResonanceSystem
	var cover := room.find_child("StealthCover", true, false)
	if player != null and receiver != null and resonance_system != null:
		resonance_system.try_activate(receiver, player)
	if player != null and cover != null and cover.has_method("_on_body_entered"):
		player.global_position = Vector2(1065, 410)
		cover.call("_on_body_entered", player)
	await _settle_frames(24)
	await _capture("test_room_resonance_cover", "Ponte materializada e cobertura ativa")
	_cleanup_room(room)


func _capture_map_room() -> void:
	var room := _instantiate_scene(MAP_ROOM_PATH)
	if room == null:
		return
	await _settle_frames(30)
	var navigator := room.find_child("MapNavigator", true, false) as MapNavigator
	if navigator != null:
		navigator.set_map_visible(true)
	await _settle_frames(8)
	await _capture("map_overlay", "Mapa central aberto")
	if navigator != null:
		navigator.set_map_visible(false)
		navigator.teleport_to(&"void")
	await _settle_frames(12)
	await _capture("map_void_anchor", "Ancora do Vazio apos teleporte")
	_cleanup_room(room)


func _capture_story_room() -> void:
	var room := _instantiate_scene(STORY_ROOM_PATH)
	if room == null:
		return
	await _settle_frames(70)
	await _capture("story_dialogue", "Primeira sala narrativa com dialogo")

	var hud := room.find_child("PrototypeHUD", true, false) as PrototypeHUD
	var overlay := room.find_child("DialogueOverlay", true, false) as Control
	var guard := 0
	while hud != null and overlay != null and overlay.visible and guard < 8:
		hud.complete_dialogue_line()
		hud.advance_dialogue()
		guard += 1
	await _settle_frames(12)
	await _capture("story_gameplay", "Primeira sala narrativa jogavel")
	_cleanup_room(room)


func _instantiate_scene(scene_path: String) -> Node:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		_issue("missing_scene:%s" % scene_path)
		return null
	var room := packed.instantiate()
	root.add_child(room)
	return room


func _cleanup_room(room: Node) -> void:
	paused = false
	root.remove_child(room)
	room.queue_free()


func _settle_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _capture(name: String, label: String) -> void:
	await RenderingServer.frame_post_draw
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		_issue("capture_texture_missing:%s" % name)
		return
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		_issue("capture_image_empty:%s" % name)
		return
	var path := "%s/%s.png" % [OUTPUT_DIR, name]
	var absolute_path := ProjectSettings.globalize_path(path)
	var error := image.save_png(absolute_path)
	if error != OK:
		_issue("capture_save_failed:%s" % name)
		return
	var stats := _analyze_image(image)
	stats["name"] = name
	stats["label"] = label
	stats["path"] = absolute_path
	_captures.append(stats)
	var width := int(stats.get("width", 0))
	var height := int(stats.get("height", 0))
	var aspect := float(width) / maxf(1.0, float(height))
	if width < 1280 or height < 720 or absf(aspect - (16.0 / 9.0)) > 0.03:
		_issue("capture_wrong_size:%s" % name)
	if int(stats.get("distinct_samples", 0)) < 12:
		_issue("capture_low_detail:%s" % name)


func _analyze_image(image: Image) -> Dictionary:
	var distinct := {}
	var sample_count := 0
	var total_luma := 0.0
	var step := 32
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var color := image.get_pixel(x, y)
			var key := "%02d_%02d_%02d" % [
				int(color.r * 15.0),
				int(color.g * 15.0),
				int(color.b * 15.0),
			]
			distinct[key] = true
			total_luma += (color.r + color.g + color.b) / 3.0
			sample_count += 1
	return {
		"width": image.get_width(),
		"height": image.get_height(),
		"distinct_samples": distinct.size(),
		"average_luma": snappedf(total_luma / maxf(1.0, float(sample_count)), 0.001),
	}


func _write_report(report: Dictionary) -> void:
	var path := ProjectSettings.globalize_path("%s/latest_report.json" % OUTPUT_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))


func _issue(issue_id: String) -> void:
	if not _issues.has(issue_id):
		_issues.append(issue_id)
