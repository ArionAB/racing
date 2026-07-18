extends Node
## Singleton audio (portat din racing 2D): pool de playere pentru SFX
## simultane + bus-uri separate pentru efecte si motor, cu volume din setari.
## SFX-urile sunt placeholder-e sintetizate (tools/generate_sfx.gd) —
## inlocuirea cu assets reale nu atinge codul de joc.

const SFX: Dictionary = {
	&"boost": preload("res://assets/audio/boost.wav"),
	&"drift_start": preload("res://assets/audio/drift_start.wav"),
	&"drift_level": preload("res://assets/audio/drift_level.wav"),
	&"backfire": preload("res://assets/audio/backfire.wav"),
	&"wall_hit": preload("res://assets/audio/wall_hit.wav"),
	&"bump": preload("res://assets/audio/bump.wav"),
	&"land": preload("res://assets/audio/land.wav"),
	&"count_beep": preload("res://assets/audio/count_beep.wav"),
	&"go_beep": preload("res://assets/audio/go_beep.wav"),
}

const ENGINE_LOOP: AudioStream = preload("res://assets/audio/engine_loop.wav")
const POOL_SIZE: int = 10

var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0

func _ready() -> void:
	_create_bus(&"SFX")
	_create_bus(&"Engine")
	apply_volumes()
	var engine_wav := ENGINE_LOOP as AudioStreamWAV
	if engine_wav != null:
		engine_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		@warning_ignore("integer_division")
		engine_wav.loop_end = engine_wav.data.size() / 2 # frames (16-bit mono)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_pool.append(player)

func _create_bus(bus_name: StringName) -> void:
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, &"Master")

func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(&"SFX"), linear_to_db(GameState.sfx_volume))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index(&"Engine"), linear_to_db(GameState.engine_volume))

func play_sfx(sfx_name: StringName, pitch: float = 1.0) -> void:
	var stream: AudioStream = SFX.get(sfx_name)
	if stream == null:
		return
	var player := _pool[_next]
	for i in POOL_SIZE:
		var candidate := _pool[(_next + i) % POOL_SIZE]
		if not candidate.playing:
			player = candidate
			break
	_next = (_pool.find(player) + 1) % POOL_SIZE
	player.stream = stream
	# Variatie mica de pitch: sunetul repetat nu suna "de robot".
	player.pitch_scale = pitch * randf_range(0.96, 1.04)
	player.volume_db = -6.0
	player.play()
