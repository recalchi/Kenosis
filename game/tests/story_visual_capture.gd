extends SceneTree

const STORY_SCENE := "res://scenes/levels/locations/Awakening.tscn"
const OUTPUT_DIR := "res://tests/artifacts"


func _init() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await process_frame

	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.begin_test_session()

	var packed: PackedScene = load(STORY_SCENE)
	var room := packed.instantiate()
	root.add_child(room)
	for _frame in range(55):
		await process_frame
	await _capture("%s/story_dialogue.png" % OUTPUT_DIR)

	var hud := room.find_child("PrototypeHUD", true, false)
	hud.complete_dialogue_line()
	hud.advance_dialogue()
	hud.complete_dialogue_line()
	hud.advance_dialogue()
	for _frame in range(12):
		await process_frame
	await _capture("%s/story_gameplay.png" % OUTPUT_DIR)

	if save_system != null:
		save_system.end_test_session()
	quit(0)


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(path)
	print("CAPTURED %s" % path)
