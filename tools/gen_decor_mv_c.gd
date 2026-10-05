extends Node
## Generator de decor MANUAL pentru POI C - GRILA PENTRU VITE + inceputul Valley
## Drive (Track19, Monument Valley, frac 0.127-0.185). Tiparul gen_decor_mv_b/g2.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvC.tscn -- --survey
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvC.tscn -- --out=C:/cale/zonaC.part
##
## Scrie fragmentul de lipit in Track19.tscn sub DecorManual/ZonaC.
## Directia de mers e +Z (sud): +lat = est (stanga), -lat = vest (dreapta).

const TRACK := "res://scenes/tracks/Track19.tscn"
const ZONE := "DecorManual/ZonaC"
const GRID_FRAC := 0.1368
## Ultimul stalp al lui B (bStalp, din Track19.tscn): ancora firului.
const B_LAST_POLE := Vector3(313.254, 1.304, 131.722)
const B_LAST_YAW := -0.0138
## Culoarul cailor (CalC1/CalC2 traverseaza la z 226,7 / 230,1): fara coliziune.
const HORSE_Z0 := 212.0
const HORSE_Z1 := 244.0

const RES := {
	"telegraph_pole": "s_telegraph_pole", "wire_fence": "s_wire_fence",
	"talus_boulders_a": "s_talus_boulders_a", "talus_boulders_b": "s_talus_boulders_b",
	"juniper": "s_juniper", "sagebrush": "s_sagebrush",
	"rabbitbrush": "s_rabbitbrush", "cattle_guard": "s_cattle_guard",
	"open_range_sign": "s_open_range_sign",
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
var _s_grid := 0.0


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
	_s_grid = 286.6  # z = 166,1 (fractia pe index 0.1368 = 287 m pe lungime)
	if "--survey" in OS.get_cmdline_user_args():
		_survey()
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


func _survey() -> void:
	print("len=%.1f s_grid=%.1f (frac 0.127=%.1f, 0.185=%.1f)" % [_len, _s_grid, 0.127 * _len, 0.185 * _len])
	for s in range(250, 400, 10):
		var q := _at(float(s))
		var p3: Vector3 = q["p"]
		var line := "s=%d p=(%.1f,%.2f,%.1f) half=%.2f |" % [s, p3.x, p3.y, p3.z, q["half"]]
		for lat in [-30, -20, -12, -9, 9, 12, 15, 20, 30]:
			var o := _off(q, float(lat))
			line += " %d:%.1f" % [lat, _sol(o.x, o.z) - p3.y]
		print(line)


# ------------------------------------------------------------------ piese

func _build() -> void:
	_grid()
	_signs()
	_poles()
	_fence()
	_talus()
	_clusters()
	_patches()


## Yaw care roteste -Z local (fata pieselor) spre directia (dx, dz) in plan.
func _face(dx: float, dz: float) -> float:
	var yaw := atan2(-dx, -dz)
	var f := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(0, 0, -1)
	var l := Vector2(dx, dz).normalized()
	assert(f.x * l.x + f.z * l.y > 0.999)
	return yaw


## Grila: X-ul local peste drum (perpendicular pe directia de mers), centrata pe
## axa, la cota soselei. PLATA, fara coliziune, peste asfalt (pragul de suprafata).
func _grid() -> void:
	var q := _at(_s_grid)
	var d: Vector2 = q["d"]
	var n: Vector2 = q["n"]
	var yaw := atan2(-n.y, n.x)
	var xl := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3.RIGHT
	assert(absf(xl.x * d.x + xl.z * d.y) < 0.02)
	var p3: Vector3 = q["p"]
	print("; grila C: s=%.1f p=%s half=%.2f dot(X,d)=%.4f" % [_s_grid, p3, q["half"], xl.x * d.x + xl.z * d.y])
	_raw("cattle_guard", "cGrila", Vector3(p3.x, p3.y + 0.01, p3.z), yaw, 1.0, "")
	_meta_last("metadata/peste_asfalt = true")


## Semne cu calul, pe DREAPTA (vest), la 2,0 m de bordura, fara coliziune, cu
## fata spre masinile care vin: unul la 15 m inainte de grila, unul la ~80 m.
func _signs() -> void:
	for back in [15.0, 80.0]:
		var ss: float = _s_grid - back
		var qs := _at(ss)
		var half: float = qs["half"]
		var sp := _on(ss, -(half + 2.0))
		var from: Vector3 = _at(ss - 25.0)["p"]
		_raw("open_range_sign", "cSemn", sp, _face(from.x - sp.x, from.z - sp.z), 1.0, "none")


var _pole_pos := PackedVector3Array()
var _pole_yaw := PackedFloat32Array()


## Doi stalpi (continuarea sirului lui B, est, 13 m de axa, spatiere 18 m): sirul
## se termina la grila. Al doilea sta langa grila (la 1,7 m in spatele ei).
func _poles() -> void:
	_pole_pos.append(B_LAST_POLE)
	_pole_yaw.append(B_LAST_YAW)
	var s0 := _s_grid - 18.0 + 0.5
	for k in 2:
		var s := s0 + 18.0 * k
		var q := _at(s)
		var n: Vector2 = q["n"]
		var pp := _on(s, 13.0)
		var yaw := atan2(-n.y, n.x)
		var xl := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3.RIGHT
		assert(absf(xl.x * n.x + xl.z * n.y) > 0.999)
		_raw("telegraph_pole", "cStalp", pp, yaw, 1.0, "")
		_pole_pos.append(pp)
		_pole_yaw.append(yaw)
	_out.append('[node name="Fire" type="Node3D" parent="%s"]' % ZONE)
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


## Gardul lui B (est, 11,5 m de axa) continua de la s = 246 si se opreste cu 3 m
## inainte de grila.
func _fence() -> void:
	var s := 246.0
	while s + 4.0 <= _s_grid - 3.0:
		var a := _off(_at(s), 11.5)
		var b := _off(_at(s + 4.0), 11.5)
		var m := (a + b) * 0.5
		_raw("wire_fence", "cGard", Vector3(m.x, _sol(m.x, m.z), m.z),
			atan2(b.x - a.x, b.z - a.z), 1.0, "")
		s += 4.0


## 2 grupuri de talus (hull, 11+ m de bordura, in afara cercului r 25 al grilei si
## a culoarului cailor).
func _talus() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 12701
	_raw("talus_boulders_a", "cTalus", _on(_s_grid - 34.0, 6.5 + 20.0), r.randf() * TAU, 1.1, "")


func _axis_dist(p: Vector3) -> float:
	var best := 1e9
	for i in _pts.size():
		if _cum[i] < 220.0 or _cum[i] > 440.0:
			continue
		best = minf(best, Vector2(_pts[i].x - p.x, _pts[i].z - p.z).length())
	return best


func _ok_spot(p: Vector3, road_y: float, s: float, lat: float, rad: float = 0.0) -> bool:
	if _axis_dist(p) < 6.5 + 0.3 + rad:
		return false
	if road_y - p.y > 0.8:
		return false
	# nu pe grila (|ds| < 5 m, |lat| < 9.5)
	if absf(s - _s_grid) < 5.0 and absf(lat) < 9.5:
		return false
	return true


## Palcuri mixte (ienupar mic + salvie + rabbitbrush, 4-7 per palc), goluri
## neregulate, de la 2-4 m de bordura pana la ~25 m, pe ambele parti. Ienuperi
## (trunchi cu coliziune) doar la >= 3,8 m de bordura si in afara culoarului cailor.
func _clusters() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 12702
	var n_cl := 0
	var s0 := 0.127 * _len
	var s1 := 0.185 * _len
	for side in [1.0, -1.0]:
		var s := s0 + (3.0 if side < 0.0 else 0.0)
		while s < s1:
			if r.randf() < 0.2:
				s += r.randf_range(4.0, 7.0)
				continue
			var layer := r.randi_range(0, 3)
			if n_cl % 2 == 0:
				layer = r.randi_range(0, 1)
			elif r.randf() < 0.5:
				layer = r.randi_range(0, 1)
			var m: float = [2.0, 3.5, 8.0, 16.0][layer] + r.randf_range(-1.0, 1.5)
			_mixed_clump(r, s + r.randf_range(-2.0, 2.0), side, m)
			n_cl += 1
			s += r.randf_range(5.5, 8.5)
	print("; palcuri: %d" % n_cl)


func _mixed_clump(r: RandomNumberGenerator, s: float, side: float, margin: float) -> void:
	var q := _at(s)
	var d: Vector2 = q["d"]
	var half: float = q["half"]
	var kinds: Array[String] = []
	var scales: Array[float] = []
	var count := r.randi_range(4, 7)
	for i in count:
		var roll := r.randf()
		if roll < 0.28 and margin >= 3.0:
			kinds.append("juniper")
			scales.append(r.randf_range(0.7, 0.95))
		elif roll < 0.62:
			kinds.append("sagebrush")
			scales.append(r.randf_range(1.4, 1.9))
		else:
			kinds.append("rabbitbrush")
			scales.append(r.randf_range(1.2, 1.6))
	for i in kinds.size():
		var ox := r.randf_range(-2.6, 2.6)
		var oz := r.randf_range(-1.8, 1.8)
		var kind := kinds[i]
		var sc := scales[i]
		var rad: float = (1.3 if kind == "juniper" else (1.0 if kind == "rabbitbrush" else 1.2)) * sc
		var lat: float = side * (half + margin) + oz
		var lat_min: float = half + 0.3 + rad
		if absf(lat) < lat_min:
			lat = side * lat_min
		# ienuparul cere >= 3,8 m intre bordura si trunchi
		if kind == "juniper" and absf(lat) < half + 3.8:
			kind = "sagebrush"
			sc = r.randf_range(1.4, 1.8)
		var p := _off(q, lat)
		p.x += d.x * ox
		p.z += d.y * ox
		p.y = _sol(p.x, p.z)
		if kind == "juniper" and p.z > HORSE_Z0 and p.z < HORSE_Z1:
			kind = "sagebrush"
			sc = r.randf_range(1.4, 1.8)
		var road_y: float = (q["p"] as Vector3).y
		if not _ok_spot(p, road_y, s + ox, lat, 4.0 if kind == "juniper" else 0.0):
			continue
		var base := "cIenupar" if kind == "juniper" else ("cRabbit" if kind == "rabbitbrush" else "cSalvie")
		_raw(kind, base, p, r.randf() * TAU, sc, "")
	# 1-2 bolovani mici in aceeasi palca (fara coliziune)
	for k in r.randi_range(1, 2):
		var bl: float = side * (half + margin + r.randf_range(-1.0, 1.0))
		if absf(bl) < half + 1.2:
			bl = side * (half + 1.2)
		var bp := _off(q, bl)
		bp.x += d.x * r.randf_range(-3.0, 3.0)
		bp.z += d.y * r.randf_range(-3.0, 3.0)
		bp.y = _sol(bp.x, bp.z)
		if not _ok_spot(bp, (q["p"] as Vector3).y, s, bl, 0.4):
			continue
		var pick := "talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b"
		_raw(pick, "cPiatra", bp, r.randf() * TAU, r.randf_range(0.3, 0.45), "none")


## 2 petice de rabbitbrush (accentul galben) la 20-35 m de axa.
func _patches() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4418
	for sp in [[_s_grid + 28.0, 1.0, 26.0], [_s_grid + 62.0, -1.0, 24.0]]:
		for k in r.randi_range(4, 6):
			var s: float = sp[0] + r.randf_range(-4.0, 4.0)
			var lat: float = sp[1] * (sp[2] + r.randf_range(-3.0, 3.0))
			var q := _at(s)
			var p := _off(q, lat)
			p.y = _sol(p.x, p.z)
			if (q["p"] as Vector3).y - p.y > 0.8:
				continue
			_raw("rabbitbrush", "cPetic", p, r.randf() * TAU, r.randf_range(1.0, 1.4), "")


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
