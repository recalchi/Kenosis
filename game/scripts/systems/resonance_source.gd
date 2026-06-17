extends Area2D
class_name ResonanceSource

signal interacted

@export var reward_points := 5

var inspected := false


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_label() -> String:
	return "Fonte de Exorigem registrada" if inspected else "E: observar fonte de Exorigem"


func interact(actor: Node) -> void:
	if not inspected:
		inspected = true
		if actor.has_method("add_points"):
			actor.add_points(reward_points)

	interacted.emit()
