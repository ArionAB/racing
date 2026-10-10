extends Node
## Generator de decor MANUAL pentru POI G - INSULA MICA SI PLAJA (Track20, Okinawa,
## frac 0.737-0.824). Calculeaza transformarile care se lipesc in Track20.tscn sub
## `DecorManual/ZonaG` (tiparul gen_decor_ok_f.gd). NU atinge tromba (hazard din cod,
## marker 0.7758) si ii lasa culoarul de ratacire liber de orice cu coliziune.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorOkG.tscn -- \
##       --out=C:/cale/zonaG.part
##   python tools/apply_zone_g.py C:/cale/zonaG.part

const TRACK := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaG"
## Culoarul trombei: frac 0.752-0.806, pana la 24 m de axa (maturarea merge pana la ~22 m).
const TY_F0 := 0.752
const TY_F1 := 0.806
const TY_LAT := 24.0

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
	_sampler = _track._sampler
	_sea = float(_sampler.mean_road_y()) + float(_track.sea_level_offset)
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 200926
	print("; mare y=%.2f" % _sea)
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


## In culoarul trombei? (cu coliziune: interzis; fara: doar piese joase)
func _in_typhoon(x: float, z: float) -> bool:
	var nr := _near(x, z)
	var f := nr.x / float(_track.baked.size())
	return f >= TY_F0 and f <= TY_F1 and nr.y < TY_LAT


const PATHS := {
	"notch_a": "res://assets/models/okinawa/rocks/notch_rock_a.glb",
	"notch_b": "res://assets/models/okinawa/rocks/notch_rock_b.glb",
	"notch_c": "res://assets/models/okinawa/rocks/notch_rock_c.glb",
	"heart": "res://assets/models/okinawa/rocks/heart_rock.glb",
	"cycad": "res://assets/models/okinawa/plants/cycad.glb",
	"fanpalm": "res://assets/models/okinawa/plants/fan_palm.glb",
	"bougain": "res://assets/models/okinawa/plants/bougainvillea.glb",
	"pandanus": "res://assets/models/trees/pandanus.glb",
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"sabani": "res://assets/models/vehicles/sabani_boat.glb",
	"clutter": "res://assets/models/scatter/beach_clutter.glb",
	"netrack": "res://assets/models/okinawa/props/fishing_net_rack.glb",
	"egret": "res://assets/models/okinawa/animals/egret.glb",
	"turtle": "res://assets/models/props/sea_turtle.glb",
}
## Raza (m) de ocupare per tip, la scara 1, pentru evitarea suprapunerilor.
const RADIUS := {
	"notch_a": 3.0, "notch_b": 3.5, "notch_c": 3.0, "heart": 4.6, "cycad": 1.0,
	"fanpalm": 1.8, "bougain": 1.2, "pandanus": 1.8, "hibiscus": 0.9, "sabani": 2.6,
	"clutter": 0.9, "netrack": 1.5, "egret": 0.5, "turtle": 1.9,
}
const NAMES := {
	"notch_a": "Notch", "notch_b": "Notch", "notch_c": "Notch", "heart": "Inima",
	"cycad": "Cicas", "fanpalm": "Palmier", "bougain": "Bougainvillea",
	"pandanus": "Pandanus", "hibiscus": "Hibiscus", "sabani": "Sabani",
	"clutter": "Flotor", "netrack": "Plasa", "egret": "Egreta", "turtle": "Broasca",
}
## Tipurile joase (<~3 m): singurele permise (fara coliziune) in culoarul trombei.
const LOW := ["hibiscus", "cycad", "bougain", "pandanus", "clutter", "sabani", "egret", "netrack"]


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


func _ref(kind: String) -> String:
	if not _res.has(kind):
		_res[kind] = "g_%s" % kind
		_ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % [PATHS[kind], _res[kind]])
	return _res[kind]


func _emit(kind: String, x: float, y: float, z: float, yaw: float, sc: float) -> void:
	var ref := _ref(kind)
	var b := Basis(Vector3.UP, yaw)
	b = b.scaled(Vector3(sc, sc, sc))
	_seq[NAMES[kind]] = int(_seq.get(NAMES[kind], 0)) + 1
	var rows := []
	for r in 3:
		rows.append("%.5f, %.5f, %.5f" % [b.x[r], b.y[r], b.z[r]])
	_out.append('[node name="%s_G%02d" parent="%s" instance=ExtResource("%s")]' % [
		NAMES[kind], int(_seq[NAMES[kind]]), ZONE, ref])
	_out.append("transform = Transform3D(%s, %s, %s, %.2f, %.3f, %.2f)" % [
		rows[0], rows[1], rows[2], x, y, z])
	if kind in ["bougain", "cycad", "hibiscus", "clutter", "egret"] or _nocol_all:
		_out.append('metadata/coliziune = "none"')
	_out.append("")
	_placed.append(Vector4(x, z, float(RADIUS[kind]) * sc, 0.0))
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	_n += 1


## Piesa pe uscat; cu coliziune nu intra in culoarul trombei; edge >= min_edge.
func _land_xz(kind: String, q: Vector3, sc: float, yaw: float, min_edge: float) -> bool:
	var y := _sol(q.x, q.z)
	if y < _sea + 0.9 or _edge_dist(q.x, q.z) < min_edge or not _free(q.x, q.z, float(RADIUS[kind]) * sc):
		_skipped += 1
		return false
	if _in_typhoon(q.x, q.z):
		if not _nocol_all or not (kind in LOW):
			_skipped += 1
			return false
	_emit(kind, q.x, y - 0.05, q.z, yaw, sc)
	return true


func _land(kind: String, frac: float, side: float, lat: float, sc: float, yaw: float, min_edge: float) -> bool:
	return _land_xz(kind, _pos_at(frac, side, lat), sc, yaw, min_edge)


## Stanca in apa putin adanca, in jurul ancorei; nu in culoarul trombei.
func _rock_xz(kind: String, base: Vector3, sc: float, yaw: float, lo: float = 0.2, hi: float = 1.9, min_edge: float = 12.0) -> Vector3:
	var r := float(RADIUS[kind])
	for ring in 14:
		for k in 16:
			var a := TAU * float(k) / 16.0 + float(ring)
			var q := base + Vector3(cos(a), 0.0, sin(a)) * float(ring) * 2.0
			var dep := _sea - _sol(q.x, q.z)
			if dep < lo or dep > hi:
				continue
			if _edge_dist(q.x, q.z) < min_edge or _in_typhoon(q.x, q.z):
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
			return q
	print("; stanca sarita %s la (%.0f, %.0f)" % [kind, base.x, base.z])
	_skipped += 1
	return Vector3.INF


func _rock(kind: String, frac: float, side: float, lat: float, sc: float, yaw: float) -> Vector3:
	return _rock_xz(kind, _pos_at(frac, side, lat), sc, yaw)


## Palc de umplere (fara coliziune): `n` piese in jurul unui centru dat prin (frac, side, edge).
func _patch(frac: float, side: float, lat: float, rad: float, n: int, mix: Array, min_edge: float = 3.0) -> void:
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
				me = maxf(min_edge, 4.5)
			"fanpalm": sc = _rng.randf_range(1.0, 1.3)
			"cycad": sc = _rng.randf_range(0.9, 1.4)
			"hibiscus": sc = _rng.randf_range(1.0, 1.5)
			"bougain": sc = _rng.randf_range(1.0, 1.4)
		if _land_xz(kind, q, sc, _rng.randf() * TAU, me):
			placed += 1
	_nocol_all = prev


func _heart() -> void:
	# Stanca-inima: in apa golfului (dreapta), la ~25-35 m de axa; fata inimii
	# (planul XY al modelului) spre drum.
	var best := Vector3.INF
	for f in [0.802, 0.806, 0.798, 0.810, 0.794]:
		for lat in [24.0, 27.0, 30.0, 22.0]:
			var q := _pos_at(f, -1.0, lat)
			var dep := _sea - _sol(q.x, q.z)
			if dep < 0.35 or dep > 1.7 or _edge_dist(q.x, q.z) < 14.0:
				continue
			var ok := true
			for m in 8:
				var b := float(m) * PI * 0.25
				var qq := q + Vector3(cos(b), 0.0, sin(b)) * 6.0
				var d2 := _sea - _sol(qq.x, qq.z)
				if d2 < -2.5 or d2 > 3.5:
					ok = false
			if ok:
				best = q
				break
		if best != Vector3.INF:
			break
	if best == Vector3.INF:
		print("; INIMA nu si-a gasit loc")
		return
	var vp: Vector3 = _track.baked[_idx(0.782)]
	var to := vp - best
	to.y = 0.0
	to = to.normalized()
	var yaw := atan2(to.x, to.z)
	print("; inima la (%.1f, %.1f) adancime %.2f yaw %.2f" % [best.x, best.z, _sea - _sol(best.x, best.z), yaw])
	_emit("heart", best.x, _sol(best.x, best.z) - 0.1, best.z, yaw, 1.45)


func _turtle(frac: float, side: float, lat: float) -> void:
	var c := _pos_at(frac, side, lat)
	var i := _idx(frac)
	var t := _tangent(i)
	var y := _sol(c.x, c.z)
	if y < _sea + 0.9:
		print("; broasca sarita (apa)")
		return
	var ref := _ref("turtle")
	var sref := "g_pathmover"
	if not _res.has("pathmover"):
		_res["pathmover"] = sref
		_ext.append('[ext_resource type="Script" path="res://scenes/props/path_mover.gd" id="%s"]' % sref)
	# traseu scurt (7 m) paralel cu plaja, dus-intors, foarte lent
	var p1 := t * 3.5
	var p2 := -t * 3.5
	_out.append('[node name="Broasca_G01" type="Path3D" parent="%s"]' % ZONE)
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.2f, %.3f, %.2f)" % [c.x, y, c.z])
	_out.append('script = ExtResource("%s")' % sref)
	_out.append('model = ExtResource("%s")' % ref)
	_out.append("model_scale = 1.6")
	_out.append("collide = false")
	_out.append("points = PackedVector3Array(%.2f, 0, %.2f, %.2f, 0, %.2f)" % [p1.x, p1.z, p2.x, p2.z])
	_out.append("speed = 0.22")
	_out.append("travel_mode = 1")
	_out.append("")
	_placed.append(Vector4(c.x, c.z, 4.5, 0.0))
	_counts["turtle"] = 1
	_n += 1


func _build() -> void:
	var low := ["hibiscus", "cycad", "pandanus", "hibiscus", "bougain", "cycad", "pandanus", "hibiscus"]
	var mid := ["pandanus", "pandanus", "hibiscus", "pandanus", "cycad", "hibiscus", "pandanus", "bougain"]
	# --- 1. inima (O SINGURA) ---
	_heart()
	# --- 2. stancile-ciuperca in apa mica, ambele laturi (dincolo de culoarul trombei) ---
	var specs := [
		["notch_a", 0.746, 1.0, 14.0, 1.45, 0.7], ["notch_c", 0.752, 1.0, 22.0, 1.2, 2.4],
		["notch_b", 0.786, 1.0, 26.0, 1.5, 4.0], ["notch_a", 0.772, 1.0, 36.0, 1.1, 5.0],
		["notch_c", 0.760, -1.0, 22.0, 1.3, 1.1], ["notch_b", 0.790, -1.0, 24.0, 1.0, 3.3],
		["notch_a", 0.818, -1.0, 62.0, 1.4, 0.2],
	]
	for sp in specs:
		_rock(sp[0], sp[1], sp[2], sp[3], sp[4], sp[5])
	# --- 4. palmieri-evantai (cel mult 2, spre pod) ---
	var fp := 0
	for fa in [[0.742, 1.0, 11.0], [0.7405, -1.0, 12.0], [0.745, 1.0, 13.0], [0.739, -1.0, 14.0]]:
		if fp < 2 and _land("fanpalm", fa[0], fa[1], fa[2], 1.2, 0.5, 8.0):
			fp += 1
	# --- 3. pandanus-hero cu coliziune (trunchi), grupuri de 3, in afara culoarului ---
	var groups := [
		[0.745, -1.0, 12.0], [0.744, 1.0, 9.0], [0.808, -1.0, 12.0],
		[0.8115, 1.0, 14.0], [0.7395, -1.0, 9.0], [0.818, -1.0, 22.0],
		[0.8005, 1.0, 11.0], [0.8135, -1.0, 9.0], [0.822, 1.0, 12.0],
	]
	for g in groups:
		var c := _pos_at(g[0], g[1], g[2])
		var got := 0
		var tries := 0
		while got < 3 and tries < 30:
			tries += 1
			var q := c + Vector3(_rng.randf_range(-5.0, 5.0), 0.0, _rng.randf_range(-5.0, 5.0))
			if _land_xz("pandanus", q, _rng.randf_range(1.5, 1.8), _rng.randf() * TAU, 7.0):
				got += 1
	# --- 6. sabani trase pe nisip + plase/flotoare (uscat, >= 9 m de asfalt) ---
	for bsp in [[0.748, 1.0, 12.0, 0.9], [0.8085, 1.0, 11.0, 2.4], [0.8175, -1.0, 10.0, 4.1]]:
		_land("sabani", bsp[0], bsp[1], bsp[2], 1.1, bsp[3], 9.0)
	_nocol_all = true
	_land("netrack", 0.8085, 1.0, 9.0, 1.0, 1.0, 8.0)
	for cl in [[0.7475, 1.0, 9.5], [0.8095, 1.0, 14.0], [0.8165, -1.0, 12.0], [0.7425, 1.0, 12.0], [0.7945, 1.0, 10.0], [0.7925, -1.0, 11.5]]:
		_land("clutter", cl[0], cl[1], cl[2], 1.0, _rng.randf() * TAU, 6.0)
	_land("egret", 0.7705, 1.0, 17.0, 1.0, 1.5, 6.0)
	_land("egret", 0.8, -1.0, 12.0, 1.0, 4.0, 6.0)
	_nocol_all = false
	# --- 7. broasca (animata) pe plaja dreapta, >= 10 m de asfalt ---
	_turtle(0.8075, 1.0, 12.0)

	# --- 5. umplerea benzii: palcuri de tufe joase si medii, ambele laturi, toata felia ---
	_nocol_all = true
	var f := 0.738
	while f < 0.8235:
		for side in [-1.0, 1.0]:
			# banda apropiata (4-8 m de bordura): tufe joase, petice
			_patch(f + _rng.randf_range(-0.001, 0.001), side, _rng.randf_range(4.0, 8.0), 3.0, _rng.randi_range(4, 7), low)
			# banda din spate (10-17 m): amestec dens cu pandanus
			_patch(f + _rng.randf_range(-0.001, 0.001), side, _rng.randf_range(9.0, 16.0), 4.5, _rng.randi_range(6, 10), mid, 3.0)
		f += 0.0028
	# petice de hibiscus rosu (accentul viu), aproape de drum
	for hf in [0.742, 0.756, 0.769, 0.783, 0.797, 0.811, 0.7455, 0.8035]:
		var sd := 1.0 if (int(hf * 1000.0) % 2 == 0) else -1.0
		_patch(hf, sd, _rng.randf_range(3.6, 6.0), 2.2, 5, ["hibiscus", "hibiscus", "hibiscus", "bougain"], 3.0)
	_nocol_all = false

func _write() -> void:
	print("; asezate %d piese, %d sarite; %s" % [_n, _skipped, str(_counts)])
	var lines: Array[String] = []
	lines.append("; --- EXT_RESOURCES (de lipit in antet) ---")
	lines.append_array(_ext)
	lines.append("; --- NODURI (de lipit la sfarsit, sub ZonaG) ---")
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
