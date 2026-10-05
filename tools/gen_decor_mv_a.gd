extends Node
## Generator de decor MANUAL pentru POI A — STARTUL PE PLATOU (Track19, Monument
## Valley, frac 0.985-1.000 + 0.000-0.056, x >= 190). Tiparul gen_decor_jod_a.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMvA.tscn -- \
##       --out=C:/cale/zonaA.part
##
## Calculeaza transformarile care se lipesc in Track19.tscn sub
## `DecorManual/ZonaA`, plus nodul `Fire` (TelegraphWires) cu aceleasi pozitii
## ca stalpii. Pozitiile vin din contractul A (monument_poi_gauntlet.md).

const TRACK := "res://scenes/tracks/Track19.tscn"
const ZONE := "DecorManual/ZonaA"
const SEMI := 7.0

const RES := {
	"trading_post": "s_trading_post", "pickup_old": "s_pickup_old",
	"water_tower": "s_water_tower", "windmill_pump": "s_windmill_pump",
	"horse_bay": "11_horse_bay", "horse_pinto": "11_horse_pinto",
	"horse_black": "s_horse_black", "telegraph_pole": "s_telegraph_pole",
	"wire_fence": "s_wire_fence", "raven": "s_raven",
	"talus_boulders_a": "s_talus_boulders_a", "talus_boulders_b": "s_talus_boulders_b",
	"juniper": "s_juniper", "sagebrush": "s_sagebrush", "rabbitbrush": "s_rabbitbrush",
	"mesa_wall_module": "s_mesa_wall_module",
}

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
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
	_rng.seed = 51005
	_index_path()
	if "--terrain" in OS.get_cmdline_user_args():
		_print_terrain()
		get_tree().quit(0)
		return
	_poles()
	_fence()
	_post_and_pickup()
	_water()
	_scatter()
	_wires_node()
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


## Punct pe axa la arclength s (cu infasurare), directia (xz) si normala stanga.
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


func _print_terrain() -> void:
	for x in [230.0, 250.0, 270.0, 290.0, 330.0]:
		var line := "x=%d: " % int(x)
		for z in [-120.0, -90.0, -70.0, -55.0, -40.0, -20.0, 0.0, 10.0, 20.0, 40.0, 60.0]:
			line += "z%d=%.1f " % [int(z), _sol(x, z)]
		print(line)
	for s in [-20.0, 0.0, 40.0, 84.0, 117.0]:
		print("s=%.0f p=%s" % [s, _at(s)["p"]])


# ------------------------------------------------------------------ piese

## 8 stalpi pe partea STANGA (nord pe dreapta, exteriorul virajului), la 10 m de
## margine (17 m de axa), spatiere 18 m, de la x 190 pana inaintea lui B.
## Runda 2: mai deci si mai departe de drum decat gardul (care trece prin fata).
func _poles() -> void:
	var ss := [-18.0, 0.0, 18.0, 36.0, 54.0, 72.0, 90.0, 108.0]
	for s: float in ss:
		var q := _at(s)
		var n: Vector2 = q["n"]
		var p3: Vector3 = q["p"]
		var lat := SEMI + 10.0
		var x := p3.x + n.x * lat
		var z := p3.z + n.y * lat
		var yaw := atan2(-n.y, n.x)
		# Verificare de semn (memoria rotatii-in-builder-semnul): X-ul local
		# rotit trebuie sa fie normala drumului.
		var xl := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3.RIGHT
		assert(absf(xl.x * n.x + xl.z * n.y) > 0.999)
		var y := _sol(x, z)
		_raw("telegraph_pole", "aStalp", Vector3(x, y, z), yaw, 1.0, "")
		_pole_pos.append(Vector3(x, y, z))
		_pole_yaw.append(yaw)
	# Doi corbi pe traversele stalpilor 2 si 5 (varful izolatorului stang).
	for k in [2, 5]:
		var base := _pole_pos[k]
		var yw := _pole_yaw[k]
		var tip := base + Basis.from_euler(Vector3(0, yw, 0)) * Vector3(-0.75, 7.52, 0.0)
		_raw("raven", "aCorb", tip, yw + PI * 0.5 + _rng.randf_range(-0.4, 0.4), 1.4, "")
		# Ancora de sol: baza stalpului (probe_manual nu-l mai ia drept plutitor).
		_meta_last("metadata/ancora_sol = Vector3(0, %.3f, 0)" % (-7.52 / 1.4))


## Gard de sarma paralel cu drumul, la 6,5 m de margine (13,5 m de axa), pe
## curba (corzi de 4 m), de la s = -10 la s = 94: 26 de segmente (~104 m).
## Segmentul merge pe Z local: yaw = atan2(dx, dz).
func _fence() -> void:
	var s := -10.0
	while s < 94.0:
		var q0 := _at(s)
		var q1 := _at(s + 4.0)
		var a := _off(q0, SEMI + 6.5)
		var b := _off(q1, SEMI + 6.5)
		var m := (a + b) * 0.5
		var yaw := atan2(b.x - a.x, b.z - a.z)
		_raw("wire_fence", "aGard", Vector3(m.x, _sol(m.x, m.z), m.z), yaw, 1.0, "")
		s += 4.0


## Punct decalat lateral (stanga) fata de axa la arclength dat de `q`.
func _off(q: Dictionary, lat: float) -> Vector3:
	var n: Vector2 = q["n"]
	var p3: Vector3 = q["p"]
	return Vector3(p3.x + n.x * lat, 0.0, p3.z + n.y * lat)


## Catunul compact la 10-20 m de margine, 25-50 m in fata camerei de pe grila
## (x 262-300, z -58..-72): postul cu prispa spre drum, pickup-ul in fata lui,
## turnul de apa in dreapta, grup liber de 4 cai intre ei si drum.
func _post_and_pickup() -> void:
	var pp := Vector3(281.0, 0.0, -70.0)
	pp.y = _sol(pp.x, pp.z)
	_raw("trading_post", "aPost", pp, PI + 0.12, 1.0, "")
	var pk := Vector3(266.0, 0.0, -64.0)
	pk.y = _sol(pk.x, pk.z)
	_raw("pickup_old", "aPickup", pk, 0.55, 1.0, "")
	var tw := Vector3(299.0, 0.0, -64.0)
	tw.y = _sol(tw.x, tw.z)
	_raw("water_tower", "aTurn", tw, 0.4, 1.0, "")


func _water() -> void:
	# Moara cu jgheab ramane reper de fundal pe axa lui H, cu cai in jurul
	# jgheabului (jgheabul, -Z local, spre vest).
	var mw := Vector3(337.0, 0.0, -50.0)
	mw.y = _sol(mw.x, mw.z)
	var myaw := PI * 0.5
	var chk := Basis.from_euler(Vector3(0, myaw, 0)) * Vector3(0, 0, -1)
	assert(chk.x < -0.99)
	_raw("windmill_pump", "aMoara", mw, myaw, 1.0, "")
	var trough := mw + Basis.from_euler(Vector3(0, myaw, 0)) * Vector3(0, 0, -2.15)
	var kinds := ["horse_bay", "horse_pinto", "horse_black"]
	var angs: Array[float] = [PI * 0.62, PI * 1.1, PI * 1.55]
	var rads: Array[float] = [3.4, 3.6, 3.5]
	for k in 3:
		var a: float = angs[k]
		var hp: Vector3 = trough + Vector3(cos(a), 0, sin(a)) * rads[k]
		hp.y = _sol(hp.x, hp.z)
		var tdir: Vector3 = trough - hp
		var yaw := atan2(-tdir.x, -tdir.z) + _rng.randf_range(-0.3, 0.3)
		_raw(kinds[k], "aCal", hp, yaw, 1.0, "none")
		_hide_pose()
	# Grupul nou de 4 cai, liber, intre post si drum (8-15 m de asfalt).
	var spots := [Vector3(272.0, 0, -60.0), Vector3(277.5, 0, -63.0),
		Vector3(283.0, 0, -59.5), Vector3(289.0, 0, -62.0)]
	var hk := ["horse_pinto", "horse_bay", "horse_black", "horse_pinto"]
	for k in 4:
		var hp: Vector3 = spots[k]
		hp.y = _sol(hp.x, hp.z)
		_raw(hk[k], "aCalG", hp, _rng.randf() * TAU, 1.0, "none")
		_hide_pose()


func _scatter() -> void:
	# Grohotis (2), ienuperi (2) si tufe la picioarele catunului, in pâlcuri.
	for g in [[287.0, -78.0, "talus_boulders_a"], [263.0, -73.0, "talus_boulders_b"]]:
		var p := Vector3(g[0], 0.0, g[1])
		p.y = _sol(p.x, p.z)
		_raw(g[2], "aTalus", p, _rng.randf() * TAU, 1.0, "")
	for g in [[272.0, -76.0], [306.0, -70.0]]:
		var p := Vector3(g[0], 0.0, g[1])
		p.y = _sol(p.x, p.z)
		_raw("juniper", "aIenupar", p, _rng.randf() * TAU, 1.0, "")
	# 5 tufe de salvie in 2 pâlcuri (la post si la turn), 3 rabbitbrush.
	for c in [Vector3(274.0, -57.0, 3.0), Vector3(293.0, -57.5, 2.0)]:
		for i in int(c.z):
			var o := Vector2(_rng.randf_range(-2.6, 2.6), _rng.randf_range(-1.8, 1.8))
			var p := Vector3(c.x + o.x, 0.0, c.y + o.y)
			p.y = _sol(p.x, p.z)
			_raw("sagebrush", "aSalvie", p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.3), "")
	for c in [Vector3(268.0, -68.0, 2.0), Vector3(297.0, -72.0, 1.0)]:
		for i in int(c.z):
			var o := Vector2(_rng.randf_range(-1.8, 1.8), _rng.randf_range(-1.4, 1.4))
			var p := Vector3(c.x + o.x, 0.0, c.y + o.y)
			p.y = _sol(p.x, p.z)
			_raw("rabbitbrush", "aRabbit", p, _rng.randf() * TAU, _rng.randf_range(0.9, 1.2), "")


func _wires_node() -> void:
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


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	var rid: String = RES[model]
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, rid])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")
	_last_name = "%s%d" % [base, _n]


## Calul static are doua poze in acelasi GLB: o ascundem pe cea de mers.
func _meta_last(line: String) -> void:
	_out.insert(_out.size() - 1, line)


func _hide_pose() -> void:
	_out.append('[node name="Pose_Walk" parent="%s/%s" index="1"]' % [ZONE, _last_name])
	_out.append("visible = false")
	_out.append("")


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
