extends Node
## Generator de decor MANUAL pentru POI G - CAMPIA DESCHISA + G' (Track19,
## Monument Valley, frac 0.600-0.826). Tiparul gen_decor_mv_g2.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvG.tscn -- --survey
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvG.tscn -- --out=C:/cale/zonaG.part
##
## Scrie fragmentul de lipit in Track19.tscn sub DecorManual/ZonaG.

const TRACK := "res://scenes/tracks/Track19.tscn"
const ZONE := "DecorManual/ZonaG"
const SEMI := 7.0
const RES := {
	"telegraph_pole": "s_telegraph_pole", "raven": "s_raven",
	"talus_boulders_a": "s_talus_boulders_a", "talus_boulders_b": "s_talus_boulders_b",
	"juniper": "s_juniper", "sagebrush": "s_sagebrush",
	"rabbitbrush": "s_rabbitbrush", "hoodoo": "s_hoodoo",
	"cattle_guard": "s_cattle_guard", "open_range_sign": "s_open_range_sign",
	"tumbleweed": "s_tumbleweed", "butte_small_a": "s_butte_small_a", "butte_small_c": "s_butte_small_c", "rock_fin": "s_rock_fin", "yucca": "s_yucca",
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
	print("len=%.1f  s: 0.600=%.1f 0.645=%.1f 0.6555=%.1f 0.754=%.1f 0.826=%.1f" % [
		_len, 0.600 * _len, 0.645 * _len, 0.6555 * _len, 0.754 * _len, 0.826 * _len])
	var prev := Vector2.ZERO
	for s in range(1250, 1735, 12):
		var q := _at(float(s))
		var p3: Vector3 = q["p"]
		var d: Vector2 = q["d"]
		var hd := fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)
		var turn := 0.0
		if prev != Vector2.ZERO:
			turn = rad_to_deg(prev.angle_to(d))
		prev = d
		var line := "s=%d f=%.3f p=(%.1f,%.2f,%.1f) h=%.0f dturn=%.1f n=(%.2f,%.2f) half=%.1f |" % [s, s / _len, p3.x, p3.y, p3.z, hd, turn, q["n"].x, q["n"].y, q["half"]]
		for lat in [-40, -20, -10, 10, 20, 40]:
			var o := _off(q, float(lat))
			line += " %d:%.1f" % [lat, _sol(o.x, o.z) - p3.y]
		print(line)
	var r1: TrackRoute = _track.routes[1]
	print("route1: n=%d half=%.1f entry=%.4f exit=%.4f len=%.1f" % [r1.baked.size(), r1.half_width, r1.entry_frac, r1.exit_frac, r1.dists[r1.dists.size() - 1]])
	for i in range(0, r1.baked.size(), 5):
		var p: Vector3 = r1.baked[i]
		print("r1 i=%d d=%.1f p=(%.1f,%.2f,%.1f)" % [i, r1.dists[i], p.x, p.y, p.z])


## ------------------------------------------------------------------ piese

const S0 := 1262.0
const S1 := 1690.0
const BR_HALF := 3.5
## Raze nominale (m, la scara 1) pentru distantele intre piese.
const RAD := {"sagebrush": 0.7, "rabbitbrush": 0.77, "juniper": 2.1, "tumbleweed": 0.5,
	"yucca": 0.6, "talus_boulders_a": 2.0, "talus_boulders_b": 2.6, "raven": 0.5,
	"butte_small_a": 7.0, "butte_small_c": 7.0, "rock_fin": 4.0, "hoodoo": 3.5}
const VORTEX := [Vector2(-8.7, 142.0), Vector2(-10.0, 125.0)]

var _br: TrackRoute
var _placed: Array = [] # [Vector2, radius]
var _counts := {}


func _build() -> void:
	_br = _track.routes[1]
	_formations()
	_clumps_main()
	_clumps_branch()
	_talus_field()
	_patches()
	_tumble()
	_ravens()
	print("; pe tipuri: ", _counts)


func _axis_main(p: Vector3) -> float:
	var best := 1e9
	for i in _pts.size():
		if _cum[i] < 1130.0 or _cum[i] > 1860.0:
			continue
		best = minf(best, Vector2(_pts[i].x - p.x, _pts[i].z - p.z).length())
	return best


## [dist, d_pe_banda, y_banda] pana la cel mai apropiat punct al benzii Dunele.
func _axis_br(p: Vector3) -> Array:
	var best := 1e9
	var bd := 0.0
	var by := 0.0
	for i in _br.baked.size():
		var b := _br.baked[i]
		var d := Vector2(b.x - p.x, b.z - p.z).length()
		if d < best:
			best = d
			bd = _br.dists[i]
			by = b.y
	return [best, bd, by]


## Piesa cu raza r, mod de coliziune: "none" / "trunk" / "hull".
func _fits(p: Vector3, r: float, mode: String) -> bool:
	var pm := Vector2(p.x, p.z)
	var em := _axis_main(p) - 7.0
	var ab := _axis_br(p)
	var eb: float = ab[0] - BR_HALF
	if mode == "none":
		var crown := 0.3 + r
		if em < crown or eb < crown:
			return false
	elif mode == "trunk":
		if em < 3.8 or eb < 3.8 or em < 0.3 + r or eb < 0.3 + r:
			return false
	else:
		if em < 5.0 + r * 0.5 or eb < 5.0 + r * 0.5:
			return false
	# nimic cu coliziune la gura G (primii 25 m + 7 m dupa) la < 8 m de banda
	if mode != "none" and float(ab[1]) < 40.0 and eb < 8.0:
		return false
	if mode != "none":
		for v in VORTEX:
			if pm.distance_to(v) < 22.0 + r:
				return false
		if p.x > -18.0 - r and p.x < 10.0 + r and p.z > 62.0 - r and p.z < 90.0 + r:
			return false
	# nu peste petecul rabbitbrush al lui G2
	if pm.distance_to(Vector2(-70.0, 66.0)) < 13.0 + r:
		return false
	# nu pe cocoase langa banda (teren peste cota benzii) si nu in groapa
	if eb < 14.0:
		if p.y > float(ab[2]) + 0.6 or p.y < float(ab[2]) - 1.6:
			return false
	for o in _placed:
		if pm.distance_to(o[0]) < (r + float(o[1])) * 0.8:
			return false
	return true


func _put(model: String, base: String, p: Vector3, yaw: float, scl: float, mode_meta: String,
		mode: String) -> bool:
	var r: float = float(RAD[model]) * scl
	if not _fits(p, r, mode):
		return false
	_raw(model, base, p, yaw, scl, mode_meta)
	_placed.append([Vector2(p.x, p.z), r])
	_counts[model] = int(_counts.get(model, 0)) + 1
	return true


func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, _sol(x, z), z)


## 5 formatiuni: doua butte-uri in interiorul S-urilor + un ac de stanca,
## doua hoodoo de o parte si de alta a gurii G (reper de pe cornisa).
func _formations() -> void:
	var spec := [
		["butte_small_c", "gButteC", Vector2(22.0, 140.0), 0.6],
		["butte_small_a", "gButteA", Vector2(-32.0, 98.0), 2.2],
		["rock_fin", "gFin", Vector2(-47.0, 106.0), 4.3],
		["hoodoo", "gHoodooN", Vector2(-85.0, 138.0), 1.0],
		["hoodoo", "gHoodooS", Vector2(-72.0, 184.0), 3.6],
	]
	for f in spec:
		var c: Vector2 = f[2]
		var p := _ground(c.x, c.y)
		var ok := _put(f[0], f[1], p, f[3], 1.0, "", "hull")
		var ab := _axis_br(p)
		print("; formatiune %s (%.1f,%.1f) ok=%s dist_axa_main=%.1f dist_axa_banda=%.1f" % [
			f[1], c.x, c.y, ok, _axis_main(p), ab[0]])


func _kind_for(r: RandomNumberGenerator, margin: float) -> Array:
	# rabbitbrush = accent (~15 %), salvie dominanta; ienuperi doar la >= 3,8 m
	var roll := r.randf()
	if roll < 0.15:
		return ["rabbitbrush", r.randf_range(1.2, 1.6), "gRabbit"]
	if margin >= 4.4 and roll < 0.42:
		return ["juniper", r.randf_range(0.7, 0.95), "gIenupar"]
	return ["sagebrush", r.randf_range(1.4, 1.9), "gSalvie"]


## Ciorchini de tufe MARI la marginea drumului: strat strans (0,4-1,4 m de
## bordura, doar tufe fara coliziune), mediu (3,8-6 m) si larg (8-15 m).
func _clump(r: RandomNumberGenerator, q: Dictionary, side: float, margin: float,
		half: float, n: int) -> void:
	var d: Vector2 = q["d"]
	for i in n:
		var k := _kind_for(r, margin)
		var kind: String = k[0]
		var sc: float = k[1]
		var lat: float = side * (half + margin + r.randf_range(-0.4, 1.4))
		var p := _off(q, lat)
		var ox := r.randf_range(-2.4, 2.4)
		p.x += d.x * ox
		p.z += d.y * ox
		p.y = _sol(p.x, p.z)
		var meta := "" if kind == "juniper" else "none"
		_put(kind, k[2], p, r.randf() * TAU, sc, meta, "trunk" if kind == "juniper" else "none")
	# un bolovan mic (fara coliziune) in unele ciorchini
	if r.randf() < 0.35:
		var bl: float = side * (half + margin + r.randf_range(-0.2, 1.2))
		var bp := _off(q, bl)
		bp.x += d.x * r.randf_range(-2.5, 2.5)
		bp.z += d.y * r.randf_range(-2.5, 2.5)
		bp.y = _sol(bp.x, bp.z)
		var pick := "talus_boulders_a" if r.randf() < 0.55 else "talus_boulders_b"
		_put(pick, "gPiatra", bp, r.randf() * TAU, r.randf_range(0.22, 0.4), "none", "none")


func _pick_margin(r: RandomNumberGenerator) -> float:
	var roll := r.randf()
	if roll < 0.40:
		return r.randf_range(0.4, 1.4)
	if roll < 0.80:
		return r.randf_range(3.8, 5.6)
	return r.randf_range(8.0, 15.0)


func _clumps_main() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 60826
	var n := 0
	for side in [1.0, -1.0]:
		var s := S0 + (0.0 if side > 0.0 else 7.0)
		while s < S1:
			if r.randf() < 0.22:
				s += r.randf_range(8.0, 14.0)
				continue
			var q := _at(s)
			_clump(r, q, side, _pick_margin(r), 7.0, r.randi_range(2, 4))
			n += 1
			s += r.randf_range(8.0, 14.0)
	print("; ciorchini main: %d" % n)


## Ciorchini pe banda Dunele (drum de nisip de 3,5 m): tufe la 0,4-1,4 m si la
## 3,8-6 m, ienuperi la >= 3,8 m, nimic cu coliziune la gura.
func _clumps_branch() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 64575
	var total: float = _br.dists[_br.dists.size() - 1]
	var n := 0
	for side in [1.0, -1.0]:
		var d := 6.0 + (0.0 if side > 0.0 else 8.0)
		while d < total - 6.0:
			var q := _at_br(d)
			if r.randf() < 0.25:
				d += r.randf_range(8.0, 12.0)
				continue
			var m := r.randf_range(0.4, 1.4) if r.randf() < 0.5 else r.randf_range(3.8, 6.0)
			_clump(r, q, side, m, BR_HALF, r.randi_range(2, 3))
			n += 1
			d += r.randf_range(13.0, 22.0)
	print("; ciorchini banda: %d" % n)


func _at_br(dd: float) -> Dictionary:
	var i := 0
	for k in _br.dists.size() - 1:
		if _br.dists[k] <= dd:
			i = k
		else:
			break
	i = mini(i, _br.baked.size() - 2)
	var a := _br.baked[i]
	var b := _br.baked[i + 1]
	var seg := maxf(a.distance_to(b), 0.001)
	var t := clampf((dd - _br.dists[i]) / seg, 0.0, 1.0)
	var p := a.lerp(b, t)
	var dir := Vector2(b.x - a.x, b.z - a.z).normalized()
	return {"p": p, "d": dir, "n": Vector2(dir.y, -dir.x), "half": BR_HALF}


## Grupuri de talus (hull) la 9-15 m de ancore: formatiuni si interiorul S-urilor.
func _talus_field() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 77113
	var anchors := [Vector2(22.0, 140.0), Vector2(-32.0, 98.0), Vector2(-84.0, 139.0),
		Vector2(-72.0, 184.0), Vector2(-135.0, 140.0), Vector2(-5.0, 205.0), Vector2(45.0, 120.0),
		Vector2(-60.0, 90.0)]
	var made := 0
	for a in anchors:
		for tries in 12:
			var ang := r.randf() * TAU
			var rad := r.randf_range(9.0, 15.0)
			var c: Vector2 = a + Vector2(cos(ang), sin(ang)) * rad
			var pick := "talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b"
			if _put(pick, "gTalus", _ground(c.x, c.y), r.randf() * TAU, r.randf_range(0.9, 1.2),
					"", "hull"):
				made += 1
				for k in 2:
					var o := c + Vector2(r.randf_range(-4.0, 4.0), r.randf_range(-4.0, 4.0))
					var pk := "talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b"
					_put(pk, "gPiatra", _ground(o.x, o.y), r.randf() * TAU,
						r.randf_range(0.3, 0.45), "none", "none")
				break
		if made >= 8:
			break
	print("; grupuri talus hull: %d" % made)


## Petice de rabbitbrush (accentul galben), niciodata aliniate, cate 3-5.
func _patches() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4491
	var centers := [Vector2(-120.0, 150.0), Vector2(-48.0, 124.0), Vector2(6.0, 158.0),
		Vector2(52.0, 112.0), Vector2(30.0, 84.0), Vector2(-24.0, 74.0), Vector2(-135.0, 196.0),
		Vector2(18.0, 192.0)]
	var made := 0
	for c in centers:
		var k := 0
		var target := r.randi_range(3, 4)
		for tries in 20:
			if k >= target:
				break
			var o: Vector2 = c + Vector2(r.randf_range(-4.5, 4.5), r.randf_range(-4.5, 4.5))
			if _put("rabbitbrush", "gPetic", _ground(o.x, o.y), r.randf() * TAU,
					r.randf_range(0.95, 1.3), "none", "none"):
				k += 1
		made += 1 if k > 0 else 0
	print("; petice: %d" % made)


## Tumbleweed pe terenul deschis, 8-30 m de drum.
func _tumble() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 3207
	var k := 0
	var tries := 0
	while k < 8 and tries < 200:
		tries += 1
		var q := _at(r.randf_range(S0, S1))
		var side := 1.0 if r.randf() < 0.5 else -1.0
		var p := _off(q, side * (7.0 + r.randf_range(8.0, 30.0)))
		p.y = _sol(p.x, p.z)
		if _put("tumbleweed", "gTumble", p, r.randf() * TAU, r.randf_range(1.0, 1.3), "none", "none"):
			k += 1
	print("; tumbleweed: %d" % k)


## 2 corbi la sol, pe camp.
func _ravens() -> void:
	var k := 0
	for c in [Vector2(-28.0, 112.0), Vector2(16.0, 154.0)]:
		for dx in [0.0, 2.5, -2.5, 5.0]:
			var p := _ground(c.x + dx, c.y)
			if _put("raven", "gCorb", p, 0.5 + dx, 1.4, "none", "none"):
				k += 1
				break
	print("; corbi: %d" % k)


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
