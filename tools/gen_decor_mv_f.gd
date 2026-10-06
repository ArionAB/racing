extends Node
## Generator de decor MANUAL pentru POI F - CORNISA DE LA ARTIST'S POINT
## (Track19, Monument Valley, frac 0.442-0.600). Tiparul gen_decor_mv_b.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvF.tscn -- ##       --out=C:/cale/zonaF.part        (--terrain tipareste profilul lateral)
##
## Latura STANGA = +n (n = (d.y, -d.x)); pe F drumul merge spre NV/N, deci
## stanga = vest (belvederul), dreapta = est (rapa de 13 m).

const TRACK := "res://scenes/tracks/Track19.tscn"
const SEMI := 7.0
const RES := {
	"shade_ramada": "s_shade_ramada", "tour_truck": "s_tour_truck",
	"tourist_group": "s_tourist_group", "juniper": "s_juniper",
	"sagebrush": "s_sagebrush", "rabbitbrush": "s_rabbitbrush",
	"talus_boulders_a": "s_talus_boulders_a", "talus_boulders_b": "s_talus_boulders_b",
	"hoodoo": "s_hoodoo", "butte_small_c": "s_butte_small_c",
	"butte_small_a": "s_butte_small_a", "rock_fin": "s_rock_fin",
}
## F = fractiile 0.442-0.600 pe lungime (2089,9 m).
const S0 := 0.442 * 2089.9
const S1 := 0.600 * 2089.9

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _gosp: Array[String] = []
var _cur: Array[String] = _out
var _zone := "DecorManual/ZonaF"
var _n := 0
var _out_path := ""
var _rng := RandomNumberGenerator.new()
var _pts: PackedVector3Array
var _cum: PackedFloat32Array
var _len := 0.0
var _pole_pos := PackedVector3Array()
var _pole_yaw := PackedFloat32Array()
var _last_name := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_rng.seed = 56127
	_index_path()
	if "--terrain" in OS.get_cmdline_user_args():
		_print_terrain()
		get_tree().quit(0)
		return
	_build()
	_write()
	get_tree().quit(0)


func _index_path() -> void:
	_pts = PackedVector3Array(_track.baked)
	_cum = PackedFloat32Array()
	var acc := 0.0
	for i in _pts.size():
		_cum.append(acc)
		acc += _pts[i].distance_to(_pts[(i + 1) % _pts.size()])
	_len = acc


func _at(s: float) -> Dictionary:
	s = fposmod(s, _len)
	var i := 0
	for k in _cum.size():
		if _cum[k] <= s:
			i = k
		else:
			break
	var a := _pts[i]
	var b := _pts[(i + 1) % _pts.size()]
	var seg := maxf(a.distance_to(b), 0.001)
	var t := (s - _cum[i]) / seg
	var p := a.lerp(b, t)
	var d := Vector2(b.x - a.x, b.z - a.z).normalized()
	return {"p": p, "d": d, "n": Vector2(d.y, -d.x)}


## Punct la arclength dat de `q`, decalat lateral cu `lat` (+ = est/stanga la mers).
func _off(q: Dictionary, lat: float) -> Vector3:
	var n: Vector2 = q["n"]
	var p3: Vector3 = q["p"]
	return Vector3(p3.x + n.x * lat, 0.0, p3.z + n.y * lat)


func _on(s: float, lat: float) -> Vector3:
	var p := _off(_at(s), lat)
	p.y = _sol(p.x, p.z)
	return p



func _print_terrain() -> void:
	var lats := [-60.0, -40.0, -30.0, -20.0, -14.0, -9.0, -7.0, 7.0, 9.0, 14.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 55.0, 70.0]
	var hdr := "lat:        "
	for l in lats:
		hdr += "%6d" % int(l)
	print(hdr)
	var s := S0 - 40.0
	while s < S1 + 20.0:
		var q := _at(s)
		var line := "s=%4d f=%.3f x=%6.1f z=%6.1f y=%5.1f |" % [int(s), s / _len, q["p"].x, q["p"].z, q["p"].y]
		for l in lats:
			var p := _off(q, l)
			line += "%6.1f" % (_sol(p.x, p.z) - q["p"].y)
		print(line)
		s += 20.0


## Latura stanga = +lat. Belvederul sta la nivelul drumului pe stanga (plat
## +-0,5 m pe >= 70 m, masurat cu --terrain); dreapta e rapa, fara nimic cu coliziune.
const BEL_S0 := 1052.0
const BEL_S1 := 1128.0
const BEL_L0 := 13.0
const BEL_L1 := 50.0


## Directia -n (spre drum si rapa) in plan, la arclength s: pozitia pieselor
## belvederului se uita intr-acolo (vale/peste drum).
func _towards_road(s: float, wobble: float) -> float:
	var n: Vector2 = _at(s)["n"]
	return _face(-n.x, -n.y) + wobble


func _face(dx: float, dz: float) -> float:
	var yaw := atan2(-dx, -dz)
	var f := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(0, 0, -1)
	var l := Vector2(dx, dz).normalized()
	assert(f.x * l.x + f.z * l.y > 0.999)
	return yaw


func _build() -> void:
	_belvedere()
	_formations()
	_ravine_floor()
	_vegetation()


func _belvedere() -> void:
	# Ramada pe mesa plata, in spatele camioanelor, cu fata spre drum.
	_raw("shade_ramada", "fRamada", _on(1112.0, 41.0), _towards_road(1112.0, 0.1), 1.0, "")
	# 3 camioane de tur parcate cu botul spre drum (ca in dioram), usor
	# nealiniate; centrul la ~30 m de axa, botul la ~27 m.
	var tr := [[1070.0, 31.0, 0.12], [1087.0, 29.5, -0.08], [1101.0, 33.0, 0.2]]
	for t in tr:
		_raw("tour_truck", "fCamion", _on(t[0], t[1]), _towards_road(t[0], t[2]), 1.0, "")
	# Bolovani de parcare in fata botului camioanelor (hull, la >= 23 m de axa).
	var bl := [[1066.0, 24.5, "talus_boulders_a", 0.6], [1073.5, 24.0, "talus_boulders_b", 0.5],
		[1083.0, 23.5, "talus_boulders_b", 0.55], [1091.5, 24.5, "talus_boulders_a", 0.5],
		[1098.0, 25.5, "talus_boulders_a", 0.6], [1106.0, 26.5, "talus_boulders_b", 0.5]]
	for b in bl:
		_raw(b[2], "fBolovan", _on(b[0], b[1]), _rng.randf() * TAU, b[3], "")
	# 2 grupuri de turisti (4 oameni fiecare), intre camioane si drum, cu spatele
	# la camioane si fata spre vale/peste drum; ochii la rapa din dreapta.
	_raw("tourist_group", "fTuristi", _on(1078.0, 19.5), _towards_road(1078.0, 0.25), 1.0, "none")
	_raw("tourist_group", "fTuristi", _on(1099.0, 18.0), _towards_road(1099.0, -0.3), 1.0, "none")
	# 4 ienuperi pe mesa, in jurul ramadei si al camioanelor (trunchi, >= 12 m de axa).
	for g in [[1090.0, 44.0, 1.15], [1124.0, 33.0, 1.0], [1060.0, 38.0, 0.95], [1128.0, 47.0, 1.2]]:
		_raw("juniper", "fIenupar", _on(g[0], g[1]), _rng.randf() * TAU, g[2], "")
	# 5 petice de rabbitbrush (accentul galben), grupe de 2-3, in jurul belvederului.
	for g in [[1058.0, 30.0, 3], [1117.0, 27.0, 3], [1094.0, 38.0, 2], [1124.0, 42.0, 2], [1064.0, 44.0, 3]]:
		_patch("rabbitbrush", g[0], g[1], g[2])
		_patch("sagebrush", g[0] + 2.0, g[1] + 2.0, 1)


func _patch(model: String, s: float, lat: float, count: int) -> void:
	var q := _at(s)
	var n: Vector2 = q["n"]
	var d: Vector2 = q["d"]
	for i in count:
		var p := _off(q, lat)
		var ox := _rng.randf_range(-1.8, 1.8)
		var oz := _rng.randf_range(-1.4, 1.4)
		p.x += n.x * oz + d.x * ox
		p.z += n.y * oz + d.y * ox
		p.y = _sol(p.x, p.z)
		var base := "fRabbit" if model == "rabbitbrush" else "fSalvie"
		_raw(model, base, p, _rng.randf() * TAU, _rng.randf_range(1.0, 1.35), "none")


## Formatiile: hoodoo la ~45 m (axa 51), butte_small_c la ~52 m (axa 58), pe
## stanga, la capetele belvederului, nu in fata lui. Un rock_fin mic la 30 m.
func _formations() -> void:
	_raw("hoodoo", "fHoodoo", _on(1022.0, 52.0), 2.2, 1.0, "")
	_raw("butte_small_c", "fButteC", _on(1150.0, 58.0), 0.7, 1.0, "")
	_raw("rock_fin", "fFin", _on(1186.0, 34.0), 1.3, 0.9, "")


## 6 grupuri de talus pe fundul rapei (dreapta, la -13 m), fara coliziune:
## nu se ajunge acolo. Doar `none`.
func _ravine_floor() -> void:
	for g in [[1012.0, -24.0], [1058.0, -30.0], [1104.0, -22.0], [1146.0, -34.0],
			[1190.0, -26.0], [1222.0, -30.0]]:
		_raw("talus_boulders_a" if _rng.randf() < 0.5 else "talus_boulders_b", "fTalus",
			_on(g[0], g[1]), _rng.randf() * TAU, _rng.randf_range(0.8, 1.2), "none")


func _in_belvedere(s: float, lat: float) -> bool:
	return s > BEL_S0 - 6.0 and s < BEL_S1 + 8.0 and lat > BEL_L0 and lat < BEL_L1 + 4.0


## Palcuri MIXTE (ienupar mic + salvie + rabbitbrush, 3-6 piese), pe stanga de
## la 3,5 la ~25 m de margine, cu goluri neregulate; pe dreapta doar unde nu
## e rapa (inainte de 0.47 si dupa 0.595) si pe malul indepartat al rapei.
func _vegetation() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 424242
	var margins := [3.6, 9.0, 18.0, 27.0]
	var s := S0 - 2.0
	var n_cl := 0
	while s < S1 + 6.0:
		for side in [1.0, -1.0]:
			if side < 0.0 and s > 976.0 and s < 1250.0:
				continue
			# gol neregulat: ~25% din pozitii lipsesc
			if r.randf() < 0.5:
				continue
			var layer: int = r.randi_range(1, 3)
			var m: float = margins[layer] + r.randf_range(-0.6, 1.8)
			var lat: float = side * (SEMI + m)
			var ss: float = s + r.randf_range(-2.5, 2.5)
			n_cl += 1
			if _in_belvedere(ss, absf(lat)) and side > 0.0:
				continue
			_mixed_clump(r, ss, lat, layer)
			if n_cl % 4 == 1:
				var rl: float = side * (SEMI + r.randf_range(6.0, 26.0))
				var rs: float = ss + r.randf_range(3.0, 6.0)
				if side < 0.0 and rs > 976.0 and rs < 1250.0:
					continue
				if _in_belvedere(rs, absf(rl)) and side > 0.0:
					continue
				var pick := "talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b"
				_raw(pick, "fPiatra", _on(rs, rl), r.randf() * TAU, r.randf_range(0.45, 0.7), "none")
		s += 4.6
	_near_strip(r)
	# Malul indepartat al rapei (la ~55-75 m dreapta, plat): pete de verde
	# si galben care dau a doua treapta a cadrului peste sant.
	s = 1000.0
	while s < 1240.0:
		var lat2: float = -(SEMI + r.randf_range(50.0, 70.0))
		_mixed_clump(r, s + r.randf_range(-3.0, 3.0), lat2, 2, true)
		s += r.randf_range(12.0, 20.0)
	# Fundul rapei (-13 m): pete rare de salvie/rabbitbrush, cat sa nu para goala.
	s = 1000.0
	while s < 1240.0:
		_mixed_clump(r, s + r.randf_range(-3.0, 3.0), -(SEMI + r.randf_range(14.0, 30.0)), 0, true)
		s += r.randf_range(12.0, 20.0)


func _mixed_clump(r: RandomNumberGenerator, s: float, lat: float, layer: int,
		strict := false) -> void:
	var q := _at(s)
	var n: Vector2 = q["n"]
	var d: Vector2 = q["d"]
	var kinds: Array[String] = []
	var scales: Array[float] = []
	for i in r.randi_range(1, 2):
		if layer > 0 and r.randf() < 0.5:
			kinds.append("juniper")
			scales.append(r.randf_range(0.55, 0.8))
		else:
			kinds.append("sagebrush")
			scales.append(r.randf_range(1.3, 1.6))
	for i in r.randi_range(1, 2):
		kinds.append("rabbitbrush")
		scales.append(r.randf_range(0.95, 1.25))
	for i in r.randi_range(1, 2):
		kinds.append("sagebrush")
		scales.append(r.randf_range(0.9, 1.15))
	for i in kinds.size():
		var ox := r.randf_range(-2.4, 2.4)
		var oz := r.randf_range(-1.6, 1.6)
		var p := _off(q, lat)
		p.x += n.x * oz + d.x * ox
		p.z += n.y * oz + d.y * ox
		p.y = _sol(p.x, p.z)
		# Taluzul rapei: raza pe teren si esantionul terenului nu se potrivesc;
		# piesa s-ar ingropa (probe_manual). O sarim.
		if strict and absf(p.y - _track._sampler.ground_y(p.x, p.z)) > 0.4:
			continue
		var base := "fIenupar" if kinds[i] == "juniper" else ("fRabbit" if kinds[i] == "rabbitbrush" else "fSalvie")
		_raw(kinds[i], base, p, r.randf() * TAU, scales[i], "")


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	var rid: String = RES[model]
	_cur.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, _zone, rid])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_cur.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_cur.append('metadata/coliziune = "%s"' % mode)
	_cur.append("")
	_last_name = "%s%d" % [base, _n]


func _meta_last(line: String) -> void:
	_cur.insert(_cur.size() - 1, line)


## Animalele statice au doua poze in acelasi GLB: o ascundem pe cea de mers.
func _hide_pose() -> void:
	_cur.append('[node name="Pose_Walk" parent="%s/%s" index="1"]' % [_zone, _last_name])
	_cur.append("visible = false")
	_cur.append("")


func _write() -> void:
	print("; asezate %d piese" % _n)
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	fa.store_string("
".join(_out) + "
")
	fa.close()
	print("; scris %s" % _out_path)


func _sol(x: float, z: float) -> float:
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


## Fasia de 3-6 m de la bordura, ambele parti: palcuri de 5-8 tufe lipite,
## la scara mare (salvie/rabbitbrush 1,4-1,9, ienupar 0,8-1,1 de la 3 m), ca o
## margine continua. Dreapta doar unde terenul e inca plat (nu pe cadere).
func _near_strip(r: RandomNumberGenerator) -> void:
	var s := S0 - 2.0
	while s < S1 + 6.0:
		for side in [1.0, -1.0]:
			if side < 0.0 and s > 976.0 and s < 1250.0:
				continue
			var lat: float = side * (SEMI + r.randf_range(3.8, 5.6))
			var q := _at(s + r.randf_range(-1.0, 1.0))
			var n: Vector2 = q["n"]
			var d: Vector2 = q["d"]
			var cnt := r.randi_range(5, 8)
			for i in cnt:
				var kind := "sagebrush"
				var sc := r.randf_range(1.4, 1.9)
				var roll := r.randf()
				if roll < 0.3:
					kind = "rabbitbrush"
					sc = r.randf_range(1.4, 1.8)
				elif roll < 0.38:
					kind = "juniper"
					sc = r.randf_range(0.7, 0.95)
				var ox := r.randf_range(-2.6, 2.6)
				var oz: float = r.randf_range(-0.9, 1.2) * float(side)
				var p := _off(q, lat)
				p.x += n.x * oz + d.x * ox
				p.z += n.y * oz + d.y * ox
				p.y = _sol(p.x, p.z)
				var base := "fIenupar" if kind == "juniper" else ("fRabbit" if kind == "rabbitbrush" else "fSalvie")
				_raw(kind, base, p, r.randf() * TAU, sc, "")
			if r.randf() < 0.6:
				var bp := _off(q, lat + float(side) * r.randf_range(-0.8, 1.6))
				bp.y = _sol(bp.x, bp.z)
				_raw("talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b", "fPiatra", bp,
					r.randf() * TAU, r.randf_range(0.4, 0.6), "none")
		s += 5.5
