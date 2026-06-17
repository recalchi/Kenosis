extends SceneTree

const MENU_HUB_PATH := "res://scenes/ui/MenuHub.tscn"

var _failed := false


func _init() -> void:
	await _test_menu_hub()
	if not _failed:
		print("KENOSIS_MENU_HUB_SMOKE_OK")
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

	var expected_nodes := [
		"MenuLogo",
		"MainMenuPanel",
		"SubMenuPanel",
		"MainPlayButton",
		"MapSelectionPanel",
		"MapDestinationAwakeningButton",
		"TutorialButton",
		"SettingsButton",
		"TutorialPanel",
		"TutorialCloseButton",
		"SettingsPanel"
	]

	for node_name: String in expected_nodes:
		if root.find_child(node_name, true, false) == null:
			_fail("%s not found" % node_name)
			return

	var menu_logo := root.find_child("MenuLogo", true, false)
	if menu_logo.get("texture") == null:
		_fail("MenuLogo texture not loaded")
		return

	var story_button := root.find_child("StoryButton", true, false)
	if story_button.disabled:
		_fail("StoryButton should be enabled")
		return

	var tutorial_panel := root.find_child("TutorialPanel", true, false)
	var settings_panel := root.find_child("SettingsPanel", true, false)
	var submenu_panel := root.find_child("SubMenuPanel", true, false)
	var map_panel := root.find_child("MapSelectionPanel", true, false)
	if submenu_panel.visible or tutorial_panel.visible or settings_panel.visible or map_panel.visible:
		_fail("right side panels should start hidden/minimized")
		return

	var play_button := root.find_child("MainPlayButton", true, false)
	play_button.emit_signal("pressed")
	await process_frame
	if not submenu_panel.visible:
		_fail("play button did not reveal right panel")
		return
	for node_name: String in ["ContinueButton", "StoryButton", "RightTabEntry", "RightTabMap", "RightTabStory"]:
		if root.find_child(node_name, true, false) == null:
			_fail("%s not found after opening play menu" % node_name)
			return

	var map_test_button := root.find_child("MapTestButton", true, false)
	_click_control(map_test_button as Control)
	await process_frame
	if not map_panel.visible:
		_fail("MapTestButton content click did not open map selection")
		return

	var right_tab_entry_from_content := root.find_child("RightTabEntry", true, false)
	_click_control(right_tab_entry_from_content as Control)
	await process_frame

	menu.call("show_tutorial")
	if not tutorial_panel.visible or settings_panel.visible:
		_fail("tutorial panel did not open cleanly")
		return

	menu.call("hide_tutorial")
	menu.call("show_settings")
	if tutorial_panel.visible or map_panel.visible or not settings_panel.visible:
		_fail("settings panel did not open cleanly")
		return
	for node_name: String in ["SettingsTabGeneral", "SettingsTabAudio", "SettingsTabVideo", "SettingsTabControls"]:
		if root.find_child(node_name, true, false) == null:
			_fail("%s not found after opening settings" % node_name)
			return

	var audio_tab := root.find_child("SettingsTabAudio", true, false)
	_click_control(audio_tab as Control)
	await process_frame
	var master_slider := root.find_child("MasterVolumeSlider", true, false)
	if master_slider == null or not master_slider.visible:
		_fail("audio header tab did not reveal audio settings")
		return

	menu.call("hide_settings")
	if settings_panel.visible:
		_fail("settings panel did not close")
		return

	var right_tab_entry := root.find_child("RightTabEntry", true, false)
	var right_tab_map := root.find_child("RightTabMap", true, false)
	_click_control(right_tab_map as Control)
	await process_frame
	if not map_panel.visible:
		_fail("Map header tab did not open map selection")
		return

	_click_control(right_tab_entry as Control)
	await process_frame
	if map_panel.visible or not submenu_panel.visible:
		_fail("Entrada header tab did not return to entry page")
		return

	root.remove_child(menu)
	menu.queue_free()
	await process_frame


func _click_control(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.position = center
	press.global_position = center
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press)

	var release := InputEventMouseButton.new()
	release.position = center
	release.global_position = center
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release)


func _fail(message: String) -> void:
	_failed = true
	push_error("MenuHub smoke test failed: %s" % message)
	quit(1)
