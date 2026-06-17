extends SceneTree

const MAP_ROOM_PATH := "res://scenes/levels/MapTestRoom.tscn"
const OUTPUT_DIR := "res://../builds/qa/mapbot"

var _issues: Array[String] = []
var _teleports: Array[Dictionary] = []
var _selected_count := 0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.begin_test_session()

	var packed: PackedScene = load(MAP_ROOM_PATH)
	var room := packed.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	var player := room.find_child("Player", true, false) as PlayerController
	var navigator := room.find_child("MapNavigator", true, false) as MapNavigator
	var overlay := room.find_child("WorldMapOverlay", true, false) as Control
	var gps_label := room.find_child("GPSPanel", true, false)
	var enemy_root := room.find_child("ExpansionEnemies", true, false)

	if player == null:
		_issue("missing_player")
	if navigator == null:
		_issue("missing_map_navigator")
	if overlay == null:
		_issue("missing_world_map_overlay")
	if gps_label == null:
		_issue("missing_gps")
	if enemy_root == null or enemy_root.get_child_count() < 4:
		_issue("missing_expansion_enemies")

	if _issues.is_empty():
		navigator.destination_selected.connect(func(_id: StringName, _position: Vector2) -> void:
			_selected_count += 1
		)
		_validate_overlay(navigator, overlay)
		await _validate_destinations(player, navigator)

	var report := {
		"generated_at": Time.get_datetime_string_from_system(),
		"passed": _issues.is_empty(),
		"destination_count": navigator.destinations.size() if navigator != null else 0,
		"teleport_count": _teleports.size(),
		"destination_selected_count": _selected_count,
		"teleports": _teleports,
		"issues": _issues,
	}
	_write_report(report)

	if save_system != null:
		save_system.end_test_session()
	root.remove_child(room)
	room.queue_free()
	for _frame in range(3):
		await process_frame

	print("KENOSIS_MAP_AUTO_QA_OK %s" % JSON.stringify(report))
	quit(0 if _issues.is_empty() else 1)


func _validate_overlay(navigator: MapNavigator, overlay: Control) -> void:
	if overlay.visible:
		_issue("map_overlay_should_start_hidden")
	navigator.set_map_visible(true)
	if not overlay.visible or not paused:
		_issue("map_overlay_did_not_pause")
	navigator.set_map_visible(false)
	if overlay.visible or paused:
		_issue("map_overlay_did_not_resume")


func _validate_destinations(player: PlayerController, navigator: MapNavigator) -> void:
	if navigator.destinations.size() != 5:
		_issue("expected_five_map_anchors")
		return

	for destination_id in navigator.destinations:
		var destination: Dictionary = navigator.destinations[destination_id]
		var expected_position: Vector2 = destination.get("position", Vector2.ZERO)
		var returned_position := navigator.teleport_to(StringName(destination_id))
		await process_frame
		var distance := player.global_position.distance_to(expected_position)
		_teleports.append({
			"id": String(destination_id),
			"x": snappedf(player.global_position.x, 0.1),
			"y": snappedf(player.global_position.y, 0.1),
			"distance_to_anchor": snappedf(distance, 0.1),
		})
		if returned_position.distance_to(expected_position) > 0.1:
			_issue("teleport_return_mismatch:%s" % destination_id)
		if absf(player.global_position.x - expected_position.x) > 2.0 or absf(player.global_position.y - expected_position.y) > 6.0:
			_issue("player_anchor_mismatch:%s" % destination_id)
		if player.checkpoint_position.distance_to(expected_position) > 2.0:
			_issue("checkpoint_anchor_mismatch:%s" % destination_id)
		if player.global_position.y > 520.0:
			_issue("teleport_spawned_below_safe_floor:%s" % destination_id)


func _write_report(report: Dictionary) -> void:
	var path := ProjectSettings.globalize_path("%s/latest_report.json" % OUTPUT_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))


func _issue(issue_id: String) -> void:
	if not _issues.has(issue_id):
		_issues.append(issue_id)
