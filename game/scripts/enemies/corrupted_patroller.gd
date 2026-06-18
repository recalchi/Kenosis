extends CharacterBody2D
class_name CorruptedPatroller

signal state_changed(state_name: String)
signal player_caught
signal purified
signal alert_started

enum State { SPAWNING, PATROL, ALERT, CHASE, ATTACK, STUNNED, DEFEATED }

const ANIMATION_LIBRARY := {
	"idle": {"frames": 4, "speed": 5.0, "loop": true},
	"walk": {"frames": 4, "speed": 7.0, "loop": true},
	"walk_furtivo": {"frames": 4, "speed": 7.0, "loop": true},
	"alert": {"frames": 3, "speed": 5.0, "loop": true},
	"stop_idle_alerta": {"frames": 3, "speed": 5.0, "loop": true},
	"crouch": {"frames": 3, "speed": 5.0, "loop": true},
	"crouch_stealth": {"frames": 3, "speed": 5.0, "loop": true},
	"crouch_walk": {"frames": 3, "speed": 6.0, "loop": true},
	"attack": {"frames": 4, "speed": 8.0, "loop": false},
	"attack_golpe_rapido": {"frames": 4, "speed": 8.0, "loop": false},
	"attack_ataque_critico": {"frames": 4, "speed": 8.0, "loop": false},
	"backstab": {"frames": 3, "speed": 8.0, "loop": false},
	"damage": {"frames": 3, "speed": 6.0, "loop": false},
	"take_damage": {"frames": 3, "speed": 6.0, "loop": false},
	"turn": {"frames": 5, "speed": 10.0, "loop": false},
	"death": {"frames": 5, "speed": 5.0, "loop": false},
	"respawn": {"frames": 3, "speed": 5.0, "loop": false},
	"respawn_reformacao": {"frames": 3, "speed": 5.0, "loop": false},
}

const BEHAVIOR_TREE := {
	"root": "guard_test_field_memory_gate",
	"states": [
		"spawning",
		"patrol",
		"alert",
		"chase",
		"attack",
		"stunned",
		"defeated",
	],
	"transitions": [
		{"from": "spawning", "to": "patrol", "when": "respawn_reformacao_finished"},
		{"from": "patrol", "to": "alert", "when": "player_signature_hidden_after_chase"},
		{"from": "patrol", "to": "chase", "when": "player_visible_inside_vision"},
		{"from": "alert", "to": "chase", "when": "player_visible_inside_vision"},
		{"from": "chase", "to": "alert", "when": "player_signature_hidden"},
		{"from": "patrol|alert|chase", "to": "attack", "when": "player_enters_contact_area"},
		{"from": "patrol|alert|chase", "to": "stunned", "when": "rear_resonance_or_hidden_resonance"},
		{"from": "stunned", "to": "spawning", "when": "stun_timer_finished"},
	],
	"animation_map": {
		"spawning": "respawn_reformacao",
		"patrol": "walk_furtivo",
		"alert": "stop_idle_alerta",
		"chase": "walk_furtivo",
		"attack": "attack_golpe_rapido",
		"stunned": "backstab > take_damage > death",
		"defeated": "death",
	},
	"pending_animation_hooks": {
		"crouch_stealth": "reserved_for_low_profile_patrol_or_stealth_cover_variant",
		"crouch_walk": "reserved_for_low_profile_chase_variant",
		"attack_ataque_critico": "reserved_for_elite_or_low_health_attack_variant",
		"turn": "used_as_patrol_boundary_turn_visual",
	},
}

@export var patrol_left := -130.0
@export var patrol_right := 130.0
@export var patrol_speed := 55.0
@export var chase_speed := 120.0
@export var gravity := 980.0
@export var stun_seconds := 4.0
@export var contact_damage := 1
@export var attack_standoff_distance := 54.0
@export var separation_recovery_speed := 220.0

var state := State.PATROL
var direction := -1.0
var player: PlayerController
var player_hidden := false
var is_stunned := false
var _origin_x := 0.0
var _stun_remaining := 0.0
var _spawn_remaining := 0.0
var _attack_cooldown := 0.0
var _turn_visual_remaining := 0.0

@onready var animator: AnimatedSprite2D = $EnemyAnimator
@onready var vision_area: Area2D = $VisionArea
@onready var contact_area: Area2D = $ContactArea


func _ready() -> void:
	_origin_x = global_position.x
	add_to_group("resonance_target")
	animator.sprite_frames = _build_frames()
	animator.animation_finished.connect(_on_animation_finished)
	vision_area.body_entered.connect(_on_vision_entered)
	contact_area.body_entered.connect(_on_contact_entered)
	_begin_reformation()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if not is_on_floor():
		velocity.y += gravity * delta

	if state == State.SPAWNING:
		_spawn_remaining -= delta
		velocity.x = 0.0
		if _spawn_remaining <= 0.0:
			vision_area.monitoring = true
			contact_area.monitoring = true
			_set_state(State.PATROL)
			_play_animation("walk_furtivo")
		move_and_slide()
		return

	if state == State.STUNNED:
		_stun_remaining -= delta
		velocity.x = 0.0
		if _stun_remaining <= 0.0:
			is_stunned = false
			_begin_reformation()
		move_and_slide()
		return

	if state == State.DEFEATED:
		velocity.x = 0.0
		move_and_slide()
		return

	if state == State.ATTACK:
		velocity.x = 0.0
		_recover_player_separation(delta)
		move_and_slide()
		return

	if player != null:
		player_hidden = bool(player.get("signature_hidden"))
		if not player_hidden and state == State.ALERT and vision_area.overlaps_body(player):
			_set_state(State.CHASE)

	if state == State.CHASE and player != null and not player_hidden:
		direction = _direction_to_player()
		var horizontal_distance := absf(player.global_position.x - global_position.x)
		if horizontal_distance <= attack_standoff_distance:
			velocity.x = 0.0
			_try_attack_player(player)
			_recover_player_separation(delta)
			_play_animation("stop_idle_alerta")
		else:
			velocity.x = direction * chase_speed
			_play_animation("walk_furtivo")
	elif state == State.ALERT:
		velocity.x = 0.0
		_play_animation("stop_idle_alerta")
	else:
		if _turn_visual_remaining > 0.0:
			_turn_visual_remaining -= delta
			velocity.x = 0.0
			_play_animation("turn")
		else:
			velocity.x = direction * patrol_speed
			_play_animation("walk_furtivo")
			if global_position.x <= _origin_x + patrol_left:
				_face_direction(1.0)
			elif global_position.x >= _origin_x + patrol_right:
				_face_direction(-1.0)

	animator.flip_h = direction < 0.0
	animator.speed_scale = clampf(absf(velocity.x) / patrol_speed, 0.8, 1.75) if animator.animation in ["walk", "walk_furtivo"] else 1.0
	_update_vision_direction()
	move_and_slide()


func set_player_hidden(hidden: bool) -> void:
	player_hidden = hidden
	if hidden and state == State.CHASE:
		_set_state(State.ALERT)
		_play_animation("stop_idle_alerta")


func force_alert(target: PlayerController) -> void:
	player = target
	player_hidden = bool(target.get("signature_hidden"))
	if not player_hidden and state not in [State.ATTACK, State.STUNNED, State.DEFEATED]:
		direction = _direction_to_player()
		_set_state(State.CHASE)
		alert_started.emit()


func receive_resonance(actor: Node) -> bool:
	return receive_back_resonance(actor)


func receive_back_resonance(actor: Node) -> bool:
	if state in [State.ATTACK, State.STUNNED, State.DEFEATED] or not actor is PlayerController:
		return false

	var actor_is_behind: bool = (actor.global_position.x < global_position.x and direction > 0.0) or (actor.global_position.x > global_position.x and direction < 0.0)
	if not actor_is_behind and not bool(actor.get("signature_hidden")):
		return false

	is_stunned = true
	_stun_remaining = stun_seconds
	velocity = Vector2.ZERO
	_set_state(State.STUNNED)
	_play_animation("backstab")
	purified.emit()
	return true


func get_interaction_label() -> String:
	return "F: desatar corrupcao por tras"


func _on_vision_entered(body: Node) -> void:
	if body is PlayerController:
		player = body
		player_hidden = bool(body.get("signature_hidden"))
		if not player_hidden:
			force_alert(body)


func _on_contact_entered(body: Node) -> void:
	if body is PlayerController:
		_try_attack_player(body)


func _set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(State.keys()[state].to_lower())


func _begin_reformation() -> void:
	_set_state(State.SPAWNING)
	_spawn_remaining = 0.9
	velocity = Vector2.ZERO
	vision_area.set_deferred("monitoring", false)
	contact_area.set_deferred("monitoring", false)
	_play_animation("respawn_reformacao")


func _on_animation_finished() -> void:
	if state == State.ATTACK and animator.animation in ["attack", "attack_golpe_rapido", "attack_ataque_critico"]:
		if player != null and is_instance_valid(player) and not player_hidden:
			_set_state(State.CHASE)
		else:
			_set_state(State.ALERT)
	elif state == State.STUNNED and animator.animation == "backstab":
		_play_animation("take_damage")
	elif state == State.STUNNED and animator.animation in ["damage", "take_damage"]:
		_play_animation("death")


func _update_vision_direction() -> void:
	var collision := vision_area.get_node("CollisionShape2D") as CollisionShape2D
	collision.position.x = 105.0 * direction


func _direction_to_player() -> float:
	if player == null or not is_instance_valid(player):
		return -1.0 if direction < 0.0 else 1.0
	var delta_x := player.global_position.x - global_position.x
	if absf(delta_x) <= 0.5:
		return -1.0 if direction < 0.0 else 1.0
	return signf(delta_x)


func _recover_player_separation(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var desired_x := player.global_position.x - direction * attack_standoff_distance
	global_position.x = move_toward(global_position.x, desired_x, separation_recovery_speed * delta)


func _try_attack_player(target: PlayerController) -> void:
	if state not in [State.PATROL, State.ALERT, State.CHASE] or _attack_cooldown > 0.0:
		return
	player = target
	player_hidden = bool(target.get("signature_hidden"))
	if player_hidden:
		_set_state(State.ALERT)
		return
	direction = _direction_to_player()
	_attack_cooldown = 1.0
	_set_state(State.ATTACK)
	velocity.x = 0.0
	_play_animation("attack_golpe_rapido")
	if target.take_damage(contact_damage, global_position):
		player_caught.emit()


func _face_direction(next_direction: float) -> void:
	if next_direction == 0.0 or is_equal_approx(direction, next_direction):
		return
	direction = next_direction
	_turn_visual_remaining = 0.32


func _play_animation(animation_name: String) -> void:
	if animator.sprite_frames == null or not animator.sprite_frames.has_animation(animation_name):
		return
	if animator.animation != animation_name or not animator.is_playing():
		animator.play(animation_name)


func get_behavior_tree() -> Dictionary:
	return BEHAVIOR_TREE.duplicate(true)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in ANIMATION_LIBRARY:
		if not frames.has_animation(animation_name):
			frames.add_animation(animation_name)
		var animation_config: Dictionary = ANIMATION_LIBRARY[animation_name]
		for frame_index in range(int(animation_config.get("frames", 0))):
			var path := "res://assets/sprites/enemies/corrupted_patroller/%s_%d.png" % [animation_name, frame_index]
			var texture: Texture2D = load(path)
			if texture != null:
				frames.add_frame(animation_name, texture)
		frames.set_animation_speed(animation_name, float(animation_config.get("speed", 5.0)))
		frames.set_animation_loop(animation_name, bool(animation_config.get("loop", false)))
	return frames
