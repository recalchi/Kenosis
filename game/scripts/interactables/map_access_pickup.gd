extends Area2D
class_name MapAccessPickup

signal collected

@export var item_id: StringName = &"cartographer_lens"
@export var interaction_text := "E: recolher lente cartografica"
@export var collected_text := "Mapa sincronizado"

var is_collected := false


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("map_access_pickup")
	refresh_persistence()


func get_interaction_label() -> String:
	return collected_text if is_collected else interaction_text


func interact(_actor: Node) -> void:
	if is_collected:
		return

	is_collected = true
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system != null:
		save_system.collect_item(item_id)
		if save_system.has_method("set_map_access"):
			save_system.set_map_access(true)

	monitoring = false
	monitorable = false
	collected.emit()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(func() -> void: visible = false)


func refresh_persistence() -> void:
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	if save_system.has_method("has_map_access") and save_system.has_map_access():
		is_collected = true
		visible = false
		monitoring = false
		monitorable = false
