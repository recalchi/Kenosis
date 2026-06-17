extends Area2D
class_name CheckpointStation

signal interacted

@export var reward_points := 5

var activated := false


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_label() -> String:
	return "E: preservar memoria"


func interact(actor: Node) -> void:
	if actor.has_method("set_checkpoint"):
		actor.set_checkpoint(actor.global_position)

	if not activated and actor.has_method("add_points"):
		actor.add_points(reward_points)
	activated = true

	if actor.has_method("restore_health"):
		actor.restore_health()

	interacted.emit()
