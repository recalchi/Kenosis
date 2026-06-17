extends Area2D
class_name MemorySeal

signal activated
signal activation_denied(cost: int)

@export var cost := 20

var is_active := false


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_label() -> String:
	return "Selo de memoria ativo" if is_active else "E: investir %d memorias no selo" % cost


func interact(actor: Node) -> void:
	if is_active:
		return

	if not actor.has_method("spend_points") or not bool(actor.spend_points(cost)):
		activation_denied.emit(cost)
		return

	is_active = true
	activated.emit()
