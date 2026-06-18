extends SceneTree

const CORRUPTED_PATROLLER_SCENE := "res://scenes/enemies/CorruptedPatroller.tscn"
const PLAYER_CONTROLLER_SCRIPT := preload("res://scripts/player/player_controller.gd")
const EXPECTED_ANIMATIONS := {
	"idle": 4,
	"walk": 4,
	"walk_furtivo": 4,
	"alert": 3,
	"stop_idle_alerta": 3,
	"crouch": 3,
	"crouch_stealth": 3,
	"crouch_walk": 3,
	"attack": 4,
	"attack_golpe_rapido": 4,
	"attack_ataque_critico": 4,
	"backstab": 3,
	"damage": 3,
	"take_damage": 3,
	"turn": 5,
	"death": 5,
	"respawn": 3,
	"respawn_reformacao": 3,
}

var _failed := false


func _init() -> void:
	await _test_corrupted_patroller_contract()
	if not _failed:
		print("KENOSIS_CORRUPTED_PATROLLER_CONTRACT_OK")
		quit(0)


func _test_corrupted_patroller_contract() -> void:
	var packed_scene: PackedScene = load(CORRUPTED_PATROLLER_SCENE)
	if packed_scene == null:
		_fail("could not load %s" % CORRUPTED_PATROLLER_SCENE)
		return

	var patroller := packed_scene.instantiate()
	if patroller == null:
		_fail("could not instantiate CorruptedPatroller")
		return

	root.add_child(patroller)
	await process_frame
	await process_frame

	var animator := patroller.find_child("EnemyAnimator", true, false) as AnimatedSprite2D
	if animator == null:
		_fail("EnemyAnimator not found")
		return

	if animator.sprite_frames == null:
		_fail("EnemyAnimator has no SpriteFrames")
		return

	if animator.scale.x < 0.17 or animator.scale.y < 0.17:
		_fail("patroller visual scale is too small for the player readability target")
		return

	for animation_name: String in EXPECTED_ANIMATIONS:
		if not animator.sprite_frames.has_animation(animation_name):
			_fail("missing patroller animation: %s" % animation_name)
			return
		var frame_count := animator.sprite_frames.get_frame_count(animation_name)
		if frame_count != int(EXPECTED_ANIMATIONS[animation_name]):
			_fail("invalid frame count for %s: expected %d, got %d" % [animation_name, int(EXPECTED_ANIMATIONS[animation_name]), frame_count])
			return
		for frame_index in range(frame_count):
			var texture := animator.sprite_frames.get_frame_texture(animation_name, frame_index)
			if texture == null:
				_fail("missing texture for %s frame %d" % [animation_name, frame_index])
				return
			if texture.get_width() < 280 or texture.get_height() < 540:
				_fail("low resolution texture for %s frame %d: %dx%d" % [animation_name, frame_index, texture.get_width(), texture.get_height()])
				return

	if not patroller.has_method("get_behavior_tree"):
		_fail("patroller does not expose behavior tree contract")
		return

	var behavior_tree: Dictionary = patroller.call("get_behavior_tree")
	for required_key in ["root", "states", "transitions", "animation_map", "pending_animation_hooks"]:
		if not behavior_tree.has(required_key):
			_fail("behavior tree missing key: %s" % required_key)
			return

	var animation_map: Dictionary = behavior_tree.get("animation_map", {})
	for state_name in ["spawning", "patrol", "alert", "chase", "attack", "stunned", "defeated"]:
		if not animation_map.has(state_name):
			_fail("behavior tree missing animation mapping for state: %s" % state_name)
			return

	patroller.set("direction", -1.0)
	for _frame in range(70):
		await physics_frame
	if not animator.flip_h:
		_fail("patroller should mirror when moving left because source art faces right")
		return

	patroller.set("direction", 1.0)
	for _frame in range(3):
		await physics_frame
	if animator.flip_h:
		_fail("patroller should not mirror when moving right because source art faces right")
		return

	var player: PlayerController = PLAYER_CONTROLLER_SCRIPT.new()
	player.set("signature_hidden", false)
	player.global_position = patroller.global_position
	patroller.call("force_alert", player)
	for _frame in range(25):
		await physics_frame
	var horizontal_distance := absf(patroller.global_position.x - player.global_position.x)
	if horizontal_distance < 38.0:
		_fail("patroller did not recover horizontal separation from an overlapped player")
		return
	if is_zero_approx(float(patroller.get("direction"))):
		_fail("patroller direction collapsed to zero while chasing an overlapped player")
		return
	player.free()

	root.remove_child(patroller)
	patroller.queue_free()
	await process_frame


func _fail(reason: String) -> void:
	_failed = true
	push_error("Corrupted patroller contract failed: %s" % reason)
	quit(1)
