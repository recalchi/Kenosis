extends CharacterBody2D
class_name PlayerController

signal failed(points: int)
signal points_changed(points: int)
signal nearby_target_changed(label: String)
signal health_changed(health: int, max_health: int)
signal stealth_changed(hidden: bool, cover_available: bool, crouching: bool)

@export var speed := 210.0
@export var jump_velocity := -430.0
@export var gravity := 980.0
@export var failure_penalty := 10
@export var max_health := 3
@export var max_points := 999
@export var damage_invulnerability_seconds := 1.1

var points := 100
var health := 3
var checkpoint_position := Vector2.ZERO
var resonance_system: ResonanceSystem
var signature_hidden := false
var is_crouching := false
var _inside_stealth_cover := false
var _last_nearby_label := ""
var _visual_lock_seconds := 0.0
var _facing_direction := 1
var _was_on_floor := false
var _invulnerability_remaining := 0.0
var _stealth_key_held := false
var _last_crouching := false

@onready var interaction_area: Area2D = $InteractionArea
@onready var animator: AnimatedSprite2D = $PlayerAnimator


func _ready() -> void:
	checkpoint_position = global_position
	_was_on_floor = is_on_floor()
	points_changed.emit(points)
	health_changed.emit(health, max_health)
	stealth_changed.emit(false, false, false)
	animator.frame_changed.connect(_on_animation_frame_changed)
	force_visual_state("idle")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode in [KEY_SHIFT, KEY_C] or key_event.physical_keycode in [KEY_SHIFT, KEY_C]:
			_stealth_key_held = key_event.pressed


func _physics_process(delta: float) -> void:
	_invulnerability_remaining = maxf(0.0, _invulnerability_remaining - delta)
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction := Input.get_axis("move_left", "move_right")
	if absf(direction) > 0.1:
		var next_facing := 1 if direction > 0.0 else -1
		if next_facing != _facing_direction and is_on_floor():
			set_facing_direction(next_facing)
			lock_visual_state("turn", 0.22)
		else:
			set_facing_direction(next_facing)
	is_crouching = _is_stealth_pressed() and is_on_floor()
	var next_hidden := is_crouching and _inside_stealth_cover
	var crouching_changed := is_crouching != _last_crouching
	_last_crouching = is_crouching
	if next_hidden != signature_hidden or crouching_changed:
		signature_hidden = next_hidden
		stealth_changed.emit(signature_hidden, _inside_stealth_cover, is_crouching)
	_update_stealth_visual()
	velocity.x = direction * speed * (0.48 if is_crouching else 1.0)

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity
		lock_visual_state("jump_start", 0.18)

	move_and_slide()
	if is_on_floor() and not _was_on_floor:
		lock_visual_state("land", 0.24)
	_was_on_floor = is_on_floor()
	_update_nearby_target()
	_update_visual_state(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("resonance"):
		_try_resonance()


func set_checkpoint(position: Vector2) -> void:
	checkpoint_position = position


func set_facing_direction(direction: int) -> void:
	_facing_direction = -1 if direction < 0 else 1
	if animator != null:
		animator.flip_h = _facing_direction < 0


func set_stealth_cover_active(active: bool) -> void:
	_inside_stealth_cover = active
	if not active:
		signature_hidden = false
	stealth_changed.emit(signature_hidden, _inside_stealth_cover, is_crouching)
	_update_stealth_visual()


func set_signature_hidden(hidden: bool) -> void:
	signature_hidden = hidden
	stealth_changed.emit(signature_hidden, _inside_stealth_cover, is_crouching)
	_update_stealth_visual()


func add_points(amount: int) -> void:
	points = clampi(points + amount, 0, max_points)
	points_changed.emit(points)


func spend_points(amount: int) -> bool:
	if amount <= 0 or points < amount:
		return false
	points -= amount
	points_changed.emit(points)
	return true


func get_memory_rank() -> String:
	if points >= 180:
		return "S"
	if points >= 140:
		return "A"
	if points >= 100:
		return "B"
	return "C"


func register_failure() -> void:
	points = max(0, points - failure_penalty)
	points_changed.emit(points)
	velocity = Vector2.ZERO
	lock_visual_state("death", 0.0)
	failed.emit(points)


func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> bool:
	if amount <= 0 or _invulnerability_remaining > 0.0 or health <= 0:
		return false

	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	_invulnerability_remaining = damage_invulnerability_seconds
	velocity.x = -180.0 if source_position.x > global_position.x else 180.0
	velocity.y = -185.0
	lock_visual_state("damage_hit", 0.42)
	_flash_damage()

	if health <= 0:
		register_failure()
	return true


func restore_health() -> void:
	health = max_health
	_invulnerability_remaining = 0.0
	health_changed.emit(health, max_health)
	_update_stealth_visual()


func respawn_at_checkpoint() -> void:
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	restore_health()
	lock_visual_state("respawn", 0.95)


func force_visual_state(state_name: StringName) -> void:
	if animator == null or animator.sprite_frames == null:
		return

	if not animator.sprite_frames.has_animation(state_name):
		return

	if animator.animation != state_name:
		animator.play(state_name)
	if state_name not in ["run", "walk", "crouch_stealth"]:
		animator.speed_scale = 1.0


func lock_visual_state(state_name: StringName, duration_seconds: float) -> void:
	_visual_lock_seconds = duration_seconds
	force_visual_state(state_name)


func _try_interact() -> void:
	var target := _find_nearest_area("interactable")
	if target != null and target.has_method("interact"):
		lock_visual_state("interact", 0.35)
		target.interact(self)


func _try_resonance() -> void:
	var target := _find_nearest_area("resonance_target")
	if resonance_system != null:
		var activated := resonance_system.try_activate(target, self)
		if activated:
			lock_visual_state("resonance", 0.45)


func _update_nearby_target() -> void:
	var target := _find_nearest_area("interactable")
	if target == null:
		target = _find_nearest_area("resonance_target")

	var label := ""

	if target != null:
		if target.has_method("get_interaction_label"):
			label = target.get_interaction_label()
		else:
			label = "E: Interagir"

	if label != _last_nearby_label:
		_last_nearby_label = label
		nearby_target_changed.emit(label)


func _find_nearest_area(group_name: StringName) -> Node:
	var nearest: Node
	var nearest_distance := INF
	var candidates: Array[Node] = []

	for area in interaction_area.get_overlapping_areas():
		candidates.append(area)
	for body in interaction_area.get_overlapping_bodies():
		candidates.append(body)

	for candidate_entry in candidates:
		var candidate: Node = candidate_entry
		if not candidate.is_in_group(group_name) and candidate.get_parent() != null and candidate.get_parent().is_in_group(group_name):
			candidate = candidate.get_parent()
		if candidate.is_in_group(group_name):
			var distance := global_position.distance_squared_to(candidate.global_position)
			if distance < nearest_distance:
				nearest = candidate
				nearest_distance = distance

	return nearest


func _update_visual_state(delta: float) -> void:
	if _visual_lock_seconds > 0.0:
		_visual_lock_seconds = maxf(0.0, _visual_lock_seconds - delta)
		return

	if is_crouching:
		force_visual_state("crouch_stealth" if absf(velocity.x) > 1.0 else "crouch")
		animator.speed_scale = clampf(absf(velocity.x) / (speed * 0.48), 0.75, 1.05) if absf(velocity.x) > 1.0 else 1.0
		return
	elif not is_on_floor():
		if velocity.y < -120.0:
			force_visual_state("jump_rise")
		elif velocity.y < 90.0:
			force_visual_state("apex")
		else:
			force_visual_state("fall")
		return

	if absf(velocity.x) > 1.0:
		force_visual_state("run")
		animator.speed_scale = clampf(absf(velocity.x) / speed, 0.85, 1.15)
	else:
		force_visual_state("idle")


func _on_animation_frame_changed() -> void:
	if not is_on_floor() or absf(velocity.x) <= 20.0 or signature_hidden:
		return

	var foot_frames: Array = [1, 5] if animator.animation == "run" else [1, 3]
	if animator.animation not in ["run", "walk", "crouch_stealth"] or animator.frame not in foot_frames:
		return

	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("play_footstep"):
		audio.play_footstep()


func _is_stealth_pressed() -> bool:
	return _stealth_key_held or Input.is_action_pressed("stealth") or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_C)


func _update_stealth_visual() -> void:
	if animator == null:
		return
	if signature_hidden:
		animator.modulate = Color(0.58, 0.82, 0.86, 0.78)
	elif is_crouching:
		animator.modulate = Color(0.82, 0.88, 0.82, 1.0)
	else:
		animator.modulate = Color.WHITE


func _flash_damage() -> void:
	if animator == null:
		return
	animator.modulate = Color(1.45, 0.48, 0.42, 1.0)
	var tween := create_tween()
	tween.tween_property(animator, "modulate", Color.WHITE, 0.28)
