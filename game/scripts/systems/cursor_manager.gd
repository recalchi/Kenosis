extends Node

const CURSOR_DEFINITIONS := {
	"default": {
		"path": "res://assets/ui/gameplay/cursors/32x32/cursor_arrow_gem_32x32.png",
		"shape": Input.CURSOR_ARROW,
		"hotspot": Vector2(5, 2),
	},
	"interact": {
		"path": "res://assets/ui/gameplay/cursors/32x32/cursor_resonance_select_32x32.png",
		"shape": Input.CURSOR_POINTING_HAND,
		"hotspot": Vector2(5, 2),
	},
	"disabled": {
		"path": "res://assets/ui/gameplay/cursors/32x32/cursor_disabled_gray_32x32.png",
		"shape": Input.CURSOR_FORBIDDEN,
		"hotspot": Vector2(5, 2),
	},
	"drag": {
		"path": "res://assets/ui/gameplay/cursors/32x32/cursor_shadow_blade_32x32.png",
		"shape": Input.CURSOR_DRAG,
		"hotspot": Vector2(5, 2),
	},
	"can_drop": {
		"path": "res://assets/ui/gameplay/cursors/32x32/cursor_arrow_gold_32x32.png",
		"shape": Input.CURSOR_CAN_DROP,
		"hotspot": Vector2(5, 2),
	},
	"precision": {
		"path": "res://assets/ui/gameplay/cursors/32x32/cursor_corruption_purple_32x32.png",
		"shape": Input.CURSOR_CROSS,
		"hotspot": Vector2(5, 2),
	},
}

var _loaded_cursors: Dictionary = {}
var _active_context := "default"


func _ready() -> void:
	_register_gameplay_cursors()
	get_tree().node_added.connect(_apply_cursor_hint)
	_apply_cursor_hints_to_tree(get_tree().root)


func has_gameplay_cursor(cursor_name: String) -> bool:
	return _loaded_cursors.has(cursor_name)


func get_gameplay_cursor_size(cursor_name: String) -> Vector2i:
	var texture := _loaded_cursors.get(cursor_name) as Texture2D
	return texture.get_size() if texture != null else Vector2i.ZERO


func get_active_context() -> String:
	return _active_context


func set_gameplay_context(cursor_name: String) -> bool:
	if not _loaded_cursors.has(cursor_name):
		return false
	var definition: Dictionary = CURSOR_DEFINITIONS[cursor_name]
	Input.set_default_cursor_shape(int(definition["shape"]))
	_active_context = cursor_name
	return true


func _register_gameplay_cursors() -> void:
	for cursor_name in CURSOR_DEFINITIONS:
		var definition: Dictionary = CURSOR_DEFINITIONS[cursor_name]
		var texture := load(String(definition["path"])) as Texture2D
		if texture == null:
			push_warning("Gameplay cursor could not be loaded: %s" % definition["path"])
			continue
		Input.set_custom_mouse_cursor(
			texture,
			int(definition["shape"]),
			definition["hotspot"] as Vector2
		)
		_loaded_cursors[cursor_name] = texture
	set_gameplay_context("default")


func _apply_cursor_hints_to_tree(node: Node) -> void:
	_apply_cursor_hint(node)
	for child in node.get_children():
		_apply_cursor_hints_to_tree(child)


func _apply_cursor_hint(node: Node) -> void:
	if not node is BaseButton:
		return
	var button := node as BaseButton
	_refresh_button_cursor(button)
	if not button.has_meta("gameplay_cursor_connected"):
		button.set_meta("gameplay_cursor_connected", true)
		button.mouse_entered.connect(_refresh_button_cursor.bind(button))


func _refresh_button_cursor(button: BaseButton) -> void:
	button.mouse_default_cursor_shape = (
		Control.CURSOR_FORBIDDEN if button.disabled else Control.CURSOR_POINTING_HAND
	)
