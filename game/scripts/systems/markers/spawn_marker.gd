extends Marker2D
class_name SpawnMarker

@export var spawn_id: StringName = &"default"
@export var facing_direction := 1


func _ready() -> void:
	add_to_group("spawn_marker")
