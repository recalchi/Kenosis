extends SceneTree

const MAP_ROOM_PATH := "res://scenes/levels/MapTestRoom.tscn"
const OUTPUT_DIR := "res://../builds/qa/mapbot"

var _issues: Array[String] = []
var _teleports: Array[Dictionary] = []
var _selected_count := 0
var _central_hotspot_count := 0

const EXPECTED_ATLAS_POINTS := {
	"awakening": Vector2(417, 141),
	"echo_trail": Vector2(261, 246),
	"forgotten_sanctuary": Vector2(795, 203),
	"forge": Vector2(638, 592),
	"void_heart": Vector2(652, 879),
	"rebirth": Vector2(677, 1036),
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.begin_test_session()
		var test_data: Dictionary = save_system.get_data()
		test_data["current_location"] = "awakening"
		test_data["unlocked_locations"] = ["awakening"]
		save_system.set("_data", test_data)
		if save_system.has_method("set_map_access"):
			save_system.set_map_access(false)

	var packed: PackedScene = load(MAP_ROOM_PATH)
	var room := packed.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	var player := room.find_child("Player", true, false) as PlayerController
	var navigator := room.find_child("MapNavigator", true, false) as MapNavigator
	var overlay := room.find_child("WorldMapOverlay", true, false) as Control
	var gps_label := room.find_child("GPSPanel", true, false)
	var objective_panel := room.find_child("ObjectivePanel", true, false)
	var current_location_label := room.find_child("CurrentLocationLabel", true, false) as Label
	var objective_points_label := room.find_child("ObjectivePointsLabel", true, false) as Label
	var enemy_root := room.find_child("ExpansionEnemies", true, false)
	var map_access_pickup := room.find_child("MapAccessPickup", true, false)

	if player == null:
		_issue("missing_player")
	if navigator == null:
		_issue("missing_map_navigator")
	if overlay == null:
		_issue("missing_world_map_overlay")
	if gps_label != null:
		_issue("separate_gps_panel_should_not_exist")
	if objective_panel == null:
		_issue("missing_unified_mission_navigation_panel")
	if current_location_label == null:
		_issue("missing_current_location_label")
	if objective_points_label == null:
		_issue("missing_objective_points_label")
	if enemy_root == null or enemy_root.get_child_count() < 4:
		_issue("missing_expansion_enemies")
	if map_access_pickup == null:
		_issue("missing_map_access_pickup")

	if _issues.is_empty():
		navigator.destination_selected.connect(func(_id: StringName, _position: Vector2) -> void:
			_selected_count += 1
		)
		await _validate_map_access(save_system, player, navigator, overlay, map_access_pickup)
		_validate_overlay(navigator, overlay)
		await _validate_central_map(navigator)
		await _validate_destinations(player, navigator)

	var report := {
		"generated_at": Time.get_datetime_string_from_system(),
		"passed": _issues.is_empty(),
		"destination_count": navigator.destinations.size() if navigator != null else 0,
		"central_hotspot_count": _central_hotspot_count,
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


func _validate_map_access(save_system: Node, player: PlayerController, navigator: MapNavigator, overlay: Control, map_access_pickup: Node) -> void:
	if save_system == null:
		_issue("missing_save_system")
		return
	if save_system.has_map_access():
		_issue("map_access_should_start_locked_in_test_session")
	navigator.set_map_visible(true)
	if overlay.visible or paused:
		_issue("map_opened_without_access_item")
	if not navigator.has_method("is_map_unlocked") or navigator.is_map_unlocked():
		_issue("navigator_should_report_locked_map")
	map_access_pickup.call("interact", player)
	await process_frame
	if not save_system.has_map_access():
		_issue("map_access_pickup_did_not_unlock_map")
	if not navigator.is_map_unlocked():
		_issue("navigator_did_not_refresh_access_after_pickup")
	save_system.unlock_location(&"echo_trail")


func _validate_overlay(navigator: MapNavigator, overlay: Control) -> void:
	if overlay.visible:
		_issue("map_overlay_should_start_hidden")
	navigator.set_map_visible(true)
	if not overlay.visible or not paused:
		_issue("map_overlay_did_not_pause")
	navigator.set_map_visible(false)
	if overlay.visible or paused:
		_issue("map_overlay_did_not_resume")


func _validate_central_map(navigator: MapNavigator) -> void:
	navigator.set_map_visible(true)
	var hotspot_root := navigator.find_child("MapHotspots", true, false)
	var legacy_marker_root := navigator.find_child("MapMarkers", true, false)
	var legacy_discovery_root := navigator.find_child("DiscoveryRegions", true, false)
	var player_marker := navigator.find_child("PlayerMapMarker", true, false)
	var locked_point_root := navigator.find_child("LockedPointOverlays", true, false)
	var opening_animation := navigator.find_child("MapOpeningAnimation", true, false)
	var story_travel_button := navigator.find_child("StoryTravelButton", true, false) as Button
	var map_panel := navigator.find_child("MapPanel", true, false) as Control
	var route_panel := navigator.find_child("RoutePanel", true, false) as Control
	var map_content := navigator.find_child("MapContent", true, false)
	var map_overlay := navigator.find_child("WorldMapOverlay", true, false) as Control
	if opening_animation == null:
		_issue("missing_map_opening_animation")
	if not navigator.has_method("get_map_opening_frame_count") or int(navigator.call("get_map_opening_frame_count")) != 8:
		_issue("map_opening_animation_should_have_eight_frames")
	if map_panel == null or route_panel == null:
		_issue("map_opening_targets_are_missing")
	elif opening_animation.visible and (map_panel.visible or route_panel.visible):
		_issue("map_interface_visible_behind_opening_animation")
	await create_timer(1.25, true).timeout
	if map_panel == null or route_panel == null or not map_panel.visible or not route_panel.visible:
		_issue("map_interface_not_revealed_after_opening")
	if hotspot_root == null:
		_issue("missing_native_map_hotspots")
	else:
		_central_hotspot_count = hotspot_root.get_child_count()
		if _central_hotspot_count != 16:
			_issue("expected_sixteen_native_map_hotspots")
		for child in hotspot_root.get_children():
			var hotspot := child as Button
			if hotspot == null:
				_issue("map_hotspot_is_not_button")
				continue
			if not hotspot.text.is_empty() or hotspot.icon != null or not hotspot.flat:
				_issue("map_hotspot_has_visible_content:%s" % hotspot.name)
			if hotspot.get_signal_connection_list("pressed").is_empty():
				_issue("map_hotspot_has_no_action:%s" % hotspot.name)
	if legacy_marker_root != null:
		_issue("legacy_static_map_markers_present")
	if legacy_discovery_root != null:
		_issue("legacy_discovery_overlays_present")
	if player_marker == null:
		_issue("missing_player_location_marker")
	elif player_marker is TextureRect and (player_marker as TextureRect).texture == null:
		_issue("player_location_marker_has_no_texture")
	elif map_content != null:
		await process_frame
		var marker_center: Vector2 = player_marker.global_position + player_marker.size * 0.5
		var map_rect: Rect2 = map_content.get_global_rect()
		if not map_rect.has_point(marker_center) or marker_center.x < map_rect.position.x + 40.0:
			_issue("player_location_marker_not_projected_on_map")
	if locked_point_root == null:
		_issue("missing_locked_point_overlays")
	elif locked_point_root.get_child_count() == 0:
		_issue("locked_points_are_not_desaturated")
	else:
		for child in locked_point_root.get_children():
			var overlay := child as TextureRect
			if overlay == null or overlay.texture == null or not bool(overlay.get_meta("desaturated_native_point", false)):
				_issue("locked_point_overlay_is_not_desaturated_native_texture:%s" % child.name)
				break
	if story_travel_button == null:
		_issue("missing_story_travel_button")
	for point_id in EXPECTED_ATLAS_POINTS:
		if not navigator.has_method("get_map_hotspot_atlas_position"):
			_issue("missing_hotspot_atlas_position_api")
			break
		var actual: Vector2 = navigator.get_map_hotspot_atlas_position(point_id)
		var expected: Vector2 = EXPECTED_ATLAS_POINTS[point_id]
		if actual.distance_to(expected) > 0.1:
			_issue("hotspot_atlas_position_mismatch:%s" % point_id)
	navigator.call("_select_native_point", "awakening")
	var details := navigator.find_child("DetailsLabel", true, false) as Label
	if details == null or not details.text.contains("Clareira do Despertar"):
		_issue("native_point_does_not_show_stage_name")
	if map_overlay == null or not map_overlay.visible:
		_issue("native_point_selection_closed_map")
	if not navigator.has_method("can_travel_to_story_location"):
		_issue("missing_story_travel_validation_api")
	else:
		if bool(navigator.call("can_travel_to_story_location", "awakening")):
			_issue("current_story_location_should_not_be_travel_destination")
		if not bool(navigator.call("can_travel_to_story_location", "echo_trail")):
			_issue("unlocked_story_location_should_be_travel_destination")
		if bool(navigator.call("can_travel_to_story_location", "forgotten_sanctuary")):
			_issue("locked_story_location_should_not_be_travel_destination")
	if not navigator.has_method("get_story_travel_scene"):
		_issue("missing_story_travel_scene_api")
	elif String(navigator.call("get_story_travel_scene", "echo_trail")) != "res://scenes/levels/locations/EchoTrail.tscn":
		_issue("story_travel_scene_does_not_match_catalog")
	navigator.call("_select_native_point", "echo_trail")
	if story_travel_button == null or not story_travel_button.visible or story_travel_button.disabled:
		_issue("unlocked_story_point_did_not_enable_travel")
	if map_content == null:
		_issue("missing_zoomable_map_content")
	if navigator.has_method("set_map_zoom"):
		navigator.set_map_zoom(1.5)
		await process_frame
		if absf(float(navigator.get("map_zoom")) - 1.5) > 0.05:
			_issue("map_zoom_not_applied")
	else:
		_issue("missing_map_zoom_api")
	if navigator.has_method("pan_map"):
		var offset_before: Vector2 = navigator.get("map_pan")
		navigator.pan_map(Vector2(48, -24))
		await process_frame
		var offset_after: Vector2 = navigator.get("map_pan")
		if offset_after.distance_to(offset_before) < 1.0:
			_issue("map_pan_not_applied")
	else:
		_issue("missing_map_pan_api")
	navigator.set_map_visible(false)


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
