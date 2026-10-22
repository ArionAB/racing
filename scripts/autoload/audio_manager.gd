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
	# Tabla pe tabla (#500): stratul de deasupra bufniturii `bump`, cu volum si
	# pitch dupa impuls (vezi Car._process_contacts).
	&"metal_hit": preload("res://assets/audio/metal_hit.wav"),
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
	# Stropul de apa la intrarea in vad / parau / mare (Car._enter_water):
	# pitch inalt la pas, jos la o cadere de la inaltime.
	&"splash": preload("res://assets/audio/splash.wav"),
	# Daruma-otoshi (Kyoto): „TOC"-ul ciocanului de lemn si frecarea discului.
	&"daruma_toc": preload("res://assets/audio/daruma_toc.wav"),
	&"daruma_slide": preload("res://assets/audio/daruma_slide.wav"),
	# Shishimai (Kyoto): muzica leului (bucla de exact un ciclu de 9 s, in faza cu
	# atacul) si clampanitul falcii.
	&"shishimai_music": preload("res://assets/audio/shishimai_music.wav"),
	&"shishimai_clack": preload("res://assets/audio/shishimai_clack.wav"),
	# Carul de festival Gion Matsuri (Kyoto): doua BUCLE pozitionale, muzica de
	# telegraf (taiko + kane) si scartaitul rotilor la traversare.
	&"gion_bayashi": preload("res://assets/audio/gion_bayashi.wav"),
	&"gion_wheels": preload("res://assets/audio/gion_wheels.wav"),
}

## Fluxul brut al unui sunet, pentru cine si-l reda singur.
##
## play_sfx() e 2D: bun pentru feedback-ul jucatorului (boost, impact), inutil
## pentru un hazard care trebuie localizat in lume. Hazardele isi pun stream-ul
## pe un AudioStreamPlayer3D propriu.
static func stream(sfx_name: StringName) -> AudioStream:
	var found: AudioStream = SFX.get(sfx_name)
	return found if found != null else EVENT_SFX.get(sfx_name)


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
			SFX[&"wave_wash"], SFX[&"avalanche_rumble"], SFX[&"shishimai_music"],
			SFX[&"gion_bayashi"], SFX[&"gion_wheels"]]:
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
	_events_ready()

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

## `volume_db`: -6 e nivelul comun; apelantii care dozeaza dupa intensitate
## (ciocnirea intre masini) il dau explicit.
func play_sfx(sfx_name: StringName, pitch: float = 1.0,
		volume_db: float = -6.0) -> void:
	var stream: AudioStream = SFX.get(sfx_name)
	if stream == null:
		stream = EVENT_SFX.get(sfx_name)
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
	player.volume_db = volume_db
	player.play()
	_log(sfx_name, volume_db, player.pitch_scale, false, Vector3.INF)


# ======================================================================
# EVENIMENTE (docs/feel_checklist.md: impact-layers, scrape-sparks,
# side-rubbing, jump-skill, who-hit-me, ai-ai-hits, position-change,
# hazards-speak, things-fly — partea de sunet).
#
# Bloc separat de restul: sunetele CONTINUE ale masinii (motor, derapaj,
# rulare) nu trec pe aici. Logica de ruta (cine aude ce, cand) sta in
# scenes/race/impact_sound.gd; aici sta doar ce e comun: ce straturi se aleg
# dupa putere, cele 4 playere 3D, cele doua bucle de contact, claxonul.
# ======================================================================

const EVENT_SFX: Dictionary = {
	# Trei straturi de impact, doua variante fiecare (vezi plan_impact).
	&"impact_tap_a": preload("res://assets/audio/impact_tap_a.wav"),
	&"impact_tap_b": preload("res://assets/audio/impact_tap_b.wav"),
	&"impact_crunch_a": preload("res://assets/audio/impact_crunch_a.wav"),
	&"impact_crunch_b": preload("res://assets/audio/impact_crunch_b.wav"),
	&"impact_crash_a": preload("res://assets/audio/impact_crash_a.wav"),
	&"impact_crash_b": preload("res://assets/audio/impact_crash_b.wav"),
	# Hartaielile (bucle, vezi set_loop).
	&"scrape_loop": preload("res://assets/audio/scrape_loop.wav"),
	&"rub_loop": preload("res://assets/audio/rub_loop.wav"),
	&"land_heavy": preload("res://assets/audio/land_heavy.wav"),
	&"toy_horn": preload("res://assets/audio/toy_horn.wav"),
	&"stinger_up": preload("res://assets/audio/stinger_up.wav"),
	&"stinger_down": preload("res://assets/audio/stinger_down.wav"),
	&"hazard_barrier_hit": preload("res://assets/audio/hazard_barrier_hit.wav"),
	&"hazard_bus_hit": preload("res://assets/audio/hazard_bus_hit.wav"),
	&"prop_knock_a": preload("res://assets/audio/prop_knock_a.wav"),
	&"prop_knock_b": preload("res://assets/audio/prop_knock_b.wav"),
}

## Variantele fiecarui strat (alese la intamplare, niciodata aceeasi de doua ori la rand).
const IMPACT_LAYERS: Dictionary = {
	&"tap": [&"impact_tap_a", &"impact_tap_b"],
	&"crunch": [&"impact_crunch_a", &"impact_crunch_b"],
	&"crash": [&"impact_crash_a", &"impact_crash_b"],
	&"knock": [&"prop_knock_a", &"prop_knock_b"],
}

## Bucla -> fisier.
const LOOP_STREAMS: Dictionary = {
	&"scrape": &"scrape_loop",
	&"rub": &"rub_loop",
}
const POOL3D_SIZE: int = 4

@export_group("Impact")
## Sub aceasta putere (m/s de delta-v) un impact nu scoate niciun sunet — acelasi
## prag ca feed-ul `Car.impact` (impact_min_dv).
@export var impact_floor: float = 2.5
## La aceasta putere volumul atinge maximul.
@export var impact_full: float = 22.0
## Volumul total (dB) la prag si la plafon; curba e k^0.7 (urca repede la inceput).
@export var impact_db_min: float = -17.0
@export var impact_db_max: float = -1.0
## Un strat cu cota mai mica din amestec nu se mai reda (economie de voci).
@export var impact_min_layer_weight: float = 0.12
## Cat se adauga stratului principal cand e redat pozitional (atenuarea 3D il taie).
@export var positional_gain_db: float = 3.0

@export_group("Aterizare")
## Viteza de cadere (m/s) de la care aterizarea suna (= pragul lui Car.landed) si
## cea care da volumul maxim.
@export var land_floor: float = 6.0
@export var land_full: float = 24.0
@export var land_db_min: float = -16.0
@export var land_db_max: float = -2.0
## Stratul greu (land_heavy) intra intre aceste doua viteze de cadere.
@export var land_heavy_from: float = 9.0
@export var land_heavy_full: float = 16.0

@export_group("Bucle de contact")
## Timpii de intrare / iesire ai volumului unei bucle (s). Scurti, ca sa nu intarzie
## fata de contact, dar peste un tick: un contact care palpaie nu pocneste.
@export var loop_attack_s: float = 0.04
@export var loop_release_s: float = 0.10
## Cat de repede urmareste pitch-ul tinta (1/s).
@export var loop_pitch_rate: float = 30.0

@export_group("Claxon")
@export var horn_db: float = -7.0
## Pauza minima dintre doua claxonate ale ACELEIASI masini, si dintre oricare doua.
@export var horn_cooldown_s: float = 3.0
@export var horn_global_gap_s: float = 0.4
## Peste atatia metri de camera nu se mai aude.
@export var horn_range_m: float = 55.0

@export_group("Stinger")
@export var stinger_db: float = -8.0

@export_group("Hazarde si decor")
@export var hazard_db: float = -5.0
## Cat mai incet suna o masina AI lovita de hazard (jucatorul: hazard_db).
@export var hazard_ai_offset_db: float = -8.0
@export var hazard_range_m: float = 60.0
@export var hazard_interval_s: float = 0.12
@export var knock_db_min: float = -24.0
@export var knock_db_max: float = -9.0
@export var knock_range_m: float = 40.0
@export var knock_interval_s: float = 0.07

@export_group("Playere 3D")
## Pana la atatia metri de camera sunetul 3D nu slabeste deloc; peste, scade
## invers cu distanta. Camera de urmarire sta la ~15 m de masina.
@export var pool3d_unit_size: float = 14.0
@export var pool3d_max_distance: float = 90.0
## 1.0 = panoramare fizica; mai mult exagereaza stanga/dreapta (cine m-a lovit).
@export var pool3d_panning: float = 1.6

## Ceasul real (s). Sondele il inlocuiesc cu unul simulat.
var clock: Callable = func() -> float: return Time.get_ticks_msec() * 0.001

## Jurnalul ultimelor sunete de eveniment (sonde): {name, db, pitch, positional, pos,
## frame}. Doar ce trece prin API-ul de mai jos; motorul si derapajul nu apar.
var sfx_log: Array[Dictionary] = []

var _pool3d: Array[AudioStreamPlayer3D] = []
var _p3_prio: Array[int] = []
var _p3_start: Array[float] = []
var _p3_until: Array[float] = []
var _last_variant: Dictionary = {}
var _loops: Dictionary = {}
var _horn_ready: Dictionary = {}
var _horn_global_until: float = 0.0
var _hazard_until: float = 0.0
var _knock_until: float = 0.0


func _events_ready() -> void:
	for i in POOL3D_SIZE:
		var p := AudioStreamPlayer3D.new()
		p.bus = &"SFX"
		p.unit_size = pool3d_unit_size
		p.max_distance = pool3d_max_distance
		p.panning_strength = pool3d_panning
		p.attenuation_filter_cutoff_hz = 9000.0
		add_child(p)
		_pool3d.append(p)
		_p3_prio.append(0)
		_p3_start.append(-1.0e9)
		_p3_until.append(-1.0e9)
	for loop_name: StringName in LOOP_STREAMS:
		var wav := EVENT_SFX[LOOP_STREAMS[loop_name]] as AudioStreamWAV
		if wav != null:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			@warning_ignore("integer_division")
			wav.loop_end = wav.data.size() / 2 # cadre (16-bit mono)
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		player.stream = wav
		player.volume_db = -80.0
		add_child(player)
		_loops[loop_name] = {"player": player, "gain": 0.0, "active": false,
			"db": -80.0, "pitch": 1.0, "pitch_now": 1.0, "starts": 0, "stops": 0}


# ----------------------------------------------------------- impact in straturi

## Planul unui impact: ce straturi, cu ce volum (dB) si pitch. FUNCTIE PURA in
## afara de alegerea variantei si de zgomotul de pitch. Gol sub `impact_floor`.
##
## Volumul TOTAL urmeaza o singura curba monotona (`master`), iar straturile
## principale (tap -> crunch -> crash) o impart intre ele cu cote de putere egala
## (suma cotelor = 1): puterea totala creste cu puterea impactului, iar caracterul
## trece de la „tac" la „crancanit" la „bufnitura" fara sa sara in volum. Peste ele
## vine un strat de corp (rol &"body"): `wall_hit` la perete, `bump` (+ clinchetul
## `metal_hit`) intre masini — cel care da „punch"-ul si ramane mereu 2D.
##
## `kind`: &"wall" sau &"car" (ca `Car.impact`). Fiecare intrare:
## {name, db, pitch, role: &"main"|&"body", layer}.
func plan_impact(kind: StringName, strength: float) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	if strength < impact_floor:
		return plan
	var k := clampf(inverse_lerp(impact_floor, impact_full, strength), 0.0, 1.0)
	var master := lerpf(impact_db_min, impact_db_max, pow(k, 0.7))
	var weights := {
		&"tap": 1.0 - smoothstep(5.0, 11.0, strength),
		&"crash": smoothstep(10.0, 17.0, strength),
	}
	weights[&"crunch"] = maxf(1.0 - float(weights[&"tap"]) - float(weights[&"crash"]), 0.0)
	var total := 0.0
	for layer: StringName in weights:
		if float(weights[layer]) < impact_min_layer_weight:
			weights[layer] = 0.0
		total += float(weights[layer])
	var is_car := kind == &"car"
	var base_pitch := (1.1 if is_car else 0.95) * lerpf(1.1, 0.88, k)
	for layer: StringName in [&"tap", &"crunch", &"crash"]:
		var w := float(weights[layer]) / maxf(total, 0.0001)
		if w <= 0.0:
			continue
		plan.append({"name": _pick_variant(layer),
			"db": master + 10.0 * log(w) / log(10.0),
			"pitch": base_pitch * randf_range(0.95, 1.05),
			"role": &"main", "layer": layer})
	# Corpul: intra la ~4 m/s si creste, nu scade niciodata (puterea ramane monotona).
	var body_w := smoothstep(4.0, 9.0, strength)
	if body_w >= impact_min_layer_weight:
		plan.append({"name": &"bump" if is_car else &"wall_hit",
			"db": master - 5.0 + 10.0 * log(body_w) / log(10.0),
			"pitch": lerpf(1.1, 0.85, k) * randf_range(0.97, 1.03),
			"role": &"body", "layer": &"body"})
	# Clinchetul de tabla doar intre masini, ca inainte (#500), ceva mai tarziu.
	var metal_w := smoothstep(4.0, 10.0, strength)
	if is_car and metal_w >= impact_min_layer_weight:
		plan.append({"name": &"metal_hit",
			"db": master - 6.0 + 10.0 * log(metal_w) / log(10.0),
			"pitch": lerpf(1.18, 0.86, k),
			"role": &"body", "layer": &"metal"})
	return plan


## Reda un impact. `point` finit + `positional_main` = straturile principale ies
## din 3D la punctul de contact (cine m-a lovit); corpul ramane 2D. `extra_db` se
## adauga peste tot (masinile AI lovite intre ele suna mai incet); `priority` e
## cea din play_sfx_at. Intoarce planul.
func play_impact(kind: StringName, strength: float, point: Vector3 = Vector3.INF,
		positional_main: bool = false, extra_db: float = 0.0,
		with_body: bool = true, priority: int = 3) -> Array[Dictionary]:
	var plan := plan_impact(kind, strength)
	for entry in plan:
		var role: StringName = entry["role"]
		var db: float = float(entry["db"]) + extra_db
		if role == &"body" and not with_body:
			continue
		if role == &"main" and positional_main and point.is_finite():
			play_sfx_at(entry["name"], point, float(entry["pitch"]),
				db + positional_gain_db, priority)
		else:
			_play_2d(entry["name"], float(entry["pitch"]), db)
	return plan


# ----------------------------------------------------------------- aterizare

## Planul unei aterizari: `land.wav` mereu (volum si pitch dupa viteza de cadere),
## `land_heavy` peste el de la `land_heavy_from`. Gol sub `land_floor`.
func plan_land(fall_speed: float) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	if fall_speed < land_floor:
		return plan
	var k := clampf(inverse_lerp(land_floor, land_full, fall_speed), 0.0, 1.0)
	var db := lerpf(land_db_min, land_db_max, pow(k, 0.8))
	plan.append({"name": &"land", "db": db, "pitch": lerpf(1.25, 0.85, k),
		"role": &"body", "layer": &"land"})
	var hw := smoothstep(land_heavy_from, land_heavy_full, fall_speed)
	if hw >= impact_min_layer_weight:
		plan.append({"name": &"land_heavy", "db": db - 2.0 + 10.0 * log(hw) / log(10.0),
			"pitch": lerpf(1.1, 0.8, k), "role": &"body", "layer": &"heavy"})
	return plan


func play_land(fall_speed: float) -> Array[Dictionary]:
	var plan := plan_land(fall_speed)
	for entry in plan:
		_play_2d(entry["name"], float(entry["pitch"]), float(entry["db"]))
	return plan


# ----------------------------------------------------------------- bucle

## Tinta unei bucle de contact (&"scrape" sau &"rub"). Se cheama la FIECARE tick de
## fizica: `active` = contactul exista (cu o mica ramanere in ImpactSound),
## `volume_db`/`pitch` = nivelul tinta cat e activ. Volumul urca in
## `loop_attack_s`, coboara in `loop_release_s`; bucla porneste cand are volum si
## se opreste abia cand a ajuns la zero — un contact care palpaie nu o opreste.
func set_loop(loop_name: StringName, active: bool, volume_db: float = -12.0,
		pitch: float = 1.0) -> void:
	var l: Dictionary = _loops.get(loop_name, {})
	if l.is_empty():
		return
	l["active"] = active
	if active:
		l["db"] = volume_db
		l["pitch"] = pitch


## Starea unei bucle, pentru sonde: {playing, gain, db, pitch, starts, stops, active}.
func loop_info(loop_name: StringName) -> Dictionary:
	var l: Dictionary = _loops.get(loop_name, {})
	if l.is_empty():
		return {}
	var player := l["player"] as AudioStreamPlayer
	return {"playing": player.playing, "gain": l["gain"], "db": player.volume_db,
		"pitch": player.pitch_scale, "starts": l["starts"], "stops": l["stops"],
		"active": l["active"]}


func _process(delta: float) -> void:
	for loop_name: StringName in _loops:
		_step_loop(_loops[loop_name], delta)


func _step_loop(l: Dictionary, delta: float) -> void:
	var player := l["player"] as AudioStreamPlayer
	var active: bool = l["active"]
	var gain: float = l["gain"]
	var rate := (1.0 / maxf(loop_attack_s, 0.001)) if active \
		else (1.0 / maxf(loop_release_s, 0.001))
	gain = move_toward(gain, 1.0 if active else 0.0, rate * delta)
	l["gain"] = gain
	l["pitch_now"] = lerpf(float(l["pitch_now"]), float(l["pitch"]),
		clampf(loop_pitch_rate * delta, 0.0, 1.0))
	if gain > 0.002:
		player.volume_db = float(l["db"]) + linear_to_db(gain)
		player.pitch_scale = maxf(float(l["pitch_now"]), 0.05)
		if not player.playing:
			player.play()
			l["starts"] = int(l["starts"]) + 1
	elif player.playing:
		player.stop()
		player.volume_db = -80.0
		l["stops"] = int(l["stops"]) + 1


# ----------------------------------------------------------------- 3D

## Reda un sunet din lume la `pos`, pe unul din cele `POOL3D_SIZE` playere 3D.
## Fara playere libere: il fura pe cel cu prioritatea cea mai mica (apoi cel mai
## vechi), dar numai daca nu e mai important decat noul sunet; altfel sunetul se
## pierde. Prioritati: 3 jucatorul/hazard, 2 claxon, 1 AI-AI, 0 decor.
func play_sfx_at(sfx_name: StringName, pos: Vector3, pitch: float = 1.0,
		volume_db: float = -6.0, priority: int = 1, jitter: float = 0.03) -> AudioStreamPlayer3D:
	var snd := stream(sfx_name)
	if snd == null or _pool3d.is_empty():
		return null
	var now := float(clock.call())
	var idx := -1
	# „Liber" = ceasul `clock` a trecut de sfarsitul sunetului, nu `playing`: pe
	# desktop e acelasi lucru, dar in sondele headless (simulare mai rapida decat
	# timpul real) `playing` ramane adevarat mult dupa ce sunetul ar fi trebuit sa se
	# termine, iar comportamentul pool-ului ar depinde de viteza masinii.
	for i in _pool3d.size():
		if now >= _p3_until[i]:
			idx = i
			break
	if idx < 0:
		var best_prio := 1 << 30
		var best_start := INF
		for i in _pool3d.size():
			if _p3_prio[i] < best_prio \
					or (_p3_prio[i] == best_prio and _p3_start[i] < best_start):
				best_prio = _p3_prio[i]
				best_start = _p3_start[i]
				idx = i
		if _p3_prio[idx] > priority:
			return null
	var player := _pool3d[idx]
	player.stream = snd
	player.global_position = pos
	player.pitch_scale = pitch * (randf_range(1.0 - jitter, 1.0 + jitter) if jitter > 0.0 else 1.0)
	player.volume_db = volume_db
	player.play()
	_p3_prio[idx] = priority
	_p3_start[idx] = now
	_p3_until[idx] = now + snd.get_length() / maxf(player.pitch_scale, 0.1)
	_log(sfx_name, volume_db, player.pitch_scale, true, pos)
	return player


## Playerele 3D (sonde: pozitii, volume).
func pool3d() -> Array[AudioStreamPlayer3D]:
	return _pool3d


## Cate playere 3D sunt ocupate ACUM, dupa `clock` (sonde).
func pool3d_busy() -> int:
	var now := float(clock.call())
	var n := 0
	for i in _pool3d.size():
		if now < _p3_until[i]:
			n += 1
	return n


## Pozitia camerei active (urechea), sau Vector3.INF daca nu exista.
func listener_position() -> Vector3:
	var vp := get_viewport()
	if vp != null:
		var cam := vp.get_camera_3d()
		if cam != null:
			return cam.global_position
	return Vector3.INF


## Punctul e destul de aproape de ureche? (fara camera: da, nu stim.)
func in_range(pos: Vector3, range_m: float) -> bool:
	var l := listener_position()
	return not l.is_finite() or l.distance_to(pos) <= range_m


# ----------------------------------------------------------------- claxon, stinger, decor, hazarde

## Claxonul de jucarie al unei masini (`key` = id-ul ei): pozitional, cu pauza
## per masina si una globala, doar in raza `horn_range_m`. Fiecare masina are
## propriul ton (din `key`), ca doua claxoane sa nu fie acelasi sunet.
## Intoarce true daca a sunat.
func honk(key: int, pos: Vector3) -> bool:
	var now := float(clock.call())
	if float(_horn_ready.get(key, -1.0e9)) > now or now < _horn_global_until:
		return false
	if not in_range(pos, horn_range_m):
		return false
	_horn_ready[key] = now + horn_cooldown_s
	_horn_global_until = now + horn_global_gap_s
	var tone := 0.84 + float(posmod(key, 9)) * 0.045
	play_sfx_at(&"toy_horn", pos, tone, horn_db, 2, 0.0) # tonul masinii: fara zgomot
	return true


## Stinger la schimbarea pozitiei jucatorului (PositionWatch.announced): urcare
## daca pozitia noua e mai buna (numar mai mic), coborare altfel.
func play_stinger(new_pos: int, old_pos: int) -> void:
	if new_pos == old_pos or new_pos <= 0 or old_pos <= 0:
		return
	_play_2d(&"stinger_up" if new_pos < old_pos else &"stinger_down", 1.0,
		stinger_db, 0.0)


## Contactul unui hazard mobil cu o masina, din hazard (ghiontul). Pozitional, cu
## pauza globala; masina AI suna mai incet. Intoarce true daca a sunat.
func hazard_contact(sfx_name: StringName, pos: Vector3, player_involved: bool) -> bool:
	if not EVENT_SFX.has(sfx_name):
		return false
	var now := float(clock.call())
	if now < _hazard_until or not in_range(pos, hazard_range_m):
		return false
	_hazard_until = now + hazard_interval_s
	play_sfx_at(sfx_name, pos, randf_range(0.95, 1.05),
		hazard_db + (0.0 if player_involved else hazard_ai_offset_db),
		3 if player_involved else 1)
	return true


## Decor usor lovit (PropDebris): „tac" de lemn/plastic la `pos`, `k` in [0, 1]
## dupa puterea loviturii. Cel mai de jos in prioritate si cu pauza proprie.
func prop_knock(pos: Vector3, k: float) -> bool:
	var now := float(clock.call())
	if now < _knock_until or not in_range(pos, knock_range_m):
		return false
	_knock_until = now + knock_interval_s
	var kk := clampf(k, 0.0, 1.0)
	play_sfx_at(_pick_variant(&"knock"), pos, lerpf(1.2, 0.88, kk),
		lerpf(knock_db_min, knock_db_max, kk), 0)
	return true


# ----------------------------------------------------------------- comune

## O varianta a stratului, la intamplare, niciodata aceeasi ca data trecuta.
func _pick_variant(layer: StringName) -> StringName:
	var names: Array = IMPACT_LAYERS[layer]
	var last := int(_last_variant.get(layer, -1))
	var i := randi() % names.size()
	if names.size() > 1 and i == last:
		i = (i + 1 + randi() % (names.size() - 1)) % names.size()
	_last_variant[layer] = i
	return names[i]


## Ca play_sfx(), dar cu zgomotul de pitch ales de apelant (0 = niciunul: stinger-ele
## sunt note, nu zgomote) si cu intrare in jurnal.
func _play_2d(sfx_name: StringName, pitch: float, volume_db: float,
		jitter: float = 0.04) -> void:
	var snd := stream(sfx_name)
	if snd == null:
		return
	var player := _pool[_next]
	for i in POOL_SIZE:
		var candidate := _pool[(_next + i) % POOL_SIZE]
		if not candidate.playing:
			player = candidate
			break
	_next = (_pool.find(player) + 1) % POOL_SIZE
	player.stream = snd
	player.pitch_scale = pitch * (randf_range(1.0 - jitter, 1.0 + jitter) if jitter > 0.0 else 1.0)
	player.volume_db = volume_db
	player.play()
	_log(sfx_name, volume_db, player.pitch_scale, false, Vector3.INF)


func _log(sfx_name: StringName, volume_db: float, pitch: float, positional: bool,
		pos: Vector3) -> void:
	sfx_log.append({"name": sfx_name, "db": volume_db, "pitch": pitch,
		"positional": positional, "pos": pos, "frame": Engine.get_physics_frames()})
	if sfx_log.size() > 128:
		sfx_log.pop_front()
