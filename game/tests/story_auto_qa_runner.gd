extends SceneTree

const STORY_SCENE := "res://scenes/levels/locations/Awakening.tscn"
const OUTPUT_DIR := "res://../builds/qa/storybot"

var _issues: Array[String] = []
var _milestones: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	call_deferred("_run")


func _run() -> void:
	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.begin_test_session()

	var packed: PackedScene = load(STORY_SCENE)
	var room := packed.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	var player := room.find_child("Player", true, false) as PlayerController
	var hud := room.find_child("PrototypeHUD", true, false) as PrototypeHUD
	var lore_scar := room.find_child("RegionalLoreScar", true, false)
	var enemy := room.find_child("RegionalEnemy", true, false)
	var puzzle_controller := room.find_child("StoryPuzzleController", true, false)
	var story_exit := room.find_child("StoryExit", true, false)
	var collectible := room.find_child("RegionalCollectible", true, false)
	var resonance_system := room.find_child("ResonanceSystem", true, false) as ResonanceSystem

	if player == null:
		_issue("missing_player")
	if hud == null:
		_issue("missing_hud")
	if lore_scar == null:
		_issue("missing_lore")
	if enemy == null:
		_issue("missing_enemy")
	if puzzle_controller == null:
		_issue("missing_story_puzzle")
	if story_exit == null:
		_issue("missing_story_exit")
	if collectible == null:
		_issue("missing_collectible")
	if resonance_system == null:
		_issue("missing_resonance_system")

	if _issues.is_empty():
		await _close_intro_dialogue(hud, room)
		_validate_initial_lock(story_exit)
		await _observe_lore(lore_scar, player, hud, room)
		await _solve_puzzle(room, resonance_system, player, puzzle_controller)
		await _stabilize_enemy(enemy, player)
		await _collect_fragment(collectible, player)
		await process_frame
		if bool(story_exit.get("locked")):
			_issue("story_exit_still_locked")
		else:
			_milestones.append("story_exit_unlocked")

	var report := {
		"generated_at": Time.get_datetime_string_from_system(),
		"scene": STORY_SCENE,
		"passed": _issues.is_empty(),
		"milestones": _milestones,
		"issues": _issues,
	}
	_write_report(report)

	if save_system != null:
		save_system.end_test_session()
	root.remove_child(room)
	room.queue_free()
	for _frame in range(3):
		await process_frame

	print("KENOSIS_STORY_AUTO_QA_OK %s" % JSON.stringify(report))
	quit(0 if _issues.is_empty() else 1)


func _close_intro_dialogue(hud: PrototypeHUD, room: Node) -> void:
	for _frame in range(60):
		await process_frame
	var overlay := room.find_child("DialogueOverlay", true, false) as Control
	var guard := 0
	while overlay != null and overlay.visible and guard < 8:
		hud.complete_dialogue_line()
		hud.advance_dialogue()
		guard += 1
	_milestones.append("intro_dialogue_closed")


func _validate_initial_lock(story_exit: Node) -> void:
	if not bool(story_exit.get("locked")):
		_issue("story_exit_should_start_locked")
	else:
		_milestones.append("story_exit_initially_locked")


func _observe_lore(lore_scar: Node, player: PlayerController, hud: PrototypeHUD, room: Node) -> void:
	lore_scar.call("interact", player)
	await process_frame
	var overlay := room.find_child("DialogueOverlay", true, false) as Control
	var guard := 0
	while overlay != null and overlay.visible and guard < 8:
		hud.complete_dialogue_line()
		hud.advance_dialogue()
		guard += 1
	_milestones.append("lore_observed")


func _solve_puzzle(room: Node, resonance_system: ResonanceSystem, player: PlayerController, puzzle_controller: Node) -> void:
	for node in room.get_tree().get_nodes_in_group("story_puzzle_node"):
		if room.is_ancestor_of(node):
			var accepted := resonance_system.try_activate(node, player)
			if not accepted:
				_issue("story_puzzle_node_rejected_resonance")
			await _wait_for_resonance_ready(resonance_system)
	if not bool(puzzle_controller.call("is_solved")):
		_issue("story_puzzle_not_solved")
	else:
		_milestones.append("story_puzzle_solved")


func _stabilize_enemy(enemy: Node, player: PlayerController) -> void:
	var guard := 0
	while is_instance_valid(enemy) and guard < 5:
		enemy.call("receive_resonance", player)
		guard += 1
		await process_frame
	var enemy_state := int(enemy.get("state")) if is_instance_valid(enemy) else -1
	var defeated_state := int(ExpansionEnemy.State.DEFEATED)
	var respawning_state := int(ExpansionEnemy.State.RESPAWNING)
	if is_instance_valid(enemy) and enemy_state not in [defeated_state, respawning_state]:
		_issue("regional_enemy_not_stabilized")
	else:
		_milestones.append("regional_enemy_stabilized")


func _collect_fragment(collectible: Node, player: PlayerController) -> void:
	collectible.call("interact", player)
	await process_frame
	if not bool(collectible.get("is_collected")):
		_issue("collectible_not_collected")
	else:
		_milestones.append("collectible_collected")


func _wait_for_resonance_ready(resonance_system: ResonanceSystem) -> void:
	var guard := 0
	while not resonance_system.is_ready() and guard < 180:
		await process_frame
		guard += 1


func _write_report(report: Dictionary) -> void:
	var path := ProjectSettings.globalize_path("%s/latest_report.json" % OUTPUT_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))


func _issue(issue_id: String) -> void:
	if not _issues.has(issue_id):
		_issues.append(issue_id)
