extends Node
## Generator de decor MANUAL pentru POI G2 - ALBIA SECATA + GRILA H (Track19,
## Monument Valley, frac 0.826-0.866). Tiparul gen_decor_mv_b.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvG2.tscn -- --survey
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvG2.tscn -- --out=C:/cale/zonaG2.part
##
## Scrie fragmentul de lipit in Track19.tscn sub DecorManual/ZonaG2.

const TRACK := "res://scenes/tracks/Track19.tscn"
const ZONE := "DecorManual/ZonaG2"
const SEMI := 7.0
## Culoarul de zbor al ChannelKicker (gol 0.834-0.846 = s 1743-1768): 30 m in fata,
## 40 m in spate. Nimic cu coliziune la < FLY_LAT de axa in intervalul asta.
const FLY_S0 := 1713.0
const FLY_S1 := 1808.0
const FLY_LAT := 16.0

const RES := {
	"telegraph_pole": "s_telegraph_pole", "raven": "s_raven",
	"talus_boulders_a": "s_talus_boulders_a", "talus_boulders_b": "s_talus_boulders_b",
	"juniper": "s_juniper", "sagebrush": "s_sagebrush",
	"rabbitbrush": "s_rabbitbrush", "hoodoo": "s_hoodoo",
	"cattle_guard": "s_cattle_guard", "open_range_sign": "s_open_range_sign",
	"tumbleweed": "s_tumbleweed",
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
	print("len=%.1f  frac->s: 0.826=%.1f 0.834=%.1f 0.846=%.1f 0.8593=%.1f 0.866=%.1f" % [
		_len, 0.826 * _len, 0.834 * _len, 0.846 * _len, 0.8593 * _len, 0.866 * _len])
	var prev := Vector2.ZERO
	for s in range(1680, 1840, 8):
		var q := _at(float(s))
		var p3: Vector3 = q["p"]
		var d: Vector2 = q["d"]
		var hd := fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)
		var turn := 0.0
		if prev != Vector2.ZERO:
			turn = rad_to_deg(prev.angle_to(d))
		prev = d
		var line := "s=%d p=(%.1f,%.2f,%.1f) h=%.0f dturn=%.1f n=(%.2f,%.2f) |" % [s, p3.x, p3.y, p3.z, hd, turn, q["n"].x, q["n"].y]
		for lat in [-40, -30, -20, -15, -10, -8, 8, 10, 15, 20, 30, 40]:
			var o := _off(q, float(lat))
			line += " %d:%.1f" % [lat, _sol(o.x, o.z) - p3.y]
		print(line)


# ------------------------------------------------------------------ piese

func _build() -> void:
	_grid()
	_poles()
	_formations()
	_talus()
	_clusters()
	_patches()


## Ce coboara sub cota soselei (>0 = adancime) la (s, lat): albia secata.
func _drop(s: float, lat: float) -> float:
	var q := _at(s)
	var o := _off(q, lat)
	var p3: Vector3 = q["p"]
	return p3.y - _sol(o.x, o.z)


## Marginea exterioara a albiei pe latura `side` (+1 stanga, -1 dreapta) la `s`:
## primul lat (in afara) dupa care terenul revine la < 0,6 m sub sosea.
## -1.0 daca la s nu exista albie.
func _lip(s: float, side: float) -> float:
	var in_pit := false
	var lat := 9.0
	while lat < 60.0:
		var d := _drop(s, side * lat)
		if d > 1.0:
			in_pit = true
		elif in_pit and d < 0.6:
			return lat
		lat += 0.5
	return -1.0


## Yaw care roteste -Z local (fata pieselor) spre directia (dx, dz) in plan.
func _face(dx: float, dz: float) -> float:
	var yaw := atan2(-dx, -dz)
	var f := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(0, 0, -1)
	var l := Vector2(dx, dz).normalized()
	assert(f.x * l.x + f.z * l.y > 0.999)
	return yaw


## A doua grila pentru vite, la 0.8593: X-ul local peste drum (perpendicular pe
## directia h ~ 054), centrata pe axa, la cota soselei. PLATA, fara coliziune.
func _grid() -> void:
	var s := 0.8593 * _len
	var q := _at(s)
	var d: Vector2 = q["d"]
	var n: Vector2 = q["n"]
	# X-ul local = (cos t, 0, -sin t) pentru yaw t; cerem dot(X, d) ~ 0.
	var yaw := atan2(-n.y, n.x)
	var xl := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3.RIGHT
	assert(absf(xl.x * d.x + xl.z * d.y) < 0.02)
	var p3: Vector3 = q["p"]
	print("; grila H: s=%.1f p=%s h=%.1f deg  dot(X,d)=%.4f" % [s, p3,
		fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0), xl.x * d.x + xl.z * d.y])
	_raw("cattle_guard", "g2Grila", Vector3(p3.x, p3.y + 0.01, p3.z), yaw, 1.0, "")
	# Semnul cu calul, pe latura interioara a virajului (dreapta), la 2,5 m de
	# bordura, cu fata spre masinile care vin (spre punctul de la s - 25).
	var ss := s - 14.0
	var qs := _at(ss)
	var half: float = qs["half"]
	var sp := _on(ss, -(half + 2.5))
	var from := _at(ss - 25.0)["p"] as Vector3
	_raw("open_range_sign", "g2Semn", sp, _face(from.x - sp.x, from.z - sp.z), 1.0, "none")


var _pole_pos := PackedVector3Array()
var _pole_yaw := PackedFloat32Array()


## Doi stalpi pe latura stanga (nord pe H), la 16,5 m de axa: in afara culoarului
## de zbor (+-15 m), cu trunchi (coliziune `trunk`) deci doar dincolo de el.
func _poles() -> void:
	for s in [1774.0, 1796.0]:
		var q := _at(s)
		var n: Vector2 = q["n"]
		var pp := _on(s, FLY_LAT + 0.5)
		var yaw := atan2(-n.y, n.x)
		var xl := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3.RIGHT
		assert(absf(xl.x * n.x + xl.z * n.y) > 0.999)
		_raw("telegraph_pole", "g2Stalp", pp, yaw, 1.0, "")
		_pole_pos.append(pp)
		_pole_yaw.append(yaw)
		if s == 1796.0:
			var tip := pp + Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(-0.75, 7.52, 0.0)
			_raw("raven", "g2Corb", tip, yaw + PI * 0.5 + 0.3, 1.4, "")
			_meta_last("metadata/ancora_sol = Vector3(0, %.3f, 0)" % (-7.52 / 1.4))
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


## Hoodoo-ul pe malul stang al albiei, in axa privirii celui care soseste (la ~8
## grade de directia de mers de la s = 1710), 34 m de axa, dincolo de buza.
func _formations() -> void:
	var p := _on(1768.0, 34.0)
	_raw("hoodoo", "g2Hoodoo", p, 4.0, 1.0, "")


## 4 grupuri de talus pe maluri (la buza albiei, fara coliziune: culoarul de
## zbor), plus bolovani mici raspanditi pe buze.
func _talus() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 82601
	var spec := [[1748.0, 1.0, "talus_boulders_b", 1.1], [1741.0, -1.0, "talus_boulders_a", 1.2],
		[1759.0, 1.0, "talus_boulders_a", 1.0], [1779.0, -1.0, "talus_boulders_b", 1.0]]
	for g in spec:
		var s: float = g[0]
		var side: float = g[1]
		var lip := _lip(s, side)
		if lip < 0.0:
			print("; ATENTIE: fara buza la s=%.0f side=%.0f" % [s, side])
			continue
		_raw(g[2], "g2Talus", _on(s, side * (lip + 1.8)), r.randf() * TAU, g[3], "none")
		# doi bolovani mici pe panta buzei
		for k in 2:
			var ss := s + r.randf_range(-7.0, 7.0)
			var lp := _lip(ss, side)
			if lp < 0.0:
				continue
			var pick := "talus_boulders_a" if r.randf() < 0.5 else "talus_boulders_b"
			_raw(pick, "g2Piatra", _on(ss, side * (lp + r.randf_range(-1.0, 3.0))),
				r.randf() * TAU, r.randf_range(0.4, 0.6), "none")
	# Tumbleweed: doua, pe buza dreapta.
	for s in [1750.0, 1764.0]:
		var lp := _lip(s, -1.0)
		if lp > 0.0:
			_raw("tumbleweed", "g2Tumble", _on(s, -(lp + 0.8)), r.randf() * TAU, 1.2, "none")
	for sd in [[1745.0, 1.0], [1762.0, 1.0], [1757.0, -1.0], [1771.0, -1.0]]:
		var lp := _lip(sd[0], sd[1])
		if lp > 0.0:
			_raw("sagebrush", "g2Salvie", _on(sd[0], sd[1] * (lp + 0.3)), r.randf() * TAU,
				r.randf_range(1.1, 1.4), "none")


func _ok_spot(p: Vector3, road_y: float, s: float, lat: float) -> bool:
	# nu in albie, nu pe grila (|ds| < 5 m, |lat| < 9.5)
	if road_y - p.y > 0.8:
		return false
	if absf(s - 0.8593 * _len) < 5.0 and absf(lat) < 9.5:
		return false
	return true


## Palcuri mixte (ienupar mic + salvie + rabbitbrush, 3-6 per palc), goluri
## neregulate, de la 2-4 m de bordura pana la ~25 m. Ienuperii (trunchi cu
## coliziune) doar la >= FLY_LAT de axa in culoarul de zbor. Coroana la >= 0,3 m
## de bordura. Nu pe albie (_ok_spot).
func _clusters() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 90226
	var n_cl := 0
	for side in [1.0, -1.0]:
		var s := 1727.0 + (3.0 if side < 0.0 else 0.0)
		while s < 1809.0:
			# gol neregulat: ~30 % din pozitii raman goale
			if r.randf() < 0.3:
				s += r.randf_range(5.0, 9.0)
				continue
			var layer := r.randi_range(0, 3)
			if n_cl % 2 == 0:
				layer = r.randi_range(0, 1)
			var m: float = [3.0, 7.0, 13.0, 21.0][layer] + r.randf_range(-1.0, 1.5)
			_mixed_clump(r, s + r.randf_range(-2.0, 2.0), side, m)
			n_cl += 1
			s += r.randf_range(7.0, 11.0)
	print("; palcuri: %d" % n_cl)


func _mixed_clump(r: RandomNumberGenerator, s: float, side: float, margin: float) -> void:
	var q := _at(s)
	var d: Vector2 = q["d"]
	var half: float = q["half"]
	var kinds: Array[String] = []
	var scales: Array[float] = []
	var count := r.randi_range(3, 6)
	for i in count:
		var roll := r.randf()
		if roll < 0.28:
			kinds.append("juniper")
			scales.append(r.randf_range(0.55, 0.8))
		elif roll < 0.62:
			kinds.append("sagebrush")
			scales.append(r.randf_range(1.0, 1.5))
		else:
			kinds.append("rabbitbrush")
			scales.append(r.randf_range(0.95, 1.25))
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
		var in_fly := s > FLY_S0 and s < FLY_S1
		if kind == "juniper" and in_fly and absf(lat) < FLY_LAT + 1.5:
			kind = "sagebrush"
			sc = r.randf_range(1.0, 1.3)
		var p := _off(q, lat)
		p.x += d.x * ox
		p.z += d.y * ox
		p.y = _sol(p.x, p.z)
		var road_y: float = (q["p"] as Vector3).y
		if not _ok_spot(p, road_y, s + ox, lat):
			continue
		var base := "g2Ienupar" if kind == "juniper" else ("g2Rabbit" if kind == "rabbitbrush" else "g2Salvie")
		_raw(kind, base, p, r.randf() * TAU, sc, "")


## 3 petice de rabbitbrush (accentul galben) pe buzele albiei si pe campul din
## spatele grilei, la 25-45 m de axa.
func _patches() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4417
	for sp in [[1733.0, 1.0, 30.0], [1789.0, -1.0, 26.0], [1805.0, 1.0, 34.0]]:
		for k in r.randi_range(4, 6):
			var s: float = sp[0] + r.randf_range(-4.0, 4.0)
			var lat: float = sp[1] * (sp[2] + r.randf_range(-3.0, 3.0))
			var q := _at(s)
			var p := _off(q, lat)
			p.y = _sol(p.x, p.z)
			if (q["p"] as Vector3).y - p.y > 0.8:
				continue
			_raw("rabbitbrush", "g2Petic", p, r.randf() * TAU, r.randf_range(0.95, 1.3), "")


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
