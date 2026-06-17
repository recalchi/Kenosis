extends CharacterBody2D
class_name ExpansionEnemy

signal defeated(enemy_id: StringName, reward: int)
signal attack_started(enemy_id: StringName)
signal state_changed(state_name: StringName)

enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, DAMAGED, DEFEATED, RESPAWNING }

@export var enemy_id: StringName = &"expansion_enemy"
@export var display_name := "Entidade"
@export var frame_root := ""
@export var floating := false
@export var patrol_distance := 120.0
@export var detection_distance := 300.0
@export var attack_distance := 72.0
@export var patrol_speed := 42.0
@export var chase_speed := 88.0
@export var max_health := 2
@export var contact_damage := 1
@export var point_reward := 20
@export var attack_cooldown_seconds := 1.5
@export var attack_vfx_path := ""
@export var resonance_vfx_path := ""

var state := State.PATROL
var health := 2
var direction := -1.0
var target: PlayerController
var _origin := Vector2.ZERO
var _attack_cooldown := 0.0
var _respawn_remaining := 0.0
var _hover_time := 0.0

@onready var animator: AnimatedSprite2D = $EnemyAnimator
@onready var contact_area: Area2D = $ContactArea


func _ready() -> void:
	add_to_group("expansion_enemy")
	add_to_group("resonance_target")
	_origin = global_position
	_apply_balance_data()
	health = max_health
	animator.sprite_frames = _build_frames()
	animator.play("idle")
	contact_area.body_entered.connect(_on_contact_entered)


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_hover_time += delta

	if state == State.DEFEATED:
		velocity = Vector2.ZERO
		return

	if state == State.RESPAWNING:
		_respawn_remaining -= delta
		if _respawn_remaining <= 0.0:
			health = max_health
			visible = true
			contact_area.set_deferred("monitoring", true)
			_set_state(State.PATROL)
			animator.play("respawn")
		return

	if floating:
		global_position.y = _origin.y + sin(_hover_time * 1.8) * 8.0
		velocity.y = 0.0
	elif not is_on_floor():
		velocity.y += 980.0 * delta

	var target_distance: float = INF
	if target != null and is_instance_valid(target):
		target_distance = global_position.distance_to(target.global_position)
		if bool(target.get("signature_hidden")):
			target_distance = INF

	if target_distance <= attack_distance and _attack_cooldown <= 0.0:
		_perform_attack()
	elif target_distance <= detection_distance:
		_set_state(State.CHASE)
		direction = signf(target.global_position.x - global_position.x)
		velocity.x = direction * chase_speed
		animator.play("move")
	elif state != State.DAMAGED:
		_set_state(State.PATROL)
		velocity.x = direction * patrol_speed
		if global_position.x <= _origin.x - patrol_distance:
			direction = 1.0
		elif global_position.x >= _origin.x + patrol_distance:
			direction = -1.0
		animator.play("move")

	animator.flip_h = direction > 0.0
	animator.speed_scale = clampf(absf(velocity.x) / maxf(patrol_speed, 1.0), 0.8, 1.8)
	move_and_slide()


func configure_target(player: PlayerController) -> void:
	target = player


func receive_resonance(actor: Node) -> bool:
	if state in [State.DEFEATED, State.RESPAWNING] or not actor is PlayerController:
		return false

	health -= 1
	velocity.x = signf(global_position.x - actor.global_position.x) * 120.0
	_set_state(State.DAMAGED)
	animator.speed_scale = 1.0
	animator.play("damage")
	_spawn_vfx(resonance_vfx_path)
	if health <= 0:
		_defeat(actor)
	else:
		var tween := create_tween()
		tween.tween_interval(0.35)
		tween.tween_callback(func() -> void: _set_state(State.ALERT))
	return true


func get_interaction_label() -> String:
	return "F: romper assinatura de %s" % display_name


func _perform_attack() -> void:
	if state in [State.DEFEATED, State.RESPAWNING, State.ATTACK]:
		return
	_attack_cooldown = attack_cooldown_seconds
	velocity.x = 0.0
	_set_state(State.ATTACK)
	animator.speed_scale = 1.0
	animator.play("attack")
	attack_started.emit(enemy_id)
	_spawn_vfx(attack_vfx_path)

	if target != null and global_position.distance_to(target.global_position) <= attack_distance * 1.35:
		if enemy_id == &"fallen_shadow":
			target.add_points(-5)
		target.take_damage(contact_damage, global_position)

	var tween := create_tween()
	tween.tween_interval(0.48)
	tween.tween_callback(func() -> void:
		if state == State.ATTACK:
			_set_state(State.ALERT)
	)


func _defeat(actor: PlayerController) -> void:
	_set_state(State.DEFEATED)
	velocity = Vector2.ZERO
	contact_area.set_deferred("monitoring", false)
	animator.play("death")
	actor.add_points(point_reward)
	defeated.emit(enemy_id, point_reward)
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0
		_set_state(State.RESPAWNING)
		_respawn_remaining = 5.0
	)


func _on_contact_entered(body: Node) -> void:
	if body is PlayerController and state not in [State.DEFEATED, State.RESPAWNING]:
		target = body
		if _attack_cooldown <= 0.0:
			_perform_attack()


func _set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(StringName(State.keys()[state].to_lower()))


func _spawn_vfx(texture_path: String) -> void:
	if texture_path.is_empty():
		return
	var texture: Texture2D = load(texture_path)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.z_index = 50
	var vfx_parent := get_tree().current_scene
	if vfx_parent == null:
		vfx_parent = get_parent()
	if vfx_parent == null:
		return
	vfx_parent.add_child(sprite)
	sprite.global_position = global_position + Vector2(0.0, -30.0)
	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.35, 1.35), 0.35)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(sprite.queue_free)


func _apply_balance_data() -> void:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		return
	var balance: Dictionary = registry.get_section(&"balance")
	var enemy_balance: Dictionary = balance.get("enemies", {}).get(String(enemy_id), {})
	if enemy_balance.is_empty():
		return
	max_health = int(enemy_balance.get("health", max_health))
	contact_damage = int(enemy_balance.get("damage", contact_damage))
	patrol_speed = float(enemy_balance.get("patrol_speed", patrol_speed))
	chase_speed = float(enemy_balance.get("chase_speed", chase_speed))
	var point_rewards: Dictionary = balance.get("points", {}).get("enemy_defeat", {})
	point_reward = int(point_rewards.get(String(enemy_id), point_reward))


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in ["idle", "move", "alert", "attack", "damage", "death", "respawn"]:
		if not frames.has_animation(animation_name):
			frames.add_animation(animation_name)
		var frame_index := 0
		while frame_index < 12:
			var path := "%s/%s_%d.png" % [frame_root, animation_name, frame_index]
			if not ResourceLoader.exists(path):
				break
			var texture: Texture2D = load(path)
			if texture != null:
				frames.add_frame(animation_name, texture)
			frame_index += 1
		frames.set_animation_loop(animation_name, animation_name in ["idle", "move", "alert"])
		frames.set_animation_speed(animation_name, 7.0 if animation_name in ["move", "attack"] else 5.0)
	return frames
