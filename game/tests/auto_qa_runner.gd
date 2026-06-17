extends SceneTree

const TEST_ROOM_PATH := "res://scenes/levels/TestRoom.tscn"
const BOT_SCRIPT := preload("res://scripts/systems/auto_qa_bot.gd")
const OUTPUT_DIR := "res://../builds/qa/autobot"

var _requested_cycles := 3
var _reports: Array[Dictionary] = []
var _current_room: Node
var _current_bot: AutoQABot


func _init() -> void:
	root.size = Vector2i(1280, 720)
	_requested_cycles = _read_cycle_count()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.begin_test_session()
	call_deferred("_run")


func _run() -> void:
	var cycle := 1
	while _requested_cycles == 0 or cycle <= _requested_cycles:
		await _run_cycle(cycle)
		_write_reports()
		cycle += 1

	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.end_test_session()
	var summary := _build_summary()
	print("KENOSIS_AUTO_QA_OK %s" % JSON.stringify(summary))
	for _frame in range(4):
		await process_frame
	quit(0 if int(summary.get("failed_cycles", 0)) == 0 else 1)


func _run_cycle(cycle: int) -> void:
	paused = false
	var packed: PackedScene = load(TEST_ROOM_PATH)
	_current_room = packed.instantiate()
	root.add_child(_current_room)
	await process_frame
	await process_frame

	var hud := _current_room.find_child("PrototypeHUD", true, false)
	if hud != null:
		hud.apply_tutorial_preference(false)

	_current_bot = BOT_SCRIPT.new() as AutoQABot
	_current_bot.name = "AutoQABot"
	_current_bot.process_mode = Node.PROCESS_MODE_ALWAYS
	_current_bot.configure(_current_room, _scenario_for_cycle(cycle), cycle)
	_current_bot.milestone_reached.connect(_on_milestone)
	_current_room.add_child(_current_bot)
	_current_bot.start()

	var report: Dictionary = await _current_bot.run_finished
	_reports.append(report)
	paused = false
	root.remove_child(_current_room)
	_current_room.queue_free()
	_current_room = null
	_current_bot = null
	for _frame in range(4):
		await process_frame


func _on_milestone(name: String, _snapshot: Dictionary) -> void:
	if _current_bot == null or _current_bot.cycle_index != 1:
		return
	if name not in ["left_boundary", "resonance_bridge", "enemy_purified"]:
		return
	call_deferred("_capture_snapshot", name)


func _capture_snapshot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		return
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		return
	var path := "%s/cycle_01_%s.png" % [OUTPUT_DIR, name]
	image.save_png(ProjectSettings.globalize_path(path))


func _write_reports() -> void:
	var payload := {
		"generated_at": Time.get_datetime_string_from_system(),
		"summary": _build_summary(),
		"cycles": _reports,
	}
	var path := ProjectSettings.globalize_path("%s/latest_report.json" % OUTPUT_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "  "))


func _build_summary() -> Dictionary:
	var passed := 0
	var failed := 0
	var durations: Array[float] = []
	var issues: Dictionary = {}
	for report in _reports:
		if bool(report.get("passed", false)):
			passed += 1
		else:
			failed += 1
		durations.append(float(report.get("duration_seconds", 0.0)))
		for issue in report.get("issues", []):
			issues[String(issue)] = int(issues.get(String(issue), 0)) + 1
	var average := 0.0
	for duration in durations:
		average += duration
	if not durations.is_empty():
		average /= durations.size()
	return {
		"requested_cycles": _requested_cycles,
		"completed_cycles": _reports.size(),
		"passed_cycles": passed,
		"failed_cycles": failed,
		"average_duration_seconds": snappedf(average, 0.01),
		"issue_frequency": issues,
	}


func _read_cycle_count() -> int:
	var environment_value := OS.get_environment("KENOSIS_QA_CYCLES")
	if environment_value.is_valid_int():
		return maxi(0, int(environment_value))
	return 3


func _scenario_for_cycle(cycle: int) -> String:
	var scenarios := ["critical_path", "failure_recovery", "interaction_stress"]
	return scenarios[(cycle - 1) % scenarios.size()]
