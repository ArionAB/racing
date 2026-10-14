extends Node
## Generator de decor MANUAL pentru POI D — VALEA CAPREI si PORTALUL Transfagarasan
## (Track21, frac 0.252-0.3171: acele +119/-96, peretii de zapada, semaforul, gura
## Portal_S). Nu e sonda: MASOARA terenul real (raycast pe TerrainBody) si
## CALCULEAZA nodurile care se lipesc in Track21.tscn sub `DecorManual/ZonaD`.
##
##   godot --headless --path . res://tools/GenDecorTfD.tscn -- --survey
##   godot --headless --path . res://tools/GenDecorTfD.tscn -- --emit    (tipareste)
##   godot --headless --path . res://tools/GenDecorTfD.tscn -- --write   (rescrie ZonaD)
##
## ---------------------------------------------------------------------------
## LISTA DE ELEMENTE (runda 1) — din decupajul `D.png`, cu cifrele fisei
## (`### D` din transfagarasan_poi_gauntlet.md), fiecare legat de o piesa.
##
## Ce arata decupajul (MATERIA, nu layoutul): zapada veche (strat murdar, umbre
## albastre) pe versantul stang si intre pereti; portalul de beton plat intre pereti
## de zapada; semaforul pe stalp (montat); SIST gri-verzui cu fete luminate in lame
## deasupra; MOLIZI verde-negru in 2-3 randuri si 3 marimi la poale; JNEAPAN joasa
## verde-inchis intre drum si copaci; stalpi alb-rosii (montati, snow_pole).
##
##  #  element                      cifra   piesa (GLB)                       cum
##  1  palcuri de jneapan           ~110    plants/jneapan_a + jneapan_b      MultiMesh (ace tri_class
##     (3-5 tufe/palc ~430 tufe)    (fisa 40)                                 tf_jneapan + scoarta pe
##                                                                            tf_jneapan, 2 felii)
##  2  petice de bujor de munte     8       plants/bujor_de_munte (x3-5)      noduri WorldProp (tf_bloom)
##  3  palcuri de afin              10      plants/afin (x6/palc)             MultiMesh, atlas
##  4  aflorimente de sist          ~28     rocks/schist_outcrop_a/b/c        noduri, hull, in GRUPURI
##     (fisa 4: ridicat dupa verdictul   de 3-5, scara mixta 0.5-1.35         pe versantul de sus
##     de densitate din valul 1)
##  5  conuri de grohotis           3       rocks/scree_cone                  noduri, fara coliziune
##  6  zapada cu volum              ~60     structures/snow_wall SnowWall_B_  MultiMesh, tri_class=snow,
##     (fisa: 6 snow_patch; regula        Snow ingropat 35-50%                zero material nou
##     valului 1: snow_patch citeste folie)
##  7  molizi                       ~230    trees/alpine_pines Pine_B/Pine_C  MultiMesh (copac+trunchi),
##     3 randuri / 3 marimi (fisa 12 izolati; criticul cere masa)             0.4-0.6 / 0.7-1.0 / 1.0-1.4
##  8  stana cu tarc                1       buildings/stana                   nod, hull, in interiorul
##                                                                            acelor, 25-30 m de drum
##  9  flori de pajiste             ~100    flowers/flower_cluster            MultiMesh, atlas
## 10  peretii de zapada, jaloane, Portal_S, Santier, semafor: NU se ating
##
## Densitate spre drum: 0-10 m de MARGINE = flori + tufe joase (jneapan la >= 3 m);
## 10-30 m = palcuri de jneapan si afin, aflorimente, molizi mici/medii; 30-60 m =
## molizi mari, stana, grohotis, zapada pe versant. Culoarele: nimic la < 3 m de
## marginea ORICAREI ramuri; nimic la < 13 m de axa in lungimea peretilor de zapada
## (0.266-0.316: peretii stau la 10,4-11 m, Utilaj_parcat la 8,3 m, Lampa la 7,5 m,
## Jalon la 7,9 m); nimic la < 18 m de axa pe 0.309-0.322 (aripile portalului);
## culoarul utilajului (offset -2,6) e pe banda, deci liber.

const TRACK := "res://scenes/tracks/Track21.tscn"
const SCENE_PATH := "res://scenes/tracks/Track21.tscn"
const ZONE := "DecorManual/ZonaD"
const F0 := 0.252
const F1 := 0.3171

const MODELS := {
	"d_flock": ["Script", "res://scenes/props/flock.gd"],
	"d_jneapan_a": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_a.glb"],
	"d_jneapan_b": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_b.glb"],
	"d_afin": ["PackedScene", "res://assets/models/transfagarasan/plants/afin.glb"],
	"d_bujor": ["PackedScene", "res://assets/models/transfagarasan/plants/bujor_de_munte.glb"],
	"d_outcrop_a": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb"],
	"d_outcrop_b": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb"],
	"d_outcrop_c": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb"],
	"d_scree": ["PackedScene", "res://assets/models/transfagarasan/rocks/scree_cone.glb"],
	"d_snow_wall": ["PackedScene", "res://assets/models/transfagarasan/structures/snow_wall.glb"],
	"d_pines": ["PackedScene", "res://assets/models/trees/alpine_pines.glb"],
	"d_flower": ["PackedScene", "res://assets/models/flowers/flower_cluster.glb"],
	"d_stana": ["PackedScene", "res://assets/models/transfagarasan/buildings/stana.glb"],
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _rng := RandomNumberGenerator.new()
var _i_lo := 0
var _i_hi := 0

var _nodes: Array[String] = []
var _flocks := {}
var _count := {}
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
	_rng.seed = 252317
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


func _build() -> void:
	_stana()
	_jneapan()
	_afin()
	_bujor()
	_roci_si_zapada()
	_grohotis()
	_molizi()
	_flori()
	var tot := 0
	for k in _count:
		tot += int(_count[k])
	print("; ZonaD: %d piese asezate, %d respinse de garzi" % [tot, _rejected])
	for k in _count:
		print(";   %s: %d" % [k, _count[k]])
	for k in _flocks:
		print(";   lot %s: %d instante" % [k, (_flocks[k]["pos"] as PackedVector3Array).size()])


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
	var y1 := _sol_real(q.x + 2.0, q.z)
	var y2 := _sol_real(q.x - 2.0, q.z)
	var y3 := _sol_real(q.x, q.z + 2.0)
	var y4 := _sol_real(q.x, q.z - 2.0)
	var slope := maxf(absf(y1 - y2), absf(y3 - y4)) / 4.0
	var nrm := Vector3(y2 - y1, 4.0, y4 - y3).normalized()
	var up := _sol_real(p.x + s.x * sg * (half + 14.0), p.z + s.z * sg * (half + 14.0)) - p.y > 3.0
	return {"pos": q, "i": i, "f": f, "half": half, "d": near["d"], "j": near["i"],
		"half_j": _track.width_at_index(near["i"]), "slope": slope, "nrm": nrm,
		"uphill": up, "dy_road": y - _track.baked[near["i"]].y}


## Garzile comune. `margin` = cat de departe de MARGINEA oricarei ramuri (m), `r` = raza piesei.
func _ok(c: Dictionary, r: float, margin: float) -> bool:
	var d: float = c["d"]
	if d < float(c["half_j"]) + margin + r:
		return false
	var fj: float = float(c["j"]) / float(_track.baked.size())
	var fi: float = c["f"]
	# lungimea peretilor de zapada (10,4-11 m de axa) + utilaj + lampa + jaloane
	if (fj > 0.266 and fj < 0.316) or (fi > 0.266 and fi < 0.316):
		if d < 13.0 + r:
			return false
	# aripile portalului
	if (fj > 0.309 and fj < 0.322) or (fi > 0.309 and fi < 0.322):
		if d < 18.0 + r:
			return false
	return true


func _put(kind: String, _c: Dictionary) -> void:
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
	return 0 if f < 0.2845 else 1


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


# 8 ------------------------------------------------------------------ stana

## Stana: cel mai plat loc la 20-36 m de marginea oricarei ramuri, cu tot tarcul
## (14,35 x 10,35) in garzi. Fata (usa, poarta: +Y Blender = -Z Godot) priveste spre drum.
func _stana() -> void:
	var best := {}
	var best_score := 1e9
	for k in 2500:
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.012)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var c := _cand(f, sg, _rng.randf_range(20.0, 36.0))
		if not _ok(c, 8.5, 12.0):
			continue
		var cp: Vector3 = c["pos"]
		var near := _nearest_road(cp)
		var rp: Vector3 = _track.baked[near["i"]]
		var toward := Vector3(rp.x - cp.x, 0.0, rp.z - cp.z).normalized()
		var yaw := atan2(-toward.x, -toward.z)
		var b := Basis(Vector3.UP, yaw)
		var ys: Array[float] = []
		var ok := true
		for ix in [-7.0, 0.0, 7.0]:
			for iz in [-5.0, 0.0, 5.0]:
				var w: Vector3 = cp + b * Vector3(ix, 0.0, iz)
				var cc := _cand_at(w, c)
				if float(cc["d"]) < float(cc["half_j"]) + 9.0:
					ok = false
				ys.append(float(cc["pos"].y))
		if not ok:
			continue
		var mn: float = ys.min()
		var mx: float = ys.max()
		var score := (mx - mn) + absf(float(c["d"]) - 27.0) * 0.05
		if score < best_score:
			best_score = score
			best = {"c": c, "yaw": yaw, "mn": mn, "mx": mx}
	if best.is_empty():
		print("; STANA: niciun loc")
		return
	var cb: Dictionary = best["c"]
	var p3: Vector3 = cb["pos"]
	p3.y = float(best["mn"]) + (float(best["mx"]) - float(best["mn"])) * 0.35 - 0.1
	print("; STANA f=%.4f d=%.1f dY teren=%.2f yaw=%.2f" % [float(cb["f"]), float(cb["d"]), float(best["mx"]) - float(best["mn"]), float(best["yaw"])])
	_node("D_Stana", "d_stana", p3, float(best["yaw"]), 1.0)
	_put("stana", cb)


# 1 ------------------------------------------------------------------ jneapan

func _jneapan() -> void:
	var clusters := 0
	var guard := 0
	while clusters < 110 and guard < 14000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.002, F1 - 0.002)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var off := 3.0 + pow(_rng.randf(), 1.7) * 36.0
		var c := _cand(f, sg, off)
		if float(c["slope"]) > 1.0 and _rng.randf() < 0.7:
			continue
		if not _ok(c, 2.0, 3.0):
			_rejected += 1
			continue
		var k := _rng.randi_range(3, 5)
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
			var p3: Vector3 = pc["pos"]
			p3.y -= 0.05
			_flock_add("jn_%s_s%d" % [variant, _slice_of(f)], p3, yaw, Vector3(sc, sc * _rng.randf_range(0.9, 1.15), sc))
			_put("jneapan_" + variant, pc)
			placed += 1
		if placed > 0:
			clusters += 1
	_count["palcuri_jneapan"] = clusters


# 3 ------------------------------------------------------------------ afin

func _afin() -> void:
	var pal := 0
	var guard := 0
	while pal < 10 and guard < 2500:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var c := _cand(f, sg, _rng.randf_range(4.0, 16.0))
		if float(c["slope"]) > 0.8 or not _ok(c, 2.0, 3.0):
			continue
		for m in 6:
			var ang := _rng.randf() * TAU
			var rad := _rng.randf_range(0.2, 1.8)
			var pos: Vector3 = (c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
			var pc := _cand_at(pos, c)
			if not _ok(pc, 0.6, 2.6):
				continue
			var sc := _rng.randf_range(1.0, 1.5)
			_flock_add("afin_s%d" % _slice_of(f), pc["pos"], _rng.randf_range(-PI, PI), Vector3(sc, sc, sc))
			_put("afin", pc)
		pal += 1
	_count["palcuri_afin"] = pal


# 2 ------------------------------------------------------------------ bujor

func _bujor() -> void:
	var patches := 0
	var slots := 8
	for s in slots:
		var placed := false
		var guard := 0
		while not placed and guard < 400:
			guard += 1
			var f := F0 + (F1 - F0) * (float(s) + _rng.randf_range(0.1, 0.9)) / float(slots)
			var sg := 1.0 if _rng.randf() < 0.5 else -1.0
			var c := _cand(f, sg, _rng.randf_range(4.0, 14.0))
			if float(c["slope"]) > 0.8 or not _ok(c, 1.2, 3.0):
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
				_node("D_Bujor%02d_%d" % [patches + 1, m], "d_bujor", p3, _rng.randf_range(-PI, PI), sc)
				_put("bujor", pc)
				got += 1
			if got > 0:
				patches += 1
				placed = true
	_count["petice_bujor"] = patches


## Un punct pe versantul de SUS: latura care urca SI cota peste drumul cel mai apropiat.
func _uphill_cand(f: float, off_lo: float, off_hi: float, min_dy: float = 3.5) -> Dictionary:
	var sg := 1.0 if _rng.randf() < 0.5 else -1.0
	var c := _cand(f, sg, _rng.randf_range(off_lo, off_hi))
	if float(c["dy_road"]) < min_dy:
		return {}
	# D are relief domol: panta contribuie, nu e conditie (valea Caprei e larga)
	if not bool(c["uphill"]) and float(c["dy_road"]) < min_dy + 1.5:
		return {}
	return c


# 5 ------------------------------------------------------------------ grohotis

func _grohotis() -> void:
	var placed: Array[Vector3] = []
	var guard := 0
	while placed.size() < 3 and guard < 6000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.01)
		var c := _uphill_cand(f, 10.0, 30.0, 1.2)
		if c.is_empty() or not _ok(c, 6.5, 4.0):
			continue
		var pp: Vector3 = c["pos"]
		var near := false
		for q in placed:
			if q.distance_to(pp) < 30.0:
				near = true
				break
		if near:
			continue
		var sc := _rng.randf_range(0.8, 1.1)
		var p3: Vector3 = pp
		p3.y -= 0.4
		_node("D_Grohotis%02d" % (placed.size() + 1), "d_scree", p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 0.7)
		_put("grohotis", c)
		placed.append(pp)


# 4+6 ----------------------------------------------------------------- roci + zapada

## Un banc de zapada: mesh-ul `SnowWall_B_Snow` din snow_wall.glb (clasa `snow`),
## cu lungimea pe curba de nivel, ingropat 35-50% ca sa iasa o calota cu trepte.
func _snow_lump(pc: Dictionary, big: bool) -> void:
	var nrm: Vector3 = pc["nrm"]
	var cx := -nrm.z
	var cz := nrm.x
	var yaw := _rng.randf_range(-PI, PI)
	if Vector2(cx, cz).length() > 0.05:
		yaw = atan2(cx, cz) + _rng.randf_range(-0.4, 0.4)
	var sy := _rng.randf_range(1.3, 2.1) if big else _rng.randf_range(0.8, 1.3)
	var sx := _rng.randf_range(1.6, 2.6) if big else _rng.randf_range(1.0, 1.8)
	var sz := _rng.randf_range(0.9, 1.5) if big else _rng.randf_range(0.5, 0.9)
	var p3: Vector3 = pc["pos"]
	p3.y -= 3.02 * sy * _rng.randf_range(0.35, 0.5)
	_flock_add("snow_s%d" % _slice_of(float(pc["f"])), p3, yaw, Vector3(sx, sy, sz))
	_put("zapada", pc)


func _roci_si_zapada() -> void:
	var centers: Array[Vector3] = []
	var guard := 0
	var groups := 0
	var total := 0
	while groups < 12 and guard < 9000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.012)
		var c := _uphill_cand(f, 9.0, 34.0, 1.2)
		if c.is_empty() or not _ok(c, 3.5, 5.0):
			continue
		var pp: Vector3 = c["pos"]
		var near := false
		for q in centers:
			if q.distance_to(pp) < 14.0:
				near = true
				break
		if near:
			continue
		centers.append(pp)
		groups += 1
		total = _grup(c, total)
	# panouri mari de zapada pe versant (sus) + zapada intre si dincolo de pereti
	var big := 0
	guard = 0
	while big < 30 and guard < 5000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.004, F1 - 0.004)
		var c := _uphill_cand(f, 16.0, 50.0, 2.5)
		if c.is_empty() or not _ok(c, 3.5, 6.0):
			continue
		_snow_lump(c, true)
		big += 1
	var lo := 0
	guard = 0
	while lo < 26 and guard < 5000:
		guard += 1
		var f := _rng.randf_range(0.272, F1 - 0.003)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var c := _cand(f, sg, _rng.randf_range(7.0, 22.0))
		if not _ok(c, 2.2, 3.0):
			continue
		_snow_lump(c, false)
		lo += 1


func _grup(c: Dictionary, total: int) -> int:
	var cp: Vector3 = c["pos"]
	var k := _rng.randi_range(3, 5)
	for m in k:
		var ang := _rng.randf() * TAU
		var rad := _rng.randf_range(0.0, 4.5) if m > 0 else 0.0
		var pc := _cand_at(cp + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
		var small := m > 0 and _rng.randf() < 0.5
		var sc := _rng.randf_range(0.5, 0.8) if small else _rng.randf_range(0.9, 1.35)
		if not _ok(pc, 3.0 * sc, 4.5):
			continue
		var nm := "outcrop_a" if _rng.randf() < 0.5 else "outcrop_b"
		if _rng.randf() < 0.1:
			nm = "outcrop_c"
		var p3: Vector3 = pc["pos"]
		p3.y -= 0.35 * sc
		total += 1
		_node("D_Aflor%02d" % total, "d_" + nm, p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 0.25)
		_put("aflorimente", pc)
	var z := _rng.randi_range(2, 4)
	for m in z:
		var ang := _rng.randf() * TAU
		var rad := _rng.randf_range(2.0, 5.0)
		var pc := _cand_at(cp + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
		if not _ok(pc, 2.0, 4.0):
			continue
		_snow_lump(pc, false)
	return total


# 7 ------------------------------------------------------------------ molizi

func _pine_put(pc: Dictionary, variant: String, sc: float, f: float) -> void:
	var yaw := _rng.randf_range(-PI, PI)
	var sl := _slice_of(f)
	var p3: Vector3 = pc["pos"]
	p3.y -= 0.1
	_flock_add("pine_%s_s%d" % [variant, sl], p3, yaw, Vector3(sc, sc, sc))
	_flock_add("trunk_%s_s%d" % [variant, sl], p3, yaw, Vector3(sc, sc, sc))
	_put("molizi", pc)


## Trei randuri, trei marimi, in palcuri: mici (0.4-0.6) la 8-20 m de margine,
## medii (0.7-1.0) la 16-34 m, mari (1.0-1.4) la 28-58 m.
func _molizi() -> void:
	var rows := [
		{"n": 30, "lo": 8.0, "hi": 20.0, "s0": 0.4, "s1": 0.6, "k0": 3, "k1": 5},
		{"n": 26, "lo": 16.0, "hi": 34.0, "s0": 0.7, "s1": 1.0, "k0": 3, "k1": 5},
		{"n": 22, "lo": 28.0, "hi": 58.0, "s0": 1.0, "s1": 1.4, "k0": 3, "k1": 5},
	]
	for r in rows:
		var clumps := 0
		var guard := 0
		while clumps < int(r["n"]) and guard < 12000:
			guard += 1
			var f := _rng.randf_range(F0 + 0.002, F1 - 0.002)
			var sg := 1.0 if _rng.randf() < 0.5 else -1.0
			var c := _cand(f, sg, _rng.randf_range(float(r["lo"]), float(r["hi"])))
			if not _ok(c, 2.2, 4.0):
				_rejected += 1
				continue
			var got := 0
			for m in _rng.randi_range(int(r["k0"]), int(r["k1"])):
				var pc := c
				if m > 0:
					var ang := _rng.randf() * TAU
					var rad := _rng.randf_range(1.6, 5.0)
					pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
					if not _ok(pc, 1.8, 4.0):
						continue
				var variant := "b" if _rng.randf() < 0.55 else "c"
				_pine_put(pc, variant, _rng.randf_range(float(r["s0"]), float(r["s1"])), f)
				got += 1
			if got > 0:
				clumps += 1


# 9 ------------------------------------------------------------------ flori

func _flori() -> void:
	var n := 0
	var guard := 0
	while n < 100 and guard < 8000:
		guard += 1
		var f := _rng.randf_range(F0 + 0.002, F1 - 0.002)
		var sg := 1.0 if _rng.randf() < 0.5 else -1.0
		var off := 3.2 + pow(_rng.randf(), 1.8) * 22.0
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
			return {"model": "d_jneapan_" + parts[1], "mesh": "Jneapan_Needles", "cls": "tf_jneapan", "nm": "D_JnAce_" + parts[1] + "_" + parts[2]}
		"afin":
			return {"model": "d_afin", "mesh": "Afin_Leaves", "cls": "", "nm": "D_Afin_" + parts[1]}
		"pine":
			return {"model": "d_pines", "mesh": "Pine_" + parts[1].to_upper(), "cls": "", "nm": "D_Molid_" + parts[1] + "_" + parts[2]}
		"trunk":
			return {"model": "d_pines", "mesh": "Trunk_" + parts[1].to_upper(), "cls": "", "nm": "D_Trunchi_" + parts[1] + "_" + parts[2]}
		"snow":
			return {"model": "d_snow_wall", "mesh": "SnowWall_B_Snow", "cls": "snow", "nm": "D_Banc_" + parts[1]}
		"flori":
			return {"model": "d_flower", "mesh": "", "cls": "", "nm": "D_Flori_" + parts[1]}
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
	lines.append('script = ExtResource("d_flock")')
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
		lines.append('script = ExtResource("d_flock")')
		lines.append('model = ExtResource("%s")' % spec["model"])
		lines.append('mesh_name = "Jneapan_Bark"')
		lines.append('tri_class = "tf_jneapan"')
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


## Rescrie DOAR ZonaD si ext_resource-urile `f_*` din Track21.tscn. Restul ramane
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
		if l.begins_with('[ext_resource') and ' id="d_' in l:
			continue
		if l.begins_with("["):
			skipping = ('parent="%s"' % ZONE) in l
		if skipping:
			continue
		kept.append(l)
		i += 1
	# acum: gaseste ultimul ext_resource si nodul ZonaD (+ metadata) pentru insertie
	var out: Array[String] = []
	for k in kept.size():
		if kept[k].begins_with("[ext_resource"):
			last_ext = k
	var zona_meta := -1
	for k in kept.size():
		if kept[k].begins_with('[node name="ZonaD" type="Node3D" parent="DecorManual"]'):
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
			# dupa linia goala a lui ZonaD: nodurile mele
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
