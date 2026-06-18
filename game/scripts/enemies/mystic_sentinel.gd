extends ExpansionEnemy
class_name MysticSentinel

const ANIMATION_LIBRARY := {
	"idle": {"frames": 5, "speed": 5.0, "loop": true},
	"move": {"frames": 4, "speed": 6.0, "loop": true},
	"alert": {"frames": 4, "speed": 6.0, "loop": true},
	"attack": {"frames": 5, "speed": 8.0, "loop": false},
	"damage": {"frames": 5, "speed": 7.0, "loop": false},
	"death": {"frames": 5, "speed": 5.0, "loop": false},
	"respawn": {"frames": 5, "speed": 5.0, "loop": false},
	"patrulha_flutuacao": {"frames": 5, "speed": 6.0, "loop": true},
	"scan_observacao": {"frames": 4, "speed": 6.0, "loop": true},
	"pulso_deteccao": {"frames": 6, "speed": 8.0, "loop": false},
	"idle_alerta": {"frames": 4, "speed": 6.0, "loop": true},
	"turn": {"frames": 4, "speed": 9.0, "loop": false},
	"cone_varredura_feixe_busca": {"frames": 4, "speed": 7.0, "loop": true},
	"lockon_marcacao_alvo": {"frames": 5, "speed": 8.0, "loop": false},
	"alarme_arcano_chamado": {"frames": 5, "speed": 8.0, "loop": false},
	"disparo_de_luz_contra_ataque": {"frames": 5, "speed": 8.0, "loop": false},
	"take_damage": {"frames": 5, "speed": 7.0, "loop": false},
	"respawn_reativacao": {"frames": 5, "speed": 5.0, "loop": false},
	"estado_dormente": {"frames": 3, "speed": 4.0, "loop": true},
	"estado_ativo": {"frames": 4, "speed": 6.0, "loop": true},
	"estado_alerta": {"frames": 4, "speed": 6.0, "loop": true},
	"estado_sobrecarga": {"frames": 4, "speed": 8.0, "loop": true},
}

const BEHAVIOR_TREE := {
	"root": "arcane_area_denial_sentinel",
	"states": [
		"idle",
		"patrol",
		"scan",
		"alert",
		"lockon",
		"attack",
		"damaged",
		"defeated",
		"respawning",
	],
	"transitions": [
		{"from": "idle", "to": "patrol", "when": "spawn_finished_or_target_missing"},
		{"from": "patrol", "to": "scan", "when": "target_enters_detection_radius"},
		{"from": "scan", "to": "alert", "when": "target_signature_visible"},
		{"from": "alert", "to": "lockon", "when": "target_inside_attack_range"},
		{"from": "lockon", "to": "attack", "when": "attack_cooldown_ready"},
		{"from": "alert|lockon", "to": "patrol", "when": "target_signature_hidden_or_lost"},
		{"from": "patrol|alert|attack", "to": "damaged", "when": "resonance_received"},
		{"from": "damaged", "to": "defeated", "when": "health_reaches_zero"},
		{"from": "defeated", "to": "respawning", "when": "death_fade_finished"},
		{"from": "respawning", "to": "patrol", "when": "reactivation_timer_finished"},
	],
	"animation_map": {
		"idle": "idle",
		"patrol": "estado_ativo",
		"scan": "scan_observacao > cone_varredura_feixe_busca",
		"alert": "estado_alerta",
		"lockon": "lockon_marcacao_alvo",
		"attack": "disparo_de_luz_contra_ataque",
		"damaged": "take_damage",
		"defeated": "death",
		"respawning": "respawn_reativacao",
	},
	"pending_animation_hooks": {
		"estado_dormente": "reserved_for_sleeping_guard_intro",
		"pulso_deteccao": "reserved_for_periodic_detection_pulse",
		"alarme_arcano_chamado": "reserved_for_summoning_or_room_alarm",
		"estado_sobrecarga": "reserved_for low health enraged sentinel phase",
		"patrulha_flutuacao": "kept as compact patrol variant; move uses estado_ativo for readability",
		"turn": "reserved_for_patrol_boundary_turn_visual",
	},
}


func get_behavior_tree() -> Dictionary:
	return BEHAVIOR_TREE.duplicate(true)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in ANIMATION_LIBRARY:
		if not frames.has_animation(animation_name):
			frames.add_animation(animation_name)
		var animation_config: Dictionary = ANIMATION_LIBRARY[animation_name]
		for frame_index in range(int(animation_config.get("frames", 0))):
			var path := "%s/%s_%d.png" % [frame_root, animation_name, frame_index]
			var texture: Texture2D = load(path)
			if texture != null:
				frames.add_frame(animation_name, texture)
		frames.set_animation_loop(animation_name, bool(animation_config.get("loop", false)))
		frames.set_animation_speed(animation_name, float(animation_config.get("speed", 5.0)))
	return frames
