extends StaticBody2D
class_name ResonanceGate

var visual: CanvasItem
var collision_shape: CollisionShape2D
var is_open := false


func open_gate() -> void:
	is_open = true

	if collision_shape != null:
		collision_shape.disabled = true

	if visual != null:
		visual.visible = false
