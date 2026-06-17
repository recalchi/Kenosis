extends CanvasLayer
class_name MapNavigator

signal destination_selected(destination_id: StringName, position: Vector2)

const THEME := preload("res://assets/ui/themes/kenosis_theme.tres")
const MAP_TEXTURE := preload("res://assets/maps/central_map.png")
const CHECKPOINT_ICON := preload("res://assets/ui/reference/map_checkpoint_marker.png")

var player: PlayerController
var destinations: Dictionary = {}
var gps_panel: PanelContainer
var gps_label: Label
var gps_distance_label: Label
var map_overlay: Control
var destination_stack: VBoxContainer
var _refresh_remaining := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_gps()
	_build_world_map()


func _process(delta: float) -> void:
	_refresh_remaining -= delta
	if _refresh_remaining <= 0.0:
		_refresh_remaining = 0.2
		_update_gps()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("world_map"):
		set_map_visible(not map_overlay.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and map_overlay.visible:
		set_map_visible(false)
		get_viewport().set_input_as_handled()


func register_destination(destination_id: StringName, display_name: String, world_position: Vector2) -> void:
	destinations[destination_id] = {
		"name": display_name,
		"position": world_position,
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
	map_overlay.visible = visible
	if visible:
		_rebuild_destination_buttons()
	get_tree().paused = visible


func _build_gps() -> void:
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

	var map_panel := PanelContainer.new()
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

	var map_texture := TextureRect.new()
	map_texture.name = "CentralMap"
	map_texture.texture = MAP_TEXTURE
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_margin.add_child(map_texture)

	var route_panel := PanelContainer.new()
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
	route_stack.add_theme_constant_override("separation", 12)
	route_margin.add_child(route_stack)

	var title := Label.new()
	title.text = "MAPA CENTRAL"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.94, 0.78, 0.42, 1.0))
	route_stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "16 destinos mapeados\n5 ancoras ativas no campo"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.78, 0.76, 1.0))
	route_stack.add_child(subtitle)

	var separator := HSeparator.new()
	route_stack.add_child(separator)

	destination_stack = VBoxContainer.new()
	destination_stack.name = "DestinationButtons"
	destination_stack.add_theme_constant_override("separation", 8)
	destination_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_stack.add_child(destination_stack)

	var close_button := Button.new()
	close_button.name = "CloseMapButton"
	close_button.text = "Fechar mapa"
	close_button.custom_minimum_size = Vector2(0, 42)
	close_button.pressed.connect(func() -> void: set_map_visible(false))
	route_stack.add_child(close_button)


func _rebuild_destination_buttons() -> void:
	for child in destination_stack.get_children():
		child.queue_free()

	for destination_id in destinations:
		var id := StringName(destination_id)
		var destination: Dictionary = destinations[id]
		var button := Button.new()
		button.name = "%sButton" % String(id).to_pascal_case()
		button.text = String(destination.get("name", id))
		button.custom_minimum_size = Vector2(0, 46)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = "Teletransportar para esta ancora"
		button.pressed.connect(_on_destination_button_pressed.bind(id))
		destination_stack.add_child(button)


func _on_destination_button_pressed(destination_id: StringName) -> void:
	teleport_to(destination_id)


func _update_gps() -> void:
	if player == null or destinations.is_empty() or gps_label == null:
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

	gps_label.text = nearest_name
	gps_distance_label.text = "%d m  |  M / TAB  mapa" % maxi(0, roundi(nearest_distance / 10.0))


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
