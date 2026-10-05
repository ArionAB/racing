extends Node
## Generator de decor MANUAL pentru POI B - COBORAREA US-163 (Track19, Monument
## Valley, frac 0.056-0.127) + GOSPODARIA DIN VALE. Tiparul gen_decor_mv_a.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvB.tscn -- \
##       --out=C:/cale/zonaB.part
##   (--terrain tipareste cotele raftului gospodariei)
##
## Scrie doua fisiere: <out> (ZonaB) si <out>.gosp (ZonaGospodarie), de lipit in
## Track19.tscn sub nodurile respective. Firele (TelegraphWires) continua
## sirul lui A: primul stalp din `poles` e ULTIMUL stalp al lui A (aStalp8),
## fara instanta (apartine lui A), ca firul sa treaca din A in B.

const TRACK := "res://scenes/tracks/Track19.tscn"
const SEMI := 7.0
## Ultimul stalp al lui A (din Track19.tscn, aStalp8): ancora sirului de fire.
const A_LAST_POLE := Vector3(318.086639, 11.634567, -13.618431)
const A_LAST_YAW := 0.095644

const RES := {
	"trading_post": "s_trading_post", "pickup_old": "s_pickup_old",
	"horse_bay": "11_horse_bay", "horse_pinto": "11_horse_pinto",
	"horse_black": "s_horse_black", "telegraph_pole": "s_telegraph_pole",
	"wire_fence": "s_wire_fence", "raven": "s_raven",
	"talus_boulders_a": "s_talus_boulders_a", "talus_boulders_b": "s_talus_boulders_b",
	"juniper": "s_juniper", "corral": "s_corral", "sagebrush": "s_sagebrush",
	"rabbitbrush": "s_rabbitbrush", "butte_small_b": "s_butte_small_b",
	"butte_small_c": "s_butte_small_c", "rock_fin": "s_rock_fin",
	"hoodoo": "s_hoodoo", "homestead_house": "s_homestead_house",
	"hogan": "s_hogan", "sheep": "s_sheep", "shade_ramada": "s_shade_ramada",
}

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _gosp: Array[String] = []
var _cur: Array[String] = _out
var _zone := "DecorManual/ZonaB"
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
	_zone = "DecorManual/ZonaB"
	_cur = _out
	_poles()
	_fence()
	_formations()
	_scatter()
	_wires_node()
	_zone = "DecorManual/ZonaGospodarie"
	_cur = _gosp
	_homestead()
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


func _grand(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			var m := c as MeshInstance3D
			var bb := m.global_transform * m.get_aabb()
			if bb.size.y > 14.0 and bb.position.x > 380.0 and bb.position.x < 600.0 					and bb.position.z > 20.0 and bb.position.z < 230.0:
				print("GRAND %s/%s aabb=%s" % [m.get_parent().name, m.name, bb])
		_grand(c)


func _print_terrain() -> void:
	_grand(_track)
	for x in [420.0, 430.0, 440.0, 450.0, 460.0, 470.0]:
		var line := "x=%d: " % int(x)
		for z in [60.0, 70.0, 85.0, 100.0, 115.0, 130.0, 145.0, 160.0, 170.0]:
			line += "z%d=%.1f " % [int(z), _sol(x, z)]
		print(line)
	for s in [100.0, 117.0, 150.0, 200.0, 250.0, 266.0]:
		print("s=%.0f p=%s" % [s, _at(s)["p"]])
	for s in [126.0, 150.0, 180.0, 210.0, 240.0, 262.0]:
		var line := "s=%d road=%.2f |" % [s, _at(s)["p"].y]
		for lat in [8.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 18.0, 22.0]:
			var q := _off(_at(s), lat)
			line += " %d:%.1f" % [lat, _sol(q.x, q.z)]
		print(line)


# ------------------------------------------------------------------ piese

## 8 stalpi pe partea ESTICA (exteriorul), la 10 m de margine (17 m de axa),
## spatiere 18 m - acelasi ritm si aceeasi parte ca A (ultimul lui: s = 108).
func _poles() -> void:
	_pole_pos.append(A_LAST_POLE)
	_pole_yaw.append(A_LAST_YAW)
	var k := 0
	# Pe coborare soseaua sta pe un rambleu: umarul plat tine pana la ~13 m de
	# axa, apoi terenul cade 1:1,5 spre valea y = 0 (masurat cu raza pe teren).
	# Linia de stalpi se strange deci de la 16 m (ca la A: 17) la 13 m.
	var lats := [16.0, 15.0, 14.0, 13.5, 13.0, 13.0, 13.0, 13.0]
	for s in range(126, 253, 18):
		var q := _at(float(s))
		var n: Vector2 = q["n"]
		var pp := _on(float(s), lats[k])
		var yaw := atan2(-n.y, n.x)
		var xl := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3.RIGHT
		assert(absf(xl.x * n.x + xl.z * n.y) > 0.999)
		_raw("telegraph_pole", "bStalp", pp, yaw, 1.0, "")
		_pole_pos.append(pp)
		_pole_yaw.append(yaw)
		k += 1
		if k == 4:
			# Un corb pe traversa stalpului 4 (varful izolatorului stang).
			var tip := pp + Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(-0.75, 7.52, 0.0)
			_raw("raven", "bCorb", tip, yaw + PI * 0.5 + 0.3, 1.4, "")
			_meta_last("metadata/ancora_sol = Vector3(0, %.3f, 0)" % (-7.52 / 1.4))


## 13,5 m de axa (ca A) pe platou; coboara la 11,5 m pe rambleu, ca sa nu stea
## pe buza taluzului.
func _fence_lat(s: float) -> float:
	return 13.5 - 2.0 * clampf((s - 94.0) / 60.0, 0.0, 1.0)


## Gard de sarma la 6,5 m de margine (13,5 m de axa), est, de la s = 94 (unde
## se opreste cel al lui A) la s = 246: 38 de segmente (152 m).
func _fence() -> void:
	var s := 94.0
	while s < 246.0:
		var q0 := _at(s)
		var q1 := _at(s + 4.0)
		var a := _off(q0, _fence_lat(s))
		var b := _off(q1, _fence_lat(s + 4.0))
		var m := (a + b) * 0.5
		var yaw := atan2(b.x - a.x, b.z - a.z)
		_raw("wire_fence", "bGard", Vector3(m.x, _sol(m.x, m.z), m.z), yaw, 1.0, "")
		s += 4.0


## Formatiile: perechea butte_small_b/c (VEST, 40-55 m de margine: diorama le
## pune pe stanga drumului, iar la est ar fi taiat privirea spre gospodarie),
## rock_fin vest la 25 m, hoodoo vest la 45 m.
func _formations() -> void:
	_raw("butte_small_b", "bButteB", _on(150.0, -(SEMI + 42.0)), 0.5, 1.0, "")
	_raw("butte_small_c", "bButteC", _on(167.0, -(SEMI + 54.0)), 2.3, 1.0, "")
	_raw("rock_fin", "bFin", _on(205.0, -(SEMI + 27.0)), 1.1, 1.0, "")
	_raw("hoodoo", "bHoodoo", _on(232.0, -(SEMI + 46.0)), 4.0, 1.0, "")


func _scatter() -> void:
	# Grohotis: 3 grupuri (vest 9 m, est 22 m, vest 12 m de margine).
	for g in [[140.0, -(SEMI + 9.0), "talus_boulders_a"],
			[188.0, SEMI + 22.0, "talus_boulders_b"],
			[222.0, -(SEMI + 12.0), "talus_boulders_a"]]:
		_raw(g[2], "bTalus", _on(g[0], g[1]), _rng.randf() * TAU, 1.0, "")
	# Ienuperi (3), la distante diferite.
	for g in [[158.0, -(SEMI + 15.0)], [186.0, SEMI + 30.0], [214.0, -(SEMI + 22.0)]]:
		_raw("juniper", "bIenupar", _on(g[0], g[1]), _rng.randf() * TAU,
			_rng.randf_range(0.9, 1.15), "")
	_vegetation()


## Runda 2: palcuri MIXTE pe ambele parti, pe 3 adancimi fata de margine
## (3, 10, 20 m), in loc de tufe izolate. Pozitiile prin raza pe teren (_on),
## deci stau pe taluz acolo unde rambleul cade. Ienuperi doar de la adancimea
## a doua (trunchiul are coliziune, nu la < 2,5 m de margine). Pietrele mici sunt
## fara coliziune. RNG separat: nu muta zarurile gospodariei.
func _vegetation() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 90210
	var margins := [3.0, 10.0, 20.0]
	var s := 118.0
	var n_cl := 0
	while s < 262.0:
		for side in [1.0, -1.0]:
			var layer: int = r.randi_range(0, 2)
			# Fiecare 3-4 palcuri pastram un strat apropiat; primele randuri deasa.
			if n_cl % 2 == 0:
				layer = 0
			var m: float = margins[layer] + r.randf_range(-1.0, 1.5)
			var lat: float = side * (SEMI + m)
			if side > 0.0 and layer == 1:
				lat = SEMI + 12.0 + r.randf_range(0.0, 2.0)  # dincolo de stalpi/gard
			var ss: float = s + r.randf_range(-2.5, 2.5)
			_mixed_clump(r, ss, lat, layer)
			n_cl += 1
			# Piatra mica printre palcuri, la fiecare al treilea.
			if n_cl % 4 == 1:
				var rl: float = side * (SEMI + r.randf_range(6.0, 24.0))
				var rs: float = ss + r.randf_range(3.0, 6.0)
				var pick := "talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b"
				_raw(pick, "bPiatra", _on(rs, rl), r.randf() * TAU, r.randf_range(0.45, 0.7), "none")
		s += 6.5


func _mixed_clump(r: RandomNumberGenerator, s: float, lat: float, layer: int) -> void:
	var q := _at(s)
	var n: Vector2 = q["n"]
	var d: Vector2 = q["d"]
	var kinds: Array[String] = []
	var scales: Array[float] = []
	# 2-3 baza: ienupar mic (de la stratul 2) sau salvie mare.
	for i in r.randi_range(1, 2):
		if layer > 0 and r.randf() < 0.55:
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
		var oz := r.randf_range(-1.8, 1.8)
		var p := _off(q, lat)
		p.x += n.x * oz + d.x * ox
		p.z += n.y * oz + d.y * ox
		p.y = _sol(p.x, p.z)
		var base := "bIenupar" if kinds[i] == "juniper" else ("bRabbit" if kinds[i] == "rabbitbrush" else "bSalvie")
		_raw(kinds[i], base, p, r.randf() * TAU, scales[i], "")


func _clump(model: String, base: String, s: float, lat: float, count: int,
		rx: float, rz: float) -> void:
	var q := _at(s)
	var n: Vector2 = q["n"]
	var d: Vector2 = q["d"]
	for i in count:
		var ox := _rng.randf_range(-rx, rx)
		var oz := _rng.randf_range(-rz, rz)
		var p := _off(q, lat)
		p.x += n.x * oz + d.x * ox
		p.z += n.y * oz + d.y * ox
		p.y = _sol(p.x, p.z)
		_raw(model, base, p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.3), "")


func _wires_node() -> void:
	_out.append('[node name="Fire" type="Node3D" parent="DecorManual/ZonaB"]')
	_out.append('script = ExtResource("tw_wires")')
	var ps: Array[String] = []
	var ys: Array[String] = []
	for i in _pole_pos.size():
		var v := _pole_pos[i]
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
		ys.append("%.4f" % _pole_yaw[i])
	_out.append("poles = PackedVector3Array(%s)" % ", ".join(ps))
	_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
	_out.append("")


# ------------------------------------------------------------------ gospodaria

## Yaw care roteste -Z local (fata pieselor) spre directia (dx, dz) in plan.
func _face(dx: float, dz: float) -> float:
	var yaw := atan2(-dx, -dz)
	var f := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(0, 0, -1)
	var l := Vector2(dx, dz).normalized()
	assert(f.x * l.x + f.z * l.y > 0.999)
	return yaw


func _g(x: float, z: float) -> Vector3:
	return Vector3(x, _sol(x, z), z)


## Grup strans pe raftul y ~ +4,3, citit la 125-170 m. Siluetele de orizont
## din track.gd pun `FarMesa_B` (AABB x 418-465, z 101-268, 17 m) chiar pe
## jumatatea de sud a ploturilor (x 425-470, z 70-170): gospodaria sta deci in
## partea de NORD a raftului (z 62-100), cu mesa in spate (ca in dioram, unde
## sta la poalele unei mese). Hoganul sta la NE de casa, nu in spatele ei: dinspre drum si grila (azimut
## ~ ESE) casa l-ar fi ascuns. Fata casei spre vest = spre drum si grila, pickup-ul intre ele si tarc, tarcul cu cai, oile, umbrar.
func _homestead() -> void:
	_raw("homestead_house", "gCasa", _g(440.0, 79.0), _face(-1.0, 0.25), 1.0, "")
	# Usa hoganului spre EST (rotatie -90 grade pe Y, derivata din produs scalar).
	_raw("hogan", "gHogan", _g(453.0, 63.0), _face(1.0, 0.0), 1.0, "")
	_raw("pickup_old", "gPickup", _g(434.0, 89.0), _face(-0.4, 1.0), 1.0, "")
	# Tarc: poarta (-Z local) spre vest.
	_raw("corral", "gTarc", _g(447.0, 93.0), _face(-1.0, 0.0), 1.0, "")
	_raw("shade_ramada", "gUmbrar", _g(468.0, 79.0), _face(-1.0, 0.0), 1.0, "")
	# 3 cai statici: doi in tarc, unul in fata lui.
	var hk := ["horse_bay", "horse_black", "horse_pinto"]
	var hp := [_g(445.0, 92.0), _g(449.0, 95.0), _g(431.0, 92.0)]
	for k in 3:
		_raw(hk[k], "gCal", hp[k], _rng.randf() * TAU, 1.0, "none")
		_hide_pose()
	# 10 oi in turma, la vest de tarc (pe sub mesa din spate, z < 100).
	for i in 10:
		var p := _g(430.0 + _rng.randf_range(-5.0, 5.0), 96.0 + _rng.randf_range(-2.5, 2.5))
		_raw("sheep", "gOaie", p, _rng.randf() * TAU, _rng.randf_range(0.95, 1.1), "none")
		_hide_pose()
	# Gard ~40 m: linie pe Z, la vest de casa (10 segmente).
	for i in 10:
		var z := 60.0 + 4.0 * i + 2.0
		_raw("wire_fence", "gGard", _g(427.0, z), 0.0, 1.0, "")
	# 3 ienuperi.
	for p0 in [_g(419.0, 80.0), _g(472.0, 68.0), _g(463.0, 58.0)]:
		_raw("juniper", "gIenupar", p0, _rng.randf() * TAU, 1.1, "")


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
		for line in _out + _gosp:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	fa.store_string("\n".join(_out) + "\n")
	fa.close()
	var fb := FileAccess.open(_out_path + ".gosp", FileAccess.WRITE)
	fb.store_string("\n".join(_gosp) + "\n")
	fb.close()
	print("; scris %s (+ .gosp)" % _out_path)


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
