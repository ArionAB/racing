class_name Race
extends Node3D
## Orchestreaza o cursa: mediu, pista (aleasa din GameState), masini
## (jucatorul cu masina din garaj + lineup AI stabil), countdown cu rocket
## start, progres/pozitii, rezultate si avansarea campionatului.

const CAR_SCENE: PackedScene = preload("res://scenes/cars/Car.tscn")
## Pilotii sunt stabili intre curse (punctele de campionat raman pe slot).
const PILOTS: Array[String] = ["Tu", "Robo", "Vex", "Luna", "Kai", "Nyx"]
## Lineup-ul AI: masina (index in GameState.CAR_DATA) + culoarea per slot.
##
## Garajul are 4 masini non-player, iar adversarii sunt 5: ultimul repeta un
## model. E o repetare ACCEPTATA, nu o scapare — se rezolva cand apar modele
## noi, adaugand un index aici. Culoarea ramane insa unica per slot, ca cele
## doua autobuze sa nu fie confundabile pe pista si pe minimap.
const AI_CARS: Array[int] = [3, 1, 4, 2, 3] # Autobuz, Politia, Pompieri, Taxi, Autobuz
const AI_COLORS: Array[Color] = [
	Color(0.3, 0.8, 0.4), Color(0.8, 0.4, 0.9), Color(0.55, 0.75, 0.95),
	Color(0.95, 0.8, 0.25), Color(0.9, 0.35, 0.3)]

## LOADING e la coada, nu in fata: valorile vechi raman aceleasi numere.
enum State { COUNTDOWN, RUNNING, FINISHED, LOADING }

var state: State = State.COUNTDOWN
var track: Track
var player: Car
var cars: Array[Car] = []
## Tuk-tuk-urile (Jodhpur, Track17, brief §3): corpuri `Car` reale, cu
## `TrafficController`, dar EXCLUSE din clasament/tururi/`race_finished`/HUD —
## vezi `_spawn_traffic`. Gol pe orice pista cu `Track.traffic_count == 0`
## (implicit), deci comportamentul ramane neschimbat peste tot in afara de
## Jodhpur.
var traffic: Array[Car] = []
## Lista pe care o vede FIECARE `AIController` prin `configure(..., cars)` —
## deci citita de `_avoid_line` (campul `traffic` de acolo, nume din pacate
## identic cu `Race.traffic`, dar alt obiect). Contine masinile de cursa SI
## tuk-tuk-urile, in ACEEASI referinta partajata (tiparul vechi: fiecare pilot
## primeste aceeasi lista si o vede crescand pe masura ce se adauga restul
## masinilor) — separata de `Race.cars` (doar cursa: pozitii/tururi/HUD) si de
## `Race.traffic` (doar tuk-tuk-uri: exclus din cursa), ca niciuna din cele
## doua liste "oficiale" sa nu se amestece cu cealalta.
var _ai_visible: Array[Car] = []
var camera: ChaseCamera
var hud: RaceHUD
## „Parbrizul ud" (Fiordland, brief pasul 4): picaturi pe ecran cand jucatorul
## e in perdeaua Stirling sau in ploaie. Null pe piste fara niciun
## `WaterfallHazard`/`RainCycle` — vezi `_setup_windshield_wipers`.
var wipers: WindshieldWipers

var _progress: Array[Dictionary] = []
var _countdown_left: float = 3.6
var _last_beep: int = -1
var _skid_parent: Node3D
var _drift_hold: Dictionary = {}
var _lap_start_ms: int = -1
var _best_lap_ms: int = -1
var _final_order: Array = [] # sloturi in ordinea sosirii
var _champion_shown: bool = false
## Cat sta fiecare masina impotmolita in afara soselei (secunde).
var _stalled: Dictionary = {}
## Runda 3 (Fiordland): cat sta o masina SCUTITA de plasa de siguranta fiindca
## e intr-o coada legitima la semafor (vezi `_queue_exempt`). Separat de
## `_stalled`, care tot creste in fundal cat scutirea e activa — daca
## scutirea expira (QUEUE_EXEMPT_MAX_S) inainte ca masina sa mai progreseze,
## plasa de siguranta trebuie sa apuce imediat, nu sa mai astepte alte 5s.
var _queue_exempt_time: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	# Din joc (meniu, restart, campionat) cursa se incarca in spatele ecranului
	# de incarcare. Sondele si F6 din editor instantiaza Race direct si raman
	# pe drumul sincron de mai jos: citesc `player`/`track` imediat dupa
	# add_child, deci au nevoie ca _ready sa fi terminat tot.
	if GameState.take_loading_screen():
		_load_behind_screen()
		return
	# Mediul (cer, soare, teren) e construit de pista — fiecare are tema ei.
	var track_scene := load(
		GameState.TRACK_SCENES[GameState.selected_track]) as PackedScene
	_mount_track(track_scene.instantiate() as Track)
	_setup_race()


## Cursa pornita din joc: ecranul apare intai, scena pistei se citeste pe alt
## fir, apoi pista se construieste (sincron, cu bara mutata intre faze) si
## abia la urma pornesc numaratoarea si fizica de cursa. Vezi LoadingScreen.
func _load_behind_screen() -> void:
	state = State.LOADING
	var screen := LoadingScreen.new()
	screen.track_index = GameState.selected_track
	add_child(screen)
	var scene := await screen.load_scene(
		GameState.TRACK_SCENES[GameState.selected_track])
	var t := scene.instantiate() as Track if scene != null else null
	if t == null:
		push_error("Race: pista %s nu s-a putut incarca"
			% GameState.TRACK_SCENES[GameState.selected_track])
		GameState.go_to_menu()
		return
	screen.watch_build(t)
	_mount_track(t)
	_setup_race()
	screen.end_phase(&"masini")
	# Numaratoarea porneste cand ecranul incepe sa se ridice, nu inainte:
	# cadrele de incalzire nu au voie sa manance din READY?/3/2/1.
	await screen.finish()
	state = State.COUNTDOWN


## Pista intra in scena: `Track._ready` o construieste intreaga, sincron.
func _mount_track(t: Track) -> void:
	track = t
	# `--traffic=N` (ProbeRace, brief §4(c)): suprascrie ÎNAINTE de
	# `_spawn_traffic()`. Vezi GameState.traffic_override.
	if GameState.traffic_override >= 0:
		track.traffic_count = GameState.traffic_override
	add_child(track)


## Tot ce sta pe pista: masini, camera, HUD, legaturile de feedback.
func _setup_race() -> void:
	_skid_parent = Node3D.new()
	_skid_parent.name = "SkidMarks"
	add_child(_skid_parent)
	_spawn_cars()
	_spawn_traffic()
	camera = ChaseCamera.new()
	add_child(camera)
	camera.target = player
	_fit_camera_to_player()
	camera.snap_behind()
	# Reglajul de camera din volan: doar in build de debug. E unealta de
	# dezvoltare, iar pe telefon nu exista tastatura pe care sa-l tii apasat.
	if OS.is_debug_build():
		var tuner := CameraTuner.new()
		tuner.camera = camera
		add_child(tuner)
	hud = RaceHUD.new()
	add_child(hud)
	hud.restart_requested.connect(GameState.start_race)
	hud.respawn_requested.connect(_on_respawn_requested)
	hud.menu_requested.connect(GameState.go_to_menu)
	hud.results_primary.connect(_on_results_primary)
	hud.setup_minimap(track, cars)
	hud.show_countdown("READY?")
	_setup_windshield_wipers()
	player.wall_hit.connect(func(_c: Car, impact: float) -> void:
		camera.add_trauma(clampf(impact / 45.0, 0.15, 0.5)))
	player.landed.connect(func(_c: Car, fall: float) -> void:
		camera.add_trauma(clampf(fall / 30.0, 0.1, 0.35)))
	player.boost_started.connect(func(_c: Car) -> void:
		camera.add_trauma(0.18))
	# Valul care spala digul: izbitura de apa se vede, nu doar se aude.
	#
	# Plafonul e 0.85, cel mai mare din lista, si nu e o scapare: shake-ul e
	# `trauma^2`, deci pana pe la 0.4 practic nu se vede nimic — prima versiune
	# limita aici la 0.4 si raportul din joc a fost „ecranul nu se zguduie", desi
	# semnalul se emitea. Un val care te acopera cu totul are voie sa loveasca mai
	# tare decat o aripa frecata de perete (0.5).
	player.splashed.connect(func(_c: Car, strength: float) -> void:
		camera.add_trauma(clampf(strength, 0.05, 0.85)))
	# Rafala de abur: DOAR ecranul se albeste. Fara shake si fara sunet de
	# impact, fiindca nu te-a lovit nimic — fumarola e hazard-teatru, iar un
	# zgomot de izbitura ar promite o pedeapsa care nu vine (vezi
	# FumaroleHazard).
	player.blinded.connect(func(_c: Car, seconds: float) -> void:
		hud.blind_flash(seconds))
	# Imbranceala se SIMTE proportional cu cat ai incasat: un autobuz care te ia
	# din spate zguduie ecranul, o atingere lateral aproape deloc.
	player.bumped.connect(func(_c: Car, _other: Car, delta_v: float) -> void:
		camera.add_trauma(clampf(delta_v / 40.0, 0.05, 0.35)))
	# Repunerea teleporteaza masina: camera trebuie sa sara cu ea, altfel
	# urmareste cateva cadre un punct de la 100m.
	player.respawned.connect(func(_c: Car) -> void:
		camera.snap_behind()
		camera.add_trauma(0.22)
		hud.flash_message("RATAT — repus pe pista"))
	# Soferul aruncat din masina (buggy, prototip): camera ramane pe loc si
	# urmareste figurina cat tine aruncarea; repunerea de dupa trage camera
	# inapoi prin `respawned` (snap_behind sterge focalizarea).
	player.ejected.connect(func(c: Car, ragdoll: Node3D) -> void:
		var rag := ragdoll as ToyRagdoll
		camera.focus_on(rag.focus_node() if rag != null else ragdoll,
			c.eject_hold + 0.6)
		camera.add_trauma(0.45)
		hud.flash_message("EJECTAT!"))
	# Strivit / ars: shake proportional cu severitatea. Semnalul exista de la
	# bolovani (#242), dar nu fusese legat la camera; lava il refoloseste.
	player.crushed.connect(func(_c: Car, severity: float) -> void:
		camera.add_trauma(clampf(0.25 + severity * 0.35, 0.25, 0.6)))
	# Directia inversata (bolovanul de pe buza, Track19): flash-ul tine cam cat
	# inversarea (1.2 s + 0.5 s fade vs 1.75 s), deci jucatorul stie DE CE vireaza
	# invers. Pe masina apare si "<=>" (vezi Car._update_invert_marker).
	player.steer_inverted.connect(func(_s: float) -> void:
		hud.flash_message("DIRECTIE INVERSATA  <=>"))
	# Aprins de o coloana de foc: mesajul spune de ce vezi prost, ca sa nu se
	# citeasca drept bug grafic. Shake-ul il da deja `crushed`, emis din
	# `Car.ignite` — nu-l dublam aici.
	player.ignited.connect(func(_c: Car, _s: float) -> void:
		hud.flash_message("IN FLACARI!"))
	# Eruptia (Stromboli): bubuitul e al lumii (il reda EruptionCycle), dar
	# tremurul de ecran e feedback de jucator, deci se leaga aici — pentru
	# TOATE ciclurile de pe pista, oriunde ai fi (telegraph-ul din brief).
	for child in track.get_children():
		if child is EruptionCycle:
			(child as EruptionCycle).erupted.connect(func(_i: int) -> void:
				camera.add_trauma(0.5))

func _spawn_cars() -> void:
	var count := GameState.ai_count + 1
	var spawns := track.spawn_transforms(count)
	for i in count:
		var car := CAR_SCENE.instantiate() as Car
		car.track = track
		add_child(car)
		car.global_transform = spawns[i]
		car.route = 0
		car.road_index = track.closest_index_global(car.global_position)
		car.last_safe_index = car.road_index
		car.last_safe_route = 0
		car.skid_parent = _skid_parent
		car.pilot_name = PILOTS[i % PILOTS.size()]
		if i == 0:
			player = car
			car.is_player = true
			car.apply_data(GameState.CAR_DATA[GameState.selected_car] as CarData)
			car.set_controller(PlayerController.new())
		else:
			var data_idx: int = AI_CARS[(i - 1) % AI_CARS.size()]
			car.apply_data(GameState.CAR_DATA[data_idx] as CarData,
				AI_COLORS[(i - 1) % AI_COLORS.size()])
			var ai := AIController.new()
			car.set_controller(ai)
			# `_ai_visible` e aceeasi lista in care se adauga toate masinile (si,
			# mai jos, tuk-tuk-urile) — fiecare pilot o vede crescand.
			ai.configure(track, _rng, _ai_visible)
			car.speed_scale = _rng.randf_range(0.88, 0.97)
		# Inghetata pana la GO: pe grila nu se aluneca la vale. Vezi nota din
		# Car._physics_process — blocarea comenzilor singura nu ajunge.
		car.on_start_grid = true
		cars.append(car)
		_ai_visible.append(car)
		var frac := track.frac_at(car.road_index, car.route)
		_progress.append({
			"frac": frac,
			"total": frac - 1.0 if frac > 0.5 else frac,
			"laps": 0,
		})

## Tuk-tuk-urile (Jodhpur, brief §3): `Track.traffic_count` corpuri `Car`
## reale, cu `TrafficController`, distribuite UNIFORM pe bucla principala
## (ruta 0 — brief: "circula pe tot circuitul, fara ulicioara"), pe banda
## stanga. No-op pe orice pista cu `traffic_count == 0` (implicit) — deci
## Track01/08/09/.../16 raman neschimbate.
##
## EXCLUSE din `cars`/`_progress`/clasament/HUD/`race_finished`: intra doar in
## `traffic` (proprie) si in `_ai_visible` (vazuta de AIController._avoid_line
## prin campul `traffic` de-acolo — nume identic, alt obiect, vezi comentariul
## de la declaratia `_ai_visible`).
func _spawn_traffic() -> void:
	var count := track.traffic_count
	if count <= 0:
		return
	var route := track.route_at(0)
	if route == null or route.count() == 0:
		return
	var n := route.count()
	for i in count:
		var idx := int(float(i) / float(count) * float(n)) % n
		var pos := route.baked[route.wrap_index(idx)] \
			+ route.side_at(idx) * TrafficController.LANE_OFFSET_M \
			+ Vector3.UP * 0.5
		var dir := (route.baked[route.wrap_index(idx + 1)]
			- route.baked[route.wrap_index(idx)])
		dir.y = 0.0
		if dir.length_squared() < 0.001:
			dir = Vector3.FORWARD
		dir = dir.normalized()
		var car := CAR_SCENE.instantiate() as Car
		car.track = track
		add_child(car)
		car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos)
		car.route = 0
		car.road_index = idx
		car.last_safe_index = idx
		car.last_safe_route = 0
		car.skid_parent = _skid_parent
		car.pilot_name = "Tuk-tuk %d" % (i + 1)
		car.apply_data(GameState.CAR_DATA_TUKTUK)
		var traf := TrafficController.new()
		car.set_controller(traf)
		traf.configure(track, _ai_visible)
		car.on_start_grid = false # circula din primul cadru, nu asteapta grila
		car.race_active = true
		car.linear_velocity = dir * TrafficController.CRUISE_SPEED
		traffic.append(car)
		_ai_visible.append(car)

func _physics_process(delta: float) -> void:
	# In timpul incarcarii nu exista inca masini, HUD sau camera.
	if state == State.LOADING:
		return
	if state == State.COUNTDOWN:
		_tick_countdown(delta)
	else:
		_tick_race(delta)
	_update_hud()

# -------------------------------------------------------------- countdown

func _tick_countdown(delta: float) -> void:
	_countdown_left -= delta
	# Rocket start: masuram cat tine fiecare "creier" TURBO apasat.
	for car in cars:
		if car.controller != null and car.controller.is_turbo_pressed():
			_drift_hold[car] = float(_drift_hold.get(car, 0.0)) + delta
		else:
			_drift_hold[car] = 0.0
	if _countdown_left > 3.0:
		return
	if _countdown_left > 0.0:
		var number := ceili(_countdown_left)
		hud.show_countdown(str(number))
		if number != _last_beep:
			_last_beep = number
			AudioManager.play_sfx(&"count_beep")
		return
	_go()

func _go() -> void:
	state = State.RUNNING
	hud.show_countdown("GO!")
	AudioManager.play_sfx(&"go_beep")
	get_tree().create_timer(0.7, false).timeout.connect(
		func() -> void: hud.show_countdown(""))
	_lap_start_ms = Time.get_ticks_msec()
	for car in cars:
		car.race_active = true
		car.on_start_grid = false # se dezgheata fizica; de aici incolo e cursa
		var hold := float(_drift_hold.get(car, 0.0))
		if car == player:
			if hold > 0.05 and hold <= 1.05:
				car.force_boost(1.2)
				hud.flash_message("ROCKET START!")
			elif hold > 1.05:
				hud.flash_message("Prea devreme...")
		elif _rng.randf() < 0.45:
			car.force_boost(0.8)

# ------------------------------------------------------------------ cursa

func _tick_race(delta: float) -> void:
	for i in cars.size():
		var car := cars[i]
		_watch_recovery(car, delta)
		var st := _progress[i]
		var frac := track.frac_at(car.road_index, car.route)
		var d := frac - float(st.frac)
		if d < -0.5:
			d += 1.0
		elif d > 0.5:
			d -= 1.0
		st.frac = frac
		if not car.finished:
			st.total = float(st.total) + d
		var laps := int(floor(float(st.total)))
		if laps > int(st.laps):
			st.laps = laps
			if car == player:
				_on_player_lap(laps)
			if laps >= GameState.total_laps and not car.finished:
				car.finished = true
	_update_positions()

## Progresul jucatorului ca fractie din cursa intreaga (0 pe grila/countdown,
## 1 la ultima trecere) — sursa lui `DuskCycle.dusk` (Jodhpur, brief §3
## „Ceasul de lumina”: iluminarea trebuie sa fie identica pentru acelasi PUNCT
## din cursa, nu din timp, altfel recordurile de time trial nu se compara cu
## cursa normala). `_progress[0]` e jucatorul (vezi `_setup`: `i == 0` seteaza
## `is_player`), iar `.total` e acelasi camp continuu (tururi + fractie
## curenta) folosit pentru clasament in `_tick_race`/`_update_positions`, deci
## nu exista o a doua sursa de adevar pentru "cat de departe a ajuns".
func player_progress_fraction() -> float:
	if _progress.is_empty() or GameState.total_laps <= 0:
		return 0.0
	return clampf(float(_progress[0].total) / float(GameState.total_laps), 0.0, 1.0)

## Plasa de siguranta a cursei: nimeni nu ramane blocat. Zonele de fly-off au
## RespawnZone-ul lor, dar mai exista doua feluri de a te pierde — sa cazi din
## lume si sa te impotmolesti in nisip fara sa mai poti iesi. Amandoua se
## termina cu repunerea pe ultimul checkpoint valid.
func _watch_recovery(car: Car, delta: float) -> void:
	if car.finished:
		return
	# Prag RELATIV la sosea, nu absolut. De cand terenul urmareste drumul, cota
	# zero nu mai inseamna nimic: fundul unei rape sapate pe o portiune joasa e
	# la -14, deci un prag fix de -12 ar repune masina inainte sa atinga fundul,
	# iar pe creasta (drum la 19 m) n-ar prinde niciodata o cadere reala.
	if car.global_position.y \
			< track.point_at(car.road_index, car.route).y - 25.0:
		if OS.get_environment("AI_UNSTICK_TRACE") == "1":
			print("[race-respawn] %s cauza=cadere frac=%.3f pos=(%.0f,%.0f,%.0f)" % [
				car.pilot_name, track.frac_at(car.road_index, car.route),
				car.global_position.x, car.global_position.y, car.global_position.z])
		car.respawn()
		return
	var off_road := not track.is_on_road(car.road_index, car.global_position,
		car.route)
	if off_road and car.horizontal_speed() < 2.5:
		# Runda 3, punctul 2: gasit prin diagnostic (AI_UNSTICK_TRACE=1) ca
		# fiind chiar plasa asta, nu paznicul de progres al AI-ului
		# (AIController._begin_unstick) si nici o RespawnZone — mecanismul de
		# aici e "off-road si sub 2.5 m/s peste 5s", fara nicio notiune de
		# semafor sau coada. O masina impinsa in afara soselei de presiunea
		# cozii de la semafor (lat mare, masurat in runda 2: pana la 15.3m)
		# cade exact aici.
		#
		# SCUTIRE DE COADA: daca masina are in fata, la sub QUEUE_EXEMPT_REACH_M,
		# o alta masina care e ea insasi scutita de plasa (semafor rosu SAU sub
		# 2 m/s, in aceeasi zona) — adica o coada legitima, nu un blocaj real —
		# ceasul de stall nu avanseaza, DAR un ceas SEPARAT (`_queue_exempt_time`)
		# tine minte cat a durat scutirea, plafonat la QUEUE_EXEMPT_MAX_S: o
		# coada care nu se mai misca deloc timp de 25s tot merita o repunere,
		# altfel scutirea ar ascunde un blocaj real (exact riscul numit in
		# cerinta rundei 3).
		var dbg := OS.get_environment("AI_UNSTICK_TRACE") == "1"
		var exempt := _queue_exempt(car)
		if exempt:
			var qt: float = float(_queue_exempt_time.get(car, 0.0)) + delta
			_queue_exempt_time[car] = qt
			if qt <= QUEUE_EXEMPT_MAX_S:
				_stalled[car] = 0.0
				return
			# Plafonul a expirat: scutirea nu se mai aplica, plasa normala preia.
			if dbg:
				print("[queue-ceiling] %s a expirat scutirea dupa %.1fs" % [
					car.pilot_name, qt])
		else:
			_queue_exempt_time[car] = 0.0
		_stalled[car] = float(_stalled.get(car, 0.0)) + delta
		if float(_stalled[car]) > 5.0:
			_stalled[car] = 0.0
			if dbg:
				print("[race-respawn] %s cauza=stall_offroad frac=%.3f pos=(%.0f,%.0f,%.0f)"
					% [car.pilot_name, track.frac_at(car.road_index, car.route),
						car.global_position.x, car.global_position.y, car.global_position.z])
			car.respawn()
	else:
		_stalled[car] = 0.0
		_queue_exempt_time[car] = 0.0

## Cat de departe INAINTE (m, de-a lungul drumului) se cauta o alta masina
## care sa justifice o coada legitima. Coordonatorul a cerut 8m (distanta
## tipica dintre doua masini oprite in linie la semafor); masurat cu
## PROBE_RACE_TRACE_WINDOW=125,138 pe seed 3, un pilc de masini impinse in
## afara soselei de presiunea cozii (nu o linie curata) sta la ~13m intre ele
## (car0 la (-136,-500), car6 la (-141,-488), amandoua sub 1 m/s) — 8m nu
## prindea acest caz, desi e exact "coada legitima" pe care scutirea trebuie
## s-o acopere. Marit la 15m; QUEUE_EXEMPT_MAX_S (plafonul de 25s) ramane
## paza impotriva mascarii unui blocaj real, indiferent de raza.
const QUEUE_EXEMPT_REACH_M: float = 15.0
## Sub ce viteza (m/s) o masina din fata conteaza drept "oprita in coada"
## chiar daca nu e ea insasi semnalata ca asteptand la semafor.
const QUEUE_EXEMPT_SPEED: float = 2.0
## Plafon de timp (s) pentru scutirea de coada: o coada care nu se misca deloc
## atat de mult merita totusi o repunere, ca sa nu se ascunda un blocaj real
## sub eticheta "astepti in coada".
const QUEUE_EXEMPT_MAX_S: float = 25.0

## Adevarat daca `car` are in fata, la sub `QUEUE_EXEMPT_REACH_M`, o alta
## masina care e ea insasi scutita de plasa de siguranta — semnalata ca
## asteptand la un semafor rosu (`AIController._signal_block_m`) SAU sub
## `QUEUE_EXEMPT_SPEED`. Asta e diferenta dintre „coada legitima la semafor"
## (toata lumea in spatele primei masini merita scutire) si „blocaj real"
## (nimeni din fata nu asteapta nimic, doar s-au impotmolit).
func _queue_exempt(car: Car) -> bool:
	var r := track.route_at(car.route)
	if r == null:
		return false
	var n := r.count()
	var best_d := INF
	var ahead: Car = null
	for other in cars:
		if other == car or not is_instance_valid(other) or other.route != car.route:
			continue
		var d := other.road_index - car.road_index
		if r.closed:
			if d > n / 2:
				d -= n
			elif d < -n / 2:
				d += n
		var ahead_m := float(d) * track.curve.bake_interval
		if ahead_m <= 0.0 or ahead_m > QUEUE_EXEMPT_REACH_M:
			continue
		if ahead_m < best_d:
			best_d = ahead_m
			ahead = other
	if ahead == null:
		return false
	var ahead_ai := ahead.controller as AIController
	var ahead_signal_wait := ahead_ai != null \
		and ahead_ai._signal_block_m < AIController.SIGNAL_BRAKE_M
	return ahead_signal_wait or ahead.horizontal_speed() < QUEUE_EXEMPT_SPEED

func _on_player_lap(laps: int) -> void:
	# Lava creste odata cu tururile. E o proprietate a LUMII, nu a cursei
	# tale: ce vede jucatorul pe canal trebuie sa fie acelasi lucru pe care
	# il vede si AI-ul cand isi alege ruta.
	for child in track.get_children():
		if child is LavaFlowHazard:
			(child as LavaFlowHazard).on_lap_completed()
	var now := Time.get_ticks_msec()
	if _lap_start_ms >= 0:
		var lap_ms := now - _lap_start_ms
		if _best_lap_ms < 0 or lap_ms < _best_lap_ms:
			_best_lap_ms = lap_ms
		if GameState.try_record(GameState.selected_track, lap_ms):
			hud.flash_message("RECORD NOU! " + _fmt_ms(lap_ms))
			AudioManager.play_sfx(&"drift_level", 1.5)
	_lap_start_ms = now
	if laps >= GameState.total_laps and state != State.FINISHED:
		_finish_race()

func _finish_race() -> void:
	state = State.FINISHED
	_update_positions()
	# Ordinea finala = pozitiile din clipa sosirii jucatorului (AI-ul din
	# spate isi pastreaza locul relativ; cursa e a jucatorului).
	var order := range(cars.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return cars[a].race_position < cars[b].race_position)
	_final_order = order
	if GameState.champ_active:
		GameState.record_results(_final_order)
	hud.flash_message("FINISH — locul %d!" % player.race_position)
	get_tree().create_timer(1.5, false).timeout.connect(_show_results)

func _show_results() -> void:
	var rows: Array[Dictionary] = []
	for rank in _final_order.size():
		var slot: int = _final_order[rank]
		var car := cars[slot]
		var right := ""
		if GameState.champ_active:
			# Sub baremul de puncte nu se mai da nimic — vezi record_results.
			var gained: int = GameState.CHAMP_POINTS[rank] \
				if rank < GameState.CHAMP_POINTS.size() else 0
			right = "+%d p  (total %d)" % [gained, GameState.champ_points[slot]]
		rows.append({
			"name": "%d. %s (%s)" % [rank + 1, car.pilot_name, car.car_name],
			"color": car.body_color,
			"right": right,
			"is_player": car.is_player,
		})
	var title := "REZULTATE — " + track.track_name
	var primary := "RESTART"
	if GameState.champ_active:
		title = "CURSA %d/%d — %s" % [GameState.champ_round + 1,
			GameState.CHAMP_ROUNDS, track.track_name]
		primary = "CLASAMENT FINAL" if GameState.champ_is_last_round() \
			else "URMATOAREA CURSA"
	hud.show_results(title, rows, primary)

func _on_results_primary() -> void:
	if not GameState.champ_active:
		GameState.start_race()
		return
	if _champion_shown:
		GameState.start_championship()
		return
	if GameState.champ_is_last_round():
		_show_champion()
	else:
		GameState.champ_next_race()

## Clasamentul final al campionatului, sortat dupa puncte.
func _show_champion() -> void:
	_champion_shown = true
	var slots := range(cars.size())
	slots.sort_custom(func(a: int, b: int) -> bool:
		return GameState.champ_points[a] > GameState.champ_points[b])
	var rows: Array[Dictionary] = []
	for rank in slots.size():
		var slot: int = slots[rank]
		var car := cars[slot]
		rows.append({
			"name": "%d. %s (%s)" % [rank + 1, car.pilot_name, car.car_name],
			"color": car.body_color,
			"right": "%d puncte" % GameState.champ_points[slot],
			"is_player": car.is_player,
		})
	var champion := cars[slots[0]]
	var title := "CAMPION: %s!" % champion.pilot_name
	AudioManager.play_sfx(&"go_beep", 1.3)
	hud.show_results(title, rows, "CAMPIONAT NOU")

# -------------------------------------------------------------------- HUD

func _update_positions() -> void:
	var order := range(cars.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return float(_progress[a].total) > float(_progress[b].total))
	for rank in cars.size():
		cars[order[rank]].race_position = rank + 1

func _unhandled_key_input(event: InputEvent) -> void:
	if state == State.LOADING:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Actiunea "reset" (tasta R) exista in project.godot de la inceput dar nu era
	# citita de nicaieri — cod mort. Legata prin ACTIUNE, nu prin KEY_R, ca sa
	# ramana remapabila din setari.
	if key.is_action_pressed("reset"):
		_on_respawn_requested()
		get_viewport().set_input_as_handled()
		return
	match key.physical_keycode:
		KEY_1: _swap_player_car(0)
		KEY_2: _swap_player_car(1)
		KEY_3: _swap_player_car(2)
		KEY_4: _swap_player_car(3)
		KEY_5: _swap_player_car(4)
		KEY_6: _swap_player_car(5)

func _swap_player_car(index: int) -> void:
	player.apply_data(GameState.CAR_DATA[index] as CarData)
	_fit_camera_to_player()

## Camera se retrage proportional cu lungimea vehiculului (autobuzul ar
## umple ecranul la distanta potrivita pentru muscle car).
##
## Formula traieste in ChaseCamera, nu aici. Cat timp existau doua seturi de
## literale, editarea constantelor din chase_camera.gd nu schimba nimic in joc:
## valorile de acolo erau suprascrise la runtime chiar de functia asta.
## Repunere ceruta de jucator, din buton sau de la tasta R.
##
## Tot ce urmeaza dupa e deja legat: `respawned` trage camera in spate, adauga
## trauma si scrie mesajul pe ecran.
func _on_respawn_requested() -> void:
	if state != State.RUNNING or player.finished:
		return
	player.respawn()


func _fit_camera_to_player() -> void:
	if player.data != null:
		camera.apply_settings_for(player.data.body_length)


## Instantiaza „parbrizul ud" (brief pasul 4) si il leaga la starea reala a
## pistei, prin doua Callable-uri mici — nu prin referinte directe: pe o
## pista FARA niciun `WaterfallHazard`/`RainCycle` (toate, in afara de
## Fiordland), cele doua cautari nu gasesc nimic si funcțiile intorc
## constant `false`/`0.0` — overlay-ul ramane instantiat dar nu are niciodata
## motiv sa arate o picatura, exact contractul "0 noduri vizibile" de pe
## uscat.
##
## Cascada reala (nu o "cascada de ploaie" decorativa) se distinge prin
## `force_accel > 0.0` — cele 5 `RainFall*` de pe Fiordland au `force_accel =
## 0` (teatru, brief §3), deci ele NU trebuie sa declanseze rafala de 20-30.
##
## `in_curtain_fn` cauta la FIECARE apel, nu cacheaza o singura perdea la
## `_ready`: pe Fiordland exista DOUA surse cu `force_accel > 0` (Stirling,
## static in scena) SI torentul de pe scurtatura, a carui `WaterfallHazard`
## e construit de `TorrentCycle` cu `call_deferred` (memoria „decor ready
## inaintea temei" — `TorrentCycle._ready` amana constructia, deci la
## `Race._ready()` sincron `_hazard` inca nu exista). Un cache luat aici ar
## fi prins fie null (torentul), fie doar PRIMA gasita prin ordinea din
## arbore (Stirling, inaintea `TorentChasm` in .tscn) — runda 3 cere ca
## rafala de picaturi sa porneasca si la intrarea in puls, nu doar la
## Stirling.
func _setup_windshield_wipers() -> void:
	wipers = WindshieldWipers.new()
	add_child(wipers)
	var rain: RainCycle = null
	var cycles := get_tree().get_nodes_in_group(&"rain_cycle")
	if not cycles.is_empty():
		rain = cycles[0] as RainCycle
	var in_curtain_fn := (func() -> bool:
		for node in track.find_children("*", "WaterfallHazard", true, false):
			var wf := node as WaterfallHazard
			if wf.force_accel > 0.0 and wf.cars_inside().has(player):
				return true
		return false)
	var rain_factor_fn := (func() -> float:
		return rain.rain_factor if rain != null and is_instance_valid(rain) else 0.0)
	wipers.configure(in_curtain_fn, rain_factor_fn)

func _update_hud() -> void:
	hud.set_respawn_enabled(state == State.RUNNING and player.can_respawn())
	var lap_text := "--:--.-"
	if _lap_start_ms >= 0 and state != State.COUNTDOWN:
		lap_text = _fmt_ms(Time.get_ticks_msec() - _lap_start_ms)
	var best_text := _fmt_ms(_best_lap_ms) if _best_lap_ms >= 0 else "--:--.-"
	var lap_no := clampi(int(_progress[0].laps) + 1, 1, GameState.total_laps)
	var champ_line := ""
	if GameState.champ_active:
		champ_line = "   cursa %d/%d" % [
			GameState.champ_round + 1, GameState.CHAMP_ROUNDS]
	var record_ms := GameState.best_lap(GameState.selected_track)
	var record_text := _fmt_ms(record_ms) if record_ms > 0 else "--:--.-"
	# Indiciul de camera apare doar unde exista si reglajul (build de debug),
	# altfel ar promite jucatorului o tasta care nu face nimic.
	var cam_hint := "  [F2] camera" if OS.is_debug_build() else ""
	var info := "%3.0f km/h   loc %d/%d   tur %d/%d%s\ntur:  %s\nbest: %s   rec: %s\n%s pe %s   [SPACE] turbo  [SHIFT] drift%s" % [
		player.horizontal_speed() * 3.6, player.race_position, cars.size(),
		lap_no, GameState.total_laps, champ_line, lap_text, best_text,
		record_text, player.car_name, track.track_name, cam_hint]
	hud.set_info(info)
	hud.set_turbo(player.turbo_charge, player.is_boosting)

func _fmt_ms(ms: int) -> String:
	@warning_ignore("integer_division")
	return "%d:%02d.%d" % [ms / 60000, (ms % 60000) / 1000, (ms % 1000) / 100]
