extends Area2D
class_name ResonanceReceiver

signal activated

var is_active := false
var visual: CanvasItem


func _ready() -> void:
	add_to_group("resonance_target")
	_update_visual()


func receive_resonance(_actor: Node) -> bool:
	if is_active:
		return false

	is_active = true
	_update_visual()
	activated.emit()
	return true


func get_interaction_label() -> String:
	return "F: usar Ressonancia"


func _update_visual() -> void:
	if visual == null:
		return

	visual.modulate = Color(1.20, 1.40, 1.45, 1.00) if is_active else Color(0.78, 0.86, 0.92, 1.00)
