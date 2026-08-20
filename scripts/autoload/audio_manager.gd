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
	# Hazarde. Astea se redau POZITIONAL (AudioStreamPlayer3D pe nodul de hazard),
	# nu prin play_sfx() care e 2D — un tren trebuie sa se auda dinspre tren.
	&"rock_warn": preload("res://assets/audio/rock_warn.wav"),
	&"rock_impact": preload("res://assets/audio/rock_impact.wav"),
	&"train_horn": preload("res://assets/audio/train_horn.wav"),
	&"crossing_bell": preload("res://assets/audio/crossing_bell.wav"),
	# Singurul SFX de hazard care se reda IN BUCLA, nu la eveniment: tromba n-are
	# un moment in care „se intampla", e acolo tot timpul si volumul ei e ce iti
	# spune cat de aproape e. Vezi lista de bucle din _ready.
	&"typhoon_roar": preload("res://assets/audio/typhoon_roar.wav"),
	# A doua bucla de hazard, din acelasi motiv: valul e acolo tot timpul, doar
	# ca se apropie si se departeaza. `WaveSurge` ii urca volumul cand urca pe
	# drum si i-l coboara cand se scurge — porniri si opriri de stream ar fi
	# pocnit la fiecare trecere.
	&"wave_wash": preload("res://assets/audio/wave_wash.wav"),
	# A treia bucla de hazard: huruitul avalansei de pe versant. Ca la tromba si
	# la val, hazardul e acolo inainte sa se vada — dar aici e SINGURUL
	# avertisment, si pedeapsa e iesirea din cursa, deci volumul lui e chiar
	# mecanica, nu ambianta.
	&"avalanche_rumble": preload("res://assets/audio/avalanche_rumble.wav"),
	# Trosnetul ghetii (campul de placi, Baikal): mic la inclinare (pitch
	# ~1.35), mare la rupere (pitch ~0.62) — acelasi fisier, alta viteza.
	&"ice_crack": preload("res://assets/audio/ice_crack.wav"),
	# Impactul, o singura data, cand masa te inghite.
	&"avalanche_hit": preload("res://assets/audio/avalanche_hit.wav"),
}

## Fluxul brut al unui sunet, pentru cine si-l reda singur.
##
## play_sfx() e 2D: bun pentru feedback-ul jucatorului (boost, impact), inutil
## pentru un hazard care trebuie localizat in lume. Hazardele isi pun stream-ul
## pe un AudioStreamPlayer3D propriu.
static func stream(sfx_name: StringName) -> AudioStream:
	return SFX.get(sfx_name)


const ENGINE_LOOP: AudioStream = preload("res://assets/audio/engine_loop.wav")
const SKID_LOOP: AudioStream = preload("res://assets/audio/skid_loop.wav")
const POOL_SIZE: int = 10

var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0

func _ready() -> void:
	_create_bus(&"SFX")
	_create_bus(&"Engine")
	apply_volumes()
	for loop_stream: AudioStream in [ENGINE_LOOP, SKID_LOOP, SFX[&"typhoon_roar"],
			SFX[&"wave_wash"], SFX[&"avalanche_rumble"]]:
		var wav := loop_stream as AudioStreamWAV
		if wav != null:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			@warning_ignore("integer_division")
			wav.loop_end = wav.data.size() / 2 # frames (16-bit mono)
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
