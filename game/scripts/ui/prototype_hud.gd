extends CanvasLayer
class_name PrototypeHUD

signal resume_requested
signal retry_requested
signal menu_requested
signal quit_requested
signal dialogue_closed

var points_label: Label
var health_label: Label
var health_hearts: HBoxContainer
var health_heart_nodes: Array[TextureRect] = []
var stealth_label: Label
var resonance_label: Label
var resonance_bar: ProgressBar
var resonance_orb: TextureRect
var prompt_label: Label
var prompt_icon: TextureRect
var prompt_panel: PanelContainer
var objective_panel: PanelContainer
var objective_step_label: Label
var objective_text: Label
var current_location_label: Label
var navigation_detail_label: Label
var objective_points_label: Label
var points_purpose_label: Label
var message_label: Label
var opening_label: Label
var opening_panel: PanelContainer
var message_panel: PanelContainer
var pause_overlay: PanelContainer
var death_overlay: PanelContainer
var completion_overlay: PanelContainer
var dialogue_overlay: Control
var dialogue_visual_root: Control
var dialogue_title: Label
var dialogue_speaker: Label
var dialogue_body: Label
var dialogue_counter: Label
var dialogue_hint: Label
var dialogue_next_marker: TextureRect
var completion_body: Label
var _dialogue_lines: Array[String] = []
var _dialogue_index := 0
var _dialogue_line_text := ""
var _dialogue_character_elapsed := 0.0
var _dialogue_typing := false
var _dialogue_closing := false
var _dialogue_close_elapsed := 0.0
var _dialogue_close_frames := 0
var _dialogue_previous_paused := false
var _dialogue_last_tick_character := 0
var _dialogue_transition_tween: Tween
var _message_text := ""
var _message_elapsed := 0.0
var _message_hold_seconds := 0.0
var _opening_text := "CAMPO DE TESTES\nAmbiente de validacao. A historia principal permanece indisponivel."
var _opening_elapsed := 0.0

const DEFAULT_HEART_COUNT := 3
const HEART_TEXTURE_PATH := "res://assets/ui/gameplay/icons/32x32/icone_vida_32x32.png"
const DIALOGUE_FRAME_TEXTURE_PATH := "res://assets/ui/dialogue/caixa_dialogo_grande_com_slot_retrato_e_tag_vazios_416x123_2x_832x246.png"
const DIALOGUE_NEXT_MARKER_TEXTURE_PATH := "res://assets/ui/dialogue/icone_marcador_proxima_pagina_20x19_2x_40x38.png"
const DIALOGUE_NATIVE_SIZE := Vector2(832, 246)
const DIALOGUE_OPEN_OFFSET_Y := 28.0
const DIALOGUE_OPEN_DURATION := 0.22
const DIALOGUE_CLOSE_DURATION := 0.18


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_status_hud()
	_build_objective_panel()
	_build_prompt()
	_build_message_panel()
	_build_opening_banner()
	_build_pause_overlay()
	_build_death_overlay()
	_build_completion_overlay()
	_build_dialogue_overlay()
	_apply_interface_theme()

	set_points(100)
	set_points_context("Memorias abrem selos e definem rank.")
	set_objective("1 / 6", "Observe a fonte e use F no receptor para materializar a ponte.")
	set_resonance(1.0, 0.0)
	set_prompt("")
	var settings := get_node_or_null("/root/GameSettings")
	var tutorials_enabled := bool(settings.get("tutorials_enabled")) if settings != null else true
	apply_tutorial_preference(tutorials_enabled)
	if tutorials_enabled:
		show_message("Encontre o receptor e use F para materializar a ponte.")


func _apply_interface_theme() -> void:
	var interface_theme: Theme = load("res://assets/ui/themes/kenosis_theme.tres")
	for child in get_children():
		if child is Control:
			(child as Control).theme = interface_theme


func _process(delta: float) -> void:
	_update_opening_text(delta)
	_update_message_text(delta)
	_update_dialogue_text(delta)
	_update_dialogue_transition(delta)


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_overlay != null and dialogue_overlay.visible and event.is_action_pressed("interact"):
		if _dialogue_typing:
			complete_dialogue_line()
		else:
			advance_dialogue()
		get_viewport().set_input_as_handled()


func set_points(points: int) -> void:
	points_label.text = "%03d" % points
	if objective_points_label != null:
		objective_points_label.text = "%03d MEMORIAS" % points
	if points_purpose_label != null:
		if points < 20:
			points_purpose_label.text = "Poucas memorias: evite falhas."
		elif points >= 160:
			points_purpose_label.text = "Rank alto: preserve o ritmo."


func set_points_context(context: String) -> void:
	if points_purpose_label != null:
		points_purpose_label.text = context


func set_objective(step: String, description: String) -> void:
	if objective_step_label != null:
		objective_step_label.text = step
	if objective_text != null:
		objective_text.text = description


func set_navigation(location_name: String, detail: String) -> void:
	if current_location_label != null:
		current_location_label.text = location_name
	if navigation_detail_label != null:
		navigation_detail_label.text = detail


func set_health(health: int, max_health: int) -> void:
	health_label.text = "VIDA  %d / %d" % [health, max_health]
	_ensure_health_heart_count(max_health)
	for index in health_heart_nodes.size():
		var heart := health_heart_nodes[index]
		heart.modulate = (
			Color.WHITE
			if index < health
			else Color(0.30, 0.22, 0.24, 0.32)
		)


func set_stealth(hidden: bool, cover_available: bool, crouching: bool) -> void:
	if hidden:
		stealth_label.text = "ASSINATURA OCULTA"
		stealth_label.add_theme_color_override("font_color", Color(0.42, 0.94, 0.92, 1.0))
	elif crouching:
		stealth_label.text = "AGACHADO - PROCURE COBERTURA"
		stealth_label.add_theme_color_override("font_color", Color(0.76, 0.84, 0.72, 1.0))
	elif cover_available:
		stealth_label.text = "SHIFT / C  OCULTAR"
		stealth_label.add_theme_color_override("font_color", Color(0.90, 0.78, 0.43, 1.0))
	else:
		stealth_label.text = "ASSINATURA VISIVEL"
		stealth_label.add_theme_color_override("font_color", Color(0.66, 0.70, 0.70, 1.0))


func set_resonance(ready_percent: float, remaining_seconds: float) -> void:
	resonance_bar.value = ready_percent * 100.0
	if remaining_seconds <= 0.0:
		resonance_label.text = "RESSONANCIA PRONTA"
		resonance_orb.texture = load("res://assets/ui/reference/resonance_orb_full.png")
	else:
		resonance_label.text = "RECARGA %.1fs" % remaining_seconds
		resonance_orb.texture = load("res://assets/ui/reference/resonance_orb_empty.png")


func set_prompt(label: String) -> void:
	prompt_label.text = label
	prompt_panel.visible = not label.is_empty()
	if label.begins_with("F:"):
		prompt_icon.texture = load("res://assets/ui/reference/interaction_f.png")
	else:
		prompt_icon.texture = load("res://assets/ui/reference/interaction_e.png")


func apply_tutorial_preference(enabled: bool) -> void:
	if opening_panel != null:
		opening_panel.visible = enabled
		opening_panel.modulate.a = 1.0
	if not enabled:
		_opening_elapsed = 0.0
		if opening_label != null:
			opening_label.text = ""
		_message_text = ""
		if message_panel != null:
			message_panel.visible = false


func set_opening_text(text: String) -> void:
	_opening_text = text
	_opening_elapsed = 0.0
	if opening_label != null:
		opening_label.text = ""
	if opening_panel != null:
		opening_panel.visible = true
		opening_panel.modulate.a = 1.0


func show_pause_menu() -> void:
	death_overlay.visible = false
	completion_overlay.visible = false
	pause_overlay.visible = true


func hide_pause_menu() -> void:
	pause_overlay.visible = false


func is_pause_menu_visible() -> bool:
	return pause_overlay.visible


func show_death_menu(points: int) -> void:
	pause_overlay.visible = false
	completion_overlay.visible = false
	death_overlay.visible = true
	show_message("Falha registrada. Pontos restantes: %d." % points)


func hide_death_menu() -> void:
	death_overlay.visible = false


func is_death_menu_visible() -> bool:
	return death_overlay.visible


func show_completion(points := 0) -> void:
	pause_overlay.visible = false
	death_overlay.visible = false
	completion_overlay.visible = true
	var rank := "S" if points >= 180 else ("A" if points >= 140 else ("B" if points >= 100 else "C"))
	completion_body.text = "Memorias preservadas: %03d\nClassificacao do campo: %s" % [points, rank]
	show_message("Campo de testes concluido com classificacao %s." % rank)


func hide_completion() -> void:
	completion_overlay.visible = false


func is_completion_visible() -> bool:
	return completion_overlay.visible


func show_dialogue(title: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	_kill_dialogue_transition()
	_dialogue_closing = false
	_dialogue_lines = lines.duplicate()
	_dialogue_index = 0
	dialogue_speaker.text = title
	dialogue_title = dialogue_speaker
	dialogue_overlay.visible = true
	prompt_panel.visible = false
	message_panel.visible = false
	opening_panel.visible = false
	_dialogue_previous_paused = get_tree().paused
	get_tree().paused = true
	_show_dialogue_line()
	_play_dialogue_open_transition()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_ui("dialogue_open")


func show_dialogue_id(dialogue_id: StringName) -> void:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null:
		return
	var dialogue_data: Dictionary = registry.get_section(&"dialogue")
	var entry: Dictionary = dialogue_data.get("dialogues", {}).get(String(dialogue_id), {})
	if entry.is_empty():
		return
	var lines: Array[String] = []
	for line in entry.get("lines", []):
		lines.append(String(line))
	show_dialogue(String(entry.get("speaker", "Memoria")), lines)


func advance_dialogue() -> void:
	if _dialogue_closing:
		return
	_dialogue_index += 1
	if _dialogue_index < _dialogue_lines.size():
		_show_dialogue_line()
		return
	_begin_dialogue_close_transition()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_ui("dialogue_close")


func complete_dialogue_line() -> void:
	if not _dialogue_typing or _dialogue_closing:
		return
	_dialogue_typing = false
	dialogue_body.visible_characters = -1
	dialogue_hint.text = "E  continuar"
	if dialogue_next_marker != null:
		dialogue_next_marker.visible = true


func _show_dialogue_line() -> void:
	_dialogue_line_text = _dialogue_lines[_dialogue_index]
	dialogue_body.text = _dialogue_line_text
	dialogue_body.visible_characters = 0
	dialogue_counter.text = "%d / %d" % [_dialogue_index + 1, _dialogue_lines.size()]
	dialogue_hint.text = "E  completar"
	if dialogue_next_marker != null:
		dialogue_next_marker.visible = false
	_dialogue_character_elapsed = 0.0
	_dialogue_last_tick_character = 0
	_dialogue_typing = true
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and _dialogue_index > 0:
		audio.play_sfx("lore")


func show_message(message: String) -> void:
	_message_text = message
	_message_elapsed = 0.0
	_message_hold_seconds = 2.2
	message_label.text = ""
	message_label.get_parent().visible = true


func _build_status_hud() -> void:
	var panel := PanelContainer.new()
	panel.name = "StatusPanel"
	panel.anchor_left = 0.022
	panel.anchor_top = 0.025
	panel.anchor_right = 0.285
	panel.anchor_bottom = 0.205
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.035, 0.045, 0.88), Color(0.66, 0.50, 0.23, 0.94)))
	add_child(panel)

	var ornament := NinePatchRect.new()
	ornament.name = "StatusFrameOrnament"
	ornament.texture = load("res://assets/ui/reference/hud_frame_ornament.png")
	ornament.anchor_right = 1.0
	ornament.anchor_bottom = 1.0
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ornament.draw_center = false
	ornament.set_patch_margin(SIDE_LEFT, 14)
	ornament.set_patch_margin(SIDE_TOP, 14)
	ornament.set_patch_margin(SIDE_RIGHT, 14)
	ornament.set_patch_margin(SIDE_BOTTOM, 14)
	panel.add_child(ornament)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	resonance_orb = TextureRect.new()
	resonance_orb.name = "ResonanceOrb"
	resonance_orb.custom_minimum_size = Vector2(68, 68)
	resonance_orb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	resonance_orb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(resonance_orb)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 4)
	row.add_child(stack)

	resonance_label = Label.new()
	resonance_label.name = "ResonanceLabel"
	resonance_label.add_theme_font_size_override("font_size", 13)
	resonance_label.add_theme_color_override("font_color", Color(0.45, 0.94, 0.93, 1.0))
	stack.add_child(resonance_label)

	resonance_bar = ProgressBar.new()
	resonance_bar.name = "ResonanceBar"
	resonance_bar.show_percentage = false
	resonance_bar.custom_minimum_size = Vector2(170, 14)
	resonance_bar.add_theme_stylebox_override("background", _bar_style(Color(0.06, 0.07, 0.075, 1.0), Color(0.32, 0.29, 0.23, 1.0)))
	resonance_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.12, 0.72, 0.73, 1.0), Color(0.55, 1.0, 0.96, 1.0)))
	stack.add_child(resonance_bar)

	var health_row := HBoxContainer.new()
	health_row.name = "HealthRow"
	health_row.add_theme_constant_override("separation", 8)
	stack.add_child(health_row)

	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "VIDA  3 / 3"
	health_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 12)
	health_label.add_theme_color_override("font_color", Color(0.95, 0.54, 0.48, 1.0))
	health_row.add_child(health_label)

	health_hearts = HBoxContainer.new()
	health_hearts.name = "HealthHearts"
	health_hearts.alignment = BoxContainer.ALIGNMENT_END
	health_hearts.add_theme_constant_override("separation", 3)
	health_row.add_child(health_hearts)
	_ensure_health_heart_count(DEFAULT_HEART_COUNT)

	stealth_label = Label.new()
	stealth_label.name = "StealthLabel"
	stealth_label.add_theme_font_size_override("font_size", 11)
	stack.add_child(stealth_label)

	var points_row := HBoxContainer.new()
	points_row.add_theme_constant_override("separation", 8)
	stack.add_child(points_row)

	var memory_icon := TextureRect.new()
	memory_icon.texture = load("res://assets/ui/reference/status_memory.png")
	memory_icon.custom_minimum_size = Vector2(24, 24)
	memory_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	memory_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	points_row.add_child(memory_icon)

	points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.add_theme_font_size_override("font_size", 17)
	points_label.add_theme_color_override("font_color", Color(0.94, 0.81, 0.46, 1.0))
	points_row.add_child(points_label)

	points_purpose_label = Label.new()
	points_purpose_label.name = "PointsPurposeLabel"
	points_purpose_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	points_purpose_label.add_theme_font_size_override("font_size", 10)
	points_purpose_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.66, 0.95))
	stack.add_child(points_purpose_label)


func _build_objective_panel() -> void:
	objective_panel = PanelContainer.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.anchor_left = 0.70
	objective_panel.anchor_top = 0.028
	objective_panel.anchor_right = 0.978
	objective_panel.anchor_bottom = 0.218
	objective_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.028, 0.038, 0.84), Color(0.35, 0.78, 0.78, 0.92)))
	add_child(objective_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 9)
	objective_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	margin.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	stack.add_child(header)

	var panel_title := Label.new()
	panel_title.name = "MissionNavigationTitle"
	panel_title.text = "MISSAO E LOCALIZACAO"
	panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_title.add_theme_font_size_override("font_size", 12)
	panel_title.add_theme_color_override("font_color", Color(0.47, 0.95, 0.93, 1.0))
	header.add_child(panel_title)

	objective_step_label = Label.new()
	objective_step_label.name = "ObjectiveStepLabel"
	objective_step_label.text = "1 / 6"
	objective_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_step_label.add_theme_font_size_override("font_size", 12)
	objective_step_label.add_theme_color_override("font_color", Color(0.93, 0.77, 0.38, 1.0))
	header.add_child(objective_step_label)

	objective_text = Label.new()
	objective_text.name = "ObjectiveText"
	objective_text.text = "Use a Ressonancia para abrir o primeiro caminho."
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_text.add_theme_font_size_override("font_size", 14)
	objective_text.add_theme_color_override("font_color", Color(0.91, 0.87, 0.72, 1.0))
	stack.add_child(objective_text)

	var separator := HSeparator.new()
	stack.add_child(separator)

	var navigation_row := HBoxContainer.new()
	navigation_row.add_theme_constant_override("separation", 10)
	stack.add_child(navigation_row)

	var location_icon := TextureRect.new()
	location_icon.texture = load("res://assets/ui/reference/map_checkpoint_marker.png")
	location_icon.custom_minimum_size = Vector2(34, 34)
	location_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	location_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	navigation_row.add_child(location_icon)

	var navigation_stack := VBoxContainer.new()
	navigation_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation_row.add_child(navigation_stack)

	current_location_label = Label.new()
	current_location_label.name = "CurrentLocationLabel"
	current_location_label.text = "Campo de Testes"
	current_location_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	current_location_label.add_theme_font_size_override("font_size", 13)
	current_location_label.add_theme_color_override("font_color", Color(0.78, 0.94, 0.91, 1.0))
	navigation_stack.add_child(current_location_label)

	navigation_detail_label = Label.new()
	navigation_detail_label.name = "NavigationDetailLabel"
	navigation_detail_label.text = "Mapa ainda nao sincronizado"
	navigation_detail_label.add_theme_font_size_override("font_size", 10)
	navigation_detail_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.66, 0.95))
	navigation_stack.add_child(navigation_detail_label)

	objective_points_label = Label.new()
	objective_points_label.name = "ObjectivePointsLabel"
	objective_points_label.text = "100 MEMORIAS"
	objective_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_points_label.add_theme_font_size_override("font_size", 11)
	objective_points_label.add_theme_color_override("font_color", Color(0.94, 0.81, 0.46, 1.0))
	navigation_row.add_child(objective_points_label)


func _build_prompt() -> void:
	prompt_panel = PanelContainer.new()
	prompt_panel.name = "PromptPanel"
	prompt_panel.anchor_left = 0.36
	prompt_panel.anchor_top = 0.82
	prompt_panel.anchor_right = 0.64
	prompt_panel.anchor_bottom = 0.91
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.03, 0.04, 0.90), Color(0.31, 0.83, 0.82, 0.95)))
	add_child(prompt_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	prompt_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	prompt_icon = TextureRect.new()
	prompt_icon.name = "PromptIcon"
	prompt_icon.custom_minimum_size = Vector2(38, 38)
	prompt_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prompt_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(prompt_icon)

	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 1.0))
	row.add_child(prompt_label)


func _build_message_panel() -> void:
	message_panel = PanelContainer.new()
	message_panel.name = "MessagePanel"
	message_panel.anchor_left = 0.30
	message_panel.anchor_top = 0.70
	message_panel.anchor_right = 0.70
	message_panel.anchor_bottom = 0.78
	message_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.03, 0.04, 0.88), Color(0.58, 0.44, 0.22, 0.85)))
	add_child(message_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 9)
	message_panel.add_child(margin)

	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.72, 1.0))
	margin.add_child(message_label)


func _build_opening_banner() -> void:
	opening_panel = PanelContainer.new()
	opening_panel.name = "OpeningBanner"
	opening_panel.anchor_left = 0.34
	opening_panel.anchor_top = 0.10
	opening_panel.anchor_right = 0.66
	opening_panel.anchor_bottom = 0.21
	opening_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.03, 0.04, 0.83), Color(0.63, 0.48, 0.22, 0.82)))
	add_child(opening_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 10)
	opening_panel.add_child(margin)

	opening_label = Label.new()
	opening_label.name = "GameplayOpeningTypewriter"
	opening_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opening_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opening_label.add_theme_font_size_override("font_size", 15)
	opening_label.add_theme_color_override("font_color", Color(0.91, 0.80, 0.48, 1.0))
	margin.add_child(opening_label)


func _build_pause_overlay() -> void:
	pause_overlay = _make_overlay("PauseOverlay", "PAUSA", "O campo de testes esta suspenso.")
	var stack := pause_overlay.get_node("Margin/Stack") as VBoxContainer

	var resume_button := _make_button("ResumeButton", "Continuar", true)
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	stack.add_child(resume_button)

	var menu_button := _make_button("PauseMenuButton", "Sair para o HUB")
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	stack.add_child(menu_button)

	var quit_button := _make_button("PauseQuitButton", "Encerrar jogo")
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	stack.add_child(quit_button)


func _build_death_overlay() -> void:
	death_overlay = _make_overlay("DeathOverlay", "FALHA", "A memoria regrediu. Retorne ao ultimo marco preservado.")
	var stack := death_overlay.get_node("Margin/Stack") as VBoxContainer

	var retry_button := _make_button("RetryButton", "Tentar novamente", true)
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	stack.add_child(retry_button)

	var menu_button := _make_button("DeathMenuButton", "Voltar ao HUB")
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	stack.add_child(menu_button)

	var quit_button := _make_button("DeathQuitButton", "Encerrar jogo")
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	stack.add_child(quit_button)


func _build_completion_overlay() -> void:
	completion_overlay = _make_overlay("CompletionOverlay", "CAMPO CONCLUIDO", "Todos os sistemas essenciais desta area foram validados.")
	var stack := completion_overlay.get_node("Margin/Stack") as VBoxContainer
	completion_body = stack.get_child(1) as Label

	var retry_button := _make_button("CompletionRetryButton", "Testar novamente", true)
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	stack.add_child(retry_button)

	var menu_button := _make_button("CompletionMenuButton", "Voltar ao HUB")
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	stack.add_child(menu_button)


func _build_dialogue_overlay() -> void:
	dialogue_overlay = Control.new()
	dialogue_overlay.name = "DialogueOverlay"
	dialogue_overlay.visible = false
	dialogue_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_overlay.anchor_left = 0.5
	dialogue_overlay.anchor_top = 1.0
	dialogue_overlay.anchor_right = 0.5
	dialogue_overlay.anchor_bottom = 1.0
	dialogue_overlay.offset_left = -DIALOGUE_NATIVE_SIZE.x * 0.5
	dialogue_overlay.offset_top = -DIALOGUE_NATIVE_SIZE.y - 32.0
	dialogue_overlay.offset_right = DIALOGUE_NATIVE_SIZE.x * 0.5
	dialogue_overlay.offset_bottom = -32.0
	add_child(dialogue_overlay)

	dialogue_visual_root = Control.new()
	dialogue_visual_root.name = "DialogueVisualRoot"
	dialogue_visual_root.anchor_right = 1.0
	dialogue_visual_root.anchor_bottom = 1.0
	dialogue_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_overlay.add_child(dialogue_visual_root)

	var frame := NinePatchRect.new()
	frame.name = "DialogueFrame"
	frame.texture = _load_ui_texture(DIALOGUE_FRAME_TEXTURE_PATH)
	frame.set_meta("asset_path", DIALOGUE_FRAME_TEXTURE_PATH)
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.draw_center = true
	frame.set_patch_margin(SIDE_LEFT, 44)
	frame.set_patch_margin(SIDE_TOP, 36)
	frame.set_patch_margin(SIDE_RIGHT, 44)
	frame.set_patch_margin(SIDE_BOTTOM, 36)
	dialogue_visual_root.add_child(frame)

	dialogue_speaker = Label.new()
	dialogue_speaker.name = "DialogueSpeaker"
	dialogue_speaker.offset_left = 218
	dialogue_speaker.offset_top = 50
	dialogue_speaker.offset_right = 440
	dialogue_speaker.offset_bottom = 78
	dialogue_speaker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	dialogue_speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_speaker.add_theme_font_size_override("font_size", 17)
	dialogue_speaker.add_theme_color_override("font_color", Color(0.94, 0.78, 0.46, 1.0))
	dialogue_visual_root.add_child(dialogue_speaker)
	dialogue_title = dialogue_speaker

	dialogue_body = Label.new()
	dialogue_body.name = "DialogueBody"
	dialogue_body.offset_left = 214
	dialogue_body.offset_top = 98
	dialogue_body.offset_right = 772
	dialogue_body.offset_bottom = 190
	dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_body.add_theme_font_size_override("font_size", 16)
	dialogue_body.add_theme_color_override("font_color", Color(0.14, 0.105, 0.075, 1.0))
	dialogue_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_visual_root.add_child(dialogue_body)

	dialogue_counter = Label.new()
	dialogue_counter.name = "DialogueCounter"
	dialogue_counter.offset_left = 214
	dialogue_counter.offset_top = 188
	dialogue_counter.offset_right = 336
	dialogue_counter.offset_bottom = 210
	dialogue_counter.add_theme_font_size_override("font_size", 12)
	dialogue_counter.add_theme_color_override("font_color", Color(0.39, 0.30, 0.20, 0.92))
	dialogue_visual_root.add_child(dialogue_counter)

	dialogue_hint = Label.new()
	dialogue_hint.name = "DialogueHint"
	dialogue_hint.text = "E  continuar"
	dialogue_hint.offset_left = 580
	dialogue_hint.offset_top = 186
	dialogue_hint.offset_right = 760
	dialogue_hint.offset_bottom = 210
	dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_hint.add_theme_font_size_override("font_size", 13)
	dialogue_hint.add_theme_color_override("font_color", Color(0.34, 0.25, 0.16, 0.92))
	dialogue_visual_root.add_child(dialogue_hint)

	dialogue_next_marker = TextureRect.new()
	dialogue_next_marker.name = "DialogueNextMarker"
	dialogue_next_marker.texture = _load_ui_texture(DIALOGUE_NEXT_MARKER_TEXTURE_PATH)
	dialogue_next_marker.offset_left = 770
	dialogue_next_marker.offset_top = 182
	dialogue_next_marker.offset_right = 810
	dialogue_next_marker.offset_bottom = 220
	dialogue_next_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_next_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_next_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_next_marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dialogue_next_marker.visible = false
	dialogue_visual_root.add_child(dialogue_next_marker)


func _load_ui_texture(texture_path: String) -> Texture2D:
	var imported_texture := load(texture_path) as Texture2D
	if imported_texture != null:
		return imported_texture

	var image := Image.new()
	var error := image.load(texture_path)
	if error != OK:
		push_warning("UI texture could not be loaded: %s" % texture_path)
		return null
	return ImageTexture.create_from_image(image)


func _play_dialogue_open_transition() -> void:
	if dialogue_visual_root == null:
		return
	dialogue_visual_root.pivot_offset = dialogue_visual_root.size * Vector2(0.5, 1.0)
	dialogue_visual_root.position.y = DIALOGUE_OPEN_OFFSET_Y
	dialogue_visual_root.scale = Vector2(0.985, 0.96)
	dialogue_visual_root.modulate.a = 0.0
	_dialogue_transition_tween = create_tween()
	_dialogue_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_dialogue_transition_tween.set_parallel(true)
	_dialogue_transition_tween.tween_property(dialogue_visual_root, "position:y", 0.0, DIALOGUE_OPEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_dialogue_transition_tween.tween_property(dialogue_visual_root, "scale", Vector2.ONE, DIALOGUE_OPEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_dialogue_transition_tween.tween_property(dialogue_visual_root, "modulate:a", 1.0, DIALOGUE_OPEN_DURATION * 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _begin_dialogue_close_transition() -> void:
	if _dialogue_closing:
		return
	_dialogue_closing = true
	_dialogue_typing = false
	_dialogue_close_elapsed = 0.0
	_dialogue_close_frames = 0
	get_tree().paused = _dialogue_previous_paused
	if dialogue_next_marker != null:
		dialogue_next_marker.visible = false
	_kill_dialogue_transition()
	if dialogue_visual_root == null:
		_finish_dialogue_close()
		return
	dialogue_visual_root.pivot_offset = dialogue_visual_root.size * Vector2(0.5, 1.0)
	_dialogue_transition_tween = create_tween()
	_dialogue_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_dialogue_transition_tween.set_parallel(true)
	_dialogue_transition_tween.tween_property(dialogue_visual_root, "position:y", DIALOGUE_OPEN_OFFSET_Y, DIALOGUE_CLOSE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_dialogue_transition_tween.tween_property(dialogue_visual_root, "scale", Vector2(0.99, 0.965), DIALOGUE_CLOSE_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_dialogue_transition_tween.tween_property(dialogue_visual_root, "modulate:a", 0.0, DIALOGUE_CLOSE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_dialogue_transition_tween.chain().tween_callback(_finish_dialogue_close)


func _update_dialogue_transition(delta: float) -> void:
	if not _dialogue_closing:
		return
	_dialogue_close_elapsed += delta
	_dialogue_close_frames += 1
	if _dialogue_close_elapsed >= DIALOGUE_CLOSE_DURATION + 0.05 or _dialogue_close_frames >= 16:
		_finish_dialogue_close()


func _finish_dialogue_close() -> void:
	if not _dialogue_closing and dialogue_overlay != null and not dialogue_overlay.visible:
		return
	_kill_dialogue_transition()
	if dialogue_overlay != null:
		dialogue_overlay.visible = false
	if dialogue_visual_root != null:
		dialogue_visual_root.position.y = 0.0
		dialogue_visual_root.scale = Vector2.ONE
		dialogue_visual_root.modulate.a = 1.0
	_dialogue_closing = false
	_dialogue_close_elapsed = 0.0
	_dialogue_close_frames = 0
	prompt_panel.visible = not prompt_label.text.is_empty()
	get_tree().paused = _dialogue_previous_paused
	dialogue_closed.emit()


func _kill_dialogue_transition() -> void:
	if _dialogue_transition_tween != null and _dialogue_transition_tween.is_valid():
		_dialogue_transition_tween.kill()
	_dialogue_transition_tween = null


func _make_overlay(node_name: String, title_text: String, body_text: String) -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.name = node_name
	overlay.visible = false
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.anchor_left = 0.35
	overlay.anchor_top = 0.24
	overlay.anchor_right = 0.65
	overlay.anchor_bottom = 0.76
	overlay.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.03, 0.04, 0.97), Color(0.72, 0.54, 0.24, 1.0)))
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	overlay.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", 13)
	margin.add_child(stack)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.93, 0.77, 0.38, 1.0))
	stack.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.80, 0.80, 0.72, 1.0))
	stack.add_child(body)
	return overlay


func _make_button(node_name: String, text: String, primary := false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(240, 42)
	button.add_theme_font_size_override("font_size", 15)
	var border := Color(0.68, 0.51, 0.23, 1.0)
	var background := Color(0.055, 0.07, 0.075, 1.0)
	if primary:
		border = Color(0.31, 0.90, 0.88, 1.0)
		background = Color(0.035, 0.17, 0.18, 1.0)
	button.add_theme_stylebox_override("normal", _panel_style(background, border))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.04, 0.23, 0.23, 1.0), Color(0.43, 0.98, 0.94, 1.0)))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.02, 0.11, 0.12, 1.0), Color(0.93, 0.72, 0.31, 1.0)))
	button.add_theme_color_override("font_color", Color(0.92, 0.86, 0.70, 1.0))
	button.focus_entered.connect(func() -> void: _audio_ui("select"))
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			_audio_ui("select")
	)
	button.pressed.connect(func() -> void: _audio_ui("confirm"))
	return button


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style


func _bar_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(background, border)
	style.set_corner_radius_all(2)
	return style


func _ensure_health_heart_count(heart_count: int) -> void:
	if health_hearts == null:
		return
	var safe_count := maxi(0, heart_count)
	while health_heart_nodes.size() < safe_count:
		var heart := TextureRect.new()
		heart.name = "Heart%d" % (health_heart_nodes.size() + 1)
		heart.texture = load(HEART_TEXTURE_PATH)
		heart.custom_minimum_size = Vector2(24, 24)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		health_hearts.add_child(heart)
		health_heart_nodes.append(heart)
	while health_heart_nodes.size() > safe_count:
		var heart: TextureRect = health_heart_nodes.pop_back()
		health_hearts.remove_child(heart)
		heart.queue_free()


func _update_opening_text(delta: float) -> void:
	if opening_label == null or opening_label.text.length() >= _opening_text.length():
		return

	_opening_elapsed += delta
	var visible_count := mini(_opening_text.length(), int(_opening_elapsed * _text_speed()))
	opening_label.text = _opening_text.left(visible_count)

	if visible_count >= _opening_text.length():
		var tween := create_tween()
		tween.tween_interval(2.5)
		tween.tween_property(opening_label.get_parent().get_parent(), "modulate:a", 0.0, 0.8)


func _update_message_text(delta: float) -> void:
	if message_label == null or _message_text.is_empty():
		return

	if message_label.text.length() < _message_text.length():
		_message_elapsed += delta
		var visible_count := mini(_message_text.length(), int(_message_elapsed * _text_speed()))
		message_label.text = _message_text.left(visible_count)
		return

	_message_hold_seconds -= delta
	if _message_hold_seconds <= 0.0:
		message_label.get_parent().get_parent().visible = false
		_message_text = ""


func _update_dialogue_text(delta: float) -> void:
	if not _dialogue_typing or dialogue_body == null:
		return
	_dialogue_character_elapsed += delta
	var visible_count := mini(
		_dialogue_line_text.length(),
		int(_dialogue_character_elapsed * maxf(_text_speed(), 24.0))
	)
	dialogue_body.visible_characters = visible_count
	if visible_count >= _dialogue_last_tick_character + 3:
		_dialogue_last_tick_character = visible_count
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.play_ui("dialogue_tick")
	if visible_count >= _dialogue_line_text.length():
		complete_dialogue_line()


func _text_speed() -> float:
	var settings: Node = get_node_or_null("/root/GameSettings")
	return float(settings.get("text_speed")) if settings != null else 36.0


func _audio_ui(cue: StringName) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_ui(cue)
