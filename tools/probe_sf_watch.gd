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
##   - PODUL ROSU (Track25 B200, brief §7 pasul 2b): daca pista are un `MovableMedianHazard`, fiecare
##     TRECERE prin coridorul cu doua sensuri (capul despartitorului -> capul celalalt): contactele cu
##     bariera / cu camionul / cu atenuatoarele de la capete, trecerile peste despartitor (centrul
##     masinii pe partea gresita a barierei de ACUM, ca la sonda 1d), cat din trecere banda a fost
##     ingusta (< 10 m), intalnirea cu camionul (pe latura proprie, 30 m in spatele lui) si coada (sub
##     10 m/s acolo); ciocnirile FRONTALE intre masini de sensuri opuse (in coridor si oriunde).
##     Steaguri: `--median-blind` scoate hazardul din grupul AI (SABOTAJ: `ai_reads_corridor` stins),
##     `--median-static` il face sa citeasca bariera de la t = 0, `--median-fix` il ingheata la axa
##     fara camion (A/B-ul cu despartitorul clasic). Raportul: tools/sf_route_report.py.
##   - PASUL 6 (brief §7 pasul 6): PONTONUL (`metadata/sf_ponton`): trecerile pe el si caderile in
##     golf (repunerile cu masina sub cota cheiului, langa ponton); MASINILE PARCATE (grupul
##     `sf_parked_bodies`): fiecare piesa urnita de la locul ei (cine era langa ea, cu ce viteza),
##     cat sta pe carosabil, cat din timpul asta in zona de aterizare a unei muchii (primii 45 m),
##     si zborurile / ejectarile care aterizeaza la < 8 m de o piesa urnita (resturile strica
##     aterizarea urmatorilor?).
##   - VALUL 2: trecerile masinilor PRIN volumul stalpilor si trunchiurilor fara coliziune
##     (`metadata/sf_poles`: semafoare, felinare, arbori de strada) si mobilierul mic BumpProp (grupul
##     `sf_street_bodies`): urnite, secunde pe carosabil, din care in zona de aterizare.
##     PASUL 8d: cand stalpii au coliziune (cilindrul `trunk` al WorldProp), CONTACTELE reale cu el
##     (`get_colliding_bodies`), pe familie si pe stalp, cu viteza la contact, daca masina era in zbor,
##     si ce s-a intamplat in urmatoarele 4 s (repusa / ejectata / viteza minima). Linia de volum ramane
##     (cu stalpi solizi ea numara atingerile, nu trecerile).
##   - VALUL 3: contactele cu corpurile noi (casele pictate `CasePictateCorpuri`, placa turnanta
##     `PlacaCorpuri` = gheretă + vagonul parcat, magaziile de chei `MagaziiCorpuri`), pe acelasi
##     tipar ca la case (un contact = o masina care atinge corpul, cu cel putin 1 s intre doua).

const MIN_AIR_S: float = 0.25
# --- pasul 6: pontonul si masinile parcate ---
const PONT_LAT_M: float = 14.0
const PARK_MOVED_M: float = 0.4
const PARK_NEAR_M: float = 8.0
var _pont := PackedVector3Array()
var _pont_in: Array[bool] = []
var _pont_pass: int = 0
var _pont_falls: Array = []      # [t, masina, poz]
var _parked: Array[RigidBody3D] = []
var _park_home: Array[Vector3] = []
var _park_tag: Array[String] = []
var _park_axis: Array[float] = []
var _park_moved: Array[bool] = []
var _park_hits: Array = []       # [t, tag, masina (-1 = niciuna aproape), v masinii, eticheta]
var _park_road_s: float = 0.0    # secunde-piesa pe carosabil (urnite)
var _park_land_s: float = 0.0    # din care in zona de aterizare a unei muchii
var _park_land_near: int = 0     # zboruri cu aterizarea la < 8 m de o piesa urnita
var _park_eject_near: int = 0
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
## Pasul 6: in trecerea furca -> gura, masina a atins blocul solid al unui ac (`SerpStraturi`) /
## o fatada (`SerpFatade`)? Contractul „o bordura atinsa pierde ~1 s fata de ocol”.
var _gate_bed: Array[bool] = []
var _gate_wall: Array[bool] = []
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
# --- podul ---
const POD_NARROW_M: float = 10.0
const POD_TRUCK_NEAR_M: float = 30.0
const POD_GAP_S: float = 0.5
var _podm: MovableMedianHazard = null
var _pod_open: Array[int] = []           # per masina: indexul trecerii deschise (-1)
var _pod_wrong: Array[bool] = []
var _pod_bl: Array[float] = []           # ultimul contact cu bariera / camionul / atenuatorul
var _pod_tl: Array[float] = []
var _pod_cl: Array[float] = []
var _pod_passes: Array = []              # dict-uri
var _pod_cross: Array = []               # [t, masina, s, z, offset, v]
var _pod_headon: Array = []              # [t, a, b, s, z, in_corridor]
var _pod_headon_last: Dictionary = {}
var _pod_outside: Array[int] = [0, 0, 0] # contacte bariera / camion / atenuator FARA trecere deschisa


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
	_setup_pod(track)
	if track.has_meta("sf_ponton"):
		_pont = PackedVector3Array(track.get_meta("sf_ponton"))
	_setup_poles(track)
	var cars: Array[Car] = race.cars
	for i in cars.size():
		_pod_open.append(-1)
		_pod_wrong.append(false)
		_pod_bl.append(-99.0)
		_pod_tl.append(-99.0)
		_pod_cl.append(-99.0)
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
		_pont_in.append(false)
		_air_t.append(0.0)
		_air_p.append(Vector3.ZERO)
		_air_v.append(0.0)
		_air_f.append(0.0)
		_gate_t.append(-1.0)
		_gate_branch.append(false)
		_gate_resp.append(false)
		_gate_bed.append(false)
		_gate_wall.append(false)
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


## Podul: hazardul si sabotajele lui (inainte de startul cursei).
func _setup_pod(track: Track) -> void:
	for n in track.find_children("*", "MovableMedianHazard", true, false):
		_podm = n as MovableMedianHazard
	if _podm == null:
		return
	for arg in OS.get_cmdline_user_args():
		if arg == "--median-blind":
			_podm.ai_reads_corridor = false
			_podm.remove_from_group(MovableMedianHazard.AI_GROUP)
			print("=== SF pod: SABOTAJ, despartitorul scos din grupul AI (ai_reads_corridor stins)")
		elif arg == "--median-static":
			_podm.ai_static_read = true
			print("=== SF pod: SABOTAJ, AI-ul citeste bariera de la t = 0")
		elif arg == "--median-fix":
			# A/B: despartitorul FIX la axa, fara camion (ca SondaSfPodFix), fara sa regeneram scena:
			# blocurile se pun la offset 0, camionul dispare.
			_podm.static_center = true
			_podm.truck_enabled = false
			var tb := _podm.truck_body()
			if tb != null:
				tb.get_parent().remove_child(tb)
				tb.free()
				_podm.set("_truck", null)
			for k in int(_podm.call("_block_count")):
				_podm.call("_place_block", k, (float(k) + 0.5) * _podm.block_len, 0.0, true)
			print("=== SF pod: A/B, despartitor FIX la axa, fara camion")
	print("=== SF pod: despartitor %s, tablier %.0f m, paliere %.0f m, ciclu camion %.1f s, faza %.3f, plus_dir_side %d, ai_reads_corridor %s" % [
		"FIX" if _podm.static_center else "MOBIL", _podm.deck_length, _podm.approach_m, _podm.cycle_s(),
		_podm.phase, _podm.plus_dir_side, str(_podm.is_in_group(MovableMedianHazard.AI_GROUP))])


func _pod_local(p: Vector3) -> Vector3:
	return _podm.global_transform.affine_inverse() * p


## In coridorul cu doua sensuri (despartitorul fix + mobil, cap la cap)?
func _in_corridor(l: Vector3) -> bool:
	return l.x >= -_podm.approach_m - 1.0 and l.x <= _podm.deck_length + _podm.approach_m + 1.0 \
		and absf(l.z) < _podm.deck_half_width + 1.5 and l.y > -4.0 and l.y < 6.0


## Latura PROPRIE a masinii: dupa sensul soselei la indexul ei (sonda 1d, `_own_side`).
func _pod_side(c: Car) -> float:
	var tk: Track = _race.track
	var r := tk.route_at(c.route)
	var d: Vector3 = r.baked[r.wrap_index(c.road_index + 1)] - r.baked[r.wrap_index(c.road_index)]
	var dl: Vector3 = _podm.global_transform.basis.inverse() * d
	return float(_podm.plus_dir_side) * (1.0 if dl.x >= 0.0 else -1.0)


func _tick_pod(i: int, c: Car, _delta: float) -> void:
	var l := _pod_local(c.global_position)
	var inside := _in_corridor(l)
	var v := c.horizontal_speed()
	var hit_b := false
	var hit_t := false
	var hit_c := false
	for b in c.get_colliding_bodies():
		if b == _podm.truck_body():
			hit_t = true
		elif _podm.is_block(b):
			if String((b as Node).name) == "Atenuator":
				hit_c = true
			else:
				hit_b = true
	if inside and _pod_open[i] < 0:
		var side := _pod_side(c)
		_pod_passes.append({"car": i, "side": side, "t_in": _t, "t_out": -1.0, "v_in": v, "v_min": v,
			"block": 0, "truck": 0, "cushion": 0, "cross": 0, "narrow": 0, "n": 0, "truck_near": false,
			"truck_slow": false, "resp": false, "eject": false, "complete": false, "s_in": l.x})
		_pod_open[i] = _pod_passes.size() - 1
		_pod_wrong[i] = false
	var k := _pod_open[i]
	if k < 0:
		if hit_b and _t - _pod_bl[i] > POD_GAP_S:
			_pod_outside[0] += 1
		if hit_t and _t - _pod_tl[i] > POD_GAP_S:
			_pod_outside[1] += 1
		if hit_c and _t - _pod_cl[i] > POD_GAP_S:
			_pod_outside[2] += 1
	else:
		var p: Dictionary = _pod_passes[k]
		var side: float = p.side
		p.v_min = minf(float(p.v_min), v)
		if hit_b and _t - _pod_bl[i] > POD_GAP_S:
			p.block = int(p.block) + 1
		if hit_t and _t - _pod_tl[i] > POD_GAP_S:
			p.truck = int(p.truck) + 1
		if hit_c and _t - _pod_cl[i] > POD_GAP_S:
			p.cushion = int(p.cushion) + 1
		if inside:
			p.n = int(p.n) + 1
			if l.x >= 0.0 and l.x <= _podm.deck_length and _podm.lane_width_at(l.x, side) < POD_NARROW_M:
				p.narrow = int(p.narrow) + 1
			var wrong := side * (l.z - _podm.offset_at(l.x)) < 0.0
			if wrong and not _pod_wrong[i]:
				p.cross = int(p.cross) + 1
				_pod_cross.append([_t, i, l.x, l.z, _podm.offset_at(l.x), v])
			_pod_wrong[i] = wrong
			if _podm.truck_body() != null:
				var dt := (l.x - _podm.truck_s) * (1.0 if side * float(_podm.plus_dir_side) > 0.0 else -1.0)
				if dt > -POD_TRUCK_NEAR_M and dt < 6.0 and side * l.z > 0.0:
					p.truck_near = true
					if v < 10.0:
						p.truck_slow = true
		else:
			p.t_out = _t
			p.complete = (side * float(_podm.plus_dir_side) > 0.0 and l.x > _podm.deck_length) \
				or (side * float(_podm.plus_dir_side) < 0.0 and l.x < 0.0)
			_pod_open[i] = -1
	if hit_b:
		_pod_bl[i] = _t
	if hit_t:
		_pod_tl[i] = _t
	if hit_c:
		_pod_cl[i] = _t


## Ciocniri frontale intre masini (directii la > 107 de grade, ca la sonda 1d).
func _tick_pod_pairs(cars: Array[Car]) -> void:
	for i in cars.size():
		var a := cars[i]
		for b in a.get_colliding_bodies():
			var cb := b as Car
			if cb == null:
				continue
			var j := cars.find(cb)
			if j <= i:
				continue
			var fa := -a.global_transform.basis.z
			var fb := -cb.global_transform.basis.z
			if Vector2(fa.x, fa.z).normalized().dot(Vector2(fb.x, fb.z).normalized()) >= -0.3:
				continue
			var key := i * 100 + j
			if _t - float(_pod_headon_last.get(key, -99.0)) > 1.0:
				var la := _pod_local(a.global_position)
				_pod_headon.append([_t, i, j, la.x, la.z, _in_corridor(la), a.global_position])
			_pod_headon_last[key] = _t


func _zone(p: Vector3) -> String:
	if _podm != null and _in_corridor(_pod_local(p)):
		return "pod"
	if _near_pontoon(p):
		return "ponton"
	if not _lips.is_empty() and absf(p.x - _lips[0].x) < CHAIN_HALF \
			and p.z <= _lips[0].z + 20.0 and p.z >= _lips[_lips.size() - 1].z - 60.0:
		return "lant"
	if _gate_in != Vector3.INF and p.z < _gate_in.z and p.z > _gate_out.z - 10.0 \
			and p.x > -14.0 and p.x < 50.0:
		return "serpentine"
	return "rest"


## Pe carosabilul pontonului (intre capete, pe latimea cheiului).
func _on_pontoon(p: Vector3) -> bool:
	if _pont.size() != 2:
		return false
	return p.x >= _pont[0].x and p.x <= _pont[1].x and absf(p.z - _pont[0].z) < 6.5


## Pontonul, apa de langa el si capetele lui (zona de raport si de cadere).
func _near_pontoon(p: Vector3) -> bool:
	if _pont.size() != 2:
		return false
	return p.x >= _pont[0].x - 12.0 and p.x <= _pont[1].x + 16.0 \
		and p.z <= _pont[0].z + 8.0 and p.z >= _pont[0].z - PONT_LAT_M - 30.0


func _near_moved_parked(p: Vector3) -> bool:
	for j in _parked.size():
		if _park_moved[j] and is_instance_valid(_parked[j]) \
				and _parked[j].global_position.distance_to(p) < PARK_NEAR_M \
				and _parked[j].global_position.distance_to(_park_home[j]) > PARK_MOVED_M:
			return true
	return false


## Masinile parcate: se strang la primul tick (devin corpuri dupa primul pas de fizica).
func _tick_parked(cars: Array[Car], delta: float) -> void:
	if _parked.is_empty():
		for b in get_tree().get_nodes_in_group(&"sf_parked_bodies"):
			var rb := b as RigidBody3D
			_parked.append(rb)
			_park_home.append(rb.global_position)
			_park_tag.append(String(rb.get_parent().get_meta("sf_tag", "?")))
			_park_axis.append(float(rb.get_parent().get_meta("sf_axis_x", 0.0)))
			_park_moved.append(false)
		if not _parked.is_empty():
			print("=== SF masini parcate: %d piese" % _parked.size())
		else:
			_parked.append(null)       # niciuna: nu mai cauta
		return
	for j in _parked.size():
		var rb := _parked[j]
		if rb == null or not is_instance_valid(rb):
			continue
		var p := rb.global_position
		var off := p.distance_to(_park_home[j])
		if off < PARK_MOVED_M:
			_park_moved[j] = false
			continue
		if not _park_moved[j]:
			_park_moved[j] = true
			var who := -1
			var bd := 6.0
			for i in cars.size():
				var d := cars[i].global_position.distance_to(p)
				if d < bd:
					bd = d
					who = i
			_park_hits.append([_t, _park_tag[j], who,
				cars[who].horizontal_speed() if who >= 0 else 0.0, j])
		# pe carosabil: centrul piesei la < semilatimea strazii + 1 m de axa ei (strazile cu masini
		# parcate merg N-S; axa e `metadata/sf_axis_x` a piesei, scrisa de generator)
		var axis_x := _park_axis[j]
		if absf(p.x - axis_x) < 8.0:
			_park_road_s += delta
			for L in _lips:
				if p.z <= L.z and p.z >= L.z - 45.0:
					_park_land_s += delta
					break


func _report_p6() -> void:
	var cars: Array[Car] = _race.cars
	if _pont.size() == 2:
		print("=== SF ponton: treceri=%d caderi=%d" % [_pont_pass, _pont_falls.size()])
		for f in _pont_falls:
			var p: Vector3 = f[2]
			print("    [sf cadere] t=%5.1fs %-18s poz=(%.0f,%.1f,%.0f)" % [float(f[0]),
				cars[int(f[1])].pilot_name, p.x, p.y, p.z])
	var n := 0
	for rb in _parked:
		if rb != null:
			n += 1
	if n > 0:
		print("=== SF parcate: piese=%d urnite=%d pe_carosabil=%.1fs in_zona_de_aterizare=%.1fs aterizari_langa_resturi=%d ejectari_langa_resturi=%d" % [
			n, _park_hits.size(), _park_road_s, _park_land_s, _park_land_near, _park_eject_near])
		for h in _park_hits:
			print("    [sf parcata] t=%5.1fs %s %-18s v=%.1f" % [float(h[0]), String(h[1]),
				cars[int(h[2])].car_name if int(h[2]) >= 0 else "-", float(h[3])])


func _on_respawn(c: Car, i: int) -> void:
	if _podm != null and i < _pod_open.size() and _pod_open[i] >= 0:
		var pp: Dictionary = _pod_passes[_pod_open[i]]
		pp.resp = true
		pp.t_out = _t
		_pod_open[i] = -1
	if _gate_t[i] >= 0.0:
		_gate_resp[i] = true
	if _climb_t[i] >= 0.0:
		_climb_resp[i] = true
	if _gate2_t[i] >= 0.0:
		_gate2_resp[i] = true
	_resp.append([_t, i, _zone(_prev[i]), _prev[i]])
	for f in _pole_follow:
		if int(f[5]) == i and _t - float(f[1]) <= 4.0:
			f[3] = true
	if _near_pontoon(_prev[i]) and _prev[i].y < _pont[0].y - 1.0:
		_pont_falls.append([_t, i, _prev[i]])


func _on_eject(c: Car, _rag: Node3D, i: int) -> void:
	if _podm != null and i < _pod_open.size() and _pod_open[i] >= 0:
		(_pod_passes[_pod_open[i]] as Dictionary).eject = true
	var hit: Node = c.get("_last_static")
	_ejects.append([_t, i, _zone(c.global_position), String(c.last_eject_cause),
		float(c.last_eject_value), c.global_position,
		(String(hit.name) if hit != null else "-")])
	if _near_moved_parked(c.global_position):
		_park_eject_near += 1


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
	if _podm != null:
		_tick_pod_pairs(cars)
	_tick_parked(cars, delta)
	_tick_street(cars, delta)
	for i in cars.size():
		var c := cars[i]
		var p := c.global_position
		var q := _prev[i]
		_prev[i] = p
		_tick_trams(i, c)
		if _podm != null:
			_tick_pod(i, c, delta)
		_tick_case(i, c, p, delta)
		_tick_points(i, c, p)
		_tick_gate(i, c, p)
		if not _poles.is_empty():
			_tick_poles(i, c, p)
		if q.distance_to(p) > 8.0:
			continue          # repunere: nu e trecere
		_tick_tram_gates(i, c, p, q)
		if _pont.size() == 2:
			var inp := _on_pontoon(p)
			if inp and not _pont_in[i]:
				_pont_pass += 1
			_pont_in[i] = inp
		if c.route == 0:
			for k in _lips.size():
				var L := _lips[k]
				if absf(p.x - L.x) < CHAIN_HALF and q.z > L.z and p.z <= L.z:
					(_lip_v[k] as Array).append(c.horizontal_speed())
		if c.is_on_floor():
			if _air_t[i] >= MIN_AIR_S:
				if _near_moved_parked(p):
					_park_land_near += 1
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
				_gate_bed[i] = false
				_gate_wall[i] = false
			if _gate_t[i] >= 0.0:
				if c.route == 1:
					_gate_branch[i] = true
				var ls: Node = c.get("_last_static")
				if ls != null:
					if ls.name == &"SerpStraturi":
						_gate_bed[i] = true
					elif ls.name == &"SerpFatade":
						_gate_wall[i] = true
				if absf(p.z - _gate_out.z) < GATE_HALF and q.x < _gate_out.x and p.x >= _gate_out.x:
					_passes.append([i, 1 if _gate_branch[i] else 0, _t - _gate_t[i], _gate_resp[i],
						_gate_bed[i], _gate_wall[i]])
					_gate_t[i] = -1.0
				elif _t - _gate_t[i] > PASS_TIMEOUT:
					_passes.append([i, 1 if _gate_branch[i] else 0, -1.0, _gate_resp[i],
						_gate_bed[i], _gate_wall[i]])
					_gate_t[i] = -1.0


## VALUL 2: TRECERILE PRIN STALPI. Semafoarele, felinarele si arborii de strada n-au coliziune la
## prima trecere (gen_sf_route.py, blocul VALUL 2); fiecare e in `metadata/sf_poles` (familia ->
## talpile, Godot) cu raza in `metadata/sf_pole_r`. O trecere = centrul masinii intra in cilindrul de
## raza (raza stalpului + jumatate din latimea masinii), intre talpa - 1 m si talpa + 4 m: cu un stalp
## tare, masina l-ar fi lovit. Se numara intrarile (masina x stalp, cel mult una pe secunda), cu
## viteza de la intrare si daca masina era in zbor.
var _poles: Array = []           # [familie, pozitie, raza]
var _pole_in: Dictionary = {}    # "masina|stalp" -> t ultimei intrari
var _pole_hits: Array = []       # [t, masina, stalp, v, in_aer]
## VALUL 2: MOBILIERUL MIC (grupul `sf_street_bodies`, BumpProp): urnite, secunde pe carosabil (centrul
## piesei la < semilatimea drumului de axa benzii celei mai apropiate), din care in zona de aterizare.
var _street: Array[RigidBody3D] = []
var _street_home: Array[Vector3] = []
var _street_moved: Array[bool] = []
var _street_hits: Array = []     # [t, eticheta, masina, v]
var _street_road_s: float = 0.0
var _street_land_s: float = 0.0
var _street_lost: int = 0


func _setup_poles(track: Track) -> void:
	if not track.has_meta("sf_poles"):
		return
	var fams: Dictionary = track.get_meta("sf_poles")
	var radii: Dictionary = track.get_meta("sf_pole_r", {})
	for fam: String in fams:
		for p: Vector3 in PackedVector3Array(fams[fam]):
			_poles.append([fam, p, float(radii.get(fam, 0.3))])
	print("=== SF stalpi in sf_poles: %d (%s)" % [_poles.size(), ", ".join(fams.keys().map(
		func(f: String) -> String: return "%s %d" % [f, PackedVector3Array(fams[f]).size()]))])


## PASUL 8d: corpurile de coliziune ale stalpilor (StaticBody3D cu `mod_coliziune` = "trunk", sub
## DecorManual/Semafoare|Felinare|Arbori), legate de stalpul din `sf_poles` cel mai apropiat (< 1 m).
## Rezolvate lenes, la primul tick: WorldProp le construieste in `_ready`.
var _pole_body: Dictionary = {}  # instance_id corp -> indicele stalpului
var _pole_bodies_done := false
var _pole_contacts: Array = []   # [t, masina, stalp, v, in_aer, poz masina]
var _pole_c_last: Dictionary = {}
var _pole_follow: Array = []     # [indice contact, t0, v_min, repusa, ejectata, masina]


func _resolve_pole_bodies() -> void:
	_pole_bodies_done = true
	var track: Track = _race.track
	var dm: Node = track.get_node_or_null(^"DecorManual")
	if dm == null:
		return
	var per_fam := {}
	for dir_name in ["Semafoare", "Felinare", "Arbori"]:
		var d: Node = dm.get_node_or_null(NodePath(dir_name))
		if d == null:
			continue
		for b in d.find_children("*", "StaticBody3D", true, false):
			if String((b as Node).get_meta("mod_coliziune", "")) != "trunk":
				continue
			var bp := (b as Node3D).global_position
			for cs in (b as Node).get_children():
				if cs is CollisionShape3D:
					bp = (cs as Node3D).global_position
					break
			var best := -1
			var bd := 1.0
			for k in _poles.size():
				var q: Vector3 = _poles[k][1]
				var dd := Vector2(bp.x - q.x, bp.z - q.z).length()
				if dd < bd:
					bd = dd
					best = k
			if best >= 0:
				_pole_body[(b as Node).get_instance_id()] = best
				var fam: String = _poles[best][0]
				per_fam[fam] = int(per_fam.get(fam, 0)) + 1
	print("=== SF stalpi cu coliziune: %d corpuri legate de stalpi (%s)" % [_pole_body.size(),
		", ".join(per_fam.keys().map(func(f: String) -> String: return "%s %d" % [f, per_fam[f]]))])


func _tick_poles(i: int, c: Car, p: Vector3) -> void:
	if not _pole_bodies_done:
		_resolve_pole_bodies()
	if not _pole_body.is_empty():
		for b in c.get_colliding_bodies():
			var id := (b as Node).get_instance_id()
			if not _pole_body.has(id):
				continue
			var k: int = _pole_body[id]
			var key := "%d|%d" % [i, k]
			if _t - float(_pole_c_last.get(key, -99.0)) > 1.0:
				_pole_contacts.append([_t, i, k, c.horizontal_speed(), not c.is_on_floor(), p])
				_pole_follow.append([_pole_contacts.size() - 1, _t, c.horizontal_speed(), false, false, i])
			_pole_c_last[key] = _t
	for f in _pole_follow:
		if int(f[5]) != i or _t - float(f[1]) > 4.0:
			continue
		f[2] = minf(float(f[2]), c.horizontal_speed())
		if c.is_ejected:
			f[4] = true
	var half := (c.data.body_width * 0.5) if c.data != null else 0.9
	for k in _poles.size():
		var q: Vector3 = _poles[k][1]
		if p.y < q.y - 1.0 or p.y > q.y + 4.0:
			continue
		if Vector2(p.x - q.x, p.z - q.z).length() >= float(_poles[k][2]) + half:
			continue
		var key := "%d|%d" % [i, k]
		if _t - float(_pole_in.get(key, -99.0)) > 1.0:
			_pole_hits.append([_t, i, k, c.horizontal_speed(), not c.is_on_floor()])
		_pole_in[key] = _t


func _tick_street(cars: Array[Car], delta: float) -> void:
	if _street.is_empty():
		for b in get_tree().get_nodes_in_group(&"sf_street_bodies"):
			var rb := b as RigidBody3D
			_street.append(rb)
			_street_home.append(rb.global_position)
			_street_moved.append(false)
		if not _street.is_empty():
			print("=== SF mobilier mic: %d piese (BumpProp; corpuri BumpProp pe pista: %d)" % [
				_street.size(), get_tree().get_nodes_in_group(&"bump_props").size()])
		else:
			_street.append(null)
		return
	var track: Track = _race.track
	for j in _street.size():
		var rb := _street[j]
		if rb == null:
			continue
		if not is_instance_valid(rb):
			_street[j] = null
			_street_lost += 1
			continue
		var p := rb.global_position
		if p.distance_to(_street_home[j]) < PARK_MOVED_M:
			_street_moved[j] = false
			continue
		if not _street_moved[j]:
			_street_moved[j] = true
			var who := -1
			var bd := 6.0
			for i in cars.size():
				var d := cars[i].global_position.distance_to(p)
				if d < bd:
					bd = d
					who = i
			_street_hits.append([_t, String(rb.get_parent().get_meta("sf_tag", "?")), who,
				cars[who].horizontal_speed() if who >= 0 else 0.0])
		# pe carosabil: cel mai apropiat punct copt al oricarei benzi
		var best := INF
		for r in track.routes:
			var rr: TrackRoute = r
			var n := rr.baked.size()
			var step := maxi(1, n / 400)
			var bi := 0
			for k in range(0, n, step):
				var d2 := Vector2(rr.baked[k].x - p.x, rr.baked[k].z - p.z).length_squared()
				if d2 < best:
					best = d2
					bi = k
			for k in range(bi - step, bi + step + 1):
				var a: Vector3 = rr.baked[rr.wrap_index(k)]
				best = minf(best, Vector2(a.x - p.x, a.z - p.z).length_squared())
		if sqrt(best) < track.half_width:
			_street_road_s += delta
			for L in _lips:
				if absf(p.x - L.x) < CHAIN_HALF and p.z <= L.z and p.z >= L.z - 45.0:
					_street_land_s += delta
					break


func _report_v2() -> void:
	var cars: Array[Car] = _race.cars
	if not _poles.is_empty():
		var by_fam := {}
		for h in _pole_hits:
			var fam: String = _poles[int(h[2])][0]
			if not by_fam.has(fam):
				by_fam[fam] = []
			(by_fam[fam] as Array).append(h)
		var fams := {}
		for pl in _poles:
			fams[pl[0]] = int(fams.get(pl[0], 0)) + 1
		for fam: String in fams:
			var hs: Array = by_fam.get(fam, [])
			var vs: Array = hs.map(func(h: Array) -> float: return float(h[3]))
			vs.sort()
			var poles_hit := {}
			var air := 0
			for h in hs:
				poles_hit[int(h[2])] = true
				if bool(h[4]):
					air += 1
			print("=== SF stalpi %s: %d stalpi, treceri prin volum %d (stalpi atinsi %d, in zbor %d), v med %.1f max %.1f m/s" % [
				fam, int(fams[fam]), hs.size(), poles_hit.size(), air,
				float(vs[vs.size() / 2]) if not vs.is_empty() else 0.0, float(vs[vs.size() - 1]) if not vs.is_empty() else 0.0])
		for h in _pole_hits:
			var pl: Array = _poles[int(h[2])]
			var q: Vector3 = pl[1]
			print("    [sf stalp] t=%5.1fs %s #%d %-18s v=%.1f %s poz=(%.0f,%.1f,%.0f)" % [float(h[0]), String(pl[0]),
				int(h[2]), cars[int(h[1])].pilot_name, float(h[3]), "zbor" if bool(h[4]) else "sol", q.x, q.y, q.z])
		# PASUL 8d: contactele reale (stalpi cu coliziune). Linia apare si cu 0 corpuri: spune ca
		# lotul ARE contor, iar `solizi 0` spune ca stalpii n-au coliziune in scena asta.
		var solid := {}
		for k in _pole_body.values():
			var fam_k: String = _poles[int(k)][0]
			solid[fam_k] = int(solid.get(fam_k, 0)) + 1
		for fam: String in fams:
			var cs: Array = _pole_contacts.filter(func(h: Array) -> bool: return String(_poles[int(h[2])][0]) == fam)
			var vs2: Array = cs.map(func(h: Array) -> float: return float(h[3]))
			vs2.sort()
			var hit_k := {}
			var air2 := 0
			for h in cs:
				hit_k[int(h[2])] = true
				if bool(h[4]):
					air2 += 1
			print("=== SF stalpi contact %s: %d stalpi, solizi %d, contacte %d (stalpi atinsi %d, in zbor %d), v med %.1f max %.1f m/s" % [
				fam, int(fams[fam]), int(solid.get(fam, 0)), cs.size(), hit_k.size(), air2,
				float(vs2[vs2.size() / 2]) if not vs2.is_empty() else 0.0,
				float(vs2[vs2.size() - 1]) if not vs2.is_empty() else 0.0])
		for f in _pole_follow:
			var h: Array = _pole_contacts[int(f[0])]
			var pl: Array = _poles[int(h[2])]
			var q: Vector3 = pl[1]
			var pc: Vector3 = h[5]
			print("    [sf stalp lovit] t=%5.1fs %s #%d %-18s v=%.1f %s vmin4s=%.1f repusa=%s ejectata=%s stalp=(%.0f,%.1f,%.0f) masina=(%.1f,%.1f,%.1f)" % [
				float(h[0]), String(pl[0]), int(h[2]), cars[int(h[1])].pilot_name, float(h[3]),
				"zbor" if bool(h[4]) else "sol", float(f[2]), "da" if bool(f[3]) else "nu",
				"da" if bool(f[4]) else "nu", q.x, q.y, q.z, pc.x, pc.y, pc.z])
	var n := 0
	for rb in _street:
		if rb != null:
			n += 1
	if n > 0 or _street_lost > 0:
		print("=== SF mobilier: piese=%d urnite=%d pe_carosabil=%.1fs in_zona_de_aterizare=%.1fs pierdute=%d" % [
			n + _street_lost, _street_hits.size(), _street_road_s, _street_land_s, _street_lost])
		for h in _street_hits:
			print("    [sf mobilier] t=%5.1fs %s %-18s v=%.1f" % [float(h[0]), String(h[1]),
				cars[int(h[2])].car_name if int(h[2]) >= 0 else "-", float(h[3])])


## PASUL 8b: contactele cu cutiile caselor (randul din fata `CaseCorpuri`, cel din spate
## `CaseSpateCorpuri`) si cat de departe de axa benzii lui ajunge o masina (cele mai departate
## pozitii, ca sa se vada daca randurile din spate fara cutie, de la 40 m, sunt la indemana).
## Corpurile numarate de `_tick_case` (randurile din fata si din spate; valul 3: casele pictate,
## placa turnanta, magaziile).
const CASE_BODIES: Array[String] = ["CaseCorpuri", "CaseSpateCorpuri", "CasePictateCorpuri", "PlacaCorpuri",
	"MagaziiCorpuri", "CurtePoartaCorpuri"]
var _case_hits: Array = []       # [t, masina, corp, poz, v]
var _case_last: Dictionary = {}  # (masina, corp) -> ultimul tick de contact
var _off_max: Array = []         # per masina: [distanta, poz, t]
var _off_s: Array[float] = [0.0, 0.0, 0.0]   # secunde-masina la > 15 / 25 / 40 m de axa


func _tick_case(i: int, c: Car, p: Vector3, delta: float) -> void:
	for b in c.get_colliding_bodies():
		var nm := String((b as Node).name)
		if not (nm in CASE_BODIES):
			continue
		var key := "%d|%s" % [i, nm]
		if _t - float(_case_last.get(key, -99.0)) > 1.0:
			_case_hits.append([_t, i, nm, p, c.horizontal_speed()])
		_case_last[key] = _t
	var r: TrackRoute = _race.track.route_at(c.route)
	var best := INF
	for k in range(-4, 5):
		var a: Vector3 = r.baked[r.wrap_index(c.road_index + k)]
		best = minf(best, Vector2(p.x - a.x, p.z - a.z).length())
	while _off_max.size() <= i:
		_off_max.append([0.0, Vector3.ZERO, 0.0])
	if best > float(_off_max[i][0]):
		_off_max[i] = [best, p, _t]
	for k in 3:
		if best > [15.0, 25.0, 40.0][k]:
			_off_s[k] += delta


func _report_case() -> void:
	var cars: Array[Car] = _race.cars
	var front := 0
	var back := 0
	var v3 := {"CasePictateCorpuri": 0, "PlacaCorpuri": 0, "MagaziiCorpuri": 0, "CurtePoartaCorpuri": 0}
	for h in _case_hits:
		var nm := String(h[2])
		if nm == "CaseSpateCorpuri":
			back += 1
		elif v3.has(nm):
			v3[nm] += 1
		else:
			front += 1
	var worst := 0.0
	for o in _off_max:
		worst = maxf(worst, float(o[0]))
	print("=== SF case: contacte rand din fata %d, rand din spate %d; abaterea maxima de la axa %.1f m; secunde-masina la > 15 / 25 / 40 m: %.1f / %.1f / %.1f" % [
		front, back, worst, _off_s[0], _off_s[1], _off_s[2]])
	# valul 3: corpurile au contor chiar daca pista nu le are (linia spune ce exista in scena)
	var present: Array[String] = []
	for nm: String in v3:
		if _race.track.get_node_or_null(NodePath(nm)) != null:
			present.append(nm)
	print("=== SF val3: contacte case pictate %d, placa turnanta %d, magazii %d; corpuri in scena: %s" % [
		v3["CasePictateCorpuri"], v3["PlacaCorpuri"], v3["MagaziiCorpuri"], ",".join(present)])
	if _race.track.get_node_or_null(^"CurtePoartaCorpuri") != null:
		print("=== SF curte: contacte case ulitei portii %d" % v3["CurtePoartaCorpuri"])
	for h in _case_hits:
		var p: Vector3 = h[3]
		print("    [sf casa] t=%5.1fs %-18s %s v=%.1f poz=(%.0f,%.1f,%.0f)" % [float(h[0]),
			cars[int(h[1])].pilot_name, String(h[2]), float(h[4]), p.x, p.y, p.z])
	for i in _off_max.size():
		var o: Array = _off_max[i]
		var p2: Vector3 = o[1]
		print("    [sf abatere] %-18s %.1f m t=%.1fs poz=(%.0f,%.1f,%.0f)" % [cars[i].pilot_name,
			float(o[0]), float(o[2]), p2.x, p2.y, p2.z])


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


## PASUL 8e: puncte de interes (locurile candidate pentru poarta), din `SF_PUNCTE="x,z,r;x,z,r"`
## (Godot): de cate ori intra o masina in cercul de raza r (cel mult o data pe secunda), cu viteza,
## si cea mai mica distanta atinsa. Masoara unde ies masinile din viraj, inainte sa pui ceva acolo.
var _pts: Array = []             # [Vector3 (x, z, r), intrari, v max, d min]
var _pts_last: Dictionary = {}


## PASUL 8e: contactele cu POARTA (corpurile WorldProp de sub `DecorManual/Poarta`: un hull pe stalp
## si unul pe cadru), ca la celelalte corpuri solide: o masina x poarta, cel mult unul pe secunda.
var _gate_hits: Array = []       # [t, masina, v, poz]
var _gate_last: Dictionary = {}
var _gate_seen := -1             # corpuri gasite (-1 = necautat)


func _tick_gate(i: int, c: Car, p: Vector3) -> void:
	if _gate_seen < 0:
		_gate_seen = 0
		var g: Node = _race.track.get_node_or_null(^"DecorManual/Poarta")
		if g != null:
			_gate_seen = g.find_children("*", "StaticBody3D", true, false).size()
		print("=== SF poarta: %d corpuri de coliziune" % _gate_seen)
	if _gate_seen == 0:
		return
	for b in c.get_colliding_bodies():
		var par := (b as Node).get_parent()
		if par == null or String(par.name) != "Poarta":
			continue
		if _t - float(_gate_last.get(i, -99.0)) > 1.0:
			_gate_hits.append([_t, i, c.horizontal_speed(), p])
		_gate_last[i] = _t


func _tick_points(i: int, c: Car, p: Vector3) -> void:
	if _pts.is_empty():
		var env := OS.get_environment("SF_PUNCTE")
		if env.is_empty():
			_pts.append(null)
			return
		for part in env.split(";"):
			var v := part.split_floats(",")
			if v.size() == 3:
				_pts.append([Vector3(v[0], v[1], v[2]), 0, 0.0, INF])
		if _pts.is_empty():
			_pts.append(null)
		return
	if _pts[0] == null:
		return
	for k in _pts.size():
		var pt: Array = _pts[k]
		var c3: Vector3 = pt[0]
		var d := Vector2(p.x - c3.x, p.z - c3.y).length()
		pt[3] = minf(float(pt[3]), d)
		if d < c3.z:
			var key := "%d|%d" % [i, k]
			if _t - float(_pts_last.get(key, -99.0)) > 1.0:
				pt[1] = int(pt[1]) + 1
				pt[2] = maxf(float(pt[2]), c.horizontal_speed())
			_pts_last[key] = _t


func report() -> void:
	var cars: Array[Car] = _race.cars
	if _gate_seen >= 0:
		print("=== SF poarta contacte: %d (corpuri %d)" % [_gate_hits.size(), _gate_seen])
		for h in _gate_hits:
			var hp: Vector3 = h[3]
			print("    [sf poarta] t=%5.1fs %-18s v=%.1f poz=(%.1f,%.1f,%.1f)" % [float(h[0]), cars[int(h[1])].pilot_name,
				float(h[2]), hp.x, hp.y, hp.z])
	if not _pts.is_empty() and _pts[0] != null:
		for pt: Array in _pts:
			var c3: Vector3 = pt[0]
			print("=== SF punct (%.1f, %.1f) r=%.1f: intrari %d, v max %.1f, distanta minima %.1f m" % [c3.x, c3.y,
				c3.z, int(pt[1]), float(pt[2]), float(pt[3])])
	# PASUL 8d: preferinta de scurtatura a fiecarei masini (cea de la final; cu zarul de nivel stins
	# `prefers_shortcut` se trage o data, la `configure`) si ruta pe care a trecut efectiv la furca.
	for i in cars.size():
		var ai := cars[i].controller as AIController
		var r0 := 0
		var r1 := 0
		for ps in _passes:
			if int(ps[0]) == i:
				if int(ps[1]) == 1:
					r1 += 1
				else:
					r0 += 1
		print("=== SF pref %d %s: scurtatura=%s treceri ocol=%d serpentine=%d" % [i, cars[i].pilot_name,
			("da" if ai.prefers_shortcut else "nu") if ai != null else "?", r0, r1])
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
		print("    [sf ejectare] t=%5.1fs %-18s zona=%s %s %.1f poz=(%.0f,%.1f,%.0f) lovit=%s" % [
			float(e[0]), cars[int(e[1])].pilot_name, String(e[2]), String(e[3]), float(e[4]),
			p.x, p.y, p.z, String(e[6])])
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
		print("    [sf poarta] %-18s ruta=%d %.2fs%s%s%s" % [cars[int(ps[0])].pilot_name, int(ps[1]),
			float(ps[2]), " REPUSA" if bool(ps[3]) else "", " STRAT" if bool(ps[4]) else "",
			" FATADA" if bool(ps[5]) else ""])
	_report_trams()
	_report_pod()
	_report_p6()
	_report_case()
	_report_v2()


func _report_pod() -> void:
	if _podm == null:
		return
	var cars: Array[Car] = _race.cars
	var n := 0
	var bl := 0
	var tr := 0
	var cu := 0
	var cr := 0
	for p: Dictionary in _pod_passes:
		if float(p.t_out) < 0.0:
			continue
		n += 1
		bl += 1 if int(p.block) > 0 else 0
		tr += 1 if int(p.truck) > 0 else 0
		cu += 1 if int(p.cushion) > 0 else 0
		cr += int(p.cross)
		print("    [sf pod trecere] %s side=%+d t=%.2f %.2fs v_in=%.1f v_min=%.1f bariera=%d camion=%d atenuator=%d peste=%d ingust=%.2f camion_aproape=%d coada=%d complet=%d repus=%d ejectat=%d" % [
			cars[int(p.car)].car_name, int(p.side), float(p.t_in), float(p.t_out) - float(p.t_in),
			float(p.v_in), float(p.v_min), int(p.block), int(p.truck), int(p.cushion), int(p.cross),
			float(p.narrow) / maxf(float(p.n), 1.0), 1 if bool(p.truck_near) else 0,
			1 if bool(p.truck_slow) else 0, 1 if bool(p.complete) else 0, 1 if bool(p.resp) else 0,
			1 if bool(p.eject) else 0])
	for x in _pod_cross:
		print("    [sf pod peste] t=%.2f %s s=%.1f z=%.2f bariera=%.2f v=%.1f" % [float(x[0]),
			cars[int(x[1])].pilot_name, float(x[2]), float(x[3]), float(x[4]), float(x[5])])
	var hc := 0
	for h in _pod_headon:
		var gp: Vector3 = h[6]
		if bool(h[5]):
			hc += 1
		print("    [sf frontal] t=%.2f %s x %s coridor=%d s=%.1f z=%.1f poz=(%.0f,%.1f,%.0f)" % [float(h[0]),
			cars[int(h[1])].pilot_name, cars[int(h[2])].pilot_name, 1 if bool(h[5]) else 0,
			float(h[3]), float(h[4]), gp.x, gp.y, gp.z])
	print("=== SF pod: treceri %d, cu contact bariera %d, camion %d, atenuator %d; treceri peste despartitor %d; frontale in coridor %d (oriunde %d); contacte fara trecere (bariera/camion/atenuator) %d/%d/%d" % [
		n, bl, tr, cu, cr, hc, _pod_headon.size(), _pod_outside[0], _pod_outside[1], _pod_outside[2]])


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
