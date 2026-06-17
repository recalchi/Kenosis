extends Area2D
class_name LoreScar

signal lore_requested(title: String, lines: Array[String])

@export var lore_title := "Cicatriz do Patrulheiro"
@export var lore_id: StringName = &""
@export var lore_lines: Array[String] = [
	"Estes guardioes nao nasceram monstros.",
	"A corrupcao apagou seus nomes, mas nao o impulso de vigiar.",
	"O Escriba nao os derrota: silencia sua assinatura e desfaz o no por tras.",
]
@export var reward_points := 3

var observed := false


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_label() -> String:
	return "E: reler cicatriz" if observed else "E: ler cicatriz"


func interact(actor: Node) -> void:
	if not observed:
		observed = true
		var first_global_read := true
		var save_system := get_node_or_null("/root/SaveSystem")
		if save_system != null and not lore_id.is_empty():
			first_global_read = save_system.mark_lore_observed(lore_id)
		if first_global_read and actor.has_method("add_points"):
			actor.add_points(reward_points)
	lore_requested.emit(lore_title, lore_lines)
