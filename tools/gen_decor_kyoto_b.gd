extends Node
## Generator de decor MANUAL pentru POI B — SANNENZAKA (Track18, Kyoto,
## frac 0,055-0,20: iesirea din ocolul pagodei, cele doua S-uri stranse si
## urcarea spre poarta Niomon a lui C). Tiparul gen_decor_kyoto_a.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoB.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoB.tscn -- \
##       --out=tools/kyoto_decor/poi_b.part
##
## Iesirea (`;;EXT` + `;;NODES`) o lipeste tools/gen_kyoto_route.py in
## Track18.tscn (blocul DECOR MANUAL), langa poi_a.part.

const TRACK := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneB_Sannenzaka"
const PART_A := "res://tools/kyoto_decor/poi_a.part"

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _ext: Dictionary = {}   # stem -> path
var _n := 0
var _out_path := ""
var _scan := false
var _dbg_path := ""
var _dbg: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--scan":
			_scan = true
		elif a.begins_with("--dbg="):
			_dbg_path = a.trim_prefix("--dbg=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_prep()
	if _scan:
		_do_scan()
		get_tree().quit(0)
		return
	_rng.seed = 41026
	_build()
	_write()
	get_tree().quit(0)


func _do_scan() -> void:
	print("; lungime %.1f" % _total)
	var s := 100.0
	while s < 470.0:
		var f := _frame(s)
		var p: Vector3 = f[0]
		var hw: float = f[3]
		var right: Vector3 = f[2]
		var k := _turn(s)
		var line := "s %5.1f f %.4f (%.1f, %.2f, %.1f) hw %.1f R %+6.0f  sol:" % [
			s, s / _total, p.x, p.y, p.z, hw, (1.0 / k if absf(k) > 0.0005 else 9999.0)]
		for lat in [-34.0, -22.0, -14.0, -9.0, 9.0, 14.0, 22.0, 34.0]:
			var q: Vector3 = p + right * (signf(lat) * hw + lat)
			line += " %+.0f:%.1f" % [lat, _sol_real(q.x, q.z) - p.y]
		print(line)
		s += 6.0
	for ss in [210.0, 220.0, 230.0]:
		var f := _frame(ss)
		for lat in [0.5, 1.0, 1.75, 2.5, 3.5, 4.5]:
			var q: Vector3 = (f[0] as Vector3) + (f[2] as Vector3) * ((f[3] as float) + lat)
			var hits := _hits(q.x, q.z)
			print("; s %.0f bordura+%.2f teren %.3f drum %.3f | %s" % [ss, lat, _sol_real(q.x, q.z), (f[0] as Vector3).y, str(hits)])


# ------------------------------------------------------------- geometria

var _cum: PackedFloat32Array
var _total := 0.0
var _a_obstacles: Array[Vector3] = []     # (x, z, raza) din poi_a.part
var _placed: Array[PackedVector2Array] = []  # amprentele cu corp, ale lui B


func _prep() -> void:
	var pts := _track.baked
	_cum.resize(pts.size() + 1)
	_cum[0] = 0.0
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		_cum[i + 1] = _cum[i] + Vector2(b.x - a.x, b.z - a.z).length()
	_total = _cum[pts.size()]
	_read_a()


## Piesele lui A, ca obstacole (centru + raza): nu le dublam si nu intram in
## ele. Raza dupa tipul piesei.
func _read_a() -> void:
	var fa := FileAccess.open(PART_A, FileAccess.READ)
	if fa == null:
		return
	var stem := ""
	for l in fa.get_as_text().split("\n"):
		if l.begins_with("[node ") and l.contains("ExtResource(\"poia_"):
			stem = l.get_slice("ExtResource(\"poia_", 1).get_slice("\"", 0)
		elif l.begins_with("transform = Transform3D(") and stem != "":
			var v := l.trim_prefix("transform = Transform3D(").trim_suffix(")").split(",")
			var x := float(v[9])
			var z := float(v[11])
			var r := 1.0
			if stem == "yasaka_pagoda":
				r = 12.0
			elif stem.begins_with("machiya"):
				r = 4.0
			elif stem.begins_with("momiji") or stem == "ginkgo":
				r = 3.0
			elif stem == "temple_wall":
				r = 4.0
			elif stem == "teahouse_front":
				r = 2.5
			_a_obstacles.append(Vector3(x, z, r))
			stem = ""


## Cadrul drumului la distanta s de linia de start: [pozitie, tangenta,
## dreapta, semilatime].
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


## Curbura cu semn (1/m) pe o fereastra de 8 m: < 0 = viraj la dreapta.
func _turn(s: float) -> float:
	var t0: Vector3 = _frame(s - 4.0)[1]
	var t1: Vector3 = _frame(s + 4.0)[1]
	return t0.cross(t1).y / 8.0


## Cel mai strans viraj (raza minima) pe [s-span, s+span], cu semn.
func _tight(s: float, span: float) -> float:
	var best := 0.0
	var q := s - span
	while q <= s + span:
		var k := _turn(q)
		if absf(k) > absf(best):
			best = k
		q += 2.0
	return best


## Marja de la bordura (m) a unui punct: distanta la axa cea mai apropiata
## (orice ruta) minus semilatimea acolo. Pozitiv = in afara carosabilului.
func _clear(x: float, z: float) -> float:
	var best := INF
	for r: TrackRoute in _track.routes:
		var b: PackedVector3Array = r.baked
		var n := b.size()
		for i in n:
			var d := Vector2(b[i].x - x, b[i].z - z).length()
			if d - 12.0 > best:
				continue
			var hw: float = _track.width_at_index(i) if r == _track.routes[0] else 3.2
			best = minf(best, d - hw)
	return best


## Amprenta (4 colturi XZ) a unui dreptunghi l x a, centrat in p, rotit cu yaw.
func _rect(p: Vector3, yaw: float, w: float, d: float) -> PackedVector2Array:
	var ax := Vector2(cos(yaw), -sin(yaw))       # +X local in XZ
	var az := Vector2(sin(yaw), cos(yaw))        # +Z local in XZ
	var c := Vector2(p.x, p.z)
	var out := PackedVector2Array()
	for sg in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		out.append(c + ax * (sg.x * w * 0.5) + az * (sg.y * d * 0.5))
	return out


func _rect_clear(poly: PackedVector2Array) -> float:
	var m := INF
	for q in poly:
		m = minf(m, _clear(q.x, q.y))
	# si mijloacele laturilor (pe viraj, mijlocul fetei e mai aproape)
	for i in 4:
		var q := (poly[i] + poly[(i + 1) % 4]) * 0.5
		m = minf(m, _clear(q.x, q.y))
	return m


func _overlaps(poly: PackedVector2Array, shrink: float) -> bool:
	var sp := Geometry2D.offset_polygon(poly, -shrink)
	if sp.is_empty():
		return false
	var p0: PackedVector2Array = sp[0]
	for o in _placed:
		if not Geometry2D.intersect_polygons(p0, o).is_empty():
			return true
	var c := Vector2.ZERO
	for q in poly:
		c += q * 0.25
	for e in _a_obstacles:
		if c.distance_to(Vector2(e.x, e.y)) < e.z + 2.6:
			return true
	return false


## yaw care intoarce -Z local spre directia d (orizontala).
func _yaw_face(d: Vector3) -> float:
	return atan2(-d.x, -d.z)


## yaw care duce +X local pe directia d (orizontala).
func _yaw_x_along(d: Vector3) -> float:
	return atan2(-d.z, d.x)


## ------------------------------------------------------------------------
## DECIZIILE (randul B din docs/track_briefs/kyoto.md §2, fractii reale din
## gen_kyoto_route.py: colt pagoda 0,085, S1 0,129/0,146, S2 0,162/0,174,
## Niomon 0,207; semilatimea 5,5 pe 0,055-0,174).
##
## - RANDURILE DE MACHIYA continua pe ambele parti de unde le lasa A (dreapta
##   s 150, stanga s 186 + gradina pagodei) pana la s ~402, cu ~40 m liberi
##   inaintea portii Niomon (C). Fiecare casa se aseaza pe cadrul local al
##   drumului si se TESTEAZA, nu se presupune: miezul cu corp (Machiya_Wood,
##   6,28 x 5,32) trebuie sa ramana la >= CLEAR_HOUSE m de bordura masurat pe
##   colturi si pe mijlocul laturilor, fata de orice ruta. Pe exteriorul unui
##   viraj strans casa se trage inapoi (pana la +4 m), altfel slotul se sare.
##   Astfel nimic cu corp nu sta in exteriorul S-urilor la < hw + 3.
## - CEAINARII in trei grupuri (dreapta la iesirea din colt, stanga dupa S1,
##   dreapta inainte de C): `teahouse_front` (banca + umbrela rosie) in fata,
##   cu fata la >= 3,2 m de bordura, iar casa (machiya a/b, cele cu noren) se
##   trage inapoi cu 3 m, ca ceainaria sa-i fie curte.
## - FELINARE DE HARTIE la bordura + 2,1, dar NU pe exteriorul virajelor
##   (acolo >= 3,2).
## - TREPTELE SANNENZAKA pe dreapta, pe trotuar, PARALEL cu strada: terenul
##   urca odata cu drumul (6,4%), deci treapta e o lespede ORIZONTALA de
##   2,4 m al carei capat din vale iese ~0,15 m peste sol -> trotuar in trepte.
##   Lespedea e `cyclopean_wall` turtit (piatra cu muschi a kitului, fara asset
##   nou); coliziune `none` CU MOTIV: e o treapta de 0,2 m pe trotuar, un hull
##   ar fi un prag de bordura in care se agata masina iesita din drum.
## - RICSA (`jinrikisha`) statica pe trotuarul din dreapta, cu fata la deal,
##   coliziune `none`: PathMover face corp solid mereu (AnimatableBody3D, fara
##   optiune), iar contractul cere teatru fara coliziune -> propunere in raport.
## - RANDUL DOI (fara corp) la +8 m; pe dreapta (interiorul buclei) si randul
##   trei la +16, pana la CityFill-ul lui A (care incepe la 32 m de drum).

const HOUSES := ["machiya_a", "machiya_b", "machiya_c", "machiya_d", "machiya_e"]
const WALL_FACE := 3.4
const HOUSE_FRONT_Z := 2.66
const HOUSE_W := 6.28
const HOUSE_D := 5.32
const CLEAR_HOUSE := 3.2     # miezul cu corp fata de bordura, minim
const CLEAR_OUT := 3.2       # orice corp pe exteriorul unui viraj strans
const LANTERN_OFF := 2.1
const COURT_W := 8.6
const S0 := 150.0
const S1 := 424.0   # ~16 m inaintea portii Niomon (s ~440, C)
# Grupurile de ceainarii: [side, s_de_la, s_pana_la]
const TEA := [[1.0, 196.0, 232.0], [-1.0, 300.0, 330.0], [1.0, 372.0, 400.0]]
const STAIRS := [204.0, 244.0]   # treptele, pe dreapta
const RICKSHAW_S := 306.0


func _build() -> void:
	for side in [1.0, -1.0]:
		_row(side)
	for side in [1.0, -1.0]:
		_row_back(side, 8.0, "bCasaSpate")
	_row_back(1.0, 16.0, "bCasaRand3")
	_stairs()
	_stair_lanterns()
	_rickshaw()
	_leaves()
	_town()


func _in_tea(side: float, s: float) -> bool:
	for t in TEA:
		if float(t[0]) == side and s >= float(t[1]) and s <= float(t[2]):
			return true
	return false


## E punctul (din partea `side`) pe exteriorul unui viraj strans (R < 60 m)?
func _outside(side: float, s: float) -> bool:
	var k := _tight(s, 10.0)
	return absf(k) > 1.0 / 60.0 and side * k > 0.0


func _pick_house(prev: String, pool: Array) -> String:
	var m := prev
	var guard := 0
	while m == prev and guard < 20:
		m = pool[_rng.randi_range(0, pool.size() - 1)]
		guard += 1
	return m


## Randul intai pe o parte (+1 dreapta/sud, -1 stanga/nord).
func _row(side: float) -> void:
	# Stanga (exteriorul coltului) e gradina pagodei pana la s ~200: nimic
	# intre drum si baza ei (cadrul de iesire din ocol o arata intreaga).
	var s := S0 if side > 0.0 else 200.0
	var prev := ""
	var since_court := 0
	var court_every := _rng.randi_range(3, 5)
	var house_i := 0
	while s < S1:
		var tea := _in_tea(side, s)
		if not tea and since_court >= court_every:
			if _court(s + COURT_W * 0.5, side):
				s += COURT_W
				since_court = 0
				court_every = _rng.randi_range(3, 5)
				continue
		var pool: Array = ["machiya_a", "machiya_b"] if tea else HOUSES
		var m := _pick_house(prev, pool)
		var w := HOUSE_W + (0.32 if m == "machiya_e" else 0.0)
		var sc := s + w * 0.5
		var f := _frame(sc)
		var hw: float = f[3]
		var right: Vector3 = f[2]
		var yaw := _yaw_face(-right * side) + _rng.randf_range(-0.015, 0.015)
		var back := 3.0 if tea else 0.0
		var placed := false
		var extra := 0.0
		while extra <= 4.0:
			var lat := hw + WALL_FACE + back + extra + HOUSE_FRONT_Z + _rng.randf_range(0.0, 0.2)
			var p: Vector3 = (f[0] as Vector3) + right * (side * lat)
			var poly := _rect(p, yaw, w, HOUSE_D)
			if _rect_clear(poly) >= CLEAR_HOUSE + back and not _overlaps(poly, 0.25):
				var y := _sol_min(p.x, p.z, 2.6)
				_raw(m, "buildings", "bCasa", Vector3(p.x, y - 0.08, p.z), yaw, Vector3.ONE, "")
				_placed.append(poly)
				placed = true
				if tea:
					_teahouse(f, side, lat - HOUSE_FRONT_Z - 1.75)
				break
			extra += 1.0
		if not placed:
			s += 1.5
			continue
		if not tea and (house_i + (0 if side > 0.0 else 1)) % 2 == 0:
			_lantern(sc + 1.9, side)
		prev = m
		house_i += 1
		since_court += 1
		s += w + _rng.randf_range(0.04, 0.18)


func _lantern(s: float, side: float) -> void:
	var f := _frame(s)
	var hw: float = f[3]
	var tan: Vector3 = f[1]
	var right: Vector3 = f[2]
	var out := _outside(side, s)
	var off := CLEAR_OUT if out else LANTERN_OFF
	var lp: Vector3 = (f[0] as Vector3) + right * (side * (hw + off))
	var need := (CLEAR_OUT - 0.1) if out else 2.05
	if _clear(lp.x, lp.z) < need:
		return
	if s >= STAIRS[0] - 2.0 and s <= STAIRS[1] + 2.0 and side > 0.0:
		return
	_raw("paper_lantern", "props", "bFelinar", Vector3(lp.x, _surf(lp.x, lp.z) - 0.05, lp.z),
		_yaw_x_along(-tan), Vector3.ONE, "")


## Ceainaria in fata casei trase inapoi: centrul la `lat` de ax.
func _teahouse(f: Array, side: float, lat: float) -> void:
	var right: Vector3 = f[2]
	var tan: Vector3 = f[1]
	var p: Vector3 = (f[0] as Vector3) + right * (side * lat) + tan * _rng.randf_range(-0.6, 0.6)
	var yaw := _yaw_face(-right * side) + _rng.randf_range(-0.08, 0.08)
	var poly := _rect(p, yaw, 4.2, 3.0)
	if _rect_clear(poly) < CLEAR_OUT:
		return
	_raw("teahouse_front", "props", "bCeainarie", Vector3(p.x, _sol_min(p.x, p.z, 2.0) - 0.05, p.z),
		yaw, Vector3.ONE, "")
	_placed.append(poly)


## Curte: zid de templu pe linia fatadei + un copac in spate. false = nu
## incape (viraj) -> slotul ramane casa.
func _court(sc: float, side: float) -> bool:
	var f := _frame(sc)
	var hw: float = f[3]
	var tan: Vector3 = f[1]
	var right: Vector3 = f[2]
	var lat := hw + WALL_FACE + 0.65
	var p: Vector3 = (f[0] as Vector3) + right * (side * lat)
	var wyaw := atan2(tan.x, tan.z)
	var poly := _rect(p, wyaw, 1.22, 8.0)
	if _rect_clear(poly) < CLEAR_HOUSE or _overlaps(poly, 0.2):
		return false
	_raw("temple_wall", "structures", "bCurteZid", Vector3(p.x, _sol_min(p.x, p.z, 4.0) - 0.15, p.z),
		wyaw, Vector3.ONE, "")
	_placed.append(poly)
	var trees := ["momiji_a", "momiji_b", "momiji_c", "momiji_a", "momiji_c", "ginkgo"]
	var tm: String = trees[_rng.randi_range(0, trees.size() - 1)]
	var tp: Vector3 = (f[0] as Vector3) + right * (side * (lat + 3.6))
	var tyaw := _yaw_x_along(tan) + _rng.randf_range(-0.12, 0.12)
	_raw(tm, "plants", "bCurteCopac", Vector3(tp.x, _sol_real(tp.x, tp.z) - 0.05, tp.z), tyaw,
		Vector3.ONE * _rng.randf_range(0.75, 0.85), "")
	var lp: Vector3 = (f[0] as Vector3) + right * (side * (hw + WALL_FACE - 0.9)) + tan * _rng.randf_range(-2.5, 2.5)
	_raw("leaf_pile", "props", "bFrunze", Vector3(lp.x, _surf(lp.x, lp.z) - 0.05, lp.z),
		_rng.randf_range(0.0, TAU), Vector3.ONE * _rng.randf_range(0.8, 1.1), "")
	return true


## Randurile din spate: doar acoperisuri peste primul rand, fara corp.
func _row_back(side: float, back: float, base: String) -> void:
	var s := (S0 if side > 0.0 else 200.0) + _rng.randf_range(0.0, 3.0)
	var prev := ""
	var mine: Array[PackedVector2Array] = []
	while s < S1 - 4.0:
		var m := _pick_house(prev, HOUSES)
		var f := _frame(s + HOUSE_W * 0.5)
		var hw: float = f[3]
		var right: Vector3 = f[2]
		var lat := hw + WALL_FACE + HOUSE_FRONT_Z + back + _rng.randf_range(-0.4, 0.6)
		var p: Vector3 = (f[0] as Vector3) + right * (side * lat)
		var yaw := _yaw_face(-right * side) + _rng.randf_range(-0.03, 0.03)
		var poly := _rect(p, yaw, HOUSE_W, HOUSE_D)
		var ok := _rect_clear(poly) >= CLEAR_HOUSE + 4.0 and not _overlaps(poly, 0.6)
		if ok:
			var sp := Geometry2D.offset_polygon(poly, -0.6)
			for o in mine:
				if not sp.is_empty() and not Geometry2D.intersect_polygons(sp[0], o).is_empty():
					ok = false
					break
		if not ok:
			s += 1.5
			continue
		_raw(m, "buildings", base, Vector3(p.x, _sol_min(p.x, p.z, 2.6) - 0.08, p.z), yaw, Vector3.ONE, "none")
		mine.append(poly)
		prev = m
		s += HOUSE_W + _rng.randf_range(0.05, 0.6)
	for o in mine:
		_placed.append(o)


## Treptele Sannenzaka pe trotuarul din dreapta, PARALEL cu strada. Pe 6,4%
## o treapta pe fiecare lespede de 2,4 m (r1, a doua varianta) dadea contratrepte
## de 0,15 m la 2,4 m una de alta: din camera de 10 m se citea o bordura
## ridicata, nu o scara. Acum: ZBORURI de 5 trepte (0,45 m x 0,16 m, +0,8 m in
## 2,25 m), apoi un PODEST orizontal pana il ajunge trotuarul din urma
## (~9,5 m), apoi alt zbor. Fata dinspre drum a podestului e piatra ciclopica a
## kitului (zid de sprijin care scade spre deal). Cota de pe SUPRAFATA
## trotuarului (corpul `Shoulders`), nu de pe TerrainBody (r1 le ingropase).
const STEP_N := 5
const STEP_T := 0.45
const STEP_H := 0.16
const STAIR_W := 2.3
const STAIR_LAT := 1.85   # mijlocul scarii fata de bordura


func _stairs() -> void:
	var s: float = STAIRS[0]
	while s < float(STAIRS[1]) - 4.0:
		var f0 := _frame(s)
		var hw0: float = f0[3]
		var p0: Vector3 = (f0[0] as Vector3) + (f0[2] as Vector3) * (hw0 + 0.7)
		var base := _surf(p0.x, p0.z)
		for k in STEP_N:
			var sc := s + STEP_T * (float(k) + 0.5)
			_slab(sc, STEP_T, base + STEP_H * float(k + 1))
		s += STEP_T * STEP_N
		var top := base + STEP_H * STEP_N
		# podestul: pana unde trotuarul (langa bordura) urca la top - 0,05
		var e := s
		while e < float(STAIRS[1]):
			var fe := _frame(e + 0.5)
			var pe: Vector3 = (fe[0] as Vector3) + (fe[2] as Vector3) * ((fe[3] as float) + 0.7)
			if _surf(pe.x, pe.z) >= top - 0.05:
				break
			e += 0.5
		if e - s > 0.5:
			_slab((s + e) * 0.5, e - s, top)
		s = e


## O lespede orizontala de lungime `l` centrata la s, cu fata de sus la `top`.
func _slab(sc: float, l: float, top: float) -> void:
	var f := _frame(sc)
	var hw: float = f[3]
	var tan: Vector3 = f[1]
	var right: Vector3 = f[2]
	var p: Vector3 = (f[0] as Vector3) + right * (hw + STAIR_LAT)
	var lo := minf(_sol_real(p.x, p.z), _surf(p.x, p.z))
	var h := maxf(0.6, top - lo + 0.35)
	# +X local al zidului (8 m) pe directia drumului, Z (2,64 m) peste trotuar
	_raw("cyclopean_wall", "structures", "bTreapta", Vector3(p.x, top - h, p.z),
		_yaw_x_along(tan), Vector3(l / 8.0, h / 4.18, STAIR_W / 2.64), "none")


func _stair_lanterns() -> void:
	# felinar de piatra la capatul de jos si la cel de sus, pe linia fatadelor
	for ss in [float(STAIRS[0]) - 1.5, float(STAIRS[1]) + 1.0]:
		var f := _frame(ss)
		var hw: float = f[3]
		var p: Vector3 = (f[0] as Vector3) + (f[2] as Vector3) * (hw + 3.6)
		if _clear(p.x, p.z) >= CLEAR_OUT:
			_raw("stone_lantern_a", "props", "bTreaptaFelinar", Vector3(p.x, _sol_min(p.x, p.z, 0.6) - 0.05, p.z),
				_yaw_face(-(f[2] as Vector3)), Vector3.ONE, "")


func _rickshaw() -> void:
	var f := _frame(RICKSHAW_S)
	var hw: float = f[3]
	var tan: Vector3 = f[1]
	var right: Vector3 = f[2]
	var p: Vector3 = (f[0] as Vector3) + right * (hw + 1.7)
	_raw("jinrikisha", "vehicles", "bRicsa", Vector3(p.x, _surf(p.x, p.z) - 0.02, p.z),
		_yaw_face(tan) + 0.05, Vector3.ONE, "none")


func _leaves() -> void:
	for k in 10:
		var s := _rng.randf_range(S0 + 20.0, S1 - 10.0)
		var side := -1.0 if k % 2 == 0 else 1.0
		var f := _frame(s)
		var hw: float = f[3]
		var p: Vector3 = (f[0] as Vector3) + (f[2] as Vector3) * (side * (hw + _rng.randf_range(0.9, 2.2)))
		_raw("leaf_pile", "props", "bFrunze", Vector3(p.x, _surf(p.x, p.z) - 0.05, p.z),
			_rng.randf_range(0.0, TAU), Vector3.ONE * _rng.randf_range(0.7, 1.0), "")


func _sol_min(x: float, z: float, r: float) -> float:
	var m := _sol_real(x, z)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]:
		m = minf(m, _sol_real(x + d.x, z + d.y))
	return m


# ------------------------------------------------------------------ iesire

func _res_id(stem: String, path: String) -> String:
	if not _ext.has(stem):
		_ext[stem] = path
	return "poib_" + stem


func _raw(stem: String, folder: String, base: String, pos: Vector3, yaw: float,
		scl: Vector3, mode: String) -> void:
	var path := "res://assets/models/kyoto/%s/%s.glb" % [folder, stem]
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(scl)
	_n += 1
	_dbg.append("P %s %s %.2f %.2f %.4f %.3f" % [stem, base, pos.x, pos.z, yaw, scl.x])
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, _res_id(stem, path)])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


## ORASUL DIN SPATE (runda 1): doua `CityFill` in row_mode, ca la A, pe
## benzile ramase goale intre randurile lui B si orasele lui A (capturile r1
## aratau iarba pana la padure in spatele randului doi):
##  * nord: intre randul doi (~20 m de ax) si OrasPagoda (z -236..-246), plus
##    tot cartierul dintre x 175 si 225 (OrasPagoda se opreste la x 175);
##  * sud: intre randul trei (~28 m) si OrasVechi (z -150), x 25..235.
## x <= 225/235: dincolo e poarta Niomon si versantul lui C.
const TOWN_N := [Vector2(30, -200), Vector2(225, -200), Vector2(225, -300),
	Vector2(175, -300), Vector2(175, -246), Vector2(40, -236), Vector2(30, -236)]
const TOWN_S := [Vector2(25, -150), Vector2(170, -150), Vector2(235, -143),
	Vector2(235, -200), Vector2(25, -200)]

var _cf_lines: Array[String] = []


func _town() -> void:
	for m in HOUSES:
		_res_id(m, "res://assets/models/kyoto/buildings/%s.glb" % m)
	_cityfill("OrasSannenzakaN", PackedVector2Array(TOWN_N), 25.0, 20261013)
	_cityfill("OrasSannenzakaS", PackedVector2Array(TOWN_S), 33.0, 20261014)


func _cityfill(nm: String, poly: PackedVector2Array, min_road: float, sd: int) -> void:
	var ms: Array[String] = []
	for m in HOUSES:
		ms.append('ExtResource("poib_%s")' % m)
	var pv: Array[String] = []
	for q in poly:
		pv.append("%.1f, %.1f" % [q.x, q.y])
	_cf_lines.append('[node name="%s" type="Node3D" parent="."]' % nm)
	_cf_lines.append('script = ExtResource("poib_cityfill")')
	_cf_lines.append("models = Array[PackedScene]([%s])" % ", ".join(ms))
	_cf_lines.append("weights = PackedFloat32Array(0.2, 0.2, 0.2, 0.2, 0.2)")
	_cf_lines.append("indigo_ratio = 0.0")
	_cf_lines.append("row_mode = true")
	_cf_lines.append("min_road_m = %.1f" % min_road)
	_cf_lines.append("seed_value = %d" % sd)
	_cf_lines.append("region_xz = PackedVector2Array(%s)" % ", ".join(pv))
	_cf_lines.append("")


func _write() -> void:
	var lines: Array[String] = [";;EXT"]
	var stems := _ext.keys()
	stems.sort()
	for s in stems:
		lines.append('[ext_resource type="PackedScene" path="%s" id="poib_%s"]' % [_ext[s], s])
	lines.append('[ext_resource type="Script" path="res://scenes/props/city_fill.gd" id="poib_cityfill"]')
	lines.append(";;NODES")
	lines.append('[node name="ZoneB_Sannenzaka" type="Node3D" parent="DecorManual"]')
	lines.append("")
	lines.append_array(_out)
	lines.append_array(_cf_lines)
	print("; asezate %d piese, %d modele" % [_n, stems.size()])
	if not _dbg_path.is_empty():
		var fd := FileAccess.open(_dbg_path, FileAccess.WRITE)
		for r: TrackRoute in _track.routes:
			var b: PackedVector3Array = r.baked
			for i in b.size():
				var hw: float = _track.width_at_index(i) if r == _track.routes[0] else 3.2
				fd.store_line("R %.2f %.2f %.2f" % [b[i].x, b[i].z, hw])
		for l in _dbg:
			fd.store_line(l)
		fd.close()
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


## Cota suprafetei pe care se calca: trotuarul (`Shoulders`) daca e acolo,
## altfel terenul.
func _surf(x: float, z: float) -> float:
	for h in _hits(x, z):
		if String(h[0]) == "Shoulders" or String(h[0]) == "TerrainBody":
			return float(h[1])
	return _sol_real(x, z)


## Toate corpurile de sub un punct (sus -> jos): [nume, y].
func _hits(x: float, z: float) -> Array:
	var out := []
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 200.0, z), Vector3(x, -200.0, z))
	q.collide_with_areas = false
	for k in 8:
		var hit: Dictionary = _space.intersect_ray(q)
		if hit.is_empty():
			break
		var c: Object = hit["collider"]
		out.append([str((c as Node).name) if c is Node else "?", snappedf(float(hit["position"].y), 0.001)])
		q.exclude = q.exclude + [hit["rid"]]
	return out


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
