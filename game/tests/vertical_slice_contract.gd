extends SceneTree

const TEST_ROOM_PATH := "res://scenes/levels/TestRoom.tscn"

var _failed := false


func _init() -> void:
	await _test_vertical_slice_contract()
	if not _failed:
		print("KENOSIS_VERTICAL_SLICE_CONTRACT_OK")
		quit(0)


func _test_vertical_slice_contract() -> void:
	var packed_scene: PackedScene = load(TEST_ROOM_PATH)
	if packed_scene == null:
		_fail("could not load %s" % TEST_ROOM_PATH)
		return

	var room := packed_scene.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	var registry := root.get_node_or_null("DataRegistry")
	if registry == null:
		_fail("DataRegistry autoload not found")
		return
	registry.reload()
	var balance: Dictionary = registry.get_section(&"balance")

	var player := room.find_child("Player", true, false)
	var resonance_system := room.find_child("ResonanceSystem", true, false)
	var hud := room.find_child("PrototypeHUD", true, false)
	var completion_zone := room.find_child("CompletionZone", true, false)
	var memory_seal := room.find_child("MemorySeal", true, false)
	var source := room.find_child("ExorigemSource", true, false)
	var checkpoint := room.find_child("MemoryCheckpoint", true, false)
	var patroller := room.find_child("CorruptedPatroller", true, false)

	var required_nodes := {
		"Player": player,
		"ResonanceSystem": resonance_system,
		"PrototypeHUD": hud,
		"CompletionZone": completion_zone,
		"MemorySeal": memory_seal,
		"ExorigemSource": source,
		"MemoryCheckpoint": checkpoint,
		"CorruptedPatroller": patroller,
	}
	for node_name: String in required_nodes.keys():
		if required_nodes[node_name] == null:
			_fail("%s not found" % node_name)
			return

	var player_balance: Dictionary = balance.get("player", {})
	if int(player.get("max_health")) != int(player_balance.get("max_health", -1)):
		_fail("player max health is not loaded from balance.json")
		return
	if not is_equal_approx(float(player.get("speed")), float(player_balance.get("speed", -1.0))):
		_fail("player speed is not loaded from balance.json")
		return
	if not is_equal_approx(float(player.get("jump_velocity")), float(player_balance.get("jump_velocity", 0.0))):
		_fail("player jump velocity is not loaded from balance.json")
		return
	if int(player.get("failure_penalty")) != int(player_balance.get("failure_penalty", -1)):
		_fail("player failure penalty is not loaded from balance.json")
		return

	var resonance_balance: Dictionary = balance.get("resonance", {})
	if not is_equal_approx(float(resonance_system.get("cooldown_seconds")), float(resonance_balance.get("cooldown_seconds", -1.0))):
		_fail("resonance cooldown is not loaded from balance.json")
		return

	var points_balance: Dictionary = balance.get("points", {})
	if int(memory_seal.get("cost")) != int(points_balance.get("memory_seal_activation", -1)):
		_fail("memory seal cost is not loaded from balance.json")
		return

	for hud_node_name in ["ObjectivePanel", "ObjectiveStepLabel", "ObjectiveText", "PointsPurposeLabel"]:
		if room.find_child(hud_node_name, true, false) == null:
			_fail("%s not found" % hud_node_name)
			return

	var objective_text := room.find_child("ObjectiveText", true, false) as Label
	if objective_text.text.strip_edges().is_empty():
		_fail("objective text starts empty")
		return

	if get_nodes_in_group("memory_fragment").size() < 4:
		_fail("vertical slice needs at least four memory fragments")
		return

	var lore_scar_count := 0
	for node in room.find_children("*", "LoreScar", true, false):
		lore_scar_count += 1
	if lore_scar_count < 4:
		_fail("vertical slice needs at least four lore scars")
		return

	if not bool(completion_zone.get("locked")):
		_fail("completion should start locked")
		return
	player.call("set_signature_hidden", true)
	patroller.call("receive_back_resonance", player)
	await process_frame
	if bool(completion_zone.get("locked")):
		_fail("purifying the patroller should unlock completion")
		return

	var points_before_source: int = int(player.get("points"))
	source.call("interact", player)
	var source_reward := int(player.get("points")) - points_before_source
	if source_reward != int(points_balance.get("source_first_inspection", -1)):
		_fail("source reward is not loaded from balance.json")
		return

	var points_before_checkpoint: int = int(player.get("points"))
	checkpoint.call("interact", player)
	var checkpoint_reward := int(player.get("points")) - points_before_checkpoint
	if checkpoint_reward != int(points_balance.get("checkpoint_first_activation", -1)):
		_fail("checkpoint reward is not loaded from balance.json")
		return

	root.remove_child(room)
	room.queue_free()
	await process_frame


func _fail(reason: String) -> void:
	_failed = true
	push_error("Vertical slice contract failed: %s" % reason)
	quit(1)
