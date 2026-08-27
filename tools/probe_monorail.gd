extends Node
## Sonda monorailului (Chongqing, brief §2 POI G si §3): orar de ~35 s, barieră
## care coboara ca telegraph de 3 s, si contact = ARUNCAT, nu distrus.
##
## Pista-test: bucla-stadion cu dreapta de est pe x = 0 si sensul de mers -Z.
## Traseul monorailului trece perpendicular peste ea, pe un `Path3D` copil —
## adica exact drumul pe care il va avea si pe pista, nu dreapta implicita.
##
##  (0)   orarul: intre doua sosiri ale garniturii la trecere trec `period`
##        secunde, iar drumul e liber cea mai mare parte din ciclu.
##  (i)   telegraph: brațul incepe sa coboare cu `warn_lead` (3 s) inainte de
##        sosire si e CULCAT pana ajunge garnitura; luminile clipesc.
##  (ii)  bariera e TEATRU: o masina care intra in brațul coborat trece prin
##        el — fara strivire, fara oprire, fara sa piarda viteza.
##  (iii) grinda e trecuta: cand nu vine niciun tren, masina traverseaza
##        linia fara sa fie oprita si fara sa fie aruncata in aer de prag.
##  (iv)  LOVITURA: masina prinsa pe trecere e ARUNCATA. „Aruncata" se
##        masoara in METRI DE URCARE fata de turul de control peste aceeasi
##        grinda, nu in secunde cu rotile in aer — asta a fost lipsa gasita de
##        critic in runda 1: sonda culegea `max_y` si nu-l transforma niciodata
##        in verdict, iar pragul de aer (0.25 s) era chiar valoarea martorului,
##        deci un hazard care n-ar fi facut NIMIC pe verticala il trecea.
##        NU: `race_active` stins, NU repunere, NU strivire lunga, NU
##        intepenita sub garnitura.
##  (v)   dupa aruncare masina isi duce indexul mai departe si termina bucata
##        de tur, si ATERIZEAZA langa sosea — nu la 60 m in afara ei.
##  (vi)  cazul advers al criticului: masina OPRITA fix pe trecere. Ea nu are
##        viteza proprie din care aruncarea sa-si ia partea, deci e cazul in
##        care un ghiont necontrolat o scotea din lume (masurat in runda 1:
##        62.75 m lateral, sub cota soselei, nemiscata de la t=7 la t=42).
##        Verdictul cere ca dupa aruncare sa poata PLECA singura de acolo.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMonorail.tscn
## Iese cu cod 1 la orice verdict picat.

const MonoScript := preload("res://scenes/hazards/monorail_hazard.gd")
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const HALF_WIDTH: float = 10.0
## Unde taie monorailul soseaua.
const CROSS_Z: float = 0.0
const START_Z: float = 110.0
const FINISH_Z: float = -70.0
const ENTRY_SPEED: float = 26.0
## Peste atata strivire, „aruncat" a devenit „distrus".
const CRUSH_MAX: float = 0.8
## Cat de sus trebuie sa urce masina peste turul de CONTROL (m). Nu e o cifra
## rotunda: e „vizibil mai sus decat trecerea peste grinda", adica peste un
## metru, iar contractul de proportionalitate cu `throw_height` il verifica
## verdictul de langa el.
const RISE_MIN: float = 1.2
## Cat din `throw_height` are voie sa manance amortizorul suspensiei in cadrele
## de dupa lansare. Masurat pe implicite: 2.6 m ceruti -> 1.73 m urcati, adica
## 0.66. Pragul e sub masuratoare, dar mult peste zero — un `throw_height`
## ignorat (cazul din runda 1, cu urcare de 0.45 m dintr-un lift de 7.5 m/s)
## nu are cum sa treaca.
const RISE_FRACTION: float = 0.5
## Cat de departe de axa soselei are voie sa aterizeze (peste semilatime, m).
## Pe POI G orasul e SUB drum: „aruncat departe" nu e pedeapsa, e iesire din
## lume.
const LAND_MARGIN: float = 8.0

var _track: TrackFromPath
var _hazard: MonoScript
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
	_track.custom_name = "ProbeMonorail"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame

	_hazard = MonoScript.new()
	_hazard.name = "Monorail"
	_hazard.position = Vector3(0.0, 0.0, CROSS_Z)
	# Traseul ca nod copil: linia intra dinspre +X si iese spre -X, taind
	# soseaua. Asa se va aseza si pe pista — desenata, nu parametrizata.
	var route := Path3D.new()
	route.name = "Route"
	var rc := Curve3D.new()
	rc.add_point(Vector3(90.0, 0.0, 26.0))
	rc.add_point(Vector3(30.0, 0.0, 6.0))
	rc.add_point(Vector3(-30.0, 0.0, -6.0))
	rc.add_point(Vector3(-90.0, 0.0, -26.0))
	route.curve = rc
	_hazard.add_child(route)
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== MONORAILUL: orar, bariera de teatru, contact = aruncat ===")
	print("  period %.1f s, avertizare %.1f s, traversare %.1f s; traseu %.1f m, sosire la %.2f s din ciclu"
		% [_hazard.period, _hazard.warn_lead, _hazard.cross_time,
		_hazard.route_length(), _hazard.arrival_time()])
	print("  trecerea e la %s" % str(_hazard.crossing_point().round()))
	await _run()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _spawn(at: Vector3, speed: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3(0, 0, -speed)
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	return car


# ------------------------------------------------------------------- orarul

func _measure_schedule() -> void:
	print("--- (0)+(i) orarul, brațul si luminile")
	var t := 0.0
	var arrivals: Array[float] = []
	var prev_to := _hazard.seconds_to_crossing()
	var boom_start := -1.0
	var leads: Array[float] = []
	var down_at_arrival: Array[float] = []
	var was_moving := false
	var free_frames := 0
	var frames := 0
	for _f in int(_hazard.period * 2.4 * 60.0):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		frames += 1
		if _hazard.phase() == MonoScript.Phase.IDLE:
			free_frames += 1
		# Inceputul coborarii = frontul pe care brațul pleaca DE LA ZERO. Nu
		# se reseteaza la sosire: acolo brațul e culcat (down = 1), iar o
		# resetare a starii il facea sa para ca tocmai a pornit — sonda raporta
		# un telegraph de 35 s, adica tot ciclul.
		var down_now: float = _hazard.boom_down()
		if down_now > 0.02 and not was_moving:
			boom_start = t
		was_moving = down_now > 0.02
		var to_cross := _hazard.seconds_to_crossing()
		if to_cross > prev_to + 1.0:
			arrivals.append(t)
			if boom_start > 0.0:
				leads.append(t - boom_start)
			down_at_arrival.append(_hazard.boom_down())
			boom_start = -1.0
		prev_to = to_cross
	var gaps: Array[float] = []
	for i in range(1, arrivals.size()):
		gaps.append(arrivals[i] - arrivals[i - 1])
	print("    sosiri la %s s; intervale %s" % [str(arrivals), str(gaps)])
	print("    brațul incepe sa coboare cu %s s inainte; e coborat %s la sosire"
		% [str(leads), str(down_at_arrival)])
	print("    drumul e liber %.0f%% din ciclu" % (100.0 * float(free_frames) / float(frames)))
	var gap: float = gaps[0] if gaps.size() > 0 else 0.0
	_verdict(absf(gap - _hazard.period) < 0.3,
		"intre doua sosiri trec %.2f s (cerut %.1f)" % [gap, _hazard.period])
	_verdict(_hazard.period >= 30.0 and _hazard.period <= 40.0,
		"orarul e in jurul valorii din brief ~35 s (%.1f)" % _hazard.period)
	# Prima masuratoare se arunca: sonda porneste la un moment oarecare din
	# ciclu si poate prinde brațul deja in coborare.
	var lead_ok := leads.size() >= 2
	for i in range(1, leads.size()):
		if absf(leads[i] - _hazard.warn_lead) > 0.3:
			lead_ok = false
	_verdict(lead_ok, "brațul porneste cu %.1f s inainte de sosire (masurat %s)"
		% [_hazard.warn_lead, str(leads.slice(1))])
	var all_down := down_at_arrival.size() > 0
	for d in down_at_arrival:
		if d < 0.95:
			all_down = false
	_verdict(all_down, "brațul e CULCAT cand ajunge garnitura (%s)"
		% str(down_at_arrival))
	_verdict(float(free_frames) / float(frames) > 0.6,
		"drumul e liber cea mai mare parte din ciclu")


## Asteapta pana cand garnitura ajunge la trecere peste `want` secunde
## (+/- 0.1). Intoarce false daca n-a prins fereastra.
func _wait_until_arrival_in(want: float) -> bool:
	for _f in int(_hazard.period * 3.0 * 60.0):
		await get_tree().physics_frame
		var s := _hazard.seconds_to_crossing()
		if absf(s - want) < 0.06:
			return true
	return false


# ---------------------------------------------------------------- traversari

## Conduce o masina de la START_Z spre FINISH_Z si raporteaza ce a patit.
func _drive(label: String, timeout: float) -> Dictionary:
	var car := _spawn(Vector3(0.0, 0.7, START_Z), ENTRY_SPEED)
	var driver := WaypointDriver.new()
	driver.waypoints = [Vector3(0.0, 0.0, FINISH_Z - 40.0)]
	driver.target_speed = ENTRY_SPEED
	car.set_controller(driver)
	var idx0 := car.road_index
	var t := 0.0
	var crush := 0.0
	var spin := 0.0
	var max_y := -INF
	var max_x := 0.0
	var min_speed := INF
	var airborne := 0.0
	var arrived := false
	while t < timeout:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		crush = maxf(crush, car.crush_time)
		spin = maxf(spin, car.get("_spin_left"))
		max_y = maxf(max_y, car.global_position.y)
		max_x = maxf(max_x, absf(car.global_position.x))
		if car.wheels_on_ground == 0:
			airborne += 1.0 / 60.0
		# Viteza minima se masoara doar dupa ce a intrat in zona trecerii:
		# pornirea de la START_Z nu are de-a face cu hazardul.
		if car.global_position.z < CROSS_Z + 40.0:
			min_speed = minf(min_speed, car.horizontal_speed())
		if car.global_position.z <= FINISH_Z:
			arrived = true
			break
	print("--- %s: %s in %.2f s; strivire %.2f, spin %.2f, y max %.2f, |x| max %.2f, aer %.2f s, activa %s, index %d -> %d"
		% [label, "ajunsa" if arrived else "NEAJUNSA", t, crush, spin, max_y,
		max_x, airborne, str(car.race_active), idx0, car.road_index])
	var out := {
		"t": t if arrived else INF,
		"crush": crush,
		"spin": spin,
		"max_y": max_y,
		"max_x": max_x,
		"air": airborne,
		"min_speed": min_speed,
		"active": car.race_active,
		"idx0": idx0,
		"idx": car.road_index,
		"pos": car.global_position,
		"on_road": _track.is_on_road(car.road_index, car.global_position, 0),
	}
	car.queue_free()
	await get_tree().physics_frame
	return out


func _run() -> void:
	await _measure_schedule()

	# ------------------------------------------- (iii) grinda, cu drumul liber
	print("--- (iii) grinda se trece cand nu vine niciun tren")
	# Lansare astfel incat masina sa ajunga la trecere cand garnitura e departe.
	var travel := (START_Z - CROSS_Z) / ENTRY_SPEED
	var ok_free := await _wait_until_arrival_in(travel + _hazard.period * 0.5)
	_verdict(ok_free, "am prins fereastra libera")
	var free_run := await _drive("LIBER", 16.0)
	_verdict(free_run["t"] < INF, "traversare libera terminata (%.2f s)" % free_run["t"])
	_verdict(free_run["crush"] <= 0.01,
		"grinda nu striveste (%.2f)" % free_run["crush"])
	_verdict(free_run["air"] < 0.5,
		"grinda nu e o rampa: doar %.2f s in aer" % free_run["air"])
	_verdict(free_run["min_speed"] > 12.0,
		"grinda nu opreste masina (viteza min %.2f)" % free_run["min_speed"])

	# ---------------------------------- (ii) bariera coborata e doar teatru
	print("--- (ii) brațul coborat e teatru: se trece prin el")
	# Masina ajunge la trecere cat brațul e jos, dar INAINTE de garnitura:
	# adica in intervalul de avertizare.
	var ok_boom := await _wait_until_arrival_in(travel + 0.8)
	_verdict(ok_boom, "am prins fereastra cu brațul coborat")
	var boom_run := await _drive("BARIERA", 16.0)
	_verdict(boom_run["t"] < INF,
		"a trecut prin bariera (%.2f s)" % boom_run["t"])
	_verdict(boom_run["crush"] <= 0.01,
		"brațul nu striveste (%.2f)" % boom_run["crush"])
	_verdict(boom_run["min_speed"] > 12.0,
		"brațul nu opreste masina (viteza min %.2f)" % boom_run["min_speed"])
	_verdict(absf(boom_run["t"] - free_run["t"]) < 0.4,
		"bariera nu costa timp (%.2f fata de %.2f)"
		% [boom_run["t"], free_run["t"]])

	# ------------------------------------------------ (iv)+(v) sub garnitura
	print("--- (iv)+(v) lovitura: ARUNCAT, nu distrus")
	var ok_hit := await _wait_until_arrival_in(travel)
	_verdict(ok_hit, "am prins fereastra de sub garnitura")
	var hit := await _drive("TREN", 20.0)
	print("    dupa lovitura: pozitie %s, pe sosea %s"
		% [str(hit["pos"].round()), str(hit["on_road"])])
	_verdict(hit["spin"] > 0.0 or hit["max_x"] > 6.0 or hit["air"] > 0.4,
		"garnitura chiar a lovit (spin %.2f, |x| %.2f, aer %.2f)"
		% [hit["spin"], hit["max_x"], hit["air"]])
	# --- verdictul care lipsea: URCAREA, fata de martor -----------------
	# `free_run` a trecut peste ACEEASI grinda cu aceeasi masina si aceeasi
	# viteza, deci `max_y` al lui e cota de rulare, cu tot cu cei 22 cm de
	# grinda. Diferenta e zborul, si nimic altceva.
	var rise: float = hit["max_y"] - free_run["max_y"]
	var want: float = _hazard.throw_height
	print("    URCARE: %.2f m (martor %.2f -> lovita %.2f); throw_height cere %.2f m, prag %.2f"
		% [rise, free_run["max_y"], hit["max_y"], want, maxf(RISE_MIN, want * RISE_FRACTION)])
	_verdict(rise >= RISE_MIN,
		"aruncarea chiar RIDICA masina: %.2f m peste turul de control (prag %.2f)"
		% [rise, RISE_MIN])
	_verdict(rise >= want * RISE_FRACTION,
		"`throw_height` nu e un export mort: %.2f m urcati din %.2f ceruti (%.0f%%)"
		% [rise, want, 100.0 * rise / maxf(want, 0.01)])
	_verdict(hit["air"] >= free_run["air"] + 0.5,
		"aer semnificativ peste martor (%.2f fata de %.2f s)"
		% [hit["air"], free_run["air"]])
	# --- si nu ARUNCATA IN AFARA LUMII ---------------------------------
	var land: Vector3 = hit["pos"]
	_verdict(absf(land.x) <= _hazard.road_half_width + LAND_MARGIN,
		"aterizeaza langa sosea, nu in oras (|x| %.2f <= %.2f)"
		% [absf(land.x), _hazard.road_half_width + LAND_MARGIN])
	_verdict(hit["on_road"], "iese pe sosea dupa zbor")
	_verdict(hit["crush"] <= CRUSH_MAX,
		"nu e distrusa (strivire %.2f <= %.2f)" % [hit["crush"], CRUSH_MAX])
	_verdict(hit["active"], "ramane in cursa (fara race_active stins)")
	_verdict(hit["idx"] > hit["idx0"],
		"isi duce indexul mai departe (%d -> %d)" % [hit["idx0"], hit["idx"]])
	_verdict(hit["t"] < INF,
		"nu ramane intepenita sub garnitura (a terminat in %.2f s)" % hit["t"])
	_verdict(hit["t"] > free_run["t"],
		"lovitura costa timp (%.2f fata de %.2f liber)" % [hit["t"], free_run["t"]])

	await _parked_run()


# ------------------------------------------- (vi) masina OPRITA pe trecere

## Cazul advers al criticului. O masina oprita fix pe trecere e cazul limita:
## aruncarea nu are din ce sa-si ia partea orizontala „a ta", deci tot ce o
## misca e impinsul garniturii. Daca acela e nemasurat, masina pleaca din
## lume — masurat in runda 1: 62.75 m lateral, y = -0.33, v = 0.1 m/s de la
## t=7 pana la t=42, adica salvata doar de plasa de 5 s din `race.gd`.
##
## Verdictul nu e „a fost lovita", ci „poate PLECA de acolo": pe roti, langa
## sosea, si cu gaz plin ajunge iar la viteza de mers.
func _parked_run() -> void:
	print("--- (vi) advers: masina OPRITA fix pe trecere")
	var ok := await _wait_until_arrival_in(3.0)
	_verdict(ok, "am prins fereastra pentru masina parcata")
	var cross := _hazard.crossing_point()
	var car := _spawn(Vector3(cross.x, 0.9, cross.z), 0.0)
	var idle := WaypointDriver.new()
	idle.waypoints = []
	idle.throttle_when_done = 0.0
	car.set_controller(idle)
	# Pana trece garnitura: stationara, fara gaz.
	var hit_t := -1.0
	var t := 0.0
	for _f in int(5.0 * 60.0):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if hit_t < 0.0 and car.crush_time > 0.0:
			hit_t = t
	var thrown := car.global_position
	print("    lovita la %.2f s; dupa 5 s: pozitie %s (deplasare %.2f m), y %.2f, activa %s"
		% [hit_t, str(thrown.round()), thrown.distance_to(cross), thrown.y,
		str(car.race_active)])
	_verdict(hit_t > 0.0, "garnitura a lovit masina parcata (%.2f s)" % hit_t)
	_verdict(absf(thrown.x - cross.x) <= _hazard.road_half_width + LAND_MARGIN,
		"nu e ejectata din lume (|x| %.2f <= %.2f)"
		% [absf(thrown.x - cross.x), _hazard.road_half_width + LAND_MARGIN])
	_verdict(thrown.y > cross.y - 1.0,
		"nu ajunge sub cota soselei (y %.2f)" % thrown.y)
	_verdict(car.race_active, "ramane in cursa")
	# Si acum: poate pleca singura de acolo?
	var driver := WaypointDriver.new()
	driver.waypoints = [Vector3(0.0, 0.0, FINISH_Z - 40.0)]
	driver.target_speed = ENTRY_SPEED
	car.set_controller(driver)
	var best := 0.0
	var moved := 0.0
	var from := car.global_position
	for _f in int(4.0 * 60.0):
		await get_tree().physics_frame
		best = maxf(best, car.horizontal_speed())
		moved = maxf(moved, car.global_position.distance_to(from))
	print("    cu gaz plin, 4 s: viteza max %.2f m/s, %.2f m parcursi, pozitie %s"
		% [best, moved, str(car.global_position.round())])
	_verdict(best > 12.0, "pleaca singura de acolo (viteza max %.2f m/s)" % best)
	_verdict(moved > 25.0, "chiar se misca (%.2f m in 4 s)" % moved)
	car.queue_free()
	await get_tree().physics_frame
