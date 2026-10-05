extends Node
## Generator de decor pentru POI D — Poarta dintre Mittens (Track19, Monument Valley).
##   godot --headless --path . res://tools/GenDecorMvD.tscn -- --survey
##   godot --headless --path . res://tools/GenDecorMvD.tscn -- --out=<fisier>

const SCENE := "res://scenes/tracks/Track19.tscn"

var tr: Track
var n: int


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	tr = (load(SCENE) as PackedScene).instantiate() as Track
	add_child(tr)
	for k in 6:
		await get_tree().process_frame
	n = tr.baked.size()
	if "--survey" in args:
		_survey()
	for a in args:
		if a.begins_with("--out="):
			_generate(a.substr(6))
	if "--east" in args:
		_east()
	if "--aabb" in args:
		for m in ["talus_boulders_a", "talus_boulders_b", "rock_fin", "butte_small_b", "rabbitbrush", "juniper"]:
			_aabb(m)
	get_tree().quit(0)


func _east() -> void:
	var z := 200.0
	while z <= 350.0:
		var line := "z %5.0f " % z
		var x := 330.0
		while x <= 450.0:
			line += "%4.1f " % _gy(x, z)
			x += 6.0
		print(line)
		z += 10.0


func _aabb(m: String) -> void:
	var sub := "plants/" if m in ["rabbitbrush", "juniper"] else "rocks/"
	var root := (load("res://assets/models/monumentvalley/%s%s.glb" % [sub, m]) as PackedScene).instantiate() as Node3D
	add_child(root)
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mm := mi as MeshInstance3D
		if not mm.visible:
			continue
		var bb := root.global_transform.affine_inverse() * mm.global_transform * mm.get_aabb()
		lo = lo.min(bb.position)
		hi = hi.max(bb.end)
	print("%s aabb lo %s hi %s" % [m, lo, hi])
	root.queue_free()


func _gy(x: float, z: float) -> float:
	return tr._terrain_mesh_y(x, z)


func _survey() -> void:
	for f in [0.185, 0.19, 0.2, 0.2048, 0.21, 0.22, 0.23, 0.24, 0.25, 0.26]:
		var i := int(f * n)
		var q: Vector3 = tr.baked[i]
		var sd: Vector3 = tr._side_at(i)
		var hw: float = tr.width_at_index(i)
		print("frac %.4f idx %d q (%.1f %.2f %.1f) side (%.2f %.2f) hw %.2f shoulder %.2f" % [f, i, q.x, q.y, q.z, sd.x, sd.z, hw, tr._level_shoulder_at(i)])
	# harta de cote: x 270..350, z 270..330 din 4 in 4
	var z := 266.0
	while z <= 420.0:
		var line := "z %5.0f " % z
		var x := 262.0
		while x <= 350.0:
			var y := _gy(x, z)
			line += "%4.1f " % y
			x += 4.0
		print(line)
		z += 8.0


# ---------------------------------------------------------------- generare

const _NOCOL := ["s_sagebrush", "s_rabbitbrush", "s_juniper_small"]
const ZONA := "DecorManual/ZonaD"
const HALF := {"a": Vector2(2.16, 1.55), "b": Vector2(2.86, 2.24)}
const ROAD_X := 300.0
const MARGIN := 6.5
const MIN_GAP := 2.8   # hull la >= 2,8 m de marginea asfaltului

var _out: PackedStringArray = []
var _rng := RandomNumberGenerator.new()
var _count := {}


func _emit(name: String, res: String, xf: Transform3D) -> void:
	_out.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [name, ZONA, res])
	_out.append("transform = " + var_to_str(xf))
	if _force_none or res in _NOCOL:
		_out.append('metadata/coliziune = "none"')
	_out.append("")
	var key := res
	_count[key] = int(_count.get(key, 0)) + 1


## Piesa pe teren la (x, z), cu yaw; hull-ul nu intra sub MIN_GAP de margine.
func _put(name: String, stem: String, x: float, z: float, yaw: float, sink := 0.12, scl := 1.0) -> Vector3:
	var he: Vector2 = HALF.get(stem.trim_prefix("talus_boulders_"), Vector2(0.8, 0.8))
	var ex: float = (absf(cos(yaw)) * he.x + absf(sin(yaw)) * he.y) * scl
	var lat := absf(x - ROAD_X) - MARGIN - ex
	if lat < MIN_GAP and z < 395.0 and stem.begins_with("talus"):
		var push := MIN_GAP - lat
		x += push * signf(x - ROAD_X)
		lat = MIN_GAP
	var p := Vector3(x, _gy(x, z) - sink, z)
	_emit(name, "s_" + stem, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl), p))
	return p


func _group(tag: String, cx: float, z: float, mainstem: String, comp: String, comp_dz: float, comp_dx: float) -> void:
	var yaw := _rng.randf_range(0.0, TAU)
	_put(tag + "_1", mainstem, cx, z, yaw)
	_put(tag + "_2", comp, cx + comp_dx, z + comp_dz, yaw + _rng.randf_range(1.0, 2.2), 0.12, _rng.randf_range(0.8, 1.0))


func _generate(path: String) -> void:
	_rng.seed = 20261005
	var A := "talus_boulders_a"
	var B := "talus_boulders_b"
	# umerii portii: 3 grupuri pe latura, goluri >= 6 m, culoarul BolovanD (z 296-312) liber
	# vest (spre WM): marginea la x 293,5, fusta GLB la ~286
	_group("TalusW1", 285.5, 276.0, B, A, -4.4, 1.2)
	_group("TalusW2", 284.0, 323.0, A, B, 5.0, -0.8)
	_group("TalusW3", 286.5, 337.0, B, A, 5.6, 0.6)
	# est (spre EM): marginea la x 306,5, fusta GLB la ~315
	_group("TalusE1", 314.5, 281.0, A, B, -5.2, 0.8)
	_group("TalusE2", 313.5, 325.0, B, A, 4.6, 0.9)
	_group("TalusE3", 315.5, 340.0, A, B, 5.4, -0.5)
	# baza lui Merrick, spre drum
	_group("TalusM1", 343.0, 252.0, B, A, 5.2, 1.4)
	_group("TalusM2", 341.0, 272.0, A, B, 5.6, 0.8)
	_group("TalusM3", 346.0, 289.0, B, A, 5.4, -1.0)
	# dupa poarta (z 355-415): densitatea scade spre E, dar nu la zero
	_group("TalusW4", 281.5, 372.0, A, A, 4.2, 1.0)
	_group("TalusE4", 319.0, 384.0, B, A, 5.0, -0.6)
	_group("TalusW5", 279.0, 402.0, B, A, -5.4, 0.8)
	# formatiuni
	_emit("RockFin", "s_rock_fin", Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3(388.0, _gy(388.0, 330.0) - 0.15, 330.0)))
	_emit("ButteSpateMerrick", "s_butte_small_b", Transform3D(Basis(Vector3.UP, deg_to_rad(-70.0)), Vector3(414.0, _gy(414.0, 238.0) - 0.2, 238.0)))
	# petice de rabbitbrush (galben = accentul viu): nealiniate
	_patch("RabbitW", 279.0, 346.0, 5)
	_patch("RabbitE", 322.0, 292.0, 4)
	_patch("RabbitM", 331.0, 352.0, 5)
	_patch("RabbitW2", 276.0, 392.0, 4)
	_patch("RabbitE2", 326.0, 372.0, 4)
	# ienuperi
	_emit("JuniperW", "s_juniper", Transform3D(Basis(Vector3.UP, 0.9), Vector3(281.0, _gy(281.0, 352.0) - 0.1, 352.0)))
	_emit("JuniperE", "s_juniper", Transform3D(Basis(Vector3.UP, 2.4), Vector3(322.0, _gy(322.0, 351.0) - 0.1, 351.0)))
	_carpet()
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("
".join(_out))
	f.close()
	print("scris %s: %s" % [path, _count])


func _patch(tag: String, cx: float, cz: float, k: int) -> void:
	for i in k:
		var a := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(0.4, 2.8)
		var x := cx + cos(a) * r
		var z := cz + sin(a) * r
		_emit("%s_%d" % [tag, i + 1], "s_rabbitbrush", Transform3D(Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.25)), Vector3(x, _gy(x, z) - 0.05, z)))


var _force_none := false
var _taken: Array[Vector2] = []
var _smallrocks := 0


func _free(x: float, z: float, r: float) -> bool:
	for t in _taken:
		if Vector2(x, z).distance_to(t) < r:
			return false
	return true


## Covorul de langa drum (runda 3): palcuri de 3-5 tufe pe fasia 2-12 m de la
## margine, pe ambele parti, cu goluri; una mare + 2-3 mici; bolovani mici
## fara coliziune lipiti de palcuri.
func _carpet() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 77031
	# centrele grupurilor de talus deja puse (nu se suprapun)
	for l in _out:
		if l.begins_with("transform"):
			var nums := l.trim_prefix("transform = Transform3D(").trim_suffix(")").split(", ")
			_taken.append(Vector2(float(nums[9]), float(nums[11])))
	_force_none = true
	var z := 262.0
	var k := 0
	var rocks := 0
	while z < 404.0:
		for side: float in [-1.0, 1.0]:
			k += 1
			var zc := z + r.randf_range(-3.0, 3.0)
			var d0 := r.randf_range(3.5, 10.0)
			var cx := ROAD_X + side * (MARGIN + d0)
			if not _free(cx, zc, 5.5):
				continue
			var n := r.randi_range(3, 5)
			var kind_main: String = ["s_sagebrush", "s_sagebrush", "s_juniper", "s_rabbitbrush"][r.randi() % 4]
			for i in n:
				var a := r.randf_range(0.0, TAU)
				var rad := 0.0 if i == 0 else r.randf_range(1.0, 2.6)
				var x := cx + cos(a) * rad
				var zz := zc + sin(a) * rad
				var lat := absf(x - ROAD_X) - MARGIN
				if lat < 2.0 or lat > 12.5:
					continue
				var res: String = kind_main if i == 0 else ["s_sagebrush", "s_sagebrush", "s_rabbitbrush", "s_sagebrush"][r.randi() % 4]
				var sc := (r.randf_range(1.6, 2.0) if i == 0 else r.randf_range(0.8, 1.1))
				if res == "s_rabbitbrush":
					sc = r.randf_range(1.0, 1.3) if i == 0 else r.randf_range(0.6, 0.85)
				if res == "s_juniper":
					sc = 0.55 if i == 0 else 0.4
				var xf := Transform3D(Basis(Vector3.UP, r.randf_range(0.0, TAU)).scaled(Vector3.ONE * sc), Vector3(x, _gy(x, zz) - 0.05, zz))
				_emit("Tufa%d_%d" % [k, i], res, xf)
			if rocks < 8 and (zc < 292.0 or zc > 316.0) and r.randf() < 0.4:
				var m := r.randi_range(2, 3)
				for j in m:
					var x2 := cx + r.randf_range(-2.0, 2.0)
					var z2 := zc + r.randf_range(-2.0, 2.0)
					var s2 := r.randf_range(0.22, 0.32)
					_emit("Lespede%d_%d" % [k, j], "s_talus_boulders_a", Transform3D(Basis(Vector3.UP, r.randf_range(0.0, TAU)).scaled(Vector3.ONE * s2), Vector3(x2, _gy(x2, z2) - 0.05, z2)))
					rocks += 1
				_smallrocks += m
		z += r.randf_range(6.5, 10.0) if z < 300.0 else r.randf_range(10.0, 16.0)
	_force_none = false
	print("covor: %d palcuri, %d bolovani mici" % [k, _smallrocks])
