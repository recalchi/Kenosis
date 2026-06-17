extends SceneTree

const LOCATION_IDS := [
	"awakening",
	"echo_trail",
	"forgotten_sanctuary",
	"broken_gate",
	"dormant_factory",
	"scar_city",
	"mechanical_core",
	"forge",
	"flame_labyrinth",
	"whisper_library",
	"rupture_chamber",
	"eternal_bridge",
	"formless_echo",
	"void_heart",
	"remaining_silence",
	"rebirth",
]

var _failed := false
var _save_system: Node


func _init() -> void:
	await process_frame
	_save_system = root.get_node_or_null("SaveSystem")
	if _save_system != null:
		_save_system.begin_test_session()
	await _test_location_data()
	if _failed:
		return
	await _test_location_scenes()
	if _failed:
		return
	await _test_dialogue_box()
	if _failed:
		return
	await _test_audio_pool()
	if _failed:
		return
	await _test_save_progression()
	if _failed:
		return
	if _save_system != null:
		_save_system.end_test_session()
	print("KENOSIS_STORY_REGIONS_OK")
	quit(0)


func _test_location_data() -> void:
	var registry := root.get_node_or_null("DataRegistry")
	if registry == null:
		_fail("DataRegistry autoload is unavailable")
		return
	var levels: Dictionary = registry.get_section(&"levels")
	var locations: Dictionary = levels.get("story_locations", {})
	var layouts: Dictionary = registry.get_section(&"layouts").get("layouts", {})
	if locations.size() != LOCATION_IDS.size():
		_fail("story location data should map all 16 destinations")
		return
	if layouts.size() != LOCATION_IDS.size():
		_fail("level design catalog should map all 16 destinations")
		return

	var layout_ids: Dictionary = {}
	var challenge_ids: Dictionary = {}
	for location_id in LOCATION_IDS:
		var profile: Dictionary = locations.get(location_id, {})
		if profile.is_empty():
			_fail("missing story profile: %s" % location_id)
			return
		for required_key in ["name", "region", "scene", "lore", "dialogue", "next"]:
			if not profile.has(required_key):
				_fail("story profile %s is missing %s" % [location_id, required_key])
				return
		if not ResourceLoader.exists(String(profile.scene)):
			_fail("story scene is missing: %s" % profile.scene)
			return
		var layout: Dictionary = layouts.get(location_id, {})
		if layout.is_empty():
			_fail("missing level design profile: %s" % location_id)
			return
		for required_key in ["layout_id", "challenge_id", "puzzle_mode", "platforms", "nodes", "pace"]:
			if not layout.has(required_key):
				_fail("layout %s is missing %s" % [location_id, required_key])
				return
		layout_ids[String(layout.layout_id)] = true
		challenge_ids[String(layout.challenge_id)] = true

	if layout_ids.size() != LOCATION_IDS.size() or challenge_ids.size() != LOCATION_IDS.size():
		_fail("each destination needs a unique layout and challenge identity")
		return


func _test_location_scenes() -> void:
	var registry := root.get_node("DataRegistry")
	var levels: Dictionary = registry.get_section(&"levels")
	var locations: Dictionary = levels.get("story_locations", {})
	var layouts: Dictionary = registry.get_section(&"layouts").get("layouts", {})
	var runtime_signatures: Dictionary = {}
	for location_id in LOCATION_IDS:
		var profile: Dictionary = locations[location_id]
		var layout_profile: Dictionary = layouts[location_id]
		var packed: PackedScene = load(String(profile.scene))
		var room := packed.instantiate()
		root.add_child(room)
		await process_frame
		await process_frame

		if String(room.get("location_id")) != location_id:
			_fail("scene identity mismatch: %s" % location_id)
			return
		if room.find_child("Player", true, false) == null:
			_fail("location has no Player: %s" % location_id)
			return
		if room.find_child("PrototypeHUD", true, false) == null:
			_fail("location has no HUD: %s" % location_id)
			return
		if room.find_child("StoryExit", true, false) == null:
			_fail("location has no connected exit: %s" % location_id)
			return
		if room.find_child("RegionalLoreScar", true, false) == null:
			_fail("location has no regional lore: %s" % location_id)
			return
		if room.find_child("RegionalCollectible", true, false) == null:
			_fail("location has no persistent collectible: %s" % location_id)
			return
		if room.find_child("LocationTitle", true, false) == null:
			_fail("location has no title presentation: %s" % location_id)
			return
		var layout_root := room.find_child("StoryLayout", true, false)
		var puzzle_controller := room.find_child("StoryPuzzleController", true, false)
		if layout_root == null or puzzle_controller == null:
			_fail("location has no runtime layout or puzzle: %s" % location_id)
			return
		var signature := String(layout_root.get_meta("layout_signature", ""))
		if signature.is_empty() or runtime_signatures.has(signature):
			_fail("runtime layout signature is missing or duplicated: %s" % location_id)
			return
		runtime_signatures[signature] = true
		if not puzzle_controller.has_method("is_solved"):
			_fail("location puzzle API is incomplete: %s" % location_id)
			return
		if not layout_profile.get("nodes", []).is_empty():
			var puzzle_visual := room.find_child("PuzzleNodeVisual", true, false) as Sprite2D
			if puzzle_visual == null or puzzle_visual.scale.x < 0.7:
				_fail("puzzle device is too small to read: %s" % location_id)
				return
		if not layout_profile.get("hazards", []).is_empty():
			var hazard_visual := room.find_child("HazardTile00", true, false) as Sprite2D
			if hazard_visual == null:
				_fail("regional hazard still uses a prototype-only visual: %s" % location_id)
				return

		root.remove_child(room)
		room.queue_free()
		await process_frame


func _test_dialogue_box() -> void:
	var scene: PackedScene = load("res://scenes/levels/locations/Awakening.tscn")
	var room := scene.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	var hud := room.find_child("PrototypeHUD", true, false)
	var overlay := room.find_child("DialogueOverlay", true, false)
	var speaker := room.find_child("DialogueSpeaker", true, false) as Label
	var counter := room.find_child("DialogueCounter", true, false) as Label
	if hud == null or overlay == null or speaker == null or counter == null:
		_fail("dialogue box structure is incomplete")
		return
	if not hud.has_method("show_dialogue_id"):
		_fail("HUD cannot load dialogue by data id")
		return

	hud.call("show_dialogue_id", &"awakening_intro")
	await process_frame
	if not overlay.visible or speaker.text.is_empty() or counter.text != "1 / 2":
		_fail("data-driven dialogue did not open correctly")
		return
	hud.call("complete_dialogue_line")
	hud.call("advance_dialogue")
	if counter.text != "2 / 2":
		_fail("dialogue did not advance to its second line")
		return
	hud.call("complete_dialogue_line")
	hud.call("advance_dialogue")
	if overlay.visible:
		_fail("dialogue did not close")
		return

	var story_exit := room.find_child("StoryExit", true, false)
	var lore_scar := room.find_child("RegionalLoreScar", true, false)
	var regional_enemy := room.find_child("RegionalEnemy", true, false)
	var puzzle_controller := room.find_child("StoryPuzzleController", true, false)
	var player := room.find_child("Player", true, false)
	if story_exit == null or lore_scar == null or regional_enemy == null or puzzle_controller == null or player == null:
		_fail("first location progression actors are incomplete")
		return
	if not bool(story_exit.get("locked")):
		_fail("story exit should start locked")
		return

	lore_scar.call("interact", player)
	await process_frame
	_close_dialogue(hud, overlay)
	regional_enemy.call("receive_resonance", player)
	regional_enemy.call("receive_resonance", player)
	puzzle_controller.call("solve_for_test")
	await process_frame
	if bool(story_exit.get("locked")):
		_fail("lore and enemy completion did not unlock the story exit")
		return

	root.remove_child(room)
	room.queue_free()
	await process_frame


func _test_audio_pool() -> void:
	var audio := root.get_node_or_null("AudioManager")
	if audio == null:
		_fail("AudioManager autoload is unavailable")
		return
	if not audio.has_method("get_pool_capacity") or int(audio.call("get_pool_capacity")) < 12:
		_fail("audio pools are too small for simultaneous gameplay cues")
		return
	for cue in [&"confirm", &"lore", &"alert", &"dialogue_open", &"dialogue_tick"]:
		if not bool(audio.call("has_cue", cue)):
			_fail("audio cue was not preloaded: %s" % cue)
			return
	audio.call("play_ui", &"confirm")
	audio.call("play_sfx", &"lore")
	if int(audio.call("get_active_stream_count")) < 2:
		_fail("simultaneous UI and SFX streams were not assigned")
		return


func _close_dialogue(hud: Node, overlay: Control) -> void:
	var guard := 0
	while overlay.visible and guard < 8:
		hud.call("complete_dialogue_line")
		hud.call("advance_dialogue")
		guard += 1


func _test_save_progression() -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	if save_system == null:
		_fail("SaveSystem autoload is unavailable")
		return
	for method_name in ["set_current_location", "unlock_location", "is_location_unlocked", "mark_lore_observed"]:
		if not save_system.has_method(method_name):
			_fail("save progression API missing: %s" % method_name)
			return
	save_system.call("unlock_location", &"echo_trail")
	if not bool(save_system.call("is_location_unlocked", &"echo_trail")):
		_fail("location unlock was not persisted in memory")
		return


func _fail(reason: String) -> void:
	_failed = true
	if _save_system != null:
		_save_system.end_test_session()
	push_error("Story regions test failed: %s" % reason)
	quit(1)
