extends Node
## Sonda 1b San Francisco: SERPENTINELE scurtaturii (brief san_francisco.md §2
## „Scurtatura: strada cu serpentine (E')", §7 pasul 1b), pe strada sintetica
## `tools/SondaSfSerp*.tscn` scrisa de tools/gen_sf_serpentine.py.
##
## Contractul din brief, pe care il masoara:
##   1. AI-ul trece acele fara [blocaj], fara repuneri, fara sa o ia invers;
##   2. trecerea curata castiga 1-2 s fata de ocol (bulevardul de ~270 m);
##   3. cu o bordura atinsa, scurtatura pierde (aici nu exista borduri fizice:
##      se masoara iesirea de pe carosabil, pe iarba la 45%).
##
## Segmentul cronometrat e ACELASI pe ambele rute: de la poarta de intrare
## (12 m inaintea furcii, pe dreapta de apropiere) la poarta de iesire (20 m
## dupa reintalnire, pe strada tramvaiului). Portile sunt in metadatele scenei.
##
## Ruleaza CA SCENA (autoload-uri), headless:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfSerp.tscn -- \
##       --mode=solo --scene=res://tools/SondaSfSerpR8W7F.tscn
##   ... --mode=solo --pilots=ai,drift,grip --routes=0,1 --cars=0,3 [--alat=10,13,16]
##   ... --mode=race --scene=... --seed=3 --seconds=150 [--car=0 --ai-cars=1,2,...]
##   ... --mode=dump --scene=... --out=tools/data/sf_serp/main.csv
##
## Pilotii din modul solo (fiecare masina din garaj, cate o trecere pe ruta):
##   ai      AIController real, cu `prefers_shortcut` fortat pe ruta ceruta;
##           turbo-ul tinut gol (bara la 0 in fiecare tick), ca timpul pe
##           segment sa nu depinda de unde a ars-o;
##   drift   pilot de proba pe axa rutei: viteza-tinta din curbura care vine
##           (v = sqrt(a_lat * R), franare la a_brake), DRIFT apasat in acele
##           strmte (R < 14 m) — „cum ar conduce un jucator bun"; `--alat=`
##           baleiaza agresivitatea, raportul ia cea mai buna trecere CURATA;
##   grip    acelasi pilot, fara drift;
##   wide    pilotul drift, dar in acul 2 linia e impinsa 1,5 m dincolo de
##           marginea exterioara (o iesire larga: „bordura atinsa");
##   cut     pilotul drift, dar taie interiorul acului 2 (unde vor fi
##           hortensiile): linia e trasa 1,5 m dincolo de marginea interioara;
##   line    drept de la furca la gura, peste tot ce e intre ele (iarba), cu
##           gaz la fund: limita de sus a unei scurtaturi fara borduri fizice.
##
## Modul race: Race.tscn cu 8 masini (jucatorul primeste tot un creier AI, ca
## in ProbeRace), fiecare trecere prin segment e un rand: ruta, timpul,
## offroad, lent (<4 m/s), frana tare, marsarier, contrasens, repuneri, perete,
## [blocaj] (>= 3 s sub 6 m/s, aceeasi regula ca ProbeRace). Iese cu o linie
## `SFSERP_JSON {...}` pe care o aduna tools/sf_serp_sum.py.
##
## Jolt e multithread (memoria `proberace-nedeterminism`): se compara
## DISTRIBUTII pe seed-uri, nu o rulare.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const GATE_HALF: float = 10.0
const STUCK_SPEED: float = 6.0
const STUCK_S: float = 3.0
const SLOW_SPEED: float = 4.0


## Pilot de proba pe o LINIE precalculata (axa rutei, deplasata spre exteriorul
## acelor cat sa incapa raza de viraj a masinii), cu viteza-tinta din curbura.
##
## Limita care decide totul la raza 8 (car.gd `_apply_driving`): rotatia e
## `steer * steer_speed * min(v / (max_speed/2), 1)`, deci SUB jumatate din viteza
## maxima raza minima de viraj fara drift e constanta: (max_speed/2) / steer_speed
## = 17,5 / 1,9 = 9,2 m la toate masinile (steer_speed 1,9 e comun). Un ac cu axa
## la 8 m nu se poate urmari pe axa decat in drift (raza alege intre 0,2 si 1,6
## din volan, maparea CTR) — pe grip trebuie linia exterioara.
class PathPilot extends CarController:
	var path: PackedVector3Array
	var cum: PackedFloat32Array
	var rad: PackedFloat32Array
	var turn: PackedFloat32Array
	var a_lat: float = 12.0
	var a_brake: float = 14.0
	var use_drift: bool = true
	var drift_r: float = 12.0
	var full_gas: bool = false
	var idx: int = 0
	var _steer: float = 0.0
	var _thr: float = 1.0
	var _drift: bool = false
	var _vyaw: Dictionary = {}

	## Cea mai mare viteza la care raza r se poate urmari cu volanul `eff`.
	func v_yaw(r: float, eff: float) -> float:
		var key := int(r * 4.0) * 10 + int(eff * 10.0)
		if _vyaw.has(key):
			return _vyaw[key]
		var mx := car.max_speed
		var v := 40.0
		var out := 7.0
		while v >= 7.0:
			var t := clampf(inverse_lerp(mx * car.steer_taper_start, mx, v), 0.0, 1.0)
			var taper := lerpf(1.0, car.steer_taper_at_top, t)
			var yaw := eff * car.steer_speed * minf(v / (mx * 0.5), 1.0) * taper
			if v / r <= 0.92 * yaw:
				out = v
				break
			v -= 0.5
		_vyaw[key] = out
		return out

	func update(_d: float) -> void:
		var p := car.global_position
		var best := idx
		var bd := INF
		for j in range(idx, mini(idx + 60, path.size())):
			var q := path[j]
			var dd := Vector2(q.x - p.x, q.z - p.z).length_squared()
			if dd < bd:
				bd = dd
				best = j
		idx = best
		var v := car.horizontal_speed()
		var la := clampf(0.35 * v + 3.0, 4.5, 14.0)
		var tj := _at(cum[idx] + la)
		var tgt := path[tj]
		# urmarire pura EXACTA pe modelul de directie al masinii: curbura ceruta
		# k = 2 sin(a) / L, rotatia ceruta k*v, iar volanul o da prin
		# steer_speed * min(v / (max/2), 1) * taper (car.gd `_apply_driving`).
		# In drift unghiul se ia fata de VITEZA (botul e rotit spre interior).
		var f := -car.global_transform.basis.z
		if car.is_drifting and v > 3.0:
			f = car.linear_velocity
		f.y = 0.0
		var t := tgt - p
		t.y = 0.0
		if f.length() > 0.01 and t.length() > 0.01:
			f = f.normalized()
			var L := t.length()
			t = t / L
			var a := atan2(f.cross(t).y, f.dot(t))
			var kappa := 2.0 * sin(a) / maxf(L, 1.0)
			var s_v := _steer_gain(maxf(v, 2.0))
			var eff := kappa * maxf(v, 2.0) / s_v
			if car.is_drifting:
				# maparea CTR: in drift volanul alege raza intre arc_wide si tight
				var tight := lerpf(car.drift_arc_tight, car.drift_arc_tight_top,
					clampf(inverse_lerp(car.drift_min_speed, car.max_speed, v), 0.0, 1.0))
				var want := clampf(eff * car.drift_dir, car.drift_arc_wide, tight)
				var into := 2.0 * (want - car.drift_arc_wide) / maxf(tight - car.drift_arc_wide, 0.01) - 1.0
				_steer = clampf(into * car.drift_dir, -1.0, 1.0)
				if eff * car.drift_dir < car.drift_arc_wide - 0.1:
					_steer = -car.drift_dir
			else:
				_steer = clampf(eff, -1.0, 1.0)
		if full_gas:
			_thr = 1.0
			_drift = false
			return
		# viteza-tinta: cel mai strans punct din urmatorii 70 m, cu franare
		var eff := 1.4 if use_drift else 1.0
		var target := 99.0
		var j := idx
		while j < path.size() and cum[j] - cum[idx] < 70.0:
			var vc := minf(sqrt(a_lat * rad[j]), v_yaw(rad[j], eff))
			var d := maxf(cum[j] - cum[idx] - 1.0, 0.0)
			target = minf(target, sqrt(vc * vc + 2.0 * a_brake * d))
			j += 1
		if v > target + 0.3:
			_thr = clampf(-(v - target) / 3.0, -1.0, -0.2)
		else:
			_thr = 1.0
		if use_drift:
			var r_soon := 999.0
			var sgn := 0.0
			j = idx
			while j < path.size() and cum[j] - cum[idx] < 7.0:
				if rad[j] < r_soon:
					r_soon = rad[j]
					sgn = turn[j]
				j += 1
			if not _drift:
				if r_soon < drift_r and v > car.drift_min_speed * 1.05 and sgn * _steer > 0.0:
					_drift = true
			else:
				var r_now := 999.0
				var s_now := 0.0
				j = idx
				while j < path.size() and cum[j] - cum[idx] < 3.0:
					if rad[j] < r_now:
						r_now = rad[j]
						s_now = turn[j]
					j += 1
				if (car.is_drifting and _steer * car.drift_dir < -0.15) 						or r_now > drift_r * 1.5 						or (car.is_drifting and s_now * car.drift_dir < 0.0):
					_drift = false

	## Rotatia pe unitate de volan la viteza v (fara drift).
	func _steer_gain(v: float) -> float:
		var mx := car.max_speed
		var t := clampf(inverse_lerp(mx * car.steer_taper_start, mx, v), 0.0, 1.0)
		return car.steer_speed * minf(v / (mx * 0.5), 1.0) * lerpf(1.0, car.steer_taper_at_top, t)

	func _at(s: float) -> int:
		var j := idx
		while j < path.size() - 1 and cum[j] < s:
			j += 1
		return j

	func get_steer() -> float:
		return _steer

	func get_throttle() -> float:
		return _thr

	func is_drift_pressed() -> bool:
		return _drift


## „Pilotul care drifturează": AIController-ul real (linia lui, driftul lui,
## volanul lui), plus un PUNCT DE FRANARE de om: in fata oricarui viraj mai
## strans de `r_tight` coboara la `v_hair` (franare la `a_b`). AI-ul de joc nu
## coboara niciodata sub 0,44 x viteza maxima (CORNER_SPEED_FLOOR, ~15,5 m/s);
## aici pragul se baleiaza. Peste 1,2 x drift_min_speed (~10,8 m/s) AI-ul
## drifturează singur in ace; sub el, le ia pe grip.
## `v_h2` >= 0: alta viteza DOAR la acul 2 (greseala „intrat prea tare").
class SkilledAI extends AIController:
	var v_hair: float = 10.0
	var v_h2: float = -1.0
	var h2: Vector2 = Vector2(1e9, 1e9)
	var h2_r: float = 12.0
	var a_b: float = 14.0
	var r_tight: float = 14.0
	var rad: Dictionary = {}
	var _cap: float = 99.0

	func update(delta: float) -> void:
		super.update(delta)
		_cap = 99.0
		# doar pe scurtatura (ruta 1): pe ocol pilotul e AI-ul neschimbat
		if car.route == 1:
			var r: TrackRoute = track.route_at(1)
			_scan(1, clampi(car.road_index, 0, r.baked.size() - 1), 0.0)
		# inca pe bucla, inainte de furca, cu scurtatura aleasa: acele de pe ruta 1
		if car.route == 0 and prefers_shortcut and rad.has(1):
			var b: TrackRoute = track.route_at(1)
			var d := car.global_position.distance_to(b.baked[0])
			if d < 70.0:
				_scan(1, 0, d)

	func _scan(route: int, i0: int, d_off: float) -> void:
		var r: TrackRoute = track.route_at(route)
		var rr: PackedFloat32Array = rad[route]
		var n := r.baked.size()
		var j := i0
		var steps := 0
		while steps < n:
			var dj := r.dists[j] - r.dists[i0]
			if dj < 0.0:
				dj += r.length()
			dj += d_off
			if dj > 60.0:
				break
			if rr[j] < r_tight:
				var vh := v_hair
				if v_h2 >= 0.0 and Vector2(r.baked[j].x - h2.x, r.baked[j].z - h2.y).length() < h2_r:
					vh = v_h2
				_cap = minf(_cap, sqrt(vh * vh + 2.0 * a_b * maxf(dj - 2.0, 0.0)))
			j += 1
			steps += 1
			if j >= n:
				if r.closed:
					j = 0
				else:
					break

	func get_throttle() -> float:
		var v := car.horizontal_speed()
		if v > _cap + 0.3:
			return clampf(-(v - _cap) / 3.0, -1.0, -0.2)
		return super.get_throttle()


var _mode: String = "solo"
var _scene: String = "res://tools/SondaSfSerpR8W7F.tscn"
var _out: String = ""
var _cars: Array[int] = []
var _pilots: PackedStringArray = PackedStringArray(["ai", "pro"])
var _routes: Array[int] = [0, 1]
## `--alat=`: pentru `pro` / `wide` e viteza-tinta in ace (m/s), pentru pilotii
## de proba pe linie, acceleratia laterala.
var _alats: Array[float] = [10.0, 13.0, 16.0]
var _lead: float = 110.0
var _detail: bool = false
## `--trace`: pozitia la 4 Hz in segment (x, z, ruta, lateral, v, pe sosea, drift)
var _trace: bool = false
var _seed: int = 20261110
var _seconds: float = 150.0
var _player_car: int = -1
var _ai_cars: Array[int] = []

## `--walls=off,h`: ziduri statice pe AMBELE margini ale scurtaturii, la `off` m
## dincolo de marginea carosabilului, inalte de `h` m (0,2 = bordura; 1,5 =
## fatada / zid de gradina). Lipsesc unde banda e la < hw+3 m de bucla (furca,
## gura). Strada reala are case si borduri; pe sonda goala AI-ul iese pe iarba.
var _walls: Vector2 = Vector2(-1.0, 0.0)
var _wall_body: StaticBody3D = null

var _track: Track
var _gin: Vector2
var _gout: Vector2
var _tram_x: float
var _hairpins: Array[Vector2] = []
var _hp_r: float = 8.0
var _fork: Vector3
var _merge: Vector3


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--scene="):
			_scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--cars="):
			for s in arg.trim_prefix("--cars=").split(","):
				_cars.append(int(s))
		elif arg.begins_with("--pilots="):
			_pilots = arg.trim_prefix("--pilots=").split(",")
		elif arg.begins_with("--routes="):
			_routes.clear()
			for s in arg.trim_prefix("--routes=").split(","):
				_routes.append(int(s))
		elif arg.begins_with("--alat="):
			_alats.clear()
			for s in arg.trim_prefix("--alat=").split(","):
				_alats.append(float(s))
		elif arg.begins_with("--walls="):
			var wv := arg.trim_prefix("--walls=").split(",")
			_walls = Vector2(float(wv[0]), float(wv[1]) if wv.size() > 1 else 1.5)
		elif arg.begins_with("--rneed="):
			_r_need = float(arg.trim_prefix("--rneed="))
		elif arg.begins_with("--lead="):
			_lead = float(arg.trim_prefix("--lead="))
		elif arg == "--detail":
			_detail = true
		elif arg == "--trace":
			_trace = true
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--car="):
			_player_car = int(arg.trim_prefix("--car="))
		elif arg.begins_with("--ai-cars="):
			for s in arg.trim_prefix("--ai-cars=").split(","):
				_ai_cars.append(int(s))
	if _cars.is_empty():
		for i in GameState.CAR_DATA.size():
			_cars.append(i)
	match _mode:
		"dump":
			_do_dump.call_deferred()
		"solo":
			_do_solo.call_deferred()
		"race":
			_start_race()
		_:
			push_error("probe_sf_serp: mod necunoscut %s" % _mode)
			get_tree().quit(2)


func _read_meta(t: Track) -> bool:
	if not t.has_meta("serp_gate_in"):
		print("probe_sf_serp: scena n-are metadata/serp_* (nu e o SondaSfSerp)")
		return false
	_gin = t.get_meta("serp_gate_in")
	_gout = t.get_meta("serp_gate_out")
	_tram_x = float(t.get_meta("serp_tram_x"))
	_hp_r = float(t.get_meta("serp_radius"))
	_fork = t.get_meta("serp_fork")
	_merge = t.get_meta("serp_merge")
	_hairpins.clear()
	for h: Vector2 in t.get_meta("serp_hairpins"):
		_hairpins.append(h)
	return true


func _load_track() -> bool:
	_track = (load(_scene) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	if not _read_meta(_track):
		return false
	_build_walls()
	return true


func _build_walls() -> void:
	if _walls.x < 0.0 or _track.routes.size() < 2:
		return
	var b: TrackRoute = _track.routes[1]
	var main: TrackRoute = _track.routes[0]
	var hw := b.half_width
	var body := StaticBody3D.new()
	body.name = "ZidSerp"
	_track.add_child(body)
	_wall_body = body
	var made := 0
	for side: float in [-1.0, 1.0]:
		var prev := Vector3.INF
		for i in b.baked.size():
			var p: Vector3 = b.baked[i]
			var a: Vector3 = b.baked[maxi(i - 1, 0)]
			var c: Vector3 = b.baked[mini(i + 1, b.baked.size() - 1)]
			var d := Vector3(c.x - a.x, 0.0, c.z - a.z).normalized()
			var right := d.cross(Vector3.UP).normalized()
			var w := p + right * side * (hw + _walls.x + 0.2)
			var ok := true
			# langa bucla (furca, gura): fara zid
			for q in main.baked:
				if Vector2(q.x - w.x, q.z - w.z).length() < main.half_width + 3.0:
					ok = false
					break
			# peste alt tronson al benzii (interiorul acului): fara zid
			if ok:
				for k in b.baked.size():
					if absi(k - i) < 3:
						continue
					var q: Vector3 = b.baked[k]
					if Vector2(q.x - w.x, q.z - w.z).length() < hw + 0.3:
						ok = false
						break
			if not ok:
				prev = Vector3.INF
				continue
			if prev != Vector3.INF:
				var seg := Vector3(w.x - prev.x, 0.0, w.z - prev.z)
				var L := seg.length()
				if L > 0.05:
					var cs := CollisionShape3D.new()
					var box := BoxShape3D.new()
					box.size = Vector3(0.4, _walls.y + 0.6, L + 0.15)
					cs.shape = box
					var mid := (w + prev) * 0.5
					mid.y = minf(w.y, prev.y) + (_walls.y + 0.6) * 0.5 - 0.6
					cs.transform = Transform3D(Basis.looking_at(seg.normalized(), Vector3.UP), mid)
					body.add_child(cs)
					made += 1
			prev = w
	print("  ziduri pe scurtatura: %d segmente, la %.1f m de margine, %.2f m peste drum" % [made, _walls.x, _walls.y])


# ------------------------------------------------------------------ dump

func _do_dump() -> void:
	if not await _load_track():
		get_tree().quit(2)
		return
	var r: TrackRoute = _track.routes[0]
	var n := r.baked.size()
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out.get_base_dir())
		var f := FileAccess.open(_out, FileAccess.WRITE)
		f.store_line("i,x,y,z")
		for i in n:
			var p: Vector3 = r.baked[i]
			f.store_line("%d,%.3f,%.3f,%.3f" % [i, p.x, p.y, p.z])
		f.close()
	print("dump: ruta 0 %d puncte copte, %.1f m -> %s" % [n, r.length(), _out])
	_print_geometry()
	get_tree().quit(0)


## Ce a iesit din spline, nu ce s-a cerut: lungimea benzii, raza minima pe
## fiecare ac, panta, capetele.
func _print_geometry() -> void:
	if _track.routes.size() < 2:
		print("  !! scena n-are ruta 1")
		return
	var b: TrackRoute = _track.routes[1]
	var main: TrackRoute = _track.routes[0]
	print("  ruta 1 '%s': %.1f m, %d puncte, hw %.2f, capete (%.1f,%.1f,%.1f) -> (%.1f,%.1f,%.1f), frac %.4f -> %.4f" % [
		b.label, b.length(), b.baked.size(), b.half_width,
		b.baked[0].x, b.baked[0].y, b.baked[0].z,
		b.baked[b.baked.size() - 1].x, b.baked[b.baked.size() - 1].y, b.baked[b.baked.size() - 1].z,
		b.entry_frac, b.exit_frac])
	var pts := b.baked
	for k in _hairpins.size():
		var h := _hairpins[k]
		var rmin := 999.0
		var dmin := 999.0
		var dmax := 0.0
		for i in range(2, pts.size() - 2):
			var d := Vector2(pts[i].x - h.x, pts[i].z - h.y).length()
			if d > _hp_r + 6.0:
				continue
			rmin = minf(rmin, _circ_r(pts[i - 2], pts[i], pts[i + 2]))
			dmin = minf(dmin, d)
			dmax = maxf(dmax, d)
		print("  acul %d (centru %.0f,%.0f): raza de curbura minima %.1f m, distanta ax-centru %.1f..%.1f m" % [
			k + 1, h.x, h.y, rmin, dmin, dmax])
	var maxg := 0.0
	for i in range(1, pts.size()):
		var dh := Vector2(pts[i].x - pts[i - 1].x, pts[i].z - pts[i - 1].z).length()
		if dh > 0.3:
			maxg = maxf(maxg, absf(pts[i].y - pts[i - 1].y) / dh)
	print("  panta maxima pe banda %.1f%%, cadere %.2f m; ocolul (bucla de la furca la reintalnire) %.1f m" % [
		maxg * 100.0, pts[0].y - pts[pts.size() - 1].y, _main_len_between(main, b)])


func _main_len_between(main: TrackRoute, b: TrackRoute) -> float:
	var n := main.baked.size()
	var i0 := int(round(b.entry_frac * n)) % n
	var i1 := int(round(b.exit_frac * n)) % n
	var d := main.dists[i1] - main.dists[i0]
	if d < 0.0:
		d += main.length()
	return d


static func _circ_r(a: Vector3, b: Vector3, c: Vector3) -> float:
	var A := Vector2(a.x, a.z)
	var B := Vector2(b.x, b.z)
	var C := Vector2(c.x, c.z)
	var cr := absf((B - A).cross(C - A))
	if cr < 1e-6:
		return 999.0
	return (A.distance_to(B) * B.distance_to(C) * C.distance_to(A)) / (2.0 * cr)


# ------------------------------------------------------------------ solo

## Polilinia rutei alese, din punctul de lansare pana dupa poarta de iesire.
var _path_hw: PackedFloat32Array = PackedFloat32Array()
## Raza la care linia pilotului de proba se muta spre exterior (`--rneed=`).
var _r_need: float = 10.0


func _build_path(route: int, i_start: int) -> PackedVector3Array:
	var main: TrackRoute = _track.routes[0]
	var n := main.baked.size()
	var out := PackedVector3Array()
	_path_hw = PackedFloat32Array()
	var i_end := _main_index_near(Vector3(_gout.x, 0.0, _gout.y + 40.0))
	if route == 0:
		var i := i_start
		while i != i_end:
			out.append(main.baked[i])
			_path_hw.append(main.half_width)
			i = (i + 1) % n
		return out
	var b: TrackRoute = _track.routes[1]
	var i_entry := int(b.entry_frac * n) % n
	var i_exit := int(b.exit_frac * n) % n
	var i := i_start
	while i != i_entry:
		out.append(main.baked[i])
		_path_hw.append(main.half_width)
		i = (i + 1) % n
	for p in b.baked:
		out.append(p)
		_path_hw.append(b.half_width)
	i = (i_exit + 1) % n
	while i != i_end:
		out.append(main.baked[i])
		_path_hw.append(main.half_width)
		i = (i + 1) % n
	return out


## Linia pilotului: axa, deplasata spre exteriorul virajelor mai stranse decat
## `r_need` (cat incape: semi-latimea minus 0,9 m), netezita; `wide` / `cut`
## pun in acul 2 linia la 1,5 m DINCOLO de marginea exterioara / interioara.
func _make_line(pp: PathPilot, axis: PackedVector3Array, hws: PackedFloat32Array,
		r_need: float, mistake: String) -> void:
	var n := axis.size()
	var cum := _cum_of(axis)
	var rad := PackedFloat32Array()
	var trn := PackedFloat32Array()
	_curv(axis, cum, rad, trn)
	var off := PackedFloat32Array()
	off.resize(n)
	for i in n:
		off[i] = 0.0
		if rad[i] < r_need and hws[i] > 0.0:
			off[i] = clampf(r_need - rad[i], 0.0, maxf(hws[i] - 0.9, 0.0))
	# netezire: maxim pe +-6 m, apoi medie pe +-4 m
	var mx := PackedFloat32Array()
	mx.resize(n)
	for i in n:
		var m := 0.0
		var j := _cum_index(cum, cum[i] - 6.0, i, -1)
		var k := _cum_index(cum, cum[i] + 6.0, i, 1)
		for q in range(j, k + 1):
			m = maxf(m, off[q])
		mx[i] = m
	var sm := PackedFloat32Array()
	sm.resize(n)
	for i in n:
		var j := _cum_index(cum, cum[i] - 4.0, i, -1)
		var k := _cum_index(cum, cum[i] + 4.0, i, 1)
		var acc := 0.0
		for q in range(j, k + 1):
			acc += mx[q]
		sm[i] = acc / float(k - j + 1)
	# semnul exteriorului: al virajului dominant din jur (±6 m)
	var line := PackedVector3Array()
	line.resize(n)
	var h2 := _hairpins[1] if _hairpins.size() >= 2 else Vector2(1e9, 1e9)
	for i in n:
		var j := _cum_index(cum, cum[i] - 6.0, i, -1)
		var k := _cum_index(cum, cum[i] + 6.0, i, 1)
		var tsum := 0.0
		for q in range(j, k + 1):
			tsum += trn[q] / maxf(rad[q], 1.0)
		var a := axis[maxi(i - 1, 0)]
		var c := axis[mini(i + 1, n - 1)]
		var d := Vector3(c.x - a.x, 0.0, c.z - a.z).normalized()
		var right := d.cross(Vector3.UP).normalized()
		var outward := right if tsum > 0.0 else -right
		var o := sm[i]
		if mistake != "" and Vector2(axis[i].x - h2.x, axis[i].z - h2.y).length() < _hp_r + 3.0:
			o = (hws[i] + 1.5) * (1.0 if mistake == "wide" else -1.0)
		line[i] = axis[i] + outward * o
	pp.path = line
	pp.cum = _cum_of(line)
	pp.rad = PackedFloat32Array()
	pp.turn = PackedFloat32Array()
	_curv(line, pp.cum, pp.rad, pp.turn)


static func _cum_of(pts: PackedVector3Array) -> PackedFloat32Array:
	var cum := PackedFloat32Array()
	cum.resize(pts.size())
	var acc := 0.0
	for i in pts.size():
		if i > 0:
			acc += Vector2(pts[i].x - pts[i - 1].x, pts[i].z - pts[i - 1].z).length()
		cum[i] = acc
	return cum


## Raza (cerc prin punctele la ±3 m) si semnul virajului (+1 stanga) pe polilinie.
static func _curv(pts: PackedVector3Array, cum: PackedFloat32Array,
		rad: PackedFloat32Array, trn: PackedFloat32Array) -> void:
	rad.resize(pts.size())
	trn.resize(pts.size())
	for i in pts.size():
		var ia := _cum_index(cum, cum[i] - 3.0, i, -1)
		var ib := _cum_index(cum, cum[i] + 3.0, i, 1)
		if ia == i or ib == i:
			rad[i] = 999.0
			trn[i] = 0.0
			continue
		rad[i] = _circ_r(pts[ia], pts[i], pts[ib])
		var d1 := Vector3(pts[i].x - pts[ia].x, 0, pts[i].z - pts[ia].z)
		var d2 := Vector3(pts[ib].x - pts[i].x, 0, pts[ib].z - pts[i].z)
		trn[i] = signf(d1.cross(d2).y)


func _main_index_near(p: Vector3) -> int:
	var main: TrackRoute = _track.routes[0]
	var best := 0
	var bd := INF
	for i in main.baked.size():
		var q: Vector3 = main.baked[i]
		var d := Vector2(q.x - p.x, q.z - p.z).length_squared()
		if d < bd:
			bd = d
			best = i
	return best


func _do_solo() -> void:
	if not await _load_track():
		get_tree().quit(2)
		return
	print("")
	print("=== SERPENTINE SOLO — %s ===" % _scene.get_file())
	_print_geometry()
	var results: Array[Dictionary] = []
	for ci in _cars:
		for pilot in _pilots:
			for route in _routes:
				if pilot in ["wide", "line", "pro"] and route == 0:
					continue
				if pilot in ["pro", "wide"]:
					var best: Dictionary = {}
					var all_runs: Array[Dictionary] = []
					for al in _alats:
						var r := await _run_solo(ci, pilot, route, al)
						all_runs.append(r)
						if _detail:
							_print_row(r)
						# cea mai buna trecere: curata pentru drift/grip; pentru
						# wide/cut, cea mai buna dintre cele care chiar au gresit
						# curata = terminata, fara repunere, fara perete, <= 1 s pe
						# iarba (~0,5 s se numara oricum la furca, unde masina e
						# intre benzi); pentru wide: cea mai buna care CHIAR a gresit
						var ok := bool(r["done"]) and int(r["resp"]) == 0
						if pilot == "pro":
							ok = ok and float(r["off"]) <= 1.5 and int(r["walls"]) == 0
						else:
							ok = ok and (float(r["off"]) > 1.5 or int(r["walls"]) > 0)
						if ok and (best.is_empty() or float(r["t"]) < float(best["t"])):
							best = r
					if best.is_empty():
						best = all_runs[0].duplicate()
						best["note"] = "nicio trecere curata"
					results.append(best)
					if not _detail:
						_print_row(best)
				else:
					var r := await _run_solo(ci, pilot, route, 0.0)
					results.append(r)
					_print_row(r)
	_solo_summary(results)
	print("SFSOLO_JSON " + JSON.stringify({"scene": _scene.get_file(), "walls": [_walls.x, _walls.y],
		"results": results}))
	get_tree().quit(0)


func _print_row(r: Dictionary) -> void:
	var apex := ""
	for v: float in r["apex"]:
		apex += "%5.1f" % v
	print("  %-11s %-5s ruta %d a_lat %4.1f | %s t %6.2f s | v_med %4.1f | apex%s | off %4.2f s | lent %4.2f | frana %4.2f | mars %4.2f | contra %4.2f | drift %4.2f | bara +%.2f | perete %d (%.0f) | resp %d | blocaj %d %s" % [
		r["car"], r["pilot"], r["route_used"], r["alat"], "OK " if r["done"] else "NU ",
		r["t"], r["vmed"], apex, r["off"], r["slow"], r["brake"], r["rev"], r["wrong"], r["drift"],
		r["bar"], r["walls"], r["wall_max"], r["resp"], r["stuck"], String(r.get("note", ""))])


func _run_solo(ci: int, pilot: String, route: int, alat: float) -> Dictionary:
	var data: CarData = GameState.CAR_DATA[ci]
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(data)
	car.track = _track
	var main: TrackRoute = _track.routes[0]
	var n := main.baked.size()
	var i_gate := _main_index_near(Vector3(_gin.x, 0.0, _gin.y))
	var back := int(round(_lead / (main.length() / float(n))))
	var si := (i_gate - back + n) % n
	var p0: Vector3 = main.baked[si]
	var p1: Vector3 = main.baked[(si + 2) % n]
	var dir := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z).normalized()
	car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), p0 + Vector3(0, 0.6, 0))
	var v0 := car.max_speed * 0.95
	car.linear_velocity = dir * v0
	car.road_index = si
	car.last_safe_index = si
	var ai: AIController = null
	var pp: PathPilot = null
	if pilot in ["ai", "pro", "wide"]:
		if pilot == "ai":
			ai = AIController.new()
		else:
			var sk := SkilledAI.new()
			sk.v_hair = alat
			if pilot == "wide" and _hairpins.size() >= 2:
				sk.v_h2 = alat + 5.0
				sk.h2 = _hairpins[1]
				sk.h2_r = _hp_r + 5.0
			for ri in [1]:
				var rt: TrackRoute = _track.routes[ri]
				var rr := PackedFloat32Array()
				var tt := PackedFloat32Array()
				var cm := PackedFloat32Array()
				cm.resize(rt.baked.size())
				for q in rt.baked.size():
					cm[q] = rt.dists[q]
				_curv(rt.baked, cm, rr, tt)
				sk.rad[ri] = rr
			ai = sk
		car.set_controller(ai)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261110 + ci
		ai.configure(_track, rng)
		ai.line_offset = 0.0
		ai.prefers_shortcut = route == 1
	else:
		pp = PathPilot.new()
		var axis := _build_path(route, si)
		var hws := _path_hw
		if pilot == "line":
			axis = _line_path(si)
			hws = PackedFloat32Array()
			hws.resize(axis.size())
			hws.fill(0.0)
		var mistake := ""
		_make_line(pp, axis, hws, _r_need, mistake)
		pp.a_lat = alat
		pp.use_drift = pilot != "grip"
		pp.full_gas = pilot == "line"
		car.set_controller(pp)
	car.race_active = true
	var ev := {"resp": 0, "walls": 0, "wall_max": 0.0, "eject": 0}
	car.respawned.connect(func(_c: Car) -> void: ev["resp"] = int(ev["resp"]) + 1)
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: ev["eject"] = int(ev["eject"]) + 1)
	car.wall_hit.connect(func(_c: Car, imp: float) -> void:
		ev["walls"] = int(ev["walls"]) + 1
		ev["wall_max"] = maxf(float(ev["wall_max"]), imp))
	var t := 0.0
	var t_in := -1.0
	var t_out := -1.0
	var prev := car.global_position
	var st := _new_seg_stats()
	var bar0 := 0.0
	var route_used := 0
	while t < 60.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if ai != null:
			car.turbo_charge = 0.0
		var p := car.global_position
		if t_in < 0.0 and _cross_in(prev, p):
			t_in = t
			bar0 = car.turbo_charge
			ev["resp"] = 0
			ev["walls"] = 0
			ev["wall_max"] = 0.0
		elif t_in >= 0.0:
			route_used = maxi(route_used, car.route)
			_seg_tick(car, st, 1.0 / 60.0, -1)
			if _trace and int(round((t - t_in) * 60.0)) % 15 == 0:
				print("    tr %5.2f (%6.1f,%5.1f,%6.1f) r%d i%3d lat %+5.1f v %4.1f %s %s thr %+.1f st %+.2f" % [
					t - t_in, p.x, p.y, p.z, car.route, car.road_index,
					_track.lateral_distance(car.road_index, p, car.route), car.horizontal_speed(),
					"sosea" if _track.is_on_road(car.road_index, p, car.route) else "IARBA",
					"D" if car.is_drifting else "-", car.controller.get_throttle(), car.controller.get_steer()])
			if _cross_out(prev, p):
				t_out = t
				break
		prev = p
	var apex: Array[float] = []
	for k in _hairpins.size():
		apex.append(float(st["apex"][k]) if route_used == 1 else 0.0)
	var res := {
		"car": (data.display_name as String).left(11), "ci": ci, "pilot": pilot, "route": route,
		"route_used": route_used, "alat": alat, "done": t_out > 0.0,
		"t": (t_out - t_in) if t_out > 0.0 else 99.0,
		"vmed": float(st["dist"]) / maxf(t_out - t_in, 0.01) if t_out > 0.0 else 0.0,
		"apex": apex, "off": st["off"], "slow": st["slow"], "brake": st["brake"],
		"rev": st["rev"], "wrong": st["wrong"], "drift": st["drift_s"],
		"bar": (car.turbo_charge - bar0) if ai == null else 0.0,
		"walls": ev["walls"], "wall_max": ev["wall_max"], "resp": int(ev["resp"]) + int(ev["eject"]),
		"stuck": st["stuck_n"],
	}
	car.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	return res


static func _cum_index(cum: PackedFloat32Array, s: float, from: int, step: int) -> int:
	var j := from
	while j + step >= 0 and j + step < cum.size():
		if (step > 0 and cum[j] >= s) or (step < 0 and cum[j] <= s):
			break
		j += step
	return j


## Linia dreapta peste iarba: apropierea pe sosea pana la furca, apoi o linie
## de la furca la punctul de reintalnire, apoi strada tramvaiului.
func _line_path(si: int) -> PackedVector3Array:
	var main: TrackRoute = _track.routes[0]
	var n := main.baked.size()
	var out := PackedVector3Array()
	var i_f := _main_index_near(_fork)
	var i := si
	while i != i_f:
		out.append(main.baked[i])
		i = (i + 1) % n
	var a := _fork
	var b := _merge + Vector3(0, 0, 4)
	var steps := int(a.distance_to(b) / 2.0)
	for k in steps:
		out.append(a.lerp(b, float(k) / float(steps)))
	var i_m := _main_index_near(b)
	var i_end := _main_index_near(Vector3(_gout.x, 0.0, _gout.y + 40.0))
	i = i_m
	while i != i_end:
		out.append(main.baked[i])
		i = (i + 1) % n
	return out


func _cross_in(a: Vector3, b: Vector3) -> bool:
	return a.x < _gin.x and b.x >= _gin.x and absf(b.z - _gin.y) < GATE_HALF


func _cross_out(a: Vector3, b: Vector3) -> bool:
	return a.z < _gout.y and b.z >= _gout.y and absf(b.x - _gout.x) < GATE_HALF


func _new_seg_stats() -> Dictionary:
	var ap: Array[float] = []
	for k in _hairpins.size():
		ap.append(99.0)
	return {"off": 0.0, "slow": 0.0, "brake": 0.0, "rev": 0.0, "wrong": 0.0,
		"drift_s": 0.0, "dist": 0.0, "stuck_t": 0.0, "stuck_n": 0, "apex": ap,
		"last": Vector3.INF, "stuck_where": []}


## Un tick in segment: cronometrele de stare.
func _seg_tick(car: Car, st: Dictionary, dt: float, _idx: int) -> void:
	var v := car.horizontal_speed()
	var p := car.global_position
	if st["last"] != Vector3.INF:
		var lp: Vector3 = st["last"]
		st["dist"] = float(st["dist"]) + Vector2(p.x - lp.x, p.z - lp.z).length()
	st["last"] = p
	var on_road := _track.is_on_road(car.road_index, p, car.route)
	if not on_road:
		st["off"] = float(st["off"]) + dt
	if v < SLOW_SPEED:
		st["slow"] = float(st["slow"]) + dt
	var fwd := -car.global_transform.basis.z
	var fwd_speed := car.linear_velocity.dot(fwd)
	var thr := car.controller.get_throttle() if car.controller != null else 0.0
	if thr < -0.5 and fwd_speed > 0.5:
		st["brake"] = float(st["brake"]) + dt
	if fwd_speed < -0.5:
		st["rev"] = float(st["rev"]) + dt
	# contrasens: viteza contra directiei rutei pe care sta masina, numarata
	# doar PE carosabil (pe iarba, langa un ac, indexul cel mai apropiat poate
	# sari pe tronsonul vecin, care merge in sens opus — fals pozitiv)
	var r: TrackRoute = _track.route_at(car.route)
	if on_road and r != null and r.baked.size() > 2:
		var i := clampi(car.road_index, 0, r.baked.size() - 2)
		var tan := r.baked[i + 1] - r.baked[i]
		tan.y = 0.0
		if tan.length() > 0.01 and car.linear_velocity.dot(tan.normalized()) < -1.0:
			st["wrong"] = float(st["wrong"]) + dt
	if car.is_drifting:
		st["drift_s"] = float(st["drift_s"]) + dt
	var ap: Array = st["apex"]
	for k in _hairpins.size():
		var h := _hairpins[k]
		if Vector2(p.x - h.x, p.z - h.y).length() < _hp_r + 5.0 and car.route == 1:
			ap[k] = minf(float(ap[k]), v)
	if v < STUCK_SPEED:
		st["stuck_t"] = float(st["stuck_t"]) + dt
		if float(st["stuck_t"]) >= STUCK_S:
			st["stuck_t"] = 0.0
			st["stuck_n"] = int(st["stuck_n"]) + 1
			(st["stuck_where"] as Array).append("(%.0f,%.0f,%.0f) r%d v%.1f" % [p.x, p.y, p.z, car.route, v])
	else:
		st["stuck_t"] = 0.0


func _solo_summary(results: Array[Dictionary]) -> void:
	print("")
	print("  REZUMAT pe pilot x ruta (mediana [min-max] a timpului pe segment, masini cu trecere completa):")
	var keys := {}
	for r in results:
		keys["%s|%d" % [r["pilot"], int(r["route"])]] = true
	for key: String in keys:
		var ts: Array = []
		var bad := 0
		var off := 0.0
		var stuck := 0
		var resp := 0
		var wrong := 0.0
		var cnt := 0
		for r in results:
			if "%s|%d" % [r["pilot"], int(r["route"])] != key:
				continue
			cnt += 1
			if bool(r["done"]):
				ts.append(float(r["t"]))
			else:
				bad += 1
			off += float(r["off"])
			stuck += int(r["stuck"])
			resp += int(r["resp"])
			wrong += float(r["wrong"])
		ts.sort()
		var med := 0.0
		if not ts.is_empty():
			med = ts[ts.size() / 2] if ts.size() % 2 == 1 else (ts[ts.size() / 2 - 1] + ts[ts.size() / 2]) * 0.5
		print("  %-12s | %2d treceri, %d neterminate | t %.2f [%.2f-%.2f] | off %.2f s | blocaj %d | resp %d | contrasens %.2f s" % [
			key, cnt, bad, med, ts[0] if not ts.is_empty() else 0.0,
			ts[ts.size() - 1] if not ts.is_empty() else 0.0, off, stuck, resp, wrong])
	# delta pe masina: scurtatura - ocol, per pilot
	print("")
	print("  DELTA pe masina (scurtatura - ocol, s; negativ = scurtatura castiga):")
	for pilot in ["ai", "pro"]:
		var line := ""
		var ds: Array = []
		for ci in _cars:
			var t0 := -1.0
			var t1 := -1.0
			var nm := ""
			for r in results:
				if int(r["ci"]) != ci or not bool(r["done"]):
					continue
				if r["pilot"] != pilot and not (pilot == "pro" and r["pilot"] == "ai" and int(r["route"]) == 0):
					continue
				nm = r["car"]
				if int(r["route"]) == 0 and int(r["route_used"]) == 0:
					t0 = float(r["t"])
				elif pilot == "pro" and r["pilot"] == "ai" and int(r["route"]) == 0:
					t0 = float(r["t"])
				elif int(r["route"]) == 1 and int(r["route_used"]) == 1:
					t1 = float(r["t"])
			if t0 > 0.0 and t1 > 0.0:
				line += " %s %+.2f" % [nm, t1 - t0]
				ds.append(t1 - t0)
		if not ds.is_empty():
			ds.sort()
			print("  %-6s mediana %+.2f [%+.2f..%+.2f] |%s" % [pilot, ds[ds.size() / 2], ds[0], ds[ds.size() - 1], line])
	for pilot in ["wide", "line"]:
		var line := ""
		for ci in _cars:
			var tc := -1.0
			var tw := -1.0
			var t0 := -1.0
			var nm := ""
			for r in results:
				if int(r["ci"]) != ci or not bool(r["done"]):
					continue
				nm = r["car"]
				if r["pilot"] == "pro" and int(r["route"]) == 1:
					tc = float(r["t"])
				elif r["pilot"] == "ai" and int(r["route"]) == 0:
					t0 = float(r["t"])
				elif r["pilot"] == pilot:
					tw = float(r["t"])
			if tw > 0.0 and tc > 0.0:
				line += " %s %+.2f (vs ocol %+.2f)" % [nm, tw - tc, (tw - t0) if t0 > 0.0 else 0.0]
		if not line.is_empty():
			print("  %-6s fata de trecerea curata a pilotului pro:%s" % [pilot, line])


# ------------------------------------------------------------------ race

var _race: Node = null
var _t: float = 0.0
var _done: bool = false
var _c: Array[Dictionary] = []
var _passes: Array[Dictionary] = []
var _stuck_events: Array[Dictionary] = []
var _respawn_events: Array[Dictionary] = []


func _start_race() -> void:
	var lineup: Array[int] = []
	var player := _player_car
	if player < 0:
		player = _seed % GameState.CAR_DATA.size()
	if _ai_cars.is_empty():
		for k in 7:
			lineup.append((player + 1 + k) % GameState.CAR_DATA.size())
	else:
		lineup = _ai_cars
	GameState.selected_track = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.traffic_override = -1
	GameState.ai_cars_override = lineup
	GameState.selected_car = player
	GameState.ai_count = lineup.size()
	GameState.track_scene_override = _scene
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	_track = _race.track
	if not _read_meta(_track):
		get_tree().quit(2)
		return
	_build_walls()
	var pl: Car = _race.player
	var old: CarController = pl.controller
	pl.remove_child(old)
	old.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	(_race._rng as RandomNumberGenerator).seed = _seed
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car == pl:
			var ai := AIController.new()
			car.set_controller(ai)
			var visible: Array[Car] = cars.duplicate()
			ai.configure(_track, rng, visible)
		var roll := rng.randf_range(0.88, 0.97)
		car.speed_scale = 1.0 if car == pl else roll
		_c.append({"name": "%s" % car.car_name, "open": {}, "prev": car.global_position,
			"stuck_t": 0.0, "prefers": (car.controller as AIController).prefers_shortcut})
		var idx := i
		car.respawned.connect(func(cc: Car) -> void: _on_respawn(idx, cc))
		car.wall_hit.connect(func(_cc: Car, imp: float) -> void:
			var o: Dictionary = _c[idx]["open"]
			if not o.is_empty():
				o["walls"] = int(o["walls"]) + 1
				o["wall_max"] = maxf(float(o["wall_max"]), imp))
	print("probe_sf_serp race: %s seed %d, %d masini, ai_shortcut_chance %.2f" % [
		_scene.get_file(), _seed, cars.size(), _track.ai_shortcut_chance])


func _on_respawn(i: int, car: Car) -> void:
	var o: Dictionary = _c[i]["open"]
	var p := car.global_position
	_respawn_events.append({"t": snappedf(_t, 0.1), "car": _c[i]["name"], "in_seg": not o.is_empty(),
		"route": car.route, "pos": [snappedf(p.x, 1), snappedf(p.y, 1), snappedf(p.z, 1)]})
	if not o.is_empty():
		o["resp"] = int(o["resp"]) + 1


func _physics_process(delta: float) -> void:
	if _mode != "race" or _race == null or _done:
		return
	if _race.state != Race.State.RUNNING:
		for i in _race.cars.size():
			_c[i]["prev"] = (_race.cars[i] as Car).global_position
		return
	_t += delta
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		var c := _c[i]
		var p := car.global_position
		var prev: Vector3 = c["prev"]
		var o: Dictionary = c["open"]
		if _cross_in(prev, p):
			if not o.is_empty():
				_close_pass(i, false)
			o = _new_seg_stats()
			o.merge({"t0": _t, "route": 0, "walls": 0, "wall_max": 0.0, "resp": 0,
				"lap_bar": car.turbo_charge})
			c["open"] = o
		elif not o.is_empty():
			o["route"] = maxi(int(o["route"]), car.route)
			var n0 := int(o["stuck_n"])
			_seg_tick(car, o, delta, i)
			if int(o["stuck_n"]) > n0:
				_log_stuck(i, car, true)
			if _cross_out(prev, p):
				o["t1"] = _t
				_close_pass(i, true)
			elif _t - float(o["t0"]) > 60.0:
				_close_pass(i, false)
		if o.is_empty():
			# [blocaj] in afara segmentului: aceeasi regula, ca sa nu scape nimic
			var v := car.horizontal_speed()
			if v < STUCK_SPEED:
				c["stuck_t"] = float(c["stuck_t"]) + delta
				if float(c["stuck_t"]) >= STUCK_S:
					c["stuck_t"] = 0.0
					_log_stuck(i, car, false)
			else:
				c["stuck_t"] = 0.0
		c["prev"] = p
	if _t >= _seconds:
		_done = true
		_race_report()
		get_tree().quit(0)


func _log_stuck(i: int, car: Car, in_seg: bool) -> void:
	var p := car.global_position
	var touching: PackedStringArray = []
	for body in car.get_colliding_bodies():
		var b := body as Node3D
		if b != null:
			touching.append("%s" % (b.name if not String(b.name).begins_with("@") else b.get_class()))
	var e := {"t": snappedf(_t, 0.1), "car": _c[i]["name"], "in_seg": in_seg, "route": car.route,
		"pos": [snappedf(p.x, 1), snappedf(p.y, 1), snappedf(p.z, 1)], "v": snappedf(car.horizontal_speed(), 0.1),
		"touch": ",".join(touching)}
	_stuck_events.append(e)
	print("[blocaj] t=%5.1fs %-12s %s ruta %d poz=(%.0f,%.0f,%.0f) v=%.1f atinge: %s" % [
		_t, _c[i]["name"], "SEGMENT" if in_seg else "bucla", car.route, p.x, p.y, p.z,
		car.horizontal_speed(), e["touch"] if not touching.is_empty() else "-"])


func _close_pass(i: int, done: bool) -> void:
	var o: Dictionary = _c[i]["open"]
	var t := (float(o["t1"]) - float(o["t0"])) if done else -1.0
	_passes.append({"car": _c[i]["name"], "route": int(o["route"]), "done": done,
		"t": snappedf(t, 0.01), "off": snappedf(float(o["off"]), 0.01),
		"slow": snappedf(float(o["slow"]), 0.01), "brake": snappedf(float(o["brake"]), 0.01),
		"rev": snappedf(float(o["rev"]), 0.01), "wrong": snappedf(float(o["wrong"]), 0.01),
		"drift": snappedf(float(o["drift_s"]), 0.01), "stuck": int(o["stuck_n"]),
		"resp": int(o["resp"]), "walls": int(o["walls"]), "wall_max": snappedf(float(o["wall_max"]), 0.1),
		"apex": o["apex"]})
	_c[i]["open"] = {}


func _race_report() -> void:
	print("")
	print("=== SERPENTINE PLUTON — %s, seed %d, %.0f s ===" % [_scene.get_file(), _seed, _t])
	for route in [0, 1]:
		var ts: Array = []
		var n := 0
		var inc := 0
		var agg := {"off": 0.0, "slow": 0.0, "rev": 0.0, "wrong": 0.0, "stuck": 0, "resp": 0, "walls": 0}
		for ps in _passes:
			if int(ps["route"]) != route:
				continue
			n += 1
			if bool(ps["done"]):
				ts.append(float(ps["t"]))
			else:
				inc += 1
			for k in ["off", "slow", "rev", "wrong"]:
				agg[k] = float(agg[k]) + float(ps[k])
			for k in ["stuck", "resp", "walls"]:
				agg[k] = int(agg[k]) + int(ps[k])
		ts.sort()
		var med := 0.0
		if not ts.is_empty():
			med = ts[ts.size() / 2]
		print("  ruta %d: %d treceri (%d neterminate) | t med %.2f [%.2f-%.2f] | off %.1f s | lent %.1f s | mars %.1f s | contrasens %.1f s | blocaj %d | resp %d | perete %d" % [
			route, n, inc, med, ts[0] if not ts.is_empty() else 0.0, ts[ts.size() - 1] if not ts.is_empty() else 0.0,
			agg["off"], agg["slow"], agg["rev"], agg["wrong"], agg["stuck"], agg["resp"], agg["walls"]])
	var outside := 0
	for e in _stuck_events:
		if not bool(e["in_seg"]):
			outside += 1
	print("  [blocaj] total %d (%d in segment, %d pe restul buclei); repuneri %d" % [
		_stuck_events.size(), _stuck_events.size() - outside, outside, _respawn_events.size()])
	var out := {"scene": _scene.get_file(), "seed": _seed, "seconds": _t, "walls": [_walls.x, _walls.y],
		"chance": _track.ai_shortcut_chance, "passes": _passes, "stuck": _stuck_events,
		"respawns": _respawn_events}
	print("SFSERP_JSON " + JSON.stringify(out))
