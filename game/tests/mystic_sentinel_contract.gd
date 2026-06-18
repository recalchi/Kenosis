extends SceneTree

const MYSTIC_SENTINEL_SCENE := "res://scenes/enemies/MysticSentinel.tscn"
const EXPECTED_ANIMATIONS := {
	"idle": 5,
	"move": 4,
	"alert": 4,
	"attack": 5,
	"damage": 5,
	"death": 5,
	"respawn": 5,
	"patrulha_flutuacao": 5,
	"scan_observacao": 4,
	"pulso_deteccao": 6,
	"idle_alerta": 4,
	"turn": 4,
	"cone_varredura_feixe_busca": 4,
	"lockon_marcacao_alvo": 5,
	"alarme_arcano_chamado": 5,
	"disparo_de_luz_contra_ataque": 5,
	"take_damage": 5,
	"respawn_reativacao": 5,
	"estado_dormente": 3,
	"estado_ativo": 4,
	"estado_alerta": 4,
	"estado_sobrecarga": 4,
}

const HIGH_READABILITY_ANIMATIONS := [
	"idle",
	"move",
	"alert",
	"attack",
	"damage",
	"death",
	"respawn",
]

var _failed := false


func _init() -> void:
	await _test_mystic_sentinel_contract()
	if not _failed:
		print("KENOSIS_MYSTIC_SENTINEL_CONTRACT_OK")
		quit(0)


func _test_mystic_sentinel_contract() -> void:
	var packed_scene: PackedScene = load(MYSTIC_SENTINEL_SCENE)
	if packed_scene == null:
		_fail("could not load %s" % MYSTIC_SENTINEL_SCENE)
		return

	var sentinel := packed_scene.instantiate()
	if sentinel == null:
		_fail("could not instantiate MysticSentinel")
		return

	root.add_child(sentinel)
	await process_frame
	await process_frame

	var animator := sentinel.find_child("EnemyAnimator", true, false) as AnimatedSprite2D
	if animator == null:
		_fail("EnemyAnimator not found")
		return

	if animator.sprite_frames == null:
		_fail("EnemyAnimator has no SpriteFrames")
		return

	if animator.scale.x < 0.18 or animator.scale.y < 0.18:
		_fail("mystic sentinel visual scale is too small for the expansion readability target")
		return

	for animation_name: String in EXPECTED_ANIMATIONS:
		if not animator.sprite_frames.has_animation(animation_name):
			_fail("missing mystic sentinel animation: %s" % animation_name)
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
			if animation_name in HIGH_READABILITY_ANIMATIONS and (texture.get_width() < 260 or texture.get_height() < 250):
				_fail("low readability texture for %s frame %d: %dx%d" % [animation_name, frame_index, texture.get_width(), texture.get_height()])
				return

	if not sentinel.has_method("get_behavior_tree"):
		_fail("mystic sentinel does not expose behavior tree contract")
		return

	var behavior_tree: Dictionary = sentinel.call("get_behavior_tree")
	for required_key in ["root", "states", "transitions", "animation_map", "pending_animation_hooks"]:
		if not behavior_tree.has(required_key):
			_fail("behavior tree missing key: %s" % required_key)
			return

	var animation_map: Dictionary = behavior_tree.get("animation_map", {})
	for state_name in ["idle", "patrol", "scan", "alert", "lockon", "attack", "damaged", "defeated", "respawning"]:
		if not animation_map.has(state_name):
			_fail("behavior tree missing animation mapping for state: %s" % state_name)
			return

	root.remove_child(sentinel)
	sentinel.queue_free()
	await process_frame


func _fail(reason: String) -> void:
	_failed = true
	push_error("Mystic sentinel contract failed: %s" % reason)
	quit(1)
