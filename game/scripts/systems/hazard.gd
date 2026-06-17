extends Area2D
class_name HazardZone

var visual: CanvasItem
var collision_shape: CollisionShape2D
var is_active := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_state()


func neutralize() -> void:
	is_active = false
	_update_state()


func _on_body_entered(body: Node) -> void:
	if not is_active:
		return

	if body.has_method("register_failure"):
		body.register_failure()


func _update_state() -> void:
	if collision_shape != null:
		collision_shape.disabled = not is_active

	if visual != null:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_active else Color(0.45, 0.95, 1.0, 0.35)
