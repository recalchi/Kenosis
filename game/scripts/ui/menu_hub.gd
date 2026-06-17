extends Control
class_name MenuHub

# ============================================================
#  MENU HUB — Kenosis
#
#  Layout reconstruido sobre uma grade de referencia 1280x720
#  (mesma base de window/stretch do project.godot). As molduras
#  NAO sao esticadas por NinePatch: cada painel e dimensionado
#  pela proporcao NATIVA da textura e desenhado com
#  TextureRect KEEP_ASPECT — assim cantos, gemas e ornamentos
#  nunca distorcem. O conteudo vive dentro de MarginContainers
#  com padding consistente. Topos e bases dos dois paineis ficam
#  alinhados na mesma linha.
# ============================================================

const MENU_ASSET_ROOT := "res://assets/ui/menu"

# Grade de referencia (bate com display/window/size do projeto).
const DESIGN_W := 1280.0
const DESIGN_H := 720.0

# Proporcoes nativas (manifest.json dos assets).
const LEFT_FRAME_RATIO := 823.0 / 1272.0     # moldura_vertical_grande
const RIGHT_PANEL_RATIO := 1267.0 / 984.0    # painel_opcoes_abas

# Geometria base dos paineis (px na grade 1280x720).
const PANEL_TOP := 128.0
const PANEL_HEIGHT := 580.0
const PANEL_GAP := 30.0

const MAIN_BUTTON_SIZE := Vector2(198, 78)
const SUBMENU_BUTTON_SIZE := Vector2(270, 86)
const SMALL_BUTTON_SIZE := Vector2(168, 68)

const CONFIG_FALLBACK := {
	"title": "KENOSIS",
	"subtitle": "A memoria insiste onde o vazio tenta apagar.",
	"season_label": "PROTOTIPO JOGAVEL",
	"opening_text": "Escolha seu ponto de entrada. A Ressonancia muda o cenario, mas a memoria decide o caminho.",
	"footer": "Sprint 0.1 | PC-first | Godot 4.6",
	"primary_menu": [],
	"submenus": {},
	"settings_tabs": []
}

@export var menu_config_path := "res://data/config/menu_hub.json"
@export var test_room_path := "res://scenes/levels/TestRoom.tscn"
@export var map_test_room_path := "res://scenes/levels/MapTestRoom.tscn"
@export var story_start_path := "res://scenes/levels/locations/Awakening.tscn"

var tutorial_panel: Control
var settings_panel: Control
var map_selection_panel: Control
var opening_label: Label

var _menu_config: Dictionary = {}
var _opening_text := ""
var _opening_elapsed := 0.0
var _opening_finished := false
var _submenu_title: Label
var _submenu_description: Label
var _submenu_items_stack: VBoxContainer
var _submenu_stack: VBoxContainer
var _right_panel: Control
var _right_content_inset := Vector4(46, 128, 46, 44)  # left, top, right, bottom
var _active_submenu_id := ""
var _setting_controls: Dictionary = {}
var _settings_tab_buttons: Dictionary = {}
var _settings_tab_pages: Dictionary = {}
var _right_tab_buttons: Dictionary = {}
var _right_tabs_root: Control
var _map_items_grid: GridContainer
var _animated_details: Array[Control] = []

# Geometria calculada em _ready (px na grade base).
var _left_rect := Rect2()
var _right_rect := Rect2()


func _ready() -> void:
	theme = load("res://assets/ui/themes/kenosis_theme.tres")
	_menu_config = _load_menu_config()
	_opening_text = String(_menu_config.get("opening_text", CONFIG_FALLBACK["opening_text"]))
	_compute_layout()
	_set_full_rect(self)
	_build_background()
	_build_header()
	_build_menu_shell()
	_build_tutorial_panel()
	_build_settings_panel()
	_build_map_selection_panel()
	_hide_right_panel()


func _process(delta: float) -> void:
	_update_opening_text(delta)
	_update_menu_details()


# Calcula os retangulos dos dois paineis mantendo a proporcao nativa
# de cada moldura e centralizando o conjunto horizontalmente.
func _compute_layout() -> void:
	var left_w := PANEL_HEIGHT * LEFT_FRAME_RATIO
	var right_w := PANEL_HEIGHT * RIGHT_PANEL_RATIO
	var group_w := left_w + PANEL_GAP + right_w
	var side_margin := maxf((DESIGN_W - group_w) * 0.5, 40.0)
	var left_x := side_margin
	var right_x := left_x + left_w + PANEL_GAP
	_left_rect = Rect2(left_x, PANEL_TOP, left_w, PANEL_HEIGHT)
	_right_rect = Rect2(right_x, PANEL_TOP, right_w, PANEL_HEIGHT)


func show_tutorial() -> void:
	_show_right_panel()
	_configure_play_tabs()
	if _submenu_stack != null:
		_submenu_stack.visible = false
	if settings_panel != null:
		settings_panel.visible = false
	if map_selection_panel != null:
		map_selection_panel.visible = false
	tutorial_panel.visible = true
	_audio_ui("open")


func hide_tutorial() -> void:
	tutorial_panel.visible = false
	_show_right_page("entry")
	_audio_ui("close")


func show_settings() -> void:
	_show_right_panel()
	_configure_settings_tabs()
	tutorial_panel.visible = false
	_show_right_page("config")
	_select_settings_tab("general")
	_audio_ui("select")


func hide_settings() -> void:
	settings_panel.visible = false
	if _active_submenu_id != "":
		_configure_play_tabs()
		_show_right_page("entry")
	else:
		_hide_right_panel()
	_audio_ui("select")


func start_game() -> void:
	get_tree().change_scene_to_file(test_room_path)


func start_map_test() -> void:
	get_tree().change_scene_to_file(map_test_room_path)


func start_story() -> void:
	var save_system := get_node_or_null("/root/SaveSystem")
	var target_path := story_start_path
	if save_system != null:
		var current_location: StringName = save_system.get_current_location()
		var registry := get_node_or_null("/root/DataRegistry")
		if registry != null:
			var levels: Dictionary = registry.get_section(&"levels")
			var profile: Dictionary = levels.get("story_locations", {}).get(String(current_location), {})
			target_path = String(profile.get("scene", story_start_path))
	get_tree().change_scene_to_file(target_path)


func quit_game() -> void:
	get_tree().quit()


func _build_background() -> void:
	var background := TextureRect.new()
	background.name = "MenuBackground"
	background.texture = load("res://assets/sprites/backgrounds/day/menu_field_background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(background)
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "BackgroundShade"
	shade.color = Color(0.014, 0.018, 0.026, 0.58)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(shade)
	add_child(shade)

	var horizon := ColorRect.new()
	horizon.name = "HorizonShade"
	horizon.color = Color(0.03, 0.012, 0.045, 0.42)
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizon.anchor_left = 0.0
	horizon.anchor_top = 0.0
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 0.42
	add_child(horizon)

	var lower_vignette := ColorRect.new()
	lower_vignette.name = "LowerVignette"
	lower_vignette.color = Color(0.018, 0.020, 0.024, 0.80)
	lower_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lower_vignette.anchor_left = 0.0
	lower_vignette.anchor_top = 0.64
	lower_vignette.anchor_right = 1.0
	lower_vignette.anchor_bottom = 1.0
	add_child(lower_vignette)


func _build_header() -> void:
	var left_x := _left_rect.position.x

	var logo := TextureRect.new()
	logo.name = "MenuLogo"
	logo.texture = load("res://assets/ui/reference/kenosis_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.modulate = Color(1.0, 0.95, 0.80, 1.0)
	_rect(logo, left_x, 24, 320, 84)
	add_child(logo)

	var subtitle := Label.new()
	subtitle.name = "MenuSubtitle"
	subtitle.text = String(_menu_config.get("subtitle", CONFIG_FALLBACK["subtitle"]))
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.79, 0.64, 0.95))
	_rect(subtitle, left_x + 2, 112, 560, 26)
	add_child(subtitle)


func _build_menu_shell() -> void:
	# ── Painel esquerdo (menu principal) ──
	var main_panel := _make_frame_panel("MainMenuPanel", "frames/moldura_vertical_grande.png", _left_rect)
	add_child(main_panel)

	var main_margin := _panel_margin(32, 40, 32, 42)
	main_panel.add_child(main_margin)

	var main_stack := VBoxContainer.new()
	main_stack.name = "MainMenuStack"
	main_stack.add_theme_constant_override("separation", 3)
	main_margin.add_child(main_stack)

	var tag := Label.new()
	tag.name = "TestFieldNote"
	tag.text = String(_menu_config.get("season_label", CONFIG_FALLBACK["season_label"]))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(0.47, 0.95, 0.93, 1.0))
	main_stack.add_child(tag)

	opening_label = Label.new()
	opening_label.name = "OpeningTypewriter"
	opening_label.text = ""
	opening_label.custom_minimum_size = Vector2(0, 76)
	opening_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opening_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opening_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	opening_label.add_theme_font_size_override("font_size", 12)
	opening_label.add_theme_color_override("font_color", Color(0.91, 0.85, 0.70, 1.0))
	main_stack.add_child(opening_label)
	opening_label.text = _opening_text
	_opening_finished = true

	main_stack.add_child(_make_divider())

	var buttons_box := VBoxContainer.new()
	buttons_box.name = "MainButtons"
	buttons_box.add_theme_constant_override("separation", 0)
	buttons_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buttons_box.alignment = BoxContainer.ALIGNMENT_CENTER
	main_stack.add_child(buttons_box)

	for item: Dictionary in _menu_config.get("primary_menu", []):
		var primary_node_name := "Main%sButton" % String(item.get("id", "")).capitalize()
		var action := String(item.get("action", ""))
		if action == "tutorial":
			primary_node_name = "TutorialButton"
		elif action == "settings":
			primary_node_name = "SettingsButton"
		var menu_button := _make_menu_button(primary_node_name, String(item.get("label", "")), false)
		menu_button.tooltip_text = String(item.get("caption", ""))
		var submenu_id := String(item.get("submenu", ""))
		menu_button.pressed.connect(func() -> void: _handle_primary_item(submenu_id, action))
		buttons_box.add_child(menu_button)

	# Rodape abaixo do painel esquerdo.
	var footer := Label.new()
	footer.name = "MenuFooter"
	footer.text = String(_menu_config.get("footer", CONFIG_FALLBACK["footer"]))
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.62, 0.65, 0.64, 0.92))
	_rect(footer, _left_rect.position.x + 4, PANEL_TOP + PANEL_HEIGHT + 6, 360, 22)
	add_child(footer)

	# ── Painel direito (abas Entrada/Config) ──
	var submenu_panel := _make_frame_panel("SubMenuPanel", "frames/painel_opcoes_abas.png", _right_rect)
	add_child(submenu_panel)
	_right_panel = submenu_panel

	_build_right_panel_tabs(submenu_panel)

	var submenu_margin := _panel_margin(
		int(_right_content_inset.x), int(_right_content_inset.y),
		int(_right_content_inset.z), int(_right_content_inset.w)
	)
	submenu_panel.add_child(submenu_margin)

	var submenu_stack := VBoxContainer.new()
	submenu_stack.name = "SubMenuStack"
	submenu_stack.add_theme_constant_override("separation", 12)
	submenu_margin.add_child(submenu_stack)
	_submenu_stack = submenu_stack

	_submenu_description = Label.new()
	_submenu_description.name = "SubMenuDescription"
	_submenu_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_submenu_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_submenu_description.add_theme_font_size_override("font_size", 16)
	_submenu_description.add_theme_color_override("font_color", Color(0.81, 0.77, 0.65, 1.0))
	submenu_stack.add_child(_submenu_description)

	# Titulo do submenu mantido como dado interno (oculto: a aba ja rotula).
	_submenu_title = Label.new()
	_submenu_title.name = "SubMenuTitle"
	_submenu_title.visible = false
	submenu_stack.add_child(_submenu_title)

	submenu_stack.add_child(_make_divider())

	var items_holder := CenterContainer.new()
	items_holder.name = "SubMenuItemsHolder"
	items_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	submenu_stack.add_child(items_holder)

	_submenu_items_stack = VBoxContainer.new()
	_submenu_items_stack.name = "SubMenuItems"
	_submenu_items_stack.add_theme_constant_override("separation", 1)
	items_holder.add_child(_submenu_items_stack)


func _build_tutorial_panel() -> void:
	# Tutorial vive dentro do painel direito (terceira pagina).
	tutorial_panel = Control.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_full_rect(tutorial_panel)
	tutorial_panel.visible = false
	_right_panel.add_child(tutorial_panel)

	var margin := _panel_margin(
		int(_right_content_inset.x), int(_right_content_inset.y),
		int(_right_content_inset.z), int(_right_content_inset.w)
	)
	tutorial_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	stack.add_child(_modal_title("CAMPO DE TESTES"))

	var body := Label.new()
	body.name = "TutorialText"
	body.text = "Objetivo: use a Ressonancia para transformar o cenario, atravesse a ameaca e alcance a saida.\n\nA / D - mover\nEspaco - pular\nE - interagir, ler cicatrizes e preservar memoria\nF - canalizar Ressonancia\nShift ou C - ocultar assinatura dentro de coberturas\nM ou Tab - abrir mapa\nEsc - pausar\n\nAtive a ponte, leia a cicatriz e desate a corrupcao do Patrulheiro pelas costas. Contato frontal causa falha e regressao de pontos."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.91, 0.86, 0.72, 1.0))
	stack.add_child(body)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	stack.add_child(actions)

	var close_button := _make_small_button("TutorialCloseButton", "Fechar")
	close_button.pressed.connect(hide_tutorial)
	actions.add_child(close_button)


func _build_settings_panel() -> void:
	settings_panel = Control.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_full_rect(settings_panel)
	settings_panel.visible = false
	_right_panel.add_child(settings_panel)

	var margin := _panel_margin(
		int(_right_content_inset.x), int(_right_content_inset.y),
		int(_right_content_inset.z), int(_right_content_inset.w)
	)
	settings_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", 14)
	margin.add_child(stack)

	var pages := Control.new()
	pages.name = "SettingsPages"
	pages.custom_minimum_size = Vector2(0, 282)
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(pages)

	for tab: Dictionary in _menu_config.get("settings_tabs", []):
		var tab_id := String(tab.get("id", ""))
		var page := VBoxContainer.new()
		page.name = "SettingsPage%s" % tab_id.capitalize()
		page.visible = false
		page.add_theme_constant_override("separation", 12)
		_set_full_rect(page)
		pages.add_child(page)
		_settings_tab_pages[tab_id] = page
		_build_settings_rows(page, tab.get("rows", []))

	var actions := HBoxContainer.new()
	actions.name = "SettingsActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	stack.add_child(actions)

	var save_button := _make_small_button("SaveSettingsButton", "Aplicar")
	save_button.pressed.connect(_apply_settings_from_controls)
	actions.add_child(save_button)

	var cancel_button := _make_small_button("CancelSettingsButton", "Cancelar")
	cancel_button.pressed.connect(hide_settings)
	actions.add_child(cancel_button)


func _build_map_selection_panel() -> void:
	map_selection_panel = Control.new()
	map_selection_panel.name = "MapSelectionPanel"
	map_selection_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_full_rect(map_selection_panel)
	map_selection_panel.visible = false
	_right_panel.add_child(map_selection_panel)

	var margin := _panel_margin(
		int(_right_content_inset.x), int(_right_content_inset.y),
		int(_right_content_inset.z), int(_right_content_inset.w)
	)
	map_selection_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)

	var description := Label.new()
	description.name = "MapSelectionDescription"
	description.text = "Escolha a fase/cena para projetar no mapa. O mapa da aventura mostra a regiao, a ameaca e a cena ligada ao ponto."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color(0.81, 0.77, 0.65, 1.0))
	stack.add_child(description)

	stack.add_child(_make_divider())

	var scroll := ScrollContainer.new()
	scroll.name = "MapSelectionScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)

	_map_items_grid = GridContainer.new()
	_map_items_grid.name = "MapSelectionGrid"
	_map_items_grid.columns = 2
	_map_items_grid.add_theme_constant_override("h_separation", 8)
	_map_items_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_map_items_grid)
	_populate_map_selection()


func _build_settings_rows(page: VBoxContainer, rows: Array) -> void:
	for row_id_variant: Variant in rows:
		var row_id := String(row_id_variant)
		match row_id:
			"master_volume":
				_add_setting_slider(page, row_id, "Volume geral", _setting_float("master_volume", 0.8), 0.0, 1.0, 0.05)
			"music_volume":
				_add_setting_slider(page, row_id, "Musica", _setting_float("music_volume", 0.7), 0.0, 1.0, 0.05)
			"sfx_volume":
				_add_setting_slider(page, row_id, "Efeitos sonoros", _setting_float("sfx_volume", 0.85), 0.0, 1.0, 0.05)
			"text_speed":
				_add_setting_slider(page, row_id, "Velocidade do texto", _setting_float("text_speed", 36.0), 16.0, 80.0, 1.0)
			"fullscreen":
				_add_setting_toggle(page, row_id, "Tela cheia", _setting_bool("fullscreen", false))
			"vsync_enabled":
				_add_setting_toggle(page, row_id, "VSync", _setting_bool("vsync_enabled", true))
			"tutorials_enabled":
				_add_setting_toggle(page, row_id, "Mostrar tutoriais", _setting_bool("tutorials_enabled", true))
			"move":
				_add_control_hint(page, "Movimento", "A / D")
			"jump":
				_add_control_hint(page, "Pular", "Espaco")
			"interact":
				_add_control_hint(page, "Interagir", "E")
			"resonance":
				_add_control_hint(page, "Ressonancia", "F")
			"stealth":
				_add_control_hint(page, "Furtividade", "Shift / C")
			"world_map":
				_add_control_hint(page, "Mapa", "M / Tab")


func _populate_map_selection() -> void:
	if _map_items_grid == null:
		return

	_clear_children(_map_items_grid)
	var levels := _levels_config()
	var destinations: Array = levels.get("map_destinations", [])
	var story_locations: Dictionary = levels.get("story_locations", {})
	for destination_variant: Variant in destinations:
		if not destination_variant is Dictionary:
			continue
		var destination := destination_variant as Dictionary
		var id := String(destination.get("id", ""))
		if id == "":
			continue
		var region := String(destination.get("region", ""))
		var index := int(destination.get("index", 0))
		var story_profile: Dictionary = story_locations.get(id, {})
		var scene_path := String(story_profile.get("scene", map_test_room_path))
		var label := "%02d  %s" % [index, String(destination.get("name", id))]
		var caption := "%s  |  %s" % [region.to_upper(), String(story_profile.get("enemy", "ameaca"))]
		var button := _make_map_destination_button(id, label, caption, scene_path)
		_map_items_grid.add_child(button)


func _make_map_destination_button(destination_id: String, label: String, caption: String, scene_path: String) -> Button:
	var button := Button.new()
	button.name = "MapDestination%sButton" % destination_id.to_pascal_case()
	button.text = "%s\n%s" % [label.to_upper(), caption]
	button.custom_minimum_size = Vector2(292, 70)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.tooltip_text = "Projetar %s" % label
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.47, 1.0, 0.95, 1.0))
	_apply_button_styles(button, "pequeno")
	button.pressed.connect(func() -> void: _start_map_destination(scene_path))
	_wire_button_audio(button)
	return button


func _start_map_destination(scene_path: String) -> void:
	var target := scene_path if ResourceLoader.exists(scene_path) else map_test_room_path
	get_tree().change_scene_to_file(target)


func _add_setting_slider(page: VBoxContainer, setting_key: String, label_text: String, value: float, minimum: float, maximum: float, step: float) -> void:
	var row := HBoxContainer.new()
	row.name = "%sRow" % setting_key.capitalize()
	row.add_theme_constant_override("separation", 16)
	page.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(210, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.72, 1.0))
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "%sSlider" % setting_key.capitalize()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = clampf(value, minimum, maximum)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(0, 34)
	_apply_slider_styles(slider)
	slider.drag_ended.connect(func(_value_changed: bool) -> void: _audio_ui("select"))
	row.add_child(slider)

	var value_label := Label.new()
	value_label.name = "%sValue" % setting_key.capitalize()
	value_label.custom_minimum_size = Vector2(58, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.72, 1.0))
	row.add_child(value_label)
	slider.value_changed.connect(func(_new_value: float) -> void: _update_slider_value_label(slider, value_label))
	_update_slider_value_label(slider, value_label)

	_setting_controls[setting_key] = slider


func _add_setting_toggle(page: VBoxContainer, setting_key: String, label_text: String, enabled: bool) -> void:
	var row := HBoxContainer.new()
	row.name = "%sRow" % setting_key.capitalize()
	row.add_theme_constant_override("separation", 16)
	page.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(210, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.72, 1.0))
	row.add_child(label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var toggle := Button.new()
	toggle.name = "%sToggle" % setting_key.capitalize()
	toggle.toggle_mode = true
	toggle.button_pressed = enabled
	toggle.custom_minimum_size = Vector2(116, 44)
	toggle.text = "LIGADO" if enabled else "DESL."
	toggle.add_theme_font_size_override("font_size", 12)
	toggle.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68, 1.0))
	_apply_toggle_styles(toggle)
	toggle.toggled.connect(func(pressed: bool) -> void:
		toggle.text = "LIGADO" if pressed else "DESL."
		_audio_ui("select")
	)
	row.add_child(toggle)
	_setting_controls[setting_key] = toggle


func _add_control_hint(page: VBoxContainer, label_text: String, binding_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	page.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(210, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.91, 0.86, 0.72, 1.0))
	row.add_child(label)

	var binding := Label.new()
	binding.text = binding_text
	binding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	binding.add_theme_font_size_override("font_size", 16)
	binding.add_theme_color_override("font_color", Color(0.47, 0.95, 0.93, 1.0))
	row.add_child(binding)


func _select_submenu(submenu_id: String) -> void:
	var submenus: Dictionary = _menu_config.get("submenus", {})
	var submenu: Dictionary = submenus.get(submenu_id, {})
	if submenu.is_empty():
		return

	_active_submenu_id = submenu_id
	_show_right_panel()
	_configure_play_tabs()
	_show_right_page("entry")
	_submenu_title.text = String(submenu.get("title", ""))
	_submenu_description.text = String(submenu.get("description", ""))
	_clear_children(_submenu_items_stack)

	for item: Dictionary in submenu.get("items", []):
		var node_name := String(item.get("node_name", "SubMenuButton"))
		var label := String(item.get("label", ""))
		var caption := String(item.get("caption", ""))
		var action := String(item.get("action", ""))
		var disabled := bool(item.get("disabled", false))
		var entry := VBoxContainer.new()
		entry.name = "%sEntry" % node_name
		entry.add_theme_constant_override("separation", 0)
		var button := _make_submenu_button(node_name, label, caption, bool(item.get("primary", false)))
		button.disabled = disabled
		if not disabled and action != "":
			button.pressed.connect(func() -> void: _handle_action(action))
		entry.add_child(button)

		var caption_label := Label.new()
		caption_label.text = caption
		caption_label.add_theme_font_size_override("font_size", 10)
		caption_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.56, 1.0))
		caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entry.add_child(caption_label)
		_submenu_items_stack.add_child(entry)


func _select_settings_tab(tab_id: String) -> void:
	for id: String in _settings_tab_pages.keys():
		var page := _settings_tab_pages[id] as Control
		page.visible = id == tab_id
		if _settings_tab_buttons.has(id):
			var button := _settings_tab_buttons[id] as Button
			button.button_pressed = id == tab_id


func _build_right_panel_tabs(panel: Control) -> void:
	_right_tabs_root = Control.new()
	_right_tabs_root.name = "RightPanelTabs"
	_right_tabs_root.z_index = 20
	_right_tabs_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(_right_tabs_root)
	panel.add_child(_right_tabs_root)


func _show_right_page(page_id: String) -> void:
	_show_right_panel()
	if tutorial_panel != null:
		tutorial_panel.visible = false
	if _submenu_stack != null:
		_submenu_stack.visible = page_id == "entry"
	if settings_panel != null:
		settings_panel.visible = page_id == "config"
	if map_selection_panel != null:
		map_selection_panel.visible = page_id == "map"
	for id: String in _right_tab_buttons.keys():
		var button := _right_tab_buttons[id] as Button
		button.button_pressed = id == page_id


func _show_right_panel() -> void:
	if _right_panel != null:
		_right_panel.visible = true


func _hide_right_panel() -> void:
	if _right_panel != null:
		_right_panel.visible = false
	if tutorial_panel != null:
		tutorial_panel.visible = false
	if settings_panel != null:
		settings_panel.visible = false
	if map_selection_panel != null:
		map_selection_panel.visible = false


func _configure_play_tabs() -> void:
	_settings_tab_buttons.clear()
	_render_right_tabs([
		{"id": "entry", "name": "RightTabEntry", "label": "Entrada", "callback": func() -> void: _show_right_page("entry")},
		{"id": "map", "name": "RightTabMap", "label": "Mapas", "callback": func() -> void: _show_right_page("map")},
		{"id": "story", "name": "RightTabStory", "label": "Jornada", "callback": func() -> void: start_story()},
	])


func _configure_settings_tabs() -> void:
	_right_tab_buttons.clear()
	var tabs: Array[Dictionary] = []
	for tab: Dictionary in _menu_config.get("settings_tabs", []):
		var tab_id := String(tab.get("id", ""))
		var captured_tab_id := tab_id
		tabs.append({
			"id": tab_id,
			"name": "SettingsTab%s" % tab_id.capitalize(),
			"label": String(tab.get("label", tab_id)),
			"callback": func() -> void: _select_settings_tab(captured_tab_id),
		})
	_render_right_tabs(tabs)
	for id: String in _right_tab_buttons.keys():
		_settings_tab_buttons[id] = _right_tab_buttons[id]


func _render_right_tabs(tabs: Array[Dictionary]) -> void:
	if _right_tabs_root == null:
		return

	_clear_children(_right_tabs_root)
	_right_tab_buttons.clear()
	if _right_panel != null:
		_right_panel.move_child(_right_tabs_root, _right_panel.get_child_count() - 1)
	var slots := [
		Rect2(0.075, 0.030, 0.178, 0.150),
		Rect2(0.280, 0.030, 0.165, 0.150),
		Rect2(0.480, 0.030, 0.165, 0.150),
		Rect2(0.680, 0.030, 0.165, 0.150),
	]

	for index in range(slots.size()):
		if index < tabs.size():
			var tab: Dictionary = tabs[index]
			var id := String(tab.get("id", "tab_%d" % index))
			var button := _make_right_tab_button(String(tab.get("name", "RightTab%d" % index)), String(tab.get("label", "")))
			_panel_anchor_rect(button, slots[index])
			var callback: Callable = tab.get("callback", Callable())
			if callback.is_valid():
				button.pressed.connect(callback)
			_right_tabs_root.add_child(button)
			_right_tab_buttons[id] = button
		else:
			var decor := _make_right_tab_button("RightTabDecor%d" % index, "")
			decor.disabled = true
			_make_button_visuals_transparent(decor)
			_panel_anchor_rect(decor, slots[index])
			_right_tabs_root.add_child(decor)


func _handle_primary_item(submenu_id: String, action: String) -> void:
	if submenu_id != "":
		_select_submenu(submenu_id)
		_audio_ui("select")
		return

	if action != "":
		_handle_action(action)


func _handle_action(action: String) -> void:
	match action:
		"start_game":
			start_game()
		"start_map_test":
			start_map_test()
		"show_map_select":
			_configure_play_tabs()
			_show_right_page("map")
		"start_story":
			start_story()
		"tutorial":
			show_tutorial()
		"settings":
			show_settings()
		"quit":
			quit_game()


func _apply_settings_from_controls() -> void:
	var current := _settings()
	if current == null:
		hide_settings()
		return

	for key: String in _setting_controls.keys():
		var control: Variant = _setting_controls[key]
		if control is HSlider:
			current.set(key, (control as HSlider).value)
		elif control is BaseButton:
			current.set(key, (control as BaseButton).button_pressed)

	current.call("commit")
	hide_settings()


func _update_opening_text(delta: float) -> void:
	if _opening_finished or opening_label == null:
		return

	_opening_elapsed += delta
	var characters_per_second := _setting_float("text_speed", 36.0)
	var visible_count := mini(_opening_text.length(), int(_opening_elapsed * characters_per_second))
	opening_label.text = _opening_text.left(visible_count)
	_opening_finished = visible_count >= _opening_text.length()


func _update_menu_details() -> void:
	var pulse := 0.96 + (sin(Time.get_ticks_msec() * 0.002) * 0.055)
	for detail: Control in _animated_details:
		detail.modulate = Color(pulse, pulse, pulse, detail.modulate.a)


func _make_menu_button(node_name: String, label: String, primary := false, style_kind := "lateral") -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label.to_upper()
	button.custom_minimum_size = MAIN_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.94, 0.86, 0.66, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.99, 0.93, 0.74, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.47, 1.0, 0.95, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.50, 0.49, 0.45, 0.78))
	_apply_button_styles(button, style_kind)
	_wire_button_audio(button)
	return button


func _make_submenu_button(node_name: String, label: String, caption: String, primary := false) -> Button:
	var button := _make_menu_button(node_name, label, primary, "principal")
	button.custom_minimum_size = SUBMENU_BUTTON_SIZE
	button.tooltip_text = caption
	button.add_theme_font_size_override("font_size", 16)
	return button


func _make_small_button(node_name: String, label: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label.to_upper()
	button.custom_minimum_size = SMALL_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.94, 0.86, 0.66, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.99, 0.93, 0.74, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.47, 1.0, 0.95, 1.0))
	_apply_button_styles(button, "pequeno")
	_wire_button_audio(button)
	return button


func _make_tab_button(node_name: String, label: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label.to_upper()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(118, 34)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.80, 0.74, 0.60, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.47, 1.0, 0.95, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.97, 0.91, 0.71, 1.0))
	var transparent := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", transparent)
	button.add_theme_stylebox_override("pressed", transparent)
	button.add_theme_stylebox_override("disabled", transparent)
	_wire_button_audio(button)
	return button


func _make_right_tab_button(node_name: String, label: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label.to_upper()
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.86, 0.78, 0.56, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.47, 1.0, 0.95, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.97, 0.91, 0.71, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.50, 0.45, 0.35, 0.0))
	_apply_header_tab_styles(button)
	_wire_button_audio(button)
	return button


func _apply_button_styles(button: Button, kind: String) -> void:
	match kind:
		"lateral":
			_apply_sized_button_styles(button, "botao_lateral_esquerdo_%s_396x156.png", Vector2(34, 8))
		"principal":
			_apply_sized_button_styles(button, "botao_principal_painel_direito_%s_540x172.png", Vector2(40, 8))
		"pequeno":
			_apply_sized_button_styles(button, "botao_pequeno_aplicar_cancelar_%s_336x136.png", Vector2(28, 8))
		_:
			var base := "buttons/botao_%s" % kind
			var tex_margin := Vector2(64, 28) if kind == "pequeno" else Vector2(86, 31)
			button.add_theme_stylebox_override("normal", _texture_style("%s_normal.png" % base, tex_margin))
			button.add_theme_stylebox_override("hover", _texture_style("%s_hover.png" % base, tex_margin))
			button.add_theme_stylebox_override("pressed", _texture_style("%s_pressionado.png" % base, tex_margin))
			button.add_theme_stylebox_override("disabled", _texture_style("%s_desabilitado.png" % base, tex_margin))


func _apply_sized_button_styles(button: Button, filename_pattern: String, content_margin: Vector2) -> void:
	var base := "buttons/sized/%s"
	button.add_theme_stylebox_override("normal", _button_texture_style(base % (filename_pattern % "normal"), content_margin))
	button.add_theme_stylebox_override("hover", _button_texture_style(base % (filename_pattern % "hover"), content_margin))
	button.add_theme_stylebox_override("pressed", _button_texture_style(base % (filename_pattern % "pressionado"), content_margin))
	button.add_theme_stylebox_override("disabled", _button_texture_style(base % (filename_pattern % "desabilitado"), content_margin))


func _apply_header_tab_styles(button: Button) -> void:
	var base := "buttons/botao_aba"
	button.add_theme_stylebox_override("normal", _texture_style("%s_normal.png" % base, Vector2.ZERO))
	button.add_theme_stylebox_override("hover", _texture_style("%s_hover.png" % base, Vector2.ZERO))
	button.add_theme_stylebox_override("pressed", _texture_style("%s_pressionado.png" % base, Vector2.ZERO))
	button.add_theme_stylebox_override("disabled", _texture_style("%s_desabilitado.png" % base, Vector2.ZERO))


func _apply_slider_styles(slider: HSlider) -> void:
	slider.add_theme_stylebox_override("slider", _flat_slider_style(Color(0.045, 0.050, 0.052, 0.98), Color(0.56, 0.40, 0.18, 1.0)))
	slider.add_theme_stylebox_override("grabber_area", _flat_slider_style(Color(0.02, 0.48, 0.47, 0.96), Color(0.58, 0.95, 0.90, 1.0)))


func _apply_toggle_styles(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _toggle_style(Color(0.055, 0.063, 0.070, 0.98), Color(0.64, 0.46, 0.20, 1.0)))
	button.add_theme_stylebox_override("hover", _toggle_style(Color(0.080, 0.090, 0.092, 1.0), Color(0.86, 0.67, 0.28, 1.0)))
	button.add_theme_stylebox_override("pressed", _toggle_style(Color(0.02, 0.40, 0.39, 1.0), Color(0.46, 0.98, 0.94, 1.0)))
	button.add_theme_stylebox_override("hover_pressed", _toggle_style(Color(0.03, 0.52, 0.50, 1.0), Color(0.74, 1.0, 0.96, 1.0)))
	button.add_theme_stylebox_override("disabled", _toggle_style(Color(0.10, 0.10, 0.10, 0.70), Color(0.34, 0.34, 0.34, 0.85)))


func _make_button_visuals_transparent(button: Button) -> void:
	var transparent := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", transparent)
	button.add_theme_stylebox_override("pressed", transparent)
	button.add_theme_stylebox_override("disabled", transparent)


func _wire_button_audio(button: Button) -> void:
	button.focus_entered.connect(func() -> void: _audio_ui("select"))
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			_audio_ui("select")
	)
	button.pressed.connect(func() -> void: _audio_ui("confirm"))


# Painel com moldura mantendo a proporcao NATIVA da textura (sem esticar).
func _make_frame_panel(node_name: String, texture_path: String, rect: Rect2) -> Control:
	var panel := Control.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_rect(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)

	var frame := TextureRect.new()
	frame.name = "FrameTexture"
	frame.texture = _texture(texture_path)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(frame)
	panel.add_child(frame)
	_animated_details.append(frame)
	return panel


func _panel_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	_set_full_rect(margin)
	return margin


func _modal_title(text: String) -> Label:
	var title := Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.97, 0.79, 0.38, 1.0))
	return title


func _make_divider() -> TextureRect:
	var divider := TextureRect.new()
	divider.texture = _texture("frames/divisor_horizontal_cristal.png")
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	divider.custom_minimum_size = Vector2(0, 18)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.modulate = Color(0.67, 0.92, 0.88, 0.74)
	_animated_details.append(divider)
	return divider


func _texture_style(path: String, margins: Vector2) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _texture(path)
	style.texture_margin_left = margins.x
	style.texture_margin_right = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_bottom = margins.y
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _button_texture_style(path: String, content_margin: Vector2) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _texture(path)
	style.content_margin_left = content_margin.x
	style.content_margin_right = content_margin.x
	style.content_margin_top = content_margin.y
	style.content_margin_bottom = content_margin.y
	return style


func _toggle_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _flat_slider_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _texture(path: String) -> Texture2D:
	return load("%s/%s" % [MENU_ASSET_ROOT, path])


func _load_menu_config() -> Dictionary:
	var config := CONFIG_FALLBACK.duplicate(true)
	var file := FileAccess.open(menu_config_path, FileAccess.READ)
	if file == null:
		return config

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		config.merge(parsed, true)
	return config


func _levels_config() -> Dictionary:
	var registry := get_node_or_null("/root/DataRegistry")
	if registry != null:
		var levels: Dictionary = registry.get_section(&"levels")
		if not levels.is_empty():
			return levels

	var file := FileAccess.open("res://data/config/levels.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _update_slider_value_label(slider: HSlider, label: Label) -> void:
	if slider.max_value <= 1.0:
		label.text = "%d%%" % int(round(slider.value * 100.0))
	else:
		label.text = "%d" % int(round(slider.value))


func _setting_float(key: String, fallback: float) -> float:
	var settings := _settings()
	return float(settings.get(key)) if settings != null else fallback


func _setting_bool(key: String, fallback: bool) -> bool:
	var settings := _settings()
	return bool(settings.get(key)) if settings != null else fallback


func _settings() -> Node:
	return get_node_or_null("/root/GameSettings")


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _panel_anchor_rect(node: Control, rect: Rect2) -> void:
	node.anchor_left = rect.position.x
	node.anchor_top = rect.position.y
	node.anchor_right = rect.position.x + rect.size.x
	node.anchor_bottom = rect.position.y + rect.size.y
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


# Define o retangulo de um Control em coordenadas da grade 1280x720,
# convertendo para ancoras proporcionais (escala junto com o stretch).
func _rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.anchor_left = x / DESIGN_W
	node.anchor_top = y / DESIGN_H
	node.anchor_right = (x + w) / DESIGN_W
	node.anchor_bottom = (y + h) / DESIGN_H
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


func _set_full_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


func _audio_ui(cue: StringName) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_ui(cue)
