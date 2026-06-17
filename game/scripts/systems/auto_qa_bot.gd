extends Node
class_name AutoQABot

signal milestone_reached(name: String, snapshot: Dictionary)
signal run_finished(report: Dictionary)

const MOVE_TOLERANCE := 18.0
const STATE_TIMEOUT := 8.0

var room: Node2D
var player: PlayerController
var hud: PrototypeHUD
var resonance_system: ResonanceSystem
var receiver: ResonanceReceiver
var gate: ResonanceGate
var enemy: CorruptedPatroller
var completion_zone: CompletionZone
var memory_seal: MemorySeal

var cycle_index := 1
var scenario := "critical_path"
var _state := "idle"
var _state_elapsed := 0.0
var _run_elapsed := 0.0
var _run_success := false
var _last_x := 0.0
var _stuck_elapsed := 0.0
var _finished := false
var _jump_started := false
var _jump_landed := false
var _dialogue_advances := 0
var _incidental_dialogues := 0
var _enemy_resonance_attempted := false
var _retry_emit_count := 0
var _resonance_attempts := 0
var _resonance_successes := 0
var _cooldown_rejections := 0
var _invalid_rejections := 0
var _damage_events := 0
var _failures := 0
var _stuck_events := 0
var _min_x := INF
var _max_x := -INF
var _min_y := INF
var _max_y := -INF
var _min_fps := INF
var _issues: Array[String] = []
var _milestones: Array[String] = []
var _state_history: Array[String] = []


func configure(target_room: Node2D, target_scenario := "critical_path", target_cycle := 1) -> void:
	room = target_room
	scenario = target_scenario
	cycle_index = target_cycle
	player = room.find_child("Player", true, false) as PlayerController
	hud = room.find_child("PrototypeHUD", true, false) as PrototypeHUD
	resonance_system = room.find_child("ResonanceSystem", true, false) as ResonanceSystem
	receiver = room.find_child("ResonanceReceiver", true, false) as ResonanceReceiver
	gate = room.find_child("ResonanceGate", true, false) as ResonanceGate
	enemy = room.find_child("CorruptedPatroller", true, false) as CorruptedPatroller
	completion_zone = room.find_child("CompletionZone", true, false) as CompletionZone
	memory_seal = room.find_child("MemorySeal", true, false) as MemorySeal


func start() -> void:
	if not _dependencies_ready():
		_finish(false, "missing_dependencies")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	player.health_changed.connect(_on_health_changed)
	player.failed.connect(_on_player_failed)
	resonance_system.resonance_succeeded.connect(_on_resonance_succeeded)
	resonance_system.resonance_failed.connect(_on_resonance_failed)
	_last_x = player.global_position.x
	_set_state("warmup")


func is_finished() -> bool:
	return _finished


func get_report() -> Dictionary:
	return {
		"cycle": cycle_index,
		"scenario": scenario,
		"passed": _finished and _run_success and _issues.is_empty(),
		"duration_seconds": snappedf(_run_elapsed, 0.01),
		"final_state": _state,
		"completion": completion_zone != null and completion_zone.is_completed,
		"resonance_attempts": _resonance_attempts,
		"resonance_successes": _resonance_successes,
		"cooldown_rejections": _cooldown_rejections,
		"invalid_rejections": _invalid_rejections,
		"damage_events": _damage_events,
		"failures": _failures,
		"stuck_events": _stuck_events,
		"incidental_dialogues": _incidental_dialogues,
		"jump_started": _jump_started,
		"jump_landed": _jump_landed,
		"world_bounds": {
			"min_x": snappedf(_min_x, 0.1),
			"max_x": snappedf(_max_x, 0.1),
			"min_y": snappedf(_min_y, 0.1),
			"max_y": snappedf(_max_y, 0.1),
		},
		"minimum_fps": 0 if _min_fps == INF else int(_min_fps),
		"milestones": _milestones.duplicate(),
		"state_history": _state_history.duplicate(),
		"issues": _issues.duplicate(),
	}


func _process(delta: float) -> void:
	if _finished or player == null:
		return
	_run_elapsed += delta
	_state_elapsed += delta
	_sample_telemetry(delta)
	if _state != "dialogue" and _advance_incidental_dialogue():
		return

	if _state_elapsed > STATE_TIMEOUT and _state not in ["warmup", "boundary_left"]:
		_add_issue("timeout:%s" % _state)
		_finish(false, "state_timeout")
		return

	match _state:
		"warmup":
			if _state_elapsed >= 0.6:
				match scenario:
					"failure_recovery":
						_set_state("failure_hit_1")
					"interaction_stress":
						_set_state("stress_empty_target")
					_:
						_set_state("boundary_left")
		"failure_hit_1":
			player.take_damage(1, player.global_position + Vector2(20, 0))
			_set_state("failure_hit_2")
		"failure_hit_2":
			if _state_elapsed >= player.damage_invulnerability_seconds + 0.1:
				player.take_damage(1, player.global_position + Vector2(20, 0))
				_set_state("failure_hit_3")
		"failure_hit_3":
			if _state_elapsed >= player.damage_invulnerability_seconds + 0.1:
				player.take_damage(1, player.global_position + Vector2(20, 0))
				_set_state("failure_overlay")
		"failure_overlay":
			if hud.is_death_menu_visible() and get_tree().paused:
				var retry_button := room.find_child("RetryButton", true, false) as Button
				if retry_button == null:
					_add_issue("missing_retry_button")
					_finish(false, "retry_unavailable")
					return
				retry_button.pressed.emit()
				_retry_emit_count = 1
				_set_state("failure_recovery_verify")
		"failure_recovery_verify":
			if _state_elapsed > 0.55 and _retry_emit_count == 1 and (get_tree().paused or hud.is_death_menu_visible()):
				var retry_button := room.find_child("RetryButton", true, false) as Button
				if retry_button != null:
					retry_button.pressed.emit()
					_retry_emit_count += 1
			if (
				not get_tree().paused
				and not hud.is_death_menu_visible()
				and player.health == player.max_health
				and player.global_position.distance_to(player.checkpoint_position) <= 4.0
			):
				_mark_milestone("failure_recovered")
				_finish(true, "failure_recovered")
		"stress_empty_target":
			_resonance_attempts += 1
			_pulse_action("resonance")
			_set_state("stress_receiver")
		"stress_receiver":
			if _move_toward(475.0):
				_release_movement()
				_resonance_attempts += 1
				_pulse_action("resonance")
				_set_state("stress_cooldown")
		"stress_cooldown":
			if receiver.is_active:
				_resonance_attempts += 1
				_pulse_action("resonance")
				_set_state("stress_wait_ready")
		"stress_wait_ready":
			if resonance_system.is_ready():
				_resonance_attempts += 1
				_pulse_action("resonance")
				_set_state("stress_verify")
		"stress_verify":
			if _state_elapsed >= 0.2:
				if _resonance_successes != 1:
					_add_issue("stress_success_count")
				if _cooldown_rejections < 1:
					_add_issue("cooldown_not_enforced")
				if _invalid_rejections < 2:
					_add_issue("invalid_target_feedback_missing")
				_mark_milestone("interaction_stress")
				_finish(_issues.is_empty(), "interaction_stress")
		"boundary_left":
			_move_toward(-130.0)
			if player.global_position.x <= -112.0 or _state_elapsed >= 3.0:
				_release_movement()
				if player.global_position.y > 500.0:
					_add_issue("left_boundary_fall")
				_mark_milestone("left_boundary")
				_set_state("checkpoint")
		"checkpoint":
			if _move_toward(150.0):
				_release_movement()
				_pulse_action("interact")
				_set_state("source")
		"source":
			if _move_toward(335.0):
				_release_movement()
				_pulse_action("interact")
				_set_state("jump_probe")
		"jump_probe":
			_move_toward(455.0)
			if not _jump_started:
				_jump_started = true
				_pulse_action("jump")
			if _jump_started and not player.is_on_floor():
				_mark_once("jump_airborne")
			if _milestones.has("jump_airborne") and player.is_on_floor() and _state_elapsed > 0.45:
				_jump_landed = true
				_release_movement()
				_mark_milestone("jump_landed")
				_set_state("receiver")
		"receiver":
			if _move_toward(475.0):
				_release_movement()
				_resonance_attempts += 1
				_pulse_action("resonance")
				_set_state("receiver_verify")
		"receiver_verify":
			if receiver.is_active and gate.collision_shape.disabled:
				_mark_milestone("resonance_bridge")
				_resonance_attempts += 1
				_pulse_action("resonance")
				_set_state("lore")
		"lore":
			if _move_toward(865.0):
				_release_movement()
				_pulse_action("interact")
				_set_state("dialogue")
		"dialogue":
			var overlay := room.find_child("DialogueOverlay", true, false) as Control
			if overlay != null and overlay.visible:
				if _state_elapsed > 0.25 + float(_dialogue_advances) * 0.18:
					hud.complete_dialogue_line()
					hud.advance_dialogue()
					_dialogue_advances += 1
			elif _dialogue_advances > 0:
				_mark_milestone("lore_dialogue")
				_set_state("cover")
		"cover":
			Input.action_press("stealth")
			if _move_toward(1065.0):
				_release_movement()
				_set_state("stealth_wait")
		"stealth_wait":
			Input.action_press("stealth")
			if player.signature_hidden:
				_mark_once("stealth_hidden")
				if (
					not _enemy_resonance_attempted
					and resonance_system.is_ready()
					and player.global_position.distance_to(enemy.global_position) <= 150.0
				):
					_enemy_resonance_attempted = true
					_resonance_attempts += 1
					_pulse_action("resonance")
			if enemy.is_stunned:
				Input.action_release("stealth")
				_mark_milestone("enemy_purified")
				_set_state("ground_fragment")
		"ground_fragment":
			if _move_toward(1570.0):
				_release_movement()
				_pulse_action("interact")
				_mark_milestone("ground_fragment")
				_set_state("memory_seal")
		"memory_seal":
			if _move_toward(2070.0):
				_release_movement()
				_pulse_action("interact")
				_set_state("memory_seal_verify")
		"memory_seal_verify":
			if memory_seal.is_active:
				_mark_milestone("memory_seal")
				_set_state("completion")
		"completion":
			if _move_toward(2520.0):
				_release_movement()
				_pulse_action("interact")
				_set_state("completion_verify")
		"completion_verify":
			if completion_zone.is_completed:
				_mark_milestone("completion")
				_finish(true, "completed")


func _move_toward(target_x: float) -> bool:
	var distance := target_x - player.global_position.x
	if absf(distance) <= MOVE_TOLERANCE:
		return true
	if distance > 0.0:
		Input.action_release("move_left")
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")
		Input.action_press("move_left")
	return false


func _release_movement() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")


func _pulse_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	var release_event := InputEventAction.new()
	release_event.action = action
	release_event.pressed = false
	Input.parse_input_event(release_event)


func _set_state(next_state: String) -> void:
	_state = next_state
	_state_elapsed = 0.0
	_stuck_elapsed = 0.0
	_last_x = player.global_position.x if player != null else 0.0
	_state_history.append(next_state)
	print("AUTO_QA_STATE cycle=%d state=%s" % [cycle_index, next_state])


func _sample_telemetry(delta: float) -> void:
	_min_x = minf(_min_x, player.global_position.x)
	_max_x = maxf(_max_x, player.global_position.x)
	_min_y = minf(_min_y, player.global_position.y)
	_max_y = maxf(_max_y, player.global_position.y)
	var current_fps := Performance.get_monitor(Performance.TIME_FPS)
	if _run_elapsed > 1.0 and current_fps > 1.0:
		_min_fps = minf(_min_fps, current_fps)

	if _state in [
		"warmup",
		"boundary_left",
		"dialogue",
		"receiver_verify",
		"stealth_wait",
		"completion_verify",
		"failure_hit_2",
		"failure_hit_3",
		"failure_overlay",
		"failure_recovery_verify",
		"stress_wait_ready",
		"stress_verify",
		"memory_seal_verify",
	]:
		_last_x = player.global_position.x
		return
	if absf(player.global_position.x - _last_x) < 0.5:
		_stuck_elapsed += delta
		if _stuck_elapsed >= 1.25:
			_stuck_events += 1
			_add_issue("stuck:%s" % _state)
			_stuck_elapsed = 0.0
	else:
		_stuck_elapsed = 0.0
		_last_x = player.global_position.x

	if player.global_position.y > 620.0:
		_add_issue("out_of_world")
		_finish(false, "fell_out_of_world")


func _advance_incidental_dialogue() -> bool:
	var overlay := room.find_child("DialogueOverlay", true, false) as Control
	if overlay == null or not overlay.visible:
		return false
	hud.complete_dialogue_line()
	hud.advance_dialogue()
	_incidental_dialogues += 1
	return true


func _on_health_changed(current: int, maximum: int) -> void:
	if current < maximum:
		_damage_events += 1


func _on_player_failed(_points: int) -> void:
	_failures += 1
	if scenario == "failure_recovery":
		return
	_add_issue("player_failure")
	_finish(false, "player_failure")


func _on_resonance_succeeded(_target: Node) -> void:
	_resonance_successes += 1


func _on_resonance_failed(reason: String) -> void:
	if reason == "cooldown":
		_cooldown_rejections += 1
	else:
		_invalid_rejections += 1


func _mark_once(name: String) -> void:
	if not _milestones.has(name):
		_mark_milestone(name)


func _mark_milestone(name: String) -> void:
	if not _milestones.has(name):
		_milestones.append(name)
	milestone_reached.emit(name, _snapshot())


func _snapshot() -> Dictionary:
	return {
		"cycle": cycle_index,
		"state": _state,
		"elapsed": snappedf(_run_elapsed, 0.01),
		"player_position": [
			snappedf(player.global_position.x, 0.1),
			snappedf(player.global_position.y, 0.1),
		],
		"health": player.health,
		"points": player.points,
		"fps": int(Performance.get_monitor(Performance.TIME_FPS)),
	}


func _add_issue(issue: String) -> void:
	if not _issues.has(issue):
		_issues.append(issue)


func _finish(success: bool, reason: String) -> void:
	if _finished:
		return
	_finished = true
	_run_success = success
	_release_movement()
	Input.action_release("stealth")
	if not success:
		_add_issue(reason)
	run_finished.emit(get_report())


func _dependencies_ready() -> bool:
	return (
		room != null
		and player != null
		and hud != null
		and resonance_system != null
		and receiver != null
		and gate != null
		and enemy != null
		and completion_zone != null
		and memory_seal != null
	)
