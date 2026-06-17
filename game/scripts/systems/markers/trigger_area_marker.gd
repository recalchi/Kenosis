extends Area2D
class_name TriggerAreaMarker

signal triggered(trigger_id: StringName, body: Node)

@export var trigger_id: StringName = &"event"
@export var one_shot := true

var has_triggered := false


func _ready() -> void:
	add_to_group("trigger_area")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if one_shot and has_triggered:
		return
	has_triggered = true
	triggered.emit(trigger_id, body)
