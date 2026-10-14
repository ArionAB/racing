extends Node
## Generator de decor MANUAL pentru POI F — SERPENTINELE Transfagarasan
## (Track21, frac 0.372-0.6268, patru ace de par). Nu e sonda: MASOARA terenul
## real (raycast pe TerrainBody) si CALCULEAZA nodurile care se lipesc in
## Track21.tscn sub `DecorManual/ZonaF`.
##
##   godot --headless --path . res://tools/GenDecorTfF.tscn -- --survey
##   godot --headless --path . res://tools/GenDecorTfF.tscn -- --emit    (tipareste)
##   godot --headless --path . res://tools/GenDecorTfF.tscn -- --write   (rescrie ZonaF)
##
## ---------------------------------------------------------------------------
## LISTA DE ELEMENTE (runda 1) — din decupajul `F.png` + `F_oi.png`, cu cifrele
## fisei (`### F` din transfagarasan_poi_gauntlet.md), fiecare legat de o piesa.
##
## Ce arata decupajul (MATERIA, nu layoutul): patru ace stivuite; pe FIECARE
## fata de treapta zid de piatra (ZidC*, montat, ramane); pe fasiile de ~18 m
## dintre ramuri iarba scurta cu tufe joase verde-inchis (jneapan) si flori;
## bujor magenta in petice mici, nealiniate; pe versantul de sus sist gri-verzui
## in lame, zapada veche in petice murdare, molizi verde-negru in palcuri; in
## stanga jos o fasie de pajiste cu molizi mici.
##
##  #  element                      cifra   piesa (GLB)                       cum
##  1  palcuri de jneapan           ~40     plants/jneapan_a + jneapan_b      MultiMesh (4 loturi:
##     (3-5 tufe/palc ~170 tufe)            clasa tf_jneapan pe ace, atlas     ace a/b + scoarta a/b)
##                                          pe scoarta                         pe fasii si versant
##  2  petice de bujor de munte     10      plants/bujor_de_munte (x3-5/petic) noduri WorldProp
##                                                                              (tf_bloom din tema)
##  3  palcuri de afin              2       plants/afin (x6/palc)              MultiMesh, atlas
##  4  aflorimente de sist          4       rocks/schist_outcrop_a/b/c         noduri, coliziune hull,
##                                                                              doar pe versantul de sus
##  5  conuri de grohotis           3       rocks/scree_cone                   noduri, fara coliziune
##  6  petice de zapada             14      scatter/snow_patch                 noduri (aliniate pe panta)
##  7  molizi                       12 izolati + ~24 in palcuri pe versant
##                                          trees/alpine_pines Pine_B/Pine_C   MultiMesh (copac + trunchi
##                                          (+ Trunk_B/Trunk_C)                separat: GLB cu 4 variante)
##  8  flori de pajiste             ~110    flowers/flower_cluster             MultiMesh, atlas
##  9  zid de sprijin pe fiecare treapta: NU se adauga (ZidC01-34 montate raman)
## 10  oile + cainii: hazard (OileAcPaior), NU se ating
##
## Densitate spre drum: 0-10 m de MARGINE = flori + tufe joase + bujor (nimic
## cu coliziune); 10-30 m = palcuri de jneapan si afin; 30-60 m (versantul de
## sus) = sist, zapada, grohotis, molizi. Intre ramuri pastrez culoarele:
## nimic la < 3 m de marginea ORICAREI ramuri (parapetul sta la 0,25 m), nimic
## in culoarul oilor (0.480-0.502, <24 m de axa) si nimic pe versantul de
## deasupra ramurii 1 in limba avalansei (0.396-0.435).

const TRACK := "res://scenes/tracks/Track21.tscn"
const SCENE_PATH := "res://scenes/tracks/Track21.tscn"
const ZONE := "DecorManual/ZonaF"
const F0 := 0.372
const F1 := 0.6268

const MODELS := {
	"f_flock": ["Script", "res://scenes/props/flock.gd"],
	"f_jneapan_a": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_a.glb"],
	"f_jneapan_b": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_b.glb"],
	"f_afin": ["PackedScene", "res://assets/models/transfagarasan/plants/afin.glb"],
	"f_bujor": ["PackedScene", "res://assets/models/transfagarasan/plants/bujor_de_munte.glb"],
	"f_outcrop_a": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb"],
	"f_outcrop_b": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb"],
	"f_outcrop_c": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb"],
	"f_scree": ["PackedScene", "res://assets/models/transfagarasan/rocks/scree_cone.glb"],
	"f_snow_patch": ["PackedScene", "res://assets/models/scatter/snow_patch.glb"],
	"f_pines": ["PackedScene", "res://assets/models/trees/alpine_pines.glb"],
	"f_flower": ["PackedScene", "res://assets/models/flowers/flower_cluster.glb"],
}

## Raza la baza (m), pentru garda de banda.
const BASE_R := {
	"jneapan_a": 1.8, "jneapan_b": 1.6, "afin": 0.45, "bujor": 0.7,
	"outcrop_a": 2.5, "outcrop_b": 3.5, "outcrop_c": 2.6, "scree": 6.5,
	"snow_patch": 2.4, "pine": 1.6, "flower": 0.5,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _rng := RandomNumberGenerator.new()
var _i_lo := 0
var _i_hi := 0

# rezultate
var _nodes: Array[String] = []      # blocuri [node] gata scrise
var _flocks := {}                   # cheie lot -> {pos: PackedVector3Array, yaw: PackedFloat32Array, scl: Array[Vector3]}
var _count := {}                    # statistici pe element
var _rejected := 0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	var n := _track.baked.size()
	_i_lo = int((F0 - 0.03) * float(n))
	_i_hi = int((F1 + 0.03) * float(n))
	_rng.seed = 372062
	var args := OS.get_cmdline_user_args()
	if "--survey" in args:
		_survey()
	else:
		_build()
		if "--write" in args:
			_write_scene()
		else:
			print("\n".join(_ext_lines()))
			print("\n".join(_nodes))
			print(_flock_text())
	get_tree().quit(0)


# ------------------------------------------------------------------ constructie

func _build() -> void:
	_jneapan()
	_afin()
	_bujor()
	_aflorimente()
	_grohotis()
	_zapada()
	_molizi()
	_flori()
	var tot := 0
	for k in _count:
		tot += int(_count[k])
	print("; ZonaF: %d piese asezate, %d respinse de garzi" % [tot, _rejected])
	for k in _count:
		print(";   %s: %d" % [k, _count[k]])
	for k in _flocks:
		print(";   lot %s: %d instante" % [k, (_flocks[k]["pos"] as PackedVector3Array).size()])


## Un punct candidat: fractia, latura (+1/-1 fata de `_side_at`) si offsetul de la
## MARGINEA asfaltului. Intoarce pozitia pe teren + tot ce trebuie garzilor.
func _cand(f: float, sg: float, off: float) -> Dictionary:
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var q: Vector3 = p + s * sg * (half + off)
	var y := _sol_real(q.x, q.z)
	q.y = y
	var near := _nearest_road(q)
	# panta locala (m pe m), din patru probe la 2 m
	var y1 := _sol_real(q.x + 2.0, q.z)
	var y2 := _sol_real(q.x - 2.0, q.z)
	var y3 := _sol_real(q.x, q.z + 2.0)
	var y4 := _sol_real(q.x, q.z - 2.0)
	var slope := maxf(absf(y1 - y2), absf(y3 - y4)) / 4.0
	var nrm := Vector3(y2 - y1, 4.0, y4 - y3).normalized()
	# urcus = terenul creste spre exterior
	var up := _sol_real(p.x + s.x * sg * (half + 14.0), p.z + s.z * sg * (half + 14.0)) - p.y > 3.0
	return {"pos": q, "i": i, "f": f, "half": half, "d": near["d"], "j": near["i"],
		"half_j": _track.width_at_index(near["i"]), "slope": slope, "nrm": nrm,
		"uphill": up, "dy_road": y - _track.baked[near["i"]].y}


## Garzile comune. `margin` = cat de departe de MARGINEA oricarei ramuri (m),
## `r` = raza piesei. Culoarul oilor si limba avalansei raman libere.
func _ok(c: Dictionary, r: float, margin: float) -> bool:
	if float(c["d"]) < float(c["half_j"]) + margin + r:
		return false
	var fj: float = float(c["j"]) / float(_track.baked.size())
	var fi: float = c["f"]
	if fj > 0.480 and fj < 0.502 and float(c["d"]) < 24.0 + r:
		return false
	if fi > 0.480 and fi < 0.502 and float(c["d"]) < 24.0 + r:
		return false
	# limba avalansei: versantul de deasupra ramurii 1
	if fi > 0.396 and fi < 0.435 and bool(c["uphill"]):
		return false
	return true


func _put(kind: String, c: Dictionary) -> void:
	_count[kind] = int(_count.get(kind, 0)) + 1


func _flock_add(key: String, pos: Vector3, yaw: float, scl: Vector3) -> void:
	if not _flocks.has(key):
		_flocks[key] = {"pos": PackedVector3Array(), "yaw": PackedFloat32Array(), "scl": [] as Array[Vector3]}
	var d: Dictionary = _flocks[key]
	var pa: PackedVector3Array = d["pos"]
	pa.append(pos)
	d["pos"] = pa
	var ya: PackedFloat32Array = d["yaw"]
	ya.append(yaw)
	d["yaw"] = ya
	var sa: Array[Vector3] = []
	sa.assign(d["scl"])
	sa.append(scl)
	d["scl"] = sa


func _slice_of(f: float) -> int:
	return 0 if f < 0.499 else 1


# 1 ------------------------------------------------------------------ jneapan

func _jneapan() -> void:
	var clusters := 0
	var guard := 0
	while clusters < 44 and guard < 5000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		# densitate spre drum: offset mic mai des
		var off := 3.0 + pow(_rng.randf(), 1.7) * 34.0
		var c := _cand(f, sg, off)
		# fasiile plate din fata drumului primesc palcul; pe taluz abrupt mai rar
		if float(c["slope"]) > 0.9 and _rng.randf() < 0.75:
			continue
		if not _ok(c, 2.0, 3.0):
			_rejected += 1
			continue
		var k := _rng.randi_range(4, 6)
		var placed := 0
		for m in k:
			var ang := _rng.randf() * TAU
			var rad := _rng.randf_range(0.0, 2.6) if m > 0 else 0.0
			var pos: Vector3 = (c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
			var pc := _cand_at(pos, c)
			if not _ok(pc, 1.6, 2.6):
				_rejected += 1
				continue
			var variant := "a" if _rng.randf() < 0.55 else "b"
			var sc := _rng.randf_range(0.8, 1.35)
			var yaw := _rng.randf_range(-PI, PI)
			var sl := _slice_of(f)
			var p3: Vector3 = pc["pos"]
			p3.y -= 0.05
			_flock_add("jn_%s_s%d" % [variant, sl], p3, yaw, Vector3(sc, sc * _rng.randf_range(0.9, 1.15), sc))
			_put("jneapan_" + variant, pc)
			placed += 1
		if placed > 0:
			clusters += 1
	_count["palcuri_jneapan"] = clusters


## Candidat construit dintr-o pozitie XZ data (membrii unui palc), cu aceleasi campuri ca `_cand`.
func _cand_at(pos: Vector3, base: Dictionary) -> Dictionary:
	var q := pos
	q.y = _sol_real(q.x, q.z)
	var near := _nearest_road(q)
	var d := base.duplicate()
	d["pos"] = q
	d["d"] = near["d"]
	d["j"] = near["i"]
	d["half_j"] = _track.width_at_index(near["i"])
	d["dy_road"] = q.y - _track.baked[near["i"]].y
	return d


# 3 ------------------------------------------------------------------ afin

func _afin() -> void:
	var pal := 0
	var guard := 0
	while pal < 2 and guard < 800:
		guard += 1
		var f := _rng.randf_range(F0 + 0.02, F1 - 0.02)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var c := _cand(f, sg, _rng.randf_range(4.0, 12.0))
		if float(c["slope"]) > 0.6 or not _ok(c, 2.0, 3.0):
			continue
		for m in 6:
			var ang := _rng.randf() * TAU
			var rad := _rng.randf_range(0.2, 1.8)
			var pos: Vector3 = (c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
			var pc := _cand_at(pos, c)
			if not _ok(pc, 0.6, 2.6):
				continue
			var sc := _rng.randf_range(1.0, 1.5)
			_flock_add("afin", pc["pos"], _rng.randf_range(-PI, PI), Vector3(sc, sc, sc))
			_put("afin", pc)
		pal += 1
	_count["palcuri_afin"] = pal


# 2 ------------------------------------------------------------------ bujor

func _bujor() -> void:
	var patches := 0
	var guard := 0
	# 10 petice, cate unul pe fiecare a zecea parte a intervalului, nu aliniate
	var slots := 10
	for s in slots:
		var placed := false
		guard = 0
		while not placed and guard < 300:
			guard += 1
			var f := F0 + (F1 - F0) * (float(s) + _rng.randf_range(0.1, 0.9)) / float(slots)
			var sg := 1.0 if _rng.randf() < 0.5 else -1.0
			var c := _cand(f, sg, _rng.randf_range(4.0, 11.0))
			if float(c["slope"]) > 0.7 or not _ok(c, 1.2, 3.0):
				continue
			var k := _rng.randi_range(3, 5)
			var got := 0
			for m in k:
				var ang := _rng.randf() * TAU
				var rad := _rng.randf_range(0.0, 1.9) if m > 0 else 0.0
				var pos: Vector3 = (c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
				var pc := _cand_at(pos, c)
				if not _ok(pc, 0.9, 2.4):
					continue
				var sc := _rng.randf_range(1.4, 2.1)
				var p3: Vector3 = pc["pos"]
				p3.y -= 0.04
				_node("F_Bujor%02d_%d" % [patches + 1, m], "f_bujor", p3, _rng.randf_range(-PI, PI), sc)
				_put("bujor", pc)
				got += 1
			if got > 0:
				patches += 1
				placed = true
	_count["petice_bujor"] = patches


# 4 ------------------------------------------------------------------ aflorimente

## Un punct pe versantul de SUS: latura care urca fata de propria ramura SI
## cota peste drumul cel mai apropiat (fasiile dintre ramuri nu sunt versant).
func _uphill_cand(f: float, off_lo: float, off_hi: float, min_dy: float = 3.5) -> Dictionary:
	var sg := 1.0 if _rng.randf() < 0.5 else -1.0
	var c := _cand(f, sg, _rng.randf_range(off_lo, off_hi))
	if not bool(c["uphill"]) or float(c["dy_road"]) < min_dy:
		return {}
	return c


func _aflorimente() -> void:
	var names := ["outcrop_a", "outcrop_b", "outcrop_a", "outcrop_c"]
	var placed: Array[Vector3] = []
	var guard := 0
	while placed.size() < 4 and guard < 6000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var c := _uphill_cand(f, 12.0, 34.0)
		if c.is_empty():
			continue
		var nm: String = names[placed.size()]
		if not _ok(c, float(BASE_R[nm]) * 1.3, 5.0):
			_rejected += 1
			continue
		var pp: Vector3 = c["pos"]
		var near := false
		for q in placed:
			if q.distance_to(pp) < 45.0:
				near = true
				break
		if near:
			continue
		var sc := _rng.randf_range(1.15, 1.6)
		var p3: Vector3 = pp
		p3.y -= 0.35 * sc
		_node("F_Aflor%02d" % (placed.size() + 1), "f_" + nm, p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 0.25)
		_put("aflorimente", c)
		placed.append(pp)


# 5 ------------------------------------------------------------------ grohotis

func _grohotis() -> void:
	var placed: Array[Vector3] = []
	var guard := 0
	while placed.size() < 3 and guard < 6000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var c := _uphill_cand(f, 10.0, 26.0)
		if c.is_empty():
			continue
		if not _ok(c, 6.5, 4.0):
			_rejected += 1
			continue
		var pp: Vector3 = c["pos"]
		var near := false
		for q in placed:
			if q.distance_to(pp) < 60.0:
				near = true
				break
		if near:
			continue
		var sc := _rng.randf_range(0.8, 1.1)
		var p3: Vector3 = pp
		p3.y -= 0.4
		_node("F_Grohotis%02d" % (placed.size() + 1), "f_scree", p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 0.7)
		_put("grohotis", c)
		placed.append(pp)


# 6 ------------------------------------------------------------------ zapada

func _zapada() -> void:
	# Petice MICI, pe panta abrupta (>0.45), cate 2-3 suprapuse: o foaie plata de
	# 11 m pe iarba usoara citea ca folie de plastic (captura t1_f0.530).
	var centers: Array[Vector3] = []
	var guard := 0
	var total := 0
	while total < 14 and guard < 8000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var c := _uphill_cand(f, 12.0, 50.0, 1.5)
		if c.is_empty() or float(c["slope"]) < 0.45:
			continue
		if not _ok(c, 2.4, 4.0):
			_rejected += 1
			continue
		var pp: Vector3 = c["pos"]
		var near := false
		for q in centers:
			if q.distance_to(pp) < 30.0:
				near = true
				break
		if near:
			continue
		centers.append(pp)
		var k := mini(_rng.randi_range(2, 3), 14 - total)
		for m in k:
			var ang := _rng.randf() * TAU
			var rad := _rng.randf_range(0.0, 2.8) if m > 0 else 0.0
			var pc := _cand_at(pp + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
			if not _ok(pc, 1.6, 4.0):
				continue
			var sc := _rng.randf_range(0.7, 1.25)
			var p3: Vector3 = pc["pos"]
			p3.y += 0.05
			total += 1
			_node("F_Zapada%02d" % total, "f_snow_patch", p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 1.0)
			_put("zapada", pc)


# 7 ------------------------------------------------------------------ molizi

func _molizi() -> void:
	var trees := 0
	var guard := 0
	while trees < 36 and guard < 4000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var off := 8.0 + pow(_rng.randf(), 1.3) * 46.0
		var c := _cand(f, sg, off)
		if not _ok(c, 2.2, 5.0):
			_rejected += 1
			continue
		# 12 izolati (un singur molid), restul in palcuri de 2-3
		var k := 1 if trees < 12 else _rng.randi_range(2, 3)
		for m in k:
			var pc := c
			if m > 0:
				var ang := _rng.randf() * TAU
				var rad := _rng.randf_range(2.8, 5.2)
				pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
				if not _ok(pc, 2.2, 5.0):
					continue
			var variant := "b" if _rng.randf() < 0.55 else "c"
			var sc := _rng.randf_range(0.85, 1.3)
			var yaw := _rng.randf_range(-PI, PI)
			var sl := _slice_of(f)
			var p3: Vector3 = pc["pos"]
			p3.y -= 0.1
			_flock_add("pine_%s_s%d" % [variant, sl], p3, yaw, Vector3(sc, sc, sc))
			_flock_add("trunk_%s_s%d" % [variant, sl], p3, yaw, Vector3(sc, sc, sc))
			_put("molizi", pc)
			trees += 1


# 8 ------------------------------------------------------------------ flori

func _flori() -> void:
	var n := 0
	var guard := 0
	while n < 140 and guard < 8000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var off := 3.2 + pow(_rng.randf(), 1.8) * 20.0
		var c := _cand(f, sg, off)
		if float(c["slope"]) > 1.0 or not _ok(c, 0.5, 2.6):
			continue
		var sc := _rng.randf_range(1.0, 1.8)
		var p3: Vector3 = c["pos"]
		p3.y -= 0.03
		_flock_add("flori_s%d" % _slice_of(f), p3, _rng.randf_range(-PI, PI), Vector3(sc, sc, sc))
		_put("flori", c)
		n += 1


# ------------------------------------------------------------------ emitere

## Un nod instantiat din GLB. `nrm` + `tilt` = cat din panta se urmeaza (0 = vertical).
func _node(nm: String, res_id: String, pos: Vector3, yaw: float, sc: float,
		nrm: Vector3 = Vector3.UP, tilt: float = 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	if tilt > 0.0 and nrm.y < 0.999:
		var axis := Vector3.UP.cross(nrm)
		if axis.length() > 0.001:
			var ang := Vector3.UP.angle_to(nrm) * tilt
			b = Basis(axis.normalized(), ang) * b
	b = b.scaled(Vector3(sc, sc, sc))
	_nodes.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [nm, ZONE, res_id])
	_nodes.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z])
	_nodes.append("")


## Lotul -> (id model, mesh_name, clasa). Cheia lotului: prefix_variant_sN.
func _lot_spec(key: String) -> Dictionary:
	var parts := key.split("_")
	match parts[0]:
		"jn":
			return {"model": "f_jneapan_" + parts[1], "mesh": "Jneapan_Needles", "cls": "tf_jneapan", "nm": "F_JnAce_" + parts[1] + "_" + parts[2]}
		"afin":
			return {"model": "f_afin", "mesh": "Afin_Leaves", "cls": "", "nm": "F_Afin"}
		"pine":
			return {"model": "f_pines", "mesh": "Pine_" + parts[1].to_upper(), "cls": "", "nm": "F_Molid_" + parts[1] + "_" + parts[2]}
		"trunk":
			return {"model": "f_pines", "mesh": "Trunk_" + parts[1].to_upper(), "cls": "", "nm": "F_Trunchi_" + parts[1] + "_" + parts[2]}
		"flori":
			return {"model": "f_flower", "mesh": "", "cls": "", "nm": "F_Flori_" + parts[1]}
	return {}


func _flock_text() -> String:
	var out: Array[String] = []
	for key in _flocks:
		out.append_array(_flock_block(key))
	return "\n".join(out)


func _flock_block(key: String) -> Array[String]:
	var lines: Array[String] = []
	var d: Dictionary = _flocks[key]
	var spec := _lot_spec(key)
	var pos: PackedVector3Array = d["pos"]
	if pos.is_empty():
		return lines
	var scl: Array[Vector3] = []
	scl.assign(d["scl"])
	lines.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [spec["nm"], ZONE])
	lines.append('script = ExtResource("f_flock")')
	lines.append('model = ExtResource("%s")' % spec["model"])
	if String(spec["mesh"]) != "":
		lines.append('mesh_name = "%s"' % spec["mesh"])
	if String(spec["cls"]) != "":
		lines.append('tri_class = "%s"' % spec["cls"])
	lines.append("positions = %s" % var_to_str(pos).replace("\n", ""))
	lines.append("yaws = %s" % var_to_str(d["yaw"]).replace("\n", ""))
	lines.append("scale3_list = %s" % var_to_str(scl).replace("\n", ""))
	lines.append("")
	# lotul cu scoarta jneapanului (atlas), pe aceleasi instante
	if key.begins_with("jn_"):
		lines.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]'
			% [String(spec["nm"]).replace("JnAce", "JnScoarta"), ZONE])
		lines.append('script = ExtResource("f_flock")')
		lines.append('model = ExtResource("%s")' % spec["model"])
		lines.append('mesh_name = "Jneapan_Bark"')
		lines.append("positions = %s" % var_to_str(pos).replace("\n", ""))
		lines.append("yaws = %s" % var_to_str(d["yaw"]).replace("\n", ""))
		lines.append("scale3_list = %s" % var_to_str(scl).replace("\n", ""))
		lines.append("")
	return lines


func _ext_lines() -> Array[String]:
	var out: Array[String] = []
	for id in MODELS:
		out.append('[ext_resource type="%s" path="%s" id="%s"]' % [MODELS[id][0], MODELS[id][1], id])
	return out


## Rescrie DOAR ZonaF si ext_resource-urile `f_*` din Track21.tscn. Restul ramane
## octet cu octet. (Un .tscn editat de mana nu se rescrie: citesc, tai, lipesc.)
func _write_scene() -> void:
	var path := ProjectSettings.globalize_path(SCENE_PATH)
	var txt := FileAccess.get_file_as_string(path)
	var lines := txt.split("\n")
	var kept: Array[String] = []
	var last_ext := -1
	var i := 0
	var skipping := false
	for ln in lines:
		var l: String = ln
		if l.begins_with('[ext_resource') and ' id="f_' in l:
			continue
		if l.begins_with("["):
			skipping = ('parent="%s"' % ZONE) in l
		if skipping:
			continue
		kept.append(l)
		i += 1
	# acum: gaseste ultimul ext_resource si nodul ZonaF (+ metadata) pentru insertie
	var out: Array[String] = []
	for k in kept.size():
		if kept[k].begins_with("[ext_resource"):
			last_ext = k
	var zona_meta := -1
	for k in kept.size():
		if kept[k].begins_with('[node name="ZonaF" type="Node3D" parent="DecorManual"]'):
			zona_meta = k
			# metadata e linia(ile) de dupa nod pana la linia goala
			var m := k + 1
			while m < kept.size() and kept[m] != "":
				m += 1
			zona_meta = m  # indexul liniei goale de dupa bloc
	for k in kept.size():
		out.append(kept[k])
		if k == last_ext:
			out.append_array(_ext_lines())
		if k == zona_meta:
			# dupa linia goala a lui ZonaF: nodurile mele
			out.append_array(_nodes)
			var ft := _flock_text()
			if ft != "":
				out.append(ft)
				out.append("")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print("; scris %s (%d noduri de instanta, %d loturi MultiMesh)" % [path, _nodes.size() / 3, _flocks.size()])


# ------------------------------------------------------------------ survey

func _survey() -> void:
	var n := _track.baked.size()
	print("; frac  x z y  dir | R: dY(4,8,14,22,35,50) libere-pana-la-alta-ramura | L: idem")
	var f := F0
	while f <= F1 + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var dir := (_track.baked[(i + 1) % n] - p).normalized()
		var half := _track.width_at_index(i)
		var line := "%.3f %6.1f %6.1f %5.1f d(%5.2f,%5.2f) |" % [f, p.x, p.z, p.y, dir.x, dir.z]
		for sg: float in [1.0, -1.0]:
			for off: float in [4.0, 8.0, 14.0, 22.0, 35.0, 50.0]:
				var q: Vector3 = p + s * sg * (half + off)
				line += " %+5.1f" % (_sol_real(q.x, q.z) - p.y)
			var free := 60.0
			var o := 1.0
			while o <= 60.0:
				var q2: Vector3 = p + s * sg * (half + o)
				var r := _nearest_road(q2)
				if absi(r["i"] - i) > 30 and r["d"] < _track.width_at_index(r["i"]) + 1.0:
					free = o
					break
				o += 1.0
			line += " free %4.0f |" % free
		print(line)
		f += 0.004


# ------------------------------------------------------------------ helpers

## Cea mai apropiata ramura de drum: {d (de la axa, xz), i (indexul)}.
func _nearest_road(q: Vector3) -> Dictionary:
	var best := 1e9
	var bi := _i_lo
	var n := _track.baked.size()
	for k in range(_i_lo, mini(_i_hi, n - 1)):
		var a := _track.baked[k]
		var b := _track.baked[k + 1]
		var abx := b.x - a.x
		var abz := b.z - a.z
		var l2 := abx * abx + abz * abz
		var t := 0.0
		if l2 > 0.0001:
			t = clampf(((q.x - a.x) * abx + (q.z - a.z) * abz) / l2, 0.0, 1.0)
		var dx := a.x + abx * t - q.x
		var dz := a.z + abz * t - q.z
		var d := dx * dx + dz * dz
		if d < best:
			best = d
			bi = k if t < 0.5 else k + 1
	return {"d": sqrt(best), "i": bi}


func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 900.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _sampler.ground_y(x, z)
