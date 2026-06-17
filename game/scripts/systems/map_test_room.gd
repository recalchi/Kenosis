extends "res://scripts/systems/test_room.gd"

const MapNavigatorScript := preload("res://scripts/systems/map_navigator.gd")
const AncestralAbominationScene := preload("res://scenes/enemies/AncestralAbomination.tscn")
const UnstableEnergyScene := preload("res://scenes/enemies/UnstableEnergy.tscn")
const MysticSentinelScene := preload("res://scenes/enemies/MysticSentinel.tscn")
const FallenShadowScene := preload("res://scenes/enemies/FallenShadow.tscn")

const REGIONAL_DESTINATIONS := {
	&"awakening": {"name": "Regiao I - Despertar", "position": Vector2(180, 410)},
	&"fall": {"name": "Regiao II - Ruinas da Queda", "position": Vector2(720, 410)},
	&"forge": {"name": "Regiao III - Forja da Corrupcao", "position": Vector2(1320, 410)},
	&"abyss": {"name": "Regiao IV - Abismo da Ressonancia", "position": Vector2(1900, 410)},
	&"void": {"name": "Regiao V - Coracao do Vazio", "position": Vector2(2460, 410)},
}


func _ready() -> void:
	super._ready()
	name = "MapTestRoom"
	_add_expansion_environment()
	_create_map_destinations()
	_create_expansion_enemies()
	_create_map_navigator()
	hud.show_message("Sala de expansao: M ou TAB abre o mapa e as ancoras de teletransporte.")


func _add_expansion_environment() -> void:
	var parallax_scene := get_node_or_null("ParallaxScene") as Node2D
	if parallax_scene == null:
		return

	var haze_layer := _create_parallax_layer(parallax_scene, "ExpansionSkyLayer", 0.06, -96)
	for x_position in [280.0, 1180.0, 2080.0]:
		_create_parallax_sprite(
			haze_layer,
			"res://assets/sprites/backgrounds/expansion/day_cloud_modules.png",
			Vector2(x_position, 205),
			92.0,
			Color(0.82, 0.92, 0.94, 0.24)
		)

	var distant_layer := _create_parallax_layer(parallax_scene, "ExpansionArchitectureLayer", 0.18, -84)
	for x_position in [420.0, 1390.0, 2360.0]:
		_create_parallax_sprite(
			distant_layer,
			"res://assets/sprites/backgrounds/expansion/distant_towers.png",
			Vector2(x_position, 330),
			235.0,
			Color(0.48, 0.56, 0.56, 0.34)
		)

	var ruins_layer := _create_parallax_layer(parallax_scene, "ExpansionMidgroundLayer", 0.38, -62)
	_create_parallax_sprite(
		ruins_layer,
		"res://assets/sprites/backgrounds/expansion/midground_ruins.png",
		Vector2(720, 395),
		150.0,
		Color(0.58, 0.62, 0.53, 0.42)
	)
	_create_parallax_sprite(
		ruins_layer,
		"res://assets/sprites/backgrounds/expansion/night_machines.png",
		Vector2(1880, 360),
		205.0,
		Color(0.43, 0.52, 0.57, 0.36)
	)

	var atmosphere_layer := _create_parallax_layer(parallax_scene, "ExpansionAtmosphereLayer", 0.68, -18)
	for x_position in [360.0, 1120.0, 1880.0, 2540.0]:
		_create_parallax_sprite(
			atmosphere_layer,
			"res://assets/sprites/backgrounds/expansion/atmosphere_fog.png",
			Vector2(x_position, 330),
			105.0,
			Color(0.65, 0.90, 0.92, 0.16)
		)

	_create_grounded_prop(
		"ExpansionRootsLeft",
		Vector2(410, GROUND_SURFACE_Y),
		52.0,
		"res://assets/sprites/backgrounds/expansion/foreground_roots.png",
		-4,
		Color(0.82, 0.86, 0.72, 0.82)
	)
	_create_grounded_prop(
		"ExpansionRocksRight",
		Vector2(2180, GROUND_SURFACE_Y),
		46.0,
		"res://assets/sprites/backgrounds/expansion/foreground_rocks.png",
		-4,
		Color(0.73, 0.79, 0.72, 0.76)
	)


func _create_map_destinations() -> void:
	var destination_root := Node2D.new()
	destination_root.name = "MapDestinations"
	add_child(destination_root)

	for destination_id in REGIONAL_DESTINATIONS:
		var destination: Dictionary = REGIONAL_DESTINATIONS[destination_id]
		var marker := Marker2D.new()
		marker.name = "%sDestination" % String(destination_id).to_pascal_case()
		marker.position = destination.get("position", Vector2.ZERO)
		marker.set_meta("destination_id", destination_id)
		marker.set_meta("display_name", destination.get("name", destination_id))
		marker.add_to_group("map_destination")
		destination_root.add_child(marker)


func _create_expansion_enemies() -> void:
	var enemy_specs := [
		{"scene": MysticSentinelScene, "position": Vector2(540, 407)},
		{"scene": AncestralAbominationScene, "position": Vector2(1040, 407)},
		{"scene": UnstableEnergyScene, "position": Vector2(1660, 340)},
		{"scene": FallenShadowScene, "position": Vector2(2200, 407)},
	]

	var enemy_root := Node2D.new()
	enemy_root.name = "ExpansionEnemies"
	add_child(enemy_root)

	for spec in enemy_specs:
		var packed_scene: PackedScene = spec.get("scene")
		var enemy := packed_scene.instantiate() as ExpansionEnemy
		enemy.position = spec.get("position", Vector2.ZERO)
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
		enemy.configure_target(player)
		enemy.defeated.connect(_on_expansion_enemy_defeated)
		enemy.attack_started.connect(_on_expansion_enemy_attack)
		enemy_root.add_child(enemy)


func _create_map_navigator() -> void:
	var navigator := MapNavigatorScript.new() as MapNavigator
	navigator.name = "MapNavigator"
	navigator.player = player
	for destination_id in REGIONAL_DESTINATIONS:
		var destination: Dictionary = REGIONAL_DESTINATIONS[destination_id]
		navigator.register_destination(
			destination_id,
			String(destination.get("name", destination_id)),
			destination.get("position", Vector2.ZERO)
		)
	navigator.destination_selected.connect(_on_destination_selected)
	add_child(navigator)


func _on_expansion_enemy_defeated(_enemy_id: StringName, reward: int) -> void:
	hud.show_message("Assinatura hostil desfeita. +%d pontos de memoria." % reward)
	_audio_sfx("confirm")


func _on_expansion_enemy_attack(enemy_id: StringName) -> void:
	var registry := get_node_or_null("/root/DataRegistry")
	var display_name := String(enemy_id)
	if registry != null:
		var levels: Dictionary = registry.get_section(&"levels")
		var catalog: Array = levels.get("enemy_catalog", [])
		if catalog.has(String(enemy_id)):
			display_name = String(enemy_id).replace("_", " ").capitalize()
	hud.show_message("Ameaca detectada: %s" % display_name)
	_audio_sfx("alert")


func _on_destination_selected(_destination_id: StringName, _position: Vector2) -> void:
	hud.show_message("Ancora sincronizada. Este ponto agora e o retorno ativo.")
	_audio_sfx("checkpoint")
