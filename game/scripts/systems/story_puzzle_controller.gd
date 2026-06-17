extends Node
class_name StoryPuzzleController

signal solved
signal progress_changed(current: int, total: int)

var challenge_id: StringName = &"challenge"
var puzzle_mode := "all"
var hud: PrototypeHUD
var nodes: Array[StoryPuzzleNode] = []
var _expected_index := 0
var _solved := false


func configure(id: StringName, mode: String, target_hud: PrototypeHUD) -> void:
	challenge_id = id
	puzzle_mode = mode
	hud = target_hud


func register_node(node: StoryPuzzleNode) -> void:
	nodes.append(node)
	node.order_index = nodes.size() - 1
	node.activated.connect(_on_node_activated.bind(node))


func start() -> void:
	if puzzle_mode == "none" or nodes.is_empty():
		call_deferred("_mark_solved")
	else:
		progress_changed.emit(0, nodes.size())


func is_solved() -> bool:
	return _solved


func solve_for_test() -> void:
	for node in nodes:
		node.active = true
		node.call("_update_visual")
	_mark_solved()


func _on_node_activated(_node_id: StringName, node: StoryPuzzleNode) -> void:
	if _solved:
		return
	if puzzle_mode == "sequence":
		if node.order_index != _expected_index:
			_reset_sequence()
			if hud != null:
				hud.show_message("A sequencia se desfez. Escute novamente o ritmo da memoria.")
			return
		_expected_index += 1
		progress_changed.emit(_expected_index, nodes.size())
		if _expected_index >= nodes.size():
			_mark_solved()
		return

	var active_count := 0
	for puzzle_node in nodes:
		if puzzle_node.active:
			active_count += 1
	progress_changed.emit(active_count, nodes.size())
	if active_count >= nodes.size():
		_mark_solved()


func _reset_sequence() -> void:
	_expected_index = 0
	for node in nodes:
		node.reset_node()
	progress_changed.emit(0, nodes.size())


func _mark_solved() -> void:
	if _solved:
		return
	_solved = true
	progress_changed.emit(nodes.size(), nodes.size())
	solved.emit()
