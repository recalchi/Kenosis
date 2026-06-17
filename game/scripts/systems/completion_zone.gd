extends Area2D
class_name CompletionZone

signal completed

var is_completed := false
var locked := true


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_label() -> String:
	return "Saida bloqueada: desate o Patrulheiro" if locked else "E: concluir campo de testes"


func unlock() -> void:
	locked = false


func interact(body: Node) -> void:
	if is_completed or locked:
		return

	if body is PlayerController:
		is_completed = true
		completed.emit()
