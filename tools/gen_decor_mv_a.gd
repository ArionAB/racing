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
	"juniper": "s_juniper", "rabbitbrush": "s_rabbitbrush",
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

## 6 stalpi pe partea STANGA (nord pe dreapta, exteriorul virajului), la 7 m de
## margine (14 m de axa), spatiere ~26 m, de la x 190 pana inaintea lui B.
func _poles() -> void:
	var ss := [-18.0, 8.0, 34.0, 60.0, 86.0, 112.0]
	for s: float in ss:
		var q := _at(s)
		var n: Vector2 = q["n"]
		var p3: Vector3 = q["p"]
		var lat := SEMI + 7.0
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
	# Doi corbi pe traversele stalpilor 1 si 4 (varful izolatorului stang).
	for k in [1, 4]:
		var base := _pole_pos[k]
		var yw := _pole_yaw[k]
		var tip := base + Basis.from_euler(Vector3(0, yw, 0)) * Vector3(-0.75, 7.52, 0.0)
		_raw("raven", "aCorb", tip, yw + PI * 0.5 + _rng.randf_range(-0.4, 0.4), 1.4, "")
		# Ancora de sol: baza stalpului (probe_manual nu-l mai ia drept plutitor).
		_meta_last("metadata/ancora_sol = Vector3(0, %.3f, 0)" % (-7.52 / 1.4))


## Gard de sarma 80 m (20 de segmente de 4 m) la 9 m de margine = 16 m de axa,
## pe nord; capetele plane se inlantuie. Segmentul merge pe Z local: yaw PI/2
## il pune pe X.
func _fence() -> void:
	var z := -40.0 - (SEMI + 9.0)
	var x := 196.0
	while x < 276.0 - 0.1:
		var xc := x + 2.0
		_raw("wire_fence", "aGard", Vector3(xc, _sol(xc, z), z), PI * 0.5, 1.0, "")
		x += 4.0


func _post_and_pickup() -> void:
	# Postul de negot la x 280-295, z -70..-85, prispa (fata -Z local) spre drum
	# (sud, +Z): yaw = PI intoarce -Z local in +Z lume.
	var pp := Vector3(286.0, 0.0, -78.0)
	pp.y = _sol(pp.x, pp.z)
	_raw("trading_post", "aPost", pp, PI + 0.06, 1.0, "")
	# Pickup parcat la ~15 m de post spre vest, botul spre drum, usor strambat.
	var pk := Vector3(271.0, 0.0, -66.0)
	pk.y = _sol(pk.x, pk.z)
	_raw("pickup_old", "aPickup", pk, 0.5, 1.0, "")


func _water() -> void:
	# Turnul pe axa lui H, moara la dreapta lui; jgheabul (-Z local) spre drum
	# (vest), caii in jurul lui, boturile spre apa.
	var tw := Vector3(325.0, 0.0, -40.0)
	tw.y = _sol(tw.x, tw.z)
	_raw("water_tower", "aTurn", tw, 0.4, 1.0, "")
	var mw := Vector3(337.0, 0.0, -50.0)
	mw.y = _sol(mw.x, mw.z)
	# jgheabul (z -3.58..-0.72 local) -> spre vest (-X): yaw = PI/2.
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
		# boturile (-Z local) spre jgheab: directia (trough - hp).
		var tdir: Vector3 = trough - hp
		var yaw := atan2(-tdir.x, -tdir.z) + _rng.randf_range(-0.3, 0.3)
		_raw(kinds[k], "aCal", hp, yaw, 1.0, "none")
		_hide_pose()


func _scatter() -> void:
	# 2 grupuri de talus, 2 ienuperi, 2 petice de rabbitbrush (3-4 tufe, jitter).
	for g in [[238.0, -72.0, "talus_boulders_a"], [304.0, -64.0, "talus_boulders_b"]]:
		var p := Vector3(g[0], 0.0, g[1])
		p.y = _sol(p.x, p.z)
		_raw(g[2], "aTalus", p, _rng.randf() * TAU, 1.0, "")
	for g in [[222.0, -76.0], [318.0, -66.0]]:
		var p := Vector3(g[0], 0.0, g[1])
		p.y = _sol(p.x, p.z)
		_raw("juniper", "aIenupar", p, _rng.randf() * TAU, 1.0, "")
	for c in [Vector2(254.0, -62.0), Vector2(296.0, -56.0)]:
		var k := _rng.randi_range(3, 4)
		for i in k:
			var o := Vector2(_rng.randf_range(-3.2, 3.2), _rng.randf_range(-2.4, 2.4))
			var p := Vector3(c.x + o.x, 0.0, c.y + o.y)
			p.y = _sol(p.x, p.z)
			_raw("rabbitbrush", "aRabbit", p, _rng.randf() * TAU, _rng.randf_range(0.85, 1.2), "")


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
