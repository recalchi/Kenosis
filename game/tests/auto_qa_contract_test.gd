extends SceneTree

const BOT_SCRIPT := "res://scripts/systems/auto_qa_bot.gd"
const RUNNER_SCRIPT := "res://tests/auto_qa_runner.gd"


func _init() -> void:
	await process_frame
	if not ResourceLoader.exists(BOT_SCRIPT):
		_fail("Auto QA bot script is missing")
		return
	if not ResourceLoader.exists(RUNNER_SCRIPT):
		_fail("Auto QA runner script is missing")
		return

	var bot_script: Script = load(BOT_SCRIPT)
	var bot: Node = bot_script.new()
	for method_name in [
		"configure",
		"start",
		"get_report",
		"is_finished",
	]:
		if not bot.has_method(method_name):
			_fail("Auto QA bot API is missing %s" % method_name)
			return

	if not bot.has_signal("milestone_reached"):
		_fail("Auto QA bot must expose milestone telemetry")
		return
	if not bot.has_signal("run_finished"):
		_fail("Auto QA bot must expose completion telemetry")
		return

	print("KENOSIS_AUTO_QA_CONTRACT_OK")
	quit(0)


func _fail(reason: String) -> void:
	push_error("Auto QA contract failed: %s" % reason)
	quit(1)
