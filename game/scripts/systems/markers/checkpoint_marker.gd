extends Marker2D
class_name CheckpointMarker

@export var checkpoint_id: StringName = &"checkpoint"
@export var auto_activate := false


func _ready() -> void:
	add_to_group("checkpoint_marker")
