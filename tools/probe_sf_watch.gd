extends Node
## Observatorul traseului San Francisco (Track25, brief san_francisco.md §7 pasul 3), pornit din
## ProbeRace cu `--sf`. Citeste geometria din metadatele scenei (`sf_lips`, `sf_gate_in`,
## `sf_gate_out`), scrise de tools/gen_sf_route.py; pe o scena fara ele nu masoara nimic.
##
## Ce numara:
##   - LANTUL: pe fiecare muchie, viteza la trecerea ei (toate masinile, pe bucla), si fiecare
##     zbor (>= 0,25 s fara `is_on_floor()`) pornit intre 6 m inaintea muchiei si 20 m dupa ea:
##     airtime, viteza la desprindere, unde aterizeaza (metri dupa muchie; blocul are 48 m) si
##     ejectarile din zona lantului (cu cauza si viteza);
##   - SCURTATURA fata de OCOL: timpul dintre aceleasi doua porti (12 m inaintea furcii, 20 m
##     dupa reintalnire), pe ruta pe care a mers masina, si daca a fost repusa intre porti.
##   - zborurile din afara lantului (o creasta neplanificata se vede aici).
##   - TRAMVAIELE (brief §7 pasul 5): intalnirile (tramvaiul vizibil, masina in spatele lui la
##     0-60 m, pe strada lui; se inchide cand masina e cu 8 m in fata centrului lui sau pleaca),
##     viteza minima, partea depasirii, contactele (cu pozitia: coltul de sus al urcarii, gura
##     scurtaturii), trecerile pe urcare (poarta de la baza -> 30 m pe latura de nord) si
##     trecerile furca -> 70 m dupa gura (`sf_gate_out2`), din care raportul scoate pierderea.
##     Steaguri (A/B, sabotaj): `--no-tram` scoate ambele tramvaie, `--tram-only=1|2` doar unul,
##     `--tram-blind` le scoate din grupul AI (sabotajul `ai_reads_lane` stins), toate INAINTE de
##     startul cursei. Raportul: tools/sf_tram_report.py.

const MIN_AIR_S: float = 0.25
const LIP_BEFORE: float = 6.0
const LIP_AFTER: float = 20.0
const CHAIN_HALF: float = 12.0
const GATE_HALF: float = 12.0
const PASS_TIMEOUT: float = 60.0

var _race: Node
var _lips: Array[Vector3] = []
var _gate_in := Vector3.INF
var _gate_out := Vector3.INF
var _t: float = 0.0
var _prev: Array[Vector3] = []
var _air_t: Array[float] = []
var _air_p: Array[Vector3] = []
var _air_v: Array[float] = []
var _air_f: Array[float] = []
var _gate_t: Array[float] = []
var _gate_branch: Array[bool] = []
var _gate_resp: Array[bool] = []
var _lip_v: Array = []           # per muchie: vitezele la trecere
var _flights: Array = []         # [masina, muchie (-1 = in afara lantului), airtime, v0, dist, frac, route]
var _passes: Array = []          # [masina, ruta (0/1), secunde, repusa]
var _ejects: Array = []          # [t, masina, zona, cauza, valoare, poz]
var _resp: Array = []            # [t, masina, zona, poz]
# --- tramvaie ---
const TRAM_APPROACH_M: float = 60.0
const TRAM_PASSED_M: float = 8.0
const TRAM_LAT_M: float = 9.0
var _trams: Array = []           # BusHazard, ordonate dupa nume (Tramvai1, Tramvai2)
var _tram_ids: Array[int] = []   # 1 / 2 (sufixul numelui)
var _enc_open: Array = []        # per masina: per tramvai, indexul intalnirii deschise (-1)
var _encs: Array = []            # dict-uri
var _tram_contacts: Array = []   # [t, masina, tramvai, poz, v, rel_z, tram_dist, ruta]
var _tc_last: Array = []         # per masina: per tramvai, ultimul tick de contact
var _climb_gates: Array = []     # [P_a, D_a, P_b, D_b]
var _gate_out2 := Vector3.INF
var _climb_t: Array[float] = []
var _climb_resp: Array[bool] = []
var _climb_passes: Array = []    # [masina, t_a, secunde, repusa]
var _gate2_t: Array[float] = []
var _gate2_branch: Array[bool] = []
var _gate2_resp: Array[bool] = []
var _passes2: Array = []         # [masina, ruta, t_in, secunde, repusa]
var _tram_d0: Array = []         # distanta pe curba la startul cursei (faza efectiva)


func setup(race: Node) -> void:
	_race = race
	var track: Track = race.track
	if track.has_meta("sf_lips"):
		for L: Vector3 in track.get_meta("sf_lips"):
			_lips.append(L)
			_lip_v.append([])
	if track.has_meta("sf_gate_in"):
		_gate_in = track.get_meta("sf_gate_in")
		_gate_out = track.get_meta("sf_gate_out")
	if track.has_meta("sf_climb_gates"):
		_climb_gates = track.get_meta("sf_climb_gates")
	if track.has_meta("sf_gate_out2"):
		_gate_out2 = track.get_meta("sf_gate_out2")
	_setup_trams(track)
	var cars: Array[Car] = race.cars
	for i in cars.size():
		_climb_t.append(-1.0)
		_climb_resp.append(false)
		_gate2_t.append(-1.0)
		_gate2_branch.append(false)
		_gate2_resp.append(false)
		var eo: Array = []
		var tl: Array = []
		for _j in _trams.size():
			eo.append(-1)
			tl.append(-99.0)
		_enc_open.append(eo)
		_tc_last.append(tl)
		_prev.append(cars[i].global_position)
		_air_t.append(0.0)
		_air_p.append(Vector3.ZERO)
		_air_v.append(0.0)
		_air_f.append(0.0)
		_gate_t.append(-1.0)
		_gate_branch.append(false)
		_gate_resp.append(false)
		cars[i].respawned.connect(_on_respawn.bind(i))
		cars[i].ejected.connect(_on_eject.bind(i))


## Steagurile de A/B si sabotaj (vezi antetul). Inainte de startul cursei.
func _setup_trams(track: Track) -> void:
	var no_tram := false
	var only := 0
	var blind := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--no-tram":
			no_tram = true
		elif arg.begins_with("--tram-only="):
			only = int(arg.trim_prefix("--tram-only="))
		elif arg == "--tram-blind":
			blind = true
		elif arg == "--no-bus-route-reset":
			AIController.bus_reset_on_route = false
			print("=== SF: --no-bus-route-reset (AI-ul nu reciteste tramvaiul la schimbarea rutei)")
	var found: Array = track.find_children("*", "BusHazard", true, false)
	found.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name) < String(b.name))
	for n in found:
		var bus := n as BusHazard
		var id := String(bus.name).trim_prefix("Tramvai").to_int()
		if no_tram or (only > 0 and id != only):
			bus.remove_from_group(BusHazard.AI_GROUP)
			bus.get_parent().remove_child(bus)
			bus.free()
			print("=== SF tramvai %d scos din scena" % id)
			continue
		if blind:
			bus.remove_from_group(BusHazard.AI_GROUP)
			print("=== SF tramvai %d: SABOTAJ, scos din grupul AI (ai_reads_lane stins)" % id)
		_trams.append(bus)
		_tram_ids.append(id)
		_tram_d0.append(-1.0)


func _zone(p: Vector3) -> String:
	if not _lips.is_empty() and absf(p.x - _lips[0].x) < CHAIN_HALF \
			and p.z <= _lips[0].z + 20.0 and p.z >= _lips[_lips.size() - 1].z - 60.0:
		return "lant"
	if _gate_in != Vector3.INF and p.z < _gate_in.z and p.z > _gate_out.z - 10.0 \
			and p.x > -14.0 and p.x < 50.0:
		return "serpentine"
	return "rest"


func _on_respawn(c: Car, i: int) -> void:
	if _gate_t[i] >= 0.0:
		_gate_resp[i] = true
	if _climb_t[i] >= 0.0:
		_climb_resp[i] = true
	if _gate2_t[i] >= 0.0:
		_gate2_resp[i] = true
	_resp.append([_t, i, _zone(_prev[i]), _prev[i]])


func _on_eject(c: Car, _rag: Node3D, i: int) -> void:
	_ejects.append([_t, i, _zone(c.global_position), String(c.last_eject_cause),
		float(c.last_eject_value), c.global_position])


func _lip_of(p: Vector3) -> int:
	for k in _lips.size():
		var L := _lips[k]
		if absf(p.x - L.x) < CHAIN_HALF and p.z <= L.z + LIP_BEFORE and p.z >= L.z - LIP_AFTER:
			return k
	return -1


func _physics_process(delta: float) -> void:
	if _race == null or _race.state != Race.State.RUNNING:
		return
	_t += delta
	for j in _trams.size():
		if float(_tram_d0[j]) < 0.0:
			_tram_d0[j] = (_trams[j] as BusHazard).distance()
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var c := cars[i]
		var p := c.global_position
		var q := _prev[i]
		_prev[i] = p
		_tick_trams(i, c)
		if q.distance_to(p) > 8.0:
			continue          # repunere: nu e trecere
		_tick_tram_gates(i, c, p, q)
		if c.route == 0:
			for k in _lips.size():
				var L := _lips[k]
				if absf(p.x - L.x) < CHAIN_HALF and q.z > L.z and p.z <= L.z:
					(_lip_v[k] as Array).append(c.horizontal_speed())
		if c.is_on_floor():
			if _air_t[i] >= MIN_AIR_S:
				var k := _lip_of(_air_p[i])
				var dist := (_lips[k].z - p.z) if k >= 0 else -1.0
				_flights.append([i, k, _air_t[i], _air_v[i], dist, _air_f[i], c.route])
			_air_t[i] = 0.0
		else:
			if _air_t[i] == 0.0:
				_air_p[i] = p
				_air_v[i] = c.horizontal_speed()
				_air_f[i] = _race.track.frac_at(c.road_index, c.route)
			_air_t[i] += delta
		if _gate_in != Vector3.INF:
			if absf(p.x - _gate_in.x) < GATE_HALF and q.z > _gate_in.z and p.z <= _gate_in.z:
				_gate_t[i] = _t
				_gate_branch[i] = false
				_gate_resp[i] = false
			if _gate_t[i] >= 0.0:
				if c.route == 1:
					_gate_branch[i] = true
				if absf(p.z - _gate_out.z) < GATE_HALF and q.x < _gate_out.x and p.x >= _gate_out.x:
					_passes.append([i, 1 if _gate_branch[i] else 0, _t - _gate_t[i], _gate_resp[i]])
					_gate_t[i] = -1.0
				elif _t - _gate_t[i] > PASS_TIMEOUT:
					_passes.append([i, 1 if _gate_branch[i] else 0, -1.0, _gate_resp[i]])
					_gate_t[i] = -1.0


static func _crossed(p: Vector3, q: Vector3, at: Vector3, dir: Vector3) -> bool:
	if (q - at).dot(dir) >= 0.0 or (p - at).dot(dir) < 0.0:
		return false
	var side := Vector3(-dir.z, 0.0, dir.x)
	return absf((p - at).dot(side)) < GATE_HALF


## Portile tramvaielor: urcarea (B0 -> latura de nord) si furca -> 70 m dupa gura.
func _tick_tram_gates(i: int, c: Car, p: Vector3, q: Vector3) -> void:
	if _climb_gates.size() == 4:
		if _crossed(p, q, _climb_gates[0], _climb_gates[1]):
			_climb_t[i] = _t
			_climb_resp[i] = false
		elif _climb_t[i] >= 0.0:
			if _crossed(p, q, _climb_gates[2], _climb_gates[3]):
				_climb_passes.append([i, _climb_t[i], _t - _climb_t[i], _climb_resp[i]])
				_climb_t[i] = -1.0
			elif _t - _climb_t[i] > PASS_TIMEOUT:
				_climb_passes.append([i, _climb_t[i], -1.0, _climb_resp[i]])
				_climb_t[i] = -1.0
	if _gate_in != Vector3.INF and _gate_out2 != Vector3.INF:
		if absf(p.x - _gate_in.x) < GATE_HALF and q.z > _gate_in.z and p.z <= _gate_in.z:
			_gate2_t[i] = _t
			_gate2_branch[i] = false
			_gate2_resp[i] = false
		if _gate2_t[i] >= 0.0:
			if c.route == 1:
				_gate2_branch[i] = true
			if absf(p.z - _gate_out2.z) < GATE_HALF and q.x < _gate_out2.x and p.x >= _gate_out2.x:
				_passes2.append([i, 1 if _gate2_branch[i] else 0, _gate2_t[i], _t - _gate2_t[i],
					_gate2_resp[i]])
				_gate2_t[i] = -1.0
			elif _t - _gate2_t[i] > PASS_TIMEOUT:
				_passes2.append([i, 1 if _gate2_branch[i] else 0, _gate2_t[i], -1.0, _gate2_resp[i]])
				_gate2_t[i] = -1.0


## Intalnirile si contactele cu tramvaiele (definitia sondei 1c / ProbeCarrara, in coordonatele
## TRAMVAIULUI: inainte = botul lui, lateral + = dreapta lui).
func _tick_trams(i: int, c: Car) -> void:
	if _trams.is_empty():
		return
	var hit := -1
	for b in c.get_colliding_bodies():
		var par: Node = (b as Node).get_parent() if b is Node else null
		if par is BusHazard:
			hit = _trams.find(par)
	var p := c.global_position
	var v := c.horizontal_speed()
	for j in _trams.size():
		var tr: BusHazard = _trams[j]
		var eo: Array = _enc_open[i]
		var open := int(eo[j])
		if hit == j:
			var tl: Array = _tc_last[i]
			if _t - float(tl[j]) > 0.5:
				var rel: Vector3 = tr._body.global_transform.affine_inverse() * p
				_tram_contacts.append([_t, i, _tram_ids[j], p, v, rel.z, tr.distance(), c.route])
				if open >= 0:
					(_encs[open] as Dictionary).contact = true
			tl[j] = _t
		if tr.is_hidden():
			if open >= 0:
				_close_enc(i, j, "ascuns")
			continue
		var tp := tr.body_position()
		var fwd := tr.body_forward()
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		var rel2 := p - tp
		var ahead := -rel2.dot(fwd)          # cat e tramvaiul IN FATA masinii
		var lat := rel2.dot(right)
		var same := absf(lat) < TRAM_LAT_M and absf(rel2.y) < 5.0
		if open < 0:
			if same and ahead > 0.0 and ahead < TRAM_APPROACH_M:
				_encs.append({"tram": _tram_ids[j], "car": i, "t_in": _t, "v_in": v, "v_min": v,
					"contact": hit == j, "lat_pass": lat, "d_min": absf(ahead), "route": c.route,
					"t_out": -1.0, "reason": "", "tram_d_in": tr.distance()})
				eo[j] = _encs.size() - 1
			continue
		var e: Dictionary = _encs[open]
		e.v_min = minf(float(e.v_min), v)
		if hit == j:
			e.contact = true
		if absf(ahead) < float(e.d_min):
			e.d_min = absf(ahead)
			e.lat_pass = lat
		if ahead < -TRAM_PASSED_M:
			_close_enc(i, j, "depasit")
		elif not same or ahead > TRAM_APPROACH_M + 10.0:
			_close_enc(i, j, "plecat")


func _close_enc(i: int, j: int, reason: String) -> void:
	var eo: Array = _enc_open[i]
	var e: Dictionary = _encs[int(eo[j])]
	e.t_out = _t
	e.reason = reason
	eo[j] = -1


static func _med(a: Array) -> float:
	if a.is_empty():
		return -1.0
	var b := a.duplicate()
	b.sort()
	return float(b[b.size() / 2])


func report() -> void:
	var cars: Array[Car] = _race.cars
	print("=== SF lant: %d muchii" % _lips.size())
	for k in _lips.size():
		var vs: Array = _lip_v[k]
		var air: Array = []
		var v0: Array = []
		var dist: Array = []
		var beyond := 0
		for f in _flights:
			if int(f[1]) == k:
				air.append(float(f[2]))
				v0.append(float(f[3]))
				dist.append(float(f[4]))
				if float(f[4]) > 48.0:
					beyond += 1
		var vmin := -1.0 if vs.is_empty() else float(vs.min())
		print("=== SF muchia %d: treceri=%d v_med=%.1f v_min=%.1f m/s | zboruri=%d airtime med=%.2f min=%.2f max=%.2f s | v0 med=%.1f | aterizare med=%.0f max=%.0f m dupa muchie, dincolo de bloc (>48 m)=%d" % [
			k + 1, vs.size(), _med(vs), vmin, air.size(), _med(air),
			-1.0 if air.is_empty() else float(air.min()),
			-1.0 if air.is_empty() else float(air.max()), _med(v0), _med(dist),
			-1.0 if dist.is_empty() else float(dist.max()), beyond])
	# brute, pentru agregarea pe seed-uri (tools/sf_route_report.py)
	for k in _lips.size():
		print("    [sf muchie] %d v=%s" % [k + 1, ",".join((_lip_v[k] as Array).map(
			func(x: float) -> String: return "%.1f" % x))])
	for f in _flights:
		if int(f[1]) >= 0:
			print("    [sf zbor] %d %s air=%.3f v0=%.1f dist=%.1f" % [int(f[1]) + 1,
				cars[int(f[0])].car_name,
				float(f[2]), float(f[3]), float(f[4])])
	var other := 0
	for f in _flights:
		if int(f[1]) < 0:
			other += 1
			print("    [zbor in afara lantului] %-18s ruta=%d frac=%.3f %.2fs v0=%.1f" % [
				cars[int(f[0])].pilot_name, int(f[6]), float(f[5]), float(f[2]), float(f[3])])
	print("=== SF zboruri in afara lantului: %d" % other)
	for e in _ejects:
		var p: Vector3 = e[5]
		print("    [sf ejectare] t=%5.1fs %-18s zona=%s %s %.1f poz=(%.0f,%.1f,%.0f)" % [
			float(e[0]), cars[int(e[1])].pilot_name, String(e[2]), String(e[3]), float(e[4]),
			p.x, p.y, p.z])
	for r in _resp:
		var p2: Vector3 = r[3]
		print("    [sf repunere] t=%5.1fs %-18s zona=%s poz=(%.0f,%.1f,%.0f)" % [
			float(r[0]), cars[int(r[1])].pilot_name, String(r[2]), p2.x, p2.y, p2.z])
	for route in [0, 1]:
		var ts: Array = []
		var resp := 0
		var unfinished := 0
		var total := 0
		for ps in _passes:
			if int(ps[1]) != route:
				continue
			total += 1
			if bool(ps[3]):
				resp += 1
			if float(ps[2]) < 0.0:
				unfinished += 1
			elif not bool(ps[3]):
				ts.append(float(ps[2]))
		print("=== SF ruta %d (%s): treceri=%d curate=%d repuse=%d neterminate=%d timp med=%.2f min=%.2f s" % [
			route, "ocol" if route == 0 else "scurtatura", total,
			ts.size(), resp, unfinished, _med(ts), -1.0 if ts.is_empty() else float(ts.min())])
	for ps in _passes:
		print("    [sf poarta] %-18s ruta=%d %.2fs%s" % [cars[int(ps[0])].pilot_name, int(ps[1]),
			float(ps[2]), " REPUSA" if bool(ps[3]) else ""])
	_report_trams()


## Brute pentru tools/sf_tram_report.py (cheia masinii = car_name: lineup-ul difera pe seed).
func _report_trams() -> void:
	var cars: Array[Car] = _race.cars
	for j in _trams.size():
		var tr: BusHazard = _trams[j]
		print("=== SF tramvai %d: curba %.0f m, %.1f m/s, ciclu %.1f s, faza %.3f; la verde la %.1f m pe curba" % [
			_tram_ids[j], tr.curve.get_baked_length(), tr.speed, tr.period, tr.phase,
			float(_tram_d0[j])])
	var n_enc := 0
	var n_hit := 0
	for e: Dictionary in _encs:
		if float(e.t_out) < 0.0:
			continue
		n_enc += 1
		if bool(e.contact):
			n_hit += 1
		print("    [sf tram enc] %d %s r=%d t=%.2f..%.2f v_in=%.1f v_min=%.1f lat=%.2f contact=%d %s" % [
			int(e.tram), cars[int(e.car)].car_name, int(e.route), float(e.t_in), float(e.t_out),
			float(e.v_in), float(e.v_min), float(e.lat_pass), 1 if bool(e.contact) else 0,
			String(e.reason)])
	for ct in _tram_contacts:
		var p: Vector3 = ct[3]
		print("    [sf tram contact] %d %s r=%d t=%.2f v=%.1f rel_z=%.2f tram_d=%.1f poz=(%.1f,%.1f,%.1f)" % [
			int(ct[2]), cars[int(ct[1])].car_name, int(ct[7]), float(ct[0]), float(ct[4]),
			float(ct[5]), float(ct[6]), p.x, p.y, p.z])
	for cp in _climb_passes:
		print("    [sf urcare] %s t=%.2f %.2fs%s" % [cars[int(cp[0])].car_name, float(cp[1]),
			float(cp[2]), " REPUSA" if bool(cp[3]) else ""])
	for ps in _passes2:
		print("    [sf poarta2] %s ruta=%d t=%.2f %.2fs%s" % [cars[int(ps[0])].car_name, int(ps[1]),
			float(ps[2]), float(ps[3]), " REPUSA" if bool(ps[4]) else ""])
	print("=== SF tramvaie: %d intalniri, %d cu contact, %d contacte" % [n_enc, n_hit,
		_tram_contacts.size()])
