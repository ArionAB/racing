extends Node
## Sonda pasajului rotativ (Chongqing, brief §2 POI F si §3): tine ciclul,
## telegraph-ul si contractul de pedeapsa, cu masina REALA (Car.tscn) pe o
## pista-test?
##
## Pista-test: o bucla-stadion din TrackFromPath, cu dreapta de est pe x = 0,
## de la z = +140 la z = -140 (sensul de mers e -Z, deci nodul hazardului sta
## cu yaw 0). Soseaua e LATA (semilatime 16 m) dinadins: rampa de serviciu a
## hazardului iese 13 m lateral, si vrem ca ea sa cada tot pe carosabil —
## altfel decorul temei ar fi avut coliziune fix pe ocol, iar sonda ar fi
## masurat copaci, nu hazard. Pasajul insusi e ridicat cu 3 m (`deck_rise`),
## fiindca golul trebuie sa fie GOL: pe pista adevarata rampa nodului
## Huangjuewan e oricum pe piloni.
##
##  (0)   ciclul: intre doua inceputuri de rotatie trec exact `period` secunde.
##  (i)   telegraph: galbenul se aprinde cu `telegraph_lead` (3 s) inainte de
##        fiecare rotatie, si abia dupa el pleaca tronsonul.
##  (ii)  DESCHIS: masina trece pe tronson de la z=+70 la z=-70, nu cade
##        (y >= cota pasajului), nu e strivita, ramane in cursa, isi pastreaza
##        indexul si iese pe sosea.
##  (iii) INCHIS + ocol: aceeasi traversare pe rampa de serviciu — aceleasi
##        conditii de integritate.
##  (iv)  contractul de pedeapsa: (iii) - (ii) e o intarziere REALA, in
##        fereastra [1.0, 8.0] s (brief: +3 s).
##  (v)   INCHIS + drept in poarta: golul nu e capcana mortala. Masina NU cade
##        in gol, NU e distrusa, si NU ramane intepenita — dupa ce se opreste
##        in bariere, acelasi sofer o duce pe ocol si termina traversarea.
##  (vi)  poarta nu se inchide peste o masina: cu o masina in dreptul portii
##        exact la comutare, colizorul asteapta (`gate_hold` > 0) si masina
##        nu e strivita.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRotatingSpan.tscn
## Iese cu cod 1 la orice verdict picat.

const SpanScript := preload("res://scenes/hazards/rotating_span_hazard.gd")
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const HALF_WIDTH: float = 16.0
const DECK_RISE: float = 3.0
const START_Z: float = 70.0
const FINISH_Z: float = -70.0
const ENTRY_SPEED: float = 24.0
## Cat de mult sub cota pasajului inseamna „a cazut in gol".
const FALL_MARGIN: float = 1.2
## Semilatimea carosabilului hazardului (implicitul lui `road_half_width`).
const HW_HAZ: float = 3.4
## Fereastra contractului de pedeapsa (s).
const PENALTY_MIN: float = 1.0
const PENALTY_MAX: float = 8.0

var _track: TrackFromPath
var _hazard: SpanScript
var _fails: int = 0


func _ready() -> void:
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeRotatingSpan"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame

	_hazard = SpanScript.new()
	_hazard.name = "RotatingSpan"
	_hazard.deck_rise = DECK_RISE
	_hazard.service_side = -1 # spre interiorul buclei
	for a in OS.get_cmdline_user_args():
		if a == "--no-deck-parapet":
			_hazard.deck_parapet = 0.0
		elif a == "--no-service-parapet":
			_hazard.service_parapet = 0.0
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== PASAJUL ROTATIV: ciclu, telegraph, contract de pedeapsa ===")
	print("  period %.1f s (asteptare %.2f + rotatie %.1f, de doua ori), telegraph %.1f s"
		% [_hazard.period, _hazard.hold_time(), _hazard.turn_time, _hazard.telegraph_lead])
	print("  gol %.2f m, pasaj +/-%.1f m, rampa %.1f m, cota pasajului %.1f m"
		% [_hazard.span_length, _hazard.deck_run, _hazard.ramp_run, DECK_RISE])
	var sw := _hazard.service_waypoints()
	print("  ocol: %d puncte, de la %s la %s, iesire laterala max %.1f m"
		% [sw.size(), str(sw[0].round()), str(sw[sw.size() - 1].round()),
		_lateral_max(sw)])
	print("  fereastra de desprindere |z| %s, poarta la z=%.2f (dorit %.2f)"
		% [str(_hazard.merge_window()), _hazard.gate_z(),
		_hazard.span_length * 0.5 + _hazard.gate_lead])
	var ext := _hazard.gate_extent()
	print("  poarta: perete x %.2f..%.2f (drumul e %.1f..%.1f); ocolul la poarta: axa %.2f, margine interioara %.2f"
		% [ext[0], ext[1], -HW_HAZ, HW_HAZ,
		_hazard.service_center_mag(_hazard.gate_z()),
		_hazard.service_inner_mag(_hazard.gate_z())])
	await _run()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


## Masina e deasupra modulului inaltat (pasaj plan + gol + ocol), acolo unde
## „sub cota pasajului" chiar inseamna cazuta?
func _over_module(car: Car) -> bool:
	var z := car.global_position.z
	return absf(z) < _hazard.span_length * 0.5 + _hazard.deck_run


## Ce atinge masina: raze scurte pe opt directii din centrul caroseriei.
## Un verdict „blocata" fara asta e o cifra fara vinovat — si vinovatul (poarta?
## parapetul ocolului? parapetul pasajului?) decide ce se repara.
func _around(car: Car) -> String:
	var space := car.get_world_3d().direct_space_state
	var from := car.global_position + Vector3.UP * 0.5
	var out := ""
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var dir := Vector3(sin(ang), 0.0, -cos(ang))
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 3.0)
		q.exclude = [car.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var col: Node = hit["collider"]
		out += "%s@%.1fm(%s) " % [_dir_name(i),
			from.distance_to(hit["position"]), col.name]
	return out if out != "" else "liber"


func _dir_name(i: int) -> String:
	return ["fata", "fata-dr", "dr", "spate-dr", "spate", "spate-st", "st",
		"fata-st"][i]


func _lateral_max(pts: Array[Vector3]) -> float:
	var m := 0.0
	for p in pts:
		m = maxf(m, absf(p.x))
	return m


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _spawn(at: Vector3, speed: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	# Botul spre -Z: sensul de mers pe dreapta de est a buclei-test.
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3(0, 0, -speed)
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	return car


## Asteapta pana la inceputul starii cerute (t din ciclu aproape de granita).
func _wait_state(want: int, timeout: float = 60.0) -> bool:
	var was := _hazard.state()
	for _f in int(timeout * 60.0):
		await get_tree().physics_frame
		if _hazard.state() == want and was != want:
			return true
		was = _hazard.state()
	return false


# ------------------------------------------------------- (0) + (i) ceasuri

func _measure_cycle() -> void:
	print("--- (0)+(i) ceasul si telegraph-ul")
	var samples: Array[float] = []
	var lead_first := -1.0
	var lead_second := -1.0
	var t_prev_turn := -1.0
	var t := 0.0
	var yellow_since := -1.0
	var was := _hazard.state()
	for _f in int(_hazard.period * 2.6 * 60.0):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var lamp := _hazard.lamp()
		if lamp == 1 and yellow_since < 0.0:
			yellow_since = t
		var now := _hazard.state()
		var turning := now == SpanScript.State.TURNING_SHUT \
			or now == SpanScript.State.TURNING_OPEN
		var was_turning := was == SpanScript.State.TURNING_SHUT \
			or was == SpanScript.State.TURNING_OPEN
		if turning and not was_turning:
			if t_prev_turn > 0.0:
				samples.append(t - t_prev_turn)
			if yellow_since > 0.0:
				var lead := t - yellow_since
				if lead_first < 0.0:
					lead_first = lead
				elif lead_second < 0.0:
					lead_second = lead
			t_prev_turn = t
			yellow_since = -1.0
		was = now
	# Intre doua inceputuri de rotatie e o JUMATATE de ciclu (inchidere si
	# deschidere), deci perioada e suma a doua intervale consecutive.
	var half_a := samples[0] if samples.size() > 0 else 0.0
	var half_b := samples[1] if samples.size() > 1 else 0.0
	print("    rotatii masurate: %s; jumatatile %.2f + %.2f = %.2f s (cerut %.1f)"
		% [str(samples), half_a, half_b, half_a + half_b, _hazard.period])
	print("    galbenul apare cu %.2f / %.2f s inainte de rotatie (cerut %.1f)"
		% [lead_first, lead_second, _hazard.telegraph_lead])
	_verdict(absf(half_a + half_b - _hazard.period) < 0.2,
		"ciclul complet e %.2f s (cerut %.1f)" % [half_a + half_b, _hazard.period])
	_verdict(absf(lead_first - _hazard.telegraph_lead) < 0.25
			and absf(lead_second - _hazard.telegraph_lead) < 0.25,
		"telegraph-ul precede fiecare rotatie cu %.1f s" % _hazard.telegraph_lead)


# ------------------------------------------------------------ traversarile

## Conduce o masina de la START_Z la FINISH_Z pe punctele date. Intoarce
## secundele (INF daca n-a ajuns) si tipareste ce s-a intamplat.
func _drive(label: String, points: Array[Vector3], timeout: float = 22.0,
		car_out: Array = []) -> float:
	var car := _spawn(Vector3(0.0, 0.7, START_Z), ENTRY_SPEED)
	car_out.append(car)
	var driver := WaypointDriver.new()
	driver.waypoints = points
	driver.target_speed = 30.0
	car.set_controller(driver)
	var t := 0.0
	var min_y := INF
	var max_crush := 0.0
	var idx_start := car.road_index
	var frames := 0
	while t < timeout:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		frames += 1
		# Cota se masoara DOAR peste modul (pasaj + gol + ocol). Prima versiune
		# lua minimul pe tot drumul si pica de fiecare data pe soseaua-test de
		# la y = 0, adica raporta „a cazut in gol" pentru o masina care nici nu
		# urcase inca pe pasaj.
		if _over_module(car):
			min_y = minf(min_y, car.global_position.y)
		max_crush = maxf(max_crush, car.crush_time)
		if frames % 60 == 0:
			print("    %s t=%5.2f pos %s v=%5.1f roti %d index %d (frac %.3f)"
				% [label, t, str(car.global_position.round()),
				car.horizontal_speed(), car.wheels_on_ground, car.road_index,
				_track.frac_at(car.road_index)])
		if car.global_position.z <= FINISH_Z:
			break
	var arrived := car.global_position.z <= FINISH_Z
	print("--- %s: %s in %.2f s; y min %.2f (pasaj la %.1f), strivire max %.2f s, activa %s, index %d -> %d"
		% [label, "ajunsa" if arrived else "NEAJUNSA", t, min_y, DECK_RISE,
		max_crush, str(car.race_active), idx_start, car.road_index])
	_verdict(min_y > DECK_RISE - FALL_MARGIN,
		"%s: nu cade in gol (y min %.2f > %.2f)" % [label, min_y, DECK_RISE - FALL_MARGIN])
	_verdict(max_crush <= 0.01, "%s: nu e strivita (crush %.2f s)" % [label, max_crush])
	_verdict(car.race_active, "%s: ramane in cursa" % label)
	return t if arrived else INF


func _run() -> void:
	await _measure_cycle()

	# ---------------------------------------------- (ii) traversarea directa
	print("--- (ii) DESCHIS: traversare pe tronson")
	var ok_open := await _wait_state(SpanScript.State.OPEN)
	_verdict(ok_open, "pasajul s-a deschis")
	var direct: Array[Vector3] = _hazard.direct_waypoints()
	direct.append(Vector3(0.0, 0.0, FINISH_Z - 20.0))
	var open_cars: Array = []
	var t_direct := await _drive("DESCHIS", direct, 22.0, open_cars)
	var car_open: Car = open_cars[0]
	_verdict(t_direct < INF, "traversare directa terminata (%.2f s)" % t_direct)
	await get_tree().physics_frame
	_verdict(_track.is_on_road(car_open.road_index, car_open.global_position, 0),
		"DESCHIS: iese pe sosea (index %d, frac %.3f)"
		% [car_open.road_index, _track.frac_at(car_open.road_index)])
	var frac_open := _track.frac_at(car_open.road_index)
	car_open.queue_free()
	await get_tree().physics_frame

	# ------------------------------------------------- (iii) ocolul, inchis
	print("--- (iii) INCHIS: traversare pe rampa de serviciu")
	var ok_shut := await _wait_state(SpanScript.State.SHUT)
	_verdict(ok_shut, "pasajul s-a inchis")
	_verdict(_hazard.gate_solid(), "poarta de bariere e solida cat e inchis")
	var service: Array[Vector3] = [Vector3(0.0, DECK_RISE, 45.0),
		Vector3(0.0, DECK_RISE, 28.0)]
	service.append_array(_hazard.service_waypoints())
	service.append(Vector3(0.0, DECK_RISE, -28.0))
	service.append(Vector3(0.0, 0.0, FINISH_Z - 20.0))
	var shut_cars: Array = []
	var t_service := await _drive("OCOL", service, 26.0, shut_cars)
	var car_shut: Car = shut_cars[0]
	_verdict(t_service < INF, "ocolul terminat (%.2f s)" % t_service)
	await get_tree().physics_frame
	_verdict(_track.is_on_road(car_shut.road_index, car_shut.global_position, 0),
		"OCOL: iese pe sosea (index %d, frac %.3f)"
		% [car_shut.road_index, _track.frac_at(car_shut.road_index)])
	var frac_shut := _track.frac_at(car_shut.road_index)
	print("    fractia de tur la iesire: direct %.3f, ocol %.3f" % [frac_open, frac_shut])
	car_shut.queue_free()
	await get_tree().physics_frame

	# --------------------------------------------- (iv) contractul de pedeapsa
	var penalty := t_service - t_direct
	print("--- (iv) pedeapsa masurata: %.2f - %.2f = %+.2f s (contract: +3 s, fereastra %.1f..%.1f)"
		% [t_service, t_direct, penalty, PENALTY_MIN, PENALTY_MAX])
	_verdict(penalty >= PENALTY_MIN and penalty <= PENALTY_MAX,
		"ocolul costa %+.2f s" % penalty)

	# ------------------------------------- (v) drept in poarta: nu e capcana
	print("--- (v) INCHIS, drept in poarta: nu cade, nu moare, nu ramane blocata")
	var ok_shut2 := await _wait_state(SpanScript.State.SHUT)
	_verdict(ok_shut2, "pasajul s-a inchis din nou")
	# Ceasul hazardului se OPRESTE cat tine testul asta. Intrebarea aici e
	# despre configuratia inchisa („se descurca cineva care a intrat in
	# bariere?"), nu despre ciclu — iar cu ceasul pornit intrebarea nu apuca sa
	# fie pusa: masina a stat 8 s in bariere, intre timp pasajul s-a redeschis,
	# si sonda masura o plimbare printr-un nod fara niciun obstacol. Perioada
	# si telegraph-ul si-au primit oricum verdictele lor la (0) si (i).
	_hazard.set_physics_process(false)
	print("    ceasul hazardului oprit pe INCHIS (tronson la %.2f, poarta solida: %s)"
		% [_hazard.turn_fraction(), str(_hazard.gate_solid())])
	var car := _spawn(Vector3(0.0, 0.7, START_Z), ENTRY_SPEED)
	var driver := WaypointDriver.new()
	driver.waypoints = _hazard.direct_waypoints()
	driver.target_speed = 30.0
	car.set_controller(driver)
	var min_y := INF
	var max_crush := 0.0
	var hit_t := -1.0
	var passed := false
	for f in int(6.0 * 60.0):
		await get_tree().physics_frame
		if _over_module(car):
			min_y = minf(min_y, car.global_position.y)
		max_crush = maxf(max_crush, car.crush_time)
		if hit_t < 0.0 and car.global_position.z < 20.0 and car.horizontal_speed() < 4.0:
			hit_t = float(f) / 60.0
		# Trecuta DINCOLO de gol pe banda directa, cu pasajul inchis: poarta
		# n-a oprit-o. Prima rulare a picat exact aici, prin tunelare printr-un
		# colizor de 0.5 m la 0.5 m pe cadru.
		if car.global_position.z < -_hazard.span_length * 0.5 - 1.0:
			passed = true
	print("    dupa 6 s: pozitie %s, viteza %.2f, y min %.2f, strivire max %.2f, activa %s, sus %.2f"
		% [str(car.global_position.round()), car.horizontal_speed(), min_y,
		max_crush, str(car.race_active), car.global_transform.basis.y.y])
	_verdict(min_y > DECK_RISE - FALL_MARGIN,
		"nu a cazut in gol (y min %.2f)" % min_y)
	_verdict(not passed, "poarta a oprit-o inainte de gol (trecuta: %s)" % str(passed))
	_verdict(max_crush <= 0.01, "nu e distrusa (crush %.2f s)" % max_crush)
	_verdict(car.race_active, "ramane in cursa")
	_verdict(car.global_transform.basis.y.y > 0.3,
		"nu a ramas rasturnata (up.y %.2f)" % car.global_transform.basis.y.y)
	# Iesirea din blocaj: acelasi sofer, pe ocol — dar numai pe punctele din
	# FATA masinii. Prima versiune ii dadea lista intreaga a ocolului, care
	# incepe cu 15 m in spatele locului unde poarta o oprise: soferul intorcea
	# ca sa atinga un punct depasit, si sonda masura o manevra inventata de ea,
	# nu iesirea din blocaj.
	var out: Array[Vector3] = []
	for p in _hazard.service_waypoints():
		if p.z < car.global_position.z - 2.0:
			out.append(p)
	out.append(Vector3(0.0, DECK_RISE, -28.0))
	out.append(Vector3(0.0, 0.0, FINISH_Z - 20.0))
	print("    reluare: %d puncte in fata, primul %s (masina la %s)"
		% [out.size(), str(out[0].round()), str(car.global_position.round())])
	driver.waypoints = out
	driver.index = 0
	# Din loc, cu ocolul la cativa metri in stanga: punctele apropiate sunt
	# chiar cele utile, deci raza de „atins" scade. Cu 7 m soferul le sarea pe
	# primele si tragea de volan spre unul de dincolo de gol.
	driver.reach = 4.0
	driver.target_speed = 18.0
	var escaped := false
	var t_out := 0.0
	var min_out := INF
	var t_freed := -1.0
	for f in int(32.0 * 60.0):
		await get_tree().physics_frame
		t_out += 1.0 / 60.0
		# „Desprinsa" = a rulat iar, nu doar s-a zbatut in bariere.
		if t_freed < 0.0 and car.horizontal_speed() > 8.0:
			t_freed = t_out
		if _over_module(car):
			min_out = minf(min_out, car.global_position.y)
		if f % 30 == 0:
			print("      t=%5.2f pos %s v=%5.1f dir %s | %s" % [t_out,
				str(car.global_position.round()), car.horizontal_speed(),
				str((-car.global_transform.basis.z).snapped(Vector3.ONE * 0.1)),
				_around(car)])
		if car.global_position.z <= FINISH_Z:
			escaped = true
			break
	print("    reluare pe ocol: %s in %.2f s, desprinsa la %.2f s, pozitie %s"
		% ["iesita" if escaped else "BLOCATA", t_out, t_freed,
		str(car.global_position.round())])
	_verdict(t_freed >= 0.0 and t_freed < 20.0,
		"se desprinde din bariere (a rulat iar dupa %.2f s)" % t_freed)
	_verdict(escaped, "masina nu ramane intepenita (a terminat ocolul in %.2f s)" % t_out)
	_verdict(min_out > DECK_RISE - FALL_MARGIN,
		"la reluare nu cade de pe pasaj (y min %.2f)" % min_out)
	_hazard.set_physics_process(true)
	car.queue_free()
	await get_tree().physics_frame

	# ------------------------------- (vi) poarta nu se inchide peste o masina
	print("--- (vi) poarta cu senzor: nu se inchide peste o masina")
	var ok_open2 := await _wait_state(SpanScript.State.OPEN)
	_verdict(ok_open2, "pasajul s-a deschis pentru testul portii")
	# Masina, oprita, fix in dreptul portii; asteptam comutarea.
	var gate_z := _hazard.gate_z()
	var parked := _spawn(Vector3(0.0, DECK_RISE + 0.7, gate_z), 0.0)
	var park_driver := WaypointDriver.new()
	park_driver.waypoints = []
	park_driver.throttle_when_done = 0.0
	parked.set_controller(park_driver)
	var hold_max := 0.0
	var solid_while_inside := false
	var crush_max := 0.0
	for _f in int((_hazard.hold_time() + _hazard.turn_time + 2.0) * 60.0):
		await get_tree().physics_frame
		hold_max = maxf(hold_max, _hazard.gate_hold())
		crush_max = maxf(crush_max, parked.crush_time)
		var inside := absf(parked.global_position.z - gate_z) < 2.5
		if inside and _hazard.gate_solid():
			solid_while_inside = true
	print("    masina la z=%.1f (poarta la %.1f): asteptare max %.2f s (plafon %.2f), strivire %.2f, solid peste ea: %s"
		% [parked.global_position.z, gate_z, hold_max, _hazard.gate_hold_max,
		crush_max, str(solid_while_inside)])
	_verdict(hold_max > 0.0, "poarta a asteptat masina (%.2f s)" % hold_max)
	_verdict(crush_max <= 0.01, "masina din poarta nu e strivita")
	parked.queue_free()
	await get_tree().physics_frame
