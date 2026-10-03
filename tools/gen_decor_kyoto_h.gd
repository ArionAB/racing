extends Node
## Generator de decor MANUAL pentru POI H — PODUL TOGETSUKYO SI DREAPTA FINALA
## (Track18, Kyoto, frac 0,82-1,00). Tiparul gen_decor_kyoto_a.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoH.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoH.tscn -- \
##       --out=tools/kyoto_decor/poi_h.part
##
## Fisierul .part (`;;EXT` + `;;NODES`) il lipeste tools/gen_kyoto_route.py
## in Track18.tscn (blocul DECOR MANUAL).

const TRACK := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneH_Togetsukyo"

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _ext: Dictionary = {}   # stem -> path
var _n := 0
var _out_path := ""
var _scan := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--scan":
			_scan = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_prep()
	if _scan:
		await _do_scan()
		get_tree().quit(0)
		return
	_rng.seed = 18082026
	_build()
	_write()
	get_tree().quit(0)


func _do_scan() -> void:
	var pts := _track.baked
	var n := pts.size()
	print("; baked %d, lungime %.0f" % [n, _total])
	var last_s := -100.0
	for i in n:
		var f := float(i) / float(n)
		if f < 0.80:
			continue
		if _cum[i] - last_s < 8.0:
			continue
		last_s = _cum[i]
		var p: Vector3 = pts[i]
		var hw := _track.width_at(f)
		var line := "i %4d f %.4f s %6.1f (%.1f, %.2f, %.1f) hw %.1f sol:" % [i, f, _cum[i] - _total, p.x, p.y, p.z, hw]
		var fr := _frame(_cum[i])
		for lat in [-90.0, -60.0, -40.0, -25.0, -15.0, -11.0, 11.0, 15.0, 25.0, 40.0, 60.0]:
			var q: Vector3 = p + (fr[2] as Vector3) * lat
			line += " %+.0f:%.1f" % [lat, _sol_real(q.x, q.z)]
		print(line)
	var br := _track.get_node_or_null("Poduri/Togetsukyo")
	if br != null:
		for c in br.get_children():
			if c is Node3D:
				var g := (c as Node3D).global_position
				print("; modul pod %s (%.1f, %.1f, %.1f)" % [c.name, g.x, g.y, g.z])
	await _scan_map()


## Harta pe celule de 10 m: R = banda (< hw+4), T = copaci (PadureMasa),
## ~ = apa (sol sub -3), - = sol sub cota drumului cu > 2 m, . = liber.
func _scan_map() -> void:
	var forest := _track.get_node_or_null("PadureMasa")
	for k in 900:
		if forest != null and bool(forest.get("done")):
			break
		await get_tree().process_frame
	var occ: Dictionary = forest.get("_occ") if forest != null else {}
	var cell := 10.0
	for gz in range(-60, 480, 10):
		var line := "%5d " % gz
		for gx in range(-220, 80, 10):
			var c := Vector2(gx + 5, gz + 5)
			var ch := "."
			var near := INF
			var ny := 0.0
			for p in _track.baked:
				var d := c.distance_to(Vector2(p.x, p.z))
				if d < near:
					near = d
					ny = p.y
			var nt := 0
			for kx in range(int(gx / 2.0) - 1, int((gx + cell) / 2.0) + 1):
				for kz in range(int(gz / 2.0) - 1, int((gz + cell) / 2.0) + 1):
					if occ.has(Vector2i(kx, kz)):
						nt += 1
			var sy := _sol_real(c.x, c.y)
			if near < 11.0:
				ch = "R"
			elif nt > 0:
				ch = "T"
			elif sy < -3.0:
				ch = "~"
			elif sy < ny - 2.0:
				ch = "-"
			line += ch
		print(line)
	print("      x de la -220, pas 10")


var _cum: PackedFloat32Array
var _total := 0.0


func _prep() -> void:
	var pts := _track.baked
	_cum.resize(pts.size() + 1)
	_cum[0] = 0.0
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		_cum[i + 1] = _cum[i] + Vector2(b.x - a.x, b.z - a.z).length()
	_total = _cum[pts.size()]


## Cadrul drumului la distanta s de linia de start (s < 0 = pe H):
## [pozitie, tangenta, dreapta, semilatime].
func _frame(s: float) -> Array:
	var pts := _track.baked
	var n := pts.size()
	var ss := fposmod(s, _total)
	var lo := 0
	var hi := n
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if _cum[mid] <= ss:
			lo = mid
		else:
			hi = mid
	var a: Vector3 = pts[lo]
	var b: Vector3 = pts[(lo + 1) % n]
	var t := (ss - _cum[lo]) / maxf(0.001, _cum[lo + 1] - _cum[lo])
	var p := a.lerp(b, t)
	var tan := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	var right := tan.cross(Vector3.UP).normalized()
	var hw: float = _track.width_at(float(lo) / float(n))
	return [p, tan, right, hw]


## ------------------------------------------------------------------------
## DECIZIILE (randul H din docs/track_briefs/kyoto.md §2, 0,82-1,00)
##
## Harta `--scan` (celule de 10 m): raul Katsura e un bazin de ~60 x 80 m de
## fiecare parte a podului (apa la -3,0, fundul la -3,3; x -110..-55 la vest,
## -30..+15 la est, z 245..320), cu mal uscat (-3..+1) in jur; la vest malul
## urca abrupt in deal (+5..+8 la x -140). Podul (14 module) e pe x -57..-38.
## Stanga dreptei (exteriorul buclei, x < -20, z 0..220) era camp gol.
##
## - BARCILE: trei `yakatabune` pe PathMover dus-intors, `collide = false`,
##   `stick_to_ground = false`, la 1,6-2,0 m/s, paralele cu podul la 30-50 m
##   de ax (pilele stau sub tablier, |lat| < hw), carena la -3,3 (pescaj 0,3).
## - MALURILE: pietre de rau (garden_rock a/b/c scalate 1,5-2,6, movile de
##   muschi) pe linia apei (sol -3,6..-2,2), artari/pini/ginkgo pe malul
##   uscat (sol > -2,2), toate la > hw + 6 de ax (trunchiuri cu corp).
## - FELINARE de piatra la capetele podului, ambele parti, la hw + 4.
## - DREAPTA (s -210..-85, pana la strada lui A de la s -70): primul rand de
##   copaci la 20-30 m in stanga (pagoda e la ~4,5 grade stanga de ax de la
##   iesirea de pe pod; la 200 m asta inseamna 16 m lateral, deci nimic mai
##   aproape de 20 m in stanga), rar in dreapta (spre orasul lui A), felinare
##   de piatra alternand partile la hw + 4, o incinta de templu (zid + artari)
##   pe stanga. Masa de dincolo e PadureMasa (zonele "H vest" din
##   gen_kyoto_route.py).

const HW := 7.0
const S_BR_IN := -360.0     # capatul de intrare al podului (frac 0,832)
const S_BR_OUT := -224.0    # capatul de iesire (frac 0,894)
const S_A := -85.0          # de aici incolo e strada lui A (case de la s -70)
const WATER_Y := -3.0
const BOAT_Y := -3.3
const MAPLES := ["momiji_a", "momiji_b", "momiji_c"]


func _build() -> void:
	_boats()
	_banks()
	_bridge_lanterns()
	_straight()
	_temple()
	_temple_right()
	_town()


## yaw care intoarce -Z local spre directia d (orizontala).
func _yaw_face(d: Vector3) -> float:
	return atan2(-d.x, -d.z)


## yaw care duce +X local pe directia d (orizontala).
func _yaw_x_along(d: Vector3) -> float:
	return atan2(-d.z, d.x)


func _road_dist(x: float, z: float) -> float:
	var c := Vector2(x, z)
	var best := INF
	for r: TrackRoute in _track.routes:
		var b: PackedVector3Array = r.baked
		for i in b.size():
			best = minf(best, c.distance_to(Vector2(b[i].x, b[i].z)))
	return best


## ---------------------------------------------------------------- barcile
var _boat_lines: Array[String] = []


func _boats() -> void:
	_res_id("yakatabune", "res://assets/models/kyoto/vehicles/yakatabune.glb")
	# [nume, puncte (x, z), viteza, faza]
	var specs := [
		["BarcaKatsuraVest1", [Vector2(-79, 254), Vector2(-77, 280), Vector2(-82, 306)], 2.0, 0.0],
		["BarcaKatsuraVest2", [Vector2(-97, 302), Vector2(-94, 280), Vector2(-96, 258)], 1.6, 0.55],
		["BarcaKatsuraEst", [Vector2(-6, 262), Vector2(-3, 286), Vector2(-8, 310)], 1.8, 0.3],
	]
	for sp in specs:
		var pts: Array[String] = []
		var a: Array = sp[1]
		for k in a.size() - 1:
			var p0: Vector2 = a[k]
			var p1: Vector2 = a[k + 1]
			var nseg := int(ceil(p0.distance_to(p1) / 4.0))
			for j in nseg:
				var q := p0.lerp(p1, float(j) / float(nseg))
				pts.append("%.2f, %.2f, %.2f" % [q.x, BOAT_Y, q.y])
				_chk_water(String(sp[0]), q)
		var qe: Vector2 = a[a.size() - 1]
		pts.append("%.2f, %.2f, %.2f" % [qe.x, BOAT_Y, qe.y])
		_chk_water(String(sp[0]), qe)
		_boat_lines.append('[node name="%s" type="Path3D" parent="."]' % sp[0])
		_boat_lines.append('script = ExtResource("poih_pathmover")')
		_boat_lines.append('model = ExtResource("poih_yakatabune")')
		_boat_lines.append("collide = false")
		_boat_lines.append("points = PackedVector3Array(%s)" % ", ".join(pts))
		_boat_lines.append("speed = %.1f" % float(sp[2]))
		_boat_lines.append("travel_mode = 1")
		_boat_lines.append("phase = %.2f" % float(sp[3]))
		_boat_lines.append("stick_to_ground = false")
		_boat_lines.append("bob_amplitude = 0.05")
		_boat_lines.append("rock_amplitude = 0.02")
		_boat_lines.append("")


## Barca (2,2 x 9,4 m) trebuie sa stea toata pe apa: fundul sub -3 la
## centru si la +-1,6 m lateral / +-4,8 m in lung.
func _chk_water(nm: String, q: Vector2) -> void:
	var worst := -INF
	for d in [Vector2.ZERO, Vector2(1.6, 0), Vector2(-1.6, 0), Vector2(0, 4.8), Vector2(0, -4.8)]:
		worst = maxf(worst, _sol_real(q.x + d.x, q.y + d.y))
	if worst > WATER_Y - 0.05:
		print("; ATENTIE %s: fundul la %.2f langa (%.1f, %.1f) - barca pe uscat" % [nm, worst, q.x, q.y])


## ---------------------------------------------------------------- malurile
func _banks() -> void:
	var rocks := ["garden_rock_a", "garden_rock_c", "garden_rock_a", "garden_rock_c", "garden_rock_b"]
	var placed: Array[Vector2] = []
	var trees: Array[Vector2] = []
	var n_rock := 0
	var n_tree := 0
	# Grila de 3 m pe caseta raului, in ordine amestecata.
	var cand: Array[Vector2] = []
	var x := -125.0
	while x <= 30.0:
		var z := 205.0
		while z <= 345.0:
			cand.append(Vector2(x + _rng.randf_range(-1.2, 1.2), z + _rng.randf_range(-1.2, 1.2)))
			z += 3.0
		x += 3.0
	for i in range(cand.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t := cand[i]
		cand[i] = cand[j]
		cand[j] = t
	for c in cand:
		var rd := _road_dist(c.x, c.y)
		if rd < HW + 6.0:
			continue
		var sy := _sol_real(c.x, c.y)
		# Linia apei: pietre DOAR pe tarm (runda 1: intervalul cuprindea si
		# fundul bazinului, -3,3, si pietrele ieseau imprastiate prin apa ca
		# niste bolovani cazuti). Acum: solul la -3,1..-2,3 si apa (sol < -3,05)
		# la cel mult 3,5 m.
		if sy > -3.1 and sy < -2.3:
			if n_rock < 46 and _far(c, placed, 5.0) and _near_water(c, 3.5):
				placed.append(c)
				var m: String = rocks[_rng.randi_range(0, rocks.size() - 1)]
				var scl := _rng.randf_range(1.3, 2.2)
				if _rng.randf() < 0.3:
					m = "moss_mound"
					scl = _rng.randf_range(0.9, 1.3)
				_raw(m, "rocks", "hPiatraRau", Vector3(c.x, _sol_min(c.x, c.y, 0.8 * scl) - 0.12 * scl, c.y),
					_rng.randf_range(0.0, TAU), scl, "")
				n_rock += 1
			continue
		# Malul uscat: copaci, la distanta unul de altul (coroane de 7-12 m).
		if sy >= -2.2 and sy < 2.6 and rd > HW + 8.0 and n_tree < 34 and _flat(c, 1.2):
			if _far(c, trees, 9.0) and _far(c, placed, 3.0):
				trees.append(c)
				var r := _rng.randf()
				var tm: String = "niwaki_pine" if r < 0.3 else ("ginkgo" if r < 0.42 else MAPLES[_rng.randi_range(0, 2)])
				var sc := _rng.randf_range(0.85, 1.15) if tm == "niwaki_pine" else _rng.randf_range(0.8, 1.05)
				_raw(tm, "plants", "hMalCopac", Vector3(c.x, _sol_real(c.x, c.y) - 0.05, c.y),
					_rng.randf_range(0.0, TAU), sc, "")
				n_tree += 1
				# tufa de mal langa unii copaci
				if _rng.randf() < 0.35:
					var o := Vector2(_rng.randf_range(-3.5, 3.5), _rng.randf_range(-3.5, 3.5))
					var q := c + o
					if _sol_real(q.x, q.y) > -2.6 and _road_dist(q.x, q.y) > HW + 5.0 and _flat(q, 0.8):
						_raw("karikomi_shrub_b" if _rng.randf() < 0.5 else "karikomi_shrub_a", "plants", "hMalTufa",
							Vector3(q.x, _sol_min(q.x, q.y, 0.9) - 0.08, q.y), _rng.randf_range(0.0, TAU),
							_rng.randf_range(1.0, 1.4), "")
	print("; maluri: %d pietre, %d copaci" % [n_rock, n_tree])


## Malul de vest urca abrupt in deal (+9 m pe ~25 m): acolo cota din
## coliziune si cea din sampler (probe_manual) diverg cu metri intre noduri.
## Un copac sta doar unde solul variaza < `tol` m pe +-2 m.
func _flat(c: Vector2, tol: float) -> bool:
	var lo := INF
	var hi := -INF
	for d in [Vector2.ZERO, Vector2(2, 0), Vector2(-2, 0), Vector2(0, 2), Vector2(0, -2)]:
		var y := _sol_real(c.x + d.x, c.y + d.y)
		lo = minf(lo, y)
		hi = maxf(hi, y)
	return hi - lo < tol


func _near_water(c: Vector2, r: float) -> bool:
	for k in 8:
		var a := TAU * float(k) / 8.0
		if _sol_real(c.x + cos(a) * r, c.y + sin(a) * r) < WATER_Y - 0.05:
			return true
	return false


func _far(c: Vector2, arr: Array[Vector2], d: float) -> bool:
	for q in arr:
		if c.distance_to(q) < d:
			return false
	return true


## Felinare de piatra la capetele podului, pe ambele parti, cu fata spre drum.
func _bridge_lanterns() -> void:
	for s in [S_BR_IN - 12.0, S_BR_OUT + 12.0]:
		for side in [-1.0, 1.0]:
			var f := _frame(s)
			var right: Vector3 = f[2]
			var p: Vector3 = (f[0] as Vector3) + right * (side * (HW + 4.0))
			_raw("stone_lantern_a", "props", "hPodFelinar", Vector3(p.x, _sol_min(p.x, p.z, 0.65) - 0.05, p.z),
				_yaw_face(-right * side), 1.0, "")
			# un artar in spatele felinarului
			var tp: Vector3 = (f[0] as Vector3) + right * (side * (HW + 11.0)) + (f[1] as Vector3) * 3.0
			if _sol_real(tp.x, tp.z) > -2.4:
				_raw(MAPLES[_rng.randi_range(0, 2)], "plants", "hPodArtar",
					Vector3(tp.x, _sol_real(tp.x, tp.z) - 0.05, tp.z), _yaw_x_along(f[1] as Vector3), 0.9, "")


## Dreapta de dupa pod, pana la strada lui A.
func _straight() -> void:
	# Stanga (exterior): primul rand neregulat de copaci, 20-30 m de ax.
	var s := S_BR_OUT + 14.0
	while s < S_A - 4.0:
		var f := _frame(s)
		var right: Vector3 = f[2]
		var lat := _rng.randf_range(20.0, 30.0)
		var p: Vector3 = (f[0] as Vector3) - right * lat
		var r := _rng.randf()
		var tm: String = "niwaki_pine" if r < 0.25 else ("ginkgo" if r < 0.35 else MAPLES[_rng.randi_range(0, 2)])
		_raw(tm, "plants", "hDreaptaCopac", Vector3(p.x, _sol_real(p.x, p.z) - 0.05, p.z),
			_yaw_x_along(f[1] as Vector3) + _rng.randf_range(-0.4, 0.4), _rng.randf_range(0.85, 1.1), "")
		if _rng.randf() < 0.6:
			var q: Vector3 = (f[0] as Vector3) - right * (lat + _rng.randf_range(9.0, 15.0)) + (f[1] as Vector3) * _rng.randf_range(-5.0, 5.0)
			_raw(MAPLES[_rng.randi_range(0, 2)], "plants", "hDreaptaCopac", Vector3(q.x, _sol_real(q.x, q.z) - 0.05, q.z),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.85, 1.1), "")
		if _rng.randf() < 0.4:
			var lp: Vector3 = (f[0] as Vector3) - right * (lat - 5.0)
			_raw("leaf_pile", "props", "hFrunze", Vector3(lp.x, _sol_real(lp.x, lp.z) - 0.05, lp.z),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.1), "")
		s += _rng.randf_range(10.0, 16.0)
	# Dreapta (interior, spre orasul lui A): rar, 15-24 m de ax.
	s = S_BR_OUT + 22.0
	while s < S_A - 6.0:
		var f := _frame(s)
		var p: Vector3 = (f[0] as Vector3) + (f[2] as Vector3) * _rng.randf_range(15.0, 24.0)
		var tm2: String = MAPLES[_rng.randi_range(0, 2)] if _rng.randf() < 0.75 else "niwaki_pine"
		_raw(tm2, "plants", "hDreaptaCopac",
			Vector3(p.x, _sol_real(p.x, p.z) - 0.05, p.z), _yaw_x_along(f[1] as Vector3), _rng.randf_range(0.8, 1.0), "")
		s += _rng.randf_range(20.0, 30.0)
	# Felinare de piatra alternand partile, la hw + 4 (ritmul spre strada).
	var k := 0
	s = S_BR_OUT + 30.0
	while s < S_A - 2.0:
		var side := -1.0 if k % 2 == 0 else 1.0
		var f := _frame(s)
		var right: Vector3 = f[2]
		var p: Vector3 = (f[0] as Vector3) + right * (side * (HW + 4.0))
		_raw("stone_lantern_b" if k % 3 == 1 else "stone_lantern_a", "props", "hDreaptaFelinar",
			Vector3(p.x, _sol_min(p.x, p.z, 0.65) - 0.05, p.z), _yaw_face(-right * side), 1.0, "")
		k += 1
		s += 22.0


## Incinta de templu pe stanga (exterior), la s -158..-130: doua module de
## zid paralele cu drumul la hw + 9, poarta (gol de 6 m) intre ele, felinare
## la poarta, artari in spate si un altar mic.
func _temple() -> void:
	var s0 := -158.0
	for i in 2:
		var sc := s0 + 4.0 + float(i) * 14.0
		var f := _frame(sc)
		var tan: Vector3 = f[1]
		var right: Vector3 = f[2]
		var p: Vector3 = (f[0] as Vector3) - right * (HW + 9.0)
		_raw("temple_wall", "structures", "hTempluZid", Vector3(p.x, _sol_min(p.x, p.z, 4.0) - 0.15, p.z),
			atan2(tan.x, tan.z), 1.0, "")
	var fm := _frame(s0 + 11.0)
	var rt: Vector3 = fm[2]
	var tn: Vector3 = fm[1]
	var gate: Vector3 = (fm[0] as Vector3) - rt * (HW + 9.0)
	for dx in [-2.2, 2.2]:
		var lp: Vector3 = gate + tn * dx + rt * 1.6
		_raw("stone_lantern_b", "props", "hTempluFelinar", Vector3(lp.x, _sol_min(lp.x, lp.z, 0.65) - 0.05, lp.z),
			_yaw_face(rt), 1.0, "")
	var sh: Vector3 = gate - rt * 10.0
	_raw("small_shrine", "structures", "hTempluAltar", Vector3(sh.x, _sol_min(sh.x, sh.z, 1.8) - 0.05, sh.z),
		_yaw_face(rt), 1.0, "")
	for it in [[-8.0, 6.0], [7.0, 7.0], [-3.0, 15.0], [5.0, 17.0]]:
		var q: Vector3 = gate + tn * float(it[0]) - rt * float(it[1])
		_raw(MAPLES[_rng.randi_range(0, 2)], "plants", "hTempluArtar", Vector3(q.x, _sol_real(q.x, q.z) - 0.05, q.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.85, 1.0), "")


## ------------------------------------------------------------ runda 2
## Partea DREAPTA a dreptei (interiorul buclei) era camp gol intre drum si
## orasul lui A (`OrasVechi`, x >= 32). Tranzitia: o incinta de templu fara
## zid (felinare in pereche, altar, artari) la hw + 10, apoi case machiya in siruri (CityFill `row_mode`) care se pierd
## spre interior, de la 26 m de banda pana la orasul lui A, cu curti cu artari.
## Nordul (z > 186) e pata de ginkgo H (PadureMasa), sudul (z < 80) e strada lui
## A. Linia de vedere spre pagoda (<= 5 m de ax pe ultima treime) nu e atinsa:
## nimic din dreapta nu e la < 15 m de ax.
const TOWN_H := [Vector2(-34.0, 186.0), Vector2(31.0, 186.0), Vector2(31.0, 80.0),
	Vector2(-4.0, 80.0)]
const MM_ROAD_M := 15.0
const NODE_ONLY := ["stone_lantern_a", "stone_lantern_b", "temple_wall", "small_shrine"]
const NO_BODY := ["leaf_pile", "karikomi_shrub_a", "karikomi_shrub_b"]
var _cf_lines: Array[String] = []
var _mm_models: Array[String] = []
var _mm_xf := PackedFloat32Array()


func _mm_add(stem: String, folder: String, b: Basis, pos: Vector3) -> void:
	if not _mm_models.has(stem):
		_mm_models.append(stem)
		_res_id(stem, "res://assets/models/kyoto/%s/%s.glb" % [folder, stem])
	for v in [float(_mm_models.find(stem)), b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z,
			b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z]:
		_mm_xf.append(v)


func _mm_lines() -> Array[String]:
	var out: Array[String] = []
	if _mm_xf.is_empty():
		return out
	var ms: Array[String] = []
	for m in _mm_models:
		ms.append('ExtResource("poih_%s")' % m)
	var vs: Array[String] = []
	for v in _mm_xf:
		vs.append("%.5f" % v)
	out.append('[node name="FaraCorpH" type="Node3D" parent="."]')
	out.append('script = ExtResource("poih_cityfill")')
	out.append("models = Array[PackedScene]([%s])" % ", ".join(ms))
	out.append("indigo_ratio = 0.0")
	out.append("explicit_xforms = PackedFloat32Array(%s)" % ", ".join(vs))
	out.append("")
	return out


## Incinta de templu pe dreapta, la s -117 (runda 3: FARA zid - zidul alb
## jos, vazut oblic din camera de 10 m, iesea placi albe rupte/inclinate, ca
## la A si B). Incinta se citeste prin felinare de piatra in pereche la
## poarta, un altar mic in ax si artari in jur.
func _temple_right() -> void:
	var fm := _frame(-117.0)
	var rt: Vector3 = fm[2]
	var tn: Vector3 = fm[1]
	var gate: Vector3 = (fm[0] as Vector3) + rt * (HW + 10.0)
	for dx in [-2.4, 2.4]:
		for dd in [-1.6, 3.4]:
			var lp: Vector3 = gate + tn * dx + rt * dd
			_raw("stone_lantern_b" if dd > 0.0 else "stone_lantern_a", "props", "hTempluDFelinar",
				Vector3(lp.x, _sol_min(lp.x, lp.z, 0.65) - 0.05, lp.z), _yaw_face(-rt), 1.0, "")
	var sh: Vector3 = gate + rt * 9.0
	_raw("small_shrine", "structures", "hTempluDAltar", Vector3(sh.x, _sol_min(sh.x, sh.z, 1.8) - 0.05, sh.z),
		_yaw_face(-rt), 1.0, "")
	for it in [[-8.0, 6.0], [8.0, 7.0], [-5.0, 15.0], [6.0, 16.0]]:
		var q: Vector3 = gate + tn * float(it[0]) + rt * float(it[1])
		_raw(MAPLES[_rng.randi_range(0, 2)], "plants", "hTempluDArtar", Vector3(q.x, _sol_real(q.x, q.z) - 0.05, q.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 0.95), "")


## Casele dintre drum si orasul lui A: CityFill row_mode pe TOWN_H, cu curti
## (exclude_xz, raza 5 m) care primesc cate un artar/ginkgo.
func _town() -> void:
	var models := ["machiya_a", "machiya_b", "machiya_c", "machiya_d", "machiya_e"]
	for m in models:
		_res_id(m, "res://assets/models/kyoto/buildings/%s.glb" % m)
	var poly := PackedVector2Array(TOWN_H)
	var courts: Array[Vector3] = []
	var tries := 0
	while courts.size() < 7 and tries < 4000:
		tries += 1
		var c := Vector2(_rng.randf_range(-34.0, 31.0), _rng.randf_range(80.0, 186.0))
		if not Geometry2D.is_point_in_polygon(c, poly) or _road_dist(c.x, c.y) < 30.0:
			continue
		var ok := true
		for q in courts:
			if c.distance_to(Vector2(q.x, q.y)) < 16.0:
				ok = false
				break
		if ok:
			courts.append(Vector3(c.x, c.y, 5.0))
	var trees := ["momiji_a", "momiji_b", "momiji_c", "momiji_b", "ginkgo"]
	for q in courts:
		_raw(trees[_rng.randi_range(0, trees.size() - 1)], "plants", "hOrasCopac",
			Vector3(q.x, _sol_real(q.x, q.y) - 0.05, q.y), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.75, 0.9), "")
	var ms: Array[String] = []
	for m in models:
		ms.append('ExtResource("poih_%s")' % m)
	var pv: Array[String] = []
	for q in poly:
		pv.append("%.1f, %.1f" % [q.x, q.y])
	var ev: Array[String] = []
	for e in courts:
		ev.append("%.1f, %.1f, %.1f" % [e.x, e.y, e.z])
	_cf_lines.append('[node name="OrasDreaptaH" type="Node3D" parent="."]')
	_cf_lines.append('script = ExtResource("poih_cityfill")')
	_cf_lines.append("models = Array[PackedScene]([%s])" % ", ".join(ms))
	_cf_lines.append("weights = PackedFloat32Array(0.2, 0.2, 0.2, 0.2, 0.2)")
	_cf_lines.append("indigo_ratio = 0.0")
	_cf_lines.append("row_mode = true")
	_cf_lines.append("min_road_m = 26.0")
	_cf_lines.append("seed_value = 20261018")
	_cf_lines.append("exclude_xz = PackedVector3Array(%s)" % ", ".join(ev))
	_cf_lines.append("region_xz = PackedVector2Array(%s)" % ", ".join(pv))
	_cf_lines.append("")
	print("; oras dreapta H: %d curti" % courts.size())


## Cota minima a solului sub o amprenta patrata de semilatura r.
func _sol_min(x: float, z: float, r: float) -> float:
	var m := _sol_real(x, z)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]:
		m = minf(m, _sol_real(x + d.x, z + d.y))
	return m


# ------------------------------------------------------------------ iesire

func _res_id(stem: String, path: String) -> String:
	if not _ext.has(stem):
		_ext[stem] = path
	return "poih_" + stem


func _raw(stem: String, folder: String, base: String, pos: Vector3, yaw: float,
		scl: float, mode: String) -> void:
	var path := "res://assets/models/kyoto/%s/%s.glb" % [folder, stem]
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	# Runda 2 (coordonator: +476 desene in r1, tinta <= +150): tot ce nu are
	# corp, sau sta la >= MM_ROAD_M de drum, intra in MultiMesh-ul unui
	# CityFill `explicit_xforms` (fara corp). Raman noduri doar felinarele,
	# zidurile, altarul si ce e la < 15 m de banda.
	if mode == "" and not NODE_ONLY.has(stem) 			and (NO_BODY.has(stem) or _road_dist(pos.x, pos.z) >= MM_ROAD_M):
		_mm_add(stem, folder, b, pos)
		return
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, _res_id(stem, path)])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	var lines: Array[String] = [";;EXT"]
	var stems := _ext.keys()
	stems.sort()
	for s in stems:
		lines.append('[ext_resource type="PackedScene" path="%s" id="poih_%s"]' % [_ext[s], s])
	lines.append('[ext_resource type="Script" path="res://scenes/props/path_mover.gd" id="poih_pathmover"]')
	lines.append('[ext_resource type="Script" path="res://scenes/props/city_fill.gd" id="poih_cityfill"]')
	lines.append(";;NODES")
	lines.append('[node name="ZoneH_Togetsukyo" type="Node3D" parent="DecorManual"]')
	lines.append("")
	lines.append_array(_out)
	lines.append_array(_boat_lines)
	lines.append_array(_mm_lines())
	lines.append_array(_cf_lines)
	print("; asezate %d piese (%d in MultiMesh), %d modele" % [_n, _mm_xf.size() / 13, stems.size()])
	if _out_path.is_empty():
		for l in lines:
			print(l)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for l in lines:
		fa.store_line(l)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, 200.0, z), Vector3(x, -200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _track._sampler.ground_y(x, z)
