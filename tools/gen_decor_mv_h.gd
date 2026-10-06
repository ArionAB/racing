extends Node
## Generator de decor MANUAL pentru POI H - US-163 INAPOI (Track19, Monument
## Valley, frac 0.866-0.985, dreapta z = -40, x -68 -> 190). Tiparul G2/A.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvH.tscn -- --out=C:/cale/zonaH.part
##
## Scrie fragmentul de lipit in Track19.tscn sub DecorManual/ZonaH.

const TRACK := "res://scenes/tracks/Track19.tscn"
const ZONE := "DecorManual/ZonaH"
const SEMI := 7.0
## Linia de telegraf: stanga (nord) la 16,5 m de axa, ca G2 (ultimul lui stalp la
## s = 1796) si A (stalpii lui la 17 m, primul la x = 192).
const POLE_LAT := 16.5
const POLE_N := 11
const FENCE_LAT := 13.5
const S_G2_LAST := 1796.0

const RES := {
	"telegraph_pole": "s_telegraph_pole", "raven": "s_raven", "wire_fence": "s_wire_fence",
	"talus_boulders_a": "s_talus_boulders_a", "talus_boulders_b": "s_talus_boulders_b",
	"juniper": "s_juniper", "sagebrush": "s_sagebrush", "rabbitbrush": "s_rabbitbrush",
	"butte_small_b": "s_butte_small_b", "hoodoo": "s_hoodoo", "rock_fin": "s_rock_fin",
	"corral": "s_corral", "horse_bay": "11_horse_bay",
}

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _n := 0
var _out_path := ""
var _pts: PackedVector3Array
var _cum: PackedFloat32Array
var _len := 0.0
var _last_name := ""
var _s0 := 0.0   # s al ultimului stalp H (x ~ 174)
var _s1 := 0.0   # s la x = 190 (granita cu A)


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
	_index_path()
	_s1 = _s_at_x(190.0)
	_s0 = _s_at_x(174.0)
	print("; len=%.1f s(x=190)=%.1f s(x=174)=%.1f  frac 0.866=%.1f 0.985=%.1f" % [
		_len, _s1, _s0, 0.866 * _len, 0.985 * _len])
	_build()
	_write()
	get_tree().quit(0)


func _s_at_x(x: float) -> float:
	for i in _pts.size() - 1:
		if _pts[i].x <= x and _pts[i + 1].x > x and _cum[i] > 1700.0:
			return _cum[i] + (x - _pts[i].x) / (_pts[i + 1].x - _pts[i].x) * (_cum[i + 1] - _cum[i])
	return -1.0


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
	var half := minf(_track.half_width, _track.width_at_index(i))
	return {"p": p, "d": d, "n": Vector2(d.y, -d.x), "half": half}


func _off(q: Dictionary, lat: float) -> Vector3:
	var n: Vector2 = q["n"]
	var p3: Vector3 = q["p"]
	return Vector3(p3.x + n.x * lat, 0.0, p3.z + n.y * lat)


func _on(s: float, lat: float) -> Vector3:
	var p := _off(_at(s), lat)
	p.y = _sol(p.x, p.z)
	return p


## Yaw care roteste -Z local (fata pieselor) spre directia (dx, dz) in plan.
func _face(dx: float, dz: float) -> float:
	var yaw := atan2(-dx, -dz)
	var f := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(0, 0, -1)
	var l := Vector2(dx, dz).normalized()
	assert(f.x * l.x + f.z * l.y > 0.999)
	return yaw


# ------------------------------------------------------------------ piese

func _build() -> void:
	_poles()
	_fence()
	_formations()
	_corral()
	_talus()
	_clusters()
	_patches()


func _yaw_perp(q: Dictionary) -> float:
	var n: Vector2 = q["n"]
	var yaw := atan2(-n.y, n.x)
	var xl := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3.RIGHT
	assert(absf(xl.x * n.x + xl.z * n.y) > 0.999)
	return yaw


## 11 stalpi pe stanga (nord) la 16,5 m de axa, de la G2 (ultimul lui, s 1796)
## pana la x ~ 174; Fire-ul leaga ultimul stalp G2 la primul H si ultimul H la
## primul stalp al lui A (x = 192, 17 m de axa): o singura linie de la G2 la A.
func _poles() -> void:
	var ps: Array[String] = ["-88.465, 0.239, -38.873"]
	var ys: Array[String] = ["2.1784"]
	for k in range(1, POLE_N + 1):
		var s := S_G2_LAST + (_s0 - S_G2_LAST) * float(k) / float(POLE_N)
		var q := _at(s)
		var yaw := _yaw_perp(q)
		var pp := _on(s, POLE_LAT)
		_raw("telegraph_pole", "hStalp", pp, yaw, 1.0, "")
		ps.append("%.3f, %.3f, %.3f" % [pp.x, pp.y, pp.z])
		ys.append("%.4f" % yaw)
		if k == 6:
			var tip := pp + Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(-0.75, 7.52, 0.0)
			_raw("raven", "hCorb", tip, yaw + PI * 0.5 + 0.3, 1.4, "")
			_meta_last("metadata/ancora_sol = Vector3(0, %.3f, 0)" % (-7.52 / 1.4))
	ps.append("192.015, 10.928, -57.000")
	ys.append("1.5708")
	_out.append('[node name="Fire" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("tw_wires")')
	_out.append("poles = PackedVector3Array(%s)" % ", ".join(ps))
	_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
	_out.append("")


## Gard de sarma paralel, la 6,5 m de margine (13,5 m de axa), corzi de 4 m, de
## la x ~ 0 pana la x ~ 200 (de aici continua gardul lui A, acelasi lat).
func _fence() -> void:
	var s := _s_at_x(20.0)
	var s_end := _s_at_x(200.0)
	while s < s_end - 0.1:
		var a := _off(_at(s), FENCE_LAT)
		var b := _off(_at(s + 4.0), FENCE_LAT)
		var m := (a + b) * 0.5
		_raw("wire_fence", "hGard", Vector3(m.x, _sol(m.x, m.z), m.z), atan2(b.x - a.x, b.z - a.z), 1.0, "")
		s += 4.0


## Formatiuni care rup campul la 20-60 m: butte mic (nord, 50 m), pereche de
## hoodoo-uri si un ac de stanca (sud), un ac pe nord aproape de G2. Nu pe axa
## privirii spre turn/moara (z = -40 in fata) - toate la >= 28 m lateral.
func _formations() -> void:
	_raw("butte_small_b", "hButte", _on(_s_at_x(64.0), 52.0), 2.2, 0.8, "")
	_raw("hoodoo", "hHoodoo", _on(_s_at_x(112.0), -33.0), 0.7, 0.9, "")
	_raw("hoodoo", "hHoodoo", _on(_s_at_x(119.0), -38.0), 3.9, 0.7, "")
	_raw("rock_fin", "hAc", _on(_s_at_x(-18.0), 30.0), 5.6, 0.8, "")


## Tarc cu un cal pe nord, la 28 m de axa, pe langa gard (gardul trece prin fata).
func _corral() -> void:
	var s := _s_at_x(138.0)
	var q := _at(s)
	var d: Vector2 = q["d"]
	var p := _on(s, 29.0)
	_raw("corral", "hTarc", p, atan2(-d.y, d.x), 1.0, "")
	var hp := _on(s + 9.5, 26.0)
	_raw("horse_bay", "hCal", hp, _face(d.x * 0.8 + q["n"].x * 0.6, d.y * 0.8 + q["n"].y * 0.6), 1.0, "none")


func _talus() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 86601
	var spec := [[_s_at_x(30.0), 1.0, 22.0, "talus_boulders_b", 1.1],
		[_s_at_x(158.0), -1.0, 19.0, "talus_boulders_a", 1.2]]
	for g in spec:
		_raw(g[3], "hTalus", _on(g[0], g[1] * g[2]), r.randf() * TAU, g[4], "none")


func _ok_spot(p: Vector3, s: float, lat: float, rad: float = 0.0) -> bool:
	# nu pe asfalt/margine, nu in zona lui A (x >= 190), nu in afara zonei H
	if p.x > 188.0 or s < 1812.0:
		return false
	if absf(lat) < SEMI + 0.3 + rad:
		return false
	return true


## Ciorchini mixte (ienupar jos + salvie mare + rabbitbrush accent ~15 %,
## 4-8 plante lipite, 1-3 bolovani `none`), de la 2 m de bordura pana la ~22 m.
## Ienuperii doar la >= 3,8 m de bordura si in afara liniei gardului/stalpilor.
func _clusters() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 86602
	var n_cl := 0
	for side in [1.0, -1.0]:
		var s := 1814.0 + (7.0 if side < 0.0 else 0.0)
		while s < _s1 - 2.0:
			if r.randf() < 0.15:
				s += r.randf_range(6.0, 12.0)
				continue
			var layer := r.randi_range(0, 4)
			if n_cl % 2 == 0:
				layer = r.randi_range(0, 1)
			var m: float = [2.0, 3.3, 5.0, 13.0, 21.0][layer] + r.randf_range(-0.5, 1.2)
			_mixed_clump(r, s + r.randf_range(-2.0, 2.0), side, m)
			n_cl += 1
			s += r.randf_range(13.0, 21.0)
	print("; ciorchini: %d" % n_cl)


func _mixed_clump(r: RandomNumberGenerator, s: float, side: float, margin: float) -> void:
	var q := _at(s)
	var d: Vector2 = q["d"]
	var count := r.randi_range(4, 7)
	for i in count:
		var roll := r.randf()
		var kind := "sagebrush"
		var sc := r.randf_range(1.4, 1.9)
		if roll < 0.18:
			kind = "juniper"
			sc = r.randf_range(0.7, 0.95)
		elif roll > 0.85:
			kind = "rabbitbrush"
			sc = r.randf_range(1.0, 1.3)
		var ox := r.randf_range(-2.4, 2.4)
		var oz := r.randf_range(-1.6, 1.6)
		var rad: float = (1.3 if kind == "juniper" else (1.0 if kind == "rabbitbrush" else 1.2)) * sc
		var lat: float = side * (SEMI + margin) + oz
		var lat_min: float = SEMI + 0.3 + rad
		if absf(lat) < lat_min:
			lat = side * lat_min
		if kind == "juniper" and (absf(lat) - SEMI < 3.8 + 1.3 * sc or (side > 0.0 and absf(absf(lat) - FENCE_LAT) < 1.5) or (side > 0.0 and absf(absf(lat) - POLE_LAT) < 2.5)):
			kind = "sagebrush"
			sc = r.randf_range(1.4, 1.8)
		var p := _off(q, lat)
		p.x += d.x * ox
		p.z += d.y * ox
		p.y = _sol(p.x, p.z)
		if not _ok_spot(p, s + ox, lat, rad * 0.0):
			continue
		var base := "hIenupar" if kind == "juniper" else ("hRabbit" if kind == "rabbitbrush" else "hSalvie")
		_raw(kind, base, p, r.randf() * TAU, sc, "")
	for k in r.randi_range(1, 3):
		var bl: float = side * (SEMI + margin + r.randf_range(-1.0, 1.0))
		if absf(bl) < SEMI + 1.4:
			bl = side * (SEMI + 1.4)
		var bp := _off(q, bl)
		bp.x += d.x * r.randf_range(-3.0, 3.0)
		bp.z += d.y * r.randf_range(-3.0, 3.0)
		bp.y = _sol(bp.x, bp.z)
		if not _ok_spot(bp, s, bl, 0.4):
			continue
		var pick := "talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b"
		_raw(pick, "hPiatra", bp, r.randf() * TAU, r.randf_range(0.3, 0.45), "none")


## 3 petice de rabbitbrush (accentul galben) la 24-40 m de axa.
func _patches() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4418
	for sp in [[_s_at_x(20.0), 1.0, 30.0], [_s_at_x(96.0), -1.0, 26.0], [_s_at_x(160.0), 1.0, 36.0]]:
		for k in r.randi_range(4, 5):
			var s: float = sp[0] + r.randf_range(-4.0, 4.0)
			var lat: float = sp[1] * (sp[2] + r.randf_range(-3.0, 3.0))
			var p := _off(_at(s), lat)
			p.y = _sol(p.x, p.z)
			_raw("rabbitbrush", "hPetic", p, r.randf() * TAU, r.randf_range(0.95, 1.3), "")


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")
	_last_name = "%s%d" % [base, _n]


func _meta_last(line: String) -> void:
	_out.insert(_out.size() - 1, line)


func _write() -> void:
	print("; asezate %d piese" % _n)
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	fa.store_string("\n".join(_out) + "\n")
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
