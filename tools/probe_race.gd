extends Node
## Sonda de TUNARE: masoara ce simti pe pista, dar in cifre. Doua moduri, ambele
## headless, ca sa poti compara "inainte / dupa" la fiecare schimbare de fizica
## sau de AI (CLAUDE.md: verificare cu sonde inainte de commit).
##
##   race  — o cursa cu 4 AI pe o pista: tururi, timp in afara soselei, timp
##           mers incet, marsarier de anti-blocaj, repuneri, izbituri in pereti,
##           imbranceli si lovituri de la obstacolele mobile.
##   bump  — matricea de imbranceli intre masini: cine pe cine arunca si cu cat.
##           Aici se vede daca "grea impinge, usoara zboara" e adevarat.
##   cliff — arunca masini in unghi in peretii de canion, in mai multe puncte de
##           pe traseu, si raporteaza daca vreuna ramane intepenita. Peretii sunt
##           ~130 de forme convexe puse cap la cap; imbinarile dintre ele sunt
##           exact locul unde o masina se poate agata.
##
## Rulare (ca SCENA, nu ca --script: avem nevoie de autoload-urile GameState /
## AudioManager, iar acelea nu exista in modul --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn
##   ... -- --mode=bump
##   ... -- --mode=race --track=0 --seconds=150 [--car=0]
##   ... -- --mode=cliff --track=0

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
## `--slice=a,b`: felia de traseu (fractii) raportata separat. (-1,-1) = fara.
var _slice: Vector2 = Vector2(-1.0, -1.0)
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Seed fix: fixeaza ZARURILE (rocket start, variatia de viteza, linia
## fiecarui AI), ca "inainte / dupa" sa porneasca din aceeasi cursa.
##
## [b]NU fixeaza si fizica, si asta trebuie stiut inainte de a citi o cifra ca
## pe o regresie.[/b] Jolt ruleaza pe mai multe fire, iar ordinea in care
## rezolva insulele de contact depinde de cum arata arborele de broadphase —
## deci de cate corpuri si cate triunghiuri de coliziune sunt in lume. Doua
## rulari ale ACELUIASI cod, cu ACELASI seed, pot da rezultate diferite, si
## masurat chiar dau: pe Track12 seed 3 a dat 2 repuneri intr-o rulare si
## 0/0/0 in urmatoarele trei, fara nicio schimbare de cod intre ele.
##
## Consecinta practica, verificata pe pasajul rotativ din Chongqing: orice
## schimbare care taie sau adauga geometrie de coliziune rearanjeaza arborele
## si perturba contactele pe TOATA pista, inclusiv la 366 m de locul schimbat
## si la 20 s inainte ca vreo masina sa ajunga acolo. Gaura din carosabilul de
## sub tronson scoate 304 triunghiuri din corpul soselei (76108 -> 75804), si
## atat a fost de ajuns ca pe seed 2 pilotul sa fie imbrancit de pe cornisa la
## frac 0.30 in fiecare rulare — desi lumea de la cornisa e IDENTICA bit cu bit
## (amprenta de raycast 32719.8205 in ambele variante).
##
## [b]„Determinist + se comuta dintr-un steag” NU inseamna cauzal[/b] — si
## asta nu e o opinie, e masurat. Tentatia e mare: doua repuneri care apar la
## ACEEASI milisecunda si in ACEEASI pozitie in fiecare rulare, si care dispar
## cand stingi un steag, arata exact ca o relatie cauzala. Trei runde la rand
## au tras concluzia asta despre gaura din carosabilul pasajului rotativ.
##
## [b]Cat de mica e perturbatia care ajunge.[/b] Doua apeluri `print` adaugate
## in `race.gd`, pe ramuri care nu se executa NICIODATA in rularea masurata
## (nu s-a tiparit nimic), au mutat repunerile de pe seed 2 de la t=30.8/37.6 s
## la t=42.2/59.4 s, si numarul de la 2,2,2 la 2,2,3. Cod mort, zero schimbari
## in lume, alt rezultat.
##
## [b]De UNDE pleaca diferenta.[/b] Cu trasoare IDENTICE pe amandoua partile
## (acelasi seed, acelasi numar de print-uri, deci acelasi cost), pozitia
## fiecarei masini comparata cadru cu cadru se despica asa:
##
##   t =  6.70 s   prima diferenta: 1 CENTIMETRU, pe car2 (un AI), la frac
##                 0.018 — dreapta de start, y 65, ruta 0, viteza constanta,
##                 fara niciun hazard, la un sfert de tur de cornisa
##   t =  8.05 s   1.25 m          t =  9.05 s    9.7 m
##   t = 10.05 s     31 m          t = 13.05 s     68 m
##   t = 29.40 s   ~50 m           <- abia ACUM masina cade de pe cornisa
##
## Adica la momentul caderii cele doua rulari au masinile la zeci de metri una
## de alta: nu se compara acelasi eveniment in doua variante, se compara doua
## curse diferite. Nici cauza caderii nu e o imbranceala — masina intra pe
## cornisa cu 5 m mai la stanga (x -250.9 fata de -246.0 la acelasi index) si
## deja incetinind (24.8 fata de 31.4 m/s).
##
## [b]Izolarea care inchide subiectul.[/b] Pe ramura INTREAGA — rutele noi,
## testul de etaj din `resolve_route`, ocolul, codul nou de AI, tot — cu
## `PROBE_NO_ROAD_HOLE=1`, adica singura variabila stinsa fiind gaura din
## carosabil, seed 2 da 0, 0, 0. Deci cele 261 de linii noi din `track.gd`
## (indexare, progres, `closest_index_global`, ordinea rutelor) NU sunt cauza:
## sunt toate active cand cifra e 0. Ce misca seed 2 e strict inventarul de
## triunghiuri de coliziune al soselei (304 scoase, 76108 -> 75804), prin
## ordinea in care Jolt isi imparte arborele de broadphase.
##
## Acelasi comutator da si perechea cea mai stransa care se poate face —
## acelasi binar, acelasi cod, un singur steag — pe 16 seed-uri x 150 s:
##
##   seed:        1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
##   cu gaura:    0  2  0  0  0  0  0  0  0  0  0  0  0  0  0  0
##   fara gaura:  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
##
## Un singur seed din 16 se misca, si acela e chiar cel pe care s-a construit
## acuzatia. Restul de 15 sunt identici cu gaura pornita.
##
## [b]Si cat de „determinist" e seed 2 de fapt.[/b] Pe starea finala, cu ZERO
## linii de cod runtime schimbate (`scenes/` neatins, doar comentarii aici),
## noua rulari consecutive au dat 2, 2, 3, 2, 2, 2, 2, 2, 2. Chiar si cifra
## „stabila" fluctueaza intre rulari ale aceluiasi binar.
##
## [b]Regula care ramane in picioare.[/b] O repunere pe o muchie expusa e o
## proprietate a MUCHIEI, nu a schimbarii care a reasezat zarurile. Ca sa
## acuzi o schimbare de o regresie iti trebuie ori (a) o cauza care se poate
## urmari in lume — geometrie mutata, o cota schimbata, o linie de AI care
## chiar ajunge acolo — ori (b) o diferenta care supravietuieste MEDIERII pe
## multe seed-uri. Un singur seed nu e o masuratoare, oricat de repetabil ar
## fi: e o realizare a zarurilor, si zarurile se schimba de la orice.
##
## Tot pe 16 seed-uri, dar comparand cu `origin/main` — deci o pereche mai
## slaba decat cea de mai sus, fiindca difera mai multe lucruri deodata:
##
##   seed:      1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16   TOTAL
##   baseline:  0  0  1  0  0  0  0  0  0  0  0  1  0  0  0  0   2
##   ramura:    0  2  1  0  0  0  0  0  0  0  0  0  0  0  0  0   3
##
## Se citeste cu grija: e o singura rulare per seed, iar seed 3 — trecut cu 1
## aici — a dat 2,0,0,2 pe patru rulari ale ACELUIASI cod. Totalurile 2 si 3
## stau amandoua in zgomotul metodei; perechea cu un singur steag de mai sus e
## cea care spune ceva.
##
## Toate caderile de pe cornisa, pe ambele parti, cad intre frac 0.301 si 0.316,
## la aceeasi pozitie (-250..-237, y 34).
##
## [b]Pentru „e cornisa mai periculoasa acum?" nu se mai foloseste sonda asta.[/b]
## `tools/ProbeCornice.tscn` masoara GEOMETRIA marginii — latimea politei,
## pragul lateral, panta de dupa buza — deci nu depinde nici de seed, nici de
## ordinea contactelor. Pe ramura si pe `origin/main` da acelasi rezultat pana
## la a treia zecimala: polita 6.75 m, prag 2.438 m, panta 2.59 m/m. Cornisa e
## neatinsa de ramura; ce s-a schimbat e care seed o nimereste.
##
## Deci: se compara DISTRIBUTII pe mai multe seed-uri si mai multe rulari, nu o
## cifra cu alta, iar pentru o proprietate a LUMII se cauta o sonda de lume.
## Vezi memoria `proberace-nedeterminism`.
const SEED: int = 20260729
## Suprascris cu --seed=N: acelasi cod, seed-uri diferite = mai multe curse
## independente. Un blocaj care apare la 1 din 5 seed-uri e tot un blocaj.
var _seed: int = SEED
## Masina jucatorului, index in GameState.CAR_DATA. Suprascris cu --car=N.
## 0 = Muscle, masina de referinta a proiectului.
var _player_car: int = 0
## Numarul de adversari AI. -1 = nu se atinge GameState.ai_count (implicitul
## de joc, 5 -> 6 masini pe grila). Suprascris cu --ai=N — Fiordland cere 8
## masini pe grila (brief §7 pasul 3: 8 masini, fara decor, pe tunelul cu
## semafor), peste implicitul de 6.
var _ai_count: int = -1
## Viteza de sosire a atacatorului in modul bump (m/s).
const BUMP_ENTRY_SPEED: float = 26.0

# --- modul cliff ---
## Cu ce viteza se arunca masina in perete.
const CLIFF_ENTRY_SPEED: float = 20.0
## Unghiul fata de directia drumului: 0 = paralel, 90 = perpendicular pe perete.
## 35° e cazul rau realist — o iesire larga din viraj, nu un impact frontal.
const CLIFF_ANGLE_DEG: float = 35.0
## Cat timp se urmareste fiecare caz. Generos: AI-ul are anti-blocaj cu marsarier,
## si vrem sa-i dam sansa sa-l foloseasca inainte sa-l declaram blocat.
const CLIFF_CASE_SECONDS: float = 8.0
## Sub viteza asta masina e considerata "oprita".
const CLIFF_STUCK_SPEED: float = 2.0
## Cat timp trebuie sa stea oprita ca sa fie declarata INTEPENITA. Peste durata
## manevrei de desprindere (frana + marsarier + reluare), ca sa nu confundam o
## recuperare reusita cu un blocaj.
const CLIFF_STUCK_SECONDS: float = 3.5
## Fractiile de traseu testate. Alese sa acopere: doua drepte, doua viraje, si
## doua zone unde sectiunile de faleza se imbina in unghi.
const CLIFF_FRACS: Array[float] = [0.12, 0.31, 0.44, 0.58, 0.73, 0.91]

var _mode: String = "race"
var _track_index: int = 0
var _seconds: float = 150.0
## `--rain=1`: fortata ploaia peste orice `RainCycle` de pe pista, prin
## `force_factor(1.0)` (Fiordland, docs/track_briefs/fiordland.md §7 pasul
## de verdict "o rulare cu ploaia fortata"). 0 = neatins, pista ramane pe
## ciclul ei normal (uscat la start). Pistele fara `RainCycle` ignora steagul.
var _force_rain: bool = false

var _race: Node = null
var _elapsed: float = 0.0
var _stats: Array[Dictionary] = []
var _done: bool = false

## Fiordland (Track16), verdictul de flotă pentru TunnelSignalHazard (brief
## `docs/track_briefs/fiordland.md` §3 „Semaforul tunelului"): evenimente
## DISCRETE, nu cadre de contact — `bus_hits` de mai sus numără CADRE cu
## coliziunea activă (un singur ghiont poate ține 20-40 de cadre), ceea ce
## suprapune „un contact" cu „un contact lung". Aici agățăm direct semnalele
## proprii ale hazardului (`bus_hit`, `signal_changed`) pentru cifre pe
## EVENIMENT, comparabile cu criteriile din brief (contacte pe verde ≤ 1/seed
## etc.). No-op pe orice altă pistă (grupul e gol).
var _signal_bus_hits: int = 0
var _signal_ran_red_clear: int = 0
var _signal_max_queue: int = 0
## Cate masini erau "asteapta la semafor" (viteza mica, in raza semaforului)
## in ultimul tick verificat — pentru coada maxima simultana.
var _signal_hazards: Array[TunnelSignalHazard] = []
var _signal_bus_hits_green: int = 0
var _signal_bus_hits_red: int = 0
## Ultimul local.z (fata de semafor) vazut per masina, pentru detectia
## trecerii liniei (semnul lui local.z schimba de la - la +).
var _signal_last_z: Dictionary = {}

## Pista taiata in felii egale, ca sa vezi UNDE se scurge viteza.
const BUCKETS: int = 20
var _bucket_speed: PackedFloat32Array = PackedFloat32Array()
var _bucket_samples: PackedInt32Array = PackedInt32Array()
var _bucket_slow: PackedInt32Array = PackedInt32Array()
var _bucket_walls: PackedInt32Array = PackedInt32Array()

# --- mod cliff ---
var _cliff_cases: Array[Dictionary] = []
var _cliff_case: int = -1
var _cliff_car: Car = null
var _cliff_track: Track = null
var _cliff_time: float = 0.0
var _cliff_slow_time: float = 0.0
var _cliff_rows: Array[Dictionary] = []

# --- mod bump ---
var _bump_cases: Array[Dictionary] = []
var _bump_case: int = -1
var _bump_frames: int = 0
var _bump_attacker: Car = null
var _bump_victim: Car = null
var _bump_rows: Array[Dictionary] = []
var _bump_peak: float = 0.0
var _bump_attacker_loss: float = 0.0
## Directia initiala a victimei — diferenta finala e rotatia PRIMITA din lovitura.
var _bump_victim_yaw0: float = 0.0
## Cea mai mica viteza a atacatorului dupa contact: "zidul" se vede aici — pe
## modelul vechi cobora la ~0 chiar si intre mase egale, desi fizica cerea ca
## amandoua masinile sa-si continue drumul.
var _bump_attacker_floor: float = 0.0
var _bump_impulses_att: int = 0
var _bump_impulses_vic: int = 0
var _bump_impulse_peak_att: float = 0.0
var _bump_impulse_peak_vic: float = 0.0

## Controller de laborator: comenzi fixe, fara "creier".
class ScriptedController extends CarController:
	var throttle: float = 1.0
	var steer: float = 0.0

	func get_throttle() -> float:
		return throttle

	func get_steer() -> float:
		return steer


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--car="):
			_player_car = int(arg.trim_prefix("--car="))
		elif arg.begins_with("--ai="):
			_ai_count = int(arg.trim_prefix("--ai="))
		elif arg.begins_with("--slice="):
			var ab := arg.trim_prefix("--slice=").split(",")
			_slice = Vector2(float(ab[0]), float(ab[1]))
		elif arg.begins_with("--rain="):
			_force_rain = int(arg.trim_prefix("--rain=")) != 0
	# Masina jucatorului se FIXEAZA, nu se mosteneste.
	#
	# `GameState.selected_car` se salveaza in `user://settings.cfg`, deci sonda
	# rula pe orice masina ai ales ultima data cand ai deschis jocul. Doua rulari
	# ale aceluiasi cod dadeau 3.96 si 3.57 tururi si arata ca o regresie de la
	# assets — de fapt se schimbase masina sub noi. Aceeasi capcana ca la
	# --mode=cliff, care nu-si seta `car.track` si masura altceva decat credea.
	GameState.selected_car = clampi(_player_car, 0, GameState.CAR_DATA.size() - 1)
	if _ai_count >= 0:
		GameState.ai_count = _ai_count
	# `--track=` ia POZITIA din lista (Stromboli = 4), dar accepta si numarul
	# scenei (--track=11). Fara verificarea asta, un index gresit nu se plangea
	# aici, ci pica mai tarziu cu "Out of bounds" si turna zeci de mii de erori
	# derivate, in care cauza nu se mai vedea.
	var resolved := GameState.resolve_track_index(_track_index)
	if resolved < 0:
		push_error("probe_race: --track=%d nu e nici pozitie in lista (0..%d), nici numar de pista din lista."
			% [_track_index, GameState.TRACK_SCENES.size() - 1])
		get_tree().quit(1)
		return
	_track_index = resolved
	print("probe_race: pista %s" % GameState.track_label(_track_index))
	match _mode:
		"race":
			_start_race()
		"bump":
			_start_bump()
		"cliff":
			_start_cliff()
		_:
			push_error("probe_race: mod necunoscut '%s'" % _mode)
			get_tree().quit(1)


func _physics_process(delta: float) -> void:
	if _done:
		return
	match _mode:
		"bump":
			_tick_bump()
		"cliff":
			_tick_cliff(delta)
		_:
			_tick_race(delta)


func _finish() -> void:
	_done = true
	get_tree().quit(0)


# --------------------------------------------------------------- mod cursa

func _start_race() -> void:
	GameState.selected_track = _track_index
	GameState.champ_active = false
	GameState.total_laps = 99 # cursa nu se termina singura; o oprim pe timp
	_bucket_speed.resize(BUCKETS)
	_bucket_samples.resize(BUCKETS)
	_bucket_slow.resize(BUCKETS)
	_bucket_walls.resize(BUCKETS)
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	# Si rocket start-ul AI-ului trage la zaruri; fara seed fix, doua rulari ale
	# ACELUIASI cod pornesc diferit si "inainte / dupa" nu mai compara nimic.
	(_race._rng as RandomNumberGenerator).seed = _seed
	# Jucatorul primeste tot un creier AI: masuram pista, nu reflexele mele.
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car == player:
			var ai := AIController.new()
			car.set_controller(ai)
			ai.configure(_race.track, rng, cars)
		else:
			(car.controller as AIController).line_offset = rng.randf_range(-0.35, 0.35)
		# Variatie onesta, dar determinista — altfel cifrele danseaza intre rulari.
		car.speed_scale = 1.0 if car == player else rng.randf_range(0.88, 0.97)
		_stats.append({
			"name": "%s (%s)" % [car.pilot_name, car.car_name],
			"offroad_s": 0.0, "slow_s": 0.0, "reverse_s": 0.0,
			"respawns": 0, "walls": 0, "wall_impact": 0.0,
			"ejects_wall": 0, "ejects_land": 0, "land_max": 0.0,
			"bumps": 0, "bump_peak": 0.0,
			"slide_hits": 0, "carousel_hits": 0, "deflector_hits": 0,
			"bus_hits": 0,
			"sl_speed": 0.0, "sl_samples": 0, "sl_slow": 0.0, "sl_walls": 0, "sl_bus": 0,
			"speed_sum": 0.0, "samples": 0,
			"stuck_t": 0.0, "stuck_reports": 0,
			"branch_laps": 0, "branch_s": 0.0, "last_route": 0,
		})
		car.respawned.connect(_on_respawn.bind(i))
		car.wall_hit.connect(_on_wall.bind(i))
		# Ejectarile soferului (masini deschise): cauza si marimea, ca pragurile
		# din Car (eject_wall_dv / eject_land_speed) sa se tuneze pe cifre, nu pe
		# impresii. Aterizarea maxima FARA ejectare spune cat de aproape e o
		# saritura proiectata de prag.
		car.ejected.connect(_on_eject.bind(i))
		# `landed` se emite INAINTE de decizia de ejectare, deci se compara cu
		# pragul, nu cu starea masinii.
		car.landed.connect(func(c: Car, fall: float) -> void:
			if fall < c.eject_land_speed:
				_stats[i].land_max = maxf(float(_stats[i].land_max), fall))
		# Delta-v-ul REAL al imbrancelii, direct din model. Masurat ca diferenta
		# de viteza intre cadre ar aduna si gravitatia, aterizarile si turbo.
		# Conditionat: pe versiunile de dinaintea modelului de masa semnalul nu
		# exista, iar sonda trebuie sa poata masura si acele rulari (coloana
		# "bump/dv" ramane goala acolo, restul cifrelor sunt comparabile).
		if car.has_signal(&"bumped"):
			car.bumped.connect(_on_bumped.bind(i))
	_setup_signal_hazards()
	if _force_rain:
		_force_rain_cycle()


## `--rain=1`: gaseste orice `RainCycle` prin grupul lui (`rain_cycle`, vezi
## RainCycle._ready) si il fixeaza in ploaie plina — acelasi apel pe care il
## foloseste sonda A/B a ploii (`ProbeFiordPloaie`). Pista ramane astfel udata
## din primul cadru, in loc sa astepte ~5-30s din ciclul de 95s pana la prima
## fereastra de ploaie. Gol pe orice pista fara `RainCycle`.
func _force_rain_cycle() -> void:
	for node in get_tree().get_nodes_in_group(&"rain_cycle"):
		if node.has_method("force_factor"):
			node.call("force_factor", 1.0)


## Fiordland: agata contorul de evenimente pe orice TunnelSignalHazard din
## grupul lui (vezi TunnelSignalHazard.AI_GROUP). Gol pe orice alta pista.
func _setup_signal_hazards() -> void:
	for node in get_tree().get_nodes_in_group(TunnelSignalHazard.AI_GROUP):
		var sig := node as TunnelSignalHazard
		if sig == null:
			continue
		_signal_hazards.append(sig)
		sig.bus_hit.connect(_on_signal_bus_hit)


func _tick_race(delta: float) -> void:
	_elapsed += delta
	var cars: Array[Car] = _race.cars
	# PROBE_RACE_TRACE=2: acelasi tabel, dar la 0,1 s si doar in fereastra
	# 60-70 s — diagnostic ad-hoc pentru un respawn reproductibil la un frac
	# fix, fara sa umple logul pe toata cursa. Fereastra si pasul se schimba
	# de mana cand se ancheteaza alt interval.
	var trace_env := OS.get_environment("PROBE_RACE_TRACE")
	if trace_env == "2" and _elapsed >= 60.0 and _elapsed <= 70.0 \
			and int(_elapsed * 60.0) % 6 == 0:
		for i in cars.size():
			var c := cars[i]
			print("FTRACE t=%6.2f car%d frac=%.4f on_road=%s v=%5.1f pos=(%.1f,%.2f,%.1f) vel=%s"
				% [_elapsed, i, _race.track.frac_at(c.road_index, c.route),
					_race.track.is_on_road(c.road_index, c.global_position, c.route),
					c.horizontal_speed(), c.global_position.x, c.global_position.y,
					c.global_position.z, c.linear_velocity])
	if trace_env == "1" \
			and int(_elapsed * 60.0) % 120 == 0:
		for i in cars.size():
			var c := cars[i]
			print("TRACE t=%5.1f car%d frac=%.3f on_road=%s v=%4.1f pos=(%.0f,%.1f,%.0f)" % [
				_elapsed, i,
				_race.track.frac_at(c.road_index, c.route),
				_race.track.is_on_road(c.road_index, c.global_position,
					c.route), c.horizontal_speed(),
				c.global_position.x, c.global_position.y, c.global_position.z])
	for i in cars.size():
		var car := cars[i]
		var st := _stats[i]
		var speed := car.horizontal_speed()
		st.speed_sum = float(st.speed_sum) + speed
		st.samples = int(st.samples) + 1
		if not _race.track.is_on_road(car.road_index, car.global_position,
				car.route):
			st.offroad_s = float(st.offroad_s) + delta
		if speed < 4.0:
			st.slow_s = float(st.slow_s) + delta
		# Banda secundara: cine si cat o foloseste. Fara cifra asta, "AI-ul ia
		# ocolul" ramane o presupunere — pe gatul cu piatra din Cappadocia
		# bifurcatia exista doar daca macar un pilot chiar trece pe ea.
		if car.route > 0:
			st.branch_s = float(st.branch_s) + delta
			if int(st.last_route) == 0:
				st.branch_laps = int(st.branch_laps) + 1
		st.last_route = car.route
		if car.controller != null and car.controller.get_throttle() < -0.5:
			st.reverse_s = float(st.reverse_s) + delta
		# Pe fizica intreaga contactele vin de la solver (contact_monitor e
		# pornit in Car._ready), nu din move_and_slide.
		for hit in car.get_colliding_bodies():
			if hit is SlidingHazard:
				st.slide_hits = int(st.slide_hits) + 1
			elif _is_under(hit as Node, "CarouselHazard"):
				# Rotorul caruselului e COPIL al hazardului, deci colizionerul
				# nu e niciodata hazardul insusi.
				st.carousel_hits = int(st.carousel_hits) + 1
			elif _is_under(hit as Node, "DeflectorHazard"):
				st.deflector_hits = int(st.deflector_hits) + 1
			elif _is_under(hit as Node, "BusHazard"):
				# Autobuzul de pe serpentine (Machu Picchu): corp cinematic
				# pe traseu; contactul se numara ca la minge/deviator.
				st.bus_hits = int(st.bus_hits) + 1
				if _in_slice(_race.track.frac_at(car.road_index, car.route)):
					st.sl_bus = int(st.sl_bus) + 1
		# FELIA ceruta cu --slice=a,b: aceleasi cifre, doar pe portiunea aia —
		# pentru un hazard local (autobuzul de pe serpentine) media pe tot turul
		# ascunde tot ce conteaza.
		var fr_here: float = _race.track.frac_at(car.road_index, car.route)
		if _in_slice(fr_here):
			st.sl_speed = float(st.sl_speed) + speed
			st.sl_samples = int(st.sl_samples) + 1
			if speed < 4.0:
				st.sl_slow = float(st.sl_slow) + delta
		# Harta pistei: unde anume se scurge viteza. Fara ea nu stii daca AI-ul
		# pierde in acelasi viraj de fiecare data sau imprastiat peste tot.
		var b := clampi(int(_race.track.frac_at(car.road_index, car.route)
			* float(BUCKETS)),
			0, BUCKETS - 1)
		_bucket_speed[b] += speed
		_bucket_samples[b] += 1
		if speed < 4.0:
			_bucket_slow[b] += 1
		_watch_stuck(car, st, speed, delta)
	if not _signal_hazards.is_empty():
		_watch_signal_fleet(cars)
	if _elapsed >= _seconds:
		_report_race()


## Fiordland: treceri pe rosu (masina trece de linia semaforului CAT e rosu)
## si coada maxima simultana (masini oprite in raza semaforului). Distinct de
## `_watch_stuck` (generic, orb la asteptarea legitima): aici stim EXACT ce
## inseamna "asteapta la semafor" — acelasi test ca AIController.SIGNAL_BRAKE_M.
func _watch_signal_fleet(cars: Array[Car]) -> void:
	var sig := _signal_hazards[0]
	var red := sig.is_red()
	var queued := 0
	for car in cars:
		# Pozitia masinii in coordonatele semaforului: local +Z e spre tunel (vezi
		# antetul TunnelSignalHazard), deci local.z < 0 e pe apropiere, > 0 in tunel.
		var local_pos: Vector3 = sig.to_local(car.global_position)
		var id := car.get_instance_id()
		var prev_z: float = _signal_last_z.get(id, local_pos.z)
		# Trecere de linie: local.z trece de la negativ la pozitiv, aproape de axa
		# (nu departe pe o nisa), CU VITEZA REALA de inaintare (nu jitter de coada
		# la 0 m/s) -- daca semaforul e rosu chiar atunci, e o trecere pe rosu
		# clara. Fara pragul de viteza, o masina oprita chiar langa linie (jitter
		# de contact intre masini in coada) oscileaza peste z=0 la viteza ~0 si
		# se numara gresit ca "a trecut pe rosu" -- masurat: toate cele 11
		# raportari initiale erau la poz aproape identica (~2-5m de linie),
		# semn de jitter de coada, nu de traversare reala a tunelului.
		var speed := car.horizontal_speed()
		if prev_z < 0.0 and local_pos.z >= 0.0 and absf(local_pos.x) < 4.0 \
				and red and speed > 4.0:
			_signal_ran_red_clear += 1
			print("[trecere-pe-rosu] t=%5.1fs  v=%4.1f  poz=(%.0f,%.0f,%.0f)  rosu_ramas=%.1fs" % [
				_elapsed, speed, car.global_position.x, car.global_position.y,
				car.global_position.z, sig.red_seconds_left()])
		_signal_last_z[id] = local_pos.z
		# Coada: aproape de linie (in raza de decizie AI), viteza mica, inca de
		# partea de apropiere (nu deja in tunel).
		if local_pos.z < 5.0 and local_pos.z > -TunnelSignalHazard.AI_REACH_M \
				and speed < 2.0:
			queued += 1
	_signal_max_queue = maxi(_signal_max_queue, queued)


func _in_slice(frac: float) -> bool:
	if _slice.x < 0.0:
		return false
	var f := fposmod(frac, 1.0)
	if _slice.x <= _slice.y:
		return f >= _slice.x and f <= _slice.y
	return f >= _slice.x or f <= _slice.y


func _is_under(node: Node, type_name: String) -> bool:
	var walker := node
	while walker != null:
		if walker.is_class(type_name) or (walker.get_script() != null
				and (walker.get_script() as Script).get_global_name() == type_name):
			return true
		walker = walker.get_parent()
	return false


## Un blocaj adevarat nu e "o clipa de incetinire", e o masina care nu mai
## progreseaza. Il raportam cu loc si vinovat — altfel tunezi in orb.
func _watch_stuck(car: Car, st: Dictionary, speed: float, delta: float) -> void:
	if _race.state != Race.State.RUNNING or speed > 6.0:
		st.stuck_t = 0.0
		return
	st.stuck_t = float(st.stuck_t) + delta
	if float(st.stuck_t) < 3.0 or int(st.stuck_reports) >= 6:
		return
	st.stuck_t = 0.0
	st.stuck_reports = int(st.stuck_reports) + 1
	var touching: Array[String] = []
	for body in car.get_colliding_bodies():
		var hit := body as Node3D
		if hit != null:
			touching.append("%s@(%.0f,%.0f,%.0f)" % [_describe(hit),
				hit.global_position.x, hit.global_position.y, hit.global_position.z])
	print("[blocaj] t=%5.1fs  %-18s frac=%.3f  v=%4.1f  lat=%4.1f  poz=(%.0f,%.0f,%.0f)  atinge: %s" % [
		_elapsed, st.name, _race.track.frac_at(car.road_index, car.route), speed,
		_race.track.lateral_distance(car.road_index, car.global_position,
			car.route),
		car.global_position.x, car.global_position.y, car.global_position.z,
		", ".join(touching) if not touching.is_empty() else "-"])


## Numele unui corp generat procedural nu spune nimic (@StaticBody3D@31);
## mesh-ul copil si culoarea lui spun exact ce bucata de pista e.
func _describe(body: Node3D) -> String:
	if not body.name.begins_with("@"):
		return String(body.name)
	for child in body.get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var mat := mi.material_override as StandardMaterial3D
		var tint := "?" if mat == null else "#%s" % mat.albedo_color.to_html(false)
		return "%s[%s]" % [body.get_class(), tint]
	return String(body.name)


func _on_bumped(_car: Car, _other: Car, delta_v: float, index: int) -> void:
	_stats[index].bumps = int(_stats[index].bumps) + 1
	_stats[index].bump_peak = maxf(float(_stats[index].bump_peak), delta_v)


func _on_respawn(car: Car, index: int) -> void:
	_stats[index].respawns = int(_stats[index].respawns) + 1
	# Unde a fost repusa: o repunere in acelasi loc, tur de tur, e o bucla
	# (masina cade, e repusa fara elan, cade iar) — vezi CHANNEL_FALL_BACKOFF.
	print("[repunere] t=%5.1fs  %-18s frac=%.3f  poz=(%.0f,%.0f,%.0f)" % [
		_elapsed, _stats[index].name,
		_race.track.frac_at(car.road_index, car.route),
		car.global_position.x, car.global_position.y, car.global_position.z])


func _on_eject(car: Car, _ragdoll: Node3D, index: int) -> void:
	if car.last_eject_cause == "perete":
		_stats[index].ejects_wall = int(_stats[index].ejects_wall) + 1
	else:
		_stats[index].ejects_land = int(_stats[index].ejects_land) + 1
	print("[ejectare] t=%5.1fs  %-18s frac=%.3f  %s %.1f m/s  poz=(%.0f,%.0f,%.0f)" % [
		_elapsed, _stats[index].name,
		_race.track.frac_at(car.road_index, car.route),
		car.last_eject_cause, car.last_eject_value,
		car.global_position.x, car.global_position.y, car.global_position.z])


## Fiordland: contact DISCRET cu autocarul (un eveniment per ghiont, nu cadre
## de coliziune continua — vezi comentariul de la `_signal_bus_hits` mai sus).
## Clasificat verde/rosu dupa STAREA semaforului chiar in clipa impactului:
## un contact nu poate exista decat cat masina e in tunel, iar `is_red()`
## acolo distinge intre "a intrat legitim pe verde si autocarul a pornit cat
## inca era in tunel" (nu ar trebui sa se intample - vezi criteriul de verdict)
## si "a intrat/ramas pe rosu, deci risc asumat".
func _on_signal_bus_hit(car: Car) -> void:
	_signal_bus_hits += 1
	var cars: Array[Car] = _race.cars
	var idx: int = cars.find(car)
	var car_name: String = String(_stats[idx].name) if idx >= 0 else "?"
	var red: bool = not _signal_hazards.is_empty() and _signal_hazards[0].is_red()
	if red:
		_signal_bus_hits_red += 1
	else:
		_signal_bus_hits_green += 1
	print("[bus-hit] t=%5.1fs  %-18s intrata_pe=%s  poz=(%.0f,%.0f,%.0f)" % [
		_elapsed, car_name, "ROSU" if red else "VERDE",
		car.global_position.x, car.global_position.y, car.global_position.z])


func _on_wall(car: Car, impact: float, index: int) -> void:
	_stats[index].walls = int(_stats[index].walls) + 1
	if _in_slice(_race.track.frac_at(car.road_index, car.route)):
		_stats[index].sl_walls = int(_stats[index].sl_walls) + 1
	_stats[index].wall_impact = maxf(float(_stats[index].wall_impact), impact)
	var b := clampi(int(_race.track.frac_at(car.road_index, car.route)
			* float(BUCKETS)),
		0, BUCKETS - 1)
	_bucket_walls[b] += 1


func _report_race() -> void:
	var track: Track = _race.track
	var cars: Array[Car] = _race.cars
	print("\n=== CURSA: %s — %.0fs, %d masini ===" % [
		track.track_name, _elapsed, cars.size()])
	print("%-20s %6s %6s %8s %7s %7s %5s %7s %6s %9s %6s %6s %6s" % [
		"masina", "tururi", "v_med", "offroad", "lent", "invers",
		"resp", "ejec p/a", "pereti", "bump/dv", "minge", "carus", "deviat"])
	var total_ej_wall := 0
	var total_ej_land := 0
	var land_max := 0.0
	var worst_offroad := 0.0
	var total_respawns := 0
	var laps: Array[float] = []
	for i in cars.size():
		var st := _stats[i]
		var done := float(_race._progress[i].total)
		laps.append(done)
		var avg := float(st.speed_sum) / maxf(float(st.samples), 1.0)
		var off_pct := float(st.offroad_s) / _elapsed * 100.0
		worst_offroad = maxf(worst_offroad, off_pct)
		total_respawns += int(st.respawns)
		total_ej_wall += int(st.ejects_wall)
		total_ej_land += int(st.ejects_land)
		land_max = maxf(land_max, float(st.land_max))
		print("%-20s %6.2f %6.1f %7.1f%% %6.1fs %6.1fs %5d %4d/%-2d %6d %4d/%4.1f %6d %6d %6d" % [
			st.name, done, avg, off_pct, float(st.slow_s), float(st.reverse_s),
			int(st.respawns), int(st.ejects_wall), int(st.ejects_land),
			int(st.walls), int(st.bumps), float(st.bump_peak),
			int(st.slide_hits), int(st.carousel_hits), int(st.deflector_hits)])
	laps.sort()
	print("--- ritm: cel mai rapid %.2f tururi, cel mai lent %.2f (ecart %.2f)" % [
		laps[laps.size() - 1], laps[0], laps[laps.size() - 1] - laps[0]])
	print("--- repuneri totale: %d · cel mai mult in afara soselei: %.1f%%" % [
		total_respawns, worst_offroad])
	print("--- ejectari: %d (perete %d, aterizare %d) · cea mai dura aterizare FARA ejectare: %.1f m/s" % [
		total_ej_wall + total_ej_land, total_ej_wall, total_ej_land, land_max])
	var branch_total := 0
	var branch_line := ""
	for i in cars.size():
		var st := _stats[i]
		if int(st.branch_laps) > 0:
			branch_total += int(st.branch_laps)
			branch_line += "  %s: %d treceri (%.1fs)" % [
				st.name, int(st.branch_laps), float(st.branch_s)]
	print("--- banda secundara: %d treceri%s" % [branch_total,
		branch_line if branch_total > 0 else " (nimeni n-a luat-o)"])
	var bus_total := 0
	for i in cars.size():
		bus_total += int(_stats[i].bus_hits)
	if bus_total > 0 or _slice.x >= 0.0:
		print("--- contacte cu autobuzul (BusHazard): %d cadre" % bus_total)
	if not _signal_hazards.is_empty():
		print("--- semafor tunel: contacte-autocar=%d (verde: %d, rosu: %d)  treceri-pe-rosu-clare=%d  coada-maxima-simultana=%d"
			% [_signal_bus_hits, _signal_bus_hits_green, _signal_bus_hits_red,
				_signal_ran_red_clear, _signal_max_queue])
	if _slice.x >= 0.0:
		print("--- felia %.3f-%.3f: %-20s %6s %6s %7s %8s" % [_slice.x, _slice.y,
			"masina", "v_med", "lent", "pereti", "autobuz"])
		var sl_speed := 0.0
		var sl_samples := 0
		var sl_slow := 0.0
		var sl_walls := 0
		var sl_bus := 0
		for i in cars.size():
			var st := _stats[i]
			var ns := maxi(int(st.sl_samples), 1)
			print("    %-32s %6.1f %5.1f%% %7d %8d" % [st.name,
				float(st.sl_speed) / float(ns),
				float(st.sl_slow) / maxf(float(st.sl_samples) / 60.0, 0.001) * 100.0,
				int(st.sl_walls), int(st.sl_bus)])
			sl_speed += float(st.sl_speed)
			sl_samples += int(st.sl_samples)
			sl_slow += float(st.sl_slow)
			sl_walls += int(st.sl_walls)
			sl_bus += int(st.sl_bus)
		print("    %-32s %6.1f %5.1f%% %7d %8d" % ["TOTAL",
			sl_speed / float(maxi(sl_samples, 1)),
			sl_slow / maxf(float(sl_samples) / 60.0, 0.001) * 100.0, sl_walls, sl_bus])
	print("\n--- unde se scurge viteza (felie de pista -> v_med, %% lent, pereti)")
	for b in BUCKETS:
		var samples := maxi(_bucket_samples[b], 1)
		var avg := _bucket_speed[b] / float(samples)
		var slow_pct := float(_bucket_slow[b]) / float(samples) * 100.0
		var bar := "#".repeat(int(avg / 2.0))
		print("  %.2f-%.2f  %5.1f m/s %5.1f%% lent %3d pereti  %s" % [
			float(b) / float(BUCKETS), float(b + 1) / float(BUCKETS),
			avg, slow_pct, _bucket_walls[b], bar])
	_finish()


# ---------------------------------------------------------------- mod bump

## Fiecare caz: atacatorul intra din spate in victima oprita, la aceeasi viteza.
## Daca modelul de masa e corect, dv-ul victimei creste cu raportul de mase, iar
## atacatorul greu isi pierde mult mai putina viteza decat cel usor.
func _start_bump() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 2, 400)
	shape.shape = box
	shape.position = Vector3(0, -1, 0)
	ground.add_child(shape)
	add_child(ground)
	var garage := GameState.CAR_DATA
	# (atacator, victima) — perechile care conteaza pentru principiul de design.
	for pair: Array in [[3, 0], [0, 3], [0, 1], [1, 0], [4, 2], [2, 4], [0, 0]]:
		_bump_cases.append({
			"attacker": garage[pair[0]] as CarData,
			"victim": garage[pair[1]] as CarData,
			"kind": "spate",
		})
	# Loviturile DIRECTIONALE: acelasi contact, alt loc pe caroserie.
	#   colt    — din spate, dar prins pe coltul victimei (PIT): trebuie sa o
	#             roteasca vizibil, in timp ce lovitura centrata de mai sus nu.
	#   lateral — in plin, perpendicular (T-bone): victima impinsa si sucita.
	for c: Array in [[0, 0, "colt"], [0, 0, "lateral"], [3, 1, "lateral"]]:
		_bump_cases.append({
			"attacker": garage[c[0]] as CarData,
			"victim": garage[c[1]] as CarData,
			"kind": c[2],
		})
	_next_bump_case()


func _next_bump_case() -> void:
	if _bump_attacker != null:
		_bump_attacker.queue_free()
		_bump_victim.queue_free()
		_bump_attacker = null
	_bump_case += 1
	if _bump_case >= _bump_cases.size():
		_report_bump()
		return
	var c := _bump_cases[_bump_case]
	var att := c.attacker as CarData
	var vic := c.victim as CarData
	var kind := String(c.kind)
	# Victima sta pe loc, cu botul spre -Z; atacatorul soseste deja lansat:
	# masuram impactul, nu accelerarea. Amandoua in liber — O SINGURA izbitura.
	_bump_victim = _spawn_bump_car(vic, Vector3(0, 0.6, 0), 0.0)
	match kind:
		"lateral":
			# T-bone: atacatorul vine perpendicular, dinspre +X, tintit putin
			# spre spatele victimei ca sa existe brat de parghie (in realitate
			# lovitura in dreptul centrului de masa doar impinge).
			var gap_x: float = (att.body_length + vic.body_width) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att,
				Vector3(gap_x, 0.6, vic.body_length * 0.25), 0.0)
			_bump_attacker.rotate_y(PI / 2.0) # cu botul spre -X, incotro merge
			_bump_attacker.velocity = Vector3(-BUMP_ENTRY_SPEED, 0, 0)
		"colt":
			# PIT: din spate, dar decalat lateral — contactul prinde coltul.
			var gap: float = (att.body_length + vic.body_length) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att,
				Vector3(vic.body_width * 0.45, 0.6, gap), 0.0)
			_bump_attacker.velocity = Vector3(0, 0, -BUMP_ENTRY_SPEED)
		_:
			var gap: float = (att.body_length + vic.body_length) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att, Vector3(0, 0.6, gap), 0.0)
			_bump_attacker.velocity = Vector3(0, 0, -BUMP_ENTRY_SPEED)
	_bump_victim_yaw0 = _bump_victim.rotation.y
	_bump_frames = 0
	_bump_peak = 0.0
	_bump_attacker_loss = 0.0
	_bump_attacker_floor = BUMP_ENTRY_SPEED
	_bump_impulses_att = 0
	_bump_impulses_vic = 0
	_bump_impulse_peak_att = 0.0
	_bump_impulse_peak_vic = 0.0


# ----------------------------------------------------- mod cliff (anti-blocaj)

## Peretii de canion sunt ~130 de forme convexe puse cap la cap, cu suprapunere
## de 1m. Suprapunerea exista tocmai ca sa nu ramana fisuri intre ele — dar
## "fara fisuri" e o afirmatie care trebuie verificata, nu presupusa: o masina
## intepenita intr-o imbinare inseamna cursa terminata pentru jucator.
##
## Testul: arunca masina in unghi in perete, la viteza, in mai multe puncte de pe
## traseu, si urmareste daca ramane oprita. Deliberat FARA repunere automata —
## plasa de siguranta din race.gd ar ascunde exact problema pe care o cautam.
func _start_cliff() -> void:
	GameState.selected_track = _track_index
	_cliff_track = (load(GameState.TRACK_SCENES[_track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(_cliff_track)
	var n := _cliff_track.baked.size()
	for frac in CLIFF_FRACS:
		var idx := int(frac * float(n)) % n
		# Ambele laturi: peretele interior si cel exterior au offseturi diferite,
		# deci si imbinari diferite.
		for side: float in [-1.0, 1.0]:
			_cliff_cases.append({"idx": idx, "side": side, "frac": frac})
	_next_cliff_case()


func _next_cliff_case() -> void:
	if _cliff_car != null:
		_cliff_car.queue_free()
		_cliff_car = null
	_cliff_case += 1
	if _cliff_case >= _cliff_cases.size():
		_report_cliff()
		return
	var c := _cliff_cases[_cliff_case]
	var idx: int = c["idx"]
	var side: float = c["side"]
	var n := _cliff_track.baked.size()
	var p: Vector3 = _cliff_track.baked[idx]
	var fwd: Vector3 = (_cliff_track.baked[(idx + 1) % n] - p).normalized()
	var lat := fwd.cross(Vector3.UP).normalized() * side

	# Pornim de pe banda dinspre perete, indreptati spre el sub CLIFF_ANGLE_DEG.
	var start := p + lat * (_cliff_track.half_width * 0.5) + Vector3.UP * 0.6
	var dir := fwd.rotated(Vector3.UP, deg_to_rad(CLIFF_ANGLE_DEG) * -side) \
		.normalized()

	_cliff_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_cliff_car)
	_cliff_car.apply_data(GameState.CAR_DATA[0] as CarData)
	# FARA linia asta sonda masoara cu totul altceva decat crede.
	#
	# Car._physics_process sare peste actualizarea lui road_index cand track e
	# null, deci indexul ramane 0 pe veci; AIController vireaza atunci spre
	# lookahead_point(0, ...), adica spre LINIA DE START, indiferent unde e
	# masina; iar supapa lui de scapare, car.respawn(), iese imediat pentru ca
	# respawn() cere track != null. Rezultatul: masuram "tine manevra de
	# marsarier a AI-ului peste 2 m/s", nu "te prinde geometria falezei".
	_cliff_car.track = _cliff_track
	_cliff_car.road_index = _cliff_track.closest_index_global(start)
	_cliff_car.last_safe_index = _cliff_car.road_index
	_cliff_car.global_position = start
	_cliff_car.look_at(start + dir, Vector3.UP)
	_cliff_car.race_active = true
	# Un AI adevarat la volan, nu comenzi fixe.
	#
	# Prima versiune folosea ScriptedController cu volanul drept: masina intra in
	# perete si impingea in el la infinit, deci iesea "intepenita" oriunde —
	# inclusiv pe forest, care n-are faleze, doar gardul rosu de dinainte (3 din
	# 12, apoi 9 din 12 cand am adaugat un viraj fix). Masura lipsa de reactie, nu
	# geometria.
	#
	# AIController stie sa dea marsarier si sa reia linia, adica exact ce ar face
	# un jucator. Daca NICI EL nu scapa, atunci chiar e o capcana de geometrie.
	var ai := AIController.new()
	_cliff_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + _cliff_case
	ai.configure(_cliff_track, rng)
	_cliff_car.velocity = dir * CLIFF_ENTRY_SPEED
	_cliff_time = 0.0
	_cliff_slow_time = 0.0


func _tick_cliff(delta: float) -> void:
	if _cliff_car == null:
		return
	_cliff_time += delta
	var speed := Vector2(_cliff_car.velocity.x, _cliff_car.velocity.z).length()
	# Primele 0.4s sunt zborul pana la perete; nu conteaza pentru "intepenit".
	if _cliff_time > 0.4 and speed < CLIFF_STUCK_SPEED:
		_cliff_slow_time += delta
	else:
		_cliff_slow_time = 0.0
	if _cliff_time >= CLIFF_CASE_SECONDS \
			or _cliff_slow_time >= CLIFF_STUCK_SECONDS:
		var c := _cliff_cases[_cliff_case]
		_cliff_rows.append({
			"frac": c["frac"],
			"side": c["side"],
			"stuck": _cliff_slow_time >= CLIFF_STUCK_SECONDS,
			"exit_speed": speed,
			"stuck_time": _cliff_slow_time,
		})
		_next_cliff_case()


func _report_cliff() -> void:
	print("\n=== ANTI-BLOCAJ IN PERETII DE CANION (%s) ==="
		% GameState.TRACK_NAMES[_track_index])
	print("intrare %.0f m/s la %.0f°, intepenit = sub %.1f m/s mai mult de %.1fs"
		% [CLIFF_ENTRY_SPEED, CLIFF_ANGLE_DEG, CLIFF_STUCK_SPEED,
			CLIFF_STUCK_SECONDS])
	print("%8s %6s %12s %10s" % ["fractie", "parte", "viteza iesire", "stare"])
	print("-".repeat(40))
	var stuck := 0
	for row in _cliff_rows:
		if row["stuck"]:
			stuck += 1
		print("%8.2f %6s %9.1f m/s %10s" % [
			row["frac"], "st" if float(row["side"]) < 0.0 else "dr",
			row["exit_speed"], "INTEPENIT" if row["stuck"] else "ok"])
	print("\n%d cazuri, %d intepenite" % [_cliff_rows.size(), stuck])
	print("VERDICT: %s" % ("PROBLEMA" if stuck > 0 else "OK"))
	_done = true
	get_tree().quit(1 if stuck > 0 else 0)


func _spawn_bump_car(data: CarData, pos: Vector3, throttle: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	# Pozitia INAINTE de add_child: corpul intra in serverul de fizica direct
	# la locul lui. Setata dupa, exista un cadru in care ambele masini stau
	# suprapuse la origine — depenetrarea o arunca pe victima pe ACOPERISUL
	# atacatorului, unde platforma mobila o cara cu viteza proprie zero si
	# cazul masoara o plimbare, nu o izbitura (primul rand din matrice iesea
	# cu 0 impulsuri si victima "impinsa" 21 m).
	car.position = pos
	add_child(car)
	car.apply_data(data)
	car.race_active = true
	var ctrl := ScriptedController.new()
	ctrl.throttle = throttle
	car.set_controller(ctrl)
	car.bumped.connect(_on_bump_impulse)
	return car


## Numaram impulsurile REALE emise de Car._resolve_bump: daca dv-ul masurat e
## zero dar impulsurile curg, inseamna ca move_and_slide le anuleaza (masina e
## intrepatrunsa), nu ca modelul de imbranceala tace.
func _on_bump_impulse(car: Car, _other: Car, delta_v: float) -> void:
	if car == _bump_attacker:
		_bump_impulses_att += 1
		_bump_impulse_peak_att = maxf(_bump_impulse_peak_att, delta_v)
	else:
		_bump_impulses_vic += 1
		_bump_impulse_peak_vic = maxf(_bump_impulse_peak_vic, delta_v)


func _tick_bump() -> void:
	if _bump_attacker == null:
		return
	_bump_frames += 1
	if _bump_frames > 3: # dupa ce au coborat pe sol
		_bump_peak = maxf(_bump_peak, _bump_victim.horizontal_speed())
		_bump_attacker_loss = maxf(_bump_attacker_loss,
			BUMP_ENTRY_SPEED - _bump_attacker.horizontal_speed())
		# Podeaua de viteza abia DUPA ce izbitura a avut loc — inainte de
		# contact atacatorul merge cu viteza de intrare si cifra n-ar spune nimic.
		if _bump_impulses_att + _bump_impulses_vic > 0:
			_bump_attacker_floor = minf(_bump_attacker_floor,
				_bump_attacker.horizontal_speed())
	if _bump_frames < 90:
		return
	var c := _bump_cases[_bump_case]
	var att := c.attacker as CarData
	var vic := c.victim as CarData
	var kind := String(c.kind)
	# Distanta dintre centre la final vs. suma semi-gabaritelor pe directia
	# loviturii: sub 1.0 inseamna ca atacatorul a "inghitit" victima si o cara
	# in el, nu a imbrancit-o.
	var touching := (att.body_length + vic.body_length) * 0.5 \
		if kind != "lateral" else (att.body_length + vic.body_width) * 0.5
	var apart := _bump_attacker.global_position - _bump_victim.global_position
	apart.y = 0.0
	var pushed := _bump_victim.global_position
	pushed.y = 0.0
	_bump_rows.append({
		"attacker": att.display_name, "victim": vic.display_name,
		"kind": kind,
		"ratio": att.mass_factor / vic.mass_factor,
		"victim_dv": _bump_peak, "attacker_loss": _bump_attacker_loss,
		"attacker_floor": _bump_attacker_floor,
		"pushed": pushed.length(), "sep": apart.length() / touching,
		"yaw_deg": absf(rad_to_deg(wrapf(
			_bump_victim.rotation.y - _bump_victim_yaw0, -PI, PI))),
		"impulses": _bump_impulses_att + _bump_impulses_vic,
		"impulse_peak": maxf(_bump_impulse_peak_att, _bump_impulse_peak_vic),
	})
	_next_bump_case()


func _report_bump() -> void:
	print("\n=== IMBRANCELI (atac la %.0f m/s in masina oprita) ===" % [
		BUMP_ENTRY_SPEED])
	print("frana atac = varful de viteza pierduta; v_min atac = podeaua de dupa")
	print("contact (aproape de zero inseamna \"zid\", nu transfer de impuls)")
	print("%-12s %-12s %-7s %8s %11s %11s %10s %8s %7s %6s %8s %6s" % [
		"atacator", "victima", "tip", "m_a/m_v", "dv victima", "frana atac",
		"v_min atac", "impinsa", "separ", "rotita", "impuls", "dv_max"])
	for row in _bump_rows:
		print("%-12s %-12s %-7s %8.2f %10.1f %10.1f %10.1f %8.1f %7.2f %5.0f° %6d %8.1f" % [
			row.attacker, row.victim, row.kind, row.ratio,
			row.victim_dv, row.attacker_loss, row.attacker_floor,
			row.pushed, row.sep, row.yaw_deg,
			row.impulses, row.impulse_peak])
	_finish()
