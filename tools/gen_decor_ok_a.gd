extends Node
## Generator de decor MANUAL pentru POI A — PORTUL SI SATUL (Track20, Okinawa,
## frac 0.974-1.000 + 0.000-0.1023). Tiparul gen_decor_mv_a.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorOkA.tscn -- --scan
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorOkA.tscn -- --out=C:/cale/zonaA.part
##
## Emite blocuri `[node ...]` pentru `DecorManual/ZonaA` + ext_resource-urile
## cu id prefixat `a_` (le lipeste tools/splice_ok_a.py in Track20.tscn).

const TRACK := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaA"
const SEMI := 7.0

const PATHS := {
	"ryukyu_house_a": "res://assets/models/okinawa/buildings/ryukyu_house_a.glb",
	"ryukyu_house_b": "res://assets/models/okinawa/buildings/ryukyu_house_b.glb",
	"ryukyu_house_c": "res://assets/models/okinawa/buildings/ryukyu_house_c.glb",
	"concrete_house_a": "res://assets/models/okinawa/buildings/concrete_house_a.glb",
	"concrete_house_b": "res://assets/models/okinawa/buildings/concrete_house_b.glb",
	"harbour_quay": "res://assets/models/okinawa/structures/harbour_quay.glb",
	"coral_stone_wall": "res://assets/models/okinawa/structures/coral_stone_wall.glb",
	"bus_stop_shelter": "res://assets/models/okinawa/structures/bus_stop_shelter.glb",
	"vending_machine": "res://assets/models/okinawa/props/vending_machine.glb",
	"convex_mirror": "res://assets/models/okinawa/props/convex_mirror.glb",
	"fishing_net_rack": "res://assets/models/okinawa/props/fishing_net_rack.glb",
	"fan_palm": "res://assets/models/okinawa/plants/fan_palm.glb",
	"bougainvillea": "res://assets/models/okinawa/plants/bougainvillea.glb",
	"fishing_boat": "res://assets/models/okinawa/vehicles/fishing_boat.glb",
	"sabani_boat": "res://assets/models/vehicles/sabani_boat.glb",
	"beach_clutter": "res://assets/models/scatter/beach_clutter.glb",
	"banyan": "res://assets/models/trees/banyan.glb",
	"shisa_statue": "res://assets/models/props/shisa_statue.glb",
	"shisa_statue_closed": "res://assets/models/props/shisa_statue_closed.glb",
	"hibiscus_bush": "res://assets/models/plants/hibiscus_bush.glb",
	"coconut_palm": "res://assets/models/trees/coconut_palm.glb",
}

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _used := {}
var _n := 0
var _out_path := ""
var _rng := RandomNumberGenerator.new()
var _pts: PackedVector3Array
var _cum: PackedFloat32Array
var _len := 0.0
var _counts := {}


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
	_rng.seed = 20001
	_index_path()
	if "--aabb" in OS.get_cmdline_user_args():
		_print_aabb()
		get_tree().quit(0)
		return
	if "--map" in OS.get_cmdline_user_args():
		_map()
		get_tree().quit(0)
		return
	if "--map2" in OS.get_cmdline_user_args():
		_map2()
		get_tree().quit(0)
		return
	if "--scan" in OS.get_cmdline_user_args():
		_scan()
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


## Punct pe axa la arclength s (cu infasurare), directia (xz) si normala STANGA.
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


func _print_aabb() -> void:
	for k in PATHS:
		var ps := load(PATHS[k]) as PackedScene
		if ps == null:
			print("%s: LIPSA" % k)
			continue
		var m := ps.instantiate() as Node3D
		add_child(m)
		var bb := Track.model_aabb(m)
		print("%s: pos=%s size=%s" % [k, bb.position, bb.size])
		m.queue_free()


func _map() -> void:
	var road := {}
	for s in range(-140, 215, 1):
		var p3: Vector3 = _at(float(s))["p"]
		road["%d,%d" % [int(round(p3.x / 4.0)), int(round(p3.z / 4.0))]] = true
	for zi in range(28, 58):
		var line := "z%4d " % (zi * 4)
		for xi in range(-48, 48):
			var k := "%d,%d" % [xi, zi]
			if road.has(k):
				line += "R"
			else:
				var y := _sol(xi * 4.0, zi * 4.0)
				line += "~" if y < 0.05 else ("." if y < 1.0 else "-")
		print(line)
	print("x from -192 step 4")


func _map2() -> void:
	var hdr := "       "
	for x in range(84, 140, 3):
		hdr += "%5d" % x
	print(hdr)
	for z in range(120, 180, 3):
		var line := "z%4d  " % z
		for x in range(84, 140, 3):
			line += "%5.1f" % _sol(float(x), float(z))
		print(line)


func _scan() -> void:
	print("len=%.1f" % _len)
	for s in range(-60, 215, 15):
		var q := _at(float(s))
		var p3: Vector3 = q["p"]
		var line := "s=%4d p=(%.1f,%.1f,%.1f) d=(%.2f,%.2f) | " % [s, p3.x, p3.y, p3.z, q["d"].x, q["d"].y]
		for lat in [-60.0, -40.0, -25.0, -15.0, -10.0, 10.0, 15.0, 25.0, 40.0, 60.0, 80.0]:
			var o := _off(q, lat)
			line += "%d:%.1f " % [int(lat), _sol(o.x, o.z)]
		print(line)


## Punct decalat lateral (lat>0 = STANGA, lat<0 = DREAPTA) fata de axa.
func _off(q: Dictionary, lat: float) -> Vector3:
	var n: Vector2 = q["n"]
	var p3: Vector3 = q["p"]
	return Vector3(p3.x + n.x * lat, 0.0, p3.z + n.y * lat)



# ------------------------------------------------------------------ piese

var _circles: Array[Vector3] = []   # (x, z, r) piese cu corp, pentru respingere
var _hib := 0
var _bou := 0


func _road_dist(x: float, z: float) -> float:
	var best := 1e9
	for i in _pts.size():
		var p := _pts[i]
		var d := Vector2(p.x - x, p.z - z).length()
		if d < best:
			best = d
	return best


func _free(x: float, z: float, r: float) -> bool:
	for c in _circles:
		if Vector2(c.x - x, c.y - z).length() < c.z + r:
			return false
	return true


func _claim(x: float, z: float, r: float) -> void:
	_circles.append(Vector3(x, z, r))


## Yaw cu fata (-Z local) spre vectorul xz `f`.
func _yaw_face(f: Vector2) -> float:
	var yaw := atan2(-f.x, -f.y)
	var chk := Basis.from_euler(Vector3(0, yaw, 0)) * Vector3(0, 0, -1)
	assert(chk.x * f.x + chk.z * f.y > 0.999)
	return yaw


## Yaw cu axa Z locala PE directia `d` (ziduri, rafturi).
func _yaw_along(d: Vector2) -> float:
	return atan2(d.x, d.y)


func _ground5(x: float, z: float, hx: float, hz: float) -> float:
	var lo := 1e9
	for o in [Vector2(0, 0), Vector2(hx, hz), Vector2(-hx, hz), Vector2(hx, -hz), Vector2(-hx, -hz)]:
		lo = minf(lo, _sol(x + o.x, z + o.y))
	return lo


## Casa (curte inclusa) cu fata spre drum. `front` = distanta de la AXA pana la
## zidul din fata al curtii; `side` = +1 stanga (sud), -1 dreapta (nord).
func _house(model: String, s: float, front: float, side: float, w: float, dep: float,
		tag: String) -> bool:
	var q := _at(s)
	var lat := side * (front + dep * 0.5)
	var o := _off(q, lat)
	var n: Vector2 = q["n"]
	var f := n * (-side)          # spre drum
	var r := 0.5 * sqrt(w * w + dep * dep) * 0.82
	if not _free(o.x, o.z, r):
		return false
	var y := _ground5(o.x, o.z, w * 0.4, dep * 0.4) - 0.04
	if y < 0.3:
		return false              # tarmul apei
	_claim(o.x, o.z, r)
	_raw(model, tag, Vector3(o.x, y, o.z), _yaw_face(f), 1.0)
	return true


func _wall_run(s0: float, s1: float, lat: float, skip_zone: bool) -> void:
	var s := s0
	while s < s1:
		if skip_zone and s > -8.0 and s < 34.0:
			s += 4.0
			continue
		var qa := _at(s)
		var qb := _at(s + 4.0)
		var a := _off(qa, lat)
		var b := _off(qb, lat)
		var m := (a + b) * 0.5
		var d := Vector2(b.x - a.x, b.z - a.z).normalized()
		var y := _sol(m.x, m.z) - 0.05
		if y > 0.3:
			_raw("coral_stone_wall", "aZid", Vector3(m.x, y, m.z), _yaw_along(d), 1.0)
		s += 4.0


func _flower(model: String, tag: String, x: float, z: float, scl: float, yaw: float) -> void:
	var y := _sol(x, z) - 0.03
	if y < 0.3:
		return
	_raw(model, tag, Vector3(x, y, z), yaw, scl, "none")


func _build() -> void:
	_street()
	var order := ["ryukyu_house_a", "ryukyu_house_b", "ryukyu_house_c"]
	var dims := {"ryukyu_house_a": Vector2(14, 12), "ryukyu_house_b": Vector2(16, 12),
		"ryukyu_house_c": Vector2(11.1, 10.0)}
	# 1) primul rand NORD (dreapta): fatada spre drum; in gabaritul de start
	#    (s -8..34) curtea sta la 17,5 m de axa, nu la 13.
	var s := -44.0
	var k := 0
	while s < 198.0:
		var m: String = order[(k + int(_rng.randi() % 2)) % 3]
		var dm: Vector2 = dims[m]
		var in_zone := (s + dm.x > -8.0 and s < 34.0)
		var front := 17.5 if in_zone else 13.0 + _rng.randf_range(0.0, 1.5)
		var ok := _house(m, s + dm.x * 0.5, front, -1.0, dm.x, dm.y, "aCasaN")
		if ok:
			s += dm.x + _rng.randf_range(2.5, 5.0)
		else:
			s += 6.0
		k += 1
	# 2) primul rand SUD (stanga): fasie intre drum si plaja
	s = -6.0
	k = 1
	while s < 190.0:
		var m2: String = order[(k + int(_rng.randi() % 3)) % 3]
		var dm2: Vector2 = dims[m2]
		if s < 36.0 and s + dm2.x > -8.0:
			s = 36.0
			continue
		var ok2 := _house(m2, s + dm2.x * 0.5, 13.0 + _rng.randf_range(0.0, 2.0), 1.0,
			dm2.x, dm2.y, "aCasaS")
		if ok2:
			s += dm2.x + _rng.randf_range(3.0, 9.0)
		else:
			s += 8.0
		k += 1
	# 3) al doilea rand NORD: case de beton (rezervoare) si Ryukyu in spate
	var cdim := {"concrete_house_a": Vector2(10.3, 8.2), "concrete_house_b": Vector2(8.2, 7.2)}
	s = -20.0
	k = 0
	var ncon := 0
	while s < 195.0:
		var concrete := (k % 3) != 1 and ncon < 9
		var m3 := "ryukyu_house_c"
		var dm3: Vector2 = dims[m3]
		if concrete:
			m3 = "concrete_house_a" if (k % 2) == 0 else "concrete_house_b"
			dm3 = cdim[m3]
		var front3 := 28.5 + _rng.randf_range(0.0, 3.0)
		var ok3 := _house(m3, s + dm3.x * 0.5, front3, -1.0, dm3.x, dm3.y, "aCasaN2")
		if ok3 and concrete:
			ncon += 1
		if ok3:
			s += dm3.x + _rng.randf_range(5.0, 12.0)
		else:
			s += 6.0
		k += 1
	# 4) zid de corali pe marginea drumului (lat 10,2 = 3,2 m de margine)
	_wall_run(-52.0, 196.0, -10.2, true)
	_wall_run(-52.0, 196.0, 10.2, true)
	_port()
	_flora()


## Mobilier de strada: adapost, automate, oglinzi, shisa, banian.
func _street() -> void:
	var q := _at(88.0)
	var o := _off(q, -(SEMI + 3.6))
	_raw("bus_stop_shelter", "aAutobuz", Vector3(o.x, _sol(o.x, o.z) - 0.04, o.z),
		_yaw_face(q["n"]), 1.0)
	_claim(o.x, o.z, 3.0)
	for ss in [79.0, 98.0]:
		var qq := _at(ss)
		var oo := _off(qq, -(SEMI + 3.4))
		_raw("vending_machine", "aAutomat", Vector3(oo.x, _sol(oo.x, oo.z) - 0.03, oo.z),
			_yaw_face(qq["n"]), 1.0)
		_claim(oo.x, oo.z, 1.0)
	# oglinzi convexe la curbe: exteriorul virajului, cu fata spre sosire
	for mm in [[-52.0, -1.0], [108.0, 1.0], [201.0, 1.0]]:
		var qm := _at(mm[0])
		var om := _off(qm, float(mm[1]) * (SEMI + 2.7))
		var d: Vector2 = qm["d"]
		_raw("convex_mirror", "aOglinda", Vector3(om.x, _sol(om.x, om.z) - 0.03, om.z),
			_yaw_face(-d), 1.0)
		_claim(om.x, om.z, 0.6)
	# perechea shisa la intrarea in sat (s = 42), una pe fiecare parte, 1,5x
	for sd in [-1.0, 1.0]:
		var qs := _at(42.0)
		var os := _off(qs, sd * (SEMI + 3.6))
		var mdl := "shisa_statue" if sd < 0.0 else "shisa_statue_closed"
		var ns: Vector2 = qs["n"]
		_raw(mdl, "aShisa", Vector3(os.x, _sol(os.x, os.z) - 0.03, os.z),
			_yaw_face(ns * (-sd)), 1.5)
		_claim(os.x, os.z, 2.0)
	# banianul-reper in sat (nord), al doilea pe fasia de plaja
	for bb in [[128.0, -27.0, 1.5], [60.0, 32.0, 1.3], [10.0, -34.0, 1.4], [165.0, 30.0, 1.3], [92.0, -48.0, 1.5], [188.0, -36.0, 1.3], [140.0, 34.0, 1.3]]:
		var qb := _at(bb[0])
		var ob := _off(qb, bb[1])
		if _free(ob.x, ob.z, 5.0):
			_claim(ob.x, ob.z, 5.0)
			_raw("banyan", "aBanian", Vector3(ob.x, _sol(ob.x, ob.z) - 0.05, ob.z),
				_rng.randf() * TAU, bb[2])


func _shore_point(from: Vector2, w: Vector2) -> Vector2:
	var p := from
	for i in 200:
		if _sol(p.x, p.y) < 0.12:
			return p
		p += w * 0.5
	return p


## Portul: cheiul in 3 module paralele cu tarmul + un mol perpendicular, barci,
## plase, flotoare, palmieri la >= 30 m de axa.
func _port() -> void:
	var w := Vector2(0.75, -0.67).normalized()   # spre apa (NE)
	var u := Vector2(0.67, 0.75).normalized()    # de-a lungul tarmului
	var yaw_q := atan2(w.y, -w.x)                # -X local -> w
	var chk := Basis.from_euler(Vector3(0, yaw_q, 0)) * Vector3(-1, 0, 0)
	assert(chk.x * w.x + chk.z * w.y > 0.999)
	var anchors := [Vector2(97, 141), Vector2(105, 150), Vector2(113, 159)]
	var shore: Array[Vector2] = []
	for a in anchors:
		var sp := _shore_point(a - w * 14.0, w)
		shore.append(sp)
		var org := sp - w * 1.6
		_raw("harbour_quay", "aCheu", Vector3(org.x, 0.05, org.y), yaw_q, 1.0)
		_claim(org.x, org.y, 7.0)
	# molul: un modul perpendicular, in apa, la capatul de nord
	var mp: Vector2 = shore[0] + w * 7.0 - u * 9.0
	var yaw_m := atan2(-u.y, u.x)
	_raw("harbour_quay", "aMol", Vector3(mp.x, 0.05, mp.y), yaw_m, 1.0)
	# barci: in bazin, paralele cu cheul
	var boats := [[1, 5.2, "fishing_boat"], [1, 9.5, "fishing_boat"], [0, 5.5, "fishing_boat"],
		[2, 6.5, "fishing_boat"], [0, 11.5, "sabani_boat"], [2, 11.0, "sabani_boat"]]
	var yaw_b := atan2(u.x, u.y)
	for b in boats:
		var base: Vector2 = shore[b[0]]
		var bp: Vector2 = base + w * float(b[1]) + u * _rng.randf_range(-2.0, 2.0)
		var yb := yaw_b + (PI if _rng.randf() < 0.5 else 0.0) + _rng.randf_range(-0.12, 0.12)
		_raw(b[2], "aBarca", Vector3(bp.x, 0.05, bp.y), yb, 1.0)
	# sabani trase pe nisip, pe fasia de plaja (stanga drumului)
	for ss in [18.0, 63.0, 96.0]:
		var qq := _at(ss)
		var oo := _off(qq, 50.0 + _rng.randf_range(0.0, 8.0))
		_raw("sabani_boat", "aSabani", Vector3(oo.x, _sol(oo.x, oo.z) - 0.03, oo.z),
			_yaw_along(Vector2(qq["d"])) + _rng.randf_range(-0.2, 0.2), 1.0)
	# rafturi cu plase si flotoare/lazi pe chei
	for i in 2:
		var pp: Vector2 = shore[1 + i] - w * 5.2 - u * 1.0
		_raw("fishing_net_rack", "aPlase", Vector3(pp.x, 1.5, pp.y), yaw_q + PI * 0.5, 1.0)
	for i in 6:
		var base2: Vector2 = shore[i % 3] - w * (4.0 + _rng.randf_range(0.0, 5.0)) \
			+ u * _rng.randf_range(-6.0, 6.0)
		var y2 := _sol(base2.x, base2.y)
		if y2 > 0.3:
			_raw("beach_clutter", "aFlotor", Vector3(base2.x, y2 - 0.03, base2.y),
				_rng.randf() * TAU, 1.0)
	for i in 3:
		var qq2 := _at(30.0 + 35.0 * i)
		var oo2 := _off(qq2, 36.0 + _rng.randf_range(0.0, 10.0))
		_raw("beach_clutter", "aFlotorP", Vector3(oo2.x, _sol(oo2.x, oo2.z) - 0.03, oo2.z),
			_rng.randf() * TAU, 1.0)
	# palmieri evantai (10) + cocotieri (5): in jurul portului, >= 30 m de axa
	var np := 0
	var nc := 0
	for tries in 2000:
		if np >= 10 and nc >= 4:
			break
		var ctr: Vector2 = shore[_rng.randi() % 3]
		var pos := ctr - w * _rng.randf_range(0.0, 10.0) + u * (_rng.randf_range(10.0, 52.0) * (1.0 if _rng.randf() < 0.5 else -1.0))
		if _sol(pos.x, pos.y) < 0.4 or _road_dist(pos.x, pos.y) < 30.0 \
				or not _free(pos.x, pos.y, 2.5):
			continue
		_claim(pos.x, pos.y, 2.5)
		var yy := _sol(pos.x, pos.y) - 0.04
		if np < 10 and (nc >= 4 or _rng.randf() < 0.7):
			_raw("fan_palm", "aPalmier", Vector3(pos.x, yy, pos.y), _rng.randf() * TAU,
				_rng.randf_range(0.95, 1.25))
			np += 1
		else:
			_raw("coconut_palm", "aCocotier", Vector3(pos.x, yy, pos.y), _rng.randf() * TAU,
				_rng.randf_range(0.9, 1.1))
			nc += 1
	# automat langa chei
	var vp: Vector2 = shore[2] - w * 9.0 + u * 8.0
	if _road_dist(vp.x, vp.y) > 14.0:
		_raw("vending_machine", "aAutomatP", Vector3(vp.x, _sol(vp.x, vp.y) - 0.03, vp.y),
			yaw_q, 1.0)


## Flori in petice: hibiscus (40) si bougainvillea (20), pe lungul zidurilor.
func _flora() -> void:
	var guard := 0
	while _bou < 26 and guard < 3000:
		guard += 1
		var s := _rng.randf_range(-48.0, 196.0)
		var side := -1.0 if _rng.randf() < 0.62 else 1.0
		var q := _at(s)
		var lat := side * (SEMI + 4.0 + _rng.randf_range(0.0, 1.8))
		if s > -8.0 and s < 34.0 and absf(lat) < 16.0:
			continue
		var f: Vector2 = Vector2(q["n"]) * (-side)
		var cnt := 2 + int(_rng.randi() % 2)
		for i in cnt:
			if _bou >= 26:
				break
			var qq := _at(s + float(i) * 2.6)
			var o := _off(qq, lat)
			if not _free(o.x, o.z, 0.5):
				continue
			var y := _sol(o.x, o.z) - 0.02
			if y < 0.3:
				continue
			_bou += 1
			_raw("bougainvillea", "aBugenvilia", Vector3(o.x, y, o.z), _yaw_face(f) + PI,
				1.15, "none")
			_claim(o.x, o.z, 0.4)
	guard = 0
	while _hib < 80 and guard < 4000:
		guard += 1
		var s2 := _rng.randf_range(-50.0, 196.0)
		var side2 := -1.0 if _rng.randf() < 0.5 else 1.0
		var q2 := _at(s2)
		var lat2 := side2 * (SEMI + _rng.randf_range(3.0, 5.6))
		var c := _off(q2, lat2)
		var m := 2 + int(_rng.randi() % 3)
		for i in m:
			if _hib >= 80:
				break
			var px := c.x + _rng.randf_range(-1.6, 1.6)
			var pz := c.z + _rng.randf_range(-1.6, 1.6)
			if not _free(px, pz, 0.5):
				continue
			_flower("hibiscus_bush", "aHibiscus", px, pz, _rng.randf_range(0.9, 1.3),
				_rng.randf() * TAU)
			_hib += 1
			_claim(px, pz, 0.45)


# ------------------------------------------------------------------ iesire

func _res_id(model: String) -> String:
	_used[model] = true
	return "a_" + model


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String = "") -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	_counts[model] = int(_counts.get(model, 0)) + 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, _res_id(model)])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese: %s" % [_n, _counts])
	var hdr: Array[String] = []
	for m in _used:
		hdr.append('[ext_resource type="PackedScene" path="%s" id="a_%s"]' % [PATHS[m], m])
	var text := "\n".join(hdr) + "\n\n=====NODES=====\n" + "\n".join(_out) + "\n"
	if _out_path.is_empty():
		print(text)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	fa.store_string(text)
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
