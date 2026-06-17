extends CharacterBody2D
class_name CorruptedPatroller

signal state_changed(state_name: String)
signal player_caught
signal purified
signal alert_started

enum State { SPAWNING, PATROL, ALERT, CHASE, STUNNED, DEFEATED }

@export var patrol_left := -130.0
@export var patrol_right := 130.0
@export var patrol_speed := 55.0
@export var chase_speed := 120.0
@export var gravity := 980.0
@export var stun_seconds := 4.0
@export var contact_damage := 1

var state := State.PATROL
var direction := -1.0
var player: PlayerController
var player_hidden := false
var is_stunned := false
var _origin_x := 0.0
var _stun_remaining := 0.0
var _spawn_remaining := 0.0
var _attack_cooldown := 0.0

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
			animator.play("walk")
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

	if player != null:
		player_hidden = bool(player.get("signature_hidden"))
		if not player_hidden and state == State.ALERT and vision_area.overlaps_body(player):
			_set_state(State.CHASE)

	if state == State.CHASE and player != null and not player_hidden:
		direction = signf(player.global_position.x - global_position.x)
		velocity.x = direction * chase_speed
		animator.play("walk")
	elif state == State.ALERT:
		velocity.x = 0.0
		animator.play("alert")
	else:
		velocity.x = direction * patrol_speed
		animator.play("walk")
		if global_position.x <= _origin_x + patrol_left:
			direction = 1.0
		elif global_position.x >= _origin_x + patrol_right:
			direction = -1.0

	animator.flip_h = direction > 0.0
	animator.speed_scale = clampf(absf(velocity.x) / patrol_speed, 0.8, 1.75) if animator.animation == "walk" else 1.0
	_update_vision_direction()
	move_and_slide()


func set_player_hidden(hidden: bool) -> void:
	player_hidden = hidden
	if hidden and state == State.CHASE:
		_set_state(State.ALERT)


func force_alert(target: PlayerController) -> void:
	player = target
	player_hidden = bool(target.get("signature_hidden"))
	if not player_hidden and state != State.STUNNED:
		_set_state(State.CHASE)
		alert_started.emit()


func receive_resonance(actor: Node) -> bool:
	return receive_back_resonance(actor)


func receive_back_resonance(actor: Node) -> bool:
	if state == State.STUNNED or state == State.DEFEATED or not actor is PlayerController:
		return false

	var actor_is_behind: bool = (actor.global_position.x < global_position.x and direction > 0.0) or (actor.global_position.x > global_position.x and direction < 0.0)
	if not actor_is_behind and not bool(actor.get("signature_hidden")):
		return false

	is_stunned = true
	_stun_remaining = stun_seconds
	velocity = Vector2.ZERO
	animator.play("damage")
	_set_state(State.STUNNED)
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
	if body is PlayerController and state in [State.PATROL, State.ALERT, State.CHASE] and _attack_cooldown <= 0.0:
		_attack_cooldown = 1.0
		animator.play("attack")
		if body.take_damage(contact_damage, global_position):
			player_caught.emit()


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
	animator.play("respawn")


func _on_animation_finished() -> void:
	if state == State.STUNNED and animator.animation == "damage":
		animator.play("death")


func _update_vision_direction() -> void:
	var collision := vision_area.get_node("CollisionShape2D") as CollisionShape2D
	collision.position.x = 105.0 * direction


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var animation_frames := {
		"idle": 4,
		"walk": 4,
		"alert": 3,
		"crouch": 3,
		"attack": 4,
		"damage": 3,
		"death": 4,
		"respawn": 3,
	}
	for animation_name in animation_frames:
		if not frames.has_animation(animation_name):
			frames.add_animation(animation_name)
		for frame_index in range(int(animation_frames[animation_name])):
			var path := "res://assets/sprites/enemies/corrupted_patroller/%s_%d.png" % [animation_name, frame_index]
			var texture: Texture2D = load(path)
			if texture != null:
				frames.add_frame(animation_name, texture)
		frames.set_animation_speed(animation_name, 6.0 if animation_name == "walk" else (8.0 if animation_name == "attack" else 4.0))
		frames.set_animation_loop(animation_name, animation_name in ["idle", "walk", "alert", "crouch"])
	return frames
