extends SceneTree

const OUTPUT_DIR := "res://tests/artifacts"
const CAPTURES := {
	"awakening_layout.png": "res://scenes/levels/locations/Awakening.tscn",
	"forge_layout.png": "res://scenes/levels/locations/Forge.tscn",
	"void_heart_layout.png": "res://scenes/levels/locations/VoidHeart.tscn",
}


func _init() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await process_frame

	var save_system := root.get_node_or_null("SaveSystem")
	if save_system != null:
		save_system.begin_test_session()

	for output_name in CAPTURES:
		await _capture_location(String(CAPTURES[output_name]), String(output_name))

	if save_system != null:
		save_system.end_test_session()
	quit(0)


func _capture_location(scene_path: String, output_name: String) -> void:
	var packed: PackedScene = load(scene_path)
	var room := packed.instantiate()
	root.add_child(room)
	for _frame in range(12):
		await process_frame

	var intro_timer := room.find_child("IntroDialogueTimer", true, false) as Timer
	if intro_timer != null:
		intro_timer.stop()
	var presentation := room.find_child("LocationPresentationContent", true, false)
	if presentation != null:
		presentation.visible = false

	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output_path := "%s/%s" % [OUTPUT_DIR, output_name]
	image.save_png(output_path)
	print("CAPTURED %s" % output_path)

	root.remove_child(room)
	room.queue_free()
	await process_frame
