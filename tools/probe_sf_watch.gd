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
	var cars: Array[Car] = race.cars
	for i in cars.size():
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
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var c := cars[i]
		var p := c.global_position
		var q := _prev[i]
		_prev[i] = p
		if q.distance_to(p) > 8.0:
			continue          # repunere: nu e trecere
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
