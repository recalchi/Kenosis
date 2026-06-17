extends Area2D
class_name TransitionZoneMarker

signal transition_requested(target_scene: String, target_spawn: StringName)
signal transition_blocked(message: String)

@export_file("*.tscn") var target_scene := ""
@export var target_location: StringName = &""
@export var target_spawn: StringName = &"default"
@export var automatic := false
@export var interaction_label := "E: atravessar para a proxima area"
@export var locked := false
@export var locked_message := "A memoria desta area ainda nao foi estabilizada."


func _ready() -> void:
	add_to_group("transition_zone")
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	set_locked(locked)


func interact(_actor: Node) -> void:
	_request_transition()


func get_interaction_label() -> String:
	if locked:
		return "E: passagem ainda instavel"
	return interaction_label


func _on_body_entered(body: Node) -> void:
	if automatic and body is PlayerController:
		_request_transition()


func _request_transition() -> void:
	if locked:
		transition_blocked.emit(locked_message)
		return
	if not target_location.is_empty():
		var transition_manager := get_node_or_null("/root/StoryTransition")
		if transition_manager != null:
			transition_manager.travel_to_location(target_location, target_spawn)
		return
	transition_requested.emit(target_scene, target_spawn)


func set_locked(value: bool) -> void:
	locked = value
	modulate = Color(0.48, 0.52, 0.56, 0.62) if locked else Color.WHITE
