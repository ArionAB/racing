extends Node
## Sonda risc/recompensa a scurtaturii Chasm (Fiordland, Track16, brief §3):
## conduce 4 presetari (cea mai usoara, cea mai grea, cea mai rapida, una
## medie) de la frac 0.33 pe bucla pana la frac 0.50, o data pe BUCLA (a) si o
## data pe SCURTATURA (b), pe uscat si cu ploaie (`track.rain_wet = true`).
##
## Contract (brief §4): pe uscat scurtatura castiga 0.5-1.5 s la >= 3 din 4
## masini; pe ud pierde sau repune la >= 2 din 4. Iese cu 1 daca nu se
## indeplineste.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordScurtatura.tscn

const TRACK := "res://scenes/tracks/Track16.tscn"
const CAR_SCENE := "res://scenes/cars/Car.tscn"
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")

## cea mai usoara (grip mare, masa mica), cea mai grea (suspensie/masa,
## masurate in brief la cascada), cea mai rapida (max_speed), una medie.
const PRESETS: Array[String] = [
	"res://scenes/cars/data/police_sports.tres",
	"res://scenes/cars/data/bus.tres",
	"res://scenes/cars/data/muscle.tres",
	"res://scenes/cars/data/taxi.tres",
]
const PRESET_LABELS: Array[String] = ["Politia (usoara)", "Autobuzul (grea)",
	"Muscle (rapida)", "Taxi (medie)"]

const START_FRAC: float = 0.33
const TARGET_FRAC: float = 0.50
## Cat conteaza "a iesit de pe banda": offroad_speed_factor se aplica sub
## viteza de croaziera, deci mai simplu sa citim is_on_road direct.
const TIMEOUT_S: float = 40.0
## Grip-ul de citire a curbelor pentru soferul de sonda — sub aderenta reala
## a masinii (memoria din probe_rotating_span.gd: masurat pe masina reala,
## ~24 m/s^2, sonda foloseste 16). Prima valoare (14.0) a iesit INERTA la
## schimbarea lui speed_factor (0.85 -> 0.93, aceleasi timpi la bit) — pe
## curbele stranse ale benzii Chasm, plafonul de viraj bate mereu plafonul
## de viteza al benzii, deci sonda masura soferul, nu drumul. Vezi
## probe_rotating_span.gd CORNER_GRIP pentru precedent.
const CORNER_GRIP: float = 20.0

const WIN_MIN: float = 0.5
const WIN_MAX: float = 1.5

var _track: Track
var _fails: int = 0
var _dry_wins: int = 0
var _wet_losses: int = 0
var _rows: Array[Dictionary] = []


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	if _track.routes.size() < 2:
		print("Track16 n-are nicio ruta secundara — sonda nu are ce masura")
		get_tree().quit(1)
		return

	# RainCycle scrie track.rain_wet in fiecare cadru dupa ciclul lui propriu
	# (~95 s) — fara sa-l oprim, comparatia uscat/ud n-ar controla nimic:
	# memoria diferenta-on-off-cere-lume-inghetata. Sonda vrea rain_wet FIX,
	# nu ciclul vizual (cer, ceata, cascade) — se opreste nodul, se scrie
	# direct campul in _run().
	var rain_cycles: Array[Node] = []
	_collect_rain_cycles(_track, rain_cycles)
	for rc in rain_cycles:
		rc.process_mode = Node.PROCESS_MODE_DISABLED
	print("RainCycle oprite: %d (rain_wet controlat direct de sonda)" % rain_cycles.size())

	print("=== SONDA RISC/RECOMPENSA: scurtatura Chasm (Track16) ===")
	print("start frac=%.2f, tinta frac=%.2f, %d presetari x {bucla,scurtatura} x {uscat,ud}"
		% [START_FRAC, TARGET_FRAC, PRESETS.size()])
	print("%-20s %-6s %-11s %8s %6s %8s %10s" % [
		"masina", "vreme", "traseu", "timp(s)", "resp", "v_min", "iesit_banda"])

	for pi in PRESETS.size():
		var label: String = PRESET_LABELS[pi]
		var data: CarData = load(PRESETS[pi])
		var dry_loop: Dictionary = await _run(data, label, false, false)
		var dry_branch: Dictionary = await _run(data, label, false, true)
		var wet_loop: Dictionary = await _run(data, label, true, false)
		var wet_branch: Dictionary = await _run(data, label, true, true)

		var dry_delta: float = dry_loop.time - dry_branch.time \
			if dry_loop.time < INF and dry_branch.time < INF else -INF
		var wet_delta: float = wet_loop.time - wet_branch.time \
			if wet_loop.time < INF and wet_branch.time < INF else -INF
		# Pe uscat, scurtatura CASTIGA daca dry_delta (bucla - scurtatura) e
		# in fereastra [0.5, 1.5].
		var dry_win := dry_delta >= WIN_MIN and dry_delta <= WIN_MAX
		if dry_win:
			_dry_wins += 1
		# Pe ud, scurtatura PIERDE sau REPUNE: fie branch mai lenta decat
		# loop (wet_delta < 0), fie a avut repuneri pe scurtatura uda.
		var wet_resp: int = wet_branch.resp
		var wet_lose: bool = (wet_delta < 0.0) or (wet_resp > 0)
		if wet_lose:
			_wet_losses += 1
		print("  %s: uscat bucla=%.2fs scurtatura=%.2fs delta=%+.2fs (castig %s) | ud bucla=%.2fs scurtatura=%.2fs delta=%+.2fs resp=%d (pierde/repune %s)"
			% [label, dry_loop.time, dry_branch.time, dry_delta,
			str(dry_win), wet_loop.time, wet_branch.time, wet_delta,
			wet_branch.resp, str(wet_lose)])
		_rows.append({"label": label, "dry_loop": dry_loop, "dry_branch": dry_branch,
			"wet_loop": wet_loop, "wet_branch": wet_branch,
			"dry_win": dry_win, "wet_lose": wet_lose})

	print("\n--- rezumat ---")
	print("uscat: scurtatura castiga 0.5-1.5s la %d/%d masini (cerut >= 3/4)"
		% [_dry_wins, PRESETS.size()])
	print("ud: scurtatura pierde sau repune la %d/%d masini (cerut >= 2/4)"
		% [_wet_losses, PRESETS.size()])
	var ok := _dry_wins >= 3 and _wet_losses >= 2
	print("VERDICT: %s" % ("TRECE" if ok else "PICA"))
	get_tree().quit(0 if ok else 1)


func _collect_rain_cycles(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		if child is RainCycle:
			out.append(child)
		_collect_rain_cycles(child, out)


## Conduce o masina de la START_FRAC la TARGET_FRAC, pe bucla sau pe
## scurtatura, uscat sau ud. Intoarce {time, resp, min_speed, off_band}.
func _run(data: CarData, label: String, rain: bool, via_branch: bool) -> Dictionary:
	_track.rain_wet = rain
	var main := _track.route_at(0)
	var branch := _track.route_at(1)
	var n := main.baked.size()
	var start_i := int(START_FRAC * float(n)) % n
	var start_p: Vector3 = main.baked[start_i]

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(data)
	car.track = _track
	var i0 := maxi(start_i - 1, 0)
	var i1 := mini(start_i + 1, n - 1)
	var fwd: Vector3 = (main.baked[i1] - main.baked[i0])
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length_squared() > 0.0001 else Vector3(0, 0, -1)
	car.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), start_p + Vector3.UP * 0.7)
	car.velocity = fwd * 12.0
	car.route = 0
	car.road_index = start_i
	car.last_safe_index = start_i
	car.last_safe_route = 0
	car.race_active = true

	var resp := 0
	car.respawned.connect(func(_c): resp += 1)

	var driver := WaypointDriver.new()
	driver.waypoints = _waypoints(main, branch, start_i, via_branch)
	# Punctele rare de pe banda (stride 4 * bake_interval 3m ~= 12m intre
	# ele) au nevoie de un reach mai mare decat implicitul de 5.0 — sub
	# spatierea reala, soferul nu ajunge NICIODATA la "reach" de tinta,
	# `index` nu mai avanseaza, si masina oscileaza la nesfarsit langa
	# intrare (masurat cu --trace: v~9 m/s constant, idx sarind intre 0-16
	# minute in sir, fara sa progreseze). Vezi si comentariul din
	# probe_rotating_span.gd despre acelasi tipar de cifre nemonotone.
	driver.reach = 10.0
	driver.corner_grip = CORNER_GRIP
	driver.target_speed = 40.0
	driver.throttle_when_done = 1.0
	car.set_controller(driver)

	var t := 0.0
	var min_speed := INF
	var off_band := false
	var reached := false
	var route_1_frames := 0
	var total_frames := 0
	while t < TIMEOUT_S:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		total_frames += 1
		if car.route == 1:
			route_1_frames += 1
		if via_branch and OS.get_cmdline_user_args().has("--trace") and int(t * 60.0) % 15 == 0:
			print("      [trace %s] t=%.1f pos=(%.0f,%.0f,%.0f) route=%d idx=%d frac=%.4f v=%.1f"
				% [label, t, car.global_position.x, car.global_position.y,
				car.global_position.z, car.route, car.road_index,
				_track.frac_at(car.road_index, car.route), car.horizontal_speed()])
		var sp := car.horizontal_speed()
		if sp < min_speed:
			min_speed = sp
		if not _track.is_on_road(car.road_index, car.global_position, car.route):
			off_band = true
		var frac := _track.frac_at(car.road_index, car.route)
		# frac_at de pe ruta 0 e deja "progres de tur" (vezi antetul
		# TrackRoute) — pe scurtatura raporteaza acelasi lucru ca punctul
		# echivalent de pe bucla, deci comparatia e directa.
		if frac >= TARGET_FRAC and frac < TARGET_FRAC + 0.05:
			reached = true
			break
	car.queue_free()
	await get_tree().physics_frame
	var route1_pct := 100.0 * route_1_frames / maxf(total_frames, 1)
	if via_branch:
		# Sanitate: pe o rulare "pe scurtatura" masina TREBUIE sa treaca prin
		# ruta 1 pentru o parte semnificativa a timpului, altfel sonda masoara
		# bucla si o eticheteaza gresit "scurtatura" (asta a fost bug-ul din
		# `_waypoints`, gasit prin cifra asta la 0% pe toate rularile).
		var flag := "" if route1_pct > 20.0 else "  <-- SUSPECT: sub 20%, verifica _waypoints()"
		print("    [sanitate %s] pe ruta 1 (banda): %.0f%% din timp%s" % [label, route1_pct, flag])
	return {"time": t if reached else INF, "resp": resp,
		"min_speed": min_speed if min_speed < INF else 0.0, "off_band": off_band}


## Punctele de urmat: cateva pe bucla pana la desprindere, apoi fie bucla mai
## departe, fie banda pana la revenire si inapoi pe bucla pana la tinta.
##
## BUG gasit si reparat: varianta veche oprea peretele "while" cu `i ==
## target_i` (sau `entry_i`), dar `i` avanseaza cu pas 4 — pe o bucla cu
## 1078 puncte, pasul de 4 de la start_i nu nimereste NICIODATA exact
## entry_i (0.335*n), deci soferul ocolea toata scurtatura si mergea pe
## bucla intreaga, in tacere (fara eroare, doar guard-ul de siguranta
## oprea dupa n+5 pasi). Masurat: route1_frames = 0% pe toate cele 8
## rulari "pe scurtatura". Fix: opreste cand INDEXUL A TRECUT de tinta
## (fractie >=), nu cand il nimereste exact.
func _waypoints(main: TrackRoute, branch: TrackRoute, start_i: int,
		via_branch: bool) -> Array[Vector3]:
	var n := main.baked.size()
	var out: Array[Vector3] = []
	var target_i := int(TARGET_FRAC * float(n)) % n
	if not via_branch:
		_walk_main(main, out, start_i, target_i, n)
		return out
	# Pe scurtatura: bucla pana la intrarea benzii, banda intreaga, apoi bucla
	# de la iesirea benzii pana la tinta.
	var entry_i := int(branch.entry_frac * float(n)) % n
	_walk_main(main, out, start_i, entry_i, n)
	# Rar, ca pe bucla (stride 4): punctele coapte ale benzii sunt la
	# ~3 m (bake_interval), deci TOATE ar da soferului de sonda zeci de
	# tinte apropiate — `index` avanseaza la fiecare "reach", iar soferul
	# re-tinteste des in loc sa priveasca inainte pe coarda lunga a benzii.
	var bn := branch.baked.size()
	var bi := 0
	while bi < bn:
		out.append(branch.baked[bi])
		bi += 4
	if (bn - 1) % 4 != 0:
		out.append(branch.baked[bn - 1])
	var exit_i := int(branch.exit_frac * float(n)) % n
	_walk_main(main, out, exit_i, target_i, n)
	return out


## Adauga punctele coapte de pe bucla principala de la `i0` la `i1` (cu pas
## 4), oprindu-se cand indexul a AJUNS SAU A TRECUT de `i1` — nu cand il
## nimereste exact (vezi antetul _waypoints pentru bug-ul pe care il repara
## asta).
func _walk_main(main: TrackRoute, out: Array[Vector3], i0: int, i1: int,
		n: int) -> void:
	var span := posmod(i1 - i0, n)
	var i := i0
	var walked := 0
	while true:
		out.append(main.baked[i])
		var next_walked := walked + 4
		if next_walked >= span:
			if i != i1:
				out.append(main.baked[i1])
			return
		i = (i + 4) % n
		walked = next_walked
