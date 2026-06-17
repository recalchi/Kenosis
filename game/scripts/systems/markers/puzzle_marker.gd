extends Marker2D
class_name PuzzleMarker

signal state_changed(puzzle_id: StringName, solved: bool)

@export var puzzle_id: StringName = &"puzzle"
@export var prerequisites: Array[StringName] = []

var solved := false


func _ready() -> void:
	add_to_group("puzzle_marker")


func set_solved(value: bool) -> void:
	if solved == value:
		return
	solved = value
	state_changed.emit(puzzle_id, solved)
