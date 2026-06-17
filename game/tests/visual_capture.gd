extends SceneTree

const TEST_ROOM_PATH := "res://scenes/levels/TestRoom.tscn"


func _init() -> void:
	root.size = Vector2i(1280, 720)
	var packed_scene: PackedScene = load(TEST_ROOM_PATH)
	var room: Node = packed_scene.instantiate()
	root.add_child(room)
	await create_timer(1.1).timeout
	_capture("res://../builds/test_room_start_latest.png")

	var player := root.find_child("Player", true, false) as CharacterBody2D
	var camera := player.find_child("Camera2D", true, false) as Camera2D
	player.global_position = Vector2(1980, 408)
	camera.reset_smoothing()
	await create_timer(0.35).timeout
	_capture("res://../builds/test_room_extension_latest.png")
	quit()


func _capture(path: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(path))
