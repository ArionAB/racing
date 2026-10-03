extends Node
## Generator de decor MANUAL pentru POI A — STARTUL PE YASAKA-DORI (Track18,
## Kyoto, frac 0,00-0,05 + capatul dreptei H, grila). Tiparul gen_decor_jod_a.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoA.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoA.tscn -- \
##       --out=tools/kyoto_decor/poi_a.part
##
## Fisierul .part are doua sectiuni (`;;EXT` si `;;NODES`) pe care
## tools/gen_kyoto_route.py le lipeste in Track18.tscn (blocul DECOR MANUAL):
## generatorul traseului rescrie tot .tscn-ul, deci decorul trebuie sa
## supravietuiasca regenerarii prin el, nu langa el.

const TRACK := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneA_Yasaka"

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _ext: Dictionary = {}   # stem -> id
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
	if _scan:
		await _do_scan()
		get_tree().quit(0)
		return
	_rng.seed = 31026
	_build()
	_write()
	get_tree().quit(0)


func _do_scan() -> void:
	var pts := _track.baked
	var n := pts.size()
	print("; baked %d, lungime %.0f" % [n, _track.route_at(0).length()])
	for i in n:
		var f := float(i) / float(n)
		if f > 0.065 and f < 0.90:
			continue
		var p: Vector3 = pts[i]
		var hw := _track.width_at(f)
		var line := "i %4d f %.4f  (%.1f, %.2f, %.1f) hw %.1f  sol:" % [i, f, p.x, p.y, p.z, hw]
		for lat in [-24.0, -16.0, -12.0, -10.0, 10.0, 12.0, 16.0, 24.0]:
			line += " %+.0f:%.2f" % [lat, _sol_real(p.x + lat, p.z) - p.y]
		print(line)
	for q in [Vector2(4, -200), Vector2(0, -200), Vector2(4, -210), Vector2(-10, -200), Vector2(14, -200)]:
		print("; sol la (%.0f, %.0f): %.2f" % [q.x, q.y, _sol_real(q.x, q.y)])
	await _scan_map()


## Harta pe celule de 20 m: R = banda la < 30 m, T = copaci (PadureMasa),
## ~ = sol sub cota drumului cu > 2 m (apa/rapa), . = liber; cota in zecimi.
func _scan_map() -> void:
	var forest0 := _track.get_node_or_null("PadureMasa")
	for k in 900:
		if forest0 != null and bool(forest0.get("done")):
			break
		await get_tree().process_frame
	# Pozitiile copacilor din ocuparea lui MeshForest (transformarile citite din
	# MultiMesh ies (0,0,0) headless: memoria multimesh-masuratoare-moarta).
	var trees := PackedVector2Array()
	var forest := _track.get_node_or_null("PadureMasa")
	if forest != null:
		var occ: Dictionary = forest.get("_occ")
		# Valorile din _occ ies goale (append pe copia unui PackedVector2Array in
		# mesh_forest._occupy), dar CHEILE sunt celulele de 2 m ocupate.
		for k in occ:
			trees.append(Vector2((k as Vector2i).x * 2.0 + 1.0, (k as Vector2i).y * 2.0 + 1.0))
	print("; copaci: %d (inst %s, occ %s)" % [trees.size(), str(forest.get("instance_count")), str((forest.get("_occ") as Dictionary).size())])
	var cell := 20.0
	var hdr := "      "
	for gx in range(-60, 440, 20):
		hdr += "%-1s" % ("|" if gx % 100 == 0 else " ")
	print(hdr)
	for gz in range(-280, 480, 20):
		var line := "%5d " % gz
		for gx in range(-60, 440, 20):
			var c := Vector2(gx + 10, gz + 10)
			var ch := "."
			var near := INF
			var ny := 0.0
			for p in _track.baked:
				var d := c.distance_to(Vector2(p.x, p.z))
				if d < near:
					near = d
					ny = p.y
			var nt := 0
			for t in trees:
				if absf(t.x - c.x) < cell * 0.5 and absf(t.y - c.y) < cell * 0.5:
					nt += 1
			if near < 30.0:
				ch = "R"
			elif nt > 0:
				ch = "T"
			elif _sol_real(c.x, c.y) < ny - 2.0:
				ch = "~"
			line += ch
		print(line)


## ------------------------------------------------------------------------
## DECIZIILE (randul A din docs/track_briefs/kyoto.md §2 si §2.0)
##
## - PAGODA YASAKA pe axa strazii, la (4, -200) = PAGODA_XY din
##   tools/gen_kyoto_route.py (garda de azimut a traseului o foloseste deja),
##   baza pe solul real (+4,2), fata parterului (-Z GLB) spre start (yaw 180).
##   Ocolul lui B trece la ~18 m de centru: streasina de jos (5,8) lasa
##   ~6,7 m pana la marginea benzii.
## - CASELE MACHIYA in randuri continue pe ambele parti, de la s = -70 (grila
##   e in ultimii ~45 m dinaintea liniei, pe dreapta H) pana la colt (s ~150
##   dreapta, unde B coteste spre interiorul randului; s ~186 stanga, pe
##   exteriorul coltului). Peretele fatadei (Machiya_Wood, z -2,66) la
##   hw + 3,4 de ax: streasina (z -3,73) cade la hw + 2,33, deci nu intra pe
##   carosabil, iar felinarele de hartie (coliziune `trunk`) stau la
##   hw + 2,1, peste marja de 2 m a lui probe_manual. Distanta fata de
##   bordura e constanta (hw + 3,4), nu fata de ax: H are hw 7, A are 8.
## - Fata bogata = -Z GLB (masurat: noren/plaster la z -2,6..-2,8), intoarsa
##   spre drum. Variantele a-e alterneaza, niciodata aceeasi casa alaturi.
## - CURTILE: din 3-5 in 3-5 case, un gol de 8,6 m cu zid de templu (8 m) pe
##   linia fatadei si un artar/ginkgo in spate, scalat 0,75-0,85 si rotit cu
##   axa ingusta a coroanei spre drum: coroana trece peste zid, nu peste case.
## - RANDUL DOI (fara corp, `none`) la +8 m in spatele primului, pe ambele
##   parti, ca acoperisurile sa se vada peste primul rand din camera de 10 m.
## - TEATRU: doi calugari care matura (`monk_sweeper`, fara corp) pe trotuarul
##   din dreapta, in fata grilei, cu gramezi de frunze; ceainarii
##   (`teahouse_front`) spre B, in golurile de langa colt.

const PAGODA := Vector3(4.0, 0.0, -200.0)
const HOUSES := ["machiya_a", "machiya_b", "machiya_c", "machiya_d", "machiya_e"]
const WALL_FACE := 3.4      # peretele fatadei fata de bordura (m)
const HOUSE_FRONT_Z := 2.66 # Machiya_Wood: fata la z -2,66
const HOUSE_W := 6.28
const LANTERN_OFF := 2.1    # stalpul felinarului fata de bordura
const ROW2_BACK := 8.0
const COURT_W := 8.6
const S_CAP := 150.0        # dupa atat drumul coteste (B); randurile continua drept

var _cum: PackedFloat32Array
var _total := 0.0


func _build() -> void:
	_prep()
	_pagoda()
	for side in [-1.0, 1.0]:
		_row(side)
		_row2(side)
	_monks()
	_old_town()


func _prep() -> void:
	var pts := _track.baked
	_cum.resize(pts.size() + 1)
	_cum[0] = 0.0
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		_cum[i + 1] = _cum[i] + Vector2(b.x - a.x, b.z - a.z).length()
	_total = _cum[pts.size()]


## Cadrul drumului la distanta s de linia de start (s < 0 = pe H, inainte de
## linie): [pozitie, tangenta, dreapta, semilatime].
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


## Cadrul pentru randul de case: dupa S_CAP drumul coteste (B), iar randul de
## pe exterior continua DREPT pe tangenta de la S_CAP.
func _row_frame(s: float) -> Array:
	if s <= S_CAP:
		return _frame(s)
	var f := _frame(S_CAP)
	f[0] = (f[0] as Vector3) + (f[1] as Vector3) * (s - S_CAP)
	return f


## yaw care intoarce -Z local spre directia d (orizontala).
func _yaw_face(d: Vector3) -> float:
	return atan2(-d.x, -d.z)


## yaw care duce +X local pe directia d (orizontala).
func _yaw_x_along(d: Vector3) -> float:
	return atan2(-d.z, d.x)


func _pagoda() -> void:
	var y := _sol_min(PAGODA.x, PAGODA.z, 3.9)
	_raw("yasaka_pagoda", "structures", "aPagoda", Vector3(PAGODA.x, y - 0.1, PAGODA.z), PI, 1.0, "")
	# Felinare de piatra la colturile fetei, zidul incintei pe vest, copaci
	# care incadreaza baza (diorama: rosu + galben langa pagoda).
	for dx in [-4.6, 4.6]:
		var x: float = PAGODA.x + dx
		var z := PAGODA.z + 7.2
		_raw("stone_lantern_a", "props", "aPagodaFelinar", Vector3(x, _sol_min(x, z, 0.6) - 0.05, z), PI, 1.0, "")
	for dx in [-7.6, 7.6]:
		var x: float = PAGODA.x + dx
		var z := PAGODA.z + 5.0
		_raw("stone_lantern_b", "props", "aPagodaFelinar", Vector3(x, _sol_min(x, z, 0.6) - 0.05, z), PI, 1.0, "")
	# Fara zid de incinta (runda 2): sirul de trei piese de pe vest (24 m
	# continuu) si apoi cele doua de pe nord se citeau, din camera de 10 m si
	# pe muchia cadrului, ca o placa alba culcata. Incinta o fac felinarele de
	# piatra si copacii; zidurile raman doar in curtile de pe strada.
	# Copacii stau in SPATELE si pe LATURILE pagodei (nord, vest, est), nu in
	# fata: de pe grila trebuie sa se vada baza. Coroanele (7-10 m) ajung la
	# primele doua acoperisuri, ca in dioramă.
	for it in [["momiji_b", -17.0, -8.0, 0.4, 1.0], ["ginkgo", 13.0, -9.0, 1.2, 0.9],
			["momiji_a", -9.0, -15.0, 2.0, 0.9], ["momiji_c", 8.0, -17.0, 0.9, 1.0],
			["momiji_a", -2.0, -22.0, 2.6, 1.05], ["ginkgo", -19.0, -18.0, 0.2, 1.0],
			["momiji_b", 17.0, -20.0, 1.7, 0.95], ["momiji_c", -24.0, -4.0, 1.1, 0.9]]:
		var x: float = PAGODA.x + float(it[1])
		var z: float = PAGODA.z + float(it[2])
		_raw(String(it[0]), "plants", "aPagodaCopac", Vector3(x, _sol_real(x, z) - 0.05, z), float(it[3]), float(it[4]), "")


## Randul intai pe o parte (side -1 = stanga/vest, +1 = dreapta/est).
func _row(side: float) -> void:
	var s_end := 150.0 if side > 0.0 else 186.0
	var tea_s := 132.0 if side > 0.0 else 158.0
	# Intrarea dinspre H: o curte (zid + copac) inaintea primei case, ca
	# randul sa nu inceapa ca un bloc taiat in camp.
	_court(-70.0 - COURT_W * 0.5 - 0.3, side)
	var s := -70.0
	var prev := ""
	var since_court := 0
	var court_every := _rng.randi_range(3, 5)
	var house_i := 0
	var tea_done := false
	while s < s_end:
		# Ceainaria spre B: un gol de 4,6 m in randul de langa colt.
		if not tea_done and s >= tea_s:
			_teahouse(s + 2.3, side)
			s += 4.6
			tea_done = true
			continue
		if since_court >= court_every and s > -40.0 and s + COURT_W < s_end - 6.0:
			_court(s + COURT_W * 0.5, side)
			s += COURT_W
			since_court = 0
			court_every = _rng.randi_range(3, 5)
			continue
		var m := _pick_house(prev)
		var w := HOUSE_W + (0.32 if m == "machiya_e" else 0.0)
		var sc := s + w * 0.5
		if sc + w * 0.5 > s_end + 1.0:
			break
		var f := _row_frame(sc)
		var hw: float = f[3]
		var tan: Vector3 = f[1]
		var right: Vector3 = f[2]
		var lat := hw + WALL_FACE + HOUSE_FRONT_Z + _rng.randf_range(0.0, 0.25)
		var p: Vector3 = (f[0] as Vector3) + right * (side * lat)
		var yaw := _yaw_face(-right * side) + _rng.randf_range(-0.015, 0.015)
		var y := _sol_min(p.x, p.z, 2.6)
		_raw(m, "buildings", "aCasa", Vector3(p.x, y - 0.08, p.z), yaw, 1.0, "")
		# Felinar de hartie (stins) la fiecare a doua casa, decalat intre parti.
		if (house_i + (0 if side > 0.0 else 1)) % 2 == 0:
			var lp: Vector3 = (f[0] as Vector3) + right * (side * (hw + LANTERN_OFF)) + tan * 1.9
			# bratul (+X local) in lungul strazii, inapoi spre mijlocul casei
			_raw("paper_lantern", "props", "aFelinar", Vector3(lp.x, _sol_real(lp.x, lp.z) - 0.05, lp.z),
				_yaw_x_along(-tan), 1.0, "")
		prev = m
		house_i += 1
		since_court += 1
		s += w + _rng.randf_range(0.04, 0.18)


func _pick_house(prev: String) -> String:
	var m := prev
	while m == prev:
		m = HOUSES[_rng.randi_range(0, HOUSES.size() - 1)]
	return m


## Curte: zid de templu pe linia fatadei + un copac in spate.
func _court(sc: float, side: float) -> void:
	var f := _row_frame(sc)
	var hw: float = f[3]
	var tan: Vector3 = f[1]
	var right: Vector3 = f[2]
	var lat := hw + WALL_FACE + 0.35
	var p: Vector3 = (f[0] as Vector3) + right * (side * lat)
	_raw("temple_wall", "structures", "aCurteZid", Vector3(p.x, _sol_min(p.x, p.z, 4.0) - 0.15, p.z),
		atan2(tan.x, tan.z), 1.0, "")
	var trees := ["momiji_a", "momiji_b", "momiji_c", "momiji_a", "momiji_c", "ginkgo"]
	var tm: String = trees[_rng.randi_range(0, trees.size() - 1)]
	var tp: Vector3 = (f[0] as Vector3) + right * (side * (lat + 3.6))
	# axa ingusta a coroanei (Z local) spre drum: +X local pe tangenta
	var tyaw := _yaw_x_along(tan) + _rng.randf_range(-0.12, 0.12)
	_raw(tm, "plants", "aCurteCopac", Vector3(tp.x, _sol_real(tp.x, tp.z) - 0.05, tp.z), tyaw,
		_rng.randf_range(0.75, 0.85), "")
	# frunze cazute la piciorul zidului
	var lp: Vector3 = (f[0] as Vector3) + right * (side * (hw + WALL_FACE - 0.9)) + tan * _rng.randf_range(-2.5, 2.5)
	_raw("leaf_pile", "props", "aFrunze", Vector3(lp.x, _sol_real(lp.x, lp.z) - 0.05, lp.z),
		_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.1), "")


func _teahouse(sc: float, side: float) -> void:
	var f := _row_frame(sc)
	var hw: float = f[3]
	var right: Vector3 = f[2]
	var lat := hw + WALL_FACE + 1.1
	var p: Vector3 = (f[0] as Vector3) + right * (side * lat)
	_raw("teahouse_front", "props", "aCeainarie", Vector3(p.x, _sol_min(p.x, p.z, 2.0) - 0.05, p.z),
		_yaw_face(-right * side), 1.0, "")


## Randul doi: doar acoperisuri peste primul rand, fara corp.
func _row2(side: float) -> void:
	var s := -40.0 + _rng.randf_range(0.0, 3.0)
	var s_end := 140.0 if side > 0.0 else 176.0
	var prev := ""
	while s < s_end:
		var m := _pick_house(prev)
		var f := _row_frame(s + HOUSE_W * 0.5)
		var hw: float = f[3]
		var right: Vector3 = f[2]
		var lat := hw + WALL_FACE + HOUSE_FRONT_Z + ROW2_BACK + _rng.randf_range(-0.4, 0.6)
		var p: Vector3 = (f[0] as Vector3) + right * (side * lat)
		var yaw := _yaw_face(-right * side) + _rng.randf_range(-0.03, 0.03)
		_raw(m, "buildings", "aCasaSpate", Vector3(p.x, _sol_min(p.x, p.z, 2.6) - 0.08, p.z), yaw, 1.0, "none")
		prev = m
		s += HOUSE_W + _rng.randf_range(0.05, 0.6)


## Doi calugari care matura pe trotuarul din dreapta, in fata grilei (se vad
## din cadrul de start), cu gramezile lor de frunze.
func _monks() -> void:
	for it in [[-4.5, 1.5, 0.35], [-0.5, 2.3, -0.5]]:
		var f := _frame(float(it[0]))
		var hw: float = f[3]
		var tan: Vector3 = f[1]
		var right: Vector3 = f[2]
		var p: Vector3 = (f[0] as Vector3) + right * (hw + float(it[1]))
		_raw("monk_sweeper", "props", "aCalugar", Vector3(p.x, _sol_real(p.x, p.z) - 0.03, p.z),
			_yaw_face(tan) + float(it[2]), 1.0, "")
		var lp: Vector3 = p + tan * 1.3 - right * 0.4
		_raw("leaf_pile", "props", "aFrunze", Vector3(lp.x, _sol_real(lp.x, lp.z) - 0.05, lp.z),
			_rng.randf_range(0.0, TAU), 0.9, "")
	# cateva gramezi in lungul bordurilor
	for k in 6:
		var s := _rng.randf_range(-30.0, 140.0)
		var side := -1.0 if k % 2 == 0 else 1.0
		var f := _frame(s)
		var hw: float = f[3]
		var p: Vector3 = (f[0] as Vector3) + (f[2] as Vector3) * (side * (hw + _rng.randf_range(0.9, 1.8)))
		_raw("leaf_pile", "props", "aFrunze", Vector3(p.x, _sol_real(p.x, p.z) - 0.05, p.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.7, 1.0), "")


## Cota minima a solului sub o amprenta patrata de semilatura r (ca nimic sa
## nu pluteasca pe panta de 2%).
func _sol_min(x: float, z: float, r: float) -> float:
	var m := _sol_real(x, z)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]:
		m = minf(m, _sol_real(x + d.x, z + d.y))
	return m


# ------------------------------------------------------------------ iesire

func _res_id(stem: String, path: String) -> String:
	if not _ext.has(stem):
		_ext[stem] = path
	return "poia_" + stem


func _raw(stem: String, folder: String, base: String, pos: Vector3, yaw: float,
		scl: float, mode: String) -> void:
	var path := "res://assets/models/kyoto/%s/%s.glb" % [folder, stem]
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, _res_id(stem, path)])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


## ORASUL VECHI (runda 2, aprobat de coordonator): doua noduri `CityFill`
## (MultiMesh feliat, fara corp) cu machiya a-e.
##  * Interiorul buclei, dincolo de randul doi al lui A (x > ~30): de la B
##    (z -150) pana inainte de iazul F (z 228), pana la padurea de pe D
##    (x ~262). Poligonul vine din harta `--scan` (celule de 20 m, copacii din
##    ocuparea lui MeshForest): liber = x 20..260, z -160..230.
##  * Cartierul pagodei, in AFARA buclei, la nord de B si la vest de randul
##    din stanga (`region_xz`, extensie opt-in in city_fill.gd).
## Curtile: puncte rare in interior, exceptate din umplutura (`exclude_xz`),
## cu cate un artar/ginkgo — diorama are coroane rosii printre acoperisuri.
const TOWN_IN := [Vector2(32, -150), Vector2(170, -150), Vector2(258, -140),
	Vector2(262, 40), Vector2(255, 200), Vector2(200, 228), Vector2(40, 228),
	Vector2(32, 180)]
const TOWN_PAGODA := [Vector2(-75, -165), Vector2(-30, -165), Vector2(-28, -232),
	Vector2(40, -236), Vector2(175, -246), Vector2(175, -300), Vector2(-75, -300)]

var _cf_lines: Array[String] = []


func _road_dist(c: Vector2) -> float:
	var best := INF
	for r: TrackRoute in _track.routes:
		var b: PackedVector3Array = r.baked
		for i in range(0, b.size(), 2):
			best = minf(best, c.distance_to(Vector2(b[i].x, b[i].z)))
	return best


func _old_town() -> void:
	var models := ["machiya_a", "machiya_b", "machiya_c", "machiya_d", "machiya_e"]
	for m in models:
		_res_id(m, "res://assets/models/kyoto/buildings/%s.glb" % m)
	# Curtile (runda 3): ~1 la 15 case, puncte la >= 14 m unul de altul si
	# departe de banda; fiecare scoate din siruri ~1-2 case (raza 5 m) si
	# primeste un artar/ginkgo.
	var courts := _courts(PackedVector2Array(TOWN_IN), Rect2(32, -150, 230, 378), 40.0, 52)
	var courts_p := _courts(PackedVector2Array(TOWN_PAGODA), Rect2(-75, -300, 250, 135), 32.0, 12)
	courts_p.append(Vector3(PAGODA.x, PAGODA.z, 26.0))
	_cityfill("OrasVechi", PackedVector2Array(TOWN_IN), 32.0, courts, 20261003)
	_cityfill("OrasPagoda", PackedVector2Array(TOWN_PAGODA), 26.0, courts_p, 20261004)
	print("; curti cu copac: %d + %d" % [courts.size(), courts_p.size() - 1])


func _courts(poly: PackedVector2Array, box: Rect2, road_m: float, want: int) -> Array[Vector3]:
	var courts: Array[Vector3] = []
	var tries := 0
	while courts.size() < want and tries < 6000:
		tries += 1
		var c := Vector2(_rng.randf_range(box.position.x, box.end.x),
			_rng.randf_range(box.position.y, box.end.y))
		if not Geometry2D.is_point_in_polygon(c, poly):
			continue
		if _road_dist(c) < road_m:
			continue
		var ok := true
		for q in courts:
			if c.distance_to(Vector2(q.x, q.y)) < 14.0:
				ok = false
				break
		if ok:
			courts.append(Vector3(c.x, c.y, 5.0))
	var trees := ["momiji_a", "momiji_b", "momiji_c", "momiji_b", "momiji_a", "ginkgo"]
	for q in courts:
		var tm: String = trees[_rng.randi_range(0, trees.size() - 1)]
		_raw(tm, "plants", "aOrasCopac", Vector3(q.x, _sol_real(q.x, q.y) - 0.05, q.y),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.75, 0.9), "")
	return courts


func _cityfill(nm: String, poly: PackedVector2Array, min_road: float,
		excl: Array[Vector3], sd: int) -> void:
	var ms: Array[String] = []
	for m in ["machiya_a", "machiya_b", "machiya_c", "machiya_d", "machiya_e"]:
		ms.append('ExtResource("poia_%s")' % m)
	var pv: Array[String] = []
	for q in poly:
		pv.append("%.1f, %.1f" % [q.x, q.y])
	var ev: Array[String] = []
	for e in excl:
		ev.append("%.1f, %.1f, %.1f" % [e.x, e.y, e.z])
	_cf_lines.append('[node name="%s" type="Node3D" parent="."]' % nm)
	_cf_lines.append('script = ExtResource("poia_cityfill")')
	_cf_lines.append("models = Array[PackedScene]([%s])" % ", ".join(ms))
	_cf_lines.append("weights = PackedFloat32Array(0.2, 0.2, 0.2, 0.2, 0.2)")
	_cf_lines.append("indigo_ratio = 0.0")
	# Runda 3: siruri lipite pe ulite (modul opt-in din city_fill.gd).
	_cf_lines.append("row_mode = true")
	_cf_lines.append("min_road_m = %.1f" % min_road)
	_cf_lines.append("seed_value = %d" % sd)
	_cf_lines.append("exclude_xz = PackedVector3Array(%s)" % ", ".join(ev))
	_cf_lines.append("region_xz = PackedVector2Array(%s)" % ", ".join(pv))
	_cf_lines.append("")


func _write() -> void:
	var lines: Array[String] = [";;EXT"]
	var stems := _ext.keys()
	stems.sort()
	for s in stems:
		lines.append('[ext_resource type="PackedScene" path="%s" id="poia_%s"]' % [_ext[s], s])
	lines.append('[ext_resource type="Script" path="res://scenes/props/city_fill.gd" id="poia_cityfill"]')
	lines.append(";;NODES")
	lines.append('[node name="ZoneA_Yasaka" type="Node3D" parent="DecorManual"]')
	lines.append("")
	lines.append_array(_out)
	lines.append_array(_cf_lines)
	print("; asezate %d piese, %d modele" % [_n, stems.size()])
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
