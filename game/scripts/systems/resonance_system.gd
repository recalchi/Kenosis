extends Node
class_name ResonanceSystem

signal cooldown_changed(ready_percent: float, remaining_seconds: float)
signal resonance_succeeded(target: Node)
signal resonance_failed(reason: String)

@export var cooldown_seconds := 2.0

var cooldown_remaining := 0.0


func _process(delta: float) -> void:
	if cooldown_remaining <= 0.0:
		return

	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	cooldown_changed.emit(get_ready_percent(), cooldown_remaining)


func is_ready() -> bool:
	return cooldown_remaining <= 0.0


func get_ready_percent() -> float:
	if cooldown_seconds <= 0.0:
		return 1.0
	return 1.0 - (cooldown_remaining / cooldown_seconds)


func try_activate(target: Node, actor: Node) -> bool:
	if not is_ready():
		resonance_failed.emit("cooldown")
		return false

	if target == null:
		resonance_failed.emit("sem_alvo")
		return false

	if not target.has_method("receive_resonance"):
		resonance_failed.emit("alvo_invalido")
		return false

	var accepted: bool = target.receive_resonance(actor)
	if not accepted:
		resonance_failed.emit("rejeitado")
		return false

	cooldown_remaining = cooldown_seconds
	cooldown_changed.emit(get_ready_percent(), cooldown_remaining)
	resonance_succeeded.emit(target)
	return true
