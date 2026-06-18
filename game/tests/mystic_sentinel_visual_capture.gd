extends SceneTree

const ROOM_PATH := "res://scenes/levels/MapTestRoom.tscn"
const OUTPUT_PATH := "res://../builds/mystic_sentinel_focus_latest.png"


func _init() -> void:
	root.size = Vector2i(1280, 720)
	var packed: PackedScene = load(ROOM_PATH)
	var room := packed.instantiate()
	root.add_child(room)
	for _frame in range(24):
		await process_frame

	var sentinel := room.find_child("MysticSentinel", true, false) as CharacterBody2D
	var player := room.find_child("Player", true, false) as CharacterBody2D
	if sentinel != null and player != null:
		player.global_position = sentinel.global_position + Vector2(-180, 0)
		var camera := player.find_child("Camera2D", true, false) as Camera2D
		if camera != null:
			camera.reset_smoothing()
	for _frame in range(18):
		await process_frame

	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	print("CAPTURED %s" % OUTPUT_PATH)
	quit(0)
