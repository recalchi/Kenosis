extends Area2D
class_name StoryPuzzleNode

signal activated(node_id: StringName)

var node_id: StringName = &"node"
var order_index := 0
var active := false
var visual: Sprite2D


func _ready() -> void:
	add_to_group("resonance_target")
	add_to_group("story_puzzle_node")
	_update_visual()


func receive_resonance(_actor: Node) -> bool:
	if active:
		return false
	active = true
	_update_visual()
	activated.emit(node_id)
	return true


func reset_node() -> void:
	active = false
	_update_visual()


func get_interaction_label() -> String:
	return "Ressonancia alinhada" if active else "F: alinhar memoria"


func _update_visual() -> void:
	if visual == null:
		return
	visual.modulate = Color(0.76, 1.25, 1.22, 1.0) if active else Color(0.46, 0.68, 0.72, 0.78)
	visual.scale = Vector2(0.9, 0.9) if active else Vector2(0.76, 0.76)
