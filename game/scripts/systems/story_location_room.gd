extends "res://scripts/systems/test_room.gd"
class_name StoryLocationRoom

const TransitionZoneScene := preload("res://scenes/systems/TransitionZone.tscn")
const StoryPuzzleNodeScript := preload("res://scripts/systems/story_puzzle_node.gd")
const StoryPuzzleControllerScript := preload("res://scripts/systems/story_puzzle_controller.gd")
const MapNavigatorScript := preload("res://scripts/systems/map_navigator.gd")
const ENEMY_SCENES := {
	"ancestral_abomination": preload("res://scenes/enemies/AncestralAbomination.tscn"),
	"unstable_energy": preload("res://scenes/enemies/UnstableEnergy.tscn"),
	"mystic_sentinel": preload("res://scenes/enemies/MysticSentinel.tscn"),
	"fallen_shadow": preload("res://scenes/enemies/FallenShadow.tscn"),
}
const AWAKENING_ASSET_ROOT := "res://assets/sprites/backgrounds/locations/awakening/"

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
	_add_location_set_dressing()
	_create_regional_lore()
	_create_regional_collectible()
	_create_story_map_access_pickup()
	_create_regional_enemy()
	_create_story_transitions()
	_create_story_map_navigator()
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


func _add_location_set_dressing() -> void:
	match String(location_id):
		"awakening":
			_add_awakening_set_dressing()


func _add_awakening_set_dressing() -> void:
	var background_fill := get_node_or_null("BackgroundFill") as Polygon2D
	if background_fill != null:
		background_fill.color = Color(0.13, 0.29, 0.32, 1.0)

	var parallax_scene := get_node_or_null("ParallaxScene") as Node2D
	if parallax_scene != null:
		_add_awakening_parallax(parallax_scene)

	_add_awakening_ground_composition()
	_set_awakening_scene_notes()


func _add_awakening_parallax(parallax_scene: Node2D) -> void:
	var sky_layer := _create_parallax_layer(parallax_scene, "AwakeningSkyDistant", 0.0, -128)
	for x_position in [520.0, 1940.0]:
		_create_parallax_sprite(
			sky_layer,
			_awakening_asset("01_sky_distant/sky_parallax_strip_01.png"),
			Vector2(x_position, 165),
			260.0,
			Color(0.82, 0.96, 0.96, 0.58)
		)

	var cloud_layer := _create_parallax_layer(parallax_scene, "AwakeningCloudMemory", 0.04, -118)
	var cloud_specs := [
		["01_sky_distant/cloud_cluster_01.png", Vector2(270, 92), 88.0, 0.28],
		["01_sky_distant/cloud_cluster_02.png", Vector2(930, 130), 72.0, 0.22],
		["01_sky_distant/cloud_cluster_03.png", Vector2(1610, 80), 52.0, 0.20],
		["01_sky_distant/cloud_cluster_04.png", Vector2(2290, 145), 44.0, 0.18],
	]
	for spec in cloud_specs:
		_create_parallax_sprite(
			cloud_layer,
			_awakening_asset(String(spec[0])),
			spec[1],
			float(spec[2]),
			Color(0.86, 0.98, 0.97, float(spec[3]))
		)

	var mountain_layer := _create_parallax_layer(parallax_scene, "AwakeningMountainVeil", 0.10, -108)
	for x_position in [360.0, 1100.0, 1880.0, 2600.0]:
		_create_parallax_sprite(
			mountain_layer,
			_awakening_asset("01_sky_distant/mountain_range_strip_02.png"),
			Vector2(x_position, 330),
			78.0,
			Color(0.51, 0.72, 0.70, 0.34)
		)

	var distant_architecture := _create_parallax_layer(parallax_scene, "AwakeningDistantRuinLine", 0.20, -98)
	for spec in [
		["02_distant_architecture/distant_architecture_strip_02.png", 510.0, 188.0],
		["02_distant_architecture/distant_architecture_strip_04.png", 1750.0, 176.0],
		["02_distant_architecture/distant_architecture_strip_01.png", 2600.0, 150.0],
	]:
		_create_parallax_sprite(
			distant_architecture,
			_awakening_asset(String(spec[0])),
			Vector2(float(spec[1]), 382),
			float(spec[2]),
			Color(0.38, 0.54, 0.50, 0.34)
		)

	var forest_layer := _create_parallax_layer(parallax_scene, "AwakeningForestEdge", 0.34, -82)
	for spec in [
		["04_midground_nature/forest_edge_strip_01.png", 260.0, 175.0],
		["04_midground_nature/forest_edge_strip_03.png", 780.0, 155.0],
		["04_midground_nature/forest_edge_strip_02.png", 1480.0, 185.0],
		["04_midground_nature/forest_edge_strip_04.png", 2180.0, 165.0],
		["04_midground_nature/forest_edge_strip_01.png", 2760.0, 155.0],
	]:
		_create_parallax_sprite(
			forest_layer,
			_awakening_asset(String(spec[0])),
			Vector2(float(spec[1]), 414),
			float(spec[2]),
			Color(0.37, 0.58, 0.45, 0.52)
		)

	var shrine_layer := _create_parallax_layer(parallax_scene, "AwakeningShrineMemory", 0.48, -58)
	for spec in [
		["03_midground_ruins/arch_ruin_03.png", 650.0, 206.0, 0.58],
		["03_midground_ruins/sanctuary_ruin_cluster_03.png", 1270.0, 188.0, 0.62],
		["03_midground_ruins/arch_ruin_02.png", 2030.0, 220.0, 0.55],
		["03_midground_ruins/standing_stone_05.png", 2420.0, 170.0, 0.45],
	]:
		_create_parallax_sprite(
			shrine_layer,
			_awakening_asset(String(spec[0])),
			Vector2(float(spec[1]), 393),
			float(spec[2]),
			Color(0.54, 0.67, 0.57, float(spec[3]))
		)

	var haze_layer := _create_parallax_layer(parallax_scene, "AwakeningLowHaze", 0.70, -36)
	for spec in [
		["01_sky_distant/mist_haze_strip_01.png", 420.0, 70.0],
		["01_sky_distant/mist_haze_strip_03.png", 1120.0, 78.0],
		["01_sky_distant/mist_haze_strip_05.png", 1850.0, 82.0],
		["01_sky_distant/mist_haze_strip_04.png", 2450.0, 68.0],
	]:
		_create_parallax_sprite(
			haze_layer,
			_awakening_asset(String(spec[0])),
			Vector2(float(spec[1]), 430),
			float(spec[2]),
			Color(0.66, 0.94, 0.88, 0.22)
		)


func _add_awakening_ground_composition() -> void:
	var dressing := Node2D.new()
	dressing.name = "AwakeningSetDressing"
	dressing.set_meta("scene_role", "historia_01_clareira_do_despertar")
	dressing.set_meta("level_design_note", "Tutorial contemplativo: acordar, ler a cicatriz, alinhar a primeira Ressonancia e estabilizar a passagem.")
	add_child(dressing)

	var back_props := [
		["TreeFrameLeft", "04_midground_nature/tree_medium_02.png", Vector2(45, GROUND_SURFACE_Y), 238.0, -18, Color(0.46, 0.68, 0.50, 0.64)],
		["TreeFrameCenter", "04_midground_nature/tree_medium_01.png", Vector2(1360, GROUND_SURFACE_Y), 214.0, -17, Color(0.44, 0.64, 0.48, 0.56)],
		["TreeFrameRight", "04_midground_nature/tree_medium_03.png", Vector2(2675, GROUND_SURFACE_Y), 252.0, -18, Color(0.42, 0.62, 0.46, 0.64)],
		["RuinGateLeft", "03_midground_ruins/standing_stone_01.png", Vector2(365, GROUND_SURFACE_Y), 118.0, -13, Color(0.72, 0.78, 0.66, 0.86)],
		["RuinGateRight", "03_midground_ruins/standing_stone_02.png", Vector2(525, GROUND_SURFACE_Y), 112.0, -13, Color(0.72, 0.78, 0.66, 0.86)],
		["MemoryAltar", "03_midground_ruins/resonance_altar_01.png", Vector2(1120, GROUND_SURFACE_Y), 96.0, -11, Color(0.72, 0.93, 0.88, 0.94)],
		["ExitStandingStone", "03_midground_ruins/standing_stone_05.png", Vector2(2510, GROUND_SURFACE_Y), 138.0, -13, Color(0.65, 0.82, 0.74, 0.72)],
	]
	for spec in back_props:
		var prop := _create_grounded_prop(
			String(spec[0]),
			spec[2],
			float(spec[3]),
			_awakening_asset(String(spec[1])),
			int(spec[4]),
			spec[5]
		)
		prop.reparent(dressing, true)

	var foreground_props := [
		["RootLeft", "05_foreground/root_log_cluster_02.png", Vector2(235, GROUND_SURFACE_Y + 7), 58.0, -3, Color(0.82, 0.88, 0.72, 0.88)],
		["RootBridge", "05_foreground/root_log_cluster_04.png", Vector2(760, GROUND_SURFACE_Y + 8), 47.0, -3, Color(0.76, 0.82, 0.66, 0.78)],
		["StoneNestLore", "05_foreground/rock_cluster_08.png", Vector2(1475, GROUND_SURFACE_Y + 3), 62.0, -4, Color(0.78, 0.84, 0.76, 0.82)],
		["OldLogEnemyCue", "05_foreground/stump_or_log_01.png", Vector2(2095, GROUND_SURFACE_Y + 4), 70.0, -4, Color(0.76, 0.84, 0.70, 0.82)],
		["ExitRoots", "05_foreground/root_log_cluster_05.png", Vector2(2460, GROUND_SURFACE_Y + 9), 52.0, -3, Color(0.72, 0.82, 0.70, 0.76)],
	]
	for spec in foreground_props:
		var prop := _create_grounded_prop(
			String(spec[0]),
			spec[2],
			float(spec[3]),
			_awakening_asset(String(spec[1])),
			int(spec[4]),
			spec[5]
		)
		prop.reparent(dressing, true)

	for index in range(10):
		var grass := _create_grounded_prop(
			"AwakeningGrass%02d" % index,
			Vector2(160.0 + float(index) * 260.0, GROUND_SURFACE_Y + 2.0),
			28.0 + float(index % 3) * 4.0,
			_awakening_asset("06_atmosphere/grass_tuft_%02d.png" % (index + 1)),
			-2,
			Color(0.75, 0.96, 0.70, 0.82)
		)
		grass.reparent(dressing, true)

	for index in range(6):
		var flower := _create_grounded_prop(
			"AwakeningFlower%02d" % index,
			Vector2(510.0 + float(index) * 315.0, GROUND_SURFACE_Y + 4.0),
			24.0,
			_awakening_asset("06_atmosphere/flower_patch_%02d.png" % (index + 1)),
			-1,
			Color(0.92, 0.82, 0.58, 0.70)
		)
		flower.reparent(dressing, true)

	var light_layer := Node2D.new()
	light_layer.name = "AwakeningLightRays"
	light_layer.z_index = 28
	dressing.add_child(light_layer)
	for spec in [
		["06_atmosphere/light_ray_01.png", Vector2(620, 250), 160.0, 0.18],
		["06_atmosphere/light_ray_05.png", Vector2(1220, 220), 180.0, 0.15],
		["06_atmosphere/light_ray_08.png", Vector2(1920, 240), 150.0, 0.13],
	]:
		var ray := _make_scaled_sprite(
			"AwakeningRay",
			_awakening_asset(String(spec[0])),
			Vector2(float(spec[2]), float(spec[2])),
			Color(0.92, 1.0, 0.82, float(spec[3]))
		)
		ray.position = spec[1]
		light_layer.add_child(ray)

	var story_layout := get_node_or_null("StoryLayout") as Node2D
	if story_layout != null:
		story_layout.set_meta("art_pass", "clareira_do_despertar_assets_v1")


func _set_awakening_scene_notes() -> void:
	var story_layout := get_node_or_null("StoryLayout") as Node2D
	if story_layout == null:
		return
	story_layout.set_meta("beat_01", "O Escriba desperta protegido por arvores e pedras de memoria.")
	story_layout.set_meta("beat_02", "A ruina central enquadra o primeiro no de Ressonancia.")
	story_layout.set_meta("beat_03", "A saida fica visualmente mais clara depois da cicatriz, puzzle e sentinela.")


func _awakening_asset(relative_path: String) -> String:
	return "%s%s" % [AWAKENING_ASSET_ROOT, relative_path]


func _make_scaled_sprite(node_name: String, texture_path: String, target_size: Vector2, tint: Color) -> Sprite2D:
	var texture: Texture2D = load(texture_path)
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.modulate = tint
	if texture != null:
		var texture_size := texture.get_size()
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			var uniform_scale := minf(target_size.x / texture_size.x, target_size.y / texture_size.y)
			sprite.scale = Vector2(uniform_scale, uniform_scale)
	return sprite


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


func _create_story_map_access_pickup() -> void:
	if String(location_id) != "awakening":
		return
	var pickup := _create_map_access_pickup("MapAccessPickup", _vector_from_data(layout_profile.get("map_access_position", [520, 330])))
	pickup.set("interaction_text", "E: recolher lente cartografica")


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


func _create_story_map_navigator() -> void:
	var navigator := MapNavigatorScript.new() as MapNavigator
	navigator.name = "MapNavigator"
	navigator.player = player
	var region := String(location_profile.get("region", "awakening"))
	navigator.register_destination(
		location_id,
		String(location_profile.get("name", location_id)),
		player.global_position,
		false,
		region
	)
	add_child(navigator)

	var pickup := get_node_or_null("MapAccessPickup")
	if pickup != null:
		pickup.connect("collected", Callable(navigator, "refresh_map_access"))


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
