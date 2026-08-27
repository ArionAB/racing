extends Node
## Sonda macaralei (Chongqing, brief §2 POI F si §3): leagana prefabricatul
## peste rampa de sus pe un ciclu propriu, si contactul te INVARTE — nu te
## distruge, nu te opreste, nu te scoate din cursa.
##
## Pista-test: aceeasi bucla-stadion ca la pasajul rotativ, cu dreapta de est
## pe x = 0 si sensul de mers -Z. Macaraua sta pe marginea drumului (turnul la
## 7 m de axa), iar sarcina traverseaza soseaua de doua ori pe rotatie.
##
## Sonda nu asteapta sa se nimereasca impactul: cere hazardului unde si cand
## trece sarcina peste axa (`crossings()`) si LANSEAZA masina de la distanta
## potrivita, ca sa ajunga acolo exact atunci. Fara asta, „contact = invartit"
## ar fi un verdict care trece fiindca n-a atins nimic.
##
##  (0)   ciclul: o rotatie completa a brațului dureaza `period` (20 s), si e
##        in fereastra ceruta de brief (18-22 s).
##  (i)   telegraph: lampa de avertizare se aprinde cu `telegraph_lead` (3 s)
##        inainte de fiecare trecere peste axa.
##  (ii)  geometria: turnul NU e pe carosabil, iar sarcina trece destul de jos
##        cat sa loveasca o masina (sub inaltimea caroseriei).
##  (iii) LOVITURA: masina trimisa in sarcina chiar e atinsa, si efectul e
##        invartire (spin vizual) + ghiont. NU: distrugere (strivire lunga),
##        NU iesire din cursa, NU repunere, NU oprire definitiva.
##  (iv)  dupa lovitura masina isi pastreaza indexul de pista, il duce mai
##        departe si ramane pe sosea — adica pierde linia, nu turul.
##  (v)   fereastra: o masina trimisa cand sarcina e departe trece neatinsa.
##        Macaraua e o panda, nu un zid.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCrane.tscn
## Iese cu cod 1 la orice verdict picat.

const CraneScript := preload("res://scenes/hazards/crane_hazard.gd")
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
const ENTRY_SPEED: float = 22.0
## Fereastra de lansare: cat de departe in timp trebuie sa fie trecerea ca sa
## merite sa pornim masina spre ea.
const LAUNCH_MIN: float = 2.5
const LAUNCH_MAX: float = 5.0
## Peste atata strivire, „invartit" a devenit „distrus".
const CRUSH_MAX: float = 0.9
## Sub atata viteza dupa lovitura, hazardul e un zid, nu o maturare.
const MIN_SPEED_AFTER: float = 4.0
## Cat din viteza dinaintea contactului trebuie sa ramana in secunda de dupa.
##
## Verdictul care lipsea in runda 1: „viteza finala 28.37" era masurata la
## t=14, dupa noua secunde de reaccelerare, deci trecea si cu un PERETE in
## mijloc. Criticul a masurat ce ascundea: 22.0 -> 1.1 m/s la impact, adica
## 5%. Un prefabricat care te matura iti ia un sfert din viteza; unul care te
## zideste ti-o ia pe toata, si diferenta se vede doar aici.
const KEEP_MIN: float = 0.45
## Cat tine fereastra in care se masoara impactul (s). Vezi nota din `_hit_run`.
const IMPACT_WINDOW: float = 0.5
## Cat din `lift_rise` trebuie sa se si vada in urcarea masurata (restul il
## mananca amortizorul suspensiei in cadrele de dupa lansare).
const RISE_FRACTION: float = 0.4

var _track: TrackFromPath
var _hazard: CraneScript
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
	_track.custom_name = "ProbeCrane"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame

	_hazard = CraneScript.new()
	_hazard.name = "Crane"
	_hazard.tower_side = 1
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== MACARAUA: ciclu, telegraph, contact = invartit ===")
	print("  period %.1f s, telegraph %.1f s, brat %.1f m, turn la %.1f m, garda %.2f m"
		% [_hazard.period, _hazard.telegraph_lead, _hazard.hook_radius,
		_hazard.tower_offset, _hazard.load_clearance])
	for c in _hazard.crossings():
		print("    trecere peste axa la z=%+6.2f (unghi %.2f rad)"
			% [c["z"], c["angle"]])
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


# ------------------------------------------------------------------ ceasuri

func _measure_cycle() -> void:
	print("--- (0)+(i) rotatia si telegraph-ul")
	var t := 0.0
	var prev := _hazard.jib_angle()
	var laps: Array[float] = []
	var t_lap := -1.0
	var lamp_since := -1.0
	var leads: Array[float] = []
	var was_lamp := false
	var prev_to := _hazard.seconds_to_crossing()
	for _f in int(_hazard.period * 2.4 * 60.0):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var a := _hazard.jib_angle()
		if a < prev: # brațul a trecut prin 0: o rotatie completa
			if t_lap > 0.0:
				laps.append(t - t_lap)
			t_lap = t
		prev = a
		var lamp := _hazard.warning()
		# Lampa CLIPESTE, deci are un front crescator la fiecare 0.4 s. Ne
		# trebuie inceputul avertizarii, nu ultima clipire: primul front dupa
		# ce a fost stinsa, adica primul de dupa resetarea de la trecerea
		# precedenta. (Fara asta sonda raporta un telegraph de 0.2 s pentru o
		# avertizare care tinea 3.)
		if lamp and not was_lamp and lamp_since < 0.0:
			lamp_since = t
		was_lamp = lamp
		# Momentul trecerii: `seconds_to_crossing` cade spre 0 si apoi sare
		# inapoi sus, cand tinta devine urmatoarea trecere.
		var to_cross := _hazard.seconds_to_crossing()
		if to_cross > prev_to + 1.0 and lamp_since > 0.0:
			leads.append(t - lamp_since)
			lamp_since = -1.0
		prev_to = to_cross
	print("    rotatii complete: %s s" % str(laps))
	print("    lampa se aprinde cu %s s inainte de trecere" % str(leads))
	var lap: float = laps[0] if laps.size() > 0 else 0.0
	_verdict(absf(lap - _hazard.period) < 0.3,
		"o rotatie dureaza %.2f s (cerut %.1f)" % [lap, _hazard.period])
	_verdict(_hazard.period >= 18.0 and _hazard.period <= 22.0,
		"ciclul e in fereastra din brief 18-22 s (%.1f)" % _hazard.period)
	# Prima masuratoare se arunca: sonda porneste la un moment oarecare din
	# ciclu, iar daca prinde avertizarea deja inceputa, masoara cat a mai
	# ramas din ea, nu cat tine. Restul trebuie sa fie toate 3 s.
	var lead_ok := leads.size() >= 3
	for i in range(1, leads.size()):
		if absf(leads[i] - _hazard.telegraph_lead) > 0.35:
			lead_ok = false
	_verdict(lead_ok, "lampa precede fiecare trecere cu %.1f s (masurat %s)"
		% [_hazard.telegraph_lead, str(leads.slice(1))])


func _measure_geometry() -> void:
	print("--- (ii) geometria: turnul langa drum, sarcina destul de jos")
	var clear := _hazard.tower_offset - CraneScript.MAST_SIDE * 0.5 \
		- _hazard.road_half_width
	_verdict(clear > 0.0,
		"turnul nu e pe carosabil (marginea lui la %+.2f m de buza)" % clear)
	var lowest := INF
	var over := 0.0
	for _f in int(_hazard.period * 60.0):
		await get_tree().physics_frame
		if absf(_hazard.load_offset()) < _hazard.road_half_width:
			lowest = minf(lowest, _hazard.load_bottom())
			over += 1.0 / 60.0
	print("    sarcina e peste asfalt %.2f s pe rotatie; cota minima %.2f m"
		% [over, lowest])
	_verdict(lowest < 1.1,
		"sarcina trece sub inaltimea caroseriei (%.2f m < 1.10)" % lowest)
	_verdict(over > 0.5 and over < _hazard.period * 0.5,
		"e o fereastra, nu un zid: %.2f s din %.1f" % [over, _hazard.period])


# ------------------------------------------------------------------ lovitura

## Asteapta pana cand trecerea de pe partea ceruta e la LAUNCH_MIN..LAUNCH_MAX
## secunde, apoi intoarce (z-ul trecerii, secundele pana la ea).
func _wait_launch(want_z_positive: bool) -> Array[float]:
	for _f in int(_hazard.period * 3.0 * 60.0):
		await get_tree().physics_frame
		for c in _hazard.crossings():
			var z: float = c["z"]
			if (z > 0.0) != want_z_positive:
				continue
			var s: float = c["seconds"]
			if s >= LAUNCH_MIN and s <= LAUNCH_MAX:
				return [z, s]
	return []


func _hit_run() -> void:
	print("--- (iii)+(iv) lovitura: invartit, nu distrus")
	var launch := await _wait_launch(true)
	_verdict(not launch.is_empty(), "am prins fereastra de lansare")
	if launch.is_empty():
		return
	var z_cross: float = launch[0]
	var wait: float = launch[1]
	var start_z := z_cross + ENTRY_SPEED * wait
	print("    trecere la z=%+.2f peste %.2f s -> lansare de la z=%+.2f cu %.1f m/s"
		% [z_cross, wait, start_z, ENTRY_SPEED])
	var car := _spawn(Vector3(0.0, 0.7, start_z), ENTRY_SPEED)
	var driver := WaypointDriver.new()
	driver.waypoints = [Vector3(0.0, 0.0, z_cross - 60.0),
		Vector3(0.0, 0.0, z_cross - 120.0)]
	driver.target_speed = ENTRY_SPEED
	car.set_controller(driver)

	var idx0 := car.road_index
	var pos0 := car.global_position
	var spin_seen := 0.0
	var crush_seen := 0.0
	var lateral := 0.0
	var touched := false
	var t := 0.0
	var t_touch := -1.0
	# Cifrele care despart „maturat" de „zidit": viteza chiar inainte de
	# contact, viteza minima din secunda de DUPA el, si urcarea peste cota de
	# RULARE de dinainte.
	#
	# Amandoua se iau dintr-o fereastra de o secunda TINUTA IN URMA, nu din
	# cadrul curent: cand `spin` devine pozitiv, hazardul si-a aplicat deja
	# lovitura in cadrul ala, deci viteza „de dinainte" citita atunci e cea de
	# dupa (masurat: 13.47 in loc de 22.0). Iar cota de rulare nu se poate lua
	# ca maxim de la pornire — masina e lansata de la y = 0.7 si se aseaza,
	# deci maximul ala e inaltimea de spawn (0.69), nu drumul.
	var hist_v: Array[float] = []
	var hist_y: Array[float] = []
	var v_before := 0.0
	var v_after := INF
	var y_roll := 0.0
	var y_air := -INF
	while t < 14.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var spin: float = car.get("_spin_left")
		spin_seen = maxf(spin_seen, spin)
		crush_seen = maxf(crush_seen, car.crush_time)
		if spin > 0.0 and not touched:
			touched = true
			t_touch = t
			v_before = hist_v[0] if hist_v.size() > 0 else car.horizontal_speed()
			for y in hist_y:
				y_roll = maxf(y_roll, y)
		if not touched:
			# Coada de o secunda: [0] e cel mai vechi cadru din ea.
			hist_v.append(car.horizontal_speed())
			hist_y.append(car.global_position.y)
			if hist_v.size() > 60:
				hist_v.pop_front()
				hist_y.pop_front()
		else:
			lateral = maxf(lateral, absf(car.global_position.x))
			y_air = maxf(y_air, car.global_position.y)
			# Fereastra de IMPACT e o jumatate de secunda, si e o alegere, nu o
			# comoditate: la +0.50 s masina e iar pe patru roti, iar ce se
			# masoara dupa aia e soferul care se intoarce pe linie (traseul
			# arata dipul de la +1.00 s si revenirea la +1.50 s). Verdictul
			# trebuie sa fie despre hazard.
			if t - t_touch <= IMPACT_WINDOW:
				v_after = minf(v_after, car.horizontal_speed())
			if int(round((t - t_touch) * 60.0)) in [3, 6, 12, 21, 30, 60, 90]:
				print("      +%.2f s: v %.2f, y %.2f, rotile %d"
					% [t - t_touch, car.horizontal_speed(),
					car.global_position.y, car.wheels_on_ground])
		if int(round(t * 60.0)) % 60 == 0:
			print("    t=%5.2f pos %s v=%5.1f spin %.2f crush %.2f index %d"
				% [t, str(car.global_position.round()), car.horizontal_speed(),
				spin, car.crush_time, car.road_index])
	print("--- lovitura la %.2f s; spin max %.2f s, strivire max %.2f s, deviere laterala %.2f m"
		% [t_touch, spin_seen, crush_seen, lateral])
	print("    dupa lovitura: viteza finala %.2f; index %d -> %d; activa %s; pozitie %s"
		% [car.horizontal_speed(), idx0, car.road_index, str(car.race_active),
		str(car.global_position.round())])
	_verdict(touched, "sarcina chiar a atins masina (spin pornit la %.2f s)" % t_touch)
	_verdict(spin_seen > 0.0, "efectul e invartire (spin %.2f s)" % spin_seen)
	_verdict(crush_seen <= CRUSH_MAX,
		"nu e distrusa (strivire %.2f s <= %.2f)" % [crush_seen, CRUSH_MAX])
	_verdict(car.race_active, "ramane in cursa")
	_verdict(car.global_position.distance_to(pos0) > 40.0,
		"nu a fost repusa pe loc (a parcurs %.1f m)"
		% car.global_position.distance_to(pos0))
	_verdict(car.horizontal_speed() > MIN_SPEED_AFTER,
		"nu e oprita de sarcina (viteza finala %.2f m/s)" % car.horizontal_speed())
	# --- nu e un PERETE: cifra se ia la impact, nu dupa reaccelerare ------
	var kept := v_after / maxf(v_before, 0.01)
	print("    la IMPACT: %.2f -> %.2f m/s in %.2f s (%.0f%% pastrat, prag %.0f%%)"
		% [v_before, v_after, IMPACT_WINDOW, 100.0 * kept, 100.0 * KEEP_MIN])
	_verdict(kept >= KEEP_MIN,
		"sarcina MATURA, nu zideste (%.0f%% din viteza pastrat la impact)"
		% (100.0 * kept))
	# --- si `lift_rise` chiar ridica -------------------------------------
	var rise := y_air - y_roll
	print("    URCARE: %.2f m (rulare %.2f -> varf %.2f); lift_rise cere %.2f m"
		% [rise, y_roll, y_air, _hazard.lift_rise])
	_verdict(rise >= _hazard.lift_rise * RISE_FRACTION,
		"`lift_rise` nu e un export mort: %.2f m din %.2f ceruti"
		% [rise, _hazard.lift_rise])
	_verdict(car.road_index > idx0,
		"isi duce indexul mai departe (%d -> %d)" % [idx0, car.road_index])
	_verdict(_track.is_on_road(car.road_index, car.global_position, 0),
		"e tot pe sosea dupa lovitura")
	car.queue_free()
	await get_tree().physics_frame


func _clean_run() -> void:
	print("--- (v) fereastra libera: cine trece la timp nu pateste nimic")
	var target_z := 0.0
	for c in _hazard.crossings():
		if c["z"] > 0.0:
			target_z = c["z"]
	var travel := 4.0
	var launched := false
	var car: Car = null
	for _f in int(_hazard.period * 3.0 * 60.0):
		await get_tree().physics_frame
		var soonest := INF
		for c in _hazard.crossings():
			soonest = minf(soonest, c["seconds"])
		# Vrem ca dupa `travel` secunde (cat ii ia masinii sa ajunga la punctul
		# de trecere) sarcina sa fie inca departe de el.
		if soonest > travel + 4.0 and soonest < _hazard.period * 0.75:
			car = _spawn(Vector3(0.0, 0.7, target_z + ENTRY_SPEED * travel),
				ENTRY_SPEED)
			var d := WaypointDriver.new()
			d.waypoints = [Vector3(0.0, 0.0, target_z - 60.0)]
			d.target_speed = ENTRY_SPEED
			car.set_controller(d)
			launched = true
			break
	_verdict(launched, "am prins fereastra libera")
	if not launched:
		return
	var spin := 0.0
	var crush := 0.0
	for _f in int(6.0 * 60.0):
		await get_tree().physics_frame
		spin = maxf(spin, car.get("_spin_left"))
		crush = maxf(crush, car.crush_time)
	print("    dupa 6 s: pozitie %s, viteza %.2f, spin %.2f, strivire %.2f"
		% [str(car.global_position.round()), car.horizontal_speed(), spin, crush])
	_verdict(spin <= 0.0 and crush <= 0.01,
		"trecere curata (spin %.2f, strivire %.2f)" % [spin, crush])
	car.queue_free()
	await get_tree().physics_frame


func _run() -> void:
	await _measure_cycle()
	await _measure_geometry()
	await _hit_run()
	await _clean_run()
