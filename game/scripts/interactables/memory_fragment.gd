extends Area2D
class_name MemoryFragment

signal collected(reward: int)

@export var reward := 10
@export var item_id: StringName = &""

var is_collected := false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("memory_fragment")
	refresh_persistence()


func get_interaction_label() -> String:
	return "Memoria recolhida" if is_collected else "E: recolher fragmento de memoria"


func interact(actor: Node) -> void:
	if is_collected:
		return

	is_collected = true
	var first_collection := true
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null and not item_id.is_empty():
		first_collection = save_system.collect_item(item_id)
	if first_collection and actor.has_method("add_points"):
		actor.add_points(reward)
	monitoring = false
	monitorable = false
	collected.emit(reward)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(func() -> void: visible = false)


func refresh_persistence() -> void:
	if item_id.is_empty():
		return
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	var save_data: Dictionary = save_system.get_data()
	if String(item_id) in save_data.get("collected_items", []):
		is_collected = true
		visible = false
		monitoring = false
		monitorable = false
