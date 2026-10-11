extends Node
## Generator de decor MANUAL pentru POI F — COBORAREA SI PODUL (Track20, Okinawa,
## frac 0.612-0.737). Calculeaza transformarile care se lipesc in Track20.tscn sub
## `DecorManual/ZonaF` (tiparul gen_decor_jod_f.gd). NU atinge podul/canalul.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorOkF.tscn -- \
##       --out=C:/cale/zonaF.part [--survey]

const TRACK := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaF"

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
var _chan_p := Vector3(320.638, 8.5, 146.441)
var _chan_t := Vector3.ZERO
var _counts := {}


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
				"vehicles/coastal_freighter", "vehicles/fishing_boat", "plants/ryukyu_pine",
				"plants/cycad", "plants/fan_palm", "plants/bougainvillea", "structures/coral_stone_wall"]:
			_aabb("res://assets/models/okinawa/%s.glb" % path)
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
	_rng.seed = 200926
	var ic := _closest(_chan_p)
	_chan_t = _tangent(ic)
	print("; mare y=%.2f, canal idx %d frac %.4f tang %s" % [_sea, ic, float(ic) / _track.baked.size(), str(_chan_t)])
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


## In culoarul canalului (+ margine)? Axa canalului e perpendiculara pe sosea.
func _in_channel(x: float, z: float, margin: float) -> bool:
	var d := Vector3(x - _chan_p.x, 0.0, z - _chan_p.z)
	var along := absf(d.dot(_chan_t))
	var perp := absf(d.dot(Vector3(_chan_t.z, 0.0, -_chan_t.x)))
	return along < 26.0 + margin and perp < 100.0 + margin


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


func _grid() -> void:
	print("; grila adancime (mare-sol) in jurul canalului: rand=along (spre inainte), col=perp stanga + (-120..120 pas 20)")
	var lf := Vector3(_chan_t.z, 0.0, -_chan_t.x)
	var a := -100.0
	while a <= 140.0:
		var line := ""
		var pp := -120.0
		while pp <= 120.0:
			var q := _chan_p + _chan_t * a + lf * pp
			line += "%6.1f" % (_sol(q.x, q.z) - _sea)
			pp += 20.0
		print("; a=%+5.0f %s" % [a, line])
		a += 20.0


func _survey() -> void:
	_grid()
	print("; frac    i     x       z      y   | adancime(apa sub mare) la st 6/10/14/20/30/45/60 | dr 6/10/14/20/30/45/60  (+ = uscat peste mare)")
	var f := 0.610
	while f <= 0.740 + 1e-6:
		var i := _idx(f)
		var p: Vector3 = _track.baked[i]
		var sl := ""
		var sr := ""
		for d: float in [6.0, 10.0, 14.0, 20.0, 30.0, 45.0, 60.0]:
			var ql: Vector3 = p + _left(i) * d
			var qr: Vector3 = p - _left(i) * d
			sl += "%+6.1f " % (_sol(ql.x, ql.z) - _sea)
			sr += "%+6.1f " % (_sol(qr.x, qr.z) - _sea)
		print("; %.3f %4d %7.1f %7.1f %6.2f | %s| %s" % [f, i, p.x, p.z, p.y, sl, sr])
		f += 0.004


const PATHS := {
	"notch_a": "res://assets/models/okinawa/rocks/notch_rock_a.glb",
	"notch_b": "res://assets/models/okinawa/rocks/notch_rock_b.glb",
	"notch_c": "res://assets/models/okinawa/rocks/notch_rock_c.glb",
	"freighter": "res://assets/models/okinawa/vehicles/coastal_freighter.glb",
	"boat": "res://assets/models/okinawa/vehicles/fishing_boat.glb",
	"pine": "res://assets/models/okinawa/plants/ryukyu_pine.glb",
	"cycad": "res://assets/models/okinawa/plants/cycad.glb",
	"fanpalm": "res://assets/models/okinawa/plants/fan_palm.glb",
	"bougain": "res://assets/models/okinawa/plants/bougainvillea.glb",
	"wall": "res://assets/models/okinawa/structures/coral_stone_wall.glb",
	"pandanus": "res://assets/models/trees/pandanus.glb",
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"quay": "res://assets/models/okinawa/structures/harbour_quay.glb",
}
## Raza (m) de ocupare per tip, la scara 1, pentru evitarea suprapunerilor.
const RADIUS := {
	"notch_a": 3.0, "notch_b": 3.5, "notch_c": 3.0, "freighter": 17.0, "boat": 2.5,
	"pine": 3.0, "cycad": 1.0, "fanpalm": 1.8, "bougain": 1.2, "wall": 2.0, "pandanus": 1.8,
	"hibiscus": 0.9, "quay": 5.0,
}
const NAMES := {
	"notch_a": "Notch", "notch_b": "Notch", "notch_c": "Notch", "freighter": "Cargou",
	"boat": "Barca", "pine": "Pin", "cycad": "Cicas", "fanpalm": "Palmier",
	"bougain": "Bougainvillea", "wall": "ZidCoral", "pandanus": "Pandanus",
	"hibiscus": "Hibiscus", "quay": "Chei",
}

var _seq := {}
var _nocol_all := false
var _skip_kinds: PackedStringArray = PackedStringArray()


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


func _emit(kind: String, x: float, y: float, z: float, yaw: float, sc: float) -> void:
	if kind in _skip_kinds:
		return
	if not _res.has(kind):
		_res[kind] = "f_%s" % kind
		_ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % [PATHS[kind], _res[kind]])
	var b := Basis(Vector3.UP, yaw)
	b = b.scaled(Vector3(sc, sc, sc))
	_seq[NAMES[kind]] = int(_seq.get(NAMES[kind], 0)) + 1
	var rows := []
	for r in 3:
		rows.append("%.5f, %.5f, %.5f" % [b.x[r], b.y[r], b.z[r]])
	_out.append('[node name="%s_F%02d" parent="%s" instance=ExtResource("%s")]' % [
		NAMES[kind], int(_seq[NAMES[kind]]), ZONE, _res[kind]])
	_out.append("transform = Transform3D(%s, %s, %s, %.2f, %.3f, %.2f)" % [
		rows[0], rows[1], rows[2], x, y, z])
	if kind in ["bougain", "cycad", "hibiscus"] or _nocol_all:
		_out.append('metadata/coliziune = "none"')
	_out.append("")
	_placed.append(Vector4(x, z, float(RADIUS[kind]) * sc, 0.0))
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	_n += 1


## Piesa pe uscat (cota solului real), cu conditii de distanta fata de asfalt.
func _land(kind: String, frac: float, side: float, lat: float, sc: float, yaw: float, min_edge: float = 8.0) -> bool:
	return _land_xz(kind, _pos_at(frac, side, lat), sc, yaw, min_edge)


func _land_xz(kind: String, q: Vector3, sc: float, yaw: float, min_edge: float = 8.0) -> bool:
	var y := _sol(q.x, q.z)
	if y < _sea + 0.9 or _edge_dist(q.x, q.z) < min_edge or not _free(q.x, q.z, float(RADIUS[kind]) * sc):
		_skipped += 1
		return false
	_emit(kind, q.x, y - 0.05, q.z, yaw, sc)
	return true


## Stanca in apa putin adanca: cauta in jurul ancorei un loc cu `lo`..`hi` m adancime.
func _rock(kind: String, frac: float, side: float, lat: float, sc: float, yaw: float, lo: float = 0.2, hi: float = 1.9) -> bool:
	return _rock_xz(kind, _pos_at(frac, side, lat), sc, yaw, lo, hi)


func _rock_xz(kind: String, base: Vector3, sc: float, yaw: float, lo: float = 0.2, hi: float = 1.9) -> bool:
	var r := float(RADIUS[kind])
	for ring in 14:
		for k in 16:
			var a := TAU * float(k) / 16.0 + float(ring)
			var q := base + Vector3(cos(a), 0.0, sin(a)) * float(ring) * 2.0
			var dep := _sea - _sol(q.x, q.z)
			if dep < lo or dep > hi:
				continue
			if _edge_dist(q.x, q.z) < 12.0 or _in_channel(q.x, q.z, 16.0):
				continue
			if not _free(q.x, q.z, r * sc):
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
			return true
	print("; stanca sarita %s la (%.0f, %.0f)" % [kind, base.x, base.z])
	_skipped += 1
	return false


## Palc dens: `n` piese in jurul unui centru, amestec pandanus/palmier/cicada/hibiscus/bougainvillea.
func _cluster(frac: float, side: float, lat: float, rad: float, n: int, _jit: float) -> void:
	var c := _pos_at(frac, side, lat)
	var mix := ["pandanus", "cycad", "cycad", "hibiscus", "fanpalm", "cycad", "bougain", "pandanus", "hibiscus", "cycad"]
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 6:
		tries += 1
		var a := _rng.randf() * TAU
		var d := rad * sqrt(_rng.randf())
		var q := c + Vector3(cos(a), 0.0, sin(a)) * d
		var kind: String = mix[_rng.randi() % mix.size()]
		var sc := 1.0
		match kind:
			"pandanus": sc = _rng.randf_range(1.5, 1.9)
			"fanpalm": sc = _rng.randf_range(1.0, 1.3)
			"cycad": sc = _rng.randf_range(0.9, 1.4)
			"hibiscus": sc = _rng.randf_range(1.0, 1.5)
			"bougain": sc = _rng.randf_range(1.0, 1.4)
		if _land_xz(kind, q, sc, _rng.randf() * TAU, 8.0):
			placed += 1


## Cheiul: cauta pe tarmul golfului, dincolo de culoar, un punct cu apa la ~0,3 m si uscat la 4 m spre mal.
func _quay() -> void:
	var lf := Vector3(_chan_t.z, 0.0, -_chan_t.x)
	var best := Vector3.INF
	var yawb := 0.0
	for ap in [56.0, 66.0, 76.0, 88.0, -56.0, -70.0]:
		for pp in [-24.0, -30.0, -36.0, -44.0, -52.0]:
			var q: Vector3 = _chan_p + _chan_t * ap + lf * pp
			var dep := _sea - _sol(q.x, q.z)
			if dep < 0.0 or dep > 1.2 or _in_channel(q.x, q.z, 16.0) or _edge_dist(q.x, q.z) < 14.0:
				continue
			# directia spre uscat: -lf (spre dreapta->centru) sau +lf; alege cea cu uscat
			for sgn in [1.0, -1.0]:
				var dirn: Vector3 = lf * sgn
				var land: Vector3 = q + dirn * 5.0
				if _sol(land.x, land.z) > _sea + 0.8 and _free(q.x, q.z, 6.0):
					best = q
					yawb = atan2(dirn.x, dirn.z)
					break
			if best != Vector3.INF:
				break
		if best != Vector3.INF:
			break
	if best == Vector3.INF:
		print("; cheiul sarit (nu am gasit tarm)")
		return
	print("; chei la (%.1f, %.1f) yaw %.2f" % [best.x, best.z, yawb])
	_emit("quay", best.x, _sea, best.z, yawb, 1.0)
	var side := Vector3(cos(yawb), 0.0, -sin(yawb))
	for k in 2:
		var bq: Vector3 = best - Vector3(sin(yawb), 0.0, cos(yawb)) * (7.0 + 3.0 * k) + side * (5.0 if k == 0 else -6.0)
		if _sea - _sol(bq.x, bq.z) > 1.4 and _free(bq.x, bq.z, 3.0):
			_emit("boat", bq.x, _sea, bq.z, yawb + 1.5 + k, 1.0)


func _build() -> void:
	var ch := _chan_p
	var lf := Vector3(_chan_t.z, 0.0, -_chan_t.x)
	# --- stancile-ciuperca in apa mica (nu in culoarul canalului) ---
	var specs := [
		["notch_a", 0.620, 1.0, 44.0, 1.45, 0.7],
		["notch_c", 0.628, 1.0, 62.0, 1.2, 2.4],
		["notch_b", 0.614, 1.0, 40.0, 1.0, 4.0],
		["notch_b", 0.650, -1.0, 24.0, 1.3, 1.1],
		["notch_a", 0.654, 1.0, 36.0, 1.1, 5.0],
		["notch_c", 0.694, -1.0, 28.0, 1.35, 3.3],
		["notch_a", 0.704, -1.0, 34.0, 1.0, 0.2],
		["notch_b", 0.684, 1.0, 30.0, 0.9, 2.0],
	]
	for sp in specs:
		_rock(sp[0], sp[1], sp[2], sp[3], sp[4], sp[5])
	# stancile mari de langa pod, in cadrul de joc de pe aproape (cadru canal: a = de-a lungul
	# soselei, p = stanga +); dincolo de culoarul feribotului (|a| > 42)
	var frame := [
		["notch_a", -54.0, 36.0, 1.8, 0.4], ["notch_b", -62.0, 60.0, 1.45, 2.9],
		["notch_c", 52.0, -36.0, 1.8, 1.6], ["notch_a", 64.0, -60.0, 1.5, 4.1],
		["notch_b", 56.0, 70.0, 1.6, 5.5], ["notch_c", -50.0, -44.0, 1.4, 3.3],
	]
	for fr in frame:
		var fq: Vector3 = _chan_p + _chan_t * float(fr[1]) + Vector3(_chan_t.z, 0.0, -_chan_t.x) * float(fr[2])
		_rock_xz(fr[0], fq, fr[3], fr[4])
	# --- coborarea (fara zid de corali: runda 2) ---
	_land("pine", 0.620, 1.0, 17.0, 1.1, 0.6, 12.0)
	_land("pine", 0.629, 1.0, 24.0, 0.9, 2.2, 12.0)
	_land("pine", 0.624, -1.0, 16.0, 1.0, 4.4, 12.0)
	for c in [[0.618, 1.0, 11.5], [0.622, 1.0, 13.0], [0.626, 1.0, 12.0], [0.630, -1.0, 11.5], [0.633, -1.0, 12.5], [0.627, 1.0, 20.0], [0.621, -1.0, 12.0]]:
		_land("cycad", c[0], c[1], c[2], _rng.randf_range(0.9, 1.25), _rng.randf() * TAU, 8.0)
	for fl in [[0.619, 1.0, 10.0], [0.6195, 1.0, 11.2], [0.6205, 1.0, 10.6], [0.631, -1.0, 10.0], [0.6318, -1.0, 11.0]]:
		_land("bougain", fl[0], fl[1], fl[2], _rng.randf_range(1.0, 1.3), PI + _rng.randf_range(-0.4, 0.4), 8.0)
	# --- pâlcuri dese (coliziune none): capatul podului dreapta + stanga, rampa stanga ---
	_nocol_all = true
	_cluster(0.712, 1.0, 14.0, 9.0, 30, 0.15)
	_cluster(0.724, -1.0, 15.0, 9.0, 28, 0.15)
	_cluster(0.7335, 1.0, 14.0, 7.0, 16, 0.1)
	_cluster(0.623, 1.0, 15.0, 8.0, 22, 0.2)
	_cluster(0.628, -1.0, 13.0, 7.0, 14, 0.2)
	_nocol_all = false
	# --- stanci in grupuri, in apa mica, la ambele maluri ---
	var groups := [
		[-52.0, 34.0], [-66.0, 62.0], [52.0, -34.0], [66.0, -52.0], [60.0, 56.0],
	]
	var kinds := ["notch_a", "notch_b", "notch_c"]
	var gi := 0
	for g in groups:
		var cp: Vector3 = _chan_p + _chan_t * float(g[0]) + lf * float(g[1])
		for m in 3:
			var off := Vector3(_rng.randf_range(-9.0, 9.0), 0.0, _rng.randf_range(-9.0, 9.0))
			var sc: float = float([1.9, 1.4, 1.0][m]) * _rng.randf_range(0.9, 1.1)
			_rock_xz(kinds[(gi + m) % 3], cp + off, sc, _rng.randf() * TAU)
		gi += 1
	for fr in [[0.692, -1.0, 26.0], [0.698, -1.0, 36.0], [0.7055, -1.0, 30.0]]:
		for m in 2:
			var bp := _pos_at(fr[0], fr[1], fr[2]) + Vector3(_rng.randf_range(-6.0, 6.0), 0.0, _rng.randf_range(-6.0, 6.0))
			_rock_xz(kinds[(gi + m) % 3], bp, [1.7, 1.1][m], _rng.randf() * TAU)
		gi += 1
	# --- cheiul de piatra pe malul golfului (dincolo de culoar), cu barci ---
	_quay()
	# --- vasul de coasta, STATIC, asteptand in larg (stanga, dincolo de gura canalului) ---
	var fp := ch + _chan_t * 84.0 + lf * 116.0
	var dir := (ch + _chan_t * 28.0 + lf * 70.0) - fp
	dir.y = 0.0
	dir = dir.normalized()
	var fdep := _sea - _sol(fp.x, fp.z)
	print("; cargou la (%.1f, %.1f) adancime %.1f" % [fp.x, fp.z, fdep])
	if fdep > 3.5 and not _in_channel(fp.x, fp.z, 0.0):
		_emit("freighter", fp.x, _sea, fp.z, atan2(-dir.x, -dir.z), 1.0)
	# --- barci mici in golf ---
	var bspecs := [[44.0, -62.0, 0.4], [58.0, -48.0, 2.6], [-52.0, -74.0, 4.8]]
	for bs in bspecs:
		var q: Vector3 = ch + _chan_t * float(bs[0]) + lf * float(bs[1])
		var dep := _sea - _sol(q.x, q.z)
		if dep > 1.6 and _free(q.x, q.z, 3.0) and _edge_dist(q.x, q.z) > 12.0:
			_emit("boat", q.x, _sea, q.z, float(bs[2]), 1.0)
		else:
			print("; barca sarita la (%.1f, %.1f) adancime %.1f" % [q.x, q.z, dep])
			_skipped += 1


func _write() -> void:
	print("; asezate %d piese, %d sarite; %s" % [_n, _skipped, str(_counts)])
	var lines: Array[String] = []
	lines.append("; --- EXT_RESOURCES (de lipit in antet) ---")
	lines.append_array(_ext)
	lines.append("; --- NODURI (de lipit la sfarsit, sub ZonaF) ---")
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
