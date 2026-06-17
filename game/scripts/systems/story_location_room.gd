extends "res://scripts/systems/test_room.gd"
class_name StoryLocationRoom

const TransitionZoneScene := preload("res://scenes/systems/TransitionZone.tscn")
const StoryPuzzleNodeScript := preload("res://scripts/systems/story_puzzle_node.gd")
const StoryPuzzleControllerScript := preload("res://scripts/systems/story_puzzle_controller.gd")
const ENEMY_SCENES := {
	"ancestral_abomination": preload("res://scenes/enemies/AncestralAbomination.tscn"),
	"unstable_energy": preload("res://scenes/enemies/UnstableEnergy.tscn"),
	"mystic_sentinel": preload("res://scenes/enemies/MysticSentinel.tscn"),
	"fallen_shadow": preload("res://scenes/enemies/FallenShadow.tscn"),
}

@export var location_id: StringName = &"awakening"

var location_profile: Dictionary = {}
var layout_profile: Dictionary = {}
var story_exit: TransitionZoneMarker
var _regional_lore_observed := false
var _regional_enemy_cleared := false
var _regional_puzzle_solved := false
var _story_puzzle_gate: ResonanceGate


func _ready() -> void:
	super._ready()
	name = String(location_id).to_pascal_case()
	_load_location_profile()
	_load_layout_profile()
	if location_profile.is_empty() or layout_profile.is_empty():
		return
	_remove_test_only_content()
	_create_story_layout()
	_apply_location_identity()
	_create_regional_lore()
	_create_regional_collectible()
	_create_regional_enemy()
	_create_story_transitions()
	_update_story_exit_lock()
	_schedule_intro_dialogue()
	_record_location_visit()


func _load_location_profile() -> void:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		push_warning("Story location could not access DataRegistry")
		return
	var levels: Dictionary = registry.get_section(&"levels")
	location_profile = levels.get("story_locations", {}).get(String(location_id), {})
	if location_profile.is_empty():
		push_warning("Story location profile not found: %s" % location_id)


func _load_layout_profile() -> void:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		return
	var layout_data: Dictionary = registry.get_section(&"layouts")
	layout_profile = layout_data.get("layouts", {}).get(String(location_id), {})
	if layout_profile.is_empty():
		push_warning("Story layout profile not found: %s" % location_id)


func _remove_test_only_content() -> void:
	if corrupted_patroller != null and is_instance_valid(corrupted_patroller):
		corrupted_patroller.queue_free()
	if completion_zone != null and is_instance_valid(completion_zone):
		completion_zone.queue_free()

	for node in find_children("LoreScar*", "", true, false):
		node.queue_free()
	for node in find_children("MemoryFragment*", "", true, false):
		node.queue_free()
	for node_name in [
		"UpperPlatform",
		"LookoutPlatform",
		"MemoryStepA",
		"MemoryStepB",
		"RuinsPlatform",
		"SealedPlatform",
		"ExorigemSource",
		"ResonanceReceiver",
		"ResonanceGate",
		"ResonanceBridge",
		"FailureZone",
		"MemorySeal",
		"StealthCover",
	]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.queue_free()


func _create_story_layout() -> void:
	var layout_root := Node2D.new()
	layout_root.name = "StoryLayout"
	layout_root.set_meta(
		"layout_signature",
		"%s:%s" % [
			String(layout_profile.get("layout_id", location_id)),
			String(layout_profile.get("challenge_id", "challenge")),
		]
	)
	layout_root.set_meta("pace", String(layout_profile.get("pace", "exploration")))
	add_child(layout_root)

	var spawn := _vector_from_data(layout_profile.get("spawn", [170, 410]))
	player.global_position = spawn
	player.set_checkpoint(spawn)
	var checkpoint := get_node_or_null("MemoryCheckpoint")
	if checkpoint != null:
		checkpoint.position = Vector2(spawn.x, 402)

	var platform_index := 0
	for platform_data in layout_profile.get("platforms", []):
		var data: Array = platform_data
		if data.size() < 4:
			continue
		var skin := String(data[3])
		var texture_path := (
			"res://assets/sprites/tilesets/scenario/platform_stone_bridge.png"
			if skin == "stone"
			else "res://assets/sprites/tilesets/scenario/platform_floating_grass.png"
		)
		var platform := _create_platform(
			"StoryPlatform%02d" % platform_index,
			Vector2(float(data[0]), float(data[1])),
			float(data[2]),
			texture_path,
			"StoryPlatformSprite%02d" % platform_index
		)
		platform.reparent(layout_root, true)
		platform_index += 1

	for hazard_index in layout_profile.get("hazards", []).size():
		var hazard_data: Array = layout_profile.get("hazards", [])[hazard_index]
		var hazard := _create_hazard(
			Vector2(float(hazard_data[0]), float(hazard_data[1])),
			Vector2(float(hazard_data[2]), 38.0)
		)
		hazard.name = "StoryHazard%02d" % hazard_index
		hazard.add_to_group("story_hazard")
		hazard.reparent(layout_root, true)

	var puzzle_controller := StoryPuzzleControllerScript.new() as StoryPuzzleController
	puzzle_controller.name = "StoryPuzzleController"
	puzzle_controller.configure(
		StringName(layout_profile.get("challenge_id", "challenge")),
		String(layout_profile.get("puzzle_mode", "all")),
		hud
	)
	puzzle_controller.solved.connect(_on_story_puzzle_solved)
	puzzle_controller.progress_changed.connect(_on_story_puzzle_progress)
	add_child(puzzle_controller)

	var node_index := 0
	for node_data in layout_profile.get("nodes", []):
		var data: Array = node_data
		if data.size() < 3:
			continue
		var puzzle_node := _create_story_puzzle_node(
			StringName(data[0]),
			Vector2(float(data[1]), float(data[2]))
		)
		puzzle_node.name = "PuzzleNode%02d" % node_index
		puzzle_node.reparent(layout_root, true)
		puzzle_controller.register_node(puzzle_node)
		node_index += 1

	_story_puzzle_gate = _create_gate(Vector2(2450, 392), Vector2(52, 92))
	_story_puzzle_gate.name = "StoryPuzzleGate"
	_story_puzzle_gate.reparent(layout_root, true)
	puzzle_controller.start()


func _create_story_puzzle_node(node_id: StringName, position: Vector2) -> StoryPuzzleNode:
	var puzzle_node := StoryPuzzleNodeScript.new() as StoryPuzzleNode
	puzzle_node.node_id = node_id
	puzzle_node.position = position
	puzzle_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(puzzle_node)

	var shape := CircleShape2D.new()
	shape.radius = 88.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	puzzle_node.add_child(collision)

	var visual := Sprite2D.new()
	visual.name = "PuzzleNodeVisual"
	visual.texture = load("res://assets/sprites/interactables/resonance_receiver_relic.png")
	visual.position = Vector2(0, -42)
	visual.scale = Vector2(0.76, 0.76)
	puzzle_node.visual = visual
	puzzle_node.add_child(visual)
	puzzle_node.call("_update_visual")
	return puzzle_node


func _apply_location_identity() -> void:
	var display_name := String(location_profile.get("name", location_id))
	var region := String(location_profile.get("region", "awakening"))
	var tint_hex := String(location_profile.get("tint", "6c8f91"))
	var tint := Color.from_string(tint_hex, Color(0.42, 0.56, 0.57))

	var background_fill := get_node_or_null("BackgroundFill") as Polygon2D
	if background_fill != null:
		background_fill.color = tint.darkened(0.22)

	hud.set_opening_text("%s\n%s" % [display_name.to_upper(), _region_subtitle(region)])
	_create_location_title(display_name, region)
	_add_region_environment(region, tint)


func _create_location_title(display_name: String, region: String) -> void:
	var layer := CanvasLayer.new()
	layer.name = "LocationPresentation"
	layer.layer = 8
	add_child(layer)

	var presentation := Control.new()
	presentation.name = "LocationPresentationContent"
	presentation.anchor_right = 1.0
	presentation.anchor_bottom = 1.0
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(presentation)

	var title := Label.new()
	title.name = "LocationTitle"
	title.text = display_name.to_upper()
	title.position = Vector2(38, 650)
	title.size = Vector2(720, 42)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.92, 0.80, 0.50, 0.92))
	title.theme = load("res://assets/ui/themes/kenosis_theme.tres")
	presentation.add_child(title)

	var region_label := Label.new()
	region_label.name = "RegionLabel"
	region_label.text = _region_subtitle(region)
	region_label.position = Vector2(40, 684)
	region_label.size = Vector2(720, 28)
	region_label.add_theme_font_size_override("font_size", 12)
	region_label.add_theme_color_override("font_color", Color(0.68, 0.82, 0.80, 0.86))
	region_label.theme = title.theme
	presentation.add_child(region_label)

	var tween := create_tween()
	tween.tween_interval(2.8)
	tween.tween_property(presentation, "modulate:a", 0.0, 0.8)


func _add_region_environment(region: String, tint: Color) -> void:
	var parallax_scene := get_node_or_null("ParallaxScene") as Node2D
	if parallax_scene == null:
		return
	var layer := _create_parallax_layer(parallax_scene, "StoryRegionLayer", 0.31, -64)
	var texture_path := "res://assets/sprites/backgrounds/expansion/distant_towers.png"
	var target_height := 210.0
	match region:
		"fall":
			texture_path = "res://assets/sprites/backgrounds/expansion/midground_ruins.png"
			target_height = 145.0
		"forge":
			texture_path = "res://assets/sprites/backgrounds/expansion/night_machines.png"
			target_height = 205.0
		"abyss":
			texture_path = "res://assets/sprites/backgrounds/expansion/night_mountains.png"
			target_height = 165.0
		"void":
			texture_path = "res://assets/sprites/backgrounds/expansion/foreground_shadows.png"
			target_height = 90.0

	for x_position in [520.0, 1420.0, 2320.0]:
		_create_parallax_sprite(
			layer,
			texture_path,
			Vector2(x_position, 385),
			target_height,
			Color(tint.r, tint.g, tint.b, 0.42)
		)


func _create_regional_lore() -> void:
	var lore_key := StringName(location_profile.get("lore", ""))
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null or lore_key.is_empty():
		return
	var lore_data: Dictionary = registry.get_section(&"lore")
	var memory: Dictionary = lore_data.get("memories", {}).get(String(lore_key), {})
	if memory.is_empty():
		return

	var lines: Array[String] = []
	for line in memory.get("lines", []):
		lines.append(String(line))
	var lore_scar := _create_lore_scar(
		_vector_from_data(layout_profile.get("lore_position", [1740, 410])),
		String(memory.get("title", "Cicatriz")),
		lines
	)
	lore_scar.name = "RegionalLoreScar"
	lore_scar.lore_id = lore_key
	var save_system := get_node_or_null("/root/SaveSystem")
	_regional_lore_observed = save_system != null and save_system.is_lore_observed(lore_key)
	lore_scar.lore_requested.connect(func(_title: String, _lines: Array[String]) -> void:
		_regional_lore_observed = true
		_update_story_exit_lock()
	)


func _create_regional_collectible() -> void:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		return
	var collectibles_data: Dictionary = registry.get_section(&"collectibles")
	for collectible in collectibles_data.get("collectibles", []):
		if String(collectible.get("level", "")) != String(location_id):
			continue
		var fragment := _create_memory_fragment(
			"RegionalCollectible",
			_vector_from_data(layout_profile.get("collectible_position", [2240, 350]))
		) as MemoryFragment
		fragment.item_id = StringName(collectible.get("id", ""))
		fragment.reward = int(collectible.get("reward", 10))
		fragment.refresh_persistence()
		return


func _create_regional_enemy() -> void:
	var enemy_id := String(location_profile.get("enemy", ""))
	if enemy_id.is_empty() or not ENEMY_SCENES.has(enemy_id):
		_regional_enemy_cleared = true
		return
	var packed: PackedScene = ENEMY_SCENES[enemy_id]
	var enemy := packed.instantiate() as ExpansionEnemy
	enemy.name = "RegionalEnemy"
	enemy.position = _vector_from_data(
		layout_profile.get("enemy_position", [2080, 407 if not enemy.floating else 345])
	)
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.configure_target(player)
	enemy.defeated.connect(func(_id: StringName, reward: int) -> void:
		_regional_enemy_cleared = true
		_update_story_exit_lock()
		hud.show_message("Caminho estabilizado. +%d memorias." % reward)
		_audio_sfx("confirm")
	)
	add_child(enemy)


func _create_story_transitions() -> void:
	var next_location := StringName(location_profile.get("next", ""))
	var previous_location := StringName(location_profile.get("previous", ""))
	if not next_location.is_empty():
		story_exit = _create_transition(
			"StoryExit",
			Vector2(2550, 390),
			next_location,
			"E: seguir para %s" % _location_name(next_location)
		)
	else:
		_create_final_exit()

	if not previous_location.is_empty():
		_create_transition(
			"StoryReturn",
			Vector2(-105, 390),
			previous_location,
			"E: retornar para %s" % _location_name(previous_location)
		)


func _create_transition(node_name: String, position: Vector2, target_id: StringName, label: String) -> TransitionZoneMarker:
	var transition := TransitionZoneScene.instantiate() as TransitionZoneMarker
	transition.name = node_name
	transition.position = position
	transition.target_location = target_id
	transition.interaction_label = label
	transition.transition_blocked.connect(func(message: String) -> void:
		hud.show_message(message)
		_audio_sfx("error")
	)
	add_child(transition)
	transition.add_child(_transition_visual())
	return transition


func _create_final_exit() -> void:
	var transition := TransitionZoneScene.instantiate() as TransitionZoneMarker
	transition.name = "StoryExit"
	transition.position = Vector2(2550, 390)
	transition.interaction_label = "E: concluir a memoria"
	story_exit = transition
	transition.transition_blocked.connect(func(message: String) -> void:
		hud.show_message(message)
		_audio_sfx("error")
	)
	transition.transition_requested.connect(func(_scene: String, _spawn: StringName) -> void:
		hud.show_completion(player.points)
	)
	add_child(transition)
	transition.add_child(_transition_visual())


func _update_story_exit_lock() -> void:
	if story_exit == null:
		return
	story_exit.set_locked(
		not (_regional_lore_observed and _regional_enemy_cleared and _regional_puzzle_solved)
	)
	if story_exit.locked:
		story_exit.locked_message = "Observe a cicatriz, resolva a Ressonancia e estabilize a ameaca."
	else:
		hud.show_message("A passagem para a proxima memoria foi estabilizada.")


func _on_story_puzzle_progress(current: int, total: int) -> void:
	if total <= 0 or current >= total:
		return
	hud.show_message("Ressonancia do local: %d / %d" % [current, total])


func _on_story_puzzle_solved() -> void:
	_regional_puzzle_solved = true
	if _story_puzzle_gate != null:
		_story_puzzle_gate.open_gate()
	for hazard in get_tree().get_nodes_in_group("story_hazard"):
		if is_ancestor_of(hazard) and hazard.has_method("neutralize"):
			hazard.neutralize()
	hud.show_message("O padrao de Ressonancia foi estabilizado.")
	_audio_sfx("checkpoint")
	_update_story_exit_lock()


func _transition_visual() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/ui/reference/checkpoint_complete.png")
	sprite.position = Vector2(0, -34)
	sprite.scale = Vector2(0.62, 0.62)
	sprite.modulate = Color(0.75, 1.0, 0.96, 0.94)
	return sprite


func _schedule_intro_dialogue() -> void:
	var dialogue_id := StringName(location_profile.get("dialogue", ""))
	if dialogue_id.is_empty():
		return
	var timer := Timer.new()
	timer.name = "IntroDialogueTimer"
	timer.wait_time = 0.75
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(func() -> void:
		if is_inside_tree() and not get_tree().paused:
			var presentation := get_node_or_null("LocationPresentation/LocationPresentationContent")
			if presentation != null:
				presentation.visible = false
			hud.show_dialogue_id(dialogue_id)
	)
	add_child(timer)
	timer.start()


func _record_location_visit() -> void:
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.set_current_location(location_id)


func _location_name(target_id: StringName) -> String:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		return String(target_id)
	var levels: Dictionary = registry.get_section(&"levels")
	var profile: Dictionary = levels.get("story_locations", {}).get(String(target_id), {})
	return String(profile.get("name", target_id))


func _region_subtitle(region: String) -> String:
	match region:
		"awakening":
			return "REGIAO I - DESPERTAR"
		"fall":
			return "REGIAO II - RUINAS DA QUEDA"
		"forge":
			return "REGIAO III - FORJA DA CORRUPCAO"
		"abyss":
			return "REGIAO IV - ABISMO DA RESSONANCIA"
		"void":
			return "REGIAO V - CORACAO DO VAZIO"
	return "MEMORIA NAO CATALOGADA"


func _vector_from_data(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
