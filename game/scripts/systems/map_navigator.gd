extends CanvasLayer
class_name MapNavigator

signal destination_selected(destination_id: StringName, position: Vector2)

const THEME := preload("res://assets/ui/themes/kenosis_theme.tres")
const MAP_TEXTURE := preload("res://assets/maps/central_map.png")
const CHECKPOINT_ICON := preload("res://assets/ui/reference/map_checkpoint_marker.png")
const MAP_ACCESS_ITEM_ID := "cartographer_lens"
const MAP_ATLAS_SIZE := Vector2(1456, 1088)
const MAP_OPENING_FRAME_PATHS := [
	"res://assets/ui/map_opening/frame_01_fechado_1920x1080.png",
	"res://assets/ui/map_opening/frame_02_inicio_abertura_horizontal_1920x1080.png",
	"res://assets/ui/map_opening/frame_03_abertura_25_1920x1080.png",
	"res://assets/ui/map_opening/frame_04_abertura_40_1920x1080.png",
	"res://assets/ui/map_opening/frame_05_abertura_55_1920x1080.png",
	"res://assets/ui/map_opening/frame_06_abertura_70_1920x1080.png",
	"res://assets/ui/map_opening/frame_07_abertura_85_1920x1080.png",
	"res://assets/ui/map_opening/frame_08_totalmente_aberto_1920x1080.png",
]

const REGION_ATLAS_POSITIONS := {
	"awakening": Vector2(417, 141),
	"fall": Vector2(936, 328),
	"forge": Vector2(638, 592),
	"abyss": Vector2(984, 693),
	"void": Vector2(652, 879),
}

const STORY_ATLAS_POSITIONS := {
	"awakening": Vector2(417, 141),
	"echo_trail": Vector2(261, 246),
	"forgotten_sanctuary": Vector2(795, 203),
	"broken_gate": Vector2(640, 249),
	"dormant_factory": Vector2(936, 328),
	"scar_city": Vector2(592, 428),
	"mechanical_core": Vector2(303, 526),
	"forge": Vector2(638, 592),
	"flame_labyrinth": Vector2(999, 540),
	"whisper_library": Vector2(277, 690),
	"rupture_chamber": Vector2(677, 706),
	"eternal_bridge": Vector2(984, 693),
	"formless_echo": Vector2(231, 831),
	"void_heart": Vector2(652, 879),
	"remaining_silence": Vector2(986, 797),
	"rebirth": Vector2(677, 1036),
}

const REGION_ANCHOR_POINT_IDS := {
	"awakening": "awakening",
	"fall": "dormant_factory",
	"forge": "forge",
	"abyss": "eternal_bridge",
	"void": "void_heart",
}

const REGION_LABELS := {
	"awakening": "Regiao I - Despertar",
	"fall": "Regiao II - Ruinas da Queda",
	"forge": "Regiao III - Forja da Corrupcao",
	"abyss": "Regiao IV - Abismo da Ressonancia",
	"void": "Regiao V - Coracao do Vazio",
}

var player: PlayerController
var destinations: Dictionary = {}
var map_zoom := 1.0
var map_pan := Vector2.ZERO

var gps_panel: PanelContainer
var gps_label: Label
var gps_distance_label: Label
var map_overlay: Control
var map_panel: PanelContainer
var route_panel: PanelContainer
var map_viewport: Control
var map_content: Control
var map_texture: TextureRect
var locked_point_root: Control
var hotspot_root: Control
var player_marker: TextureRect
var destination_stack: VBoxContainer
var details_label: Label
var zoom_label: Label
var story_travel_button: Button
var opening_animation: TextureRect
var _hud: PrototypeHUD
var _opening_frames: Array[Texture2D] = []
var _opening_animation_token := 0

var _refresh_remaining := 0.0
var _dragging_map := false
var _drag_origin := Vector2.ZERO
var _drag_start_pan := Vector2.ZERO
var _story_points: Dictionary = {}
var _selected_point_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_gps()
	_build_world_map()
	_load_story_points()
	refresh_map_access()


func _process(delta: float) -> void:
	_refresh_remaining -= delta
	if _refresh_remaining <= 0.0:
		_refresh_remaining = 0.2
		_update_gps()
		if map_overlay != null and map_overlay.visible:
			_update_player_marker()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("world_map"):
		set_map_visible(not map_overlay.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and map_overlay.visible:
		set_map_visible(false)
		get_viewport().set_input_as_handled()


func register_destination(
	destination_id: StringName,
	display_name: String,
	world_position: Vector2,
	teleport_enabled := true,
	region_id := ""
) -> void:
	var id := String(destination_id)
	var region := region_id if not region_id.is_empty() else _region_from_anchor_id(id)
	destinations[destination_id] = {
		"name": display_name,
		"position": world_position,
		"region": region,
		"map_position": STORY_ATLAS_POSITIONS.get(id, REGION_ATLAS_POSITIONS.get(region, MAP_ATLAS_SIZE * 0.5)),
		"type": "teleport",
		"teleport_enabled": teleport_enabled,
	}


func teleport_to(destination_id: StringName) -> Vector2:
	if player == null or not destinations.has(destination_id):
		return Vector2.ZERO

	var destination: Dictionary = destinations[destination_id]
	var destination_position: Vector2 = destination.get("position", Vector2.ZERO)
	player.global_position = destination_position
	player.velocity = Vector2.ZERO
	player.set_checkpoint(destination_position)
	destination_selected.emit(destination_id, destination_position)
	set_map_visible(false)
	_update_gps()
	return destination_position


func set_map_visible(visible: bool) -> void:
	if map_overlay == null:
		return
	if visible and not is_map_unlocked():
		_show_map_locked_feedback()
		return

	map_overlay.visible = visible
	if visible:
		refresh_map_access()
		_rebuild_destination_buttons()
		_rebuild_central_map()
		_center_map()
		_play_map_open_animation()
		_apply_map_transform.call_deferred()
		_update_player_marker.call_deferred()
	else:
		_opening_animation_token += 1
		if opening_animation != null:
			opening_animation.visible = false
	get_tree().paused = visible


func is_map_unlocked() -> bool:
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system == null or not save_system.has_method("has_map_access"):
		return true
	return save_system.has_map_access()


func refresh_map_access() -> void:
	if gps_distance_label == null:
		return
	if is_map_unlocked():
		gps_distance_label.modulate = Color(1, 1, 1, 1)
	else:
		gps_distance_label.text = "Lente cartografica ausente"
		gps_distance_label.modulate = Color(0.95, 0.62, 0.42, 1.0)


func set_map_zoom(value: float) -> void:
	map_zoom = clampf(value, 0.72, 2.25)
	_apply_map_transform()


func pan_map(delta: Vector2) -> void:
	map_pan += delta
	_apply_map_transform()


func get_map_opening_frame_count() -> int:
	return _opening_frames.size()


func can_travel_to_story_location(point_id: String) -> bool:
	var point: Dictionary = _story_points.get(point_id, {})
	if point.is_empty() or not _is_story_point_discovered(point_id):
		return false
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null and String(save_system.get_current_location()) == point_id:
		return false
	var scene_path := String(point.get("scene", ""))
	return not scene_path.is_empty() and ResourceLoader.exists(scene_path)


func get_story_travel_scene(point_id: String) -> String:
	if not can_travel_to_story_location(point_id):
		return ""
	var point: Dictionary = _story_points.get(point_id, {})
	return String(point.get("scene", ""))


func travel_to_story_location(point_id: String) -> bool:
	var scene_path := get_story_travel_scene(point_id)
	if scene_path.is_empty():
		return false
	var transition_manager := get_node_or_null("/root/StoryTransition")
	if transition_manager == null or not transition_manager.has_method("travel_to_location"):
		return false
	map_overlay.visible = false
	get_tree().paused = false
	transition_manager.call("travel_to_location", StringName(point_id), &"default")
	return true


func _build_gps() -> void:
	_hud = get_parent().find_child("PrototypeHUD", true, false) as PrototypeHUD
	if _hud != null:
		gps_label = _hud.current_location_label
		gps_distance_label = _hud.navigation_detail_label
		return

	gps_panel = PanelContainer.new()
	gps_panel.name = "GPSPanel"
	gps_panel.theme = THEME
	gps_panel.anchor_left = 1.0
	gps_panel.anchor_top = 0.0
	gps_panel.anchor_right = 1.0
	gps_panel.anchor_bottom = 0.0
	gps_panel.offset_left = -318.0
	gps_panel.offset_top = 24.0
	gps_panel.offset_right = -24.0
	gps_panel.offset_bottom = 118.0
	gps_panel.add_theme_stylebox_override("panel", _panel_style(
		Color(0.018, 0.035, 0.045, 0.94),
		Color(0.30, 0.88, 0.86, 0.92)
	))
	add_child(gps_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	gps_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var icon := TextureRect.new()
	icon.texture = CHECKPOINT_ICON
	icon.custom_minimum_size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(labels)

	var title := Label.new()
	title.text = "NAVEGACAO DE RESSONANCIA"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.43, 0.96, 0.93, 1.0))
	labels.add_child(title)

	gps_label = Label.new()
	gps_label.text = "Sincronizando..."
	gps_label.add_theme_font_size_override("font_size", 15)
	gps_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	labels.add_child(gps_label)

	gps_distance_label = Label.new()
	gps_distance_label.text = "M / TAB  abrir mapa"
	gps_distance_label.add_theme_font_size_override("font_size", 12)
	gps_distance_label.add_theme_color_override("font_color", Color(0.76, 0.69, 0.48, 1.0))
	labels.add_child(gps_distance_label)


func _build_world_map() -> void:
	map_overlay = Control.new()
	map_overlay.name = "WorldMapOverlay"
	map_overlay.theme = THEME
	map_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	map_overlay.visible = false
	_set_full_rect(map_overlay)
	add_child(map_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.009, 0.012, 0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_full_rect(shade)
	map_overlay.add_child(shade)

	map_panel = PanelContainer.new()
	map_panel.name = "MapPanel"
	map_panel.anchor_left = 0.025
	map_panel.anchor_top = 0.045
	map_panel.anchor_right = 0.76
	map_panel.anchor_bottom = 0.955
	map_panel.add_theme_stylebox_override("panel", _panel_style(
		Color(0.015, 0.022, 0.026, 1.0),
		Color(0.67, 0.49, 0.22, 1.0)
	))
	map_overlay.add_child(map_panel)

	var map_margin := MarginContainer.new()
	map_margin.add_theme_constant_override("margin_left", 10)
	map_margin.add_theme_constant_override("margin_top", 10)
	map_margin.add_theme_constant_override("margin_right", 10)
	map_margin.add_theme_constant_override("margin_bottom", 10)
	map_panel.add_child(map_margin)

	map_viewport = Control.new()
	map_viewport.name = "MapViewport"
	map_viewport.clip_contents = true
	map_viewport.mouse_filter = Control.MOUSE_FILTER_STOP
	map_viewport.mouse_default_cursor_shape = Control.CURSOR_DRAG
	map_viewport.gui_input.connect(_on_map_viewport_gui_input)
	map_viewport.resized.connect(_apply_map_transform)
	_set_full_rect(map_viewport)
	map_margin.add_child(map_viewport)

	map_content = Control.new()
	map_content.name = "MapContent"
	map_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_full_rect(map_content)
	map_viewport.add_child(map_content)

	map_texture = TextureRect.new()
	map_texture.name = "CentralMap"
	map_texture.texture = MAP_TEXTURE
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_texture.modulate = Color.WHITE
	_set_full_rect(map_texture)
	map_content.add_child(map_texture)

	locked_point_root = Control.new()
	locked_point_root.name = "LockedPointOverlays"
	locked_point_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(locked_point_root)
	map_content.add_child(locked_point_root)

	hotspot_root = Control.new()
	hotspot_root.name = "MapHotspots"
	hotspot_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_full_rect(hotspot_root)
	map_content.add_child(hotspot_root)

	player_marker = TextureRect.new()
	player_marker.name = "PlayerMapMarker"
	player_marker.texture = CHECKPOINT_ICON
	player_marker.custom_minimum_size = Vector2(28, 28)
	player_marker.size = Vector2(28, 28)
	player_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_marker.modulate = Color(1.0, 0.86, 0.38, 1.0)
	player_marker.tooltip_text = "Posicao atual do Escriba"
	map_content.add_child(player_marker)

	route_panel = PanelContainer.new()
	route_panel.name = "RoutePanel"
	route_panel.anchor_left = 0.78
	route_panel.anchor_top = 0.045
	route_panel.anchor_right = 0.975
	route_panel.anchor_bottom = 0.955
	route_panel.add_theme_stylebox_override("panel", _panel_style(
		Color(0.025, 0.035, 0.042, 0.98),
		Color(0.31, 0.86, 0.83, 0.94)
	))
	map_overlay.add_child(route_panel)

	var route_margin := MarginContainer.new()
	route_margin.add_theme_constant_override("margin_left", 18)
	route_margin.add_theme_constant_override("margin_top", 20)
	route_margin.add_theme_constant_override("margin_right", 18)
	route_margin.add_theme_constant_override("margin_bottom", 20)
	route_panel.add_child(route_margin)

	var route_stack := VBoxContainer.new()
	route_stack.add_theme_constant_override("separation", 10)
	route_margin.add_child(route_stack)

	var title := Label.new()
	title.text = "MAPA CENTRAL"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.94, 0.78, 0.42, 1.0))
	route_stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ancoras, memorias e regioes descobertas"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.78, 0.76, 1.0))
	route_stack.add_child(subtitle)

	var zoom_row := HBoxContainer.new()
	zoom_row.add_theme_constant_override("separation", 8)
	route_stack.add_child(zoom_row)

	var zoom_out := Button.new()
	zoom_out.text = "-"
	zoom_out.custom_minimum_size = Vector2(38, 34)
	zoom_out.pressed.connect(func() -> void: set_map_zoom(map_zoom - 0.18))
	zoom_row.add_child(zoom_out)

	zoom_label = Label.new()
	zoom_label.text = "100%"
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_label.custom_minimum_size = Vector2(72, 34)
	zoom_row.add_child(zoom_label)

	var zoom_in := Button.new()
	zoom_in.text = "+"
	zoom_in.custom_minimum_size = Vector2(38, 34)
	zoom_in.pressed.connect(func() -> void: set_map_zoom(map_zoom + 0.18))
	zoom_row.add_child(zoom_in)

	var center_button := Button.new()
	center_button.text = "Centralizar"
	center_button.custom_minimum_size = Vector2(0, 34)
	center_button.pressed.connect(_center_map)
	route_stack.add_child(center_button)

	var separator := HSeparator.new()
	route_stack.add_child(separator)

	details_label = Label.new()
	details_label.name = "DetailsLabel"
	details_label.text = "Selecione um ponto no mapa."
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.add_theme_font_size_override("font_size", 13)
	details_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82, 1.0))
	details_label.custom_minimum_size = Vector2(0, 64)
	route_stack.add_child(details_label)

	story_travel_button = Button.new()
	story_travel_button.name = "StoryTravelButton"
	story_travel_button.text = "Selecione uma fase"
	story_travel_button.custom_minimum_size = Vector2(0, 40)
	story_travel_button.visible = false
	story_travel_button.disabled = true
	story_travel_button.pressed.connect(_on_story_travel_pressed)
	route_stack.add_child(story_travel_button)

	destination_stack = VBoxContainer.new()
	destination_stack.name = "DestinationButtons"
	destination_stack.add_theme_constant_override("separation", 7)
	destination_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_stack.add_child(destination_stack)

	var close_button := Button.new()
	close_button.name = "CloseMapButton"
	close_button.text = "Fechar mapa"
	close_button.custom_minimum_size = Vector2(0, 42)
	close_button.pressed.connect(func() -> void: set_map_visible(false))
	route_stack.add_child(close_button)

	_load_map_opening_frames()
	opening_animation = TextureRect.new()
	opening_animation.name = "MapOpeningAnimation"
	opening_animation.visible = false
	opening_animation.process_mode = Node.PROCESS_MODE_ALWAYS
	opening_animation.mouse_filter = Control.MOUSE_FILTER_STOP
	opening_animation.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	opening_animation.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	opening_animation.anchor_left = 0.025
	opening_animation.anchor_top = 0.045
	opening_animation.anchor_right = 0.76
	opening_animation.anchor_bottom = 0.955
	map_overlay.add_child(opening_animation)


func _load_story_points() -> void:
	_story_points.clear()
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		return
	var levels: Dictionary = registry.get_section(&"levels")
	var story_locations: Dictionary = levels.get("story_locations", {})
	for destination in levels.get("map_destinations", []):
		var id := String(destination.get("id", ""))
		if id.is_empty() or not story_locations.has(id):
			continue
		var profile: Dictionary = story_locations[id]
		var region := String(destination.get("region", profile.get("region", "awakening")))
		_story_points[id] = {
			"name": String(destination.get("name", profile.get("name", id))),
			"region": region,
			"index": int(destination.get("index", 0)),
			"map_position": STORY_ATLAS_POSITIONS.get(id, _story_map_position(int(destination.get("index", 0)), region)),
			"scene": String(profile.get("scene", "")),
			"type": "story",
		}


func _rebuild_destination_buttons() -> void:
	for child in destination_stack.get_children():
		child.queue_free()

	for destination_id in destinations:
		var id := StringName(destination_id)
		var destination: Dictionary = destinations[id]
		var button := Button.new()
		button.name = "%sButton" % String(id).to_pascal_case()
		button.text = _compact_destination_name(String(destination.get("name", id)))
		button.custom_minimum_size = Vector2(0, 42)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var teleport_enabled := bool(destination.get("teleport_enabled", true))
		button.disabled = not teleport_enabled
		button.tooltip_text = "Teletransportar para esta ancora" if teleport_enabled else "Localizacao atual"
		button.pressed.connect(_on_destination_button_pressed.bind(id))
		destination_stack.add_child(button)


func _rebuild_central_map() -> void:
	_clear_children(locked_point_root)
	_clear_children(hotspot_root)

	for point_id in _story_points:
		var point: Dictionary = _story_points[point_id]
		var discovered := _is_story_point_discovered(point_id)
		if not discovered and point_id != "remaining_silence":
			var locked_overlay := _make_locked_point_overlay(point_id, point)
			locked_point_root.add_child(locked_overlay)
		var hotspot := _make_invisible_hotspot("%sMapHotspot" % String(point_id).to_pascal_case())
		hotspot.tooltip_text = _story_tooltip(point_id, point, discovered)
		hotspot.set_meta("point_id", point_id)
		hotspot.set_meta("atlas_position", point.get("map_position", MAP_ATLAS_SIZE * 0.5))
		hotspot.pressed.connect(_select_native_point.bind(point_id))
		hotspot_root.add_child(hotspot)

	_update_player_marker()
	_apply_map_transform()


func get_map_hotspot_atlas_position(point_id: String) -> Vector2:
	return STORY_ATLAS_POSITIONS.get(point_id, Vector2.ZERO)


func _on_destination_button_pressed(destination_id: StringName) -> void:
	teleport_to(destination_id)


func _select_anchor(destination_id: StringName) -> void:
	if not destinations.has(destination_id):
		return
	var destination: Dictionary = destinations[destination_id]
	_selected_point_id = String(destination_id)
	if bool(destination.get("teleport_enabled", true)):
		details_label.text = "%s\nAncora segura. Use o botao lateral para teleportar." % String(destination.get("name", destination_id))
	else:
		details_label.text = "%s\nLocalizacao atual da memoria." % String(destination.get("name", destination_id))


func _select_native_point(point_id: String) -> void:
	var point: Dictionary = _story_points.get(point_id, {})
	if point.is_empty():
		return
	_selected_point_id = point_id
	_update_story_travel_button(point_id)
	if not _is_story_point_discovered(point_id):
		details_label.text = "%s\nFASE NAO LIBERADA\nAvance pela historia para restaurar este ponto." % String(point.get("name", point_id))
		return

	var destination_id := _destination_id_for_story_point(point_id)
	if not destination_id.is_empty():
		details_label.text = "%s\n%s\nAncora ativa. Use o botao lateral para teleportar." % [
			String(point.get("name", point_id)),
			REGION_LABELS.get(String(point.get("region", "")), "Regiao desconhecida"),
		]
		return
	_select_story_point(point_id)


func _select_story_point(point_id: String) -> void:
	var point: Dictionary = _story_points.get(point_id, {})
	if point.is_empty():
		return
	_selected_point_id = point_id
	details_label.text = "%s\n%s\n%s" % [
		String(point.get("name", point_id)),
		REGION_LABELS.get(String(point.get("region", "")), "Regiao desconhecida"),
		"Memoria catalogada. Acesse pelo modo historia.",
	]


func _update_story_travel_button(point_id: String) -> void:
	if story_travel_button == null:
		return
	var discovered := _is_story_point_discovered(point_id)
	story_travel_button.visible = discovered
	story_travel_button.disabled = not can_travel_to_story_location(point_id)
	if not discovered:
		story_travel_button.text = "Fase nao liberada"
	elif story_travel_button.disabled:
		story_travel_button.text = "Localizacao atual"
	else:
		story_travel_button.text = "Viajar para esta fase"


func _on_story_travel_pressed() -> void:
	travel_to_story_location(_selected_point_id)


func _destination_id_for_story_point(point_id: String) -> String:
	for destination_id in destinations:
		var destination: Dictionary = destinations[destination_id]
		var region := String(destination.get("region", ""))
		if String(REGION_ANCHOR_POINT_IDS.get(region, "")) == point_id:
			return String(destination_id)
	return ""


func _update_gps() -> void:
	if player == null or destinations.is_empty() or gps_label == null:
		return

	if not is_map_unlocked():
		_set_navigation_text("Mapa nao sincronizado", "Encontre a lente cartografica")
		return

	var nearest_name := "Sem ancora"
	var nearest_distance := INF
	for destination_id in destinations:
		var destination: Dictionary = destinations[destination_id]
		var destination_position: Vector2 = destination.get("position", Vector2.ZERO)
		var distance := player.global_position.distance_to(destination_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_name = String(destination.get("name", destination_id))

	_set_navigation_text(
		_compact_destination_name(nearest_name),
		"%d m da ancora | M / TAB  mapa" % maxi(0, roundi(nearest_distance / 10.0))
	)


func _set_navigation_text(location_name: String, detail: String) -> void:
	if _hud != null:
		_hud.set_navigation(location_name, detail)
		return
	if gps_label != null:
		gps_label.text = location_name
	if gps_distance_label != null:
		gps_distance_label.text = detail


func _update_player_marker() -> void:
	if player_marker == null or player == null:
		return
	_position_atlas_control(player_marker, _player_map_position(), Vector2(28, 28))
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 170.0) * 0.09
	player_marker.scale = Vector2.ONE * pulse


func _on_map_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_map_zoom(map_zoom + 0.12)
			map_viewport.accept_event()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_map_zoom(map_zoom - 0.12)
			map_viewport.accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_dragging_map = mouse_event.pressed
			_drag_origin = mouse_event.position
			_drag_start_pan = map_pan
			map_viewport.accept_event()
	elif event is InputEventMouseMotion and _dragging_map:
		var motion := event as InputEventMouseMotion
		map_pan = _drag_start_pan + motion.position - _drag_origin
		_apply_map_transform()
		map_viewport.accept_event()


func _apply_map_transform() -> void:
	if map_content == null or map_viewport == null:
		return
	map_content.size = map_viewport.size
	_layout_map_interactions()
	map_content.scale = Vector2.ONE * map_zoom
	map_content.position = map_pan + map_viewport.size * (1.0 - map_zoom) * 0.5
	if zoom_label != null:
		zoom_label.text = "%d%%" % roundi(map_zoom * 100.0)


func _center_map() -> void:
	map_pan = Vector2.ZERO
	set_map_zoom(maxf(map_zoom, 1.0))
	_apply_map_transform()


func _play_map_open_animation() -> void:
	map_overlay.modulate.a = 0.0
	map_content.scale = Vector2.ONE * maxf(0.82, map_zoom - 0.08)
	map_panel.visible = false
	route_panel.visible = false
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(map_overlay, "modulate:a", 1.0, 0.12)
	tween.tween_property(map_content, "scale", Vector2.ONE * map_zoom, 0.24).set_trans(Tween.TRANS_SINE)
	_opening_animation_token += 1
	_run_map_opening_frames(_opening_animation_token)


func _load_map_opening_frames() -> void:
	_opening_frames.clear()
	for frame_path in MAP_OPENING_FRAME_PATHS:
		var texture := load(frame_path) as Texture2D
		if texture != null:
			_opening_frames.append(texture)


func _run_map_opening_frames(animation_token: int) -> void:
	if opening_animation == null or _opening_frames.is_empty():
		return
	opening_animation.visible = true
	opening_animation.modulate = Color.WHITE
	for frame_index in range(_opening_frames.size()):
		if animation_token != _opening_animation_token or not map_overlay.visible:
			opening_animation.visible = false
			return
		opening_animation.texture = _opening_frames[frame_index]
		var frame_duration := 0.09 if frame_index < 6 else 0.12
		await get_tree().create_timer(frame_duration, true).timeout
	if animation_token != _opening_animation_token:
		return
	map_panel.visible = true
	route_panel.visible = true
	var fade := create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(opening_animation, "modulate:a", 0.0, 0.16)
	await fade.finished
	if animation_token == _opening_animation_token:
		opening_animation.visible = false


func _show_map_locked_feedback() -> void:
	refresh_map_access()
	gps_label.text = "Mapa bloqueado"
	gps_distance_label.text = "Procure a lente cartografica"


func _make_invisible_hotspot(node_name: String) -> Button:
	var hotspot := Button.new()
	hotspot.name = node_name
	hotspot.text = ""
	hotspot.flat = true
	hotspot.focus_mode = Control.FOCUS_NONE
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.custom_minimum_size = Vector2(50, 50)
	hotspot.size = Vector2(50, 50)
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		hotspot.add_theme_stylebox_override(state, empty_style)
	return hotspot


func _make_locked_point_overlay(point_id: String, point: Dictionary) -> TextureRect:
	var atlas_position: Vector2 = point.get("map_position", MAP_ATLAS_SIZE * 0.5)
	var sample_size := Vector2(32, 32)
	var source_image := MAP_TEXTURE.get_image()
	var sample_origin := Vector2i(atlas_position - sample_size * 0.5)
	var sample_image := source_image.get_region(Rect2i(sample_origin, Vector2i(sample_size)))
	sample_image.convert(Image.FORMAT_RGBA8)
	var center := sample_size * 0.5
	var radius := sample_size.x * 0.46
	for y in range(sample_image.get_height()):
		for x in range(sample_image.get_width()):
			var color := sample_image.get_pixel(x, y)
			var distance_to_center := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var mask := 1.0 - smoothstep(radius - 3.0, radius, distance_to_center)
			var luminance := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			color.r = luminance * 0.56
			color.g = luminance * 0.56
			color.b = luminance * 0.56
			color.a *= mask
			sample_image.set_pixel(x, y, color)

	var overlay := TextureRect.new()
	overlay.name = "%sLockedPointOverlay" % point_id.to_pascal_case()
	overlay.texture = ImageTexture.create_from_image(sample_image)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_meta("atlas_position", atlas_position)
	overlay.set_meta("atlas_size", sample_size)
	overlay.set_meta("desaturated_native_point", true)
	return overlay


func _layout_map_interactions() -> void:
	if locked_point_root != null:
		for child in locked_point_root.get_children():
			var overlay := child as Control
			if overlay == null:
				continue
			var atlas_position: Vector2 = overlay.get_meta("atlas_position", MAP_ATLAS_SIZE * 0.5)
			var overlay_size: Vector2 = overlay.get_meta("atlas_size", Vector2(46, 46))
			_position_atlas_control(overlay, atlas_position, overlay_size)
	if hotspot_root != null:
		for child in hotspot_root.get_children():
			var hotspot := child as Control
			if hotspot == null:
				continue
			var atlas_position: Vector2 = hotspot.get_meta("atlas_position", MAP_ATLAS_SIZE * 0.5)
			_position_atlas_control(hotspot, atlas_position, Vector2(50, 50))
	if player_marker != null and player != null:
		_position_atlas_control(player_marker, _player_map_position(), Vector2(28, 28))


func _position_atlas_control(control: Control, atlas_position: Vector2, control_size: Vector2) -> void:
	var rendered_rect := _map_render_rect()
	var normalized_position := Vector2(
		atlas_position.x / MAP_ATLAS_SIZE.x,
		atlas_position.y / MAP_ATLAS_SIZE.y
	)
	var center := rendered_rect.position + rendered_rect.size * normalized_position
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = center - control_size * 0.5
	control.size = control_size


func _map_render_rect() -> Rect2:
	if map_content == null or map_content.size.x <= 0.0 or map_content.size.y <= 0.0:
		return Rect2(Vector2.ZERO, MAP_ATLAS_SIZE)
	var fit_scale := minf(
		map_content.size.x / MAP_ATLAS_SIZE.x,
		map_content.size.y / MAP_ATLAS_SIZE.y
	)
	var rendered_size := MAP_ATLAS_SIZE * fit_scale
	return Rect2((map_content.size - rendered_size) * 0.5, rendered_size)


func _player_map_position() -> Vector2:
	if destinations.is_empty() or player == null:
		return STORY_ATLAS_POSITIONS.get("awakening", MAP_ATLAS_SIZE * 0.5)

	var ordered_destinations: Array[Dictionary] = []
	var min_x := INF
	var max_x := -INF
	for destination_id in destinations:
		var destination: Dictionary = destinations[destination_id]
		var world_position: Vector2 = destination.get("position", Vector2.ZERO)
		min_x = minf(min_x, world_position.x)
		max_x = maxf(max_x, world_position.x)
		ordered_destinations.append(destination)

	if is_equal_approx(min_x, max_x):
		return ordered_destinations[0].get("map_position", MAP_ATLAS_SIZE * 0.5)

	ordered_destinations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a.get("position", Vector2.ZERO) as Vector2).x < (b.get("position", Vector2.ZERO) as Vector2).x
	)
	var player_x := clampf(player.global_position.x, min_x, max_x)
	for index in range(ordered_destinations.size() - 1):
		var current: Dictionary = ordered_destinations[index]
		var next: Dictionary = ordered_destinations[index + 1]
		var current_world: Vector2 = current.get("position", Vector2.ZERO)
		var next_world: Vector2 = next.get("position", Vector2.ZERO)
		if player_x <= next_world.x:
			var progress := inverse_lerp(current_world.x, next_world.x, player_x)
			var current_map: Vector2 = current.get("map_position", MAP_ATLAS_SIZE * 0.5)
			var next_map: Vector2 = next.get("map_position", MAP_ATLAS_SIZE * 0.5)
			return current_map.lerp(next_map, progress)
	return ordered_destinations[-1].get("map_position", MAP_ATLAS_SIZE * 0.5)


func _story_map_position(index: int, region: String) -> Vector2:
	var base: Vector2 = REGION_ATLAS_POSITIONS.get(region, MAP_ATLAS_SIZE * 0.5)
	var step := float(maxi(index - 1, 0) % 4)
	var lane := float(maxi(index - 1, 0) / 4)
	return base + Vector2((step - 1.5) * 42.0, (lane - 1.5) * 34.0)


func _is_story_point_discovered(point_id: String) -> bool:
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system == null or not save_system.has_method("is_location_unlocked"):
		return true
	return save_system.is_location_unlocked(StringName(point_id))


func _story_tooltip(point_id: String, point: Dictionary, discovered: bool) -> String:
	if not discovered:
		return "Memoria ainda nao descoberta"
	return "%s\n%s" % [
		String(point.get("name", point_id)),
		REGION_LABELS.get(String(point.get("region", "")), "Regiao desconhecida"),
	]


func _region_from_anchor_id(id: String) -> String:
	match id:
		"awakening":
			return "awakening"
		"fall":
			return "fall"
		"forge":
			return "forge"
		"abyss":
			return "abyss"
		"void":
			return "void"
	return "awakening"


func _compact_destination_name(display_name: String) -> String:
	for prefix in [
		"Regiao I - ",
		"Regiao II - ",
		"Regiao III - ",
		"Regiao IV - ",
		"Regiao V - ",
	]:
		if display_name.begins_with(prefix):
			return display_name.trim_prefix(prefix)
	return display_name


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 5
	return style


func _set_full_rect(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
