extends Area2D
class_name StealthCover

var _cover_sprite: Sprite2D
var _pulse_tween: Tween


func _ready() -> void:
	add_to_group("stealth_cover")
	_cover_sprite = get_node_or_null("CoverSprite") as Sprite2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_stealth_cover_active"):
		body.set_stealth_cover_active(true)
		_set_cover_highlight(true)


func _on_body_exited(body: Node) -> void:
	if body.has_method("set_stealth_cover_active"):
		body.set_stealth_cover_active(false)
		_set_cover_highlight(false)


func _set_cover_highlight(active: bool) -> void:
	if _cover_sprite == null:
		return
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	if active:
		_cover_sprite.modulate = Color(0.66, 0.92, 0.78, 1.0)
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(_cover_sprite, "scale", Vector2(0.78, 0.78), 0.42)
		_pulse_tween.tween_property(_cover_sprite, "scale", Vector2(0.72, 0.72), 0.42)
	else:
		_cover_sprite.scale = Vector2(0.72, 0.72)
		_cover_sprite.modulate = Color(0.47, 0.67, 0.49, 0.9)
