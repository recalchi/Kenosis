extends Node2D
class_name CameraBoundsMarker

@export var bounds := Rect2(-640.0, -360.0, 1280.0, 720.0)


func _ready() -> void:
	add_to_group("camera_bounds")


func apply_to(camera: Camera2D) -> void:
	camera.limit_left = int(global_position.x + bounds.position.x)
	camera.limit_top = int(global_position.y + bounds.position.y)
	camera.limit_right = int(global_position.x + bounds.end.x)
	camera.limit_bottom = int(global_position.y + bounds.end.y)
