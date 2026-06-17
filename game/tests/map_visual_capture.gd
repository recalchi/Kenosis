extends SceneTree

const ROOM_PATH := "res://scenes/levels/MapTestRoom.tscn"
const OUTPUT_DIR := "res://tests/artifacts"


func _init() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var packed: PackedScene = load(ROOM_PATH)
	var room := packed.instantiate()
	root.add_child(room)
	for _frame in range(20):
		await process_frame

	var navigator := room.find_child("MapNavigator", true, false) as MapNavigator
	navigator.teleport_to(&"abyss")
	for _frame in range(8):
		await process_frame
	await _capture("%s/map_room_gameplay.png" % OUTPUT_DIR)

	navigator.set_map_visible(true)
	for _frame in range(3):
		await process_frame
	await _capture("%s/map_room_overlay.png" % OUTPUT_DIR)
	navigator.set_map_visible(false)
	quit(0)


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	print("CAPTURED %s" % path)
