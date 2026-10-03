extends Node
## Generator de decor MANUAL pentru POI D — VALEA DE ARTARI SI PODUL ACOPERIT
## TSUTEN-KYO (Track18, Kyoto, frac 0,30-0,47). Tiparul gen_decor_kyoto_a.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoD.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoD.tscn -- \
##       --out=tools/kyoto_decor/poi_d.part
##
## Fisierul .part are doua sectiuni (`;;EXT` si `;;NODES`) pe care
## tools/gen_kyoto_route.py le lipeste in Track18.tscn (blocul DECOR MANUAL).

const TRACK := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneD_Valea"

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _ext: Dictionary = {}   # stem -> path
var _n := 0
var _out_path := ""
var _scan := false
var _rng := RandomNumberGenerator.new()
var _scripts: Dictionary = {}   # id -> path (ext_resource Script)


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
	_rng.seed = 31004
	_build()
	_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ geometrie

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


## distanta pe drum (orizontala) la fractia de INDEX f
func _s_of(f: float) -> float:
	var n := _track.baked.size()
	return _cum[clampi(int(round(f * n)), 0, n)]


## Cadrul drumului la distanta s: [pozitie, tangenta, dreapta, semilatime, frac].
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
	var pa: Vector3 = pts[(lo - 2 + n) % n]
	var pb: Vector3 = pts[(lo + 3) % n]
	var tan := Vector3(pb.x - pa.x, 0.0, pb.z - pa.z).normalized()
	var right := tan.cross(Vector3.UP).normalized()
	var fr := float(lo) / float(n)
	return [p, tan, right, _track.width_at(fr), fr]


## Curbura cu semn la distanta s: > 0 = drumul vireaza la DREAPTA (exteriorul
## e stanga, side -1). Rad/m, pe o baza de 20 m.
func _turn(s: float) -> float:
	var a: Vector3 = _frame(s - 10.0)[1]
	var b: Vector3 = _frame(s + 10.0)[1]
	var r: Vector3 = _frame(s)[2]
	return (b - a).dot(r) / 20.0


func _yaw_face(d: Vector3) -> float:
	return atan2(-d.x, -d.z)


func _yaw_x_along(d: Vector3) -> float:
	return atan2(-d.z, d.x)


# ------------------------------------------------------------------ scan

func _do_scan() -> void:
	var n := _track.baked.size()
	print("; baked %d, lungime %.0f" % [n, _total])
	for nm in ["Poduri/Tsutenkyo", "Hazarduri/Kogarashi", "Hazarduri/CameraTsutenkyo"]:
		var nd := _track.get_node_or_null(nm)
		if nd is Node3D:
			print("; %s pos %s" % [nm, str((nd as Node3D).global_position)])
	var forest := _track.get_node_or_null("PadureMasa")
	for k in 900:
		if forest != null and bool(forest.get("done")):
			break
		await get_tree().process_frame
	var trees := PackedVector2Array()
	if forest != null:
		var occ: Dictionary = forest.get("_occ")
		for k in occ:
			trees.append(Vector2((k as Vector2i).x * 2.0 + 1.0, (k as Vector2i).y * 2.0 + 1.0))
	print("; copaci (celule ocupate): %d" % trees.size())
	# MeshForest._edge_dist se bazeaza pe listele din _seg_grid; daca sunt goale
	# (append pe copia PackedInt32Array), edge_clear_m nu se aplica deloc.
	var filled := 0
	var grid: Dictionary = forest.get("_seg_grid")
	for key in grid:
		filled += (grid[key] as PackedInt32Array).size()
	print("; MeshForest _seg_grid: %d celule, %d segmente in liste (0 = edge_clear_m mort)" % [grid.size(), filled])
	var s0 := _s_of(0.295)
	var s1 := _s_of(0.49)
	var s := s0
	while s <= s1:
		var fr := _frame(s)
		var p: Vector3 = fr[0]
		var right: Vector3 = fr[2]
		var hw: float = fr[3]
		var line := "s %6.1f f %.4f (%6.1f %5.2f %6.1f) hw %.1f turn %+.4f |" % [
			s, fr[4], p.x, p.y, p.z, hw, _turn(s)]
		for side in [-1.0, 1.0]:
			line += " %s:" % ("L" if side < 0.0 else "R")
			for e in [1.0, 3.0, 6.0, 10.0, 18.0]:
				var q: Vector3 = p + right * side * (hw + e)
				line += " %+.1f" % (_sol_real(q.x, q.z) - p.y)
			# cel mai apropiat copac de pe partea asta (m de la margine)
			var best := INF
			for t in trees:
				var d := Vector2(t.x - p.x, t.y - p.z)
				var lat: float = d.dot(Vector2(right.x, right.z)) * side
				var lon := d.dot(Vector2((fr[1] as Vector3).x, (fr[1] as Vector3).z))
				if lat > 0.0 and absf(lon) < 6.0:
					best = minf(best, lat - hw)
			line += " T%.1f" % best
		print(line)
		s += 8.0


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


func _sol_min(x: float, z: float, r: float) -> float:
	var m := _sol_real(x, z)
	for d in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]:
		m = minf(m, _sol_real(x + d.x, z + d.y))
	return m


# ------------------------------------------------------------------ decor

## ------------------------------------------------------------------------
## DECIZIILE (randul D din docs/track_briefs/kyoto.md §2, §2.0, §3.0)
##
## Masurat cu --scan (pasi de 8 m, frac de INDEX, ca ModulePlacer/CameraZone):
## - aterizarea C2 e la 0,305-0,313 (repunerile vechi la 0,31): NIMIC cu corp
##   inainte de 0,325;
## - S-urile (curbura cu semn pe 20 m): stanga 0,327-0,338, dreapta
##   0,345-0,375, stanga 0,390-0,405 si 0,429-0,441. hw 6;
## - solul lateral e plat fata de drum (+-0,5 m pana la margine + 18) pe toata
##   valea; rapa podului incepe la 0,444 (-2) si coboara la -11 sub punte;
## - podul (ModulePlacer) 0,449-0,466, hw 4,5; kogarashi la 0,470.
##
## Primul rand (cu corp) e la >= margine + 3,0 pe INTERIORUL curbelor si pe
## drepte, si >= margine + 4,5 pe exterior (regula vitezei: nimic cu corp la
## < hw + 3 pe exterior). Felinarele stau doar pe interior in curbe.

const S_FREE_UNTIL_F := 0.325     # aterizarea C2: fara corpuri inainte
const VALLEY_END_F := 0.4415      # ultimul punct cu sol plat inainte de rapa
const CURVE_TURN := 0.006         # |curbura| peste asta = curba (rad/m)


func _build() -> void:
	_lanterns()
	_maples_row()
	_rocks()
	_leaf_piles()
	_fences()
	_deer()
	_bridge_ends()


## Partea exterioara a curbei la s (0 = dreapta, nu e curba).
func _outside(s: float) -> float:
	var k := _turn(s)
	if absf(k) < CURVE_TURN:
		return 0.0
	return -1.0 if k > 0.0 else 1.0


## Pozitia la s, pe partea side, la `edge` metri de MARGINEA drumului.
func _at(s: float, side: float, edge: float) -> Vector3:
	var f := _frame(s)
	return (f[0] as Vector3) + (f[2] as Vector3) * (side * ((f[3] as float) + edge))


## Felinare de piatra in ritm: din 24 in 24 m, alternand partile; in curbe
## doar pe interior (cel de pe exterior se muta pe interior).
func _lanterns() -> void:
	var s := _s_of(0.328)
	var s_end := _s_of(VALLEY_END_F) - 10.0
	var side := 1.0
	var k := 0
	while s < s_end:
		var out := _outside(s)
		var sd := side
		if out != 0.0 and sd == out:
			sd = -sd
		if not _deer_gap(s, sd):
			var edge := 3.0 if out != 0.0 else 3.3
			var p := _at(s, sd, edge)
			var f := _frame(s)
			var stem := "stone_lantern_a" if k % 2 == 0 else "stone_lantern_b"
			_raw(stem, "props", "dFelinar", Vector3(p.x, _sol_min(p.x, p.z, 0.65) - 0.05, p.z),
				_yaw_face(-(f[2] as Vector3) * sd), 1.0, "")
		side = -side
		k += 1
		s += 24.0


## Primul rand de artari (cu trunchi solid): la margine + 5..6, scala
## 0,8-0,95, cu axa INGUSTA a coroanei spre drum (+X local pe tangenta):
## semiadancimea coroanei e 3,35 x 0,95 = 3,2 m, deci coroana ajunge la
## margine + 1,8 si incadreaza drumul fara sa-l acopere. Din 9 in 13 m.
func _maples_row() -> void:
	var trees := ["momiji_a", "momiji_b", "momiji_c", "momiji_a", "momiji_c", "momiji_b"]
	for side in [-1.0, 1.0]:
		var s := _s_of(S_FREE_UNTIL_F) + (0.0 if side > 0.0 else 7.0)
		var s_end := _s_of(VALLEY_END_F) - 6.0
		while s < s_end:
			if _deer_gap(s, side):
				s += 6.0
				continue
			var edge := _rng.randf_range(5.0, 6.0)
			if _outside(s) == side:
				edge += 0.8
			var p := _at(s, side, edge)
			var tan: Vector3 = _frame(s)[1]
			var tm: String = trees[_rng.randi_range(0, trees.size() - 1)]
			_raw(tm, "plants", "dArtar", Vector3(p.x, _sol_real(p.x, p.z) - 0.05, p.z),
				_yaw_x_along(tan) + _rng.randf_range(-0.15, 0.15), _rng.randf_range(0.8, 0.95), "")
			s += _rng.randf_range(9.0, 13.0)


## Pietre si muschi la piciorul artarilor (margine + 4,6..6), rare.
func _rocks() -> void:
	var rocks := ["moss_mound", "garden_rock_a", "garden_rock_c", "garden_rock_b", "moss_mound"]
	for side in [-1.0, 1.0]:
		var s := _s_of(S_FREE_UNTIL_F) + (11.0 if side > 0.0 else 3.0)
		var s_end := _s_of(VALLEY_END_F) - 4.0
		while s < s_end:
			if not _deer_gap(s, side):
				var edge := _rng.randf_range(4.6, 6.0)
				if _outside(s) == side:
					edge = maxf(edge, 5.2)
				var p := _at(s, side, edge)
				var stem: String = rocks[_rng.randi_range(0, rocks.size() - 1)]
				_raw(stem, "rocks", "dPiatra", Vector3(p.x, _sol_min(p.x, p.z, 0.7) - 0.12, p.z),
					_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.05), "")
			s += _rng.randf_range(26.0, 38.0)


## Gramezi de frunze pe umar (fara corp) si, mai rar, sub coroane (margine
## + 3..9): diorama nu arata sol gol sub artari.
func _leaf_piles() -> void:
	for side in [-1.0, 1.0]:
		var t := _s_of(0.322) + (5.0 if side > 0.0 else 0.0)
		while t < _s_of(VALLEY_END_F):
			if not _deer_gap(t, side):
				var q := _at(t, side, _rng.randf_range(3.0, 9.0))
				_raw("leaf_pile", "props", "dFrunze", Vector3(q.x, _sol_real(q.x, q.z) - 0.06, q.z),
					_rng.randf_range(0.0, TAU), _rng.randf_range(0.9, 1.3), "")
			t += _rng.randf_range(10.0, 16.0)
	var s := _s_of(0.318)
	var s_end := _s_of(VALLEY_END_F)
	var side := -1.0
	while s < s_end:
		var p := _at(s, side, _rng.randf_range(0.7, 1.8))
		_raw("leaf_pile", "props", "dFrunze", Vector3(p.x, _sol_real(p.x, p.z) - 0.06, p.z),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.75, 1.05), "")
		if _rng.randf() < 0.5:
			side = -side
		s += _rng.randf_range(14.0, 26.0)


## Gard shiba pe interiorul curbelor (fara corp, nuiele de 1,1 m): module de
## 3 m pe tangenta locala, la margine + 2,0.
func _fences() -> void:
	for run in [[0.347, 0.372], [0.391, 0.404], [0.430, 0.440]]:
		var s := _s_of(float(run[0]))
		var s_end := _s_of(float(run[1]))
		while s + 3.0 <= s_end:
			var mid := s + 1.5
			var out := _outside(mid)
			var side := -out if out != 0.0 else 1.0
			if not _deer_gap(mid, side):
				var p := _at(mid, side, 2.0)
				var tan: Vector3 = _frame(mid)[1]
				_raw("shiba_fence", "props", "dGard", Vector3(p.x, _sol_min(p.x, p.z, 0.4) - 0.04, p.z),
					atan2(tan.x, tan.z), 1.0, "")
			s += 3.02


## CERBUL SIKA: frac ~0,384, pe stanga, la margine + 2,4 (fara corp, `none`
## din PROP_COLLISION), inaintea curbei la stanga de la 0,39: camera il are in
## fata-stanga pe dreapta. Capul (-Z) spre masina care vine si spre drum.
## Nodul copil `Bow` (SikaBow) il inclina cand trece o masina.
const DEER_F := 0.384
const DEER_SIDE := -1.0


func _deer_gap(s: float, side: float) -> bool:
	return side == DEER_SIDE and absf(s - _s_of(DEER_F)) < 9.0


func _deer() -> void:
	var s := _s_of(DEER_F)
	var f := _frame(s)
	var tan: Vector3 = f[1]
	var right: Vector3 = f[2]
	var p := _at(s, DEER_SIDE, 2.4)
	var look := (-tan * 0.55 + (-right * DEER_SIDE) * 0.85).normalized()
	_raw("sika_deer", "animals", "dCerb", Vector3(p.x, _sol_real(p.x, p.z) - 0.03, p.z),
		_yaw_face(look), 1.0, "")
	var deer_name := "dCerb%d" % _n
	_out.append('[node name="Bow" type="Node" parent="%s/%s"]' % [ZONE, deer_name])
	_out.append('script = ExtResource("poid_sika_bow")')
	_out.append("")
	_scripts["poid_sika_bow"] = "res://scenes/props/sika_bow.gd"
	# A doua, o ciuta care paste (Graze; coarnele au scala 0,001 in clip), mai
	# in fata si mai departe de drum, cu spatele spre masina.
	var s2 := s + 6.0
	var f2 := _frame(s2)
	var p2 := _at(s2, DEER_SIDE, 4.2)
	var look2 := ((f2[1] as Vector3) * 0.8 + (f2[2] as Vector3) * DEER_SIDE * 0.6).normalized()
	_raw("sika_deer", "animals", "dCerb", Vector3(p2.x, _sol_real(p2.x, p2.z) - 0.03, p2.z),
		_yaw_face(look2), 0.95, "")
	_out.append('[node name="Bow" type="Node" parent="%s/dCerb%d"]' % [ZONE, _n])
	_out.append('script = ExtResource("poid_sika_bow")')
	_out.append('idle_clip = &"Graze"')
	_out.append("")
	# Fundal inchis in spatele lor: pe solul nisipiu cerbul (SAND_MID) se
	# pierdea (captura r1, 0,379). Doua movile de muschi la margine + 5..6.
	for k in [[-1.0, 5.6], [4.0, 6.4]]:
		var mp := _at(s + float(k[0]), DEER_SIDE, float(k[1]))
		_raw("moss_mound", "rocks", "dPiatra", Vector3(mp.x, _sol_min(mp.x, mp.z, 0.9) - 0.12, mp.z),
			_rng.randf_range(0.0, TAU), 1.0, "")
	# frunze la picioarele lui, un felinar si un artar in spate
	var lp := _at(s + 2.5, DEER_SIDE, 1.6)
	_raw("leaf_pile", "props", "dFrunze", Vector3(lp.x, _sol_real(lp.x, lp.z) - 0.06, lp.z), 0.7, 0.9, "")
	var fp := _at(s - 5.0, DEER_SIDE, 4.5)
	_raw("stone_lantern_b", "props", "dFelinar", Vector3(fp.x, _sol_min(fp.x, fp.z, 0.65) - 0.05, fp.z),
		_yaw_face(-right * DEER_SIDE), 1.0, "")
	var tp := _at(s + 1.0, DEER_SIDE, 8.0)
	_raw("momiji_a", "plants", "dArtar", Vector3(tp.x, _sol_real(tp.x, tp.z) - 0.05, tp.z),
		_yaw_x_along(tan), 0.9, "")


## CAPETELE PODULUI: la intrare (inainte de rapa, sol plat) cate un felinar
## mare pe fiecare parte la margine + 3,0 si un altar mic pe dreapta. La
## iesire (dupa kogarashi, 0,470) felinarele stau la margine + 5,5: dupa
## rasucirea de 72° masina are nevoie de ~25 m (brief §3.0), deci nimic solid
## aproape de banda acolo. Altarul de iesire pe stanga, la margine + 8.
func _bridge_ends() -> void:
	var s_in := _s_of(VALLEY_END_F) - 1.0
	var f := _frame(s_in)
	for side in [-1.0, 1.0]:
		var p := _at(s_in, side, 3.0)
		_raw("stone_lantern_a", "props", "dPodFelinar", Vector3(p.x, _sol_min(p.x, p.z, 0.65) - 0.05, p.z),
			_yaw_face(-(f[2] as Vector3) * side), 1.0, "")
	var sp := _at(s_in - 5.0, 1.0, 6.5)
	var fs := _frame(s_in - 5.0)
	_raw("small_shrine", "structures", "dPodAltar", Vector3(sp.x, _sol_min(sp.x, sp.z, 1.7) - 0.1, sp.z),
		_yaw_face(-(fs[2] as Vector3)), 1.0, "")
	var s_out := _s_of(0.4755)
	var fo := _frame(s_out)
	for side in [-1.0, 1.0]:
		var p := _at(s_out, side, 5.5)
		_raw("stone_lantern_a", "props", "dPodFelinar", Vector3(p.x, _sol_min(p.x, p.z, 0.65) - 0.05, p.z),
			_yaw_face(-(fo[2] as Vector3) * side), 1.0, "")
	var so := _at(s_out + 6.0, -1.0, 8.0)
	var fso := _frame(s_out + 6.0)
	_raw("small_shrine", "structures", "dPodAltar", Vector3(so.x, _sol_min(so.x, so.z, 1.7) - 0.1, so.z),
		_yaw_face(fso[2] as Vector3), 1.0, "")


# ------------------------------------------------------------------ iesire

func _res_id(stem: String, path: String) -> String:
	if not _ext.has(stem):
		_ext[stem] = path
	return "poid_" + stem


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


func _write() -> void:
	var lines: Array[String] = [";;EXT"]
	var stems := _ext.keys()
	stems.sort()
	for s in stems:
		lines.append('[ext_resource type="PackedScene" path="%s" id="poid_%s"]' % [_ext[s], s])
	for sid in _scripts:
		lines.append('[ext_resource type="Script" path="%s" id="%s"]' % [_scripts[sid], sid])
	lines.append(";;NODES")
	lines.append('[node name="ZoneD_Valea" type="Node3D" parent="DecorManual"]')
	lines.append("")
	lines.append_array(_out)
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
