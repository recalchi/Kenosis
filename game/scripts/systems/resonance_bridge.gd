extends StaticBody2D
class_name ResonanceBridge

var visual: CanvasItem
var collision_shape: CollisionShape2D
var is_active := false
var _base_visual_scale := Vector2.ONE
var _activation_tween: Tween


func _ready() -> void:
	if visual is Node2D:
		_base_visual_scale = (visual as Node2D).scale
	_update_state()


func activate_bridge() -> void:
	is_active = true
	_update_state()


func _update_state() -> void:
	if collision_shape != null:
		collision_shape.disabled = not is_active

	if visual != null:
		visual.visible = true
		if _activation_tween != null:
			_activation_tween.kill()
			_activation_tween = null
		if is_active:
			visual.modulate = Color(0.55, 1.2, 1.25, 0.45)
			if visual is Node2D:
				var visual_node := visual as Node2D
				visual_node.scale = _base_visual_scale * 0.92
				_activation_tween = create_tween()
				_activation_tween.set_parallel(true)
				_activation_tween.tween_property(visual_node, "scale", _base_visual_scale * 1.04, 0.18)
				_activation_tween.tween_property(visual, "modulate", Color(1.15, 1.35, 1.45, 1.0), 0.18)
				_activation_tween.chain().tween_property(visual_node, "scale", _base_visual_scale, 0.14)
			else:
				visual.modulate = Color(1.15, 1.35, 1.45, 1.0)
		else:
			if visual is Node2D:
				(visual as Node2D).scale = _base_visual_scale
			visual.modulate = Color(0.45, 0.85, 1.0, 0.30)
