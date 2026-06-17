extends Node

const AUDIO_PATHS := {
	"confirm": "res://assets/audio/ui/confirmation_001.ogg",
	"error": "res://assets/audio/ui/error_003.ogg",
	"alert": "res://assets/audio/sfx/glitch_003.ogg",
	"select": "res://assets/audio/ui/select_001.ogg",
	"dialogue_tick": "res://assets/audio/ui/select_001.ogg",
	"dialogue_open": "res://assets/audio/ui/open_001.ogg",
	"dialogue_close": "res://assets/audio/ui/close_001.ogg",
	"failure": "res://assets/audio/sfx/impactSoft_heavy_000.ogg",
	"checkpoint": "res://assets/audio/sfx/impactBell_heavy_000.ogg",
	"lore": "res://assets/audio/sfx/bookOpen.ogg",
	"complete": "res://assets/audio/music/jingles_PIZZI05.ogg",
}

const FOOTSTEP_PATHS := [
	"res://assets/audio/sfx/footstep_grass_000.ogg",
	"res://assets/audio/sfx/footstep_grass_001.ogg",
	"res://assets/audio/sfx/footstep_grass_002.ogg",
	"res://assets/audio/sfx/footstep_grass_003.ogg",
	"res://assets/audio/sfx/footstep_grass_004.ogg",
]

const SFX_POOL_SIZE := 8
const UI_POOL_SIZE := 4
const FOOTSTEP_POOL_SIZE := 4

var music_player: AudioStreamPlayer
var _streams: Dictionary = {}
var _footstep_streams: Array[AudioStream] = []
var _sfx_pool: Array[AudioStreamPlayer] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _footstep_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor := 0
var _ui_cursor := 0
var _footstep_cursor := 0
var _footstep_index := 0
var _last_ui_cue := &""
var _last_ui_time_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preload_audio()
	_sfx_pool = _create_pool("SFX", "SFX", SFX_POOL_SIZE)
	_ui_pool = _create_pool("UI", "SFX", UI_POOL_SIZE)
	_footstep_pool = _create_pool("Footstep", "SFX", FOOTSTEP_POOL_SIZE)
	music_player = _create_player("MusicPlayer", "Music")


func play_sfx(cue: StringName) -> void:
	_sfx_cursor = _play_from_pool(_sfx_pool, _sfx_cursor, cue)


func play_ui(cue: StringName) -> void:
	var now := Time.get_ticks_msec()
	if cue == _last_ui_cue and now - _last_ui_time_msec < 45:
		return
	_last_ui_cue = cue
	_last_ui_time_msec = now
	_ui_cursor = _play_from_pool(_ui_pool, _ui_cursor, cue)


func play_footstep() -> void:
	if _footstep_streams.is_empty() or _footstep_pool.is_empty():
		return
	var player := _next_available_player(_footstep_pool, _footstep_cursor)
	_footstep_cursor = (_footstep_cursor + 1) % _footstep_pool.size()
	player.stream = _footstep_streams[_footstep_index % _footstep_streams.size()]
	_footstep_index += 1
	player.pitch_scale = 0.96 + float(_footstep_index % 3) * 0.035
	player.play()


func play_music(cue: StringName) -> void:
	var stream: AudioStream = _streams.get(String(cue))
	if stream == null:
		return
	if music_player.playing and music_player.stream == stream:
		return
	music_player.stream = stream
	music_player.pitch_scale = 1.0
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func has_cue(cue: StringName) -> bool:
	return _streams.has(String(cue)) and _streams[String(cue)] != null


func get_pool_capacity() -> int:
	return _sfx_pool.size() + _ui_pool.size() + _footstep_pool.size()


func get_active_stream_count() -> int:
	var count := 0
	for player in _sfx_pool + _ui_pool + _footstep_pool:
		if player.stream != null:
			count += 1
	return count


func _preload_audio() -> void:
	for cue in AUDIO_PATHS:
		var stream: AudioStream = load(AUDIO_PATHS[cue])
		if stream != null:
			_streams[cue] = stream
		else:
			push_warning("Audio cue could not be loaded: %s" % cue)

	for path in FOOTSTEP_PATHS:
		var stream: AudioStream = load(path)
		if stream != null:
			_footstep_streams.append(stream)


func _create_pool(prefix: String, bus_name: String, size: int) -> Array[AudioStreamPlayer]:
	var pool: Array[AudioStreamPlayer] = []
	for index in size:
		pool.append(_create_player("%sPlayer%d" % [prefix, index], bus_name))
	return pool


func _create_player(node_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master"
	add_child(player)
	return player


func _play_from_pool(pool: Array[AudioStreamPlayer], cursor: int, cue: StringName) -> int:
	var stream: AudioStream = _streams.get(String(cue))
	if stream == null or pool.is_empty():
		return cursor
	var player := _next_available_player(pool, cursor)
	player.stream = stream
	player.pitch_scale = 1.0
	player.play()
	return (cursor + 1) % pool.size()


func _next_available_player(pool: Array[AudioStreamPlayer], fallback_index: int) -> AudioStreamPlayer:
	for player in pool:
		if not player.playing:
			return player
	return pool[fallback_index % pool.size()]
