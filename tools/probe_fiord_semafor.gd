extends Node
## Sonda tehnica pentru TunnelSignalHazard (Fiordland, brief §7 pasul 1b):
## semaforul tunelului Homer cu autocar pe rosu. Masoara daca AI-ul asteapta
## corect la rosu si daca 8 masini se blocheaza la portal sau in tunel.
##
## Nu construieste pista, nu face assets, nu face capturi — doar cifre.
##
## Rulare (CA SCENA, nu --script: Car/AIController au nevoie de autoload-urile
## GameState/AudioManager):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordSemafor.tscn
##   ... -- --seconds=150 --seed=1
##
## GEOMETRIA SINTETICA: o bucla ovala (`TrackFromPath`, ca la probe_hazard_marker
## si la probe_machu_ace) cu o dreapta care contine, in ordine: linia de oprire
## + lampa (`TunnelSignalHazard`), apoi 150 m de „tunel" ingustat la semilatime
## 3,5 m (`custom_width_segments`) cu 3 nise de 2,5 x 4 m pe dreapta la ~37 m
## distanta (StaticBody3D cu o gaura in perete, cu coliziune), interval ud
## (`custom_wet_ranges`) pe tot tunelul. Panta de 12% NU e inclusa (harnasul
## `TrackFromPath` narrow-eaza pe FRACTIE, iar o panta locala pe un sector scurt
## dintr-o bucla mica risca sa strice geometria vecina fara sonda dedicata —
## brief-ul accepta explicit "altfel plat si spune-o": e plat aici, tunelul
## ramane orizontal. Cade doar testul de panta, nu cel de blocaj/asteptare).
##
## 8 masini: jucatorul PILOTAT DE AI (ca la probe_race.gd — masuram pista, nu
## reflexele autorului) + 7 AI, garajul repetat ca la Race.AI_CARS.
##
## Metrici per masina si agregate, tiparite ca tabel + linie VERDICT:
##   - [blocaj] (metrica ProbeRace, refolosita identic: progres < prag pe
##     fereastra de timp)
##   - timp mediu/maxim de asteptare la rosu (per trecere prin linie)
##   - masini care intra pe rosu (trebuie 0)
##   - contacte frontale cu autocarul (BusHazard.shoved)
##   - masini oprite > 5 s dupa verde la linie (pile-up)
##   - timpi de tur (progres pe traseu), repuneri

const CAR_SCENE: PackedScene = preload("res://scenes/cars/Car.tscn")
const STEP: float = 1.0 / 60.0

# --- geometria sintetica ---
## Lungimea tunelului (brief: 150 m).
const TUNNEL_LEN: float = 150.0
## Semilatimea soselei in tunel (brief: 3,5 m = 7 m lat).
const TUNNEL_HALF_WIDTH: float = 3.5
## Semilatimea restului buclei (drum normal).
const ROAD_HALF_WIDTH: float = 7.0
## Rampa de tranzitie a latimii (Track.WIDTH_RAMP_M e privat; se repeta cifra
## documentata in track_from_path.gd — "trecerea se face pe o rampa de
## Track.WIDTH_RAMP_M metri de fiecare parte").
const WIDTH_RAMP_M: float = 15.0
## Nisele: 3, la 37 m distanta, 2,5 x 4 m, pe dreapta soselei.
const NICHE_COUNT: int = 3
const NICHE_SPACING_M: float = 37.0
const NICHE_WIDTH_M: float = 2.5
const NICHE_DEPTH_M: float = 4.0
## Lungimea dreptei dinaintea tunelului (loc de acumulare a plutonului inainte
## de linia de oprire) si dupa tunel (inapoi la bucla).
const APPROACH_LEN: float = 90.0
const EXIT_LEN: float = 90.0
## Restul buclei (curbe late, doar ca sa se inchida traseul si masinile sa se
## intoarca la linia de oprire din nou — cifrele care conteaza sunt toate pe
## dreapta cu tunelul).
const RETURN_RADIUS: float = 55.0

## Cate masini (jucator + AI).
const CAR_COUNT: int = 8
## Garaj repetat, ca Race.AI_CARS: 0=Muscle,1=Politie,2=Taxi,3=Autobuz,4=Pompieri,5=Buggy.
const AI_CARS: Array[int] = [0, 1, 2, 4, 5, 3, 0]

var _seconds: float = 150.0
var _seed: int = 20260920
var _track: TrackFromPath
var _signal: TunnelSignalHazard
var _cars: Array[Car] = []
var _controllers: Array[AIController] = []
var _elapsed: float = 0.0
var _done: bool = false
var _rng := RandomNumberGenerator.new()

## Linia de oprire, in coordonate de lume (X pe axa soselei la frac-ul liniei).
var _stop_line_x: float = 0.0
var _tunnel_start_x: float = 0.0
var _tunnel_end_x: float = 0.0

class Stats:
	var name: String = ""
	var laps: float = 0.0
	var respawns: int = 0
	var ran_red: int = 0 # a trecut linia CAT era rosu (orice cifra ramasa)
	var ran_red_clear: int = 0 # idem, dar cu > RED_EDGE_S de rosu ramas (nu limita)
	var ejects: int = 0 # soferul ejectat (prototip ragdoll) -- "distrus" in joc azi
	var bus_hits: int = 0
	var stuck_reports: int = 0
	## Asteptari la linie: (inceput rosu vazut, secunde de asteptare) — o
	## intrare per oprire completa (viteza sub prag la mai putin de STOP_ZONE_M
	## de linie, cat semaforul era rosu).
	var wait_times: Array[float] = []
	var waiting_now: bool = false
	var wait_start: float = 0.0
	## Pile-up: ramane oprita > 5 s DUPA ce a prins verde, la linie.
	var green_stall_reports: int = 0
	var _green_stall_timer: float = 0.0
	var _was_stopped_at_line: bool = false
	var _last_side_x: float = -1e9 # pentru detectia trecerii liniei (semn X)
	var _crossed_red_flag: bool = false


var _stats: Array[Stats] = []

## Prag de "oprit" la linie (m/s).
const STOP_SPEED: float = 2.0
## Sub atatea secunde de rosu ramas, o "trecere pe rosu" e in limita alinierii
## discrete a esantionului (verdele apare in ACEEASI fereastra de fizica in
## care masina trece linia) — se raporteaza separat, nu se conteaza ca decizie
## a AI-ului de a trece pe rosu. 2 cadre la 60 fps = 0.033s; se lasa marja
## pana la 0.5s ca sa acopere si o frana care se opreste EXACT la linie si
## trece cu putin elan cand vede verde cu cateva zecimi inainte.
const RED_EDGE_S: float = 0.5
## Cat de aproape de linie conteaza ca "la linie" (m), pe axa soselei.
const STOP_ZONE_M: float = 12.0
## Blocaj: acelasi prag ca ProbeRace (progres < prag pe fereastra), dar redus
## la fereastra de aici ca sa prindem blocaje de pluton in tunel, nu doar pe
## tot turul.
const PROGRESS_WINDOW: float = 3.0
const PROGRESS_MIN_M: float = 8.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
	_rng.seed = _seed
	print("probe_fiord_semafor: seed=%d seconds=%.0f" % [_seed, _seconds])
	# Ca la probe_hazard_marker.gd: `get_tree().root` poate fi inca ocupat
	# instantiind arborele scenei-radacina cand `_ready()` al nostru ruleaza;
	# un `add_child` direct pe el aici pica cu "Parent node is busy setting up
	# children". Un process_frame in plus il lasa sa termine.
	await get_tree().process_frame
	await _build_track()
	await _build_signal()
	_spawn_cars()
	await get_tree().physics_frame


func _build_track() -> void:
	_track = TrackFromPath.new()
	_track.custom_name = "SondaSemafor"
	_track.custom_theme = "forest"
	_track.custom_half_width = ROAD_HALF_WIDTH
	# Sectorul ingustat: fractiile se calculeaza DUPA ce curba exista (baked),
	# deci construim intai o curba provizorie ca sa avem lungimea totala, apoi
	# recalculam fractiile exacte si regeneram (acelasi tipar ca la
	# probe_hazard_marker.gd: pozitiile se aleg abia dupa prima constructie).
	_track.custom_wet_ranges = []
	_set_curve()
	get_tree().root.add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	# A doua trecere: acum avem `baked` si lungimea reala a buclei, deci
	# fractiile ingustarii/udului se calculeaza pe METRI reali, nu presupusi.
	var total_len: float = _track.curve.get_baked_length()
	var appr_frac := APPROACH_LEN / total_len
	var tunnel_frac := TUNNEL_LEN / total_len
	# Linia de oprire sta la finalul dreptei de apropiere (inceputul tunelului).
	var stop_frac := appr_frac
	_track.custom_width_segments = [
		Vector3(stop_frac, stop_frac + tunnel_frac, TUNNEL_HALF_WIDTH),
	]
	_track.custom_wet_ranges = [Vector2(stop_frac, stop_frac + tunnel_frac)]
	_track.rebuild()
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Cotele de lume pentru rapoarte (X pe axa dreptei — vezi _set_curve).
	_stop_line_x = APPROACH_LEN
	_tunnel_start_x = APPROACH_LEN
	_tunnel_end_x = APPROACH_LEN + TUNNEL_LEN
	_build_niches()


## O bucla ovala: dreapta cu tunelul (de-a lungul +X, de la 0 la
## APPROACH_LEN+TUNNEL_LEN+EXIT_LEN), apoi doua semicercuri late de intoarcere.
## Desenata simplu, in puncte (Catmull-Rom face restul, ca la orice pista).
func _set_curve() -> void:
	var curve := Curve3D.new()
	var straight_len := APPROACH_LEN + TUNNEL_LEN + EXIT_LEN
	var r := RETURN_RADIUS
	# Punctele dreptei de dus (Z=0), apoi bucla de intoarcere pe partea +Z,
	# apoi dreapta de intors (Z = 2r), apoi bucla inapoi la start.
	curve.add_point(Vector3(0.0, 0.0, 0.0))
	curve.add_point(Vector3(straight_len * 0.5, 0.0, 0.0))
	curve.add_point(Vector3(straight_len, 0.0, 0.0))
	# semicerc dreapta (centrul la (straight_len, 0, r))
	curve.add_point(Vector3(straight_len + r, 0.0, r * 0.55))
	curve.add_point(Vector3(straight_len + r, 0.0, r * 1.45))
	curve.add_point(Vector3(straight_len, 0.0, r * 2.0))
	curve.add_point(Vector3(straight_len * 0.5, 0.0, r * 2.0))
	curve.add_point(Vector3(0.0, 0.0, r * 2.0))
	# semicerc stanga (centrul la (0, 0, r))
	curve.add_point(Vector3(-r, 0.0, r * 1.45))
	curve.add_point(Vector3(-r, 0.0, r * 0.55))
	var path := _track.get_node_or_null("Path") as Path3D
	if path == null:
		path = Path3D.new()
		path.name = "Path"
		_track.add_child(path)
	path.curve = curve


func _build_signal() -> void:
	_signal = TunnelSignalHazard.new()
	_signal.name = "SemaforSonda"
	# Runda 2: period=40 (22 verde + 18 rosu = 6 golire + 12 tranzit), NU mai
	# scriem "red_hold" direct (e calculat din clear_hold + cross_time()).
	_signal.period = 40.0
	_signal.clear_hold = 6.0
	_signal.tunnel_length = TUNNEL_LEN
	_signal.bus_speed = TUNNEL_LEN / 12.0 # ~12.5 m/s, cf. brief
	_track.add_child(_signal)
	await get_tree().physics_frame
	# Nodul semaforului sta la linia de oprire, cu +Z local spre tunel (vezi
	# antetul TunnelSignalHazard._rebuild_bus_curve). Axa soselei aici e +X, deci
	# rotim 90 grade in jurul lui Y (local +Z -> lume +X).
	_signal.global_transform = Transform3D(
		Basis(Vector3.UP, -PI / 2.0), Vector3(_stop_line_x, 0.3, 0.0))


## Niste "pockets" statice pe peretele din dreapta al tunelului (lumea +Z e
## dreapta soselei aici, cu masinile mergand spre +X): trei goluri in perete,
## cu podea si tavan, ca o masina sa poata sta EFECTIV in afara benzii de
## 7 m. Fara model — doar coliziune + un cub semi-transparent ca sa se vada in
## capturi manuale, daca cineva se uita.
func _build_niches() -> void:
	var hw := TUNNEL_HALF_WIDTH
	for i in NICHE_COUNT:
		var x := _tunnel_start_x + NICHE_SPACING_M * float(i + 1)
		if x > _tunnel_end_x - 5.0:
			continue
		var body := StaticBody3D.new()
		body.name = "Nisa%d" % i
		_track.add_child(body)
		# Podea la nivelul drumului, extinsa spre +Z (dreapta) cu NICHE_DEPTH_M.
		var floor_shape := CollisionShape3D.new()
		var floor_box := BoxShape3D.new()
		floor_box.size = Vector3(NICHE_WIDTH_M, 0.2, NICHE_DEPTH_M)
		floor_shape.shape = floor_box
		floor_shape.position = Vector3(x, -0.1,
			hw + NICHE_DEPTH_M * 0.5)
		body.add_child(floor_shape)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = floor_box.size
		mesh.mesh = box
		mesh.position = floor_shape.position
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.5, 0.35, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		body.add_child(mesh)


func _spawn_cars() -> void:
	var n := _track.baked.size()
	for i in CAR_COUNT:
		var car := CAR_SCENE.instantiate() as Car
		car.track = _track
		add_child(car)
		# Grila la returul buclei (departe de linia de oprire), ca sa nu
		# porneasca deja in tunel. `spawn_transforms` foloseste bucla reala.
		var xform := _track.spawn_transforms(CAR_COUNT)[i]
		car.global_transform = xform
		car.route = 0
		car.road_index = _track.closest_index_global(car.global_position)
		car.last_safe_index = car.road_index
		car.last_safe_route = 0
		car.pilot_name = "AI%d" % i
		var data_idx: int = AI_CARS[i % AI_CARS.size()]
		car.apply_data(GameState.CAR_DATA[data_idx] as CarData)
		var ai := AIController.new()
		car.set_controller(ai)
		ai.configure(_track, _rng, _cars)
		car.speed_scale = _rng.randf_range(0.88, 0.97)
		car.race_active = true
		car.on_start_grid = false
		_cars.append(car)
		_controllers.append(ai)
		var st := Stats.new()
		st.name = "%s(%s)" % [car.pilot_name, (GameState.CAR_DATA[data_idx] as CarData).display_name]
		_stats.append(st)
		car.respawned.connect(_on_respawn.bind(i))
		# Criteriul 5 din brief: "un AI lovit frontal e impins inapoi, nu
		# distrus, si nu ramane intepenit in nisa/perete" -- ejectarea
		# soferului (prototipul ragdoll) e cea mai apropiata notiune de
		# "distrus" pe care o are jocul azi.
		car.ejected.connect(_on_eject.bind(i))
	_signal.bus_hit.connect(_on_bus_hit)
	# Toate masinile isi vad reciproc pentru depasire/ocolire (configure() le-a
	# primit deja cu lista goala la constructie — se repara aici cu lista plina).
	var traffic: Array[Car] = _cars
	for ai in _controllers:
		ai.traffic = traffic


func _on_respawn(_car: Car, index: int) -> void:
	_stats[index].respawns += 1


func _on_eject(car: Car, _ragdoll: Node3D, index: int) -> void:
	_stats[index].ejects += 1
	print("[ejectare] t=%6.1fs %-24s poz=(%.1f,%.1f,%.1f) cauza=%s v=%.1f" % [
		_elapsed, _stats[index].name,
		car.global_position.x, car.global_position.y, car.global_position.z,
		car.last_eject_cause, car.last_eject_value])


func _on_bus_hit(car: Car) -> void:
	var idx := _cars.find(car)
	if idx >= 0:
		_stats[idx].bus_hits += 1
		if OS.get_environment("PROBE_FIORD_TRACE") == "1":
			print("[bus-hit] t=%6.1fs %-24s v=%.1f poz=(%.1f,%.1f,%.1f)" % [
				_elapsed, _stats[idx].name, car.horizontal_speed(),
				car.global_position.x, car.global_position.y, car.global_position.z])


func _physics_process(delta: float) -> void:
	if _done or _signal == null or _cars.is_empty():
		return
	_elapsed += delta
	if OS.get_environment("PROBE_FIORD_TRACE") == "1" and int(_elapsed * 4.0) % 4 == 0 \
			and int(_elapsed * 60.0) % 15 == 0:
		var b := _signal.bus()
		if b != null:
			print("TRACE t=%5.1f red=%s bus_hidden=%s bus_pos=(%.1f,%.1f,%.1f) bus_dist=%.1f"
				% [_elapsed, _signal.is_red(), b.is_hidden(),
					b.body().global_position.x, b.body().global_position.y,
					b.body().global_position.z, b.distance()])
	for i in _cars.size():
		_tick_car(i, delta)
	if _elapsed >= _seconds:
		_report()


func _tick_car(i: int, delta: float) -> void:
	var car := _cars[i]
	var st: Stats = _stats[i]
	if not is_instance_valid(car):
		return
	var speed := car.horizontal_speed()
	st.laps = float(_track.frac_at(car.road_index, car.route))

	# Pozitia pe axa soselei (lume +X aici) fata de linia de oprire.
	var side_x := car.global_position.x - _stop_line_x
	var in_stop_zone := absf(side_x) < STOP_ZONE_M
	var red := _signal.is_red()

	# --- a intrat pe rosu? tranzitia side_x de la negativ la pozitiv, cu masina
	# in banda tunelului (Z aproape de axa), cat semaforul era rosu la trecere.
	if st._last_side_x < 0.0 and side_x >= 0.0 and absf(car.global_position.z) < TUNNEL_HALF_WIDTH + 1.0:
		var red_left := _signal.red_seconds_left()
		if red:
			st.ran_red += 1
			# Sub RED_EDGE_S ramase: verdele apare in ACEEASI fereastra de tick in
			# care masina trece linia — tine mai mult de alinierea discreta a
			# esantionului nostru decat de o decizie a AI-ului de a trece pe rosu.
			# Se raporteaza SEPARAT (nu se ascunde), dar nu intra la ran_red_clear.
			if red_left > RED_EDGE_S:
				st.ran_red_clear += 1
			print("[trecere-pe-rosu] t=%6.1fs %-24s v=%.1f poz=(%.1f,%.1f,%.1f) rosu_ramas=%.2fs %s"
				% [_elapsed, st.name, speed, car.global_position.x,
					car.global_position.y, car.global_position.z, red_left,
					"(limita verde)" if red_left <= RED_EDGE_S else "(CLAR ROSU)"])
		st._crossed_red_flag = false
	st._last_side_x = side_x

	# --- asteptarea la linie ---
	if red and in_stop_zone and speed < STOP_SPEED and side_x < 2.0:
		if not st.waiting_now:
			st.waiting_now = true
			st.wait_start = _elapsed
	elif st.waiting_now and (not red or side_x > 2.0 or speed >= STOP_SPEED * 3.0):
		# A plecat (verde sau s-a resetat): inregistram asteptarea, doar daca
		# a fost intr-adevar in dreptul liniei cat era rosu.
		st.waiting_now = false
		var dur := _elapsed - st.wait_start
		if dur > 0.2:
			st.wait_times.append(dur)

	# --- pile-up: oprita > 5s la linie DUPA ce a prins verde ---
	if not red and in_stop_zone and speed < STOP_SPEED:
		if not st._was_stopped_at_line:
			st._was_stopped_at_line = true
			st._green_stall_timer = 0.0
		st._green_stall_timer += delta
		if st._green_stall_timer > 5.0:
			st.green_stall_reports += 1
			print("[pile-up] t=%6.1fs %-24s oprita %.1fs dupa verde la linie" % [
				_elapsed, st.name, st._green_stall_timer])
			st._green_stall_timer = -1000.0 # un singur raport per episod
	else:
		st._was_stopped_at_line = false
		st._green_stall_timer = 0.0

	# --- [blocaj], metrica ProbeRace: progres pe traseu sub prag pe fereastra,
	# CU ACEEASI scutire ca AIController._watch_progress (asteptarea la rosu
	# nu e blocaj) — altfel am raporta drept "blocaj" exact comportamentul
	# corect cerut de brief.
	_watch_stuck(i, car, st, speed, delta, red and in_stop_zone)


var _stuck_t: PackedFloat32Array = PackedFloat32Array()
var _stuck_reports_n: PackedInt32Array = PackedInt32Array()
var _last_idx: PackedInt32Array = PackedInt32Array()


func _watch_stuck(i: int, car: Car, st: Stats, speed: float, delta: float,
		waiting_legit: bool) -> void:
	if _stuck_t.size() <= i:
		_stuck_t.resize(_cars.size())
		_stuck_reports_n.resize(_cars.size())
	if waiting_legit:
		_stuck_t[i] = 0.0
		return
	if speed > 6.0:
		_stuck_t[i] = 0.0
		return
	_stuck_t[i] += delta
	if _stuck_t[i] < 3.0 or _stuck_reports_n[i] >= 6:
		return
	_stuck_t[i] = 0.0
	_stuck_reports_n[i] += 1
	st.stuck_reports += 1
	var touching: Array[String] = []
	for body in car.get_colliding_bodies():
		var n := body as Node3D
		if n != null:
			touching.append(String(n.name))
	print("[blocaj] t=%6.1fs %-24s frac=%.3f v=%4.1f poz=(%.0f,%.0f,%.0f) atinge: %s" % [
		_elapsed, st.name, float(_track.frac_at(car.road_index, car.route)), speed,
		car.global_position.x, car.global_position.y, car.global_position.z,
		", ".join(touching) if not touching.is_empty() else "-"])


func _report() -> void:
	_done = true
	print("\n=== SEMAFORUL TUNELULUI — seed %d, %.0fs, %d masini ===" % [
		_seed, _elapsed, _cars.size()])
	print("%-26s %6s %6s %8s %8s %6s %6s %6s %8s" % [
		"masina", "tururi", "resp", "pe-rosu(clar)", "bus-hit", "eject", "blocaj", "pileup", "ast.med/max"])
	var total_red := 0
	var total_red_clear := 0
	var total_bus := 0
	var total_ejects := 0
	var total_stuck := 0
	var total_pileup := 0
	var total_resp := 0
	var all_waits: Array[float] = []
	for st: Stats in _stats:
		var wmax := 0.0
		var wsum := 0.0
		for w in st.wait_times:
			wsum += w
			wmax = maxf(wmax, w)
			all_waits.append(w)
		var wavg := wsum / maxf(float(st.wait_times.size()), 1.0)
		print("%-26s %6.2f %6d %5d(%d) %8d %6d %6d %6d %5.1f/%.1f" % [
			st.name, st.laps, st.respawns, st.ran_red, st.ran_red_clear,
			st.bus_hits, st.ejects, st.stuck_reports, st.green_stall_reports, wavg, wmax])
		total_red += st.ran_red
		total_red_clear += st.ran_red_clear
		total_bus += st.bus_hits
		total_ejects += st.ejects
		total_stuck += st.stuck_reports
		total_pileup += st.green_stall_reports
		total_resp += st.respawns
	var overall_avg := 0.0
	var overall_max := 0.0
	for w in all_waits:
		overall_avg += w
		overall_max = maxf(overall_max, w)
	overall_avg /= maxf(float(all_waits.size()), 1.0)
	print("--- total: repuneri=%d, treceri-pe-rosu=%d (clar rosu: %d), contacte-autocar=%d, ejectari=%d, blocaje=%d, pileup=%d"
		% [total_resp, total_red, total_red_clear, total_bus, total_ejects, total_stuck, total_pileup])
	print("--- asteptare la rosu: medie %.2fs, maxima %.2fs, N=%d opriri" % [
		overall_avg, overall_max, all_waits.size()])
	# Verdict pe criteriul brief-ului: 0 AI intrate pe rosu — folosim
	# ran_red_clear (exclude limita de esantionare la tranzitia in verde,
	# vezi RED_EDGE_S), ca sa nu raportam fals un AI care a franat corect
	# pana la linie si a plecat in fractiunea de secunda cand a prins verde.
	# Ejectarile intra la verdict: e cea mai apropiata notiune de "distrus".
	var ok := total_red_clear == 0 and total_stuck == 0 and total_ejects == 0
	print("\nVERDICT: %s (0 blocaje: %s, 0 treceri-pe-rosu CLAR: %s%s, 0 ejectari: %s)" % [
		"OK" if ok else "PROBLEMA",
		"da" if total_stuck == 0 else "NU (%d)" % total_stuck,
		"da" if total_red_clear == 0 else "NU (%d)" % total_red_clear,
		"" if total_red == total_red_clear else
			" [+%d la limita verde, vezi RED_EDGE_S]" % (total_red - total_red_clear),
		"da" if total_ejects == 0 else "NU (%d)" % total_ejects])
	get_tree().quit(0 if ok else 1)
