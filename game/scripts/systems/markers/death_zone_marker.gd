extends Area2D
class_name DeathZoneMarker

@export var failure_reason := "queda"


func _ready() -> void:
	add_to_group("death_zone")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_failure"):
		body.register_failure()
