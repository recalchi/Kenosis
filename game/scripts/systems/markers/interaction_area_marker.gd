extends Area2D
class_name InteractionAreaMarker

signal interaction_requested(interaction_id: StringName, actor: Node)

@export var interaction_id: StringName = &"interaction"
@export var prompt := "E: interagir"


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("interaction_area")


func get_interaction_label() -> String:
	return prompt


func interact(actor: Node) -> void:
	interaction_requested.emit(interaction_id, actor)
