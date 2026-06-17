extends SceneTree

const MENU_HUB_PATH := "res://scenes/ui/MenuHub.tscn"
const OUTPUT_PATH := "res://tests/artifacts/menu_hub_layout.png"
const SETTINGS_OUTPUT_PATH := "res://tests/artifacts/menu_hub_settings.png"


func _init() -> void:
	root.size = Vector2i(1280, 720)
	var packed_scene := load(MENU_HUB_PATH)
	if packed_scene == null:
		push_error("could not load %s" % MENU_HUB_PATH)
		quit(1)
		return

	var menu: Node = packed_scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	await process_frame

	var play_button := root.find_child("MainPlayButton", true, false)
	if play_button != null:
		play_button.emit_signal("pressed")
		await process_frame
		await process_frame

	if not await _capture(OUTPUT_PATH):
		quit(1)
		return

	menu.call("show_settings")
	await process_frame
	await process_frame
	if not await _capture(SETTINGS_OUTPUT_PATH):
		quit(1)
		return

	print("KENOSIS_MENU_CAPTURED:%s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	print("KENOSIS_MENU_CAPTURED:%s" % ProjectSettings.globalize_path(SETTINGS_OUTPUT_PATH))
	quit(0)


func _capture(path: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("could not capture menu viewport image")
		return false

	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("could not save %s" % path)
		return false
	return true
