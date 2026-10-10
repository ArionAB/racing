extends Node
## Generator de decor MANUAL pentru POI E — CAPUL SI CORNISA (Track20, Okinawa,
## frac 0.474-0.612). Calculeaza transformarile care se lipesc in Track20.tscn sub
## `DecorManual/ZonaE` (tiparul gen_decor_ok_f.gd). NU atinge traseul/terenul.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorOkE.tscn -- \
##       --out=C:/cale/zonaE.part [--survey]

const TRACK := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaE"

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid := RID()
var _space: PhysicsDirectSpaceState3D
var _sus_y := 0.0
var _sea := 0.05
var _out_path := ""
var _survey_only := false
var _out: Array[String] = []
var _ext: Array[String] = []
var _res := {}
var _n := 0
var _skipped := 0
var _rng := RandomNumberGenerator.new()
var _placed: Array[Vector4] = []  # x, z, raza, tip
var _counts := {}
var _skip_kinds: PackedStringArray = PackedStringArray()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a.begins_with("--skip="):
			_skip_kinds = a.trim_prefix("--skip=").split(",")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	if "--mesh" in OS.get_cmdline_user_args():
		for path in ["rocks/notch_rock_a", "rocks/notch_rock_b", "rocks/notch_rock_c",
				"plants/ryukyu_pine", "plants/cycad", "plants/fan_palm", "plants/bougainvillea",
				"structures/coral_stone_wall", "buildings/cape_lighthouse", "buildings/ryukyu_house_a",
				"buildings/ryukyu_house_c", "buildings/concrete_house_b", "structures/bus_stop_shelter",
				"rocks/limestone_cliff_module", "rocks/limestone_cliff_module_b", "props/fishing_net_rack", "props/convex_mirror"]:
			_aabb("res://assets/models/okinawa/%s.glb" % path)
		_aabb("res://assets/models/plants/hibiscus_bush.glb")
		_aabb("res://assets/models/trees/pandanus.glb")
		get_tree().quit(0)
		return
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_sampler = _track._sampler
	_sea = float(_sampler.mean_road_y()) + float(_track.sea_level_offset)
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 200927
	print("; mare y=%.2f" % _sea)
	_survey()
	if not _survey_only:
		_build()
		_write()
	get_tree().quit(0)


func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(round(fposmod(frac, 1.0) * float(n))) % n


func _closest(p: Vector3) -> int:
	var best := 0
	var bd := 1e18
	for i in _track.baked.size():
		var q: Vector3 = _track.baked[i]
		var d := Vector2(q.x - p.x, q.z - p.z).length_squared()
		if d < bd:
			bd = d
			best = i
	return best


func _tangent(i: int) -> Vector3:
	var n := _track.baked.size()
	var d: Vector3 = _track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n]
	d.y = 0.0
	return d.normalized()


func _left(i: int) -> Vector3:
	var t := _tangent(i)
	return Vector3(t.z, 0.0, -t.x)


func _sol(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
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
	return _sampler.ground_y(x, z)


## Distanta minima in plan pana la muchia asfaltului.
func _edge_dist(x: float, z: float) -> float:
	var best := INF
	for j in _track.baked.size():
		var b: Vector3 = _track.baked[j]
		var dx := x - b.x
		var dz := z - b.z
		if absf(dx) > 80.0 or absf(dz) > 80.0:
			continue
		best = minf(best, sqrt(dx * dx + dz * dz) - _track.width_at_index(j))
	return best


func _aabb(path: String) -> void:
	var n := (load(path) as PackedScene).instantiate() as Node3D
	add_child(n)
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		var bb: AABB = (n.global_transform.affine_inverse() * mi.global_transform) * mi.mesh.get_aabb()
		lo = lo.min(bb.position)
		hi = hi.max(bb.end)
	print("; %s  min %s  max %s" % [path.get_file(), str(lo), str(hi)])




func _survey() -> void:
	print("; frac    i     x       z      y   | adancime(+ = apa sub mare) la st 6/10/14/20/30/45/60/90 | dr")
	var f := 0.470
	while f <= 0.620 + 1e-6:
		var i := _idx(f)
		var p: Vector3 = _track.baked[i]
		var sl := ""
		var sr := ""
		for d: float in [6.0, 10.0, 14.0, 20.0, 30.0, 45.0, 60.0, 90.0]:
			var ql: Vector3 = p + _left(i) * d
			var qr: Vector3 = p - _left(i) * d
			sl += "%+6.1f " % (_sol(ql.x, ql.z) - _sea)
			sr += "%+6.1f " % (_sol(qr.x, qr.z) - _sea)
		print("; %.3f %4d %7.1f %7.1f %6.2f | %s| %s" % [f, i, p.x, p.z, p.y, sl, sr])
		f += 0.006


const PATHS := {
	"notch_a": "res://assets/models/okinawa/rocks/notch_rock_a.glb",
	"notch_b": "res://assets/models/okinawa/rocks/notch_rock_b.glb",
	"notch_c": "res://assets/models/okinawa/rocks/notch_rock_c.glb",
	"pine": "res://assets/models/okinawa/plants/ryukyu_pine.glb",
	"cycad": "res://assets/models/okinawa/plants/cycad.glb",
	"bougain": "res://assets/models/okinawa/plants/bougainvillea.glb",
	"wall": "res://assets/models/okinawa/structures/coral_stone_wall.glb",
	"pandanus": "res://assets/models/trees/pandanus.glb",
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"house": "res://assets/models/okinawa/buildings/concrete_house_b.glb",
	"shelter": "res://assets/models/okinawa/structures/bus_stop_shelter.glb",
	"cliff_a": "res://assets/models/okinawa/rocks/limestone_cliff_module.glb",
	"cliff_b": "res://assets/models/okinawa/rocks/limestone_cliff_module_b.glb",
	"bnotch_a": "res://assets/models/okinawa/rocks/notch_rock_a.glb",
	"bnotch_b": "res://assets/models/okinawa/rocks/notch_rock_b.glb",
	"bnotch_c": "res://assets/models/okinawa/rocks/notch_rock_c.glb",
	"lippine": "res://assets/models/okinawa/plants/ryukyu_pine.glb",
}
const RADIUS := {
	"notch_a": 3.0, "notch_b": 3.5, "notch_c": 3.0, "pine": 3.0, "cycad": 0.9, "bougain": 1.0,
	"wall": 2.0, "pandanus": 1.5, "hibiscus": 0.8, "house": 4.2, "shelter": 2.0,
	"cliff_a": 2.0, "cliff_b": 2.0, "bnotch_a": 1.2, "bnotch_b": 1.2, "bnotch_c": 1.2, "lippine": 2.5,
}
const NAMES := {
	"notch_a": "Notch", "notch_b": "Notch", "notch_c": "Notch", "pine": "Pin", "cycad": "Cicas",
	"bougain": "Bougainvillea", "wall": "ZidCoral", "pandanus": "Pandanus", "hibiscus": "Hibiscus",
	"house": "CasaPaznic", "shelter": "Observator",
	"cliff_a": "Faleza", "cliff_b": "Faleza", "bnotch_a": "StancaMal", "bnotch_b": "StancaMal", "bnotch_c": "StancaMal", "lippine": "PinBuza",
}
## Fara coliziune: tot ce e vegetatie joasa (banda de langa drum).
const NOCOL := ["bougain", "cycad", "hibiscus", "pandanus", "cliff_a", "cliff_b", "bnotch_a", "bnotch_b", "bnotch_c", "lippine"]

var _seq := {}
var _lh_pos := Vector3.ZERO


func _pos_at(frac: float, side: float, lat: float) -> Vector3:
	var i := _idx(frac)
	var p: Vector3 = _track.baked[i]
	var d := _track.width_at_index(i) + lat
	return p + _left(i) * side * d


func _free(x: float, z: float, r: float) -> bool:
	for q in _placed:
		var rr := r + q.z
		if Vector2(x - q.x, z - q.y).length_squared() < rr * rr:
			return false
	return true


func _emit(kind: String, x: float, y: float, z: float, yaw: float, sc: float, sy: float = 1.0) -> void:
	if kind in _skip_kinds:
		return
	if not _res.has(kind):
		_res[kind] = "e_%s" % kind
		_ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % [PATHS[kind], _res[kind]])
	var b := Basis(Vector3.UP, yaw)
	b = b.scaled(Vector3(sc, sc * sy, sc))
	_seq[NAMES[kind]] = int(_seq.get(NAMES[kind], 0)) + 1
	var rows := []
	for r in 3:
		rows.append("%.4f, %.4f, %.4f" % [b.x[r], b.y[r], b.z[r]])
	_out.append('[node name="%s_E%03d" parent="%s" instance=ExtResource("%s")]' % [
		NAMES[kind], int(_seq[NAMES[kind]]), ZONE, _res[kind]])
	_out.append("transform = Transform3D(%s, %s, %s, %.2f, %.3f, %.2f)" % [
		rows[0], rows[1], rows[2], x, y, z])
	if kind in NOCOL:
		_out.append('metadata/coliziune = "none"')
	_out.append("")
	_placed.append(Vector4(x, z, float(RADIUS[kind]) * sc, 0.0))
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	_n += 1


## Teren plat in jurul punctului (diferenta de cota pe 4 puncte la raza r <= maxd).
func _flat(x: float, z: float, r: float, maxd: float) -> bool:
	var y0 := _sol(x, z)
	for k in 4:
		var a := float(k) * PI * 0.5
		var yy := _sol(x + cos(a) * r, z + sin(a) * r)
		if absf(yy - y0) > maxd:
			return false
	return true


func _land_xz(kind: String, q: Vector3, sc: float, yaw: float, min_edge: float, sy: float = 1.0, min_h: float = 2.5, flat: float = 99.0) -> bool:
	var y := _sol(q.x, q.z)
	if y < _sea + min_h or _edge_dist(q.x, q.z) < min_edge or not _free(q.x, q.z, float(RADIUS[kind]) * sc * 0.8):
		_skipped += 1
		return false
	if flat < 90.0 and absf(y - float(_sampler.ground_y(q.x, q.z))) > 0.7:
		_skipped += 1
		return false
	if flat < 90.0 and not _flat(q.x, q.z, float(RADIUS[kind]) * sc, flat):
		_skipped += 1
		return false
	_emit(kind, q.x, y - 0.05, q.z, yaw, sc, sy)
	return true


func _rock_xz(kind: String, base: Vector3, sc: float, yaw: float, lo: float = 0.2, hi: float = 2.2) -> bool:
	var r := float(RADIUS[kind])
	for ring in 16:
		for k in 16:
			var a := TAU * float(k) / 16.0 + float(ring)
			var q := base + Vector3(cos(a), 0.0, sin(a)) * float(ring) * 2.0
			var dep := _sea - _sol(q.x, q.z)
			if dep < lo or dep > hi:
				continue
			if _edge_dist(q.x, q.z) < 12.0 or not _free(q.x, q.z, r * sc):
				continue
			var ok := true
			for m in 4:
				var b := float(m) * PI * 0.5
				var qq := q + Vector3(cos(b), 0.0, sin(b)) * r * sc * 0.7
				if _sea - _sol(qq.x, qq.z) > hi + 1.5:
					ok = false
			if not ok:
				continue
			_emit(kind, q.x, _sol(q.x, q.z) - 0.1, q.z, yaw, sc)
			print("; stanca %s la (%.0f, %.0f) adancime %.2f" % [kind, q.x, q.z, dep])
			return true
	print("; stanca sarita %s la (%.0f, %.0f)" % [kind, base.x, base.z])
	_skipped += 1
	return false


## Banda de vegetatie joasa de langa drum, pe o latura. Densitatea creste dinspre drum.
func _band(side: float, f0: float, f1: float, step: float, lat0: float, lat1: float, per: int) -> void:
	var f := f0
	while f <= f1:
		for k in per:
			var u := _rng.randf()
			var lat := lat0 + (lat1 - lat0) * sqrt(u)
			var ff := f + _rng.randf_range(-0.5, 0.5) * step
			var q := _pos_at(ff, side, lat)
			var roll := _rng.randf()
			var kind := "hibiscus"
			var sc := 1.0
			var sy := 1.0
			if lat < 7.0:
				if roll < 0.55:
					kind = "hibiscus"
					sc = _rng.randf_range(1.1, 1.7)
					sy = _rng.randf_range(0.5, 0.75)
				elif roll < 0.85:
					kind = "cycad"
					sc = _rng.randf_range(0.8, 1.2)
					sy = _rng.randf_range(0.6, 0.9)
				else:
					kind = "pandanus"
					sc = _rng.randf_range(0.9, 1.2)
					sy = _rng.randf_range(0.55, 0.8)
			else:
				if roll < 0.35:
					kind = "pandanus"
					sc = _rng.randf_range(1.2, 1.7)
					sy = _rng.randf_range(0.7, 0.95)
				elif roll < 0.7:
					kind = "cycad"
					sc = _rng.randf_range(1.1, 1.7)
					sy = _rng.randf_range(0.7, 1.0)
				else:
					kind = "hibiscus"
					sc = _rng.randf_range(1.4, 2.0)
					sy = _rng.randf_range(0.6, 0.9)
			_land_xz(kind, q, sc, _rng.randf() * TAU, 2.6, sy, 1.2, 1.0)
		f += step


## Palc dens de vegetatie joasa (5-15 piese) in jurul unui centru; intre palcuri ramane iarba.
func _clump(frac: float, side: float, lat: float, rad: float, n: int) -> void:
	var c := _pos_at(frac, side, lat)
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 6:
		tries += 1
		var a := _rng.randf() * TAU
		var d := rad * sqrt(_rng.randf())
		var q := c + Vector3(cos(a), 0.0, sin(a)) * d
		var roll := _rng.randf()
		var kind := "hibiscus"
		var sc := 1.0
		var sy := 1.0
		if roll < 0.35:
			kind = "pandanus"
			sc = _rng.randf_range(1.0, 1.6)
			sy = _rng.randf_range(0.6, 0.9)
		elif roll < 0.7:
			kind = "cycad"
			sc = _rng.randf_range(0.9, 1.5)
			sy = _rng.randf_range(0.6, 0.95)
		else:
			kind = "hibiscus"
			sc = _rng.randf_range(1.2, 1.9)
			sy = _rng.randf_range(0.5, 0.85)
		if _land_xz(kind, q, sc, _rng.randf() * TAU, 2.6, sy, 1.2, 1.0):
			placed += 1


## Muchia de calcar pe taluzul din stanga (sub cota drumului, fara coliziune).
func _cliff() -> void:
	var f := 0.518
	var k := 0
	var nh := {"bnotch_a": 9.0, "bnotch_b": 5.1, "bnotch_c": 6.7}
	while f <= 0.612:
		var i := _idx(f)
		var p: Vector3 = _track.baked[i]
		var l := _left(i)
		var t := _tangent(i)
		var w: float = _track.width_at_index(i)
		var q0 := p + l * (w + 6.0)
		var g0 := _sol(q0.x, q0.z)
		if p.y - g0 >= 2.0 and g0 > _sea - 30.0:
			# modul agatat sub buza: varful la cota drumului - 0.3, atarna pe fata taluzului
			var sc := _rng.randf_range(0.45, 0.6)
			var q := p + l * (w + 4.0)
			var yaw := atan2(t.x, t.z) + (PI if _rng.randf() < 0.5 else 0.0) + _rng.randf_range(-0.25, 0.25)
			_emit("cliff_a" if k % 2 == 0 else "cliff_b", q.x, p.y - 0.3 - 15.0 * sc, q.z, yaw, sc)
			k += 1
			for m in 3:
				var d2 := _rng.randf_range(2.6, 6.5)
				var q2 := p + l * (w + d2) + t * _rng.randf_range(-2.0, 2.0)
				var g2 := _sol(q2.x, q2.z)
				if p.y - g2 < 1.0:
					continue
				var bk: String = ["bnotch_a", "bnotch_b", "bnotch_c"][_rng.randi() % 3]
				var bsc := _rng.randf_range(0.3, 0.5)
				_emit(bk, q2.x, p.y - 0.3 - float(nh[bk]) * bsc, q2.z, _rng.randf() * TAU, bsc)
		f += 0.0024
	# pini turtiti si tufe agatati pe buza
	for lf2 in [0.529, 0.548, 0.566, 0.585, 0.600]:
		var j := _idx(lf2)
		for dd in [4.0, 6.0, 8.0, 11.0]:
			var qq := _pos_at(lf2, 1.0, dd)
			if _land_xz("lippine", qq, _rng.randf_range(0.8, 1.1), _rng.randf() * TAU, 3.5, _rng.randf_range(0.65, 0.8), 1.5, 2.0):
				break
	for lf3 in [0.526, 0.536, 0.546, 0.556, 0.567, 0.578, 0.589, 0.600, 0.608]:
		for dd in [3.5, 5.0, 7.0]:
			var qq := _pos_at(lf3, 1.0, dd)
			if _land_xz("hibiscus", qq, _rng.randf_range(1.0, 1.5), _rng.randf() * TAU, 3.0, _rng.randf_range(0.5, 0.8), 1.5, 1.2):
				break


## Petic de flori (accent viu): bougainvillea + hibiscus, in jurul unui centru.
func _patch(frac: float, side: float, lat: float, rad: float, n: int) -> void:
	var c := _pos_at(frac, side, lat)
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 6:
		tries += 1
		var a := _rng.randf() * TAU
		var d := rad * sqrt(_rng.randf())
		var q := c + Vector3(cos(a), 0.0, sin(a)) * d
		var kind := "bougain" if _rng.randf() < 0.6 else "hibiscus"
		var sc := _rng.randf_range(1.1, 1.6)
		if _land_xz(kind, q, sc, _rng.randf() * TAU, 2.8, _rng.randf_range(0.7, 1.0), 1.2, 1.0):
			placed += 1


## Grup de pini turtiti de vant (3-5), coroane joase, trunchi cu coliziune.
func _pines(frac: float, side: float, lat: float, n: int, slope_ok: float) -> void:
	var c := _pos_at(frac, side, lat)
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 8:
		tries += 1
		var a := _rng.randf() * TAU
		var d := 7.0 * sqrt(_rng.randf())
		var q := c + Vector3(cos(a), 0.0, sin(a)) * d
		var sc := _rng.randf_range(0.95, 1.4)
		if _land_xz("pine", q, sc, _rng.randf() * TAU, 3.5, _rng.randf_range(0.65, 0.85), 1.5, slope_ok):
			placed += 1


func _build() -> void:
	# --- farul: mutat mai aproape, pe platoul capului, cu casuta paznicului ---
	var fi := _idx(0.508)
	var lf := _left(fi)
	var lh: Vector3 = _track.baked[fi] + lf * 38.0
	var lh_y := _sol(lh.x, lh.z)
	print("; far la (%.1f, %.1f) cota %.2f (drum %.2f), 38 m de axa" % [lh.x, lh.z, lh_y, _track.baked[fi].y])
	_lh_pos = Vector3(lh.x, lh_y - 0.1, lh.z)
	_placed.append(Vector4(lh.x, lh.z, 5.0, 0.0))
	var tfi := _tangent(fi)
	var hp := lh + tfi * 17.0 + lf * 2.0
	_emit("house", hp.x, _sol(hp.x, hp.z) - 0.05, hp.z, atan2(lf.x, lf.z), 1.1)
	# ziduri joase de corali in jurul farului (segmente de 4 m)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var wq := lh + Vector3(cos(a), 0.0, sin(a)) * 11.0
		if _sol(wq.x, wq.z) > _sea + 8.0 and _edge_dist(wq.x, wq.z) > 8.0:
			_emit("wall", wq.x, _sol(wq.x, wq.z) - 0.05, wq.z, a + PI * 0.5, 1.0)
	# observator la marginea platoului, cu fata spre mare
	var ep := lh
	var step := 0
	while step < 60:
		var tq := lh + lf * float(step)
		if _sol(tq.x, tq.z) < _sea + 8.0:
			break
		ep = tq
		step += 1
	ep = ep - lf * 5.0 + tfi * 4.0
	print("; observator la (%.1f, %.1f), marginea platoului la %d m de far" % [ep.x, ep.z, step])
	_emit("shelter", ep.x, _sol(ep.x, ep.z) - 0.05, ep.z, atan2(-lf.x, -lf.z) + PI, 1.0)
	var ep2 := lh - tfi * 14.0 + lf * float(maxi(step - 9, 6))
	_emit("shelter", ep2.x, _sol(ep2.x, ep2.z) - 0.05, ep2.z, atan2(-lf.x, -lf.z) + PI, 0.9)
	_cliff()
	# --- banda de langa drum: dreapta (platoul) si stanga (pe culme, pana la cornisa) ---
	_band(1.0, 0.476, 0.5235, 0.0020, 2.8, 15.0, 4)
	var cf := 0.476
	while cf < 0.612:
		_clump(cf, -1.0, _rng.randf_range(3.5, 13.0), _rng.randf_range(2.4, 3.6), _rng.randi_range(6, 14))
		if _rng.randf() < 0.55:
			_clump(cf + 0.002, -1.0, _rng.randf_range(15.0, 38.0), _rng.randf_range(3.0, 4.5), _rng.randi_range(8, 15))
		cf += _rng.randf_range(0.0035, 0.0065)
	_band(1.0, 0.476, 0.5235, 0.0030, 15.0, 55.0, 2)
	# petice de flori (accent), nealiniate
	var pf := 0.480
	while pf < 0.608:
		var sd := -1.0 if _rng.randf() < 0.6 else 1.0
		_patch(pf, sd, _rng.randf_range(4.0, 11.0), 3.2, 8)
		pf += _rng.randf_range(0.007, 0.012)
	# pini turtiti in grupuri: dreapta (platoul) la >= 14 m, stanga pe platoul farului
	for g in [[0.484, 20.0], [0.494, 30.0], [0.503, 18.0], [0.512, 26.0], [0.522, 22.0], [0.532, 30.0],
			[0.543, 18.0], [0.553, 34.0], [0.565, 22.0], [0.578, 30.0], [0.590, 20.0], [0.602, 26.0]]:
		_pines(float(g[0]), -1.0, float(g[1]), 4, 2.5)
	for g in [[0.598, 26.0], [0.604, 34.0], [0.610, 24.0]]:
		_pines(float(g[0]), 1.0, float(g[1]), 4, 1.6)
	for g in [[0.484, 40.0], [0.495, 52.0], [0.507, 46.0], [0.519, 56.0], [0.529, 34.0], [0.541, 40.0], [0.552, 52.0], [0.566, 42.0], [0.580, 50.0], [0.594, 40.0], [0.606, 48.0]]:
		_pines(float(g[0]), -1.0, float(g[1]), 5, 2.5)
	for g in [[0.480, 16.0], [0.489, 24.0], [0.497, 14.0], [0.507, 28.0], [0.515, 20.0], [0.521, 34.0]]:
		_pines(float(g[0]), 1.0, float(g[1]), 4, 1.6)
	for g in [[0.502, 40.0], [0.513, 44.0], [0.5195, 30.0]]:
		_pines(float(g[0]), 1.0, float(g[1]), 3, 1.6)
	# --- stancile-ciuperca in apa mica de la piciorul cornisei ---
	var specs := [
		["notch_a", 0.531, 1.0, 26.0, 1.3, 0.7], ["notch_c", 0.531, 1.0, 44.0, 1.1, 2.4],
		["notch_b", 0.534, 1.0, 34.0, 1.0, 4.0], ["notch_a", 0.599, 1.0, 26.0, 1.15, 1.1],
		["notch_b", 0.604, 1.0, 34.0, 1.0, 5.0], ["notch_c", 0.608, 1.0, 22.0, 1.2, 3.3],
		["notch_a", 0.545, 1.0, 22.0, 1.1, 0.2], ["notch_b", 0.575, 1.0, 20.0, 1.2, 2.0],
	]
	for sp in specs:
		_rock_xz(sp[0], _pos_at(sp[1], sp[2], sp[3]), sp[4], sp[5])
	_emit_lighthouse()


func _emit_lighthouse() -> void:
	_out.append('[node name="Far_capul_E" parent="%s" instance=ExtResource("12_light")]' % ZONE)
	_out.append("transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, %.2f, %.3f, %.2f)" % [_lh_pos.x, _lh_pos.y, _lh_pos.z])
	_out.append("")
	_n += 1


func _write() -> void:
	print("; asezate %d piese, %d sarite; %s" % [_n, _skipped, str(_counts)])
	var lines: Array[String] = []
	lines.append_array(_ext)
	lines.append("###NODES###")
	lines.append_array(_out)
	if _out_path.is_empty():
		for l in lines:
			print(l)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	for l in lines:
		fa.store_line(l)
	fa.close()
	print("; scris %s" % _out_path)
