extends SceneTree

const MAP_ROOM_PATH := "res://scenes/levels/MapTestRoom.tscn"

const ENEMY_SCENES := [
	"res://scenes/enemies/AncestralAbomination.tscn",
	"res://scenes/enemies/UnstableEnergy.tscn",
	"res://scenes/enemies/MysticSentinel.tscn",
	"res://scenes/enemies/FallenShadow.tscn",
]

const DATA_FILES := [
	"res://data/lore/lore_texts.json",
	"res://data/dialogue/dialogue.json",
	"res://data/config/items.json",
	"res://data/config/levels.json",
	"res://data/config/input_config.json",
	"res://data/config/balance.json",
	"res://data/collectibles/collectibles.json",
]

const SHADERS := [
	"res://shaders/glow.gdshader",
	"res://shaders/distortion.gdshader",
	"res://shaders/dissolve.gdshader",
	"res://shaders/outline.gdshader",
	"res://shaders/fog.gdshader",
	"res://shaders/parallax_material.gdshader",
	"res://shaders/pixel_snap.gdshader",
]

const MARKER_SCENES := [
	"res://scenes/systems/SpawnMarker.tscn",
	"res://scenes/systems/CheckpointMarker.tscn",
	"res://scenes/systems/DeathZone.tscn",
	"res://scenes/systems/TriggerArea.tscn",
	"res://scenes/systems/CameraBounds.tscn",
	"res://scenes/systems/TransitionZone.tscn",
	"res://scenes/systems/InteractionArea.tscn",
	"res://scenes/systems/PuzzleMarker.tscn",
]

const REQUIRED_ASSETS := [
	"res://assets/sprites/backgrounds/expansion/day_sky.png",
	"res://assets/sprites/backgrounds/expansion/distant_towers.png",
	"res://assets/sprites/backgrounds/expansion/night_machines.png",
	"res://assets/sprites/backgrounds/expansion/foreground_roots.png",
	"res://assets/sprites/backgrounds/expansion/atmosphere_fog.png",
	"res://assets/maps/central_map.png",
	"res://assets/vfx/combat/abomination_claw.png",
	"res://assets/vfx/corruption/unstable_explosion.png",
	"res://assets/vfx/arcane/sentinel_scan.png",
	"res://assets/vfx/shadow/fallen_pressure.png",
	"res://assets/ui/reference/button_primary_normal.png",
	"res://assets/ui/fonts/Cinzel-Regular.ttf",
]

var _failed := false


func _init() -> void:
	await _test_data()
	if _failed:
		return
	await _test_resources()
	if _failed:
		return
	await _test_enemies()
	if _failed:
		return
	await _test_map_room()
	if _failed:
		return
	print("KENOSIS_EXPANSION_OK")
	quit(0)


func _test_data() -> void:
	for path in DATA_FILES:
		if not FileAccess.file_exists(path):
			_fail("missing data file: %s" % path)
			return
		var file := FileAccess.open(path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed == null:
			_fail("invalid JSON data file: %s" % path)
			return

	var levels: Dictionary = _read_json("res://data/config/levels.json")
	var enemies: Array = levels.get("enemy_catalog", [])
	if enemies.size() < 5:
		_fail("levels data does not map the complete enemy catalog")
		return
	var destinations: Array = levels.get("map_destinations", [])
	if destinations.size() < 16:
		_fail("central map should expose at least 16 mapped destinations")
		return


func _test_resources() -> void:
	for path in SHADERS:
		if load(path) == null:
			_fail("shader failed to load: %s" % path)
			return

	for path in MARKER_SCENES:
		var scene: PackedScene = load(path)
		if scene == null or scene.instantiate() == null:
			_fail("level design marker failed to instantiate: %s" % path)
			return

	for path in REQUIRED_ASSETS:
		if not FileAccess.file_exists(path):
			_fail("required expansion asset missing: %s" % path)
			return


func _test_enemies() -> void:
	for path in ENEMY_SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			_fail("enemy scene failed to load: %s" % path)
			return
		var enemy: Node = packed.instantiate()
		root.add_child(enemy)
		await process_frame
		var animator := enemy.find_child("EnemyAnimator", true, false) as AnimatedSprite2D
		if animator == null:
			_fail("enemy animator missing: %s" % path)
			return
		for animation_name in ["idle", "move", "alert", "attack", "damage", "death", "respawn"]:
			if not animator.sprite_frames.has_animation(animation_name):
				_fail("enemy animation missing: %s / %s" % [path, animation_name])
				return
			if animator.sprite_frames.get_frame_count(animation_name) < 3:
				_fail("enemy animation has too few frames: %s / %s" % [path, animation_name])
				return
		if not enemy.has_method("receive_resonance") or not enemy.has_method("configure_target"):
			_fail("enemy gameplay API incomplete: %s" % path)
			return
		root.remove_child(enemy)
		enemy.queue_free()
		await process_frame


func _test_map_room() -> void:
	var packed: PackedScene = load(MAP_ROOM_PATH)
	if packed == null:
		_fail("map test room failed to load")
		return
	var room: Node = packed.instantiate()
	root.add_child(room)
	await process_frame
	await process_frame

	var navigator := room.find_child("MapNavigator", true, false)
	var gps_panel := room.find_child("GPSPanel", true, false)
	var current_location_label := room.find_child("CurrentLocationLabel", true, false)
	var navigation_detail_label := room.find_child("NavigationDetailLabel", true, false)
	var map_overlay := room.find_child("WorldMapOverlay", true, false)
	var player := room.find_child("Player", true, false)
	var has_navigation_display := gps_panel != null or (current_location_label != null and navigation_detail_label != null)
	if navigator == null or not has_navigation_display or map_overlay == null or player == null:
		_fail("map room navigation stack is incomplete")
		return

	var markers := get_nodes_in_group("map_destination")
	if markers.size() < 5:
		_fail("map room needs at least five teleport destinations")
		return

	var destination_position: Vector2 = navigator.call("teleport_to", "forge")
	await process_frame
	if destination_position == Vector2.ZERO or not player.global_position.is_equal_approx(destination_position):
		_fail("GPS teleport did not move the player to the selected destination")
		return

	var expansion_enemies := get_nodes_in_group("expansion_enemy")
	if expansion_enemies.size() < 4:
		_fail("map room did not instantiate all expansion enemies")
		return


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary


func _fail(reason: String) -> void:
	_failed = true
	push_error("Expansion test failed: %s" % reason)
	quit(1)
