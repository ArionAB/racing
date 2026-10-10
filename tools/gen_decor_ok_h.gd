extends Node
## Generator de decor MANUAL pentru POI H - DIGUL, TETRAPOZII SI VALUL (Track20, Okinawa,
## frac 0.824-0.974). Calculeaza transformarile care se lipesc in Track20.tscn sub
## `DecorManual/ZonaH` (tiparul gen_decor_ok_h.gd). NU atinge tromba (hazard din cod,
## marker 0.7758) si ii lasa culoarul de ratacire liber de orice cu coliziune.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorOkH.tscn -- \
##       --out=C:/cale/zonaH.part
##   python tools/apply_zone_h.py C:/cale/zonaH.part

const TRACK := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaH"
var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid := RID()
var _space: PhysicsDirectSpaceState3D
var _sus_y := 0.0
var _sea := 0.05
var _out_path := ""
var _out: Array[String] = []
var _ext: Array[String] = []
var _res := {}
var _n := 0
var _skipped := 0
var _rng := RandomNumberGenerator.new()
var _placed: Array[Vector4] = []  # x, z, raza, tip
var _counts := {}
var _nocol_all := false
var _seq := {}
var _profile := false
var _variant := 1


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--profile":
			_profile = true
	await get_tree().process_frame
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
	if _profile:
		_print_profile()
	else:
		_build()
		_write()
	get_tree().quit(0)


func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(round(fposmod(frac, 1.0) * float(n))) % n


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


## (indice, distanta de la axa) al celui mai apropiat punct baked.
func _near(x: float, z: float) -> Vector2:
	var best := 0
	var bd := 1e18
	for j in _track.baked.size():
		var b: Vector3 = _track.baked[j]
		var dx := x - b.x
		var dz := z - b.z
		if absf(dx) > 90.0 or absf(dz) > 90.0:
			continue
		var d := dx * dx + dz * dz
		if d < bd:
			bd = d
			best = j
	return Vector2(float(best), sqrt(bd))



const PATHS := {
	"tetra": "res://assets/models/structures/tetrapod.glb",
	"wall": "res://assets/models/okinawa/structures/coral_stone_wall.glb",
	"notch_a": "res://assets/models/okinawa/rocks/notch_rock_a.glb",
	"notch_b": "res://assets/models/okinawa/rocks/notch_rock_b.glb",
	"notch_c": "res://assets/models/okinawa/rocks/notch_rock_c.glb",
	"cycad": "res://assets/models/okinawa/plants/cycad.glb",
	"bougain": "res://assets/models/okinawa/plants/bougainvillea.glb",
	"pandanus": "res://assets/models/trees/pandanus.glb",
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"clutter": "res://assets/models/scatter/beach_clutter.glb",
	"coral": "res://assets/models/rocks/coral_rock.glb",
}
const RADIUS := {
	"tetra": 1.6, "wall": 2.0, "notch_a": 3.0, "notch_b": 3.5, "notch_c": 3.0,
	"cycad": 1.0, "bougain": 1.2, "pandanus": 1.8, "hibiscus": 0.9, "clutter": 0.9, "coral": 1.0,
}
const NAMES := {
	"tetra": "Tetra", "wall": "Zid", "notch_a": "Notch", "notch_b": "Notch", "notch_c": "Notch",
	"cycad": "Cicas", "bougain": "Bougainvillea", "pandanus": "Pandanus", "hibiscus": "Hibiscus",
	"clutter": "Flotor", "coral": "Bolovan",
}
const NOCOL := ["bougain", "cycad", "hibiscus", "clutter", "coral"]


func _pos_at(frac: float, side: float, lat: float) -> Vector3:
	var i := _idx(frac)
	var p: Vector3 = _track.baked[i]
	var d := _track.width_at_index(i) + lat
	return p + _left(i) * side * d


## Pozitie la `lat` m de AXA (nu de margine).
func _pos_ax(frac: float, side: float, lat: float) -> Vector3:
	var i := _idx(frac)
	return (_track.baked[i] as Vector3) + _left(i) * side * lat


func _free(x: float, z: float, r: float) -> bool:
	for q in _placed:
		var rr := r + q.z
		if Vector2(x - q.x, z - q.y).length_squared() < rr * rr:
			return false
	return true


func _ref(kind: String) -> String:
	if not _res.has(kind):
		_res[kind] = "h_%s" % kind
		_ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % [PATHS[kind], _res[kind]])
	return _res[kind]


func _print_profile() -> void:
	for f in [0.830, 0.84, 0.85, 0.86, 0.87, 0.88, 0.89, 0.90, 0.91, 0.92, 0.93, 0.94, 0.95, 0.96, 0.97]:
		for side in [1.0, -1.0]:
			var s := "f=%.3f %s hw=%.1f |" % [f, "L" if side > 0.0 else "R", _track.width_at_index(_idx(f))]
			for lat in [5.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 30.0, 40.0]:
				var q := _pos_ax(f, side, lat)
				s += " %d:%+.1f" % [int(lat), _sol(q.x, q.z) - _sea]
			print(s)


func _emit(kind: String, x: float, y: float, z: float, yaw: float, sc: float, variant: int = 0) -> void:
	var ref := _ref(kind)
	var b := Basis(Vector3.UP, yaw)
	b = b.scaled(Vector3(sc, sc, sc))
	_seq[NAMES[kind]] = int(_seq.get(NAMES[kind], 0)) + 1
	var nm := "%s_H%02d" % [NAMES[kind], int(_seq[NAMES[kind]])]
	var rows := []
	for r in 3:
		rows.append("%.5f, %.5f, %.5f" % [b.x[r], b.y[r], b.z[r]])
	_out.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [nm, ZONE, ref])
	_out.append("transform = Transform3D(%s, %s, %s, %.2f, %.3f, %.2f)" % [
		rows[0], rows[1], rows[2], x, y, z])
	if kind in NOCOL or _nocol_all:
		_out.append('metadata/coliziune = "none"')
	_out.append("")
	if kind == "tetra":
		var kids := ["Tetrapod_01", "Tetrapod_04", "Tetrapod_Stack_01"]
		for v in 3:
			if v != variant:
				_out.append('[node name="%s" parent="%s/%s" index="%d"]' % [kids[v], ZONE, nm, v])
				_out.append("visible = false")
				_out.append("")
	elif kind == "coral":
		for v in 8:
			if v + 1 != _variant:
				_out.append('[node name="Coral_Rock_%02d" parent="%s/%s" index="%d"]' % [v + 1, ZONE, nm, v])
				_out.append("visible = false")
				_out.append("")
	_placed.append(Vector4(x, z, float(RADIUS[kind]) * sc, 0.0))
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	_n += 1


## Teren relativ la mare la `lat` m de AXA, pe o latura.
func _rel(frac: float, side: float, lat: float) -> float:
	var q := _pos_ax(frac, side, lat)
	return _sol(q.x, q.z) - _sea


## Cea mai mica distanta de la axa (>= lo) la care terenul e la `depth` m sub mare; daca nu se
## atinge pana la `hi`, intoarce `lo`.
func _lat_at_depth(frac: float, side: float, depth: float, lo: float, hi: float) -> float:
	var lat := lo
	while lat <= hi:
		if _rel(frac, side, lat) <= -depth:
			return lat
		lat += 0.25
	return lo


func _tilt_emit(kind: String, x: float, y: float, z: float, yaw: float, sc: float, variant: int, tx: float, tz: float) -> void:
	## ca _emit, dar cu o usoara inclinare (tetrapozi aruncati, nu asezati).
	var ref := _ref(kind)
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tx) * Basis(Vector3.FORWARD, tz)
	b = b.scaled(Vector3(sc, sc, sc))
	_seq[NAMES[kind]] = int(_seq.get(NAMES[kind], 0)) + 1
	var nm := "%s_H%02d" % [NAMES[kind], int(_seq[NAMES[kind]])]
	var rows := []
	for r in 3:
		rows.append("%.5f, %.5f, %.5f" % [b.x[r], b.y[r], b.z[r]])
	_out.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [nm, ZONE, ref])
	_out.append("transform = Transform3D(%s, %s, %s, %.2f, %.3f, %.2f)" % [
		rows[0], rows[1], rows[2], x, y, z])
	_out.append("")
	var kids := ["Tetrapod_01", "Tetrapod_04", "Tetrapod_Stack_01"]
	for v in 3:
		if v != variant:
			_out.append('[node name="%s" parent="%s/%s" index="%d"]' % [kids[v], ZONE, nm, v])
			_out.append("visible = false")
			_out.append("")
	_placed.append(Vector4(x, z, float(RADIUS["tetra"]) * sc * 0.5, 0.0))
	_counts["tetra"] = int(_counts.get("tetra", 0)) + 1
	_n += 1


## Tetrapozi: pe STANGA, 2-3 straturi neregulate pe 0.84-0.96, la >= 12.8 m de axa (>= 6,3 m de
## margine), asezati pe terenul real: stratul 1 la linia apei, 2 si 3 mai adanc in apa mica.
func _tetrapods() -> void:
	var targets := [-0.05, 0.6, 1.2]
	var f := 0.840
	while f < 0.960:
		for layer in 3:
			if layer == 2 and (f < 0.852 or f > 0.948):
				continue
			var ff := f + _rng.randf_range(-0.0012, 0.0012) + float(layer) * 0.0007
			var base := _lat_at_depth(ff, 1.0, float(targets[layer]), 12.8, 24.0)
			if layer > 0 and base <= 12.81:
				base = 12.8 + 2.4 * float(layer)
			var lat := maxf(base + _rng.randf_range(-0.7, 0.9), 12.8)
			var q := _pos_ax(ff, 1.0, lat)
			var var_i := 0
			var sc := _rng.randf_range(1.5, 1.8)
			if layer == 2 and _rng.randf() < 0.3:
				var_i = 2
				sc = _rng.randf_range(0.95, 1.2)
			var y := _sol(q.x, q.z)
			var rr := float(RADIUS["tetra"]) * sc * 0.5
			if _edge_dist(q.x, q.z) < 6.0 or not _free(q.x, q.z, rr):
				_skipped += 1
				continue
			_tilt_emit("tetra", q.x, y - _rng.randf_range(0.15, 0.45), q.z, _rng.randf() * TAU, sc, var_i,
				_rng.randf_range(-0.14, 0.14), _rng.randf_range(-0.14, 0.14))
		f += 0.0014


## Zid de corali jos pe dreapta (golful), la 3,1 m de margine, module de 4 m, cu goluri rare.
func _wall_run() -> void:
	var i1 := _idx(0.950)
	var i := _idx(0.838)
	var cnt := 0
	while i < i1:
		var ia := i
		var ib := i + 2
		var la: Vector3 = _track.baked[ia]
		var lb: Vector3 = _track.baked[ib]
		var a := la - _left(ia) * (_track.width_at_index(ia) + 3.1)
		var b := lb - _left(ib) * (_track.width_at_index(ib) + 3.1)
		var m := (a + b) * 0.5
		var d := Vector2(b.x - a.x, b.z - a.z).normalized()
		var lo := minf(minf(_sol(a.x, a.z), _sol(b.x, b.z)), _sol(m.x, m.z))
		cnt += 1
		i += 2
		if cnt % 9 == 0:
			continue  # gol (acces la mal)
		if lo < _sea + 0.2:
			continue
		if _edge_dist(m.x, m.z) < 2.5:
			continue
		_emit("wall", m.x, lo - 0.08, m.z, atan2(d.x, d.y), 1.0)


## Notch rocks in larg (stanga), >= 27 m de axa, in afara ferestrei valului 0.86-0.90.
func _notches() -> void:
	var specs := [
		["notch_a", 0.843, 30.0, 1.7, 0.4], ["notch_c", 0.853, 36.0, 1.5, 2.2],
		["notch_b", 0.912, 29.0, 1.6, 4.1], ["notch_a", 0.926, 34.0, 1.5, 1.0],
		["notch_c", 0.939, 31.0, 1.7, 3.0], ["notch_b", 0.949, 38.0, 1.4, 5.2],
	]
	for sp in specs:
		var q := _pos_ax(sp[1], 1.0, sp[2])
		var g := _sol(q.x, q.z)
		var y := maxf(g, _sea - 2.2) - 0.1
		_emit(sp[0], q.x, y, q.z, sp[4], sp[3])


func _shore(frac: float, side: float) -> Vector3:
	var lat := 8.0
	while lat < 60.0:
		var q := _pos_ax(frac, side, lat)
		if _sol(q.x, q.z) < _sea + 0.05:
			return q
		lat += 0.5
	return Vector3.INF


func _stone(x: float, z: float, variant: int, sc: float, sink: float = 0.25) -> bool:
	if not _free(x, z, 0.35 * sc * float(variant)):
		return false
	var y := _sol(x, z)
	if y < _sea - 1.0:
		return false
	_variant = variant
	var prev := _nocol_all
	_nocol_all = true
	_emit("coral", x, maxf(y, _sea - 0.15) - sink * sc, z, _rng.randf() * TAU, sc)
	_nocol_all = prev
	return true


func _stones(c: Vector3, n: int, rad: float) -> void:
	for k in n:
		var a := _rng.randf() * TAU
		var d := rad * sqrt(_rng.randf())
		var q := c + Vector3(cos(a), 0.0, sin(a)) * d
		if _edge_dist(q.x, q.z) < 3.5:
			continue
		_stone(q.x, q.z, _rng.randi_range(1, 5), _rng.randf_range(0.9, 1.7))


func _land_xz(kind: String, q: Vector3, sc: float, yaw: float, min_edge: float) -> bool:
	var y := _sol(q.x, q.z)
	if y < _sea + 0.25 or _edge_dist(q.x, q.z) < min_edge or not _free(q.x, q.z, float(RADIUS[kind]) * sc):
		_skipped += 1
		return false
	_emit(kind, q.x, y - 0.05, q.z, yaw, sc)
	return true


## Palc fara coliziune: `n` piese in jurul unui centru dat prin (frac, side, lat de la MARGINE).
func _patch(frac: float, side: float, lat: float, rad: float, n: int, mix: Array, min_edge: float = 2.0) -> void:
	var c := _pos_at(frac, side, lat)
	var placed := 0
	var tries := 0
	var prev := _nocol_all
	_nocol_all = true
	while placed < n and tries < n * 8:
		tries += 1
		var a := _rng.randf() * TAU
		var d := rad * sqrt(_rng.randf())
		var q := c + Vector3(cos(a), 0.0, sin(a)) * d
		var kind: String = mix[_rng.randi() % mix.size()]
		var sc := 1.0
		var me := min_edge
		match kind:
			"pandanus":
				sc = _rng.randf_range(1.2, 1.7)
				me = maxf(min_edge, 4.0)
			"cycad": sc = _rng.randf_range(0.9, 1.4)
			"hibiscus": sc = _rng.randf_range(1.0, 1.5)
			"bougain": sc = _rng.randf_range(1.0, 1.4)
		if _land_xz(kind, q, sc, _rng.randf() * TAU, me):
			placed += 1
	_nocol_all = prev


func _build() -> void:
	var low := ["hibiscus", "hibiscus", "cycad", "hibiscus", "bougain", "cycad", "hibiscus", "pandanus"]
	var mid := ["pandanus", "pandanus", "hibiscus", "pandanus", "cycad", "hibiscus", "pandanus", "bougain"]
	# 1. zidul de corali (dreapta), apoi tetrapozii (stanga), apoi stancile din larg
	_wall_run()
	_tetrapods()
	_notches()
	# 2. bolovani pe linia apei, dreapta (golful), in grupuri rare
	var sf := 0.832
	while sf < 0.972:
		var sp := _shore(sf + _rng.randf_range(-0.001, 0.001), -1.0)
		if sp != Vector3.INF:
			_stones(sp, _rng.randi_range(3, 6), 3.5)
		sf += 0.006
	# 3. umplerea benzii: palcuri joase si medii, dreapta pe toata felia, stanga doar pe capete
	_nocol_all = true
	var f := 0.826
	while f < 0.973:
		var ff := f + _rng.randf_range(-0.0008, 0.0008)
		_patch(ff, -1.0, _rng.randf_range(1.6, 5.5), 2.6, _rng.randi_range(4, 7), low, 2.0)
		_patch(ff, -1.0, _rng.randf_range(7.0, 15.0), 4.0, _rng.randi_range(5, 9), mid, 3.0)
		# stanga: doar unde exista uscat larg si NU in fereastra valului (0.856-0.934)
		if f < 0.856 or f > 0.934:
			_patch(ff, 1.0, _rng.randf_range(1.6, 5.5), 2.6, _rng.randi_range(4, 7), low, 2.0)
			if f < 0.846 or f > 0.962:
				_patch(ff, 1.0, _rng.randf_range(8.0, 16.0), 4.0, _rng.randi_range(5, 9), mid, 3.0)
		f += 0.0030
	# petice de hibiscus rosu / bougainvillea magenta, grupate
	var hf := 0.830
	var hn := 0
	while hf < 0.971:
		var sd := -1.0
		if (hn % 3 == 2) and (hf < 0.856 or hf > 0.934):
			sd = 1.0
		_patch(hf, sd, _rng.randf_range(2.2, 6.0), 2.4, 7, ["hibiscus", "hibiscus", "hibiscus", "hibiscus", "bougain"], 2.0)
		hf += 0.0085
		hn += 1
	_nocol_all = false


func _write() -> void:
	print("; asezate %d piese, %d sarite; %s" % [_n, _skipped, str(_counts)])
	var lines: Array[String] = []
	lines.append("; --- EXT_RESOURCES (de lipit in antet) ---")
	lines.append_array(_ext)
	lines.append("; --- NODURI (de lipit la sfarsit, sub ZonaH) ---")
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
