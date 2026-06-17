extends SceneTree

const MENU_HUB_PATH := "res://scenes/ui/MenuHub.tscn"
const TEST_ROOM_PATH := "res://scenes/levels/TestRoom.tscn"

var _failed := false


func _init() -> void:
	await _test_menu_hub()
	await _test_room()
	if not _failed:
		print("KENOSIS_SMOKE_OK")
		quit(0)


func _test_menu_hub() -> void:
	var packed_scene := load(MENU_HUB_PATH)
	if packed_scene == null:
		_fail("could not load %s" % MENU_HUB_PATH)
		return

	var menu: Node = packed_scene.instantiate()
	if menu == null:
		_fail("could not instantiate MenuHub")
		return

	root.add_child(menu)
	await process_frame
	await process_frame

	var play_button := root.find_child("MainPlayButton", true, false)
	var tutorial_button := root.find_child("TutorialButton", true, false)
	var settings_button := root.find_child("SettingsButton", true, false)
	var settings_panel := root.find_child("SettingsPanel", true, false)
	var tutorial_panel := root.find_child("TutorialPanel", true, false)
	var tutorial_close_button := root.find_child("TutorialCloseButton", true, false)
	var menu_logo := root.find_child("MenuLogo", true, false)
	var test_field_note := root.find_child("TestFieldNote", true, false)

	if play_button == null:
		_fail("MainPlayButton not found")
		return

	play_button.pressed.emit()
	await process_frame

	var continue_button := root.find_child("ContinueButton", true, false)
	var story_button := root.find_child("StoryButton", true, false)
	var map_test_button := root.find_child("MapTestButton", true, false)

	if continue_button == null:
		_fail("ContinueButton not found")
		return

	if story_button == null or story_button.disabled:
		_fail("StoryButton should exist and open the narrative journey")
		return

	if map_test_button == null:
		_fail("MapTestButton not found")
		return

	if tutorial_button == null:
		_fail("TutorialButton not found")
		return

	if settings_button == null:
		_fail("SettingsButton not found")
		return

	if settings_panel == null:
		_fail("SettingsPanel not found")
		return

	if menu_logo == null or menu_logo.get("texture") == null:
		_fail("MenuLogo texture not loaded")
		return

	if test_field_note == null:
		_fail("TestFieldNote not found")
		return

	if tutorial_panel == null:
		_fail("TutorialPanel not found")
		return

	if tutorial_close_button == null:
		_fail("TutorialCloseButton not found")
		return

	if tutorial_panel.visible:
		_fail("TutorialPanel should start hidden")
		return

	if settings_panel.visible:
		_fail("SettingsPanel should start hidden")
		return

	menu.call("show_tutorial")
	if not tutorial_panel.visible:
		_fail("TutorialPanel did not open")
		return

	menu.call("hide_tutorial")
	if tutorial_panel.visible:
		_fail("TutorialPanel did not close")
		return

	menu.call("show_settings")
	if not settings_panel.visible:
		_fail("SettingsPanel did not open")
		return

	menu.call("hide_settings")
	if settings_panel.visible:
		_fail("SettingsPanel did not close")
		return

	var target_scene_path: String = menu.get("test_room_path")
	if target_scene_path != TEST_ROOM_PATH:
		_fail("MenuHub target scene path is invalid")
		return

	root.remove_child(menu)
	menu.queue_free()
	await process_frame


func _test_room() -> void:
	var packed_scene := load(TEST_ROOM_PATH)
	if packed_scene == null:
		_fail("could not load %s" % TEST_ROOM_PATH)
		return

	var room: Node = packed_scene.instantiate()
	if room == null:
		_fail("could not instantiate TestRoom")
		return

	root.add_child(room)
	await process_frame
	await process_frame

	var player := root.find_child("Player", true, false)
	var resonance_system := root.find_child("ResonanceSystem", true, false)
	var hud := root.find_child("PrototypeHUD", true, false)
	var health_bar := root.find_child("HealthBar", true, false)
	var health_label := root.find_child("HealthLabel", true, false)
	var stealth_label := root.find_child("StealthLabel", true, false)
	var receiver := root.find_child("ResonanceReceiver", true, false)
	var gate := root.find_child("ResonanceGate", true, false)
	var bridge := root.find_child("ResonanceBridge", true, false)
	var source := root.find_child("ExorigemSource", true, false)
	var checkpoint := root.find_child("MemoryCheckpoint", true, false)
	var completion_zone := root.find_child("CompletionZone", true, false)
	var failure_zone := root.find_child("FailureZone", true, false)
	var enemy := root.find_child("CorruptedPatroller", true, false)
	var enemy_animator := root.find_child("EnemyAnimator", true, false)
	var vision_area := root.find_child("VisionArea", true, false)
	var stealth_cover := root.find_child("StealthCover", true, false)
	var lore_scar := root.find_child("LoreScar", true, false)
	var dialogue_overlay := root.find_child("DialogueOverlay", true, false)
	var checkpoint_animator := root.find_child("CheckpointAnimator", true, false)
	var audio_manager := root.find_child("AudioManager", true, false)
	var parallax_scene := root.find_child("ParallaxScene", true, false)
	var sky_layer := root.find_child("SkyLayer", true, false)
	var mountain_layer := root.find_child("MountainLayer", true, false)
	var architecture_layer := root.find_child("ArchitectureLayer", true, false)
	var midground_layer := root.find_child("MidgroundLayer", true, false)
	var player_animator := root.find_child("PlayerAnimator", true, false)
	var source_sprite := root.find_child("SourceSprite", true, false)
	var receiver_sprite := root.find_child("ReceiverSprite", true, false)
	var gate_sprite := root.find_child("GateSprite", true, false)
	var hazard_sprite := root.find_child("HazardSprite", true, false)
	var bridge_sprite := root.find_child("BridgeSprite", true, false)
	var status_frame := root.find_child("StatusFrameOrnament", true, false)
	var extended_platform := root.find_child("MemoryStepA", true, false)
	var memory_seal := root.find_child("MemorySeal", true, false)
	var opening_banner := root.find_child("OpeningBanner", true, false)
	var message_panel := root.find_child("MessagePanel", true, false)

	if player == null:
		_fail("Player not found")
		return

	if resonance_system == null:
		_fail("ResonanceSystem not found")
		return

	if hud == null:
		_fail("PrototypeHUD not found")
		return

	if health_bar == null or health_label == null or stealth_label == null:
		_fail("health or stealth HUD not found")
		return

	if status_frame == null or status_frame.get("texture") == null:
		_fail("detailed status HUD frame not found")
		return

	if int(player.get("health")) != 3 or int(player.get("max_health")) != 3:
		_fail("player should start with three integrity points")
		return

	if int(player.get("collision_layer")) != 2 or int(player.get("collision_mask")) != 1:
		_fail("player collision layers should isolate enemy body contact")
		return

	hud.call("apply_tutorial_preference", false)
	if opening_banner == null or message_panel == null or opening_banner.visible or message_panel.visible:
		_fail("disabling tutorials should hide automatic gameplay guidance")
		return
	hud.call("apply_tutorial_preference", true)

	var crouch_key := InputEventKey.new()
	crouch_key.keycode = KEY_C
	crouch_key.pressed = true
	player.call("_input", crouch_key)
	if not bool(player.get("_stealth_key_held")):
		_fail("C key did not activate crouch input")
		return
	crouch_key.pressed = false
	player.call("_input", crouch_key)

	var shift_key := InputEventKey.new()
	shift_key.keycode = KEY_SHIFT
	shift_key.pressed = true
	player.call("_input", shift_key)
	if not bool(player.get("_stealth_key_held")):
		_fail("Shift key did not activate crouch input")
		return
	shift_key.pressed = false
	player.call("_input", shift_key)

	player.call("take_damage", 1, Vector2(player.global_position.x + 20.0, player.global_position.y))
	if int(player.get("health")) != 2:
		_fail("enemy damage should remove one integrity point")
		return
	if root.find_child("DeathOverlay", true, false).visible:
		_fail("single damage hit should not cause immediate failure")
		return
	player.call("restore_health")

	if receiver == null:
		_fail("ResonanceReceiver not found")
		return

	if gate == null:
		_fail("ResonanceGate not found")
		return

	if bridge == null:
		_fail("ResonanceBridge not found")
		return

	if completion_zone == null:
		_fail("CompletionZone not found")
		return

	if not completion_zone.is_in_group("interactable"):
		_fail("completion zone should be an interaction target")
		return

	if parallax_scene == null or sky_layer == null or mountain_layer == null or architecture_layer == null or midground_layer == null:
		_fail("complete parallax layer stack not found")
		return

	if failure_zone == null:
		_fail("FailureZone not found")
		return

	if enemy == null or enemy_animator == null or vision_area == null:
		_fail("corrupted patroller system not found")
		return

	var contact_area := enemy.find_child("ContactArea", true, false) as Area2D
	if int(enemy.get("collision_layer")) != 4 or int(enemy.get("collision_mask")) != 1:
		_fail("enemy body should collide with world but not physically block player")
		return
	if vision_area.collision_mask != 2 or contact_area == null or contact_area.collision_mask != 2:
		_fail("enemy sensing areas should detect the player collision layer")
		return

	for animation_name in ["idle", "walk", "alert", "crouch", "attack", "damage", "death", "respawn"]:
		if not enemy_animator.sprite_frames.has_animation(animation_name):
			_fail("missing enemy animation: %s" % animation_name)
			return
		if enemy_animator.sprite_frames.get_frame_count(animation_name) < 3:
			_fail("enemy animation has too few frames: %s" % animation_name)
			return

	if stealth_cover == null or not stealth_cover.is_in_group("stealth_cover"):
		_fail("stealth cover not found")
		return
	if int(stealth_cover.get("collision_layer")) != 0 or int(stealth_cover.get("collision_mask")) != 2:
		_fail("stealth cover cannot detect the player physics layer")
		return
	var cover_sprite := stealth_cover.find_child("CoverSprite", true, false) as Sprite2D
	if cover_sprite == null:
		_fail("stealth cover has no visual feedback sprite")
		return

	if lore_scar == null or not lore_scar.is_in_group("interactable"):
		_fail("lore scar interaction not found")
		return

	if dialogue_overlay == null:
		_fail("dialogue overlay not found")
		return

	if checkpoint_animator == null:
		_fail("animated checkpoint not found")
		return

	if source == null or checkpoint == null:
		_fail("source or checkpoint interaction not found")
		return

	if audio_manager == null:
		_fail("AudioManager not found")
		return

	if not bool(completion_zone.get("locked")):
		_fail("completion should start locked behind the stealth challenge")
		return

	stealth_cover.call("_on_body_entered", player)
	if not bool(player.get("_inside_stealth_cover")):
		_fail("stealth cover did not enable the player stealth area")
		return
	player.call("set_signature_hidden", true)
	if not bool(player.get("signature_hidden")):
		_fail("player could not hide the signature inside cover")
		return
	stealth_cover.call("_on_body_exited", player)
	if bool(player.get("signature_hidden")):
		_fail("player signature remained hidden outside cover")
		return

	var dialogue_lines: Array[String] = ["Linha de teste."]
	hud.call("show_dialogue", "Cicatriz", dialogue_lines)
	if not dialogue_overlay.visible or not paused:
		_fail("dialogue did not pause the room")
		return
	hud.call("advance_dialogue")
	if dialogue_overlay.visible or paused:
		_fail("dialogue did not close and resume the room")
		return

	if not enemy.has_method("set_player_hidden") or not enemy.has_method("receive_back_resonance"):
		_fail("enemy stealth interaction API not found")
		return

	enemy.call("set_player_hidden", true)
	if not bool(enemy.get("player_hidden")):
		_fail("enemy did not accept hidden player state")
		return

	enemy.call("set_player_hidden", false)
	var enemy_state_before: int = int(enemy.get("state"))
	enemy.call("force_alert", player)
	if int(enemy.get("state")) == enemy_state_before:
		_fail("enemy did not enter alert state")
		return

	enemy.call("set_player_hidden", true)
	player.call("set_signature_hidden", true)
	var purified: bool = enemy.call("receive_back_resonance", player)
	if not purified:
		_fail("enemy rejected valid rear resonance interaction")
		return

	if not bool(enemy.get("is_stunned")):
		_fail("enemy did not enter stunned state")
		return

	if bool(completion_zone.get("locked")):
		_fail("purifying the enemy did not unlock completion")
		return

	var camera := player.find_child("Camera2D", true, false) as Camera2D
	if camera == null:
		_fail("Camera2D not found")
		return

	if camera.zoom.x > 0.95 or camera.zoom.y > 0.95:
		_fail("camera field of view is still too narrow")
		return

	if camera.limit_left >= 0 or camera.limit_right <= 1200:
		_fail("camera limits do not cover the complete test field")
		return

	if camera.limit_right < 2500 or extended_platform == null:
		_fail("test field was not extended into a second traversal section")
		return

	var left_boundary := root.find_child("LeftBoundary", true, false) as StaticBody2D
	var floor := root.find_child("Floor", true, false) as StaticBody2D
	if left_boundary == null or floor == null:
		_fail("room boundaries or floor not found")
		return

	var floor_collision := floor.find_child("CollisionShape2D", true, false) as CollisionShape2D
	var left_collision := left_boundary.find_child("CollisionShape2D", true, false) as CollisionShape2D
	if floor_collision == null or left_collision == null:
		_fail("room boundary collisions not found")
		return

	var floor_shape := floor_collision.shape as RectangleShape2D
	var left_shape := left_collision.shape as RectangleShape2D
	var floor_left := floor.global_position.x - floor_shape.size.x * 0.5
	var wall_right := left_boundary.global_position.x + left_shape.size.x * 0.5
	if floor_left > wall_right + 2.0:
		_fail("floor leaves a fall gap before the left boundary")
		return
	var bridge_collision_for_alignment: CollisionShape2D = bridge.get("collision_shape")
	var bridge_shape := bridge_collision_for_alignment.shape as RectangleShape2D
	var bridge_surface_y: float = bridge_collision_for_alignment.global_position.y - bridge_shape.size.y * 0.5
	var floor_surface_y: float = floor_collision.global_position.y - floor_shape.size.y * 0.5
	if absf(bridge_surface_y - floor_surface_y) > 2.0:
		_fail("active resonance bridge creates a traversal wall instead of a level surface")
		return

	var upper_platform := root.find_child("UpperPlatform", true, false) as StaticBody2D
	var upper_visual := root.find_child("UpperPlatformSprite", true, false) as Sprite2D
	if upper_platform == null or upper_visual == null:
		_fail("upper platform visual or body not found")
		return

	var upper_collision := upper_platform.find_child("CollisionShape2D", true, false) as CollisionShape2D
	var upper_shape := upper_collision.shape as RectangleShape2D
	var upper_visual_width := upper_visual.texture.get_width() * upper_visual.scale.x
	if absf(upper_shape.size.x - upper_visual_width) > 12.0:
		_fail("upper platform collision does not match visible width")
		return
	var upper_visual_top := upper_visual.global_position.y - upper_visual.texture.get_height() * upper_visual.scale.y * 0.5
	var upper_collision_top := upper_collision.global_position.y - upper_shape.size.y * 0.5
	if absf(upper_visual_top - upper_collision_top) > 2.0:
		_fail("upper platform collision is not aligned to the visible top")
		return

	if player_animator == null:
		_fail("PlayerAnimator not found")
		return

	if player_animator.get("sprite_frames") == null:
		_fail("PlayerAnimator sprite frames not loaded")
		return

	var player_collision := player.find_child("CollisionShape2D", true, false) as CollisionShape2D
	var player_shape := player_collision.shape as RectangleShape2D
	var player_frame: Texture2D = player_animator.sprite_frames.get_frame_texture("run", 0)
	var player_used_rect := player_frame.get_image().get_used_rect()
	var visual_foot_y: float = player_animator.position.y + (float(player_used_rect.end.y) - float(player_frame.get_height()) * 0.5) * player_animator.scale.y
	var collider_foot_y: float = player_collision.position.y + player_shape.size.y * 0.5
	if absf(visual_foot_y - collider_foot_y) > 3.0:
		_fail("player visual feet do not match the physics baseline")
		return

	var enemy_collision := enemy.find_child("CollisionShape2D", false, false) as CollisionShape2D
	var enemy_shape := enemy_collision.shape as RectangleShape2D
	var enemy_frame: Texture2D = enemy_animator.sprite_frames.get_frame_texture("walk", 0)
	var enemy_used_rect := enemy_frame.get_image().get_used_rect()
	var enemy_foot_y: float = enemy_animator.position.y + (float(enemy_used_rect.end.y) - float(enemy_frame.get_height()) * 0.5) * enemy_animator.scale.y
	var enemy_collider_foot_y: float = enemy_collision.position.y + enemy_shape.size.y * 0.5
	if absf(enemy_foot_y - enemy_collider_foot_y) > 3.0:
		_fail("enemy visual feet do not match the physics baseline")
		return

	var expected_player_animations := {
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
	for animation_name in expected_player_animations:
		if not player_animator.sprite_frames.has_animation(animation_name):
			_fail("missing player animation: %s" % animation_name)
			return
		if player_animator.sprite_frames.get_frame_count(animation_name) != int(expected_player_animations[animation_name]):
			_fail("invalid player animation frame count: %s" % animation_name)
			return

	player.call("force_visual_state", "run")
	if player_animator.animation != "run":
		_fail("player did not switch to run visual state")
		return

	player.call("force_visual_state", "jump_rise")
	if player_animator.animation != "jump_rise":
		_fail("player did not switch to jump_rise visual state")
		return

	player.call("set_facing_direction", -1)
	if not player_animator.flip_h:
		_fail("player did not mirror when facing left")
		return
	player.call("set_facing_direction", 1)
	if player_animator.flip_h:
		_fail("player remained mirrored when facing right")
		return

	if source_sprite == null or source_sprite.get("texture") == null:
		_fail("SourceSprite texture not loaded")
		return

	var points_before_source: int = player.get("points")
	source.call("interact", player)
	source.call("interact", player)
	if int(player.get("points")) != points_before_source + 5:
		_fail("Exorigem source reward should be granted once")
		return

	var points_before_checkpoint: int = player.get("points")
	checkpoint.call("interact", player)
	checkpoint.call("interact", player)
	if int(player.get("points")) != points_before_checkpoint + 5:
		_fail("checkpoint reward should be granted once")
		return

	if not player.has_method("spend_points"):
		_fail("points have no spending API")
		return
	var points_before_spend: int = player.get("points")
	if not bool(player.call("spend_points", 20)) or int(player.get("points")) != points_before_spend - 20:
		_fail("points could not be spent on gameplay")
		return
	player.call("add_points", 20)

	if memory_seal == null or not memory_seal.is_in_group("interactable"):
		_fail("memory seal point sink not found")
		return

	var memory_fragments := get_nodes_in_group("memory_fragment")
	if memory_fragments.size() < 3:
		_fail("extended field should contain at least three memory fragments")
		return

	var sealed_platform := root.find_child("SealedPlatform", true, false) as StaticBody2D
	var sealed_collision := sealed_platform.find_child("CollisionShape2D", true, false) as CollisionShape2D
	var points_before_seal: int = player.get("points")
	memory_seal.call("interact", player)
	await process_frame
	if not bool(memory_seal.get("is_active")) or sealed_collision.disabled:
		_fail("memory seal did not materialize its optional platform")
		return
	if int(player.get("points")) != points_before_seal - 20:
		_fail("memory seal did not consume its advertised point cost")
		return

	if receiver_sprite == null or receiver_sprite.get("texture") == null:
		_fail("ReceiverSprite texture not loaded")
		return

	if gate_sprite == null or gate_sprite.get("texture") == null:
		_fail("GateSprite texture not loaded")
		return

	if hazard_sprite == null:
		_fail("HazardSprite visual not found")
		return

	if bridge_sprite == null or bridge_sprite.get("texture") == null:
		_fail("BridgeSprite texture not loaded")
		return

	var bridge_collision: CollisionShape2D = bridge.get("collision_shape")
	if bridge_collision == null:
		_fail("bridge collision shape not wired")
		return

	var hazard_collision: CollisionShape2D = failure_zone.get("collision_shape")
	if hazard_collision == null:
		_fail("hazard collision shape not wired")
		return

	if not bridge_collision.disabled:
		_fail("bridge should start inactive before resonance")
		return

	if hazard_collision.disabled:
		_fail("hazard should start active before resonance")
		return

	if bridge_sprite.modulate.a > 0.45:
		_fail("inactive bridge should read as spectral preview")
		return

	var player_speed: float = player.get("speed")
	var player_jump_velocity: float = player.get("jump_velocity")
	if player_speed < 200.0:
		_fail("player speed is too low for the prototype gap")
		return

	if player_jump_velocity > -420.0:
		_fail("player jump is too weak for prototype platforming")
		return

	var pause_overlay := root.find_child("PauseOverlay", true, false)
	var death_overlay := root.find_child("DeathOverlay", true, false)
	var resume_button := root.find_child("ResumeButton", true, false)
	var retry_button := root.find_child("RetryButton", true, false)
	var death_menu_button := root.find_child("DeathMenuButton", true, false)

	if pause_overlay == null:
		_fail("PauseOverlay not found")
		return

	if death_overlay == null:
		_fail("DeathOverlay not found")
		return

	if resume_button == null:
		_fail("ResumeButton not found")
		return

	if retry_button == null:
		_fail("RetryButton not found")
		return

	if death_menu_button == null:
		_fail("DeathMenuButton not found")
		return

	if receiver.global_position.x >= failure_zone.global_position.x:
		_fail("resonance receiver should be before the failure zone")
		return

	if player.process_mode != Node.PROCESS_MODE_PAUSABLE:
		_fail("player should pause behind death overlay")
		return

	if resonance_system.process_mode != Node.PROCESS_MODE_PAUSABLE:
		_fail("resonance system should pause behind death overlay")
		return

	if hud.process_mode != Node.PROCESS_MODE_ALWAYS:
		_fail("HUD should remain active while paused")
		return

	var receiver_label: String = receiver.call("get_interaction_label")
	if receiver_label.is_empty():
		_fail("receiver has no resonance prompt label")
		return

	var interaction_area := player.find_child("InteractionArea", true, false)
	var interaction_collision: CollisionShape2D = interaction_area.find_child("CollisionShape2D", true, false)
	var interaction_shape: CircleShape2D = interaction_collision.shape
	if interaction_shape.radius < 130.0:
		_fail("interaction radius is too small for prototype usability")
		return
	if (int(interaction_area.get("collision_mask")) & 4) == 0:
		_fail("player interaction area cannot discover enemy resonance targets")
		return

	hud.call("show_pause_menu")
	if not pause_overlay.visible:
		_fail("pause overlay did not open")
		return

	hud.call("hide_pause_menu")
	if pause_overlay.visible:
		_fail("pause overlay did not close")
		return

	var initial_points: int = player.get("points")
	var failure_position := Vector2(500, 360)
	player.set("global_position", failure_position)
	player.call("register_failure")
	var points_after_failure: int = player.get("points")
	if points_after_failure >= initial_points:
		_fail("failure did not reduce points")
		return

	var player_position_after_failure: Vector2 = player.get("global_position")
	var checkpoint_position: Vector2 = player.get("checkpoint_position")
	if not player_position_after_failure.is_equal_approx(failure_position):
		_fail("failure should freeze player at failure position before retry")
		return

	if not death_overlay.visible:
		_fail("death overlay did not open after failure")
		return

	if player_animator.animation != "death":
		_fail("player did not switch to death visual state after failure")
		return

	if not paused:
		_fail("tree should pause after player failure")
		return

	retry_button.pressed.emit()
	if death_overlay.visible:
		_fail("death overlay did not close after retry")
		return

	var player_position_after_retry: Vector2 = player.get("global_position")
	if not player_position_after_retry.is_equal_approx(checkpoint_position):
		_fail("retry did not reset player to checkpoint")
		return

	if player_animator.animation != "respawn":
		_fail("player did not switch to respawn visual state after retry")
		return

	if paused:
		_fail("tree should resume after retry")
		return

	var activated: bool = resonance_system.call("try_activate", receiver, player)
	if not activated:
		_fail("resonance system rejected valid receiver")
		return

	if player_animator.animation != "resonance":
		_fail("player did not switch to resonance visual state after activation")
		return

	var cooldown_remaining: float = resonance_system.get("cooldown_remaining")
	if cooldown_remaining <= 0.0:
		_fail("resonance system did not start cooldown")
		return

	var gate_collision: CollisionShape2D = gate.get("collision_shape")
	if gate_collision == null or not gate_collision.disabled:
		_fail("gate collision did not disable after resonance")
		return

	if bridge_collision.disabled:
		_fail("bridge did not become solid after resonance")
		return

	for _frame in range(32):
		await process_frame

	if bridge_sprite.modulate.a < 0.95:
		_fail("bridge did not become visibly active after resonance")
		return

	if not hazard_collision.disabled:
		_fail("hazard lake did not neutralize after resonance")
		return

	var completion_label: String = completion_zone.call("get_interaction_label")
	if completion_label.is_empty():
		_fail("completion zone has no interaction prompt")
		return

	completion_zone.call("interact", player)
	var is_completed: bool = completion_zone.get("is_completed")
	if not is_completed:
		_fail("completion zone did not complete when interacted with")
		return

	var save_system := root.get_node_or_null("SaveSystem")
	if save_system == null:
		_fail("SaveSystem autoload not found")
		return

	save_system.call("mark_test_field_complete", player.get("points"))
	var save_data: Dictionary = save_system.call("get_data")
	if not bool(save_data.get("test_field_complete", false)):
		_fail("save system did not persist challenge completion state")
		return
	var save_path: String = save_system.call("get_save_path")
	if not FileAccess.file_exists(save_path):
		_fail("save file was not created on disk: %s" % save_path)
		return


func _fail(reason: String) -> void:
	_failed = true
	push_error("Smoke test failed: %s" % reason)
	quit(1)
