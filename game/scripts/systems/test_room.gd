extends Node2D

const PlayerControllerScript := preload("res://scripts/player/player_controller.gd")
const ResonanceSystemScript := preload("res://scripts/systems/resonance_system.gd")
const ResonanceSourceScript := preload("res://scripts/systems/resonance_source.gd")
const ResonanceReceiverScript := preload("res://scripts/systems/resonance_receiver.gd")
const ResonanceGateScript := preload("res://scripts/systems/gate.gd")
const ResonanceBridgeScript := preload("res://scripts/systems/resonance_bridge.gd")
const HazardScript := preload("res://scripts/systems/hazard.gd")
const CompletionZoneScript := preload("res://scripts/systems/completion_zone.gd")
const CheckpointStationScript := preload("res://scripts/systems/checkpoint_station.gd")
const MemoryFragmentScript := preload("res://scripts/interactables/memory_fragment.gd")
const MemorySealScript := preload("res://scripts/interactables/memory_seal.gd")
const PrototypeHUDScript := preload("res://scripts/ui/prototype_hud.gd")
const CorruptedPatrollerScene := preload("res://scenes/enemies/CorruptedPatroller.tscn")
const StealthCoverScene := preload("res://scenes/interactables/StealthCover.tscn")
const LoreScarScene := preload("res://scenes/interactables/LoreScar.tscn")

const WORLD_LEFT := -180.0
const WORLD_RIGHT := 2720.0
const GROUND_SURFACE_Y := 433.0

var player: PlayerController
var resonance_system: ResonanceSystem
var hud: PrototypeHUD
var completion_zone: CompletionZone
var corrupted_patroller: CorruptedPatroller
var _balance: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_balance()
	_create_background()
	_create_systems()
	_create_world()
	_create_player()
	_wire_signals()


func _process(_delta: float) -> void:
	_update_parallax()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if hud.is_death_menu_visible() or hud.is_completion_visible():
			return

		if hud.is_pause_menu_visible():
			_resume_game()
		else:
			_pause_game()


func _create_systems() -> void:
	resonance_system = ResonanceSystemScript.new()
	resonance_system.name = "ResonanceSystem"
	resonance_system.process_mode = Node.PROCESS_MODE_PAUSABLE
	resonance_system.cooldown_seconds = float(_balance_at(["resonance", "cooldown_seconds"], resonance_system.cooldown_seconds))
	add_child(resonance_system)

	hud = PrototypeHUDScript.new()
	hud.name = "PrototypeHUD"
	add_child(hud)


func _create_background() -> void:
	var background_fill := Polygon2D.new()
	background_fill.name = "BackgroundFill"
	background_fill.z_index = -220
	background_fill.color = Color(0.19, 0.52, 0.78, 1.0)
	background_fill.polygon = PackedVector2Array([
		Vector2(WORLD_LEFT - 1200.0, -700.0),
		Vector2(WORLD_RIGHT + 1200.0, -700.0),
		Vector2(WORLD_RIGHT + 1200.0, 900.0),
		Vector2(WORLD_LEFT - 1200.0, 900.0),
	])
	add_child(background_fill)

	var parallax_scene := Node2D.new()
	parallax_scene.name = "ParallaxScene"
	parallax_scene.z_index = -100
	add_child(parallax_scene)

	var sky_layer := _create_parallax_layer(parallax_scene, "SkyLayer", 0.0, -100)
	sky_layer.set_meta("sky_fill", true)

	var mountain_layer := _create_parallax_layer(parallax_scene, "MountainLayer", 0.12, -90)
	for x_position in [-100.0, 720.0, 1540.0, 2360.0, 3180.0]:
		_create_parallax_sprite(mountain_layer, "res://assets/sprites/backgrounds/day/mountains_far.png", Vector2(x_position, 360), 130.0, Color(0.70, 0.82, 0.86, 0.76))

	var architecture_layer := _create_parallax_layer(parallax_scene, "ArchitectureLayer", 0.24, -80)
	for x_position in [160.0, 760.0, 1360.0, 1960.0, 2560.0]:
		_create_parallax_sprite(architecture_layer, "res://assets/sprites/backgrounds/day/architecture_towers.png", Vector2(x_position, 385), 120.0, Color(0.43, 0.57, 0.59, 0.48))

	var midground_layer := _create_parallax_layer(parallax_scene, "MidgroundLayer", 0.42, -70)
	_create_parallax_sprite(midground_layer, "res://assets/sprites/backgrounds/day/midground_arch.png", Vector2(120, 410), 165.0, Color(0.48, 0.60, 0.54, 0.60))
	_create_parallax_sprite(midground_layer, "res://assets/sprites/backgrounds/day/midground_shrine.png", Vector2(720, 415), 150.0, Color(0.46, 0.58, 0.54, 0.58))
	_create_parallax_sprite(midground_layer, "res://assets/sprites/backgrounds/day/midground_ruins.png", Vector2(1330, 410), 160.0, Color(0.44, 0.57, 0.52, 0.58))
	_create_parallax_sprite(midground_layer, "res://assets/sprites/backgrounds/day/midground_arch.png", Vector2(1900, 410), 165.0, Color(0.48, 0.60, 0.54, 0.60))
	_create_parallax_sprite(midground_layer, "res://assets/sprites/backgrounds/day/midground_shrine.png", Vector2(2420, 415), 150.0, Color(0.46, 0.58, 0.54, 0.58))


func _create_parallax_layer(parent: Node2D, node_name: String, factor: float, layer_z_index: int) -> Node2D:
	var layer := Node2D.new()
	layer.name = node_name
	layer.z_index = layer_z_index
	layer.set_meta("parallax_factor", factor)
	parent.add_child(layer)
	return layer


func _create_parallax_sprite(parent: Node2D, texture_path: String, position: Vector2, target_height: float, tint: Color) -> Sprite2D:
	var texture: Texture2D = load(texture_path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.modulate = tint
	if texture != null and texture.get_height() > 0:
		var scale_factor := target_height / float(texture.get_height())
		sprite.scale = Vector2(scale_factor, scale_factor)
	parent.add_child(sprite)
	return sprite


func _update_parallax() -> void:
	var camera := get_viewport().get_camera_2d()
	var parallax_scene := get_node_or_null("ParallaxScene")
	if camera == null or parallax_scene == null:
		return

	for layer in parallax_scene.get_children():
		var factor := float(layer.get_meta("parallax_factor", 1.0))
		layer.position.x = camera.global_position.x * (1.0 - factor)


func _create_world() -> void:
	var ground_underlay := Polygon2D.new()
	ground_underlay.name = "GroundUnderlay"
	ground_underlay.z_index = -6
	ground_underlay.color = Color(0.055, 0.10, 0.105, 1.0)
	ground_underlay.polygon = PackedVector2Array([
		Vector2(WORLD_LEFT, 445),
		Vector2(WORLD_RIGHT, 445),
		Vector2(WORLD_RIGHT, 900),
		Vector2(WORLD_LEFT, 900),
	])
	add_child(ground_underlay)

	_create_grounded_prop("BackTreeLeft", Vector2(70, GROUND_SURFACE_Y), 162.0, "res://assets/sprites/props/scenario/tree_oak.png", -12, Color(0.88, 0.96, 0.84, 0.94))
	_create_grounded_prop("BackTreeMiddle", Vector2(1750, GROUND_SURFACE_Y), 154.0, "res://assets/sprites/props/scenario/tree_broad.png", -12, Color(0.82, 0.93, 0.79, 0.90))
	_create_grounded_prop("BackTreeRight", Vector2(2590, GROUND_SURFACE_Y), 178.0, "res://assets/sprites/props/scenario/tree_oak.png", -12, Color(0.88, 0.96, 0.84, 0.94))
	_create_grounded_prop("BackShrubA", Vector2(1535, GROUND_SURFACE_Y), 34.0, "res://assets/sprites/props/scenario/bush_round.png", -9, Color(0.78, 0.93, 0.76, 0.95))
	_create_grounded_prop("BackShrubB", Vector2(2380, GROUND_SURFACE_Y), 40.0, "res://assets/sprites/props/scenario/bush_round.png", -9, Color(0.74, 0.90, 0.72, 0.95))

	var world_width := WORLD_RIGHT - WORLD_LEFT
	_create_tiled_static_body("Floor", Vector2((WORLD_LEFT + WORLD_RIGHT) * 0.5, 455), Vector2(world_width, 44), "res://assets/sprites/tilesets/scenario/ground_grass_long.png", 76.0, "FloorSprite")
	_create_static_rect("LeftBoundary", Vector2(WORLD_LEFT + 20.0, 250), Vector2(40, 430), Color(0.0, 0.0, 0.0, 0.0))
	_create_static_rect("RightBoundary", Vector2(WORLD_RIGHT - 20.0, 250), Vector2(40, 430), Color(0.0, 0.0, 0.0, 0.0))
	_create_platform("UpperPlatform", Vector2(565, 305), 190.0, "res://assets/sprites/tilesets/scenario/platform_floating_grass.png", "UpperPlatformSprite")
	_create_platform("LookoutPlatform", Vector2(995, 325), 155.0, "res://assets/sprites/tilesets/scenario/platform_stone_bridge.png", "LookoutPlatformSprite")
	_create_platform("MemoryStepA", Vector2(1640, 342), 160.0, "res://assets/sprites/tilesets/scenario/platform_floating_grass.png", "MemoryStepASprite")
	_create_platform("MemoryStepB", Vector2(1870, 282), 148.0, "res://assets/sprites/tilesets/scenario/platform_stone_bridge.png", "MemoryStepBSprite")
	_create_platform("RuinsPlatform", Vector2(2080, 348), 178.0, "res://assets/sprites/tilesets/scenario/platform_floating_grass.png", "RuinsPlatformSprite")
	var sealed_platform := _create_platform("SealedPlatform", Vector2(2290, 286), 166.0, "res://assets/sprites/tilesets/scenario/platform_stone_bridge.png", "SealedPlatformSprite")
	var sealed_collision := sealed_platform.get_node("CollisionShape2D") as CollisionShape2D
	sealed_collision.disabled = true
	var sealed_visual := sealed_platform.get_node("SealedPlatformSprite") as Sprite2D
	sealed_visual.modulate = Color(0.45, 0.86, 0.92, 0.28)
	_create_checkpoint(Vector2(150, 402))
	_create_source(Vector2(335, 395), Vector2(62, 82))
	var receiver := _create_receiver(Vector2(475, 402), Vector2(62, 64))
	var gate := _create_gate(Vector2(940, 392), Vector2(64, 92))
	var bridge := _create_bridge(Vector2(700, GROUND_SURFACE_Y), Vector2(220, 24))
	var hazard := _create_hazard(Vector2(700, 442), Vector2(216, 38))
	receiver.activated.connect(gate.open_gate)
	receiver.activated.connect(bridge.activate_bridge)
	receiver.activated.connect(hazard.neutralize)
	_create_lore_scar(Vector2(865, 410))
	_create_stealth_cover(Vector2(1080, 433))
	_create_corrupted_patroller(Vector2(1250, 405))
	_create_lore_scar(
		Vector2(1760, 410),
		"Eco da Segunda Margem",
		["A memoria nao termina quando a ameaca cessa.", "Ela precisa de forma, custo e destino."],
	)
	_create_lore_scar(
		Vector2(2410, 410),
		"Inscricao de Retorno",
		["O campo registra o que foi preservado.", "O restante volta como regressao."],
	)
	_create_lore_scar(
		Vector2(2605, 410),
		"Limite do Campo",
		["A saida nao mede pressa.", "Ela mede o que ainda permanece depois da travessia."],
	)
	_create_memory_fragment("MemoryFragmentA", Vector2(1570, 392))
	_create_memory_fragment("MemoryFragmentB", Vector2(1870, 232))
	_create_memory_fragment("MemoryFragmentC", Vector2(2290, 236))
	_create_memory_fragment("MemoryFragmentD", Vector2(2460, 388))
	_create_memory_seal(Vector2(2070, 390), sealed_platform)
	completion_zone = _create_completion_zone(Vector2(2520, 382), Vector2(78, 108))


func _create_player() -> void:
	player = PlayerControllerScript.new()
	player.name = "Player"
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.collision_layer = 2
	player.collision_mask = 1
	player.position = Vector2(150, 408)
	player.resonance_system = resonance_system
	player.speed = float(_balance_at(["player", "speed"], player.speed))
	player.jump_velocity = float(_balance_at(["player", "jump_velocity"], player.jump_velocity))
	player.failure_penalty = int(_balance_at(["player", "failure_penalty"], player.failure_penalty))
	player.max_health = int(_balance_at(["player", "max_health"], player.max_health))
	player.health = player.max_health
	player.max_points = int(_balance_at(["player", "max_memory"], player.max_points))

	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(28, 46)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = body_shape
	player.add_child(collision)

	var sprite_frames := _create_player_sprite_frames()
	if sprite_frames != null:
		var animator := AnimatedSprite2D.new()
		animator.name = "PlayerAnimator"
		animator.sprite_frames = sprite_frames
		animator.animation = "idle"
		animator.scale = Vector2(0.72, 0.72)
		animator.position = Vector2(0, -21)
		animator.play("idle")
		player.add_child(animator)
	else:
		var visual := Polygon2D.new()
		visual.name = "PixelPlaceholder"
		visual.color = Color(0.78, 0.84, 0.95, 1.00)
		visual.polygon = PackedVector2Array([
			Vector2(-14, -23),
			Vector2(14, -23),
			Vector2(14, 23),
			Vector2(-14, 23),
		])
		player.add_child(visual)

	var interaction_area := Area2D.new()
	interaction_area.name = "InteractionArea"
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 1 | 4
	player.add_child(interaction_area)

	var interaction_shape := CircleShape2D.new()
	interaction_shape.radius = float(_balance_at(["resonance", "interaction_radius"], 150.0))

	var interaction_collision := CollisionShape2D.new()
	interaction_collision.name = "CollisionShape2D"
	interaction_collision.shape = interaction_shape
	interaction_area.add_child(interaction_collision)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(250, -74)
	camera.zoom = Vector2(0.82, 0.82)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = int(WORLD_LEFT)
	camera.limit_right = int(WORLD_RIGHT)
	camera.limit_top = -110
	camera.limit_bottom = 590
	camera.enabled = true
	player.add_child(camera)

	add_child(player)


func _wire_signals() -> void:
	player.points_changed.connect(hud.set_points)
	player.health_changed.connect(hud.set_health)
	player.stealth_changed.connect(hud.set_stealth)
	player.nearby_target_changed.connect(hud.set_prompt)
	player.failed.connect(_on_player_failed)
	resonance_system.cooldown_changed.connect(hud.set_resonance)
	resonance_system.resonance_succeeded.connect(_on_resonance_succeeded)
	resonance_system.resonance_failed.connect(func(reason: String) -> void:
		hud.show_message("Ressonancia falhou: %s" % reason)
		_audio_sfx("error")
	)
	hud.resume_requested.connect(_resume_game)
	hud.retry_requested.connect(_retry_after_failure)
	hud.menu_requested.connect(_return_to_menu)
	hud.quit_requested.connect(_quit_game)
	corrupted_patroller.player_caught.connect(func() -> void: _audio_sfx("failure"))
	corrupted_patroller.alert_started.connect(_on_enemy_alerted)
	corrupted_patroller.purified.connect(_on_enemy_purified)
	hud.set_health(player.health, player.max_health)
	hud.set_stealth(player.signature_hidden, false, player.is_crouching)
	hud.set_objective("1 / 6", "Observe a fonte, alcance o receptor e canalize F para abrir a ponte.")
	hud.set_points_context("Memorias abrem selos e definem rank.")


func _on_player_failed(points: int) -> void:
	if hud.is_death_menu_visible():
		return

	get_tree().paused = true
	hud.show_death_menu(points)


func _on_resonance_succeeded(_target: Node) -> void:
	player.lock_visual_state("resonance", 0.45)
	hud.show_message("Ressonancia transferida")
	hud.set_objective("2 / 6", "Ponte materializada. Atravesse o lago e leia a primeira cicatriz.")
	hud.set_points_context("Falha: -%d memorias. Checkpoint salva." % player.failure_penalty)
	_audio_sfx("confirm")


func _pause_game() -> void:
	get_tree().paused = true
	hud.show_pause_menu()


func _resume_game() -> void:
	get_tree().paused = false
	hud.hide_pause_menu()
	hud.hide_death_menu()
	hud.hide_completion()


func _retry_after_failure() -> void:
	player.respawn_at_checkpoint()
	_resume_game()
	hud.show_message("Tente novamente")
	hud.set_objective("2 / 6", "Recupere o ritmo: use a ponte, leia a cicatriz e evite contato frontal.")


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MenuHub.tscn")


func _quit_game() -> void:
	get_tree().quit()


func _on_completion() -> void:
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.mark_test_field_complete(player.points)
	_audio_music("complete")
	get_tree().paused = true
	hud.show_completion(player.points)


func _on_enemy_alerted() -> void:
	hud.show_message("Assinatura detectada. Alcance uma cobertura.")
	hud.set_objective("3 / 6", "Use Shift ou C dentro da cobertura para ocultar a assinatura.")
	_audio_sfx("alert")
	_spawn_vfx("res://assets/sprites/vfx/alert_hit.png", corrupted_patroller.global_position + Vector2(0, -62), Vector2(0.46, 0.46), Color(0.9, 0.4, 0.9, 0.95))


func _on_enemy_purified() -> void:
	completion_zone.unlock()
	player.add_points(int(_balance_at(["points", "enemy_defeat", "corrupted_patroller"], 15)))
	hud.show_message("No de corrupcao desfeito. A saida foi liberada.")
	hud.set_objective("4 / 6", "Saida liberada. Explore a segunda margem antes de concluir.")
	hud.set_points_context("Selo: -%d memorias, rota opcional." % int(_balance_at(["points", "memory_seal_activation"], 20)))
	_audio_sfx("confirm")
	_spawn_vfx("res://assets/sprites/vfx/resonance_burst.png", corrupted_patroller.global_position + Vector2(0, -34), Vector2(0.72, 0.72), Color(0.55, 1.0, 1.0, 0.95))


func _create_static_rect(node_name: String, position: Vector2, size: Vector2, color: Color, texture_path: String = "", visual_name: String = "") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = position
	add_child(body)

	var shape := RectangleShape2D.new()
	shape.size = size

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)

	if texture_path.is_empty():
		body.add_child(_make_rect_visual(size, color))
	else:
		var sprite_name := visual_name if not visual_name.is_empty() else "%sSprite" % node_name
		body.add_child(_make_sprite_visual(sprite_name, texture_path, size, color))
	return body


func _create_platform(node_name: String, surface_position: Vector2, visible_width: float, texture_path: String, visual_name: String) -> StaticBody2D:
	var texture: Texture2D = load(texture_path)
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = surface_position
	add_child(body)

	var collision_height := 16.0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(visible_width, collision_height)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	collision.position.y = collision_height * 0.5
	body.add_child(collision)

	if texture == null:
		body.add_child(_make_rect_visual(Vector2(visible_width, collision_height), Color(0.28, 0.30, 0.28, 1.0)))
		return body

	var visual := Sprite2D.new()
	visual.name = visual_name
	visual.texture = texture
	var scale_factor := visible_width / float(texture.get_width())
	visual.scale = Vector2(scale_factor, scale_factor)
	visual.position.y = float(texture.get_height()) * scale_factor * 0.5
	body.add_child(visual)
	return body


func _create_tiled_static_body(node_name: String, position: Vector2, size: Vector2, texture_path: String, tile_height: float, visual_name: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = position
	add_child(body)

	var shape := RectangleShape2D.new()
	shape.size = size

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)

	body.add_child(_make_tiled_sprite_visual(visual_name, texture_path, size, tile_height))
	return body


func _create_prop(node_name: String, position: Vector2, size: Vector2, texture_path: String, z_layer: int = -5, tint: Color = Color.WHITE) -> Sprite2D:
	var prop := _make_sprite_visual(node_name, texture_path, size, Color.WHITE) as Sprite2D
	prop.position = position
	prop.z_index = z_layer
	prop.modulate = tint
	add_child(prop)
	return prop


func _create_grounded_prop(node_name: String, ground_position: Vector2, target_height: float, texture_path: String, z_layer: int, tint: Color) -> Sprite2D:
	var texture: Texture2D = load(texture_path)
	var prop := Sprite2D.new()
	prop.name = node_name
	prop.texture = texture
	prop.z_index = z_layer
	prop.modulate = tint
	if texture != null and texture.get_height() > 0:
		var scale_factor := target_height / float(texture.get_height())
		prop.scale = Vector2(scale_factor, scale_factor)
		prop.position = ground_position - Vector2(0.0, target_height * 0.5)
	else:
		prop.position = ground_position
	add_child(prop)
	return prop


func _create_checkpoint(position: Vector2) -> CheckpointStation:
	var checkpoint := CheckpointStationScript.new()
	checkpoint.name = "MemoryCheckpoint"
	checkpoint.process_mode = Node.PROCESS_MODE_PAUSABLE
	checkpoint.position = position
	checkpoint.reward_points = int(_balance_at(["points", "checkpoint_first_activation"], checkpoint.reward_points))
	add_child(checkpoint)

	var shape := CircleShape2D.new()
	shape.radius = 42
	var collision := CollisionShape2D.new()
	collision.shape = shape
	checkpoint.add_child(collision)

	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("activate")
	frames.set_animation_loop("idle", true)
	frames.set_animation_loop("activate", false)
	frames.set_animation_speed("idle", 2.0)
	frames.set_animation_speed("activate", 5.0)
	var inactive: Texture2D = load("res://assets/sprites/vfx/checkpoint_inactive.png")
	var charging: Texture2D = load("res://assets/sprites/vfx/checkpoint_charge.png")
	var active: Texture2D = load("res://assets/sprites/vfx/checkpoint_active.png")
	frames.add_frame("idle", inactive)
	frames.add_frame("idle", charging)
	frames.add_frame("activate", inactive)
	frames.add_frame("activate", charging)
	frames.add_frame("activate", active)

	var animator := AnimatedSprite2D.new()
	animator.name = "CheckpointAnimator"
	animator.sprite_frames = frames
	animator.position = Vector2(0, -40)
	animator.scale = Vector2(0.58, 0.58)
	animator.play("idle")
	checkpoint.add_child(animator)
	checkpoint.interacted.connect(func() -> void:
		animator.play("activate")
		hud.show_message("Memoria preservada")
		hud.set_objective("1 / 6", "Checkpoint ativo. Observe a fonte e procure o receptor de Ressonancia.")
		_audio_sfx("checkpoint")
		var save_system := get_node_or_null("/root/SaveSystem")
		if save_system != null:
			save_system.record_checkpoint(player.global_position, player.points)
	)
	return checkpoint


func _create_lore_scar(position: Vector2, title := "", lines: Array[String] = []) -> LoreScar:
	var lore_scar := LoreScarScene.instantiate() as LoreScar
	lore_scar.position = position
	lore_scar.process_mode = Node.PROCESS_MODE_PAUSABLE
	lore_scar.reward_points = int(_balance_at(["points", "lore_first_read"], lore_scar.reward_points))
	if not title.is_empty():
		lore_scar.lore_title = title
	if not lines.is_empty():
		lore_scar.lore_lines = lines
	add_child(lore_scar)
	lore_scar.lore_requested.connect(func(title: String, lines: Array[String]) -> void:
		hud.show_dialogue(title, lines)
		if completion_zone != null and not bool(completion_zone.get("locked")):
			hud.set_objective("5 / 6", "Preserve fragmentos, avalie o selo opcional e siga para a saida.")
		else:
			hud.set_objective("3 / 6", "Leia a patrulha, use cobertura e desate a corrupcao pelas costas.")
		_audio_sfx("lore")
	)
	return lore_scar


func _create_memory_fragment(node_name: String, position: Vector2) -> Area2D:
	var fragment := MemoryFragmentScript.new()
	fragment.name = node_name
	fragment.process_mode = Node.PROCESS_MODE_PAUSABLE
	fragment.position = position
	fragment.reward = int(_balance_at(["points", "memory_fragment"], fragment.reward))
	add_child(fragment)

	var shape := CircleShape2D.new()
	shape.radius = 28.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	fragment.add_child(collision)

	var visual := _make_sprite_visual("FragmentSprite", "res://assets/ui/reference/status_resonance.png", Vector2(36, 36), Color(0.48, 0.94, 0.92, 1.0))
	visual.position.y = -28.0
	fragment.add_child(visual)
	var bob := visual.create_tween().set_loops()
	bob.tween_property(visual, "position:y", -36.0, 0.75).set_trans(Tween.TRANS_SINE)
	bob.tween_property(visual, "position:y", -28.0, 0.75).set_trans(Tween.TRANS_SINE)
	fragment.collected.connect(func(reward: int) -> void:
		hud.show_message("Fragmento preservado: +%d memorias" % reward)
		hud.set_objective("5 / 6", "Use memorias no selo opcional ou preserve pontos para melhor classificacao.")
		hud.set_points_context("Rank: 100 B, 140 A, 180 S.")
		_audio_sfx("confirm")
	)
	return fragment


func _create_memory_seal(position: Vector2, sealed_platform: StaticBody2D) -> Area2D:
	var seal := MemorySealScript.new()
	seal.name = "MemorySeal"
	seal.process_mode = Node.PROCESS_MODE_PAUSABLE
	seal.position = position
	seal.cost = int(_balance_at(["points", "memory_seal_activation"], seal.cost))
	add_child(seal)

	var shape := CircleShape2D.new()
	shape.radius = 42.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	seal.add_child(collision)

	var visual := _make_sprite_visual("MemorySealSprite", "res://assets/sprites/vfx/checkpoint_inactive.png", Vector2(72, 90), Color(0.42, 0.78, 0.84, 1.0)) as Sprite2D
	visual.position.y = -42.0
	seal.add_child(visual)
	seal.activated.connect(func() -> void:
		var platform_collision := sealed_platform.get_node("CollisionShape2D") as CollisionShape2D
		var platform_visual := sealed_platform.get_node("SealedPlatformSprite") as Sprite2D
		platform_collision.set_deferred("disabled", false)
		platform_visual.modulate = Color.WHITE
		visual.texture = load("res://assets/sprites/vfx/checkpoint_active.png")
		hud.show_message("Selo ativo: plataforma materializada por %d memorias" % seal.cost)
		hud.set_objective("5 / 6", "Rota opcional aberta. Colete a memoria alta e avance ate a saida.")
		_audio_sfx("checkpoint")
	)
	seal.activation_denied.connect(func(cost: int) -> void:
		hud.show_message("Memorias insuficientes: o selo exige %d" % cost)
		_audio_sfx("error")
	)
	return seal


func _create_stealth_cover(position: Vector2) -> StealthCover:
	var cover := StealthCoverScene.instantiate() as StealthCover
	cover.position = position
	cover.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cover)
	return cover


func _create_corrupted_patroller(position: Vector2) -> CorruptedPatroller:
	corrupted_patroller = CorruptedPatrollerScene.instantiate() as CorruptedPatroller
	corrupted_patroller.position = position
	corrupted_patroller.process_mode = Node.PROCESS_MODE_PAUSABLE
	corrupted_patroller.patrol_speed = float(_balance_at(["enemies", "corrupted_patroller", "patrol_speed"], corrupted_patroller.patrol_speed))
	corrupted_patroller.chase_speed = float(_balance_at(["enemies", "corrupted_patroller", "chase_speed"], corrupted_patroller.chase_speed))
	corrupted_patroller.contact_damage = int(_balance_at(["enemies", "corrupted_patroller", "damage"], corrupted_patroller.contact_damage))
	add_child(corrupted_patroller)
	return corrupted_patroller


func _create_source(position: Vector2, size: Vector2) -> ResonanceSource:
	var source := ResonanceSourceScript.new()
	source.name = "ExorigemSource"
	source.process_mode = Node.PROCESS_MODE_PAUSABLE
	source.position = position
	source.reward_points = int(_balance_at(["points", "source_first_inspection"], source.reward_points))
	add_child(source)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	source.add_child(collision)

	source.add_child(_make_sprite_visual("SourceSprite", "res://assets/sprites/interactables/exorigem_source_relic.png", size, Color(0.22, 0.78, 0.92, 1.00)))
	source.interacted.connect(func() -> void:
		hud.show_message("Fonte de Exorigem estavel")
		hud.set_objective("1 / 6", "Agora use F no receptor de Ressonancia adiante.")
	)
	return source


func _create_receiver(position: Vector2, size: Vector2) -> ResonanceReceiver:
	var receiver := ResonanceReceiverScript.new()
	receiver.name = "ResonanceReceiver"
	receiver.process_mode = Node.PROCESS_MODE_PAUSABLE
	receiver.position = position
	add_child(receiver)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	receiver.add_child(collision)

	var visual := _make_sprite_visual("ReceiverSprite", "res://assets/sprites/interactables/resonance_receiver_relic.png", size, Color(0.18, 0.18, 0.24, 1.00))
	receiver.visual = visual
	receiver.add_child(visual)
	return receiver


func _create_gate(position: Vector2, size: Vector2) -> ResonanceGate:
	var gate := ResonanceGateScript.new()
	gate.name = "ResonanceGate"
	gate.position = position
	add_child(gate)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	gate.collision_shape = collision
	gate.add_child(collision)

	var visual := _make_sprite_visual("GateSprite", "res://assets/sprites/interactables/completion_gate_relic.png", size, Color(0.38, 0.12, 0.18, 1.00))
	gate.visual = visual
	gate.add_child(visual)
	return gate


func _create_bridge(position: Vector2, size: Vector2) -> ResonanceBridge:
	var bridge := ResonanceBridgeScript.new()
	bridge.name = "ResonanceBridge"
	bridge.process_mode = Node.PROCESS_MODE_PAUSABLE
	bridge.position = position

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position.y = size.y * 0.5
	bridge.collision_shape = collision
	bridge.add_child(collision)

	var visual := _make_sprite_visual(
		"BridgeSprite",
		"res://assets/sprites/tilesets/scenario/resonance_bridge.png",
		Vector2(size.x, 74),
		Color(0.30, 0.70, 0.95, 0.35)
	) as Node2D
	if visual is Sprite2D:
		var sprite := visual as Sprite2D
		visual.position.y = sprite.texture.get_height() * sprite.scale.y * 0.5
	bridge.visual = visual
	bridge.add_child(visual)
	add_child(bridge)
	return bridge


func _create_hazard(position: Vector2, size: Vector2) -> HazardZone:
	var hazard := HazardScript.new()
	hazard.name = "FailureZone"
	hazard.process_mode = Node.PROCESS_MODE_PAUSABLE
	hazard.position = position
	add_child(hazard)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	hazard.collision_shape = collision
	hazard.add_child(collision)

	var visual := _make_lake_visual("HazardSprite", size)
	hazard.visual = visual
	hazard.add_child(visual)
	return hazard


func _create_completion_zone(position: Vector2, size: Vector2) -> CompletionZone:
	var completion_zone := CompletionZoneScript.new()
	completion_zone.name = "CompletionZone"
	completion_zone.process_mode = Node.PROCESS_MODE_PAUSABLE
	completion_zone.position = position
	add_child(completion_zone)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	completion_zone.add_child(collision)

	completion_zone.add_child(_make_sprite_visual("CompletionSprite", "res://assets/ui/reference/checkpoint_complete.png", size, Color(0.18, 0.55, 0.34, 0.65)))
	completion_zone.completed.connect(func() -> void:
		hud.set_objective("6 / 6", "Campo concluido. Resultado preservado no save local.")
		_on_completion()
	)
	return completion_zone


func _load_balance() -> void:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry != null:
		if registry.has_method("reload"):
			registry.reload()
		_balance = registry.get_section(&"balance")
	if _balance.is_empty():
		var file := FileAccess.open("res://data/config/balance.json", FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_balance = parsed


func _balance_at(path: Array, fallback: Variant) -> Variant:
	var value: Variant = _balance
	for segment in path:
		if not value is Dictionary:
			return fallback
		var key := String(segment)
		if not (value as Dictionary).has(key):
			return fallback
		value = (value as Dictionary)[key]
	return value


func _spawn_vfx(texture_path: String, position: Vector2, scale_value: Vector2, tint: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.position = position
	sprite.scale = scale_value * 0.6
	sprite.modulate = tint
	sprite.z_index = 60
	add_child(sprite)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", scale_value, 0.24)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(sprite.queue_free)


func _audio_sfx(cue: StringName) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(cue)


func _audio_music(cue: StringName) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_music(cue)


func _create_world_label(text: String, position: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.z_index = 40
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.96, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label


func _create_player_sprite_frames() -> SpriteFrames:
	var animation_counts := {
		"idle": 7,
		"walk": 8,
		"run": 8,
		"turn": 4,
		"jump_start": 3,
		"jump_rise": 3,
		"apex": 2,
		"fall": 4,
		"land": 4,
		"crouch": 4,
		"crouch_stealth": 5,
		"interact": 3,
		"resonance": 7,
		"damage_hit": 4,
		"death": 6,
		"respawn": 8,
		"silhouette_shadow": 4,
	}

	var frames := SpriteFrames.new()
	for animation_name in animation_counts:
		if not frames.has_animation(animation_name):
			frames.add_animation(animation_name)
		for frame_index in range(int(animation_counts[animation_name])):
			var path := "res://assets/sprites/player/frames/player_%s_%d.png" % [animation_name, frame_index]
			var texture: Texture2D = load(path)
			if texture == null:
				return null
			frames.add_frame(animation_name, texture)
		frames.set_animation_loop(animation_name, animation_name in ["idle", "walk", "run", "crouch", "crouch_stealth", "apex"])
		frames.set_animation_speed(animation_name, _player_animation_speed(animation_name))

	for alias_name in ["walk_run", "jump"]:
		frames.add_animation(alias_name)
	var run_count: int = int(animation_counts["run"])
	for frame_index in range(run_count):
		frames.add_frame("walk_run", load("res://assets/sprites/player/frames/player_run_%d.png" % frame_index))
	frames.set_animation_loop("walk_run", true)
	frames.set_animation_speed("walk_run", 10.0)
	for frame_index in range(int(animation_counts["jump_rise"])):
		frames.add_frame("jump", load("res://assets/sprites/player/frames/player_jump_rise_%d.png" % frame_index))
	frames.set_animation_loop("jump", false)
	frames.set_animation_speed("jump", 9.0)

	return frames


func _player_animation_speed(animation_name: String) -> float:
	if animation_name == "run":
		return 12.0
	if animation_name in ["walk", "crouch_stealth"]:
		return 8.0
	if animation_name in ["resonance", "respawn"]:
		return 8.0
	if animation_name in ["damage_hit", "death", "interact", "jump_start", "jump_rise", "fall", "land", "turn"]:
		return 9.0
	return 5.0


func _make_sprite_visual(node_name: String, texture_path: String, target_size: Vector2, fallback_color: Color) -> CanvasItem:
	var texture: Texture2D = load(texture_path)
	if texture == null:
		var fallback := _make_rect_visual(target_size, fallback_color)
		fallback.name = node_name
		return fallback

	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	var texture_size: Vector2 = texture.get_size()
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		var uniform_scale := minf(target_size.x / texture_size.x, target_size.y / texture_size.y)
		sprite.scale = Vector2(uniform_scale, uniform_scale)
	return sprite


func _make_tiled_sprite_visual(node_name: String, texture_path: String, target_size: Vector2, tile_height: float) -> Node2D:
	var container := Node2D.new()
	container.name = node_name

	var texture: Texture2D = load(texture_path)
	if texture == null:
		container.add_child(_make_rect_visual(target_size, Color(0.30, 0.32, 0.34, 1.00)))
		return container

	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return container

	var scale_factor := tile_height / texture_size.y
	var scaled_width := texture_size.x * scale_factor
	var tile_count := int(ceil(target_size.x / scaled_width)) + 2
	var start_x := -target_size.x * 0.5 - scaled_width * 0.5

	for index in range(tile_count):
		var sprite := Sprite2D.new()
		sprite.name = "Tile%02d" % index
		sprite.texture = texture
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = Vector2(start_x + scaled_width * float(index), (tile_height - target_size.y) * 0.5)
		container.add_child(sprite)

	return container


func _make_lake_visual(node_name: String, size: Vector2) -> Node2D:
	var container := Node2D.new()
	container.name = node_name

	var half := size * 0.5
	var glow := Polygon2D.new()
	glow.name = "Glow"
	glow.color = Color(0.68, 0.06, 0.30, 0.28)
	glow.polygon = PackedVector2Array([
		Vector2(-half.x - 5.0, -half.y + 4.0),
		Vector2(half.x + 5.0, -half.y + 4.0),
		Vector2(half.x + 5.0, half.y),
		Vector2(-half.x - 5.0, half.y),
	])
	glow.z_index = -1
	container.add_child(glow)

	var hazard_texture: Texture2D = load("res://assets/sprites/interactables/failure_hazard.png")
	if hazard_texture != null:
		var scale_factor := minf(0.9, size.y / float(hazard_texture.get_height()))
		var tile_width := float(hazard_texture.get_width()) * scale_factor
		var tile_count := maxi(1, int(ceil(size.x / tile_width)))
		var start_x := -float(tile_count - 1) * tile_width * 0.5
		for index in range(tile_count):
			var tile := Sprite2D.new()
			tile.name = "HazardTile%02d" % index
			tile.texture = hazard_texture
			tile.scale = Vector2(scale_factor, scale_factor)
			tile.position = Vector2(start_x + float(index) * tile_width, -2.0)
			tile.modulate = Color(0.92, 0.52, 0.78, 0.96)
			container.add_child(tile)

	var aura_texture: Texture2D = load("res://assets/sprites/vfx/corruption_aura.png")
	if aura_texture != null:
		for direction in [-1.0, 1.0]:
			var aura := Sprite2D.new()
			aura.name = "CorruptionAuraLeft" if direction < 0.0 else "CorruptionAuraRight"
			aura.texture = aura_texture
			aura.position = Vector2(direction * size.x * 0.24, -size.y * 0.75)
			aura.scale = Vector2(0.42, 0.42)
			aura.modulate = Color(0.78, 0.42, 0.92, 0.48)
			aura.z_index = -1
			container.add_child(aura)

	return container


func _make_rect_visual(size: Vector2, color: Color) -> Polygon2D:
	var half := size * 0.5
	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	return visual
